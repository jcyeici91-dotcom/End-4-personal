function timerestor --description "Lista snapshots de Timeshift y restaura uno (interactive)."
    if not type -q timeshift
        echo "timeshift no está instalado o no está en PATH."
        return 1
    end

    echo "== Snapshots disponibles (Timeshift) =="
    echo

    # Guardamos el listado para extraer nombres de snapshot de forma robusta
    set -l raw (command sudo timeshift --list 2>/dev/null)

    if test (count $raw) -eq 0
        echo "No pude obtener la lista (¿necesitas sudo o no hay snapshots?)."
        return 2
    end

    # Mostrar tal cual lo da Timeshift (útil para ver fecha/tipo/comentario)
    printf "%s\n" $raw
    echo

    # Extraer nombres de snapshot (suelen verse como: > 2026-01-22_10-30-01 ...)
    # Nos quedamos con tokens que parezcan "YYYY-MM-DD_HH-MM-SS"
    set -l snaps
    for line in $raw
        set -l s (string match -r -- '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}' $line)
        if test -n "$s"
            set -a snaps $s
        end
    end

    if test (count $snaps) -eq 0
        echo "No pude detectar nombres de snapshots automáticamente."
        echo "Copia/pega el nombre exacto del snapshot desde el listado."
        echo -n "Snapshot: "
        read -l pick
        if test -z "$pick"
            echo "Cancelado."
            return 3
        end
        set -l chosen $pick
    else
        echo "== Selección rápida =="
        for i in (seq (count $snaps))
            echo "  [$i] $snaps[$i]"
        end
        echo
        echo -n "Elige número o pega el nombre exacto: "
        read -l pick

        if test -z "$pick"
            echo "Cancelado."
            return 3
        end

        if string match -qr -- '^\d+$' $pick
            set -l idx $pick
            if test $idx -lt 1; or test $idx -gt (count $snaps)
                echo "Índice fuera de rango."
                return 4
            end
            set -l chosen $snaps[$idx]
        else
            set -l chosen $pick
        end
    end

    echo
    echo "Vas a restaurar el snapshot: $chosen"
    echo "Esto puede sobrescribir el estado actual del sistema."
    echo -n "Escribe RESTAURAR para confirmar: "
    read -l confirm

    if test "$confirm" != "RESTAURAR"
        echo "Cancelado."
        return 5
    end

    echo
    echo "Lanzando restore (Timeshift pedirá confirmaciones adicionales si aplica)..."
    command sudo timeshift --restore --snapshot "$chosen"
end
