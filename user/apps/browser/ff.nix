{ pkgs-unstable, ... }:

{
  # programs.floorp = {
  #   enable = true;
  #   profiles.default = {
  #     name = "default";
  #     isDefault = true;
  #   };
  # };

  xdg.mimeApps.defaultApplications = {
    "text/html" = "floorp.desktop";
    "x-scheme-handler/http" = "floorp.desktop";
    "x-scheme-handler/https" = "floorp.desktop";
    "x-scheme-handler/about" = "floorp.desktop";
    "x-scheme-handler/unknown" = "floorp.desktop";
  };


  home.packages = [ pkgs-unstable.floorp-bin ];

  home.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs-unstable.floorp-bin}/bin/floorp";
  };
}
