#!/usr/bin/env bash

sketchybar --add item battery right          \
  --set battery                              \
        icon=$icon_bat_high                  \
        update_freq=1000                     \
        script="${PLUGINS_DIR}/battery.sh"