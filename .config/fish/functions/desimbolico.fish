function desimbolico --description "Borra enlaces simbólicos (symlinks) y usa sudo automáticamente si hace falta. Uso: desimbolico <link...>"
    if test (count $argv) -lt 1
        echo "Uso: desimbolico <ruta_del_link...>"
        return 1
    end

    for link in $argv
        # Evitar problemas si lo pasan con barra final
        set -l clean (string replace -r '/+$' '' -- $link)

        if not test -e $clean
            echo "No existe: $clean"
            continue
        end

        if not test -L $clean
            echo "No es un symlink (no se borra): $clean"
            continue
        end

        set -l parent (dirname -- $clean)

        if test -w $parent
            command rm -v -- $clean
        else
            sudo rm -v -- $clean
        end
    end
end
