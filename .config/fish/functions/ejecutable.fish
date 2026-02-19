function ejecutable --description 'Permisos inteligentes con exclusiones (HOME: 644/755 +x, fuera: +x seguro) + resumen final'
    set -l dry 0
    set -l only_exec 0
    set -l no_chown 0
    set -l force_fix_outside 0

    argparse -n ejecutable \
        'h/help' \
        'd/dry-run' \
        'x/only-exec' \
        'N/no-chown' \
        'F/force-fix-outside' \
        -- $argv
    or return 2

    if set -q _flag_help
        echo "Uso:"
        echo "  ejecutable [--dry-run] [--only-exec] [--no-chown] [--force-fix-outside] <ruta...>"
        echo ""
        echo "Por defecto:"
        echo "  - En HOME: dirs 755, files 644, scripts +x (y arregla dueño root si aparece)"
        echo "  - Fuera de HOME: SOLO scripts/binarios +x (modo seguro)"
        echo ""
        echo "Flags:"
        echo "  --only-exec           Solo +x a scripts/binarios (no 644/755)"
        echo "  --dry-run             No ejecuta (y aquí: solo muestra resumen)"
        echo "  --no-chown            No intenta chown aunque detecte root en HOME"
        echo "  --force-fix-outside   Permite aplicar 644/755 también fuera de HOME (¡cuidado!)"
        return 0
    end

    if set -q _flag_dry_run; set dry 1; end
    if set -q _flag_only_exec; set only_exec 1; end
    if set -q _flag_no_chown; set no_chown 1; end
    if set -q _flag_force_fix_outside; set force_fix_outside 1; end

    # ---- QUIET automático en dry-run: SOLO resumen ----
    set -l quiet 0
    if test $dry -eq 1
        set quiet 1
    end

    set -l paths $argv
    if test (count $paths) -lt 1
        echo "Falta ruta. Ej: ejecutable ~/.config/quickshell/ambxst"
        return 1
    end

    # Regex HOME (seguro en Fish)
    set -l home_re (string escape --style=regex -- $HOME)
    set -l home_pat '^'"$home_re"'(/|$)'

    # Exclusiones (lista de args, NO string)
    set -l prune_args \
        \( -name .git -o -name .svn -o -name .hg \
           -o -name node_modules \
           -o -name .cache -o -name cache \
           -o -name __pycache__ \
           -o -name venv -o -name .venv \
           -o -name target -o -name dist -o -name build \
        \) -prune -o

    # ---- Contadores globales ----
    set -l sum_targets 0
    set -l sum_chown 0
    set -l sum_dirs_755 0
    set -l sum_files_644 0
    set -l sum_ext_exec 0
    set -l sum_shebang_exec 0
    set -l sum_elf_exec 0

    # Ejecutar o imprimir (sin eval), ignorando args vacíos
    function _run --argument-names dry quiet
        set -l cmd
        for a in $argv[3..-1]
            if test -n "$a"
                set -a cmd $a
            end
        end

        if test (count $cmd) -eq 0
            return 0
        end

        if test "$dry" = "1"
            # En dry-run: no ejecutar. Si quiet=1, no imprimir.
            if test "$quiet" != "1"
                echo -n "[dry-run] "
                printf "%s " $cmd
                echo
            end
        else
            $cmd
        end
    end

    # Dry-run con etiqueta corta
    function _run_label --argument-names dry quiet label
        set -l cmd
        for a in $argv[4..-1]
            if test -n "$a"
                set -a cmd $a
            end
        end

        if test (count $cmd) -eq 0
            return 0
        end

        if test "$dry" = "1"
            if test "$quiet" != "1"
                echo "[dry-run] $label"
            end
        else
            $cmd
        end
    end

    for target in $paths
        set -l path (string replace -r '^~' $HOME -- $target)

        if command -vq realpath
            set -l rp (realpath -m -- "$path" 2>/dev/null)
            if test -n "$rp"
                set path "$rp"
            end
        end

        if not test -e "$path"
            if test $quiet -ne 1
                echo "No existe: $target"
            end
            continue
        end

        set sum_targets (math $sum_targets + 1)

        set -l in_home 0
        if string match -rq -- "$home_pat" "$path"
            set in_home 1
        end

        # Fuera de HOME: sudo (modo seguro)
        set -l SUDO_CMD ""
        if test $in_home -eq 0
            set SUDO_CMD sudo
        end

        # ¿Aplicamos 644/755?
        set -l do_fix 1
        if test $only_exec -eq 1
            set do_fix 0
        else if test $in_home -eq 0 -a $force_fix_outside -eq 0
            set do_fix 0
        end

        # HOME: arreglar dueño root si corresponde
        if test $in_home -eq 1 -a $no_chown -eq 0
            set -l owner (stat -c '%U' -- "$path" 2>/dev/null)
            if test "$owner" = "root"
                set sum_chown (math $sum_chown + 1)
                _run $dry $quiet sudo chown -R (id -un):(id -gn) -- "$path"
            end
        end

        if test -d "$path"
            # --------- CONTEOS ----------
            set -l cdirs 0
            set -l cfiles 0
            set -l cext 0
            set -l cshebang 0
            set -l celf 0

            set -l files_list

            if test $do_fix -eq 1
                set -l dirs_list (find "$path" $prune_args -type d -print0 2>/dev/null | string split0)
                set files_list (find "$path" $prune_args -type f -print0 2>/dev/null | string split0)
                set cdirs (count $dirs_list)
                set cfiles (count $files_list)

                set sum_dirs_755 (math $sum_dirs_755 + $cdirs)
                set sum_files_644 (math $sum_files_644 + $cfiles)
            else
                set files_list (find "$path" $prune_args -type f -print0 2>/dev/null | string split0)
            end

            # extensión
            set -l ext_list (find "$path" $prune_args -type f \
                \( -name "*.sh" -o -name "*.bash" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" \) \
                -print0 2>/dev/null | string split0)
            set cext (count $ext_list)
            set sum_ext_exec (math $sum_ext_exec + $cext)

            # shebang / ELF (sobre files_list)
            for f in $files_list
                if head -c 2 "$f" 2>/dev/null | grep -q "^#!"
                    set cshebang (math $cshebang + 1)
                end

                set -l sig (od -An -N4 -tx1 "$f" 2>/dev/null | tr -d " \n")
                if test "$sig" = "7f454c46"
                    set celf (math $celf + 1)
                end
            end
            set sum_shebang_exec (math $sum_shebang_exec + $cshebang)
            set sum_elf_exec (math $sum_elf_exec + $celf)

            # --------- ACCIONES ----------
            if test $do_fix -eq 1
                _run $dry $quiet $SUDO_CMD find "$path" $prune_args -type d -exec chmod 755 {} +
                _run $dry $quiet $SUDO_CMD find "$path" $prune_args -type f -exec chmod 644 {} +
            end

            _run $dry $quiet $SUDO_CMD find "$path" $prune_args -type f \
                \( -name "*.sh" -o -name "*.bash" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" \) \
                -exec chmod +x {} +

            _run_label $dry $quiet "marcar ejecutable por shebang (#!) -> $path (count: $cshebang)" \
                $SUDO_CMD find "$path" $prune_args -type f -exec sh -c '
                    for f do
                        head -c 2 "$f" 2>/dev/null | grep -q "^#!" && chmod +x "$f"
                    done
                ' sh {} +

            _run_label $dry $quiet "marcar ejecutable por ELF -> $path (count: $celf)" \
                $SUDO_CMD find "$path" $prune_args -type f -exec sh -c '
                    for f do
                        sig=$(od -An -N4 -tx1 "$f" 2>/dev/null | tr -d " \n")
                        [ "$sig" = "7f454c46" ] && chmod +x "$f"
                    done
                ' sh {} +

            if test $quiet -ne 1
                echo "OK: carpeta -> $path"
            end
        else
            # Archivo suelto
            if test $do_fix -eq 1
                set sum_files_644 (math $sum_files_644 + 1)
                _run $dry $quiet $SUDO_CMD chmod 644 -- "$path"
            end

            if string match -rq -- '\.(sh|bash|py|pl|rb)$' "$path"
                set sum_ext_exec (math $sum_ext_exec + 1)
                _run $dry $quiet $SUDO_CMD chmod +x -- "$path"
            else
                set -l is_sh 1
                head -c 2 "$path" 2>/dev/null | grep -q "^#!"
                set is_sh $status

                set -l sig (od -An -N4 -tx1 -- "$path" 2>/dev/null | string replace -ar '\s+' '')

                if test $is_sh -eq 0
                    set sum_shebang_exec (math $sum_shebang_exec + 1)
                    if test $dry -eq 0
                        $SUDO_CMD chmod +x -- "$path"
                    end
                end

                if test "$sig" = "7f454c46"
                    set sum_elf_exec (math $sum_elf_exec + 1)
                    if test $dry -eq 0
                        $SUDO_CMD chmod +x -- "$path"
                    end
                end

                if test $dry -eq 1 -a $quiet -ne 1
                    echo "[dry-run] marcar ejecutable por shebang/ELF -> $path"
                end
            end

            if test $quiet -ne 1
                echo "OK: archivo -> $path"
            end
        end
    end

    # ---- SOLO RESUMEN (siempre) ----
    echo ""
    echo "Resumen:"
    echo "  rutas procesadas: $sum_targets"
    echo "  chown aplicados:  $sum_chown"
    echo "  chmod 755 dirs:   $sum_dirs_755"
    echo "  chmod 644 files:  $sum_files_644"
    echo "  +x por extensión: $sum_ext_exec"
    echo "  +x por shebang:   $sum_shebang_exec"
    echo "  +x por ELF:       $sum_elf_exec"
end

