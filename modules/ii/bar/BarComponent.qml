import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.ii.bar.weather
import qs.modules.ii.verticalBar as Vertical

Item {
    id: rootItem

    // 0: left, 1: center, 2: right
    property int barSection: 0
    property var list: []
    required property var modelData
    required property int index
    property int originalIndex: index
    property bool vertical: false

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    readonly property bool isLeft: barSection === 0
    readonly property bool isCenter: barSection === 1
    readonly property bool isRight: barSection === 2

    readonly property var safeList: (Array.isArray(list) ? list : [])

    function toggleVisible(visibility) {
        rootItem.visible = visibility

        const layouts = Config?.options?.bar?.layouts
        if (!layouts) return

        let arr = null
        if (rootItem.isLeft) arr = layouts.left
        else if (rootItem.isCenter) arr = layouts.center
        else if (rootItem.isRight) arr = layouts.right

        if (!arr) return
        if (rootItem.originalIndex < 0 || rootItem.originalIndex >= arr.length) return
        if (!arr[rootItem.originalIndex]) return

        arr[rootItem.originalIndex].visible = visibility
    }

    // [horizontal, vertical]
    // FIX: Añadidos alias para que funcionen los IDs:
    // - left_sidebar_button
    // - right_sidebar_button
    // Sin depender de que existan tipos QML LeftSidebarButton/RightSidebarButton.
    property var compMap: ({
        "workspaces": [workspaceComp, workspaceComp],
        "music_player": [musicPlayerComp, musicPlayerCompVert],
        "system_monitor": [systemMonitorComp, systemMonitorCompVert],
        "clock": [clockComp, clockCompVert],
        "battery": [batteryComp, batteryCompVert],
        "utility_buttons": [utilityButtonsComp, utilityButtonsComp],
        "system_tray": [systemTrayComp, systemTrayComp],
        "active_window": [activeWindowComp, activeWindowComp],
        "date": [dateCompVert, dateCompVert],
        "record_indicator": [recordIndicatorComp, recordIndicatorComp],
        "screen_share_indicator": [screenshareIndicatorComp, screenshareIndicatorComp],
        "timer": [timerComp, timerCompVert],
        "weather": [weatherComp, weatherComp],

        // IDs “nuevos”
        "policies_panel_button": [policiesPanelButtonComp, policiesPanelButtonComp],
        "dashboard_panel_button": [dashboardPanelButtonComp, dashboardPanelButtonCompVert],

        // IDs “sidebar” (alias para compatibilidad con tu layout/config)
        "left_sidebar_button": [policiesPanelButtonComp, policiesPanelButtonComp],
        "right_sidebar_button": [dashboardPanelButtonComp, dashboardPanelButtonCompVert]
    })

    property var primaryBackgroundComps: ["timer", "record_indicator", "screen_share_indicator"]

    function anyVisibleBefore(i) {
        return rootItem.safeList.slice(0, i).some(item => item && item.visible !== false)
    }
    function anyVisibleAfter(i) {
        return rootItem.safeList.slice(i + 1).some(item => item && item.visible !== false)
    }

    property real startRadius: {
        if (rootItem.isLeft) {
            return (rootItem.originalIndex === 0) ? Appearance.rounding.full : Appearance.rounding.verysmall
        } else if (rootItem.isRight) {
            return rootItem.anyVisibleBefore(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        } else { // center
            if (rootItem.safeList.length <= 1) return Appearance.rounding.full
            return rootItem.anyVisibleBefore(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    property real endRadius: {
        if (rootItem.isRight) {
            return (rootItem.originalIndex === rootItem.safeList.length - 1) ? Appearance.rounding.full : Appearance.rounding.verysmall
        } else if (rootItem.isLeft) {
            return rootItem.anyVisibleAfter(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        } else { // center
            if (rootItem.safeList.length <= 1) return Appearance.rounding.full
            return rootItem.anyVisibleAfter(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    BarGroup {
        id: wrapper
        vertical: rootItem.vertical

        anchors {
            verticalCenter: rootItem.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: rootItem.vertical ? undefined : rootItem.horizontalCenter
        }

        startRadius: rootItem.startRadius
        endRadius: rootItem.endRadius

        colBackground: (rootItem.modelData && rootItem.primaryBackgroundComps.includes(rootItem.modelData.id))
            ? Appearance.m3colors.m3primary
            : Appearance.m3colors.m3surfaceContainerLow

        // EXPLÍCITO: esto va al default property alias "items"
        items: Loader {
            id: itemLoader
            active: true

            readonly property string itemId: (rootItem.modelData && rootItem.modelData.id) ? rootItem.modelData.id : ""
            readonly property var pair: rootItem.compMap[itemId]
            readonly property var chosen: (pair && pair.length >= 2) ? pair[rootItem.vertical ? 1 : 0] : null

            sourceComponent: chosen ? chosen : unknownComp
        }
    }

    Component {
        id: unknownComp
        Item { implicitWidth: 1; implicitHeight: 1 }
    }

    Component { id: weatherComp; WeatherBar { vertical: rootItem.vertical } }

    Component { id: timerComp; TimerWidget {} }
    Component { id: timerCompVert; Vertical.VerticalTimerWidget {} }

    Component { id: screenshareIndicatorComp; ScreenShareIndicator {} }

    Component { id: recordIndicatorComp; RecordIndicator { vertical: rootItem.vertical } }

    Component { id: activeWindowComp; ActiveWindow { vertical: rootItem.vertical } }

    Component { id: systemMonitorComp; Resources {} }
    Component { id: systemMonitorCompVert; Vertical.Resources {} }

    Component { id: musicPlayerComp; Media {} }
    Component { id: musicPlayerCompVert; Vertical.VerticalMedia {} }

    Component { id: utilityButtonsComp; UtilButtons { vertical: rootItem.vertical } }

    Component { id: batteryComp; BatteryIndicator {} }
    Component { id: batteryCompVert; Vertical.BatteryIndicator {} }

    Component { id: clockComp; ClockWidget {} }
    Component { id: clockCompVert; Vertical.VerticalClockWidget {} }

    Component { id: systemTrayComp; SysTray { vertical: rootItem.vertical } }

    Component { id: dateCompVert; Vertical.VerticalDateWidget {} }

    Component { id: workspaceComp; Workspaces { vertical: rootItem.vertical } }

    Component { id: policiesPanelButtonComp; PoliciesPanelButton {} }

    Component { id: dashboardPanelButtonComp; DashboardPanelButton {} }
    Component { id: dashboardPanelButtonCompVert; VerticalDashboardPanelButton {} }
}

