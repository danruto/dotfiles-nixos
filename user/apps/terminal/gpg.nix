{ pkgs, ... }:

{
  programs.gpg = {
    enable = true;
  };

  programs.fish.interactiveShellInit = ''
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
  '';

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 43200;
    maxCacheTtl = 43200;
    pinentry.package = pkgs.pinentry-tty;
  };
}
