function borrar --description "Manda archivos/carpetas a la papelera (trash). Uso: borrar <ruta...>"
    if test (count $argv) -eq 0
        echo "Uso: borrar <archivo_o_carpeta...>"
        return 1
    end

    # Verifica existencia (evita typos)
    set -l ok 1
    for p in $argv
        if not test -e "$p"
            echo "borrar: no existe: $p"
            set ok 0
        end
    end
    if test $ok -eq 0
        return 1
    end

    if type -q trash-put
        command trash-put -- $argv
    else if type -q gio
        command gio trash -- $argv
    else
        echo "borrar: no encuentro 'trash-put' ni 'gio'."
        echo "Instala trash-cli (recomendado) o glib2."
        return 127
    end
end

