{
  description = "Danruto NixOS Configuration";

  outputs =
    { self
    , nixpkgs
    , home-manager
    , ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      overlays = import ./lib/overlays.nix { inherit inputs; };

      # Instantiate nixpkgs ONCE per system (avoid per-call fragmentation).
      pkgsBySystem = lib.genAttrs systems (system:
        import ./lib/mkPkgs.nix { inherit inputs system overlays; });

      # Identity defaults; per-host args override these.
      defaults = {
        username = "danruto";
        # email = "danny@pixelbru.sh";
        email = "1270619+danruto@users.noreply.github.com";
        theme = "ayu-dark";
        timezone = "Australia/Sydney";
        locale = "en_US.UTF-8";
        wm = "hyprland";
        wmType = "wayland";
        editor = "hx";
      };

      # One merged passthrough set — every input a host might want. Nix is lazy,
      # so unused inputs on a given host cost nothing.
      baseSpecialArgs = {
        inherit (inputs)
          blocklist-hosts neovim-nightly-overlay wanderer fff crit cull-src
          nixos-wsl hyprland-plugins niri mango nixos-hardware catppuccin
          helium dms dms-plugin-diskusage helix helix-fork;
      };

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs lib pkgsBySystem overlays defaults baseSpecialArgs home-manager;
        darwin = inputs.darwin;
      };

      mkHome = import ./lib/mkHome.nix {
        inherit inputs lib pkgsBySystem defaults baseSpecialArgs home-manager;
      };
    in
    {
      nixosConfigurations = {
        framework = mkSystem {
          hostname = "framework";
          system = "x86_64-linux";
          extraModules = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
        };
        wsl = mkSystem { hostname = "wsl"; system = "x86_64-linux"; };
        orb = mkSystem { hostname = "orb"; system = "aarch64-linux"; };
        vm = mkSystem { hostname = "vm"; system = "x86_64-linux"; };
        vm-hypr = mkSystem { hostname = "vm-hypr"; system = "x86_64-linux"; };
        vm-i3 = mkSystem { hostname = "vm-i3"; system = "x86_64-linux"; };
        vm-niri = mkSystem { hostname = "vm-niri"; system = "x86_64-linux"; };
        vm-sway = mkSystem { hostname = "vm-sway"; system = "x86_64-linux"; };
      };

      darwinConfigurations = {
        work = mkSystem { hostname = "work"; system = "aarch64-darwin"; platform = "darwin"; };
        work-x86 = mkSystem { hostname = "work"; system = "x86_64-darwin"; platform = "darwin"; };
        work2 = mkSystem { hostname = "work2"; system = "aarch64-darwin"; platform = "darwin"; };
        work2-x86 = mkSystem { hostname = "work2"; system = "x86_64-darwin"; platform = "darwin"; };
        nearmap = mkSystem { hostname = "nearmap"; system = "aarch64-darwin"; platform = "darwin"; };
        nearmap-x86 = mkSystem { hostname = "nearmap"; system = "x86_64-darwin"; platform = "darwin"; };
      };

      homeConfigurations =
        let
          orbArch = mkHome { hostname = "orb-arch"; system = "aarch64-linux"; };
        in
        {
          "danruto@orb-arch" = orbArch;
          # Kept for `make hm/switch` and vm/bootstrap/2 which reference .#user.
          user = orbArch;
        };
    };

  inputs = {
    # Global shared inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zjsb = {
      url = "github:danruto/pb-zjsb";
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
    helium.url = "github:vikingnope/helium-browser-nix-flake";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-diskusage = {
      url = "github:alcxyz/DankDiskUsage";
      flake = false;
    };

    wanderer = {
      url = "github:fonger900/wanderer";
      flake = false;
    };

    fff = {
      url = "github:dmtrKovalenko/fff";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    crit = {
      url = "github:tomasz-tomczyk/crit";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    cull-src = {
      url = "github:legostin/cull";
      flake = false;
    };

    # Mac inputs
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
