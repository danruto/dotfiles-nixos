{
  description = "Danruto NixOS Configuration";

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, stylix, blocklist-hosts, rust-overlay, hyprland-plugins, nur, ... }@inputs:
  let
    # ---- SYSTEM SETTINGS ---- #
    system = "x86_64-linux"; # system arch
    hostname = "danruto"; # hostname
    # profile = "wsl"; # select a profile defined from my profiles directory
    # profile = "vm";
    profile = "vm-hypr";
    timezone = "Australia/Sydney"; # select timezone
    locale = "en_US.UTF-8"; # select locale

    # ----- USER SETTINGS ----- #
    username = "danruto"; # username
    name = "Danny"; # name/identifier
    email = "danny@pixelbru.sh"; # email (used for certain configurations)
    dotfilesDir = "~/.dotfiles"; # absolute path of the local repo
    theme = "ayu-dark"; # selcted theme from my themes directory (./themes/)
    wm = "hyprland"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
    wmType = "wayland"; # x11 or wayland
    browser = "brave"; # Default browser; must select one from ./user/apps/browser/
    editor = "hx"; # Default editor;
    term = "alacritty"; # Default terminal command;
    font = "D2Coding"; # Selected font
    fontPkg = pkgs.d2coding; # Font package

    # create patched nixpkgs
    nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [];
    };

    # configure pkgs
    pkgs = import nixpkgs-patched {
      inherit system;
      # inherit nixpkgs-unstable;

      config = { allowUnfree = true;
                 allowUnfreePredicate = (_: true); };
      overlays = [ 
        rust-overlay.overlays.default 
        nur.overlay
        (_final: prev: {
          unstable = import nixpkgs-unstable {
            inherit (prev) system;
            config = { allowUnfree = true;
                       allowUnfreePredicate = (_: true); };
          };
        })
      ];
    };

    # configure lib
    lib = nixpkgs.lib;

  in {
    homeConfigurations = {
      user = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ (./. + "/profiles"+("/"+profile)+"/home.nix") ]; # load home.nix from selected PROFILE
          extraSpecialArgs = {
            # pass config variables from above
            inherit username;
            inherit name;
            inherit hostname;
            inherit profile;
            inherit email;
            inherit dotfilesDir;
            inherit theme;
            inherit font;
            inherit fontPkg;
            inherit wm;
            inherit wmType;
            inherit browser;
            inherit editor;
            inherit term;
            inherit (inputs) stylix;
            inherit (inputs) hyprland-plugins;
            inherit (inputs) nixos-wsl;
            channels = { inherit nixpkgs nixpkgs-unstable; };
          };
      };
    };
    nixosConfigurations = {
      system = lib.nixosSystem {
        inherit system;
        modules = [ 
          # load configuration.nix from selected PROFILE
          (./. + "/profiles"+("/"+profile)+"/configuration.nix") 
        ]; 
        specialArgs = {
          # pass config variables from above
          inherit username;
          inherit name;
          inherit hostname;
          inherit timezone;
          inherit locale;
          inherit theme;
          inherit font;
          inherit fontPkg;
          inherit wm;
          inherit (inputs) stylix;
          inherit (inputs) blocklist-hosts;
          inherit (inputs) nixos-wsl;
          channels = { inherit nixpkgs nixpkgs-unstable; };
        };
      };
    };
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nur.url = "github:nix-community/NUR";
    blocklist-hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      flake = false;
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    fw-ectool = {
        url = "github:tlvince/ectool.nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
