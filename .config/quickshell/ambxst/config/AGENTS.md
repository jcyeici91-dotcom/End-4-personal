# CONFIG KNOWLEDGE BASE

## OVERVIEW
The configuration system in Ambxst is a reactive, file-backed architecture built on `Quickshell.Io`. 
It serves as the source of truth for all shell modules (Bar, AI, Theme, etc.), managing state through 
synchronized JSON files stored in `~/.config/ambxst/config/`. 

The system is designed for high availability; it gracefully handles missing or malformed configuration 
files by falling back to hardcoded defaults without interrupting the user experience. This robustness 
ensures that even a manual editing error by the user doesn't crash the entire shell environment.

## STRUCTURE
- **Config.qml**: The massive core singleton (`pragma Singleton`). It orchestrates the lifecycle of 
  configuration data, utilizing `FileView` to monitor disk changes and `JsonAdapter` to create a live, 
  bidirectional bridge between JSON objects and QML properties.
- **defaults/*.js**: These JavaScript modules define the "soul" of the configuration. Each file 
  (e.g., `bar.js`, `theme.js`) exports a `data` object that serves as the blueprint for initial 
  file generation and the baseline for validation.
- **ConfigValidator.js**: A specialized library for deep-merging user settings with defaults. It 
  ensures that even as the project evolves and new keys are added, older configuration files remain 
  compatible and type-safe.

## WHERE TO LOOK
- **Validation Logic**: `config/ConfigValidator.js` houses the recursive `validate()` function. 
  This is where you implement constraints for specific fields, such as ensuring `gradientType` only 
  accepts "linear", "radial", or "halftone".
- **Bootstrapping**: The initialization sequence resides in `Config.qml` (look for the `Process` 
  component). It identifies missing `.json` files and populates them using the logic defined in 
  the `StdioCollector`'s `onStreamFinished` handler.
- **File Synchronization**: Search for `FileView` and `JsonAdapter` pairs in `Config.qml`. Each 
  module has its own dedicated pair to ensure isolated and reliable persistence.

## CONVENTIONS
- **Atomic Operations**: Always update `defaults/*.js` when introducing new configuration keys to 
  ensure they are propagated to new users and validated for existing ones.
- **Data Binding**: Bind UI elements to `Config.<module>.<property>`. Avoid local state for persistent 
  settings; let the `Config` singleton handle the heavy lifting and persistence logic.
- **Auto-save Behavior**: Changes to `JsonObject` properties are automatically persisted to disk 
  via their associated `FileView`. Use `root.pauseAutoSave` if you need to perform bulk updates 
  without triggering multiple disk writes.
- **Reactive Defaults**: All configuration access should assume the data might be in the process 
  of loading or reloading. The `initialLoadComplete` property in `Config.qml` can be used to gate 
  components that require a fully initialized environment.
- **JSON Formatting**: Configuration files are written with 4-space indentation for human 
  readability, managed during the initialization and saving processes.
