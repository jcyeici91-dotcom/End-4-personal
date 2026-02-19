#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "Use: $0 /path/to/wallpaper [shader_path]"
	exit 1
fi

WALLPAPER="$1"
SHADER="$2"

pkill -x "mpvpaper" 2>/dev/null

MPV_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 load-scripts=no input-ipc-server=/tmp/ambxst_mpv_socket"

if [ -n "$SHADER" ] && [ -f "$SHADER" ]; then
	MPV_OPTS="$MPV_OPTS glsl-shaders=$SHADER"
fi

nohup mpvpaper -o "$MPV_OPTS" ALL "$WALLPAPER" >/tmp/mpvpaper.log 2>&1 &
