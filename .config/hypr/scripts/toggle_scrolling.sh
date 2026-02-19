#!/bin/bash

CURRENT_LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')

if [ "$CURRENT_LAYOUT" = "scrolling" ]; then
 # SI ESTÁ ACTIVADO EL SCROLLING > CAMBIA A DWINDLE 
    hyprctl keyword general:layout dwindle
    notify-send "Hyprland" "Modo Scrolling DESACTIVADO" -i window-new
else
    # SI ESTÁ EN NORMAL> CAMBIA A SCROLLING
    hyprctl keyword general:layout scrolling
    notify-send "Hyprland" "Modo Scrolling ACTIVADO" -i view-list-icons
fi
