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

Scope {
    id: bar

    Variants {
        // One bar per monitor
        id: barVariant

        // Screen model (filtered by screenList if configured)
        readonly property var variantModel: {
            const screens = Quickshell.screens;
            const list = Config?.options?.bar?.screenList;
            if (!list || list.length === 0) return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        model: variantModel

        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData

            // Index in variantModel (NOT Hyprland monitor id)
            property int monitorIndex: barVariant.variantModel.indexOf(modelData)

            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                // --------------------------
                // Helpers / config
                // --------------------------
                property int monitorIndex: barLoader.monitorIndex

                readonly property bool isBottom: !!Config?.options?.bar?.bottom
                readonly property bool autoHideEnabled: !!Config?.options?.bar?.autoHide?.enable
                readonly property bool pushWindows: !!Config?.options?.bar?.autoHide?.pushWindows
                readonly property bool deadPixelFix: !!Config?.options?.interactions?.deadPixelWorkaround?.enable

                // 0 = glass(transparent), 1 = always visible, 2 = adaptive
                readonly property int barBackgroundStyle: (Config?.options?.bar?.barBackgroundStyle ?? 1)

                // --------------------------
                // Background style / adaptive
                // --------------------------
                property bool hasActiveWindows: false

                readonly property bool showBarBackground: (
                    (barBackgroundStyle === 1) ||
                    (barBackgroundStyle === 0) ||
                    (barBackgroundStyle === 2 && barRoot.hasActiveWindows)
                )

                readonly property color _glassTint: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35)
                readonly property color barBackgroundColorForCorners: (barBackgroundStyle === 0)
                    ? _glassTint
                    : Appearance.colors.colLayer0

                function recomputeHasActiveWindows() {
                    const screenName = barRoot.screen?.name;

                    // Prefer mapping by name
                    let monitor = null;
                    if (screenName) {
                        monitor = HyprlandData.monitors.find(m => m && m.name === screenName) ?? null;
                    }
                    // Fallback mapping by index/id
                    if (!monitor) {
                        monitor = HyprlandData.monitors.find(m => m && m.id === barRoot.monitorIndex) ?? null;
                    }

                    const wsId = monitor?.activeWorkspace?.id;
                    barRoot.hasActiveWindows = wsId
                        ? HyprlandData.windowList.some(w => w.workspace?.id === wsId && !w.floating)
                        : false;
                }

                Connections {
                    enabled: barRoot.barBackgroundStyle === 2
                    target: HyprlandData
                    function onWindowListChanged() { barRoot.recomputeHasActiveWindows(); }
                    function onMonitorsChanged() { barRoot.recomputeHasActiveWindows(); }
                }

                // --------------------------
                // Super show / hover show
                // --------------------------
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
                        if (!(Config?.options?.bar?.autoHide?.showWhenPressingSuper?.enable === true)) return;

                        if (GlobalStates.superDown) {
                            showBarTimer.restart();
                        } else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }

                // --------------------------
                // Layershell / size / mask
                // --------------------------
                exclusionMode: ExclusionMode.Ignore

                exclusiveZone: (barRoot.autoHideEnabled && (!barRoot.mustShow || !barRoot.pushWindows))
                    ? 0
                    : (Appearance.sizes.baseBarHeight
                       + ((Config?.options?.bar?.cornerStyle === 1) ? Appearance.sizes.hyprlandGapsOut : 0))

                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                color: "transparent"

                mask: Region { item: hoverMaskRegion }

                // --------------------------
                // Positioning (TOP/BOTTOM)
                // PanelWindow has NO `states`, so do it imperatively.
                // --------------------------
                function applyWindowAnchors() {
                    barRoot.anchors.top = !barRoot.isBottom;
                    barRoot.anchors.bottom = barRoot.isBottom;
                    barRoot.anchors.left = true;
                    barRoot.anchors.right = true;
                }

                anchors { top: true; bottom: false; left: true; right: true }

                onIsBottomChanged: applyWindowAnchors()

                margins {
                    right: (barRoot.deadPixelFix && barRoot.anchors.right) * -1
                    bottom: (barRoot.deadPixelFix && barRoot.anchors.bottom) * -1
                }

                // --------------------------
                // Lifecycle
                // --------------------------
                Component.onCompleted: {
                    applyWindowAnchors();
                    barRoot.recomputeHasActiveWindows();
                    GlobalFocusGrab.addPersistent(barRoot);
                }

                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                // =========================================================
                // Hover region + content
                // =========================================================
                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true

                    anchors {
                        fill: parent
                        rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) * 1
                        bottomMargin: (barRoot.deadPixelFix && barRoot.anchors.bottom) * 1
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            topMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                            bottomMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                        }
                    }

                    BarContent {
                        id: barContent
                        implicitHeight: Appearance.sizes.barHeight

                        // Give BarContent correct context
                        monitorIndex: barRoot.monitorIndex
                        screen: barRoot.screen

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            bottom: undefined

                            topMargin: (barRoot.autoHideEnabled && !barRoot.mustShow)
                                ? -Appearance.sizes.barHeight
                                : 0

                            bottomMargin: (barRoot.deadPixelFix && barRoot.anchors.bottom) * -1
                            rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) * -1
                        }

                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        // Anchor-safe bottom mode (prevents "growing")
                        states: State {
                            name: "bottom"
                            when: barRoot.isBottom

                            AnchorChanges {
                                target: barContent
                                anchors { top: undefined; bottom: parent.bottom }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: (barRoot.autoHideEnabled && !barRoot.mustShow)
                                    ? -Appearance.sizes.barHeight
                                    : ((barRoot.deadPixelFix && barRoot.anchors.bottom) * -1)
                            }
                        }
                    }

                    // =========================================================
                    // Rounded decorators (cornerStyle Hug)
                    // =========================================================
                    Loader {
                        id: roundDecorators
                        active: barRoot.showBarBackground && (Config?.options?.bar?.cornerStyle === 0)
                        height: Appearance.rounding.screenRounding

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: barContent.bottom
                            bottom: undefined
                        }

                        states: State {
                            name: "bottom"
                            when: barRoot.isBottom
                            AnchorChanges {
                                target: roundDecorators
                                anchors { top: undefined; bottom: barContent.top }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding

                            RoundCorner {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? barRoot.barBackgroundColorForCorners : "transparent"
                                corner: barRoot.isBottom
                                    ? RoundCorner.CornerEnum.BottomLeft
                                    : RoundCorner.CornerEnum.TopLeft
                            }

                            RoundCorner {
                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? barRoot.barBackgroundColorForCorners : "transparent"
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

    // =========================================================
    // IPC: external control
    // =========================================================
    IpcHandler {
        target: "bar"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close(): void { GlobalStates.barOpen = false }
        function open(): void { GlobalStates.barOpen = true }
    }

    // =========================================================
    // Global shortcuts
    // =========================================================
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

