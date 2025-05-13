{ pkgs, ... }: {
  home.file.".config/zellij/config.kdl".source = ../user/config/zellij.kdl;
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
                plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                  format_left  "{mode} #[fg=#89B4FA,bg=#0a0e14,bold] {session}#[bg=#0a0e14]"
                  format_center "{tabs}"
                  format_right "{swap_layout}#[fg=#424554,bg=#0a0e14]::{datetime}"
                  format_space "#[bg=#0a0e14]"
                  format_hide_on_overleath "true"

                  hide_frame_for_single_pane "true"
                  border_enabled  "false"
                  border_char     "─"
                  border_format   "#[fg=#6C7086]"
                  border_position "top"

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

                  command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                  command_git_branch_format      "#[fg=blue] {stdout} "
                  command_git_branch_interval    "10"
                  command_git_branch_rendermode  "static"


                  datetime          "#[fg=#85e6cb,bg=#1f2430] {format} "
                  datetime_format   "%A, %d %b %Y %H:%M"
                  datetime_timezone "Australia/Sydney"
                }
            }

        }
    }
  '';

  # font-family = "Departure Mono"
  home.file.".config/ghostty/config".text = ''
    font-family = "Iosevka Comfy"
    font-size = 12

    macos-option-as-alt = left
    keybind = alt+left=unbind
    keybind = alt+right=unbind
  '';

  home.sessionVariables = {
    EDITOR = "hx";
  };

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;
}
