{ lib, stdenvNoCC, fetchurl, fetchzip, makeWrapper, nodejs, ripgrep, fd, python3, go
, agentDir ? null
}:

let
  version = "0.5.3";
  sources = {
    "x86_64-linux" = {
      target = "linux-amd64";
      hash = "sha256-HkXl5ZGgbQh1h9XwnSttYWc6HiYssmCeYYne//1a5+w=";
    };
    "aarch64-linux" = {
      target = "linux-arm64";
      hash = "sha256-yUrKqLKl09Kx9Z5nn3C7pnYtx6AWVTabL/xA+5vkVSs=";
    };
    "aarch64-darwin" = {
      target = "darwin-arm64";
      hash = "sha256-skPgAwXix9PV3hJ0O7RlTPYySmKCsMLgZxzCm/veOpk=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
  sdkSource = fetchzip {
    url = "https://github.com/MichaelKinsy/PiG/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-XK27VNd799qUCsOUidYPo/leleMWtoan5gNuke9geqk=";
  };
  statusExtension = stdenvNoCC.mkDerivation {
    pname = "pig-status";
    version = "0.2.0";
    src = ./pig-status;
    nativeBuildInputs = [ go ];
    env = {
      CGO_ENABLED = "0";
      GOTOOLCHAIN = "local";
      GOPROXY = "off";
      GOSUMDB = "off";
    };
    preBuild = ''
      export HOME="$TMPDIR"
      export GOCACHE="$TMPDIR/go-cache"
      export GOMAXPROCS="$NIX_BUILD_CORES"
      export GOFLAGS="-p=$NIX_BUILD_CORES"
      go mod edit -replace github.com/MichaelKinsy/PiG/extensions/sdk=${sdkSource}/extensions/sdk
    '';
    buildPhase = ''
      runHook preBuild
      go build -trimpath -ldflags="-s -w" -o pig-status .
      runHook postBuild
    '';
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      go test ./...
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 pig-status "$out/bin/pig-status"
      install -Dm644 package.json "$out/package.json"
      runHook postInstall
    '';
    meta.platforms = builtins.attrNames sources;
  };
  # herdr-pig v0.2.1, Apache-2.0. Loaded only by PiG via llm.nix's home.file.
  herdrExtension = fetchurl {
    name = "herdr-pig-agent-state-0.2.1.ts";
    url = "https://raw.githubusercontent.com/Hai-Fai-Solutions/herdr-pig/3ec680471e8282e0a8a64545781069f822c0c212/extensions/herdr-agent-state.ts";
    hash = "sha256-CYiy0xLsiFe9qSqBMKchaV6iWecrPgQ+8y8C3bARdBE=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "pig";
  inherit version;

  src = fetchurl {
    url = "https://github.com/MichaelKinsy/PiG/releases/download/v${version}/pig-${version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ makeWrapper ];

  passthru = { inherit herdrExtension statusExtension; };

  # Keep credentials, sessions and installed packages separate from Pi.

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 pig "$out/libexec/pig/pig"
    makeWrapper "$out/libexec/pig/pig" "$out/bin/pig" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ripgrep fd python3 go ]} \
      ${lib.optionalString (agentDir != null) "--set-default PIG_CODING_AGENT_DIR ${lib.escapeShellArg agentDir}"}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    PIG_CODING_AGENT_DIR="$TMPDIR/agent" "$out/bin/pig" --version | grep -F "${version}+1.4.0"
    runHook postInstallCheck
  '';

  meta = {
    description = "Pi coding agent rewritten in Go with multi-language extension host";
    homepage = "https://pi-in-go.dev/";
    license = lib.licenses.mit;
    mainProgram = "pig";
    platforms = builtins.attrNames sources;
  };
}
