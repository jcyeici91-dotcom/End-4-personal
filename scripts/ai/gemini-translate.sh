#!/usr/bin/env bash

# Validación de argumentos
if [[ -z "$1" ]]; then
    echo "Usage: $0 <target_locale> [model]"
    exit 1
fi

# Verificación de dependencias necesarias
for dep in jq curl secret-tool notify-send; do
    if ! command -v "$dep" &> /dev/null; then
        echo "Error: Falta la dependencia '$dep'. Instálala para continuar."
        exit 1
    fi
done

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELL_CONFIG_DIR="$XDG_CONFIG_HOME/illogical-impulse"
SHELL_CONFIG_FILE="${SHELL_CONFIG_DIR}/config.json"
TRANSLATIONS_DIR="${SCRIPT_DIR}/../../translations"
TRANSLATIONS_TARGET_DIR="${SHELL_CONFIG_DIR}/translations"
SOURCE_LOCALE="en_US"
NOTIFICATION_APP_NAME="Shell"
TARGET_LOCALE="$1"
MODEL="${2:-${GEMINI_MODEL:-gemini-2.0-flash}}" # Actualizado a un modelo más reciente/rápido por defecto si quieres

# Update the source keys for translation
if [ -f "${TRANSLATIONS_DIR}/tools/manage-translations.sh" ]; then
    "${TRANSLATIONS_DIR}/tools/manage-translations.sh" update -l "$SOURCE_LOCALE" --yes
else
    echo "Warning: script manage-translations.sh not found, skipping update."
fi
mkdir -p "$TRANSLATIONS_TARGET_DIR"

# Obtener API Key de forma segura
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' | jq -r '.apiKeys.gemini // empty')

if [[ -z "$API_KEY" ]]; then
    notify-send "Translation Failed" "No Gemini API key found in secret-tool." -u critical -a "$NOTIFICATION_APP_NAME"
    echo "Error: API Key not found."
    exit 1
fi

# Notify start
notify-send "Translation started" "Translating to $TARGET_LOCALE using $MODEL..." -a "$NOTIFICATION_APP_NAME"

# Construct the prompt string
# Mejoramos el prompt para forzar JSON puro sin Markdown
instruction='You are a UI translator for a Linux desktop shell. 
Task: Translate the values of the provided JSON to '"$TARGET_LOCALE"'. 
Rules:
1. Keep the same JSON structure and keys.
2. Be concise (save screen space).
3. Use relevant terminology (e.g. "discharging" -> battery status).
4. OUTPUT ONLY RAW JSON. Do NOT use markdown code blocks (```json).'

content=$(cat "${TRANSLATIONS_DIR}/en_US.json")
# Construcción segura del JSON del prompt
prompt_json=$(jq -n --arg inst "$instruction" --arg cont "$content" '$inst + "\n\n" + $cont')

# Payload
payload=$(jq -n \
    --arg prompt "$prompt_json" \
    --arg model "$MODEL" \
    '{
        contents: [{ parts: [{ text: $prompt }] }],
        generationConfig: {
            temperature: 0.1,
            responseMimeType: "application/json"
        }
    }'
)

# Realizar la petición (Capturando código HTTP)
response=$(curl -s -w "\n%{http_code}" "[https://generativelanguage.googleapis.com/v1beta/models/$](https://generativelanguage.googleapis.com/v1beta/models/$){MODEL}:generateContent?key=${API_KEY}" \
    -H 'Content-Type: application/json' \
    -X POST \
    -d "$payload")

# Separar cuerpo y código de estado
http_body=$(echo "$response" | sed '$d')
http_status=$(echo "$response" | tail -n1)

if [[ "$http_status" != "200" ]]; then
    error_msg=$(echo "$http_body" | jq -r '.error.message // "Unknown error"')
    notify-send "Translation Error ($http_status)" "$error_msg" -u critical -a "$NOTIFICATION_APP_NAME"
    echo "API Error: $http_body"
    exit 1
fi

# Extraer y Limpiar el texto
generated_text=$(echo "$http_body" | jq -r '.candidates[0].content.parts[0].text')

# Limpieza extra: A veces la API ignora la instrucción y manda Markdown ```json
cleaned_json=$(echo "$generated_text" | sed 's/^```json//g; s/^```//g; s/```$//g')

# Validar que sea JSON válido antes de guardar
if echo "$cleaned_json" | jq empty > /dev/null 2>&1; then
    echo "$cleaned_json" > "${TRANSLATIONS_TARGET_DIR}/${TARGET_LOCALE}.json"
    
    # Actualizar config solo si todo salió bien
    jq --arg locale "$TARGET_LOCALE" '.language.ui = $locale' "$SHELL_CONFIG_FILE" > "${SHELL_CONFIG_FILE}.tmp" && mv "${SHELL_CONFIG_FILE}.tmp" "$SHELL_CONFIG_FILE"
    
    notify-send "Translation complete" "Saved to ${TRANSLATIONS_TARGET_DIR}/${TARGET_LOCALE}.json" -a "$NOTIFICATION_APP_NAME"
else
    notify-send "Translation Failed" "Received invalid JSON from API." -u critical -a "$NOTIFICATION_APP_NAME"
    echo "Error: Invalid JSON received:"
    echo "$cleaned_json"
    exit 1
fi
