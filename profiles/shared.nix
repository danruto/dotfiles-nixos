_: {
  home.file.".config/zellij/config.kdl".source = ../../user/config/zellij.kdl;

  home.sessionVariables = {
    EDITOR = "hx";
  };

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;

}
