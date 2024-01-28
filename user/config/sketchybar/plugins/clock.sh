#!/usr/bin/env bash

# sketchybar -m set $NAME label "$(date '+%y/%m/%d %R')"
D=$(date '+%r, %d %b')
sketchybar --set $NAME label="$D"

