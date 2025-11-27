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
    , helix-fork
    , neovim-nightly-overlay
    , zjstatus
    , niri
    , nixos-hardware
    , catppuccin
    , noctalia
    , quickshell
    , vicinae
    , mango
    , dankMaterialShell
    , ...
    }@inputs:
    let
      # ---- SYSTEM SETTINGS ---- #
      system = "x86_64-linux";
      # system = "aarch64-linux";
      # system = "x86_64-darwin";
      # system = "aarch64-darwin";
      # profile = "wsl";
      # profile = "vm";
      # profile = "vm-hypr";
      # profile = "vm-niri";
      # profile = "vm-i3";
      # profile = "vm-sway";
      # profile = "work";
      # profile = "work2";
      profile = "framework";
      # profile = "orb";
      # profile = "nearmap";
      hostname = "danruto"; # hostname
      timezone = "Australia/Sydney"; # select timezone
      locale = "en_US.UTF-8"; # select locale

      # ----- USER SETTINGS ----- #
      username = "danruto"; # username
      macusername = "danny.sok"; # darwin username
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
          quickshell.overlays.default
          # neovim-nightly-overlay.overlays.default
          (final: prev: {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                # Workaround for bug #437058
                i3ipc = python-prev.i3ipc.overridePythonAttrs (oldAttrs: {
                  doCheck = false;
                  checkPhase = ''
                    echo "Skipping pytest in Nix build"
                  '';
                  installCheckPhase = ''
                    echo "Skipping install checks in Nix build"
                  '';
                });
              })
            ];
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
          quickshell.overlays.default
          noctalia.overlays.default
          (final: prev: {
            zjstatus = zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                # Workaround for bug #437058
                i3ipc = python-prev.i3ipc.overridePythonAttrs (oldAttrs: {
                  doCheck = false;
                  checkPhase = ''
                    echo "Skipping pytest in Nix build"
                  '';
                  installCheckPhase = ''
                    echo "Skipping install checks in Nix build"
                  '';
                });
              })
            ];
          })
        ];
      };

      # configure lib
      lib = nixpkgs.lib;

      commonSpecialArgs = {
        inherit username;
        inherit macusername;
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
        inherit helix-fork;
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
        inherit (inputs) mango;
        inherit (inputs) nixos-hardware;
        inherit (inputs) catppuccin;
        inherit (inputs) noctalia;
        inherit (inputs) quickshell;
        inherit (inputs) vicinae;
        inherit (inputs) dankMaterialShell;
      };

    in
    {
      nixosConfigurations = {
        system = lib.nixosSystem {
          # system = "x86_64-linux";
          inherit system;
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
              home-manager.users.${macusername} = import (./. + "/profiles" + ("/" + profile) + "/home.nix");

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
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    blocklist-hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    helix-fork = {
      url = "github:gj1118/helix";
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
    mango.url = "github:DreamMaoMao/mango";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    fw-ectool = {
      url = "github:tlvince/ectool.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.3.0";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin.url = "github:catppuccin/nix";
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
    };

    # Mac inputs
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
