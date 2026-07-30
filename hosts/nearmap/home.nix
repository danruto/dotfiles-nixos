{ pkgs, wanderer, ... }:
let
  wanderer-pkg = pkgs.rustPlatform.buildRustPackage {
    pname = "wanderer";
    version = "0.2.0";
    src = wanderer;
    cargoLock.lockFile = "${wanderer}/Cargo.lock";
    nativeBuildInputs = [ ];
    buildInputs = [ ];
  };
in
{
  # Dev work happens in the VM, so this host keeps only the terminal spine:
  # shell, git, ssh, editors, and the tooling needed to edit this repo.
  # Deliberately not imported (see below for what each dropped):
  #   ../shared.nix          - ghostty/zellij/herdr configs are hand-managed now
  #   user/shell/tui.nix     - cli grab-bag; rg/lfk already come from brew
  #   user/apps/fileman/yazi.nix
  #   user/apps/terminal/curl.nix
  #   user/lang/{go,typescript} - toolchains live in the VM
  #   user/wm/miri           - replaced by rift, no longer installed
  imports = [
    ../../user/shell/sh.nix # Fish config
    ../../user/apps/git/git.nix # My git config
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/networking/ssh.nix
  ];

  home.packages = with pkgs; [
    # cachix
    diff-so-fancy
    git

    sops

    wanderer-pkg

    # cc-clip deps (clipboard image paste over SSH)
    xclip
    pngpaste
  ];
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Carried over from ../shared.nix, which this host no longer imports.
  home.sessionVariables = {
    EDITOR = "hx";
  };

  # home-manager owns ~/.ssh/config, so OrbStack's `orb` host has to be
  # included declaratively or it disappears on rebuild. OrbStack requires the
  # include to precede any Host block; home-manager emits includes first.
  programs.ssh.includes = [ "~/.orbstack/ssh/config" ];

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;

  # sh.nix aliases `cat = "bat"`, and bat came from the dropped tui.nix.
  programs.bat.enable = true;

  xdg = {
    enable = true;
  };

  programs.starship.enable = true;
  programs.starship.settings = {
    gcloud.disabled = true;
    kubernetes.disabled = false;
    git_branch.style = "242";
    directory.style = "bold blue dimmed";
    directory.truncate_to_repo = false;
    directory.truncation_length = 8;
    python.disabled = true;
    ruby.disabled = true;
    hostname.ssh_only = false;
    hostname.style = "bold green";
    memory_usage.disabled = false;
    memory_usage.threshold = -1;
  };
}
