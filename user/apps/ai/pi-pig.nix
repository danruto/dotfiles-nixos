{ lib, stdenvNoCC, fetchurl, makeWrapper, nodejs, ripgrep, fd, python3 }:

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
in
stdenvNoCC.mkDerivation {
  pname = "pig";
  inherit version;

  src = fetchurl {
    url = "https://github.com/MichaelKinsy/PiG/releases/download/v${version}/pig-${version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 pig "$out/libexec/pig/pig"
    makeWrapper "$out/libexec/pig/pig" "$out/bin/pig" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ripgrep fd python3 ]}
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
