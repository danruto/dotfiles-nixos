#!/usr/bin/env bash

sketchybar --add item weather right                                         \
  --set weather                                                             \
    label.padding_right=10                                                  \
    update_freq=1800                                                        \
    script="${PLUGINS_DIR}/weather.sh"                                      \
    click_script="open https://wttr.in?format:%C+"                          
