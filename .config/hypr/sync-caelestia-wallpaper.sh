#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Uso:
  sync-caelestia-wallpaper.sh --file <path>
  sync-caelestia-wallpaper.sh --random <dir>

NUEVO (sin cambiar wallpaper):
  sync-caelestia-wallpaper.sh --refresh
  sync-caelestia-wallpaper.sh --toggle light|dark
  sync-caelestia-wallpaper.sh --refresh --auto-mode

Opciones:
  --light | --dark              (cuando generas wal desde una imagen con --file/--random)
  --auto-mode                   (solo afecta a --refresh; decide prefer-light/dark por brillo)
  --no-wal
  --notify
  --no-smart
  --no-hypr
  --no-firefox
  --no-gtk
  --no-darkmode
  --no-kitty
  --restart-caelestia
EOF
}

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: falta el comando: $1"; exit 1; }; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

pick_random_wallpaper() {
  local dir="$1"
  dir="${dir/#\~/$HOME}"
  [[ -d "$dir" ]] || { echo "Error: no es un directorio: $dir"; exit 1; }

  local file
  file="$(find "$dir" -type f \( \
      -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \
    \) -print0 | shuf -z -n 1 | tr -d '\0')"

  [[ -n "${file:-}" ]] || { echo "Error: no encontré imágenes en: $dir"; exit 1; }
  printf '%s' "$file"
}

set_darkmode_preference() {
  local prefer="$1" # prefer-dark|prefer-light
  if have_cmd gsettings && gsettings writable org.gnome.desktop.interface color-scheme >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$prefer" >/dev/null 2>&1 || true
    echo "✓ System dark mode preference set to: $prefer"
  else
    echo "ℹ No pude setear color-scheme vía gsettings (schema no disponible)."
  fi
}

trigger_firefox() {
  if have_cmd pywalfox; then
    pywalfox update >/dev/null 2>&1 || true
    echo "✓ Firefox theme update triggered"
  else
    echo "ℹ pywalfox no encontrado (instala Pywalfox para Firefox)."
  fi
}

apply_gtk() {
  if have_cmd wal-gtk; then
    wal-gtk >/dev/null 2>&1 || true
    echo "✓ GTK theme update triggered"
  else
    echo "ℹ wal-gtk not found - install 'wal-gtk-theme-git' for GTK theme support"
  fi
}

reload_hyprland() {
  if have_cmd hyprctl; then
    hyprctl reload >/dev/null 2>&1 || true
    echo "✓ Hyprland configuration reloaded"
  else
    echo "ℹ hyprctl no encontrado; omitido."
  fi
}

reload_kitty() {
  if ! have_cmd kitty; then
    echo "ℹ kitty no encontrado; omitido."
    return 0
  fi

  local listen="${KITTY_LISTEN_ON:-}"
  if [[ -n "$listen" ]]; then
    local sock="${listen#unix:}"
    if [[ -S "$sock" ]]; then
      kitty @ --to "$listen" set-colors --all --configured ~/.cache/wal/colors-kitty.conf >/dev/null 2>&1 || true
      echo "✓ Kitty terminal colors reloaded"
      return 0
    fi
  fi

  if [[ -S "/tmp/kitty_pywal" ]]; then
    kitty @ --to "unix:/tmp/kitty_pywal" set-colors --all --configured ~/.cache/wal/colors-kitty.conf >/dev/null 2>&1 || true
    echo "✓ Kitty terminal colors reloaded"
    return 0
  fi

  if pgrep -x kitty >/dev/null 2>&1; then
    killall -SIGUSR1 kitty 2>/dev/null || true
    echo "✓ Kitty terminal colors reloaded"
    return 0
  fi

  echo "ℹ Kitty reload omitido (no hay instancias/socket activo)."
}

restart_caelestia_shell() {
  # En tu setup, Caelestia Shell corre bajo Quickshell como: `qs -c caelestia`
  # 1) Intento limpio por IPC (puede decir "No running instances" y no pasa nada)
  caelestia shell -k >/dev/null 2>&1 || true
  sleep 0.2

  # 2) Fallback: matar el proceso real si sigue vivo
  if pgrep -f 'qs -c caelestia' >/dev/null 2>&1; then
    pkill -f 'qs -c caelestia' >/dev/null 2>&1 || true
    sleep 0.2
  fi

  # 3) Arrancar de nuevo
  caelestia shell -d >/dev/null 2>&1 || true
  echo "✓ Caelestia shell restarted"
}

update_caelestia_wallpaper_reference() {
  local wp="$1"
  mkdir -p ~/.local/state/caelestia/wallpaper
  ln -sf "$wp" ~/.local/state/caelestia/wallpaper/current
  echo "$wp" > ~/.local/state/caelestia/wallpaper/path.txt
  echo "✓ Caelestia wallpaper reference updated"
}

apply_caelestia_scheme_from_wal() {
  local src="$HOME/.cache/wal/caelestia-scheme.json"
  local dst_dir="$HOME/.local/state/caelestia"
  local dst="$dst_dir/scheme.json"

  if [[ -f "$src" ]]; then
    mkdir -p "$dst_dir"
    cp "$src" "$dst"
    echo "✓ Caelestia colors updated"
  else
    echo "ℹ No existe $src (falta template/export de wal para Caelestia)."
  fi
}

# --------------------
# NUEVO: auto-detect prefer-light/dark desde wal cache
# --------------------
detect_prefer_scheme_from_wal() {
  local json="$HOME/.cache/wal/colors.json"
  local bg r g b brightness

  [[ -f "$json" ]] || return 1

  bg="$(grep -oP '"background"\s*:\s*"#\K[0-9A-Fa-f]{6}' "$json" | head -1 || true)"
  [[ -n "$bg" ]] || return 1

  r=$((16#${bg:0:2}))
  g=$((16#${bg:2:2}))
  b=$((16#${bg:4:2}))
  brightness=$(( (r + g + b) / 3 ))

  if (( brightness > 128 )); then
    printf '%s' "prefer-light"
  else
    printf '%s' "prefer-dark"
  fi
}

run_post_hooks() {
  # Aplicar a Caelestia el scheme generado por wal (si tu template lo produce)
  apply_caelestia_scheme_from_wal

  if [[ "$DO_GTK" -eq 1 ]]; then apply_gtk; fi
  if [[ "$DO_DARKMODE" -eq 1 ]]; then set_darkmode_preference "$PREFER_SCHEME"; fi
  if [[ "$DO_FIREFOX" -eq 1 ]]; then trigger_firefox; fi
  if [[ "$DO_HYPR" -eq 1 ]]; then reload_hyprland; fi
  if [[ "$DO_KITTY" -eq 1 ]]; then reload_kitty; fi
  if [[ "$RESTART_CAEL" -eq 1 ]]; then restart_caelestia_shell; fi
}

# --------------------
# Parse args
# --------------------
MODE=""
TARGET=""

DO_WAL=1
DO_NOTIFY=0
WALL_NO_SMART=0

DO_HYPR=1
DO_FIREFOX=1
DO_GTK=1
DO_DARKMODE=1
DO_KITTY=1
RESTART_CAEL=0

WAL_LIGHT=0
PREFER_SCHEME="prefer-dark"

# NUEVO:
REFRESH_ONLY=0
TOGGLE_MODE=""   # light|dark
AUTO_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) MODE="file"; TARGET="${2:-}"; shift 2 ;;
    --random) MODE="random"; TARGET="${2:-}"; shift 2 ;;

    --refresh) REFRESH_ONLY=1; shift ;;
    --toggle) TOGGLE_MODE="${2:-}"; shift 2 ;;
    --auto-mode) AUTO_MODE=1; shift ;;

    --light) WAL_LIGHT=1; PREFER_SCHEME="prefer-light"; shift ;;
    --dark)  WAL_LIGHT=0; PREFER_SCHEME="prefer-dark"; shift ;;

    --no-wal) DO_WAL=0; shift ;;
    --notify) DO_NOTIFY=1; shift ;;
    --no-smart) WALL_NO_SMART=1; shift ;;

    --no-hypr) DO_HYPR=0; shift ;;
    --no-firefox) DO_FIREFOX=0; shift ;;
    --no-gtk) DO_GTK=0; shift ;;
    --no-darkmode) DO_DARKMODE=0; shift ;;
    --no-kitty) DO_KITTY=0; shift ;;
    --restart-caelestia) RESTART_CAEL=1; shift ;;

    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1"; usage; exit 1 ;;
  esac
done

need_cmd caelestia

# Validación:
# Si NO es refresh/toggle, entonces sí exijo --file o --random
if [[ "$REFRESH_ONLY" -eq 0 && -z "${TOGGLE_MODE:-}" ]]; then
  [[ -n "${MODE:-}" ]] || { usage; exit 1; }
fi

# --------------------
# NUEVO: Refresh / Toggle (NO cambia wallpaper)
# --------------------
if [[ "$REFRESH_ONLY" -eq 1 || -n "${TOGGLE_MODE:-}" ]]; then
  if [[ "$DO_WAL" -ne 1 ]]; then
    echo "ℹ --refresh/--toggle se pidió pero --no-wal está activo; no hay nada que refrescar con wal."
  else
    if ! have_cmd wal; then
      echo "Error: falta el comando: wal"
      exit 1
    fi

    if [[ -n "${TOGGLE_MODE:-}" ]]; then
      case "$TOGGLE_MODE" in
        light|-l)
          wal -l 2> >(grep -v "Failed to connect to unix:/tmp/kitty_pywal" >&2) || true
          PREFER_SCHEME="prefer-light"
          WAL_LIGHT=1
          echo "✓ Switched to light theme (wal cache)"
          ;;
        dark)
          wal 2> >(grep -v "Failed to connect to unix:/tmp/kitty_pywal" >&2) || true
          PREFER_SCHEME="prefer-dark"
          WAL_LIGHT=0
          echo "✓ Switched to dark theme (wal cache)"
          ;;
        *)
          echo "Error: --toggle requiere 'light' o 'dark'"
          exit 1
          ;;
      esac
    else
      # --refresh
      if [[ -f "$HOME/.cache/wal/wal" ]]; then
        wal -R 2> >(grep -v "Failed to connect to unix:/tmp/kitty_pywal" >&2) || true
        echo "✓ Refreshed existing wal theme"
      else
        echo "✗ No hay tema previo para refrescar (~/.cache/wal/wal no existe)"
        exit 1
      fi
    fi
  fi

  # Auto-mode (solo tiene sentido con refresh; pero si lo pides, lo aplico igual)
  if [[ "$AUTO_MODE" -eq 1 ]]; then
    if pref="$(detect_prefer_scheme_from_wal)"; then
      PREFER_SCHEME="$pref"
      if [[ "$PREFER_SCHEME" == "prefer-light" ]]; then WAL_LIGHT=1; else WAL_LIGHT=0; fi
      echo "✓ Auto mode detected: $PREFER_SCHEME"
    else
      echo "ℹ No pude auto-detectar modo desde wal; mantengo: $PREFER_SCHEME"
    fi
  fi

  run_post_hooks

  echo "Done! Theme applied system-wide (no wallpaper change)."
  echo "Current mode: $([[ "$WAL_LIGHT" -eq 1 ]] && echo "Light" || echo "Dark")"
  exit 0
fi

# --------------------
# Pick wallpaper
# --------------------
WALLPAPER=""
WALL_FLAGS=()
if [[ "$WALL_NO_SMART" -eq 1 ]]; then
  WALL_FLAGS+=("-N")
fi

if [[ "$MODE" == "file" ]]; then
  WALLPAPER="${TARGET/#\~/$HOME}"
  [[ -f "$WALLPAPER" ]] || { echo "Error: no existe el archivo: $WALLPAPER"; exit 1; }
else
  WALLPAPER="$(pick_random_wallpaper "$TARGET")"
fi

# --------------------
# Apply dynamic scheme + wallpaper in Caelestia (orden importante)
# --------------------
echo "-> Caelestia: scheme set -n dynamic"
SCHEME_FLAGS=()
if [[ "$DO_NOTIFY" -eq 1 ]]; then
  SCHEME_FLAGS+=("--notify")
fi
caelestia scheme set "${SCHEME_FLAGS[@]}" -n dynamic

echo "-> Caelestia: wallpaper: $WALLPAPER"
caelestia wallpaper "${WALL_FLAGS[@]}" -f "$WALLPAPER"

# Mantener referencia interna consistente con el wallpaper REAL
update_caelestia_wallpaper_reference "$WALLPAPER"

# --------------------
# Generate wal colors (NO wallpaper changes)
# --------------------
if [[ "$DO_WAL" -eq 1 ]]; then
  if have_cmd wal; then
    echo "Applying pywal colors system-wide..."
    if [[ "$WAL_LIGHT" -eq 1 ]]; then
      wal -n -i "$WALLPAPER" -l 2> >(grep -v "Failed to connect to unix:/tmp/kitty_pywal" >&2) || true
    else
      wal -n -i "$WALLPAPER" 2> >(grep -v "Failed to connect to unix:/tmp/kitty_pywal" >&2) || true
    fi
    echo "✓ Refreshed/generated wal theme"
  else
    echo "ℹ 'wal' no está instalado; omitido."
  fi
fi

# --------------------
# Extra hooks (igual que antes)
# --------------------
run_post_hooks

echo "Done! Theme applied system-wide."
echo "Current mode: $([[ "$WAL_LIGHT" -eq 1 ]] && echo "Light" || echo "Dark")"
# :::::::::::::::::: fin ::::::::::::::::::
``*
