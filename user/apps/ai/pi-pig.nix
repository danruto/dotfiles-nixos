{ lib, buildGoModule, fetchurl, makeWrapper, nodejs, ripgrep, fd, python3, go
, agentDir ? null
}:

let
  version = "0.7.0";
  upstreamRevision = "beb56447c476da70d05d8e1e1ca9e993b367cb8b";
  platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  # herdr-pig v0.2.1, Apache-2.0. Loaded only by PiG via llm.nix's home.file.
  herdrExtension = fetchurl {
    name = "herdr-pig-agent-state-0.2.1.ts";
    url = "https://raw.githubusercontent.com/Hai-Fai-Solutions/herdr-pig/3ec680471e8282e0a8a64545781069f822c0c212/extensions/herdr-agent-state.ts";
    hash = "sha256-CYiy0xLsiFe9qSqBMKchaV6iWecrPgQ+8y8C3bARdBE=";
  };
in
assert lib.assertMsg (go.version == "1.27.3") "PiG ${version} requires Go 1.27.3";
buildGoModule {
  pname = "pig";
  inherit version;

  src = fetchurl {
    url = "https://github.com/MichaelKinsy/PiG/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-p3Ax4r2kN3Wi1bVJKwZY2mg1yDl2frEqBdOvfUs641Q=";
  };

  patches = [ ./patches/pig-0.5.3-event-bus-cleanup.patch ];
  vendorHash = "sha256-TxiMiTBUE8KqTMbxLecJ9NzvWH8PE3wIXs66ENnZ4S8=";
  proxyVendor = true;
  subPackages = [ "cmd/pig" ];
  # The extension host needs the Go compiler at runtime.
  allowGoReference = true;
  preBuild = ''
    export GOFLAGS="$GOFLAGS -trimpath"
  '';
  env = {
    GOWORK = "off";
    CGO_ENABLED = "0";
  };
  postPatch = ''
    printf '\nreplace github.com/MichaelKinsy/PiG/extensions/sdk => ./extensions/sdk\n' >> go.mod
  '';
  ldflags = [ "-s" "-w" "-X github.com/MichaelKinsy/PiG/coding/cli.Build=${upstreamRevision}-event-bus-cleanup" ];

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ nodejs ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    export HOME="$TMPDIR/home" PIG_HOME="$TMPDIR/pig" PI_HOME="$TMPDIR/pi"
    export PIG_CODING_AGENT_DIR="$TMPDIR/pig/agent" PI_CODING_AGENT_DIR="$TMPDIR/pi/agent"
    mkdir -p "$HOME" "$PIG_CODING_AGENT_DIR" "$PI_CODING_AGENT_DIR"
    go test -trimpath ./test/extension-conformance \
      -run '^(TestNativeEventBusRegistrationOrderAcrossRealms|TestNativeEventBusReload_AC3_RetiresMigratedNodeListeners)$/^AC1_AC2_node_listener_predates_native_subscription$' \
      -count=1 -timeout=180s
    go test -trimpath ./coding/extension/host/subprocess \
      -run '^(TestHostEventBusListenerIsRetiredByRuntimeInvalidate|TestHostEventBusClosedConnectionForgetsRetainedSubscriptions|TestHostEventBusStaleUnsubscribeKeepsTheListenerThatReusedItsKey|TestNodeEventBusListenersRemovedOnReloadAndShutdown)$' \
      -count=1 -timeout=180s
    runHook postCheck
  '';

  passthru = { inherit herdrExtension; };

  # Keep credentials, sessions and installed packages separate from Pi.

  postInstall = ''
    mkdir -p "$out/libexec/pig"
    mv "$out/bin/pig" "$out/libexec/pig/pig"
    makeWrapper "$out/libexec/pig/pig" "$out/bin/pig" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ripgrep fd python3 go ]} \
      ${lib.optionalString (agentDir != null) "--set-default PIG_CODING_AGENT_DIR ${lib.escapeShellArg agentDir}"}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # The binary must report the pinned release plus the Pi version baked into its source.
    upstream=$(sed -n 's/^const UpstreamVersion = "\([^"]*\)"$/\1/p' internal/coding/pigversion/pigversion.go)
    [ -n "$upstream" ]
    PIG_CODING_AGENT_DIR="$TMPDIR/agent" "$out/bin/pig" --version | grep -Fx "${version}+$upstream"
    runHook postInstallCheck
  '';

  meta = {
    description = "Pi coding agent rewritten in Go with multi-language extension host";
    homepage = "https://pi-in-go.dev/";
    license = lib.licenses.mit;
    mainProgram = "pig";
    inherit platforms;
  };
}
