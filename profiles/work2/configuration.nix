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
    loginShell = pkgs.fish;
  };

  # networking.dns = [ "1.1.1.1" "8.8.8.8" ];

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
      # "alacritty"
      "azure-data-studio"
      "brave-browser"
      "discord"
      # "docker"
      "figma"
      "firefox"
      "font-d2coding"
      "font-jetbrains-mono-nerd-font"
      "font-victor-mono-nerd-font"
      "iina"
      "insomnium"
      # "kitty"
      "raycast"
      "rectangle"
      "slack"
      "spotify"
      "obs"
      "orbstack"
      "utm"
      "vial"
      "visual-studio-code"
      "wireshark"
    ];
    taps = [
      "homebrew/cask-fonts"
    ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  security.pam.enableSudoTouchIdAuth = true;
  services.nix-daemon.enable = true;

  system.activationScripts.postActivation.text = ''
    # disable spotlight
    launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist >/dev/null 2>&1 || true
    # show upgrade diff
    ${pkgs.nix}/bin/nix store --experimental-features nix-command diff-closures /run/current-system "$systemConfig"
  '';

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.5;
      mineffect = "scale";
      show-process-indicators = true;
      tilesize = 48;
      mru-spaces = false;
      show-recents = false;
    };

    finder = {
      _FXShowPosixPathInTitle = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    screencapture = {
      disable-shadow = true;
      location = "/Users/danruto/Pictures/Screenshots";
      type = "png";
    };

    NSGlobalDomain = {
      "com.apple.mouse.tapBehavior" = 1.0;
      "com.apple.trackpad.scaling" = 3.0;
      _HIHideMenuBar = true;
      AppleICUForce24HourTime = false;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleScrollerPagingBehavior = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleMeasurementUnits = "Centimeters";
      AppleTemperatureUnit = "Celsius";

      InitialKeyRepeat = 20;
      KeyRepeat = 2;
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        WebKitDeveloperExtras = true;
        AppleAccentColor = 1;
      };
      "com.apple.finder" = {
        DisableAllAnimations = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
      };
      "com.apple.NetworkBrowser" = {
        BrowseAllInterfaces = 1;
      };
      "com.apple.DesktopServices" = {
        DSDontWriteNetworkStores = true;
      };
      "com.apple.Safari" = {
        AutoOpenSafeDownloads = false;
        IncludeDevelopMenu = true;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };
      "com.apple.mail" = {
        AddressesIncludeNameOnPasteboard = false;
      };
    };

  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # TODO: use username when we format
  users.knownUsers = [ "danruto" ];
  users.knownGroups = [ "danruto" ];
  users.users.danruto = {
    home = "/Users/danruto";
    shell = pkgs.fish;
    uid = 501;
  };

  environment.shells = with pkgs; [ 
    fish 
    # zsh
  ];

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  programs.zsh.enable = false;

}

