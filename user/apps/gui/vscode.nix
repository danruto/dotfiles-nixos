{ pkgs-unstable, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode-fhs;
    profiles.default.extensions = with pkgs-unstable; [
      vscode-extensions.ms-dotnettools.csdevkit
      vscode-extensions.teabyii.ayu
      vscode-extensions.vscodevim.vim
    ];
  };
}
