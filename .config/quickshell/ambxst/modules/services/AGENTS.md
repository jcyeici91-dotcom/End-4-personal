# SERVICES AGENTS

## OVERVIEW
The `services/` directory contains the backend logic and system interfaces of Ambxst. These are primarily Singletons that bridge Wayland protocols, CLI tools (nmcli, upower, etc.), and AI providers to the QML UI layer. 

The architecture follows a "Reactive Singleton" pattern where services maintain internal state derived from asynchronous system calls and expose it through QML properties.

## WHERE TO LOOK
- `Battery.qml` / `NetworkService.qml`: Core system status providers using UPower and nmcli.
- `Audio.qml` / `EasyEffectsService.qml`: PulseAudio/PipeWire and DSP control logic.
- `Notifications.qml`: Full DBus notification server implementation with persistence.
- `Ai.qml` & `ai/`: Hub for AI assistant strategies (OpenAI, Gemini, Mistral).
- `HyprlandConfig.qml` / `GlobalShortcuts.qml`: Compositor-level interaction and keybind management.
- `StateService.qml`: Central persistence for transient session state (tabs, visibility).
- `AppSearch.qml`: Application indexing and search logic.
- `MprisController.qml`: Media control interface for active players.

## CONVENTIONS
- **Singletons**: Must use `pragma Singleton` at the top and the `Singleton { id: root }` root component.
- **System Access**: 
    - Prefer `Quickshell.Io.Process` for CLI interaction. 
    - Use `SplitParser` for line-by-line stdout handling.
- **Naming**:
    - **Properties**: Use camelCase (e.g., `wifiEnabled`, `isCharging`).
    - **Methods**: `update()` for manual polling; `toggleX()` for boolean switches.
    - **Signals**: Use descriptive past-tense (`initDone`, `notify`) or action-based (`discard`).
- **Data Persistence**:
    - Use `FileView` for direct JSON file manipulation.
    - Reference `Config` singleton for global settings, but keep service-specific state local.
- **Async Safety**: Use `Qt.callLater()` when modifying lists or large models inside process handlers to prevent race conditions during list model updates.
- **Self-Sufficiency**: Services should handle their own lifecycle (e.g., `Component.onCompleted: update()`).
- **Error Handling**: Always provide safe fallback values for properties (e.g., `available: device !== null`).
