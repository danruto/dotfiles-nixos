#!/usr/bin/env bash

sketchybar                                                \
  --add event window_focus                                \
  --add event title_change                                \
  --add item window_title left                            \
  --set window_title                                      \
    label.padding_right=10                                \
    script="${PLUGINS_DIR}/window_title.sh"               \
    drawing=on                                            \
    icon.drawing=off                                      \
    label.background.drawing=on                           \
  --subscribe window_title                                \
    window_focus                                          \
    front_app_switched                                    \
    space_change                                          \
    title_change
