import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.ii.bar.weather
import qs.modules.ii.verticalBar as Vertical
import Quickshell.Services.Mpris

Item {
    id: rootItem

    property int barSection: 0
    property var list: []
    required property var modelData
    required property int index
    property int originalIndex: index
    property bool vertical: false

    property alias isContainer: wrapper.isContainer
    property alias forceNoContainer: wrapper.forceNoContainer
    
    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    readonly property bool isLeft: barSection === 0
    readonly property bool isCenter: barSection === 1
    readonly property bool isRight: barSection === 2

    readonly property var safeList: (Array.isArray(list) ? list : [])

    readonly property bool isMusicPlayer: (rootItem.modelData && rootItem.modelData.id === "music_player")

    readonly property bool musicHasMedia: (MprisController.activePlayer !== null)
        && (MprisController.activePlayer.playbackState !== MprisPlaybackState.Stopped)

    property bool userVisible: (rootItem.modelData ? (rootItem.modelData.visible !== false) : true)

    readonly property bool effectiveVisible: rootItem.userVisible

    visible: effectiveVisible

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.55 }
    function _on(bg, a) { return _isDark(bg) ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a) }

    readonly property color groupBg: wrapper.colBackground

    readonly property color onStrong: _on(groupBg, 0.95)
    readonly property color onNormal: _on(groupBg, 0.86)
    readonly property color onMuted:  _on(groupBg, 0.62)
    readonly property color onIcon:   _on(groupBg, 0.90)

    readonly property color chipBg: _isDark(groupBg)
        ? Qt.rgba(1, 1, 1, 0.10)
        : Qt.rgba(0, 0, 0, 0.08)

    readonly property color chipBorder: _isDark(groupBg)
        ? Qt.rgba(1, 1, 1, 0.16)
        : Qt.rgba(0, 0, 0, 0.14)

    function toggleVisible(visibility) {
        rootItem.userVisible = visibility

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

    property var compMap: ({
        "workspaces": [workspaceComp, workspaceComp],

        "music_player": [musicPlayerComp, musicPlayerCompVert],

        "system_monitor": [hybridResUtilComp, systemMonitorCompVert],
        "clock": [hybridClockComp, clockCompVert],

        "battery": [batteryComp, batteryCompVert],

        "utility_buttons": [unknownComp, unknownComp],

        "system_tray": [systemTrayComp, systemTrayComp],
        "active_window": [activeWindowComp, activeWindowComp],
        "date": [dateCompVert, dateCompVert],
        "record_indicator": [recordIndicatorComp, recordIndicatorComp],
        "screen_share_indicator": [screenshareIndicatorComp, screenshareIndicatorComp],

        "timer": [timerComp, timerComp],

        "weather": [weatherComp, weatherComp],

        "policies_panel_button": [policiesPanelButtonComp, policiesPanelButtonComp],
        "dashboard_panel_button": [dashboardPanelButtonComp, dashboardPanelButtonCompVert],

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
        } else {
            if (rootItem.safeList.length <= 1) return Appearance.rounding.full
            return rootItem.anyVisibleBefore(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    property real endRadius: {
        if (rootItem.isRight) {
            return (rootItem.originalIndex === rootItem.safeList.length - 1) ? Appearance.rounding.full : Appearance.rounding.verysmall
        } else if (rootItem.isLeft) {
            return rootItem.anyVisibleAfter(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        } else {
            if (rootItem.safeList.length <= 1) return Appearance.rounding.full
            return rootItem.anyVisibleAfter(rootItem.originalIndex) ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    function applyTokens(item) {
        if (!item) return
        if (item.onStrong !== undefined) item.onStrong = rootItem.onStrong
        if (item.onNormal !== undefined) item.onNormal = rootItem.onNormal
        if (item.onMuted !== undefined)  item.onMuted  = rootItem.onMuted
        if (item.onIcon !== undefined)   item.onIcon   = rootItem.onIcon
        if (item.chipBg !== undefined) item.chipBg = rootItem.chipBg
        if (item.chipBorder !== undefined) item.chipBorder = rootItem.chipBorder
        if (item.textColor !== undefined) item.textColor = rootItem.onStrong
        if (item.iconColor !== undefined) item.iconColor = rootItem.onIcon
        if (item.mutedTextColor !== undefined) item.mutedTextColor = rootItem.onMuted
        if (item.backgroundColor !== undefined) item.backgroundColor = rootItem.groupBg
    }

    BarGroup {
        id: wrapper
        vertical: rootItem.vertical
        visible: rootItem.effectiveVisible

        forcePillStyle: !rootItem.isCenter 

        anchors {
            verticalCenter: rootItem.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: rootItem.vertical ? undefined : rootItem.horizontalCenter
        }
        
        startRadius: rootItem.startRadius
        endRadius: rootItem.endRadius

        colBackground: (rootItem.modelData && rootItem.primaryBackgroundComps.includes(rootItem.modelData.id))
            ? Appearance.m3colors.m3primary
            : Appearance.m3colors.m3surfaceContainerLow

        items: Loader {
            id: itemLoader
            active: rootItem.effectiveVisible

            readonly property string itemId: (rootItem.modelData && rootItem.modelData.id) ? rootItem.modelData.id : ""
            readonly property var pair: rootItem.compMap[itemId]
            readonly property var chosen: (pair && pair.length >= 2) ? pair[rootItem.vertical ? 1 : 0] : null

            sourceComponent: chosen ? chosen : unknownComp

            onLoaded: rootItem.applyTokens(item)
        }
    }

    Component {
        id: unknownComp
        Item { implicitWidth: 1; implicitHeight: 1 }
    }

    Component { id: weatherComp; WeatherBar { vertical: rootItem.vertical } }

    Component { id: timerComp; TimerWidget { } }

    Component { id: screenshareIndicatorComp; ScreenShareIndicator { } }

    Component { id: recordIndicatorComp; RecordIndicator { vertical: rootItem.vertical } }

    Component { id: activeWindowComp; ActiveWindow { vertical: rootItem.vertical } }

    Component { id: systemMonitorComp; Resources { } }
    Component { id: systemMonitorCompVert; Vertical.Resources { } }

    Component { id: musicPlayerComp; Media { vertical: rootItem.vertical } }
    Component { id: musicPlayerCompVert; Media { vertical: rootItem.vertical } }

    Component { id: utilityButtonsComp; UtilButtons { vertical: rootItem.vertical } }

    Component { id: batteryComp; BatteryIndicator { } }
    Component { id: batteryCompVert; Vertical.BatteryIndicator { } }

    Component { id: hybridClockComp; HybridClockWeather { } }

    Component { id: hybridResUtilComp; HybridResourcesUtilButtons { } }

    Component { id: clockComp; ClockWidget { } }
    Component { id: clockCompVert; Vertical.VerticalClockWidget { } }

    Component { id: systemTrayComp; SysTray { vertical: rootItem.vertical } }

    Component { id: dateCompVert; Vertical.VerticalDateWidget { } }

    Component { id: workspaceComp; Workspaces { vertical: rootItem.vertical } }

    Component { id: policiesPanelButtonComp; PoliciesPanelButton { } }

    Component { id: dashboardPanelButtonComp; DashboardPanelButton { } }
    Component { id: dashboardPanelButtonCompVert; VerticalDashboardPanelButton { } }
}
