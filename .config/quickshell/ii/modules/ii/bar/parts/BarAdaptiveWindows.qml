// parts/BarAdaptiveWindows.qml
import QtQuick
import Quickshell.Hyprland

Item {
    id: aw

    // Invisible helper item (solo lógica)
    width: 0
    height: 0
    visible: false

    required property var screen
    required property int monitorIndex

    // Control externo: solo habilitar cuando bgIsAdaptive sea true
    property bool enabled: true

    property bool hasActiveWindows: false

    function resolveMonitorForThisBar() {
        if (!HyprlandData) return null

        if (aw.monitorIndex >= 0) {
            const byId = HyprlandData.monitors.find(m => m && m.id === aw.monitorIndex)
            if (byId) return byId
        }

        const scrName = aw.screen?.name
        if (scrName) {
            const byName = HyprlandData.monitors.find(m => m && m.name === scrName)
            if (byName) return byName
        }

        return null
    }

    function recomputeHasWindows() {
        if (!HyprlandData) {
            aw.hasActiveWindows = false
            return
        }

        const monitor = resolveMonitorForThisBar()
        const wsId = monitor?.activeWorkspace?.id ?? null

        if (!wsId) {
            aw.hasActiveWindows = false
            return
        }

        aw.hasActiveWindows = HyprlandData.windowList.some(w =>
            (w.workspace?.id === wsId) && !w.floating
        )
    }

    Timer {
        id: hyprRecomputeTimer
        interval: 60
        repeat: false
        onTriggered: aw.recomputeHasWindows()
    }

    Connections {
        enabled: aw.enabled
        target: HyprlandData

        function schedule() { hyprRecomputeTimer.restart() }
        function onWindowListChanged() { schedule() }
        function onMonitorsChanged() { schedule() }
    }

    onEnabledChanged: {
        if (aw.enabled) hyprRecomputeTimer.restart()
    }

    onMonitorIndexChanged: {
        if (aw.enabled) hyprRecomputeTimer.restart()
    }

    onScreenChanged: {
        if (aw.enabled) hyprRecomputeTimer.restart()
    }

    function kick() {
        if (aw.enabled) hyprRecomputeTimer.restart()
    }
}

