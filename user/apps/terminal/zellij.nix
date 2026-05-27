{ pkgs, pkgs-unstable, lib, ... }:
{
  home.file.".config/zellij/themes/lavi.kdl".source = ./configs/zellij/zellij-lavi.kdl;
  home.file.".config/zellij/config.kdl".source = ./configs/zellij/zellij.kdl;
  home.file.".config/zellij/plugins/zjsb.wasm".source =
    "${pkgs-unstable.zjsb}/share/zellij/plugins/zjsb.wasm";

  home.file.".config/zellij/layouts/zjsb.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file:~/.config/zellij/plugins/zjsb.wasm" {
                    mode "bar"
                    install_claude_hooks "true"
                    // Options: default | catppuccin-mocha | catppuccin-latte | gruvbox-dark | gruvbox-light
                    theme "ayu-dark"
                    // Sydney: +10:00 AEST / +11:00 AEDT — flip on DST transitions.
                    clock_tz_offset "+10:00"
                    // TEMP — capture tab/pane event ordering for alt-l bouncing repro. Remove after diagnosis.
                    debug_events "true"
                }
            }
        }
    }
  '';

  # Pre-grant zellij plugin permissions for zjsb so the first launch on a
  # fresh host doesn't prompt. Create-if-missing: leaves any user-granted
  # entry alone, and after first run zellij owns the file. Permission set
  # mirrors zjsb/src/main.rs::request_permission (install_claude_hooks adds
  # RunCommands; WebAccess only when OTEL http is on — not declared here).
  home.activation.zjsbZellijPerms =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      perms_file="''${HOME}/.cache/zellij/permissions.kdl"
      plugin_path="''${HOME}/.config/zellij/plugins/zjsb.wasm"
      mkdir -p "$(dirname "$perms_file")"
      if [ ! -f "$perms_file" ] || ! grep -qF "\"$plugin_path\"" "$perms_file"; then
        {
          [ -f "$perms_file" ] && cat "$perms_file"
          cat <<EOF
      "$plugin_path" {
          ReadApplicationState
          ChangeApplicationState
          OpenTerminalsOrPlugins
          ReadCliPipes
          RunCommands
      }
      EOF
        } > "$perms_file.zjsb-new"
        mv -f "$perms_file.zjsb-new" "$perms_file"
      fi
    '';
}
