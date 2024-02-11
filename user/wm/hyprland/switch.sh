#!/usr/bin/env bash

# On lid close docked state, disable laptop monitor
# and enable only external
if grep open /proc/acpi/button/lid/LID0/state; then
	hyprctl keyword monitor "DP-3, preferred, 0x0, 1"
else
	if [[ $(hyprctl monitors | grep "Monitor" | wc -l) != 1 ]]; then
		hyprctl keyword monitor "eDP-1, disable"
	fi
fi
