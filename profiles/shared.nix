{ pkgs, ... }: {
  home.file.".config/zellij/config.kdl".source = ../user/config/zellij.kdl;
  home.file.".config/zellij/layouts/default.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                  format_left  "{mode} #[fg=#89B4FA,bg=#0a0e14,bold] {session}#[bg=#0a0e14] {tabs}"
                  format_right "{command_kubectx}#[fg=#424554,bg=#0a0e14]::{datetime}"
                  format_space "#[bg=#0a0e14]"

                  hide_frame_for_single_pane "true"
                  border_enabled  "false"

                  mode_tmux          "#[bg=#ffc387] "
                  mode_normal        "#[fg=#b8bb26,bold]{name}"
                  mode_locked        "#[fg=#fb4934,bold]{name}"
                  mode_resize        "#[fg=#fabd2f,bold]{name}"
                  mode_pane          "#[fg=#d3869b,bold]{name}"
                  mode_tab           "#[fg=#83a598,bold]{name}"
                  mode_scroll        "#[fg=#8ec07c,bold]{name}"
                  mode_session       "#[fg=#fe8019,bold]{name}"
                  mode_move          "#[fg=#a89984,bold]{name}"

                  tab_normal   "#[fg=#a89984,bold] {name}"
                  tab_active   "#[fg=#83a598,bold] {name}"
                  mode_default_to_mode "tmux"

                  tab_normal               "#[fg=#6C7086,bg=#0a0e14] {index} {name} {fullscreen_indicator}{sync_indicator}{floating_indicator}"
                  tab_active               "#[fg=#e6b450,bg=#0a0e14,bold,italic] {index} {name} {fullscreen_indicator}{sync_indicator}{floating_indicator}"
                  tab_fullscreen_indicator "□ "
                  tab_sync_indicator       "  "
                  tab_floating_indicator   "󰉈 "

                  datetime          "#[fg=#85e6cb,bg=#1f2430] {format} "
                  datetime_format   "%A, %d %b %Y %H:%M"
                  datetime_timezone "Australia/Sydney"
                }
            }
        }
    }
  '';

  home.sessionVariables = {
    EDITOR = "hx";
  };

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;
}
