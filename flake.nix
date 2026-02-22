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
    , mango
    , dankMaterialShell
    , helium
    , ...
    }@inputs:
    let
      # Load local config if it exists
      localConfig =
        if builtins.pathExists ./config.local.nix
        then import ./config.local.nix
        else { };

      # Default configuration
      defaultConfig = {
        # ---- SYSTEM SETTINGS ---- #
        profile = "framework";
        hostname = "danruto";
        timezone = "Australia/Sydney";
        locale = "en_US.UTF-8";

        # ----- USER SETTINGS ----- #
        username = "danruto";
        email = "danny@pixelbru.sh";
        theme = "ayu-dark";
        wm = "hyprland";
        wmType = "wayland";
        editor = "hx";
        # fontPkg will be set per-system below
      };

      # Merge local config with defaults (local overrides defaults)
      config = defaultConfig // localConfig;

      # Extract variables for backward compatibility
      inherit (config) profile hostname timezone locale username email theme wm wmType editor;

      # Helper function to create system-specific configuration
      mkSystemConfig = system:
        let
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

          fontPkg = pkgs.d2coding;
        in
        {
          inherit pkgs pkgs-unstable fontPkg;
        };

      # configure lib
      lib = nixpkgs.lib;

      mkCommonSpecialArgs = { pkgs-unstable, fontPkg }: {
        inherit username;
        # inherit name;
        inherit hostname;
        inherit profile;
        inherit email;
        inherit theme;
        inherit fontPkg;
        inherit wm;
        inherit wmType;
        inherit editor;
        inherit helix;
        inherit helix-fork;
        inherit timezone;
        inherit locale;
        inherit pkgs-unstable;

        inherit (inputs) blocklist-hosts;
        inherit (inputs) neovim-nightly-overlay;
        inherit (inputs) wanderer;

        # channels = { inherit nixpkgs nixpkgs-unstable; };
      };

      mkWslSpecialArgs = { pkgs-unstable, fontPkg }: (mkCommonSpecialArgs { inherit pkgs-unstable fontPkg; }) // {
        inherit (inputs) nixos-wsl;
        # inherit inputs;
      };

      mkFwSpecialArgs = { pkgs-unstable, fontPkg }: (mkCommonSpecialArgs { inherit pkgs-unstable fontPkg; }) // {
        inherit (inputs) hyprland-plugins;
        inherit (inputs) niri;
        inherit (inputs) mango;
        inherit (inputs) nixos-hardware;
        inherit (inputs) catppuccin;
        inherit (inputs) noctalia;
        inherit (inputs) quickshell;
        inherit (inputs) dankMaterialShell;
        inherit (inputs) helium;
      };

      # Helper to create darwin configuration for any profile
      mkDarwinConfig = system: profile:
        let
          systemConfig = mkSystemConfig system;
        in
        darwin.lib.darwinSystem {
          inherit system;
          modules = [
            # load configuration.nix from selected PROFILE
            (./. + "/profiles" + ("/" + profile) + "/configuration.nix")
            home-manager.darwinModules.home-manager
            {
              nixpkgs.config = {
                allowUnfree = true;
                allowUnfreePredicate = (_: true);
                allowBroken = true;
              };
              nixpkgs.overlays = [
                rust-overlay.overlays.default
                nur.overlays.default
                quickshell.overlays.default
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import (./. + "/profiles" + ("/" + profile) + "/home.nix");
              home-manager.extraSpecialArgs = mkCommonSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; };
            }
          ];
          specialArgs = mkCommonSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; };
        };

    in
    {
      nixosConfigurations =
        let
          systemConfig = mkSystemConfig "x86_64-linux";
        in
        {
          system = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              # load configuration.nix from selected PROFILE
              (./. + "/profiles" + ("/" + profile) + "/configuration.nix")
              home-manager.nixosModules.home-manager
              {
                # Set nixpkgs config here instead of per-profile
                nixpkgs.config = {
                  allowUnfree = true;
                  allowUnfreePredicate = (_: true);
                  allowBroken = true;
                };
                nixpkgs.overlays = [
                  rust-overlay.overlays.default
                  nur.overlays.default
                  quickshell.overlays.default
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

                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.users.${username} = import (./. + "/profiles" + ("/" + profile) + "/home.nix");

                # Optionally, use home-manager.extraSpecialArgs to pass
                # arguments to home.nix
                home-manager.extraSpecialArgs = if (profile == "wsl") 
                  then mkWslSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; }
                  else mkFwSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; };
              }
            ];
            specialArgs = if (profile == "wsl")
              then mkWslSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; }
              else mkFwSpecialArgs { inherit (systemConfig) pkgs-unstable fontPkg; };
          };
        };

      darwinConfigurations = {
        # Generate configurations for all Darwin profiles on both architectures
        work = mkDarwinConfig "aarch64-darwin" "work";
        work-x86 = mkDarwinConfig "x86_64-darwin" "work";
        work2 = mkDarwinConfig "aarch64-darwin" "work2";
        work2-x86 = mkDarwinConfig "x86_64-darwin" "work2";
        nearmap = mkDarwinConfig "aarch64-darwin" "nearmap";
        nearmap-x86 = mkDarwinConfig "x86_64-darwin" "nearmap";
      };
    };

  inputs = {
    # Global shared inputs
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    # niri.url = "github:sodiboo/niri-flake";
    niri.url = "github:sodiboo/niri-flake/very-refactor";
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
    dankMaterialShell = {
      # url = "github:AvengeMedia/DankMaterialShell";
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium.url = "github:vikingnope/helium-browser-nix-flake";

    wanderer = {
      url = "github:fonger900/wanderer";
      flake = false;
    };

    # Mac inputs
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
