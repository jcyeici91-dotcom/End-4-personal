#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- MEJORA 1: TRANSPARENCIA ---
# 100 = Sólido (Aburrido)
# 80-90 = Transparente (Moderno/Bonito)
term_alpha=85 

if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

# --- MEJORA 2: Lectura de colores más segura ---
# Leemos el archivo SCSS y creamos arrays limpios
mapfile -t colornames < <(grep -o "^[a-zA-Z0-9_]*" "$STATE_DIR/user/generated/material_colors.scss")
mapfile -t colorstrings < <(grep -o "#[a-fA-F0-9]\{6\}" "$STATE_DIR/user/generated/material_colors.scss")

apply_term() {
  # Verificar plantilla
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping."
    return
  fi

  # Preparar archivo de destino
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  
  TARGET_FILE="$STATE_DIR/user/generated/terminal/sequences.txt"

  # Aplicar colores (Optimizado)
  # Usamos un bucle para reemplazar cada etiqueta de color con su valor hex (quitando el #)
  for i in "${!colornames[@]}"; do
    color_val=${colorstrings[$i]#\#} # Quitar el # del hex
    sed -i "s/${colornames[$i]} #/$color_val/g" "$TARGET_FILE"
  done

  # Aplicar transparencia
  sed -i "s/\$alpha/$term_alpha/g" "$TARGET_FILE"

  # --- MEJORA 3: Inyección silenciosa ---
  # Envia la secuencia a todas las terminales abiertas (kitty, alacritty, etc que usen pts)
  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
        if [ -w "$file" ]; then
            cat "$TARGET_FILE" >"$file"
        fi
      } & disown || true
    fi
  done
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

# Check config logic
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  # Si no hay config, aplicamos por defecto (mejor que no hacer nada)
  apply_term &
fi

# apply_qt & # Dejar comentado a menos que uses Kvantum específicamente
