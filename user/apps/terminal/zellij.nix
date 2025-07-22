{ pkgs-unstable, ... }:
{
  home.file.".config/zellij/themes/lavi.kdl".source = ./configs/zellij/zellij-lavi.kdl;
  home.file.".config/zellij/config.kdl".source = ./configs/zellij/zellij.kdl;
  home.file.".config/zellij/layouts/default.kdl".text = ''
    layout {
        swap_tiled_layout name="vertical" {
            tab max_panes=5 {
                pane split_direction="vertical" {
                    pane
                    pane { children; }
                }
            }
            tab max_panes=8 {
                pane split_direction="vertical" {
                    pane { children; }
                    pane { pane; pane; pane; pane; }
                }
            }
            tab max_panes=12 {
                pane split_direction="vertical" {
                    pane { children; }
                    pane { pane; pane; pane; pane; }
                    pane { pane; pane; pane; pane; }
                }
            }
        }

        swap_tiled_layout name="horizontal" {
            tab max_panes=5 {
                pane
                pane
            }
            tab max_panes=8 {
                pane {
                    pane split_direction="vertical" { children; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                }
            }
            tab max_panes=12 {
                pane {
                    pane split_direction="vertical" { children; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                    pane split_direction="vertical" { pane; pane; pane; pane; }
                }
            }
        }

        swap_tiled_layout name="stacked" {
            tab min_panes=5 {
                pane split_direction="vertical" {
                    pane
                    pane stacked=true { children; }
                }
            }
        }

        swap_floating_layout name="staggered" {
            floating_panes
        }

        swap_floating_layout name="enlarged" {
            floating_panes max_panes=10 {
                pane { x "5%"; y 1; width "90%"; height "90%"; }
                pane { x "5%"; y 2; width "90%"; height "90%"; }
                pane { x "5%"; y 3; width "90%"; height "90%"; }
                pane { x "5%"; y 4; width "90%"; height "90%"; }
                pane { x "5%"; y 5; width "90%"; height "90%"; }
                pane { x "5%"; y 6; width "90%"; height "90%"; }
                pane { x "5%"; y 7; width "90%"; height "90%"; }
                pane { x "5%"; y 8; width "90%"; height "90%"; }
                pane { x "5%"; y 9; width "90%"; height "90%"; }
                pane focus=true { x 10; y 10; width "90%"; height "90%"; }
            }
        }

        swap_floating_layout name="spread" {
            floating_panes max_panes=1 {
                pane {y "50%"; x "50%"; }
            }
            floating_panes max_panes=2 {
                pane { x "1%"; y "25%"; width "45%"; }
                pane { x "50%"; y "25%"; width "45%"; }
            }
            floating_panes max_panes=3 {
                pane focus=true { y "55%"; width "45%"; height "45%"; }
                pane { x "1%"; y "1%"; width "45%"; }
                pane { x "50%"; y "1%"; width "45%"; }
            }
            floating_panes max_panes=4 {
                pane { x "1%"; y "55%"; width "45%"; height "45%"; }
                pane focus=true { x "50%"; y "55%"; width "45%"; height "45%"; }
                pane { x "1%"; y "1%"; width "45%"; height "45%"; }
                pane { x "50%"; y "1%"; width "45%"; height "45%"; }
            }
        }

        default_tab_template {

            children

            pane size=1 borderless=true {
                plugin location="file:${pkgs-unstable.zjstatus}/bin/zjstatus.wasm" {

                  format_left   "{mode} {tabs}"
                  format_center ""
                  format_right  "{pipe_zjstatus_hints}{datetime}#[bg=#6e5fb7,fg=#ffffff,bold] {session} "
                  format_space  ""

                  pipe_zjstatus_hints_format "{output} "

                  format_hide_on_overleath "true"

                  hide_frame_for_single_pane "false"
                  hide_frame_execpt_for_search "false"
                  hide_frame_except_for_fullscreen "false"
                  hide_frame_except_for_scroll "false"

                  border_enabled  "false"
                  border_char     "─"
                  border_format   "#[fg=#6C7086]"
                  border_position "top"

                  mode_locked      "#[bg=#6e5fb7,fg=#ffffff,bold] ❤ "
                  mode_normal      "#[bg=#aa87fe,fg=#3c01cd,bold] ❤ N "
                  mode_resize      "#[bg=#ff9969,fg=#7f3513,bold] ❤ R "
                  mode_pane        "#[bg=#9FFBB6,fg=#30563a,bold] ❤ P "
                  mode_move        "#[bg=#FFD896,fg=#905b00,bold] ❤ M "
                  mode_tab         "#[bg=#80BDFF,fg=#0051a8,bold] ❤ T "
                  mode_scroll      "#[bg=#412da2,fg=#c9c0ff,bold] ❤ SCROLL "
                  mode_search      "#[bg=#e28e00,fg=#ffe9c4,bold] ❤ SEARCH "
                  mode_entersearch "#[bg=#e28e00,fg=#ffe9c4,bold] ❤ ENTER SEARCH "
                  mode_renametab   "#[bg=#0051a8,fg=#80BDFF,bold] ❤ RENAME TAB "
                  mode_renamepane  "#[bg=#30563a,fg=#9FFBB6,bold] ❤ RENAME PANE "
                  mode_session     "#[bg=#FF87A5,fg=#7d001f,bold] ❤ SESSION "
                  mode_tmux        "#[bg=#c9c0ff,fg=#412da2,bold] ❤ TMUX "

                  tab_active              "#[bg=#0D1017,fg=#83a598,bold] {index} {name} "
                  tab_active_fullscreen   "#[bg=#0D1017,fg=#83a598,bold] {fullscreen_indicator} {index} {name} "
                  tab_active_sync         "#[bg=#0D1017,fg=#83a598,bold] {sync_indicator} {index} {name} "

                  tab_normal              "#[fg=#a89984,bold] {index} {name} "
                  tab_normal_fullscreen   "#[fg=#a89984,bold] {fullscreen_indicator} {index} {name} "
                  tab_normal_sync         "#[fg=#a89984,bold] {sync_indicator} {index} {name} "

                  tab_separator " "

                  tab_floating_indicator   "󰉈 "
                  tab_sync_indicator       "󰓦"
                  tab_fullscreen_indicator "󰊓"

                  tab_rename              "#[bg=#b4befe,fg=#1e1e2e,bold] {index} {name} {floating_indicator} "

                  tab_display_count         "9"
                  tab_truncate_start_format "#[fg=#a89984]  +{count}  "
                  tab_truncate_end_format   "#[fg=#a89984]   +{count} "

                  command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                  command_git_branch_format      "#[fg=blue] {stdout} "
                  command_git_branch_interval    "10"
                  command_git_branch_rendermode  "static"

                  datetime          "#[fg=#85e6cb,bg=#1f2430] {format} "
                  datetime_format   "%H:%M"
                  datetime_timezone "Australia/Sydney"
                }
            }
        }
    }
  '';

}


# format_left  "{mode} #[fg=#89B4FA,bg=#0a0e14,bold] {session}#[bg=#0a0e14]"
# format_center "{tabs}"
# format_right "{swap_layout}#[fg=#424554,bg=#0a0e14]::{datetime}"
# format_space "#[bg=#0a0e14]"
# mode_tmux          "#[bg=#ffc387] "
# mode_normal        "#[fg=#b8bb26,bold]{name}"
# mode_locked        "#[fg=#fb4934,bold]{name}"
# mode_resize        "#[fg=#fabd2f,bold]{name}"
# mode_pane          "#[fg=#d3869b,bold]{name}"
# mode_tab           "#[fg=#83a598,bold]{name}"
# mode_scroll        "#[fg=#8ec07c,bold]{name}"
# mode_session       "#[fg=#fe8019,bold]{name}"
# mode_move          "#[fg=#a89984,bold]{name}"
# tab_normal   "#[fg=#a89984,bold] {name}"
# tab_active   "#[fg=#83a598,bold] {name}"
# datetime_format   "%A, %d %b %Y %H:%M"
# mode_default_to_mode "tmux"
