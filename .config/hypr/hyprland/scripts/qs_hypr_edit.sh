#!/bin/bash
# Inyector Premium Quickshell -> Hyprland

KEY="$1"
VAL="$2"
OVERRIDE_FILE="$HOME/.config/hypr/hyprland/qs_overrides.conf"
MAIN_CONF="$HOME/.config/hypr/hyprland.conf"

# 1. Asegurar que el archivo de overrides exista
touch "$OVERRIDE_FILE"

# 2. INYECCIÓN MAESTRA: Asegura que el archivo de overrides se lea al final de tu hyprland.conf
if [ -f "$MAIN_CONF" ]; then
    if ! grep -q "qs_overrides.conf" "$MAIN_CONF"; then
        echo -e "\n# === QUICKSHELL UI OVERRIDES ===\nsource = $OVERRIDE_FILE" >> "$MAIN_CONF"
    fi
fi

# 3. Guardar el cambio de forma segura (borra la clave vieja y pone la nueva al final)
grep -v "^[[:space:]]*$KEY[[:space:]]*=" "$OVERRIDE_FILE" > "${OVERRIDE_FILE}.tmp"
mv "${OVERRIDE_FILE}.tmp" "$OVERRIDE_FILE"
echo "$KEY = $VAL" >> "$OVERRIDE_FILE"
