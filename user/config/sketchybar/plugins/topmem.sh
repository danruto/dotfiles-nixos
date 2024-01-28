#!/usr/bin/env bash

TOPMEM=$(ps axo "rss,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0fMB\n", $1 / 1024}' | sed -e 's/com.apple.//g')
MEM=$(echo $TOPMEM | sed -nr 's/([^MB]+).*/\1/p')

sketchybar --set $NAME label="$TOPMEM" icon="" drawing=on
