import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.ii.ui 1.0
import "." as Bar

Item {
    id: s

    visible: false
    width: 0
    height: 0

    property var screen: null
    property int monitorIndex: -1

    property bool hasActiveWindows: false
    property var brightnessMonitor: null

    function recomputeBrightnessMonitor() {
        s.brightnessMonitor = Brightness.getMonitorForScreen(s.screen)
    }

    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)
    readonly property bool bgIsAdaptive: barBackgroundStyleFromConfig === 2 || (Config?.options?.bar?.followGlobalBarStyle && UIState.surfaceStyle === "adaptive")
    readonly property bool needsWindowAwareness: bgIsAdaptive

    function resolveMonitorForThisBar() {
        if (!HyprlandData) return null

        if (s.monitorIndex >= 0) {
            const byId = HyprlandData.monitors.find(m => m.id === s.monitorIndex)
            if (byId) return byId
        }

        const scrName = s.screen?.name
        if (scrName) {
            const byName = HyprlandData.monitors.find(m => m.name === scrName)
            if (byName) return byName
        }

        return null
    }

    function recomputeHasWindows() {
        if (!HyprlandData) {
            s.hasActiveWindows = false
            return
        }

        const monitor = resolveMonitorForThisBar()
        const wsId = monitor?.activeWorkspace?.id ?? null

        if (!wsId) {
            s.hasActiveWindows = false
            return
        }

        s.hasActiveWindows = HyprlandData.windowList.some(w =>
            (w.workspace?.id === wsId) && !w.floating
        )
    }

    function scheduleHasWindowsRecompute() {
        if (!s.needsWindowAwareness) return
        hyprRecomputeTimer.restart()
    }

    Timer {
        id: hyprRecomputeTimer
        interval: 60
        repeat: false
        onTriggered: s.recomputeHasWindows()
    }

    Connections {
        enabled: s.needsWindowAwareness
        target: HyprlandData
        function onWindowListChanged() { s.scheduleHasWindowsRecompute() }
        function onMonitorsChanged() { s.scheduleHasWindowsRecompute() }
    }

    onMonitorIndexChanged: scheduleHasWindowsRecompute()
    onScreenChanged: scheduleHasWindowsRecompute()

    Component.onCompleted: {
        if (s.needsWindowAwareness) hyprRecomputeTimer.restart()
        else s.hasActiveWindows = false

        s.recomputeBrightnessMonitor()
    }
}
