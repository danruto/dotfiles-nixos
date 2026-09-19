{ pkgs, pkgs-unstable, lib, config, ... }:
let

  # My shell aliases
  myAliases = {
    ls = "eza --icons -l -T -L=1";
    cat = "bat";
    fd = "fd -Lu";
    # zj = "zellij --layout compact";
    zj = "zellij";
    zjp = "zellij a personal";
    # nixos-rebuild = "systemd-run --no-ask-password --uid=0 --system --scope -p MemoryLimit=16000M -p CPUQuota=60% nixos-rebuild";
    # home-manager = "systemd-run --no-ask-password --uid=1000 --user --scope -p MemoryLimit=16000M -p CPUQuota=60% home-manager";
    norb = "sudo nixos-rebuild switch --flake .#system";
    hmr = "home-manager switch -b backup --flake .#user";
    ncu = "sudo nix-channel --update";
    ncl = "sudo nix-channel --list";
    nu = "nix flake update";
    nua = "nix flake update --access-tokens \"github.com=$(gh auth token)\"";
    nuh = "nix flake update && hmr";
    ncg = "sudo nix-collect-garbage && sudo nix-collect-garbage -d && sudo find /nix/var/nix/gcroots/auto -mindepth 1 -delete && sudo nix-collect-garbage && sudo nix-collect-garbage -d";

    # Alias for copying over flakes for new projects
    newgo = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/go.nix flake.nix";
    newrs = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/rust.nix flake.nix";
    newrsn = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/rust-nightly.nix flake.nix";
    newts = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/ts.nix flake.nix";
    newpy = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/python.nix flake.nix";
    newzig = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/zig.nix flake.nix";
    newdn = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/dotnet.nix flake.nix";

    # Unlock GPG key by performing a dummy sign
    gpgu = "gpg --sign -o /dev/null /dev/null";

    # Git worktree aliases
    gwt = "git worktree";
    gwta = "git worktree add";
    gwtl = "git worktree list";
    gwtr = "git worktree remove";
    gwtm = "git worktree move";
    gwtp = "git worktree prune";

    # Git worktree with new branch: gwtab <path> <branch-name>
    gwtab = "git worktree add -b";

    # Git worktree with existing branch: gwtae <path> <existing-branch>
    gwtae = "git worktree add";
  };
in
{
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    LESSCHARSET = "utf-8";
  };

  programs.fish = {
    enable = true;
    shellAliases = myAliases;
    functions = {
      claude-healix = {
        description = "Run claude with the Healix org subscription config dir";
        body = "CLAUDE_CONFIG_DIR=$HOME/.claude-healix claude $argv";
      };
      # Generic agent sandbox: cwd (+ $sbx_binds) writable, rest of $HOME read-only,
      # ssh/gnupg/aws hidden, network ON. Works for any CLI: sbx opencode / sbx codex / ...
      # ponytail: net stays on so agents can reach their API; for egress control use gVisor.
      sbx = {
        description = "Sandbox a command with bubblewrap (cwd writable, HOME read-only, net on)";
        body = ''
          if test (count $argv) -eq 0
              echo "usage: sbx <command> [args...]" >&2
              echo "  extra writable dirs: set -x sbx_binds ~/.codex ~/.config/opencode" >&2
              return 2
          end
          if not type -q bwrap
              echo "sbx: bubblewrap (bwrap) not available on this host" >&2
              return 1
          end
          set -l binds --bind $PWD $PWD
          for d in $sbx_binds
              set -a binds --bind $d $d
          end
          bwrap \
              --die-with-parent --unshare-pid --unshare-uts --unshare-ipc \
              --proc /proc --dev /dev --tmpfs /tmp \
              --ro-bind /nix /nix \
              --ro-bind-try /usr /usr \
              --ro-bind-try /bin /bin \
              --ro-bind-try /lib /lib \
              --ro-bind-try /lib64 /lib64 \
              --ro-bind-try /opt /opt \
              --ro-bind-try /etc /etc \
              --ro-bind-try /run /run \
              --ro-bind $HOME $HOME \
              --tmpfs $HOME/.ssh --tmpfs $HOME/.gnupg --tmpfs $HOME/.aws \
              $binds \
              --chdir $PWD \
              -- $argv
        '';
      };
    };
    interactiveShellInit = ''
      set fish_greeting
      set -gx GPG_TTY (tty)

      # Writable dirs for the sbx agent sandbox (each agent persists its own state)
      set -gx sbx_binds $HOME/.codex $HOME/.claude
      if type -q gpg-connect-agent
          gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
      end

      # iris execs itself over the shell and runs fish in its own inner pty,
      # which hides the agent process (and its OSC titles) from herdr's pane —
      # agents then never appear in herdr's sidebar. Skip it in herdr panes.
      if type -q iris; and not set -q HERDR_ENV
          iris init fish | source
      end
    '';
  };

  programs.zsh = {
    enable = false;
    shellAliases = myAliases;
  };

  programs.eza.enable = true;

  home.packages = with pkgs; [
    fd
    starship
    fish
    jq
    yq-go
    zk
    tabiew
  ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.bubblewrap;

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
      # scripts/theme-render rewrites this theme on every switch.
      color_theme = lib.mkForce "runtime";
    };
  };

  xdg.configFile."btop/themes/runtime.theme".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.xdg.stateHome}/theme/current/btop.theme";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      load_dotenv = true;
    };
  };

  programs.starship.enableFishIntegration = true;

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
    package = pkgs-unstable.zellij;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
