#!/usr/bin/env bash

USED=$(top -l1 | awk '/PhysMem/ {print $2}')
FREE=$(top -l1 | awk '/PhysMem/ {print $6}')

sketchybar --set $NAME label="$FREE" icon="" drawing=on
