#!/bin/bash
KEY="$1"
VAL="$2"
FILE="$HOME/.config/hypr/hyprland/qs_overrides.txt"

# 1. Asegurar que el archivo de guardado exista
touch "$FILE"

# 2. Aplicar el cambio al instante en la RAM (para ver el efecto en tiempo real)
hyprctl keyword "$KEY" "$VAL"

# 3. Guardar el cambio permanentemente en el archivo plano
if grep -q "^$KEY " "$FILE"; then
    # Si la variable ya existe, reemplazamos su valor
    sed -i "s|^$KEY .*|$KEY $VAL|" "$FILE"
else
    # Si no existe, la añadimos al final
    echo "$KEY $VAL" >> "$FILE"
fi
