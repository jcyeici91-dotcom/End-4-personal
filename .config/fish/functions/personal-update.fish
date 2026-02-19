function personal-update --description "Mirror ~/.config -> End-4-personal, commit local, pull --rebase, push (solo si hay cambios)"
    set -l src "/home/jcgomez91/.config/"
    set -l repo "/home/jcgomez91/End-4-personal"
    set -l remote "origin"
    set -l branch "main"

    # Dentro del repo, guardaremos TODO tu ~/.config aquí:
    set -l dest "$repo/.config/"

    # Validaciones
    if not test -d "$src"
        echo "Error: no existe la carpeta origen: $src"
        return 1
    end

    if not test -d "$repo/.git"
        echo "Error: repo no encontrado o no es git: $repo"
        return 1
    end

    # 1) Copiar ~/.config -> repo/.config (esto puede “ensuciar” el repo)
    mkdir -p "$dest" || return 1
    rsync -a --delete --exclude '.git/' "$src" "$dest" || return 1

    cd "$repo" || return 1

    # 2) Stage
    git add -A || return 1

    # 3) Si NO hay cambios locales (staged), igual revisamos remoto
    if git diff --cached --quiet
        echo "No hay cambios nuevos desde ~/.config (local). Revisando remoto..."

        git fetch "$remote" "$branch" || return 1

        # Si estoy atrás, actualizo (sin crear commit)
        set -l behind (git rev-list --count HEAD.."$remote/$branch")
        if test "$behind" -gt 0
            echo "Hay cambios en remoto. Aplicando pull --rebase..."
            git pull --rebase "$remote" "$branch" || return 1
        else
            echo "Local y remoto ya están sincronizados. No se sube nada."
            return 0
        end
    else
        # 4) Si hay cambios, commit primero
        set -l msg "personal update "(date "+%Y-%m-%d %H:%M:%S")
        git commit -m "$msg" || return 1
        echo "Cambios locales guardados. Sincronizando con remoto..."

        # 5) pull --rebase (seguro porque ya commiteaste)
        git pull --rebase "$remote" "$branch" || return 1
    end

    # 6) Push SOLO si realmente estás “adelante” del remoto
    set -l ahead (git rev-list --count "$remote/$branch"..HEAD)
    if test "$ahead" -gt 0
        git push -u "$remote" "$branch" || return 1
        echo "OK: Push realizado ($ahead commit(s) subido(s))."
    else
        echo "OK: No hay commits locales para subir."
    end
end

