function copiar --description "Copia archivos o carpetas a un destino (pregunta antes de reemplazar). Uso: copiar <origen...> <destino>"
    if test (count $argv) -lt 2
        echo "Uso: copiar <archivo_o_carpeta...> <destino>"
        echo "Ejemplos:"
        echo "  copiar archivo.txt ~/Documentos/"
        echo "  copiar carpeta ~/Backups/"
        echo "  copiar a.txt b.txt ~/Descargas/"
        return 1
    end

    set -l dest $argv[-1]
    set -l src $argv[1..-2]

    # -r: copia carpetas, -i: pregunta antes de sobrescribir, -v: muestra acciones
    command cp -riv -- $src $dest
end
