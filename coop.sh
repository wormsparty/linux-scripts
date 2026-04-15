#!/bin/bash

#
# This scripts allows to run the same executable twice, and blacklist the joystick assigned to the other window.
# This supposes the executable can be run in windowed mode. If not, you may want to wrap it in a "weston" window.
#
# Since we expect to have a windowed mode, we can't really expect the windows to be borderless, but it's not impossible.
# For Gnome you can install the "Hide top bar" extension. If you have access to the code of an SDL application,
# you could hide the border with SDL_SetWindowBordered(window, 0);
# 
# Use win+left and win+right to move the windows to use the left and right half, they may both start at the same position
# You can use Alt+F7 to move your windows to the desired positions and Alt+F8 to resize them.
#
# Let's start by listing the joysticks, we expect to have exactly 2.
# It doesn't matter which one we attach to which window, since the executable is strictly
# the same for both, it will have the same configuration on startup.
#
if [ $# -eq 0 ]; then
	echo "$0 executable (..args)"
 	exit 1
fi

CONTROLLER_LIST=$(ls -l /dev/input/by-path/ | grep joystick |  awk '{gsub("-joystick", ""); gsub("-event", ""); print $9}' | uniq)
CONTROLLER_COUNT=$(echo "$CONTROLLER_LIST" | sed '/^\s*$/d' | wc -l)

if [ $CONTROLLER_COUNT -ne 2 ]; then
	echo "Found $CONTROLLER_COUNT joysticks, please have exactly 2 plugged in."
	zenity --error --text="Found $CONTROLLER_COUNT joysticks, please have exactly 2 plugged in."
	exit 1
fi

CONTROLLER_1=$(echo "$CONTROLLER_LIST" | sed -n '1 p')
CONTROLLER_2=$(echo "$CONTROLLER_LIST" | sed -n '2 p')
BLACKLIST_1=$(ls -l /dev/input/by-path/ | grep joystick | grep -wv "$CONTROLLER_1" | awk '{print "--blacklist=/dev/input/by-path/" $9;}')
BLACKLIST_2=$(ls -l /dev/input/by-path/ | grep joystick | grep -wv "$CONTROLLER_2" | awk '{print "--blacklist=/dev/input/by-path/" $9;}')

# Run the executable twice. 
firejail --noprofile $BLACKLIST_1 "$@" &
sleep 1
firejail --noprofile $BLACKLIST_2 "$@" &
