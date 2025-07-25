{
  description = "Danruto NixOS Configuration";

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , blocklist-hosts
    , rust-overlay
    , hyprland-plugins
    , nur
    , darwin
    , helix
    , neovim-nightly-overlay
    , zjstatus
    , niri
    , nixos-hardware
    , ...
    }@inputs:
    let
      # ---- SYSTEM SETTINGS ---- #
      system = "x86_64-linux";
      # system = "x86_64-darwin";
      hostname = "danruto"; # hostname
      # profile = "wsl";
      # profile = "vm";
      # profile = "vm-hypr";
      # profile = "work";
      # profile = "work2";
      profile = "framework";
      # profile = "orb";
      timezone = "Australia/Sydney"; # select timezone
      locale = "en_US.UTF-8"; # select locale

      # ----- USER SETTINGS ----- #
      username = "danruto"; # username
      email = "danny@pixelbru.sh"; # email (used for certain configurations)
      theme = "ayu-dark"; # selcted theme from my themes directory (./themes/)
      wm = "hyprland"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
      wmType = "wayland"; # x11 or wayland
      browser = "brave"; # Default browser; must select one from ./user/apps/browser/
      editor = "hx"; # Default editor;
      term = "alacritty"; # Default terminal command;
      fontPkg = pkgs.d2coding; # Font package

      # create patched nixpkgs
      nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgs;
        patches = [ ];
      };

      nixpkgs-unstable-patched = (import nixpkgs { inherit system; }).applyPatches {
        name = "nixpkgs-unstable-patched";
        src = nixpkgs-unstable;
        patches = [ ];
      };

      # configure pkgs
      pkgs = import nixpkgs-patched {
        inherit system;
        # inherit nixpkgs-unstable;

        config = {
          allowUnfree = true;
          allowUnfreePredicate = (_: true);
          allowBroken = true;
        };
        overlays = [
          rust-overlay.overlays.default
          nur.overlays.default
          # neovim-nightly-overlay.overlays.default
          (final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
          })
        ];
      };

      pkgs-unstable = import nixpkgs-unstable-patched {
        inherit system;

        config = {
          allowUnfree = true;
          allowUnfreePredicate = (_: true);
          allowBroken = true;
        };
        overlays = [
          rust-overlay.overlays.default
          nur.overlays.default
          (final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
          })
        ];
      };

      # configure lib
      lib = nixpkgs.lib;

      commonSpecialArgs = {
        inherit username;
        # inherit name;
        inherit hostname;
        inherit profile;
        inherit email;
        inherit theme;
        inherit fontPkg;
        inherit wm;
        inherit wmType;
        inherit browser;
        inherit editor;
        inherit term;
        inherit helix;
        inherit timezone;
        inherit locale;
        inherit pkgs-unstable;

        inherit (inputs) blocklist-hosts;
        inherit (inputs) neovim-nightly-overlay;

        # channels = { inherit nixpkgs nixpkgs-unstable; };
      };

      wslSpecialArgs = commonSpecialArgs // {
        inherit (inputs) nixos-wsl;
        # inherit inputs;
      };

      fwSpecialArgs = commonSpecialArgs // {
        inherit (inputs) hyprland-plugins;
        inherit (inputs) niri;
        inherit (inputs) nixos-hardware;
      };

    in
    {
      nixosConfigurations = {
        system = lib.nixosSystem {
          system = "x86_64-linux";
          # inherit pkgs;
          modules = [
            # load configuration.nix from selected PROFILE
            (./. + "/profiles" + ("/" + profile) + "/configuration.nix")
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${username} = import (./. + "/profiles" + ("/" + profile) + "/home.nix");

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              home-manager.extraSpecialArgs = if (profile == "wsl") then wslSpecialArgs else fwSpecialArgs;
            }
          ];
          specialArgs = if (profile == "wsl") then wslSpecialArgs else fwSpecialArgs;
        };
      };

      darwinConfigurations = {
        work = darwin.lib.darwinSystem {
          # system = "x86_64-darwin";
          inherit system;
          inherit pkgs;
          # pkgs = import nixpkgs {inherit system;};

          modules = [
            # load configuration.nix from selected PROFILE
            (./. + "/profiles" + ("/" + profile) + "/configuration.nix")
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.danruto = import (./. + "/profiles" + ("/" + profile) + "/home.nix");

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              home-manager.extraSpecialArgs = commonSpecialArgs;
            }
          ];
          specialArgs = commonSpecialArgs;
        };
      };
    };

  inputs = {
    # Global shared inputs
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    blocklist-hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # WSL inputs
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Framework inputs
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      flake = false;
    };
    niri.url = "github:sodiboo/niri-flake";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    fw-ectool = {
      url = "github:tlvince/ectool.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.3.0";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Mac inputs
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
