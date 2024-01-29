#!/usr/bin/env bash

sketchybar                                                                  \
  --add item clock right                                                    \
  --set clock                                                               \
    icon=$icon_clock                                                        \
    icon.padding_left=10                                                    \
    label.padding_right=10                                                  \
    update_freq=1                                                           \
    script="${PLUGINS_DIR}/clock.sh"                                        \
