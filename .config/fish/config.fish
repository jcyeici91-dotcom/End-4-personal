function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'

 # --- Alias para proteger/desproteger Hyprland (excluye profile.conf symlink) ---
alias hyprlandbloqueado='set -l HYPRDIR "$HOME/.config/hypr/hyprland"; find "$HYPRDIR" -path "$HYPRDIR/scripts" -prune -o -type f -name "*.conf" ! -name "profile.conf" -print0 | sudo xargs -0 chattr +i; and echo "SISTEMA HYPRLAND BLINDADO (todos los .conf reales bloqueados, excepto profile.conf)"'

alias hyprlanddesbloqueado='set -l HYPRDIR "$HOME/.config/hypr/hyprland"; find "$HYPRDIR" -path "$HYPRDIR/scripts" -prune -o -type f -name "*.conf" ! -name "profile.conf" -print0 | sudo xargs -0 chattr -i; and echo "SISTEMA HYPRLAND LIBERADO (todos los .conf reales editables, excepto profile.conf)"'

end 

