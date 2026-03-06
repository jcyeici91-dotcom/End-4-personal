import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Io
import qs.modules.ii.ui 1.0
import "." as Bar

Item {
    id: root

    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1
    property var brightnessMonitor: null

    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    property bool hasActiveWindows: false

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        switch (v) {
            case 0: return "glass"
            case 1: return "solid"
            case 2: return "adaptive"
            case 3: return "crystal"
            default: return "solid"
        }
    }

    function _styleFromUIState() {
        const s = UIState.surfaceStyle
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"
    readonly property bool bgIsAdaptive: resolvedStyle === "adaptive"
    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)

    readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")
    readonly property int cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)
    readonly property bool isBottom: (Config?.options?.bar?.bottom ?? false)

    readonly property int hybridResizeMs: 85
    readonly property int pillGap: 8

    function resolveMonitorForThisBar() {
        if (!HyprlandData) return null
        if (root.monitorIndex >= 0) {
            const byId = HyprlandData.monitors.find(m => m.id === root.monitorIndex)
            if (byId) return byId
        }
        const scrName = root.screen?.name
        if (scrName) {
            const byName = HyprlandData.monitors.find(m => m.name === scrName)
            if (byName) return byName
        }
        return null
    }

    function recomputeHasWindows() {
        if (!HyprlandData) {
            root.hasActiveWindows = false
            return
        }
        const monitor = resolveMonitorForThisBar()
        const wsId = monitor?.activeWorkspace?.id ?? null
        if (!wsId) {
            root.hasActiveWindows = false
            return
        }
        root.hasActiveWindows = HyprlandData.windowList.some(w =>
            (w.workspace?.id === wsId) && !w.floating
        )
    }

    Timer {
        id: hyprRecomputeTimer
        interval: 60
        repeat: false
        onTriggered: root.recomputeHasWindows()
    }

    Connections {
        enabled: root.bgIsAdaptive
        target: HyprlandData
        function onWindowListChanged() { hyprRecomputeTimer.restart() }
        function onMonitorsChanged() { hyprRecomputeTimer.restart() }
    }

    onMonitorIndexChanged: if (root.bgIsAdaptive) hyprRecomputeTimer.restart()

    onScreenChanged: {
        recomputeBrightnessMonitor()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }

    function sendWrappedFrameState() {
        try {
            Quickshell.Io.Ipc.call("wrappedFrame", "setBarState", [
                root.resolvedStyle,
                root.hasActiveWindows,
                root.useHybridGroups,
                root.cornerStyle
            ])
        } catch (e) {}
    }

    onHasActiveWindowsChanged: sendWrappedFrameState()
    onResolvedStyleChanged: sendWrappedFrameState()
    onUseHybridGroupsChanged: sendWrappedFrameState()
    onCornerStyleChanged: sendWrappedFrameState()

    property var fullModel: (Config?.options?.bar?.layouts?.center ?? [])
    property var leftList: []
    property var centerList: []
    property var rightList: []

    function recomputeCenterSplit() {
        const model = root.fullModel
        if (!model || model.length === undefined) {
            root.leftList = []
            root.centerList = []
            root.rightList = []
            return
        }
        const idx = model.findIndex(item => item && item.centered === true)
        if (idx === -1) {
            root.leftList = []
            root.centerList = model
            root.rightList = []
            return
        }
        root.leftList = model.slice(0, idx)
        root.centerList = [model[idx]]
        root.rightList = model.slice(idx + 1)
    }

    onFullModelChanged: recomputeCenterSplit()

    FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: middleSection.left
        implicitHeight: Appearance.sizes.baseBarHeight
        onScrollDown: if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
        }
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: leftStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Math.max(8, Math.ceil(Appearance.rounding.screenRounding / 2))
        width: 1
    }

    Loader {
        id: leftContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftStopper.right
        anchors.leftMargin: 6
        active: true
        sourceComponent: root.useHybridGroups ? leftHybridComponent : leftClassicComponent
    }

    Component {
        id: leftClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.left
                delegate: BarComponent { list: Config.options.bar.layouts.left; barSection: 0 }
            }
        }
    }

    Component {
        id: leftHybridComponent
        Bar.BarGroup {
            forcePillStyle: true
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenLeft: false
            width: implicitWidth
            Behavior on width { NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } }
            Repeater {
                model: Config.options.bar.layouts.left
                delegate: BarComponent { list: Config.options.bar.layouts.left; barSection: 0 }
            }
        }
    }

    Item {
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: root.useHybridGroups ? middleHybridComponent : middleClassicComponent
        }

        Component {
            id: middleClassicComponent
            Item {
                anchors.fill: parent
                RowLayout {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: centerCenter.left
                    anchors.rightMargin: 4
                    Repeater {
                        model: root.leftList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
                RowLayout {
                    id: centerCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: root.centerList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
                RowLayout {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: centerCenter.right
                    anchors.leftMargin: 4
                    Repeater {
                        model: root.rightList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
            }
        }

        Component {
            id: middleHybridComponent
            Item {
                anchors.fill: parent

                Bar.BarGroup {
                    id: centerCenterGroup
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    vertical: false
                    spacing: 4
                    isContainer: true
                    autoHide: true
                    padding: 6
                    edgeInset: 2
                    width: implicitWidth
                    Behavior on width { NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: root.centerList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }

                Loader {
                    id: centerLeftLoader
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: centerCenterGroup.left
                    anchors.rightMargin: root.pillGap
                    active: (root.leftList && root.leftList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: 4
                        isContainer: true
                        autoHide: true
                        padding: 6
                        edgeInset: 2
                        forcePillStyle: true
                        width: implicitWidth
                        Behavior on width { NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: root.leftList
                            delegate: BarComponent {
                                list: Config.options.bar.layouts.center
                                barSection: 1
                                originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                            }
                        }
                    }
                }

                Loader {
                    id: centerRightLoader
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: centerCenterGroup.right
                    anchors.leftMargin: root.pillGap
                    active: (root.rightList && root.rightList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: 4
                        isContainer: true
                        autoHide: true
                        padding: 6
                        edgeInset: 2
                        forcePillStyle: true
                        width: implicitWidth
                        Behavior on width { NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: root.rightList
                            delegate: BarComponent {
                                list: Config.options.bar.layouts.center
                                barSection: 1
                                originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: rightStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
    }

    Loader {
        id: rightContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: rightStopper.left
        anchors.rightMargin: Math.max(8, Math.ceil(Appearance.rounding.screenRounding / 2)) + 6
        active: true
        sourceComponent: root.useHybridGroups ? rightHybridComponent : rightClassicComponent
    }

    Component {
        id: rightClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.right
                delegate: BarComponent { list: Config.options.bar.layouts.right; barSection: 2 }
            }
        }
    }

    Component {
        id: rightHybridComponent
        Bar.BarGroup {
            forcePillStyle: true
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenRight: false
            width: implicitWidth
            Behavior on width { NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } }
            Repeater {
                model: Config.options.bar.layouts.right
                delegate: BarComponent { list: Config.options.bar.layouts.right; barSection: 2 }
            }
        }
    }

    FocusedScrollMouseArea {
        id: barRightSideMouseArea
        z: -1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: middleSection.right
        anchors.right: parent.right
        implicitHeight: Appearance.sizes.baseBarHeight
        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        }
        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
        sendWrappedFrameState()
    }
}

