{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  # On hosts without a system fontconfig (e.g. the OrbStack VM), nothing pulls
  # in HM's generated conf.d, so fontconfig-only consumers like fontdb/cosmic-text
  # (mdfried) find no fonts. Provide a top-level fonts.conf that scans the stable
  # profile font dirs and includes conf.d so those tools have an entry point.
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>~/.nix-profile/share/fonts</dir>
      <dir>~/.local/state/nix/profiles/home-manager/home-path/share/fonts</dir>
      <dir prefix="xdg">fonts</dir>
      <include ignore_missing="yes">conf.d</include>
    </fontconfig>
  '';

  home.packages = with pkgs; [
    powerline
    font-awesome
    terminus_font
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.agave
    nerd-fonts.ubuntu-mono
    nerd-fonts.zed-mono
    nerd-fonts.d2coding
    nerd-fonts.blex-mono
    nerd-fonts.space-mono
    nerd-fonts.victor-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.departure-mono
    nerd-fonts.caskaydia-cove
    nerd-fonts.inconsolata
  ];

}
