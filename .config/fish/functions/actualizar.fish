function actualizar --description "Suite de mantenimiento (God Mode) - Estable"
    # Dependencias: reflector, pacman-contrib, rebuild-detector, fwupd, yay

    set -l AUTO 0
    for a in $argv
        if test "$a" = "--auto"
            set AUTO 1
        end
    end

    # --- Estética ---
    function _log_info; set_color -o blue; echo " ℹ️  $argv"; set_color normal; end
    function _log_task; set_color -o cyan; echo " 🚀 $argv"; set_color normal; end
    function _log_ok;   set_color -o green; echo " ✅ $argv"; set_color normal; end
    function _log_warn; set_color -o yellow; echo " ⚠️  $argv"; set_color normal; end
    function _log_err;  set_color -o red; echo " ❌ $argv"; set_color normal; end

    # --- 0. Elevación de Privilegios (FIXED) ---
    _log_task "Validando permisos de administrador..."
    # Simplemente invocamos sudo. Si necesita contraseña, la pedirá aquí.
    if not sudo -v
        _log_err "No se pudo obtener acceso root. Cancelando."
        return 1
    end
    _log_ok "Permisos concedidos."

    # --- 1. Velocidad (Reflector) ---
    if type -q reflector
        _log_task "Optimizando espejos (Mirrors) para máxima velocidad..."
        # Busca los 10 mejores espejos https, ordenados por velocidad
        sudo reflector --latest 10 --protocol https --sort rate --age 12 --save /etc/pacman.d/mirrorlist >/dev/null 2>&1
        _log_ok "Lista de espejos optimizada."
    end

    # --- 2. El Corazón (Pacman & Keyring) ---
    _log_task "Actualizando Core del Sistema (Pacman)..."
    
    # Actualizar llaves primero
    sudo pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1

    if test $AUTO -eq 1
        sudo pacman -Syu --noconfirm
    else
        sudo pacman -Syu
    end

    if test $status -ne 0
        _log_err "Fallo crítico en Pacman. Abortando."
        return 1
    end

    # --- 3. El Universo Expandido (AUR - Yay) ---
    if type -q yay
        _log_task "Actualizando AUR (Yay)..."
        if test $AUTO -eq 1
            yay -Syu --devel --timeupdate --needed --noconfirm
        else
            yay -Syu --devel --timeupdate --needed
        end
    end

    # --- 4. Autocuración (Rebuild Detector) ---
    if type -q checkrebuild
        _log_task "Escaneando librerías rotas..."
        set -l broken_pkgs (checkrebuild | string match -r '\S+$')
        
        if test -n "$broken_pkgs"
            _log_warn "Detectados paquetes desincronizados: $broken_pkgs"
            _log_task "Iniciando reparación automática..."
            if type -q yay
                yay -S --rebuild $broken_pkgs --noconfirm
                _log_ok "Reparación completada."
            else
                _log_err "Necesitas 'yay' para la autoreparación."
            end
        else
            _log_ok "Integridad de librerías verificada."
        end
    end

    # --- 5. Contenedores (Flatpak & Snap) ---
    if type -q flatpak
        _log_task "Actualizando Flatpaks..."
        flatpak update -y >/dev/null
        flatpak uninstall --unused -y >/dev/null 2>&1
    end

    if type -q snap
        _log_task "Actualizando Snaps..."
        sudo snap refresh >/dev/null 2>&1
    end

    # --- 6. Firmware (BIOS/Hardware) ---
    if type -q fwupdmgr
        _log_task "Buscando actualizaciones de Firmware..."
        fwupdmgr refresh >/dev/null 2>&1
        set -l updates (fwupdmgr get-updates 2>/dev/null)
        if test -n "$updates" -a "$updates" != "No updates available"
            _log_warn "Hay actualizaciones de firmware disponibles."
            _log_info "Ejecuta 'fwupdmgr update' manualmente."
        else
            _log_ok "Firmware al día."
        end
    end

    # --- 7. Mantenimiento y Limpieza ---
    _log_task "Ejecutando rutinas de mantenimiento..."

    # Limpiar caché de pacman
    if type -q paccache
        sudo paccache -r    >/dev/null 2>&1 
        sudo paccache -ruk0 >/dev/null 2>&1 
        _log_ok "Caché de paquetes optimizada."
    else
        if test $AUTO -eq 1
           yes | sudo pacman -Sc >/dev/null 2>&1
        end
    end

    # Limpiar Logs
    sudo journalctl --vacuum-time=2weeks --vacuum-size=500M >/dev/null 2>&1
    _log_ok "Logs del sistema purgados."

    # --- 8. Diagnóstico Final ---
    echo ""
    _log_info "=== INFORME DE ESTADO ==="
    
    set -l failed_services (systemctl list-units --state=failed --no-legend --plain)
    if test -n "$failed_services"
        _log_err "Se detectaron servicios fallidos:"
        echo $failed_services
    else
        _log_ok "Servicios del sistema: 100% Operativos."
    end

    echo ""
    set_color -o magenta
    echo "✨ Sistema actualizado y optimizado al 100%. ✨"
    set_color normal
end
