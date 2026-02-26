pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: ui

    // Estilo global
    // "solid" | "glass" | "crystal" | "adaptive"
    property string surfaceStyle: "crystal"

    // Helpers estilo (global)
    readonly property bool isCrystal: surfaceStyle === "crystal"
    readonly property bool isGlass: surfaceStyle === "glass" || surfaceStyle === "crystal"
    readonly property bool isSolid: surfaceStyle === "solid"
    readonly property bool isAdaptive: surfaceStyle === "adaptive"

    // Ventanas (para "adaptive")
    function _safeLen(x) {
        if (x === null || x === undefined) return 0
        if (typeof x === "number") return x
        if (x.length !== undefined) return x.length
        if (x.count !== undefined) return x.count
        return 0
    }

    function _windowCount() {
            try {
            const h = Hyprland
            if (!h) return 0

            if (h.clients !== undefined) return _safeLen(h.clients)
            if (h.toplevels !== undefined) return _safeLen(h.toplevels)
            if (h.windows !== undefined) return _safeLen(h.windows)

            // Algunos exponen "workspaces" y dentro "windows"
            if (h.workspaces !== undefined && h.workspaces.length !== undefined) {
                let total = 0
                for (let i = 0; i < h.workspaces.length; i++) {
                    const ws = h.workspaces[i]
                    if (ws && ws.windows !== undefined) total += _safeLen(ws.windows)
                }
                return total
            }
        } catch (e) {
            return 0
        }
        return 0
    }

    // Si hay al menos una ventana/toplevel, consideramos "hay ventanas"
    readonly property bool hasWindows: _windowCount() > 0
}

