#!/usr/bin/env bash

STATE_DIR="$HOME/.local/state/quickshell/user/generated"
mkdir -p "$STATE_DIR"
touch "$STATE_DIR/material_colors.json"

echo "Vigilante iniciado. Esperando cambios en $STATE_DIR..."

# Hemos añadido más eventos (modify, create) para que sea imposible que no lo detecte
inotifywait -m -e close_write,moved_to,modify,create --format "%f" "$STATE_DIR" | while read -r filename
do
    if [ "$filename" = "material_colors.json" ]; then
        echo "¡Cambio detectado! Sincronizando sistema..."
        
        TARGET_JSON="$STATE_DIR/material_colors.json"
        TARGET_SCSS="$STATE_DIR/material_colors.scss"
        
        # 1. Extraer colores
        PRIMARY=$(jq -r '.primary // "#000000"' "$TARGET_JSON")
        BACKGROUND=$(jq -r '.background // "#000000"' "$TARGET_JSON")
        SURFACE=$(jq -r '.surface // "#000000"' "$TARGET_JSON")
        ON_SURFACE=$(jq -r '.on_surface // "#ffffff"' "$TARGET_JSON")
        SECONDARY=$(jq -r '.secondary // "#000000"' "$TARGET_JSON")

        # 2. Generar SCSS para Dolphin (Kvantum y scripts de End-4)
        > "$TARGET_SCSS"
        jq -r 'to_entries | .[] | "$\(.key): \(.value);"' "$TARGET_JSON" >> "$TARGET_SCSS"
        jq -r 'to_entries | .[] | "$\(.key | split("_") | map(if . == .[0] then . else (.[0:1] | ascii_upcase) + .[1:] end) | join("")): \(.value);"' "$TARGET_JSON" >> "$TARGET_SCSS"

        # 3. Aplicar Bordes a Hyprland
        hyprctl keyword general:col.active_border "rgba(${PRIMARY//#/}ff) rgba(${SECONDARY//#/}ff) 45deg"
        hyprctl keyword general:col.inactive_border "rgba(${SURFACE//#/}aa)"

        # ==========================================
        # 4. PUENTE PARA PYWALFOX (Firefox)
        # ==========================================
        WAL_DIR="$HOME/.cache/wal"
        mkdir -p "$WAL_DIR"
        cat <<EOF > "$WAL_DIR/colors.json"
{
    "special": {
        "background": "$BACKGROUND",
        "foreground": "$ON_SURFACE",
        "cursor": "$PRIMARY"
    },
    "colors": {
        "color0": "$SURFACE", "color1": "$PRIMARY", "color2": "$SECONDARY", "color3": "$PRIMARY",
        "color4": "$SECONDARY", "color5": "$PRIMARY", "color6": "$SECONDARY", "color7": "$ON_SURFACE",
        "color8": "$SURFACE", "color9": "$PRIMARY", "color10": "$SECONDARY", "color11": "$PRIMARY",
        "color12": "$SECONDARY", "color13": "$PRIMARY", "color14": "$SECONDARY", "color15": "$ON_SURFACE"
    }
}
EOF
        # Avisar a Firefox que cambie los colores
        if command -v pywalfox &> /dev/null; then
            pywalfox update &
        fi

        # ==========================================
        # 5. PUENTE SEGURO PARA KITTY
        # ==========================================
        KITTY_CONF_DIR="$HOME/.config/kitty"
        if [ -d "$KITTY_CONF_DIR" ]; then
            cat <<EOF > "$KITTY_CONF_DIR/theme.conf"
foreground $ON_SURFACE
background $BACKGROUND
selection_foreground $BACKGROUND
selection_background $PRIMARY
cursor $PRIMARY
cursor_text_color $BACKGROUND
url_color $SECONDARY
active_border_color $PRIMARY
inactive_border_color $SURFACE
active_tab_background $PRIMARY
active_tab_foreground $BACKGROUND
inactive_tab_background $SURFACE
inactive_tab_foreground $ON_SURFACE
EOF
            kitty @ set-colors -a -c "$KITTY_CONF_DIR/theme.conf" 2>/dev/null || killall -USR1 kitty || true
        fi

        # ==========================================
        # 6. EJECUTAR EL SCRIPT ORIGINAL DE END-4
        # ==========================================
        bash "$HOME/.config/quickshell/ii/scripts/colors/applycolor.sh"

        # 7. Forzar la recarga visual en Dolphin (Qt)
        kvantummanager --set "MaterialYou" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

        echo "¡Sincronización completada! Esperando al siguiente..."
    fi
done
