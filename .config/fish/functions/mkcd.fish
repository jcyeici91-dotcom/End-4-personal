function mkcd --description "Crea una ruta (soporta segmentos con espacios) y entra. Acepta -b base."
    set -l base ""
    set -l parts

    # Parseo simple: -b/--base y --help
    while test (count $argv) -gt 0
        switch $argv[1]
            case '-h' '--help'
                echo "Uso:"
                echo "  mkcd <ruta|segmentos...>"
                echo "  mkcd -b <base> <segmentos...>"
                echo
                echo "Ejemplos:"
                echo "  mkcd Descargas/mio jc 2026"
                echo "  mkcd Descargas/mio/jc/2026"
                echo "  mkcd -b ~/Descargas Proyecto Nuevo 2026"
                return 0

            case '-b' '--base'
                if test (count $argv) -lt 2
                    echo "mkcd: falta valor para -b/--base"
                    return 1
                end
                set base $argv[2]
                set -e argv[1..2]
                continue

            case '--'
                set -e argv[1]
                set parts $parts $argv
                break

            case '*'
                set parts $parts $argv[1]
                set -e argv[1]
        end
    end

    if test (count $parts) -eq 0
        echo "mkcd: no diste ningún nombre de carpeta. Usa: mkcd --help"
        return 1
    end

    # Construir el target:
    # - Si usas -b: todo se vuelve relativo a base.
    # - Si NO usas -b:
    #   * si hay 1 argumento -> úsalo tal cual (puede tener /)
    #   * si hay varios -> se unen con / (soporta: Descargas/mio jc 2026)
    set -l target ""
    if test -n "$base"
        set target "$base/"(string join "/" $parts)
    else
        if test (count $parts) -eq 1
            set target "$parts[1]"
        else
            set target (string join "/" $parts)
        end
    end

    mkdir -p -- "$target"; or return 1
    cd -- "$target"
end
