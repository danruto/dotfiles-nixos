#!/usr/bin/env bash

sketchybar --add item cpu right                       \
  --set cpu                                           \
    icon=$icon_cpu                                    \
    update_freq=5                                     \
    script="${PLUGINS_DIR}/cpu.sh"                    \
    click_script="open -a activity\ monitor"          \
