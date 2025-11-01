{ pkgs, ... }:
{
  home.packages = [
    # Wrap 1Password GUI to force Wayland mode instead of XWayland
    (pkgs.symlinkJoin {
      name = "1password-gui-wayland";
      paths = [ pkgs._1password-gui ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/1password --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      '';
    })
    pkgs._1password-cli
  ];
}
