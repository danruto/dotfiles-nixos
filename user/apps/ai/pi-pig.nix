{ lib, stdenvNoCC, fetchurl, makeWrapper, nodejs, ripgrep, fd, python3
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

  passthru.herdrExtension = herdrExtension;

  # llm.nix pins the agent directory whose config files it symlinks, even when
  # XDG_CONFIG_HOME is set. Do not enable PIG_USE_PI_DIRS: only configuration is
  # shared with Pi, not credentials, sessions or installed packages.

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 pig "$out/libexec/pig/pig"
    makeWrapper "$out/libexec/pig/pig" "$out/bin/pig" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ripgrep fd python3 ]} \
      ${lib.optionalString (agentDir != null) "--set-default PIG_CODING_AGENT_DIR ${lib.escapeShellArg agentDir}"}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/pig" --version | grep -F "${version}+1.4.0"
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
