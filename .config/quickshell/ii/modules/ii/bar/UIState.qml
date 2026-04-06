pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: ui

    property string surfaceStyle: "crystal"

    function _normStyle(s) {
        s = (s ?? "").toString().trim().toLowerCase()
        if (s === "glass" || s === "crystal" || s === "solid" ) return s
        return "crystal"
    }

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

    readonly property string resolvedSurfaceStyle: {
        const s = _normStyle(surfaceStyle)
        if (s !== "adaptive") return s
        return hasWindows ? "crystal" : "solid"
    }

    readonly property bool isCrystal: resolvedSurfaceStyle === "crystal"
    readonly property bool isGlass: resolvedSurfaceStyle === "glass" || resolvedSurfaceStyle === "crystal"
    readonly property bool isSolid: resolvedSurfaceStyle === "solid"
  

    readonly property bool useGlassMode: isGlass
    readonly property bool showSolidBackground: isSolid
    readonly property bool useCrystalOverlay: isCrystal
    readonly property bool useGlassBlur: isGlass
}

