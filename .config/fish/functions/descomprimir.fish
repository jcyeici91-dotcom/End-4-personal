function descomprimir --description "Descomprime archivos comunes en el directorio actual"
    if test (count $argv) -eq 0
        echo "Uso: descomprimir <archivo>"
        return 1
    end

    set -l f $argv[1]

    if not test -e "$f"
        echo "No existe: $f"
        return 1
    end

    # Si es un path, lo resolvemos; si es relativo, igual funciona
    switch $f
        case '*.tar.gz' '*.tgz'
            tar -xzf "$f"
        case '*.tar.bz2' '*.tbz' '*.tbz2'
            tar -xjf "$f"
        case '*.tar.xz' '*.txz'
            tar -xJf "$f"
        case '*.tar.zst' '*.tzst'
            tar --zstd -xf "$f"
        case '*.tar'
            tar -xf "$f"
        case '*.zip'
            unzip "$f"
        case '*.7z'
            7z x "$f"
        case '*.rar'
            unrar x "$f"
        case '*.gz'
            gunzip -k "$f"
        case '*.bz2'
            bunzip2 -k "$f"
        case '*.xz'
            unxz -k "$f"
        case '*.zst'
            unzstd -k "$f"
        case '*'
            echo "Formato no soportado: $f"
            return 2
    end
end
