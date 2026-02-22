{ pkgs, username, ... }:
{
  imports = [ ];

  environment = {
    systemPackages = with pkgs; [
      fish
    ];
    shells = with pkgs; [ fish ];
    variables = {
      NEXT_TELEMETRY_DISABLED = "1";
    };
  };

  homebrew = {
    enable = true;
    brews = [
      "gnu-sed"
    ];
    casks = [
      # "docker"
      "figma"
      # "floorp"
      "font-d2coding"
      "font-departure-mono"
      "font-jetbrains-mono-nerd-font"
      "font-victor-mono-nerd-font"
      "font-aporetic"
      # "ghostty"
      # "iina"
      "insomnium"
      "raycast"
      "rectangle"
      # "spotify"
      "obs"
      # "orbstack"
      # "utm"
      # "vial"
      # "zed"
    ];
    taps = [
      # "homebrew/cask-fonts"
      # "nikitabobko/tap"
      "BarutSRB/tap"
    ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # disable for deterministic systems nix
  nix.enable = false;

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
      location = "/Users/${username}/Pictures/Screenshots";
      type = "png";
    };

    NSGlobalDomain = {
      "com.apple.mouse.tapBehavior" = 1.0;
      "com.apple.trackpad.scaling" = 3.0;
      _HIHideMenuBar = false;
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
      "com.apple.mail" = {
        AddressesIncludeNameOnPasteboard = false;
      };
    };

  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  users.knownUsers = [ "${username}" ];
  users.knownGroups = [ "${username}" ];
  users.users.${username} = {
    home = /Users/${username};
    shell = pkgs.fish;
    uid = 502;
  };
  system.primaryUser = "${username}";

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  programs.zsh.enable = false;

  system.stateVersion = 5;

}
