#!/usr/bin/env bash

# Configuración por defecto
INTERVAL=2
TOTAL_DURATION=30
SOURCE_TYPE="monitor"  # monitor | input
TMP_PATH="/tmp/quickshell/media/songrec"
TMP_RAW="$TMP_PATH/recording.raw"
TMP_MP3="$TMP_PATH/recording.mp3"

# Parseo de argumentos
while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) echo "Uso: $0 [-i intervalo] [-t duracion] [-s monitor|input]"; exit 1 ;;
  esac
done

# 1. Detección robusta de la fuente de audio (PulseAudio/PipeWire)
if [ "$SOURCE_TYPE" = "monitor" ]; then
    # Obtiene la salida de audio (lo que escuchas)
    MONITOR_SOURCE=$(pactl get-default-sink).monitor
elif [ "$SOURCE_TYPE" = "input" ]; then
    # Obtiene la entrada de audio (micrófono) de forma directa
    MONITOR_SOURCE=$(pactl get-default-source)
else
    echo "Error: Tipo de fuente inválido. Use 'monitor' o 'input'."
    exit 1
fi

# 2. Verificación de dependencias
deps=(songrec parec ffmpeg pactl jq)
for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: Falta la dependencia '$dep'."
        exit 1
    fi
done

# Validar que la fuente existe
if [ -z "$MONITOR_SOURCE" ] || ! pactl list short sources | grep -q "$MONITOR_SOURCE"; then
    echo "Error: No se encontró la fuente de audio: $MONITOR_SOURCE"
    exit 1
fi

# 3. Limpieza segura al salir (Trap)
cleanup() {
    # Mata solo los procesos hijos de este script
    pkill -P $$ parec >/dev/null 2>&1 || true
    rm -f "$TMP_RAW" "$TMP_MP3"
}
trap cleanup EXIT

# Preparar directorio
mkdir -p "$TMP_PATH"
rm -f "$TMP_RAW" # Asegurar que no hay residuos viejos

# 4. Iniciar grabación en segundo plano (Raw PCM para menor latencia)
parec --device="$MONITOR_SOURCE" --format=s16le --rate=44100 --channels=2 > "$TMP_RAW" &
PAREC_PID=$!
START_TIME=$(date +%s)

echo "Escuchando ($SOURCE_TYPE)..."

while true; do
    sleep "$INTERVAL"
    
    # Comprobar timeout
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    if (( ELAPSED >= TOTAL_DURATION )); then
        echo '{"error": "Timeout reached"}'
        exit 0 # Salimos con éxito pero sin resultado (o puedes usar exit 1)
    fi

    # 5. Conversión Optimizada
    # -threads 1: Usa solo 1 hilo (es tarea ligera)
    # -preset ultrafast: Prioriza velocidad sobre compresión
    ffmpeg -f s16le -ar 44100 -ac 2 -i "$TMP_RAW" \
           -acodec libmp3lame -q:a 4 -threads 1 -preset ultrafast \
           -y -hide_banner -loglevel error "$TMP_MP3" 2>/dev/null

    # 6. Reconocimiento
    RESULT=$(songrec audio-file-to-recognized-song "$TMP_MP3" 2>/dev/null || true)

    # 7. Validación Inteligente con JQ (Mucho mejor que contar caracteres)
    # Verifica si el JSON tiene un campo "track" con contenido real
    if echo "$RESULT" | jq -e '.track.title' >/dev/null 2>&1; then
        echo "$RESULT"
        exit 0
    fi
done
