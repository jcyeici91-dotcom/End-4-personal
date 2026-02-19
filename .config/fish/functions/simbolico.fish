function simbolico --description "Crea enlaces simbólicos y usa sudo automáticamente si hace falta. Uso: simbolico <origen...> <destino>"
    if test (count $argv) -lt 2
        echo "Uso:"
        echo "  simbolico <origen> <destino>"
        echo "  simbolico <origen...> <directorio_destino>"
        return 1
    end

    set -l dest $argv[-1]
    set -l src  $argv[1..-2]

    # Detectar dónde se crea realmente el link:
    # - Si dest es un directorio existente (o termina en /), se crea dentro de ese dir.
    # - Si dest es un path a archivo, se crea en el dir padre.
    set -l create_dir ""

    if string match -qr '/$' -- $dest
        set create_dir (string replace -r '/+$' '' -- $dest)
    else if test -d $dest
        set create_dir $dest
    else
        set create_dir (dirname -- $dest)
    end

    # Si el dir no existe, intentamos crearlo (con o sin sudo según permisos)
    if not test -d $create_dir
        if test -w (dirname -- $create_dir)
            command mkdir -p -- $create_dir
        else
            sudo mkdir -p -- $create_dir
        end
    end

    # Elegir si usar sudo según permiso de escritura en el directorio donde se creará
    if test -w $create_dir
        command ln -siv -- $src $dest
    else
        sudo ln -siv -- $src $dest
    end
end
