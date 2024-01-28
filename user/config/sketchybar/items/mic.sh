#!/usr/bin/env bash

sketchybar --add item mic right                                             \
  --set mic                                                                 \
    update_freq=100                                                         \
    label.drawing=off                                                       \
    icon.font="${default_icon_font}"                                        \
    script="${PLUGINS_DIR}/mic.sh"                                          \
    click_script="${PLUGINS_DIR}/mic_click.sh"
