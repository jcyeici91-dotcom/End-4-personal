# Hyprland Cheatsheet for Noctalia

Dynamic keybind cheatsheet plugin for Noctalia/Quickshell that automatically generates and displays your Hyprland keyboard shortcuts.

## Features

- 🔍 **Automatic keybind detection** from Hyprland config
- 📂 **Category organization** with numbered sections
- 🎨 **Visual key representation** with styled keycaps
- 🌐 **Multi-language support** (13 languages)
- ⌨️ **Keyboard shortcut** to show/hide (default: Super + F1)
- 📱 **Responsive layout** optimized for ultrawide monitors
- 🎯 **Smart parsing** of keybind.conf format

## Installation

1. Copy the plugin to your Noctalia plugins directory:
```bash
cp -r hyprland-cheatsheet ~/.config/noctalia/plugins/
```

2. Restart Quickshell:
```bash
pkill -f "qs.*noctalia" && qs -c noctalia-shell &
```

## Usage

### Via Keyboard Shortcut
Add to your Hyprland config (`~/.config/hypr/keybind.conf`):
```
bind = $mod, F1, exec, qs -c noctalia-shell ipc call plugin:hyprland-cheatsheet toggle
```

### Via IPC Command
```bash
qs -c noctalia-shell ipc call plugin:hyprland-cheatsheet toggle
```

## How It Works

1. **Reads** your `~/.config/hypr/keybind.conf` file
2. **Parses** categories (lines starting with `# 1.`, `# 2.`, etc.)
3. **Extracts** keybinds with descriptions (format: `bind = $mod, KEY, action #"Description"`)
4. **Displays** in a visual panel with categorized sections

## Config Format

Your `keybind.conf` should use this format:

```
# 1. Window Management
bind = $mod, Q, killactive #"Close window"
bind = $mod, F, fullscreen #"Toggle fullscreen"

# 2. Applications
bind = $mod, RETURN, exec, kitty #"Open terminal"
bind = $mod, E, exec, nautilus #"Open file manager"
```

**Important:**
- Categories: `# [number]. [Category Name]`
- Keybinds: `bind = $mod, KEY, action #"Description"`
- Description must be in quotes after `#`

## Layout

The cheatsheet displays in a centered overlay with:
- Color-coded key categories (modifier, action, special keys)
- Organized sections matching your config
- Responsive sizing for different screen resolutions

## Requirements

- Noctalia/Quickshell 3.6.0+
- Hyprland compositor
- `bash` for file reading
- Keybind config at `~/.config/hypr/keybind.conf`

## Files

- `Main.qml` - Core plugin logic and parser
- `Panel.qml` - Visual cheatsheet display
- `BarWidget.qml` - Top bar widget (optional)
- `manifest.json` - Plugin metadata
- `i18n/*.json` - Translation files (13 languages)

## Supported Languages

English, German, Spanish, French, Italian, Japanese, Dutch, Polish, Portuguese, Russian, Turkish, Ukrainian, Chinese

## Author

Created with ❤️ using Claude Code

## License

MIT
