{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, makeWrapper, libxcb
, nodejs, ripgrep, fd, python3, writableTmpDirAsHomeHook }:

let
  version = "1.0.4";
  sources = {
    "x86_64-linux" = {
      target = "linux-x64-baseline";
      hash = "sha256-8C2VGFknmodSF0MDBXyVMOa3eFDZ/YQQlqoTDAQjxuE=";
    };
    "aarch64-linux" = {
      target = "linux-arm64";
      hash = "sha256-xMxVnEr64/ZaEns7fz5JGh7a/2Fs4y9EPF4h9/IBcUs=";
    };
    "aarch64-darwin" = {
      target = "darwin-arm64";
      hash = "sha256-i+Z8R/h7FiH1IIUAs8VE2FIpM3MNf23lQZ17krzFXK0=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "pi-bolt";
  inherit version;

  src = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/pi-bolt-${source.target}.tar.xz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux libxcb;

  # The compiled JavaScript payload lives past the executable's native sections.
  dontStrip = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/pi-bolt"
    cp -R . "$out/libexec/pi-bolt/"
    makeWrapper "$out/libexec/pi-bolt/pi" "$out/bin/pi-bolt" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ripgrep fd python3 ]} \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0 \
      --run 'case "''${1-}" in update|compile) echo "Pi-Bolt is managed by Nix; update or rebuild it through your flake." >&2; exit 1 ;; esac'
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ writableTmpDirAsHomeHook ];
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/pi-bolt" --version)" = "1.4.0 (Pi-Bolt ${version}, ${source.target}, JIT off)"
    BUN_STATIC_HEAP_VERBOSE=1 "$out/bin/pi-bolt" --version > aot.txt 2>&1
    grep -F 'image registered: true' aot.txt
    "$out/bin/pi-bolt" --help > help.txt
    grep -qF 'pi-bolt' help.txt
    "$out/bin/pi-bolt" --no-extensions --no-skills --no-prompt-templates --no-themes --list-models > models.txt
    for command in update compile; do
      if "$out/bin/pi-bolt" "$command" > blocked.txt 2>&1; then
        echo "Unexpectedly allowed: $command" >&2
        exit 1
      fi
      grep -F 'managed by Nix' blocked.txt
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "Pi coding agent compiled ahead of time with a modified Bun runtime";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "pi-bolt";
  };
}
