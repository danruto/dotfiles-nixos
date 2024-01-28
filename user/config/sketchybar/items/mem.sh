#!/usr/bin/env bash

sketchybar --add item mem right                                             \
  --set mem                                                                 \
    icon.padding_left=10                                                    \
    label.padding_left=10                                                   \
    label.padding_right=10                                                  \
    update_freq=5                                                           \
    script="${PLUGINS_DIR}/top.sh"                                          \
    click_script="open -a activity\ monitor"                                \
