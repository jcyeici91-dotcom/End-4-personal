function copiarf --description "Copia y REEMPLAZA (sobrescribe sin preguntar). Uso: copiarf <origen...> <destino>"
    if test (count $argv) -lt 2
        echo "Uso: copiarf <origen...> <destino>"
        echo "Ejemplos:"
        echo "  copiarf archivo.txt ~/.config/app/archivo.txt"
        echo "  copiarf carpeta_nueva ~/.config/app/carpeta"
        return 1
    end

    set -l dest $argv[-1]
    set -l src $argv[1..-2]

    # -r: copia recursivo (carpetas)
    # -T: trata DESTINO como un objeto a reemplazar (no 'copiar dentro')
    # -v: verboso
    command cp -rTv -- $src $dest
end
