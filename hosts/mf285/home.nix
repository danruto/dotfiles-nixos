{ config, lib, pkgs, pkgs-unstable, herdr, ... }:

{
  home.username = "danruto";
  home.homeDirectory = "/home/danruto";

  imports = [
    ../shared.nix
    ../../user/shell/sh.nix
    ../../user/shell/tui.nix
    ../../user/apps/git/git.nix
    ../../user/lang/cc/cc.nix
    ../../user/lang/typescript/typescript.nix
    ../../user/lang/lua/lua.nix
    ../../user/lang/nix/nix.nix
    ../../user/lang/shell/shell.nix
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/curl.nix
    ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/terminal/foot.nix
    ../../user/wm/niri/niri.nix
    ../../user/apps/ai/llm.nix
    ../../user/apps/browser/ff.nix
    ../../user/apps/fileman/elio.nix
    ../../user/apps/gui/gui.nix
    ../../user/apps/networking/wireguard.nix
    ../../user/apps/networking/ssh.nix
    ../../user/apps/security/1password.nix
    ../../user/apps/security/protonvpn.nix
    ../../user/hardware/keyboard.nix
  ];

  programs.niri.settings = {
    input.tablet.map-to-output = lib.mkForce null;
    input.touch.map-to-output = lib.mkForce null;
    outputs = lib.mkForce {
      "Beihai Century Joint Innovation Technology Co.,Ltd X340 PRO EVO 0000000000000" = {
        scale = 1.0;
        mode = {
          width = 3440;
          height = 1440;
          refresh = 59.999;
        };
        position = {
          x = 0;
          y = 0;
        };
      };
    };
  };

  home.packages = with pkgs; [
    diff-so-fancy
    git
    fakeroot
    (symlinkJoin {
      name = "yaak-wrapped";
      paths = [ yaak ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/yaak-app \
          --set WEBKIT_DISABLE_DMABUF_RENDERER 0 \
          --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
          --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}" \
          --prefix XDG_DATA_DIRS : "${gtk4}/share/gsettings-schemas/${gtk4.name}" \
          --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share" \
          --set GIO_MODULE_DIR "${glib-networking}/lib/gio/modules/"
      '';
    })
  ];
  home.stateVersion = "26.05";

  systemd.user.startServices = "sd-switch";

  systemd.user.services.agent-awake = {
    Unit.Description = "Keep the PC awake while an AI agent is working";
    Service = {
      ExecStart = "${pkgs.writeShellApplication {
        name = "agent-awake";
        runtimeInputs = [
          herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.jq
          pkgs.systemd
        ];
        text = ''
          pid=""
          while :; do
            if herdr agent list 2>/dev/null | jq -e '.result.agents | any(.agent_status == "working")' >/dev/null; then
              if [ -z "$pid" ]; then
                systemd-inhibit --what=idle --who=agent-awake --why="AI agent working" sleep infinity &
                pid=$!
              fi
            elif [ -n "$pid" ]; then
              kill "$pid"
              pid=""
            fi
            sleep 60
          done
        '';
      }}/bin/agent-awake";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    settings = {
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
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
