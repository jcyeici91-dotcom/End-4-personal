# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Framework:** QtQuick / Quickshell
**Language:** QML / JavaScript

## OVERVIEW
Ambxst is a highly customizable Wayland shell built with Quickshell. It provides a unified panel (bar, dock, notch), dashboard, lockscreen, and desktop widgets, driven by a reactive JSON configuration system.

## STRUCTURE
```
./
├── config/           # Configuration logic & defaults (Singleton)
├── modules/
│   ├── bar/          # Panels, dock, and status indicators
│   ├── widgets/      # Dashboard, launcher, and overlay tools
│   ├── services/     # Backend logic (Battery, Network, AI) - Singletons
│   ├── theme/        # Style definitions (Colors, Icons) - Singletons
│   ├── components/   # Reusable UI primitives (StyledRect, Buttons)
│   └── globals/      # Shared transient state (GlobalStates.qml)
├── assets/           # Wallpapers, presets, icons
├── scripts/          # Helper utilities (install, run)
└── shell.qml         # Entry point: Loads root window & layers
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Entry Point** | `shell.qml` | Initializes `UnifiedShellPanel`, `Desktop`, `LockScreen` |
| **Config Logic** | `config/Config.qml` | HUGE Singleton. Handles `FileView` + `JsonAdapter` persistence |
| **State** | `modules/globals/GlobalStates.qml` | Transient UI state (window visibility, modes) |
| **Services** | `modules/services/*.qml` | `pragma Singleton` services (Battery, Hyprland, AI) |
| **Theme** | `modules/theme/*.qml` | Colors, fonts, radius definitions |
| **Dashboard** | `modules/widgets/dashboard/` | Main overlay UI, tabs, and controls |

## CODE MAP

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `Config` | Singleton | `config/Config.qml` | Central config store. Reactive to JSON file changes. |
| `GlobalStates` | Singleton | `modules/globals/GlobalStates.qml` | Shared runtime state (non-persistent). |
| `UnifiedShellPanel` | Component | `modules/shell/UnifiedShellPanel.qml` | Container for Bar, Notch, Dock. |
| `ShellRoot` | Component | `shell.qml` | Root Quickshell window. |
| `Ai` | Singleton | `modules/services/Ai.qml` | AI Assistant service interface. |

## CONVENTIONS
- **Singletons**: Use `pragma Singleton` for all services and global state.
- **Imports**: `qs.modules.*` namespace used for internal modules.
- **Persistence**: `FileView` watches JSON files; `JsonAdapter` maps JSON keys to QML properties.
- **Formatting**: 4-space indent.
- **Defaults**: Default config values live in `config/defaults/*.js`.

## ANTI-PATTERNS (THIS PROJECT)
- **Hardcoding**: NEVER hardcode colors/sizes. Use `Config.theme.*` or `Config.bar.*`.
- **Direct Props**: AVOID modifying `Config` properties directly; they are bound to `JsonAdapter`.
- **Global Pollution**: Do not add random properties to `root` in `shell.qml`. Use `GlobalStates`.

## COMMANDS
```bash
# Run shell (requires Quickshell)
qs -p shell.qml

# Test specific component
qs -p modules/widgets/dashboard/Dashboard.qml

# Reload config (auto-reloads on save usually)
# (File watchers in Config.qml handle this)
```

## NOTES
- `Config.qml` is >3500 lines. Be careful when modifying.
- The project supports "Presets" which bulk-update config files.
- `ReservationWindows` handles exclusive zones (bar/dock space reservation).
