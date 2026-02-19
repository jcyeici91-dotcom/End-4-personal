function mover --description "Mueve archivos o carpetas a un destino. Uso: mover <origen...> <destino>"
    if test (count $argv) -lt 2
        echo "Uso: mover <archivo_o_carpeta...> <destino>"
        echo "Ejemplos:"
        echo "  mover archivo.txt ~/Documentos/"
        echo "  mover carpeta ~/Backups/"
        echo "  mover a.txt b.txt ~/Descargas/"
        echo "  mover dms_nueva ~/.config/quickshell/dms"
        return 1
    end

    set -l dest $argv[-1]
    set -l src $argv[1..-2]

    # -i: pregunta antes de sobrescribir, -v: verboso
    command mv -iv -- $src $dest
end
