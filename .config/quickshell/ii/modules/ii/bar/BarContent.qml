pragma ComponentBehavior: Bound

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
import qs.modules.ii.bar.weather
import "." as Bar

Item {
    id: root

    property bool enableAnimations: Config.options.appearance.enableAnimations

    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1
    property var brightnessMonitor: null
    property bool hasActiveWindows: false

    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)
    
    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"

    readonly property bool showSolidBackground: bgIsSolid
    readonly property bool useGlassMode: bgIsGlass

    readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")
    
    readonly property int cornerStyle: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
    readonly property bool isBottom: (Config?.options?.bar?.bottom ?? false)

    readonly property int hybridResizeMs: 85
    readonly property int pillGap: 8

    readonly property int hyprGap: Appearance.sizes.hyprlandGapsOut > 0 ? Appearance.sizes.hyprlandGapsOut : 8
    
    readonly property bool isHugTranspHybrid: root.cornerStyle === 0 && !root.showSolidBackground && root.useHybridGroups
    readonly property int hybridPushDown: isHugTranspHybrid ? hyprGap : 0

    readonly property bool applyFloatPadding: root.cornerStyle === 1 || isHugTranspHybrid
    readonly property int baseTopMargin: applyFloatPadding ? 6 : 0

    readonly property bool useCrystalEffect: (Config?.options?.bar?.crystalEffect ?? false)
    readonly property bool drawMainCrystal: root.useCrystalEffect && root.showSolidBackground && !root.useHybridGroups

    property var fullModel: (Config?.options?.bar?.layouts?.center ?? [])
    property var leftList: []
    property var centerList: []
    property var rightList: []

    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    function _styleFromConfig(v) {
        switch (v) {
            case 0: return "glass"
            case 1: return "solid"
            default: return "solid"
        }
    }

    function _styleFromUIState() {
        if (typeof UIState === 'undefined') return ""
        const s = UIState.surfaceStyle
        return (s === "solid" || s === "glass") ? s : ""
    }

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

    Timer {
        id: hyprRecomputeTimer
        interval: 60
        repeat: false
        onTriggered: root.recomputeHasWindows()
    }

    onMonitorIndexChanged: hyprRecomputeTimer.restart()
    onScreenChanged: {
        recomputeBrightnessMonitor()
        hyprRecomputeTimer.restart()
    }

    onHasActiveWindowsChanged: sendWrappedFrameState()
    onResolvedStyleChanged: sendWrappedFrameState()
    onUseHybridGroupsChanged: sendWrappedFrameState()
    onCornerStyleChanged: sendWrappedFrameState()
    onFullModelChanged: recomputeCenterSplit()

    Loader {
        z: -11
        active: root.showSolidBackground && root.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }

    Loader {
        z: -11
        anchors.fill: barBackground
        active: root.drawMainCrystal
        sourceComponent: BarBgOverlayGlassBlur {
            useGlassMode: true
            showSolidBackground: false
            backgroundColor: "transparent"
            cornerStyle: root.cornerStyle
            position: root.isBottom ? "bottom" : "top"
        }
    }

    Rectangle {
        id: barBackground
        z: -10
        anchors {
            fill: parent
            margins: root.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut - 1) : 0
        }
        color: root.showSolidBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: root.cornerStyle === 1 ? Appearance.rounding.full : 0
        border.width: 0 
        border.color: "transparent"
        visible: !root.drawMainCrystal

        Behavior on color {
            enabled: enableAnimations
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    Loader {
        z: -9
        anchors.fill: barBackground
        active: root.drawMainCrystal
        sourceComponent: BarBgCrystalOverlay {
            useGlassMode: true
            showSolidBackground: false
            backgroundColor: "transparent"
            cornerStyle: root.cornerStyle
            position: root.isBottom ? "bottom" : "top"
        }
    }

    Item {
        id: leftStopper
        anchors {
            top: parent.top
            topMargin: root.hybridPushDown
            bottom: parent.bottom
            left: parent.left
            leftMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        }
    }

    Loader {
        id: leftSectionLoader
        anchors {
            top: parent.top
            topMargin: root.baseTopMargin + root.hybridPushDown
            left: leftStopper.right
        }
        active: !root.useHybridGroups 
        sourceComponent: leftClassicComponent
    }

    Component {
        id: leftClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                id: leftRepeater
                model: Config.options.bar.layouts.left
                delegate: BarComponent {
                    list: Config.options.bar.layouts.left
                    barSection: 0
                }
            }
        }
    }

    Item {
        id: middleSection
        anchors {
            top: parent.top
            topMargin: root.hybridPushDown
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: root.useHybridGroups ? middleHybridComponent : middleClassicComponent
        }

        Component {
            id: middleClassicComponent
            Item {
                anchors.fill: parent

                MouseArea {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: centerCenter.horizontalCenter
                    width: centerCenter.width + 120
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        GlobalStates.dashOpen = !GlobalStates.dashOpen
                        if (GlobalStates.dashOpen) Notifications.timeoutAll()
                    }
                }

                RowLayout {
                    anchors {
                        top: parent.top
                        topMargin: root.baseTopMargin
                        bottom: parent.bottom
                        right: centerCenter.left
                        rightMargin: 4
                    }
                    spacing: 4
                    Repeater {
                        id: middleLeftRepeater
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
                    anchors {
                        top: parent.top
                        topMargin: root.baseTopMargin
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    spacing: 4
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
                    anchors {
                        top: parent.top
                        topMargin: root.baseTopMargin
                        bottom: parent.bottom
                        left: centerCenter.right
                        leftMargin: 4
                    }
                    spacing: 4
                    Repeater {
                        id: middleRightRepeater
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
                id: hybridRoot
                anchors.fill: parent

                property int notchPullGap: !root.showSolidBackground ? root.hyprGap : 0

                Rectangle {
                    anchors.left: centerNotch.left
                    anchors.right: centerNotch.right
                    anchors.top: !root.isBottom ? parent.top : undefined
                    anchors.bottom: root.isBottom ? parent.bottom : undefined
                    anchors.topMargin: !root.isBottom ? -hybridRoot.notchPullGap : 0
                    anchors.bottomMargin: root.isBottom ? -hybridRoot.notchPullGap : 0
                    height: hybridRoot.notchPullGap + (centerNotch.height / 2)
                    color: centerNotch.effectiveFill
                    visible: hybridRoot.notchPullGap > 0
                }

                RoundCorner {
                    anchors.right: centerNotch.left
                    anchors.top: root.isBottom ? centerNotch.top : parent.top
                    anchors.bottom: root.isBottom ? parent.bottom : centerNotch.bottom
                    anchors.topMargin: !root.isBottom ? (-centerNotch.edgeInset - hybridRoot.notchPullGap) : 0
                    anchors.bottomMargin: root.isBottom ? (-centerNotch.edgeInset - hybridRoot.notchPullGap) : 0
                    width: height
                    color: centerNotch.effectiveFill
                    corner: root.isBottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
                }

                RoundCorner {
                    anchors.left: centerNotch.right
                    anchors.top: root.isBottom ? centerNotch.top : parent.top
                    anchors.bottom: root.isBottom ? parent.bottom : centerNotch.bottom
                    anchors.topMargin: !root.isBottom ? (-centerNotch.edgeInset - hybridRoot.notchPullGap) : 0
                    anchors.bottomMargin: root.isBottom ? (-centerNotch.edgeInset - hybridRoot.notchPullGap) : 0
                    width: height
                    color: centerNotch.effectiveFill
                    corner: root.isBottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft
                }

                MouseArea {
                    anchors.fill: centerNotch
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        GlobalStates.dashOpen = !GlobalStates.dashOpen
                        if (GlobalStates.dashOpen) Notifications.timeoutAll()
                    }
                }

                Bar.BarGroup {
                    id: centerNotch
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: !root.isBottom ? -edgeInset : 0
                    anchors.bottomMargin: root.isBottom ? -edgeInset : 0
                    vertical: false
                    spacing: root.pillGap 
                    padding: 6
                    edgeInset: 2
                    isContainer: true
                    autoHide: true
                    isNotch: true            
                    showBorder: false        
                    showHighlight: false    
                    unifyChildChips: true   
                    width: implicitWidth
                                          
                    Behavior on width { 
                        enabled: enableAnimations
                        NumberAnimation { duration: root.hybridResizeMs; easing.type: Easing.OutCubic } 
                    }

                    Repeater {
                        model: {
                            let arr = [];
                            if (Config.options.bar.layouts.left) {
                                arr = arr.concat(Config.options.bar.layouts.left);
                            }
                            if (root.leftList) arr = arr.concat(root.leftList);
                            if (root.centerList) arr = arr.concat(root.centerList);
                            if (root.rightList) arr = arr.concat(root.rightList);
                            if (Config.options.bar.layouts.right) {
                                arr = arr.concat(Config.options.bar.layouts.right);
                            }
                            return arr.filter(Boolean);
                        }
                        delegate: BarComponent {
                            property bool isLeftItem: Config.options.bar.layouts.left ? Config.options.bar.layouts.left.some(e => e && modelData && e.id === modelData.id) : false
                            property bool isRightItem: Config.options.bar.layouts.right ? Config.options.bar.layouts.right.some(e => e && modelData && e.id === modelData.id) : false
                            list: isLeftItem ? Config.options.bar.layouts.left : (isRightItem ? Config.options.bar.layouts.right : Config.options.bar.layouts.center)
                            barSection: isLeftItem ? 0 : (isRightItem ? 2 : 1) 
                            originalIndex: list.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: rightStopper
        anchors {
            top: parent.top
            topMargin: root.hybridPushDown
            bottom: parent.bottom
            right: parent.right
        }
        width: -1
    }

    Loader {
        id: rightSectionLoader
        anchors {
            top: parent.top
            topMargin: root.baseTopMargin + root.hybridPushDown
            right: rightStopper.left
            rightMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        }
        active: !root.useHybridGroups
        sourceComponent: rightClassicComponent
    }

    Component {
        id: rightClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                id: rightRepeater
                model: Config.options.bar.layouts.right
                delegate: BarComponent {
                    list: rightRepeater.model
                    barSection: 2
                }
            }
        }
    }

    FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        z: -2 
        anchors {
            top: parent.top
            topMargin: root.hybridPushDown
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitHeight: Appearance.sizes.baseBarHeight
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.policiesPanelOpen = !GlobalStates.policiesPanelOpen;
            }
        }
    }

    FocusedScrollMouseArea {
        id: barRightSideMouseArea
        z: -2 
        anchors {
            top: parent.top
            topMargin: root.hybridPushDown
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitHeight: Appearance.sizes.baseBarHeight
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.dashboardPanelOpen = !GlobalStates.dashboardPanelOpen;
            }
        }
    }

    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        hyprRecomputeTimer.restart()
        sendWrappedFrameState()
    }
}
