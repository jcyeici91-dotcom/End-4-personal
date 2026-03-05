pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: ui

    property string surfaceStyle: "crystal"

    readonly property bool isCrystal: surfaceStyle === "crystal"
    readonly property bool isGlass: surfaceStyle === "glass" || surfaceStyle === "crystal"
    readonly property bool isSolid: surfaceStyle === "solid"
    readonly property bool isAdaptive: surfaceStyle === "adaptive"

    function _safeLen(x) {
        return x ? (typeof x === "number" ? x : (x.length ?? x.count ?? 0)) : 0
    }

    readonly property bool hasWindows: {
        if (!Hyprland) return false

        const total = _safeLen(Hyprland.clients) || _safeLen(Hyprland.toplevels) || _safeLen(Hyprland.windows)
        if (total > 0) return true

        if (Hyprland.workspaces) {
            for (let i = 0; i < Hyprland.workspaces.length; ++i) {
                if (_safeLen(Hyprland.workspaces[i]?.windows) > 0) return true
            }
        }

        return false
    }
}
