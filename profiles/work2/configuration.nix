{ pkgs, ... }: {
  imports = [
      ../../user/wm/yabai/yabai.nix # yabai and co
      ../../user/wm/yabai/skhd.nix # yabai and co
      ../../user/wm/yabai/sketchybar.nix # yabai and co
  ];

  environment = {
    systemPackages = with pkgs; [
      fish
    ];
    variables = {
      NEXT_TELEMETRY_DISABLED = "1";
    };
  };
  homebrew = {
    enable = true;
    brews = [
      "gnu-sed"
      "qemu"
      "wireguard-go"
      "wireguard-tools"
    ];
    casks = [
      "1password"
      "1password-cli"
      "alacritty"
      "alfred"
      "azure-data-studio"
      "brave-browser"
      "discord"
      "docker"
      "figma"
      "firefox"
      "font-d2coding"
      "font-jetbrains-mono-nerd-font"
      "font-victor-mono-nerd-font"
      "iina"
      "insomnium"
      "kitty"
      "rectangle"
      "slack"
      "spotify"
      "obs"
      "utm"
      "vial"
      "visual-studio-code"
      "wireshark"
    ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  security.pam.enableSudoTouchIdAuth = true;
  services.nix-daemon.enable = true;
  system.defaults = {
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.autohide-time-modifier = 0.5;
    dock.mineffect = "scale";
    dock.show-process-indicators = true;
    dock.tilesize = 48;
    finder._FXShowPosixPathInTitle = true;
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder.FXEnableExtensionChangeWarning = false;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.QuitMenuItem = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1.0;
    NSGlobalDomain."com.apple.trackpad.scaling" = 3.0;
    NSGlobalDomain._HIHideMenuBar = true;
    NSGlobalDomain.AppleICUForce24HourTime = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = false;
    NSGlobalDomain.AppleScrollerPagingBehavior = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
  };
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
  # TODO: use username when we format
  users.users.danny = {
    home = "/Users/danny";
    shell = pkgs.fish;
  };

}

