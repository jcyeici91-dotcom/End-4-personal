function iynx --description "iynx update: pull + aplicar cambios al HOME (interactivo, archivo por archivo)"
    # Ruta del repo (como tú dijiste)
    set -l repo "$HOME/ii-vynx"
    set -l remote "https://github.com/vaguesyntax/ii-vynx.git"

    if test (count $argv) -eq 0
        echo "Uso: iynx update"
        return 2
    end

    switch $argv[1]
        case update
            # 0) asegurar repo (si no existe, ofrecer clonarlo)
            if not test -d "$repo/.git"
                echo "[iynx] No existe repo en $repo"
                while true
                    read -l -P "[iynx] ¿Clonar ahora desde $remote? [y]/[n]: " ans
                    switch $ans
                        case y Y ''
                            command git clone --recurse-submodules "$remote" "$repo"; or return 1
                            break
                        case n N
                            echo "[iynx] Cancelado."
                            return 1
                        case '*'
                            echo "Respuesta inválida."
                    end
                end
            end

            cd "$repo" || return 1

            # 1) stash si hay cambios locales
            if test -n (command git status --porcelain)
                echo "[iynx] Stash: guardando cambios locales..."
                command git stash push -u -m "iynx update (auto stash)" >/dev/null
            else
                echo "[iynx] Stash: no hay cambios locales."
            end

            # 2) pull
            echo "[iynx] Git pull..."
            command git pull; or return 1

            # 3) aplicar cambios del pull al HOME (archivo por archivo)
            echo "[iynx] Aplicando cambios al HOME (archivo por archivo)..."
            __iynx_apply_pull_changes "$repo"
            return $status

        case '*'
            echo "Uso: iynx update"
            return 2
    end
end


function __iynx_apply_pull_changes --description "Aplica ORIG_HEAD..HEAD al HOME con mapeo inteligente (ii-vynx)"
    set -l repo $argv[1]
    cd "$repo" || return 1

    if not git rev-parse -q --verify ORIG_HEAD >/dev/null 2>/dev/null
        echo "No encuentro ORIG_HEAD. Esto debe correrse justo después de 'git pull'."
        return 1
    end

    set -l range "ORIG_HEAD..HEAD"
    set -l lines (git diff --name-status $range)

    if test (count $lines) -eq 0
        echo "[iynx] No hay cambios para aplicar."
        return 0
    end

    # ---- MAPEADOR: repo-path -> HOME-path ----
    function __iynx_map_to_home --no-scope-shadowing
        set -l p $argv[1]

        # Caso típico del repo ii-vynx: dots/.config/... -> ~/.config/...
        if string match -rq '^dots/' -- "$p"
            echo "$HOME/"(string replace -r '^dots/' '' -- "$p")
            return 0
        end

        # Si el repo trae rutas tipo ".config/..." o ".local/..."
        if string match -rq '^\.(config|local|themes|icons|fonts)/' -- "$p"
            echo "$HOME/$p"
            return 0
        end

        # A veces vienen sin el punto (config/ -> .config/)
        if string match -rq '^(config|local)/' -- "$p"
            echo "$HOME/."$p
            return 0
        end

        return 1
    end

    function __iynx_prompt_apply --no-scope-shadowing
        set -l src_rel $argv[1]
        set -l kind $argv[2]  # A/M/D/R...
        set -l src "$repo/$src_rel"

        if test "$kind" != "D"
            if not test -e "$src"
                echo "[iynx] Aviso: no existe en repo: $src_rel"
                return 0
            end
        end

        set -l dst (__iynx_map_to_home "$src_rel")
        if test $status -ne 0
            echo
            echo "[iynx] $kind: $src_rel"
            echo "     (No mapeable a HOME: se ignora.)"
            while true
                read -l -P "¿[v]er archivo / [n]o (ignorar) / [q] salir?: " ans
                switch $ans
                    case v V
                        if test -e "$src"
                            if type -q less
                                command less -R -- "$src"
                            else
                                command sed -n '1,200p' -- "$src"
                            end
                        else
                            echo "(No existe el archivo en repo: $src_rel)"
                        end
                    case n N ''
                        return 0
                    case q Q
                        return 130
                    case '*'
                        echo "Respuesta inválida."
                end
            end
        end

        echo
        echo "[iynx] $kind: $src_rel"
        echo "     -> $dst"

        # Delete upstream => ofrecer borrar en HOME
        if test "$kind" = "D"
            if test -e "$dst"
                while true
                    read -l -P "Upstream lo borró. ¿Borrar también en HOME? [y]/[n]/[q]: " ans
                    switch $ans
                        case y Y
                            command rm -f -- "$dst"
                            echo "Borrado: $dst"
                            return 0
                        case n N ''
                            echo "Saltado (no borrado): $dst"
                            return 0
                        case q Q
                            return 130
                        case '*'
                            echo "Respuesta inválida."
                    end
                end
            else
                echo "(Ya no existe en HOME, ok)"
                return 0
            end
        end

        # diff si existe destino
        if test -e "$dst"
            echo "--- diff (HOME vs repo) ---"
            command diff -u -- "$dst" "$src" 2>/dev/null; or true
            echo "--------------------------"
        else
            echo "(Nuevo archivo en HOME)"
        end

        while true
            read -l -P "¿Aplicar (copiar/reemplazar)? [y]es/[n]o/[v]er/[q]uit: " ans
            switch $ans
                case y Y
                    command mkdir -p -- (path dirname -- "$dst")
                    command cp -a -- "$src" "$dst"
                    echo "Aplicado: $dst"
                    return 0
                case n N ''
                    echo "Saltado: $src_rel"
                    return 0
                case v V
                    if type -q less
                        command less -R -- "$src"
                    else
                        command sed -n '1,200p' -- "$src"
                    end
                case q Q
                    return 130
                case '*'
                    echo "Respuesta inválida."
            end
        end
    end

    echo "[iynx] Cambios detectados ($range):"
    printf "%s\n" $lines

    for line in $lines
        set -l parts (string split \t -- $line)
        set -l st $parts[1]

        if string match -rq '^R' -- $st
            set -l newpath $parts[3]
            __iynx_prompt_apply "$newpath" "R"
            if test $status -eq 130
                echo "[iynx] Abortado."
                return 130
            end
        else
            set -l path $parts[2]
            __iynx_prompt_apply "$path" "$st"
            if test $status -eq 130
                echo "[iynx] Abortado."
                return 130
            end
        end
    end

    echo
    echo "[iynx] Listo."
    return 0
end
