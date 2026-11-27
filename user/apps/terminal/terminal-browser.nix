{ pkgs, lib, ... }:

let
  version = "0.16.3";

  sources = {
    aarch64-linux = {
      target = "linux-arm64";
      sha256 = "805201d715a6c684c8c1d5187d90639f077f8ffae68934e1197bcd0d13682037";
    };
    x86_64-linux = {
      target = "linux-x64";
      sha256 = "b66199f47ec18b00a47423cc8095dc06898eaed0c4f247a252cfce76388ea151";
    };
  };

  src = sources.${pkgs.stdenv.hostPlatform.system};

  terminal-browser = pkgs.stdenv.mkDerivation {
    pname = "terminal-browser";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-${src.target}.tar.gz";
      inherit (src) sha256;
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libgbm
      libxkbcommon
      nspr
      nss
      pango
      systemd
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      stdenv.cc.cc.lib
    ];

    runtimeDependencies = with pkgs; [ libGL vulkan-loader libxkbcommon ];

    sourceRoot = ".";
    unpackPhase = ''
      mkdir app
      tar -xzf $src -C app --strip-components 1
    '';

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      cp -r app $out/lib/terminal-browser
      makeWrapper $out/lib/terminal-browser/bin/terminal-browser $out/bin/terminal-browser \
        --set-default TERMINAL_BROWSER_NO_TELEMETRY 1 \
        --set-default PIXEL_RENDER_SCALE 1
      runHook postInstall
    '';

    autoPatchelfIgnoreMissingDeps = [ "libffmpeg.so" ];

    meta = {
      description = "Chromium browser that draws into the terminal with the kitty graphics protocol";
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      platforms = builtins.attrNames sources;
      mainProgram = "terminal-browser";
    };
  };
in
{
  home.packages = [ terminal-browser ];
}
