#!/usr/bin/env bash

SPACE_ICONS=($icon_slack $icon_web $icon_git $icon_music "V" "VI" "VII" "VIII" "VIII")

for ii in "${!SPACE_ICONS[@]}"
do
  sid=$(($ii+1))
  sketchybar --add space      space.$sid left                      \
             --set space.$sid associated_space=$sid                \
                              icon=${SPACE_ICONS[ii]}              \
                              icon.padding_left=22                 \
                              icon.padding_right=22                \
                              icon.highlight_color=$c_icon_hl      \
                              background.padding_left=-8           \
                              background.padding_right=-8          \
                              background.height=26                 \
                              background.corner_radius=9           \
                              background.color=$c_space_bg         \
                              background.drawing=on                \
                              label.drawing=off                    \
                              click_script="$SPACE_CLICK_SCRIPT"
done

sketchybar   --add item       separator left                          \
             --set separator  icon=                                  \
                              icon.font="$default_icon_font"          \
                              background.padding_left=26              \
                              background.padding_right=15             \
                              label.drawing=off                       \
                              icon.color=$c_icon
