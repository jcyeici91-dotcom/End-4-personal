#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/mangowc_mode"
mkdir -p "$(dirname "$STATE_FILE")"

PROFILE_LINK="$HOME/.config/hypr/hyprland/profile.conf"
NORMAL="$HOME/.config/hypr/hyprland/profiles/normal.conf"
MANGO="$HOME/.config/hypr/hyprland/profiles/mango.conf"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 "Hyprland" "$1" || true; }

MODE="off"
[[ -f "$STATE_FILE" ]] && MODE="$(cat "$STATE_FILE" 2>/dev/null || echo off)"

enable_mangowc() {
  ln -sfn "$MANGO" "$PROFILE_LINK"
  hyprctl reload >/dev/null
}

disable_mangowc() {
  ln -sfn "$NORMAL" "$PROFILE_LINK"
  hyprctl reload >/dev/null
}

if [[ "$MODE" == "on" ]]; then
  disable_mangowc
  echo "off" > "$STATE_FILE"
  notify "Perfil: Normal"
else
  enable_mangowc
  echo "on" > "$STATE_FILE"
  notify "Perfil: Mango"
fi

