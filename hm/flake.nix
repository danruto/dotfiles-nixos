{
  description = "Danruto Nix Home manager for VM setup on Apple Silicon";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nur.url = "github:nix-community/NUR";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    helix-fork = {
      url = "github:gj1118/helix";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , neovim-nightly-overlay
    , nur
    , rust-overlay
    , zjstatus
    , helix-fork
    , quickshell
    , noctalia
    , ...
    }:
    let
      system = "aarch64-linux";
      overlays = [
        neovim-nightly-overlay.overlays.default
        rust-overlay.overlays.default
        nur.overlays.default
        (final: prev: {
          zjstatus = zjstatus.packages.${prev.system}.default;
        })
      ];

      # Set up custom Home Manager configurations
      homeConfigurations = {
        danruto = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          # Pass the necessary overlays
          modules = [
            {
              nixpkgs.overlays = overlays;
              # You can include an additional home.nix for the actual configurations
              imports = [ ./home.nix ]; # Import home.nix configurations
            }
          ];

          extraSpecialArgs = {
            inherit neovim-nightly-overlay;
            inherit nur;
            inherit rust-overlay;
            inherit zjstatus;
            inherit helix-fork;
            inherit quickshell;
            inherit noctalia;

            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              overlays = overlays;
            };

            name = "Danny Sok";
            email = "danny.sok@nearmap.com";
          };
        };
      };
    in
    {
      # Expose homeConfigurations to be usable in your flake.
      inherit homeConfigurations;
    };
}
