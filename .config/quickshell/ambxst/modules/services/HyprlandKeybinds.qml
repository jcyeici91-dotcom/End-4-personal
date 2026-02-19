import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.modules.globals

QtObject {
    id: root

    property Process hyprctlProcess: Process {}

    property var previousAmbxstBinds: ({})
    property var previousCustomBinds: []
    property bool hasPreviousBinds: false

    property Timer applyTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: applyKeybindsInternal()
    }

    function applyKeybinds() {
        applyTimer.restart();
    }

    // Helper function to check if an action is compatible with the current layout
    function isActionCompatibleWithLayout(action) {
        // If no compositor specified, action works everywhere
        if (!action.compositor)
            return true;

        // If compositor type is not hyprland, skip (future-proofing)
        if (action.compositor.type && action.compositor.type !== "hyprland")
            return false;

        // If no layouts specified or empty array, action works in all layouts
        if (!action.compositor.layouts || action.compositor.layouts.length === 0)
            return true;

        // Check if current layout is in the allowed list
        const currentLayout = GlobalStates.hyprlandLayout;
        return action.compositor.layouts.indexOf(currentLayout) !== -1;
    }

    function cloneKeybind(keybind) {
        return {
            modifiers: keybind.modifiers ? keybind.modifiers.slice() : [],
            key: keybind.key || ""
        };
    }

    function storePreviousBinds() {
        if (!Config.keybindsLoader.loaded)
            return;

        const ambxst = Config.keybindsLoader.adapter.ambxst;

        // Store ambxst core keybinds
        previousAmbxstBinds = {
            ambxst: {
                launcher: cloneKeybind(ambxst.launcher),
                dashboard: cloneKeybind(ambxst.dashboard),
                assistant: cloneKeybind(ambxst.assistant),
                clipboard: cloneKeybind(ambxst.clipboard),
                emoji: cloneKeybind(ambxst.emoji),
                notes: cloneKeybind(ambxst.notes),
                tmux: cloneKeybind(ambxst.tmux),
                wallpapers: cloneKeybind(ambxst.wallpapers)
            },
            system: {
                overview: cloneKeybind(ambxst.system.overview),
                powermenu: cloneKeybind(ambxst.system.powermenu),
                config: cloneKeybind(ambxst.system.config),
                lockscreen: cloneKeybind(ambxst.system.lockscreen),
                tools: cloneKeybind(ambxst.system.tools),
                screenshot: cloneKeybind(ambxst.system.screenshot),
                screenrecord: cloneKeybind(ambxst.system.screenrecord),
                lens: cloneKeybind(ambxst.system.lens),
                reload: ambxst.system.reload ? cloneKeybind(ambxst.system.reload) : null,
                quit: ambxst.system.quit ? cloneKeybind(ambxst.system.quit) : null
            }
        };

        // Store custom keybinds
        const customBinds = Config.keybindsLoader.adapter.custom;
        previousCustomBinds = [];
        if (customBinds && customBinds.length > 0) {
            for (let i = 0; i < customBinds.length; i++) {
                const bind = customBinds[i];
                if (bind.keys) {
                    let keys = [];
                    for (let k = 0; k < bind.keys.length; k++) {
                        keys.push(cloneKeybind(bind.keys[k]));
                    }
                    previousCustomBinds.push({
                        keys: keys
                    });
                } else {
                    previousCustomBinds.push(cloneKeybind(bind));
                }
            }
        }

        hasPreviousBinds = true;
    }

    function applyKeybindsInternal() {
        // Ensure adapter is loaded.
        if (!Config.keybindsLoader.loaded) {
            console.log("HyprlandKeybinds: Esperando que se cargue el adapter...");
            return;
        }

        // Wait for layout to be ready.
        if (!GlobalStates.hyprlandLayoutReady) {
            console.log("HyprlandKeybinds: Esperando que se detecte el layout de Hyprland...");
            return;
        }

        console.log("HyprlandKeybinds: Aplicando keybindings (layout: " + GlobalStates.hyprlandLayout + ")...");

        // Build unbind list.
        let unbindCommands = [];

        // Format modifiers.
        function formatModifiers(modifiers) {
            if (!modifiers || modifiers.length === 0)
                return "";
            return modifiers.join(" ");
        }

        // Create bind command (old format).
        function createBindCommand(keybind, flags) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            const dispatcher = keybind.dispatcher;
            const argument = keybind.argument || "";
            const bindKeyword = flags ? `bind${flags}` : "bind";
            // For bindm, omit argument if empty.
            if (flags === "m" && !argument) {
                return `keyword ${bindKeyword} ${mods},${key},${dispatcher}`;
            }
            return `keyword ${bindKeyword} ${mods},${key},${dispatcher},${argument}`;
        }

        // Create unbind command (old format).
        function createUnbindCommand(keybind) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            return `keyword unbind ${mods},${key}`;
        }

        // Create unbind command from key object (new format).
        function createUnbindFromKey(keyObj) {
            const mods = formatModifiers(keyObj.modifiers);
            const key = keyObj.key;
            return `keyword unbind ${mods},${key}`;
        }

        // Create bind command from key + action (new format).
        function createBindFromKeyAction(keyObj, action) {
            const mods = formatModifiers(keyObj.modifiers);
            const key = keyObj.key;
            const dispatcher = action.dispatcher;
            const argument = action.argument || "";
            const flags = action.flags || "";
            const bindKeyword = flags ? `bind${flags}` : "bind";
            // For bindm, omit argument if empty.
            if (flags === "m" && !argument) {
                return `keyword ${bindKeyword} ${mods},${key},${dispatcher}`;
            }
            return `keyword ${bindKeyword} ${mods},${key},${dispatcher},${argument}`;
        }

        // Build batch command for all binds.
        let batchCommands = [];

        // First, unbind previous keybinds if we have them stored
        if (hasPreviousBinds) {
            // Unbind previous ambxst core keybinds
            if (previousAmbxstBinds.ambxst) {
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.launcher));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.dashboard));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.assistant));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.clipboard));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.emoji));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.notes));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.tmux));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.ambxst.wallpapers));
            }

            // Unbind previous ambxst system keybinds
            if (previousAmbxstBinds.system) {
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.overview));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.powermenu));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.config));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.lockscreen));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.tools));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.screenshot));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.screenrecord));
                unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.lens));
                if (previousAmbxstBinds.system.reload) unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.reload));
                if (previousAmbxstBinds.system.quit) unbindCommands.push(createUnbindCommand(previousAmbxstBinds.system.quit));
            }

            // Unbind previous custom keybinds
            for (let i = 0; i < previousCustomBinds.length; i++) {
                const prev = previousCustomBinds[i];
                if (prev.keys) {
                    for (let k = 0; k < prev.keys.length; k++) {
                        unbindCommands.push(createUnbindFromKey(prev.keys[k]));
                    }
                } else {
                    unbindCommands.push(createUnbindCommand(prev));
                }
            }
        }

        // Process core keybinds.
        const ambxst = Config.keybindsLoader.adapter.ambxst;

        // Core keybinds
        unbindCommands.push(createUnbindCommand(ambxst.launcher));
        unbindCommands.push(createUnbindCommand(ambxst.dashboard));
        unbindCommands.push(createUnbindCommand(ambxst.assistant));
        unbindCommands.push(createUnbindCommand(ambxst.clipboard));
        unbindCommands.push(createUnbindCommand(ambxst.emoji));
        unbindCommands.push(createUnbindCommand(ambxst.notes));
        unbindCommands.push(createUnbindCommand(ambxst.tmux));
        unbindCommands.push(createUnbindCommand(ambxst.wallpapers));

        batchCommands.push(createBindCommand(ambxst.launcher, ambxst.launcher.flags || ""));
        batchCommands.push(createBindCommand(ambxst.dashboard, ambxst.dashboard.flags || ""));
        batchCommands.push(createBindCommand(ambxst.assistant, ambxst.assistant.flags || ""));
        batchCommands.push(createBindCommand(ambxst.clipboard, ambxst.clipboard.flags || ""));
        batchCommands.push(createBindCommand(ambxst.emoji, ambxst.emoji.flags || ""));
        batchCommands.push(createBindCommand(ambxst.notes, ambxst.notes.flags || ""));
        batchCommands.push(createBindCommand(ambxst.tmux, ambxst.tmux.flags || ""));
        batchCommands.push(createBindCommand(ambxst.wallpapers, ambxst.wallpapers.flags || ""));

        // System keybinds
        const system = ambxst.system;
        unbindCommands.push(createUnbindCommand(system.overview));
        unbindCommands.push(createUnbindCommand(system.powermenu));
        unbindCommands.push(createUnbindCommand(system.config));
        unbindCommands.push(createUnbindCommand(system.lockscreen));
        unbindCommands.push(createUnbindCommand(system.tools));
        unbindCommands.push(createUnbindCommand(system.screenshot));
        unbindCommands.push(createUnbindCommand(system.screenrecord));
        unbindCommands.push(createUnbindCommand(system.lens));
        if (system.reload) unbindCommands.push(createUnbindCommand(system.reload));
        if (system.quit) unbindCommands.push(createUnbindCommand(system.quit));

        batchCommands.push(createBindCommand(system.overview, system.overview.flags || ""));
        batchCommands.push(createBindCommand(system.powermenu, system.powermenu.flags || ""));
        batchCommands.push(createBindCommand(system.config, system.config.flags || ""));
        batchCommands.push(createBindCommand(system.lockscreen, system.lockscreen.flags || ""));
        batchCommands.push(createBindCommand(system.tools, system.tools.flags || ""));
        batchCommands.push(createBindCommand(system.screenshot, system.screenshot.flags || ""));
        batchCommands.push(createBindCommand(system.screenrecord, system.screenrecord.flags || ""));
        batchCommands.push(createBindCommand(system.lens, system.lens.flags || ""));
        if (system.reload) batchCommands.push(createBindCommand(system.reload, system.reload.flags || ""));
        if (system.quit) batchCommands.push(createBindCommand(system.quit, system.quit.flags || ""));

        // Process custom keybinds (keys[] and actions[] format).
        const customBinds = Config.keybindsLoader.adapter.custom;
        if (customBinds && customBinds.length > 0) {
            for (let i = 0; i < customBinds.length; i++) {
                const bind = customBinds[i];

                // Check if bind has the new format
                if (bind.keys && bind.actions) {
                    // Unbind all keys first (always unbind regardless of layout)
                    for (let k = 0; k < bind.keys.length; k++) {
                        unbindCommands.push(createUnbindFromKey(bind.keys[k]));
                    }

                    // Only create binds if enabled
                    if (bind.enabled !== false) {
                        // For each key, bind only compatible actions
                        for (let k = 0; k < bind.keys.length; k++) {
                            for (let a = 0; a < bind.actions.length; a++) {
                                const action = bind.actions[a];
                                // Check if this action is compatible with the current layout
                                if (isActionCompatibleWithLayout(action)) {
                                    batchCommands.push(createBindFromKeyAction(bind.keys[k], action));
                                }
                            }
                        }
                    }
                } else {
                    // Fallback for old format (shouldn't happen after normalization)
                    unbindCommands.push(createUnbindCommand(bind));
                    if (bind.enabled !== false) {
                        const flags = bind.flags || "";
                        batchCommands.push(createBindCommand(bind, flags));
                    }
                }
            }
        }

        storePreviousBinds();

        // Combine unbind and bind in a single batch.
        const fullBatchCommand = unbindCommands.join("; ") + "; " + batchCommands.join("; ");

        console.log("HyprlandKeybinds: Ejecutando batch command");
        hyprctlProcess.command = ["sh", "-c", `hyprctl --batch "${fullBatchCommand}"`];
        hyprctlProcess.running = true;
    }

    property Connections configConnections: Connections {
        target: Config.keybindsLoader
        function onFileChanged() {
            applyKeybinds();
        }
        function onLoaded() {
            applyKeybinds();
        }
        function onAdapterUpdated() {
            applyKeybinds();
        }
    }

    // Re-apply keybinds when layout changes
    property Connections globalStatesConnections: Connections {
        target: GlobalStates
        function onHyprlandLayoutChanged() {
            console.log("HyprlandKeybinds: Layout changed to " + GlobalStates.hyprlandLayout + ", reapplying keybindings...");
            applyKeybinds();
        }
        function onHyprlandLayoutReadyChanged() {
            if (GlobalStates.hyprlandLayoutReady) {
                applyKeybinds();
            }
        }
    }

    property Connections hyprlandConnections: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                console.log("HyprlandKeybinds: Detectado configreloaded, reaplicando keybindings...");
                applyKeybinds();
            }
        }
    }

    Component.onCompleted: {
        // Apply immediately if loader is ready.
        if (Config.keybindsLoader.loaded) {
            applyKeybinds();
        }
    }
}
