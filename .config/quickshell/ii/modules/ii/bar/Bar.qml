pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

import "." as Bar

Scope {
    id: bar

    Variants {
        id: barVariant

        readonly property var variantModel: {
            const screens = Quickshell.screens
            const list = Config?.options?.bar?.screenList
            if (!list || list.length === 0) return screens
            return screens.filter(screen => list.includes(screen.name))
        }

        model: variantModel

        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData

            property int monitorIndex: barVariant.variantModel.indexOf(modelData)

            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                property int monitorIndex: barLoader.monitorIndex

                readonly property bool isBottom: !!Config?.options?.bar?.bottom
                readonly property bool autoHideEnabled: !!Config?.options?.bar?.autoHide?.enable
                readonly property bool pushWindows: !!Config?.options?.bar?.autoHide?.pushWindows
                readonly property bool deadPixelFix: !!Config?.options?.interactions?.deadPixelWorkaround?.enable

                QtObject {
                    id: styleEnum
                    readonly property int glass: 0
                    readonly property int visible: 1
                    readonly property int adaptive: 2
                    readonly property int crystal: 3
                }

                readonly property var _barBackgroundStyleRaw: (Config?.options?.bar?.barBackgroundStyle ?? styleEnum.visible)

                function _normalizeBarStyle(v) {
                    if (typeof v === "number") {
                        switch (v) {
                            case styleEnum.glass: return "glass"
                            case styleEnum.visible: return "visible"
                            case styleEnum.adaptive: return "adaptive"
                            case styleEnum.crystal: return "crystal"
                            default: return "visible"
                        }
                    }

                    if (typeof v !== "string") return "visible"
                    const s = v.toLowerCase().trim()

                    if (s === "solid") return "visible"
                    if (s === "alwaysvisible" || s === "always_visible") return "visible"

                    if (s === "visible" || s === "glass" || s === "adaptive" || s === "crystal")
                        return s

                    return "visible"
                }

                readonly property string barStyleName: _normalizeBarStyle(_barBackgroundStyleRaw)

                readonly property int barBackgroundStyle: (typeof _barBackgroundStyleRaw === "number")
                    ? _barBackgroundStyleRaw
                    : ((barStyleName === "glass") ? styleEnum.glass
                       : (barStyleName === "adaptive") ? styleEnum.adaptive
                       : (barStyleName === "crystal") ? styleEnum.crystal
                       : styleEnum.visible)

                readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")

                property bool hasActiveWindows: false

                readonly property bool isAdaptiveStyle: (barRoot.barStyleName === "adaptive")

                readonly property bool showBarBackground: (
                    (barRoot.barStyleName === "visible") ||
                    (barRoot.barStyleName === "glass") ||
                    (barRoot.barStyleName === "crystal") ||
                    (barRoot.barStyleName === "adaptive" && barRoot.hasActiveWindows)
                )

                readonly property color _solidBase: Appearance.colors.colLayer0
                readonly property color _glassTint: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35)

                readonly property color barBackgroundColorForCorners: !barRoot.showBarBackground
                    ? "transparent"
                    : ((barRoot.barStyleName === "glass" || barRoot.barStyleName === "crystal") ? _glassTint : _solidBase)

                property var currentMonitor: {
                    const screenName = barRoot.screen?.name
                    return HyprlandData.monitors.find(m => m && m.name === screenName)
                        ?? HyprlandData.monitors.find(m => m && m.id === barRoot.monitorIndex)
                        ?? null
                }

                property var activeWsId: currentMonitor?.activeWorkspace?.id

                function recomputeHasActiveWindows() {
                    if (!activeWsId) {
                        barRoot.hasActiveWindows = false
                        return
                    }
                    barRoot.hasActiveWindows = HyprlandData.windowList.some(w =>
                        (w.workspace?.id === activeWsId) && !w.floating
                    )
                }

                onActiveWsIdChanged: barRoot.recomputeHasActiveWindows()

                Connections {
                    enabled: barRoot.isAdaptiveStyle
                    target: HyprlandData
                    function onWindowListChanged() { barRoot.recomputeHasActiveWindows() }
                    function onMonitorsChanged() { barRoot.recomputeHasActiveWindows() }
                }

                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow

                Timer {
                    id: showBarTimer
                    interval: (Config?.options?.bar?.autoHide?.showWhenPressingSuper?.delay ?? 100)
                    repeat: false
                    onTriggered: barRoot.superShow = true
                }

                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!(Config?.options?.bar?.autoHide?.showWhenPressingSuper?.enable === true)) return

                        if (GlobalStates.superDown) {
                            showBarTimer.restart()
                        } else {
                            showBarTimer.stop()
                            barRoot.superShow = false
                        }
                    }
                }

                exclusionMode: ExclusionMode.Ignore

                exclusiveZone: (barRoot.autoHideEnabled && (!barRoot.mustShow || !barRoot.pushWindows))
                    ? 0
                    : (Appearance.sizes.baseBarHeight
                       + ((Config?.options?.bar?.cornerStyle === 1) ? Appearance.sizes.hyprlandGapsOut : 0))

                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                color: "transparent"

                mask: Region { item: hoverMaskRegion }

                anchors {
                    top: !barRoot.isBottom
                    bottom: barRoot.isBottom
                    left: true
                    right: true
                }

                margins {
                    right: (barRoot.deadPixelFix && barRoot.anchors.right) ? -1 : 0
                    bottom: (barRoot.deadPixelFix && barRoot.anchors.bottom) ? -1 : 0
                }

                Component.onCompleted: {
                    barRoot.recomputeHasActiveWindows()
                    GlobalFocusGrab.addPersistent(barRoot)
                }

                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true

                    anchors {
                        fill: parent
                        rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) ? 1 : 0
                        bottomMargin: (barRoot.deadPixelFix && barRoot.anchors.bottom) ? 1 : 0
                    }

                    Item {
                        id: barSlot
                        implicitHeight: Appearance.sizes.barHeight

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            bottom: undefined

                            topMargin: (barRoot.autoHideEnabled && !barRoot.mustShow)
                                ? -Appearance.sizes.barHeight
                                : 0

                            bottomMargin: (barRoot.deadPixelFix && barRoot.anchors.bottom) ? -1 : 0
                            rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) ? -1 : 0
                        }

                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: barRoot.isBottom

                            AnchorChanges {
                                target: barSlot
                                anchors { top: undefined; bottom: parent.bottom }
                            }
                            PropertyChanges {
                                target: barSlot
                                anchors.topMargin: 0
                                anchors.bottomMargin: (barRoot.autoHideEnabled && !barRoot.mustShow)
                                    ? -Appearance.sizes.barHeight
                                    : ((barRoot.deadPixelFix && barRoot.anchors.bottom) ? -1 : 0)
                            }
                        }

                        Bar.BarFullBackground {
                            anchors.fill: parent
                            enabled: barRoot.showBarBackground

                            followGlobalStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
                            styleFromConfig: barRoot.barBackgroundStyle

                            hasActiveWindows: barRoot.hasActiveWindows
                            cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)
                            isBottom: barRoot.isBottom
                        }

                        BarContent {
                            id: barContent
                            anchors.fill: parent
                            monitorIndex: barRoot.monitorIndex
                            screen: barRoot.screen
                        }
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barSlot
                            topMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                            bottomMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                        }
                    }

                    readonly property bool isHugStyleHere: (Config?.options?.bar?.cornerStyle === 0)
                    readonly property bool allowFlatHugPaintingHere: (!barRoot.useHybridGroups)
                    readonly property int seamOverlapPx: 2

                    readonly property color effectiveCornerColor: barRoot.barBackgroundColorForCorners

                    Loader {
                        id: roundDecorators

                        active: hoverRegion.isHugStyleHere
                            && hoverRegion.allowFlatHugPaintingHere
                            && barRoot.showBarBackground
                            && (hoverRegion.effectiveCornerColor !== "transparent")

                        height: Appearance.rounding.screenRounding + hoverRegion.seamOverlapPx

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: barSlot.bottom
                            bottom: undefined
                            topMargin: -hoverRegion.seamOverlapPx
                        }

                        states: State {
                            name: "bottom"
                            when: barRoot.isBottom
                            AnchorChanges { target: roundDecorators; anchors { top: undefined; bottom: barSlot.top } }
                            PropertyChanges {
                                target: roundDecorators
                                anchors.topMargin: 0
                                anchors.bottomMargin: -hoverRegion.seamOverlapPx
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding + hoverRegion.seamOverlapPx

                            RoundCorner {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding + hoverRegion.seamOverlapPx
                                color: hoverRegion.effectiveCornerColor
                                corner: barRoot.isBottom
                                    ? RoundCorner.CornerEnum.BottomLeft
                                    : RoundCorner.CornerEnum.TopLeft
                            }

                            RoundCorner {
                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding + hoverRegion.seamOverlapPx
                                color: hoverRegion.effectiveCornerColor
                                corner: barRoot.isBottom
                                    ? RoundCorner.CornerEnum.BottomRight
                                    : RoundCorner.CornerEnum.TopRight
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close(): void { GlobalStates.barOpen = false }
        function open(): void { GlobalStates.barOpen = true }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"
        onPressed: GlobalStates.barOpen = !GlobalStates.barOpen
    }
    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"
        onPressed: GlobalStates.barOpen = true
    }
    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"
        onPressed: GlobalStates.barOpen = false
    }
}

