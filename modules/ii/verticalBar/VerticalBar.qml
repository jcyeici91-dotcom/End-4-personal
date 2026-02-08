import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: bar

    Variants {
        id: barVariant

        // For each monitor
        property var variantModel: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        model: variantModel

        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked

            required property ShellScreen modelData
            property var monitorIndex: barVariant.variantModel.indexOf(barLoader.modelData)

            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData

                property int monitorIndex: barLoader.monitorIndex

                // En tu config actual "bottom" significa "lado derecho" para verticalBar
                property bool rightSide: Config.options.bar.bottom

                property var brightnessMonitor: Brightness.getMonitorForScreen(barLoader.modelData)

                property bool hasActiveWindows: false
                property bool showBarBackground: (barRoot.hasActiveWindows && Config.options.bar.barBackgroundStyle === 2)
                                               || (Config.options.bar.barBackgroundStyle === 1)

                Connections {
                    enabled: Config.options.bar.barBackgroundStyle === 2
                    target: HyprlandData
                    function onWindowListChanged() {
                        const monitor = HyprlandData.monitors.find(m => m.id === monitorIndex);
                        const wsId = monitor?.activeWorkspace?.id;

                        const hasWindow = wsId
                            ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating)
                            : false;

                        barRoot.hasActiveWindows = hasWindow
                    }
                }

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: barRoot.superShow = true
                }

                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }

                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows))
                    ? 0
                    : (Appearance.sizes.baseVerticalBarWidth
                       + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0))

                WlrLayershell.namespace: "quickshell:verticalBar"
                implicitWidth: Appearance.sizes.verticalBarWidth + Appearance.rounding.screenRounding

                mask: Region { item: hoverMaskRegion }
                color: "transparent"

                anchors {
                    left: !barRoot.rightSide
                    right: barRoot.rightSide
                    top: true
                    bottom: true
                }

                Component.onCompleted: GlobalFocusGrab.addPersistent(barRoot)
                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors.fill: parent

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            leftMargin: -Config.options.bar.autoHide.hoverRegionWidth
                            rightMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        }
                    }

                    VerticalBarContent {
                        id: barContent
                        implicitWidth: Appearance.sizes.verticalBarWidth

                        // FIX: monitorIndex ahora se pasa al content (y content lo requiere)
                        monitorIndex: barRoot.monitorIndex

                        // Lado (por si lo usas dentro del content/widgets)
                        rightSide: barRoot.rightSide

                        anchors {
                            top: parent.top
                            bottom: parent.bottom

                            // Default: izquierda
                            left: parent.left
                            right: undefined

                            leftMargin: (Config?.options.bar.autoHide.enable && !barRoot.mustShow)
                                ? -barContent.implicitWidth
                                : 0
                            rightMargin: 0
                        }

                        Behavior on anchors.leftMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "right"
                            when: barRoot.rightSide

                            AnchorChanges {
                                target: barContent
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: undefined
                                    right: parent.right
                                }
                            }

                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0

                                // FIX CRÍTICO: ocultar por ancho verticalBar, NO por barHeight
                                anchors.rightMargin: (Config?.options.bar.autoHide.enable && !barRoot.mustShow)
                                    ? -barContent.implicitWidth
                                    : 0
                            }
                        }
                    }

                    Loader {
                        id: roundDecorators
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: barContent.right
                            right: undefined
                        }
                        width: Appearance.rounding.screenRounding
                        active: barRoot.showBarBackground && Config.options.bar.cornerStyle === 0 // Hug

                        states: State {
                            name: "right"
                            when: barRoot.rightSide
                            AnchorChanges {
                                target: roundDecorators
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: undefined
                                    right: barContent.left
                                }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding

                            RoundCorner {
                                id: topCorner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }

                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                                corner: RoundCorner.CornerEnum.TopLeft

                                states: State {
                                    name: "right"
                                    when: barRoot.rightSide
                                    PropertyChanges { topCorner.corner: RoundCorner.CornerEnum.TopRight }
                                }
                            }

                            RoundCorner {
                                id: bottomCorner
                                anchors {
                                    bottom: parent.bottom
                                    left: !barRoot.rightSide ? parent.left : undefined
                                    right: barRoot.rightSide ? parent.right : undefined
                                }

                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? Appearance.colors.colLayer0 : "transparent"
                                corner: RoundCorner.CornerEnum.BottomLeft

                                states: State {
                                    name: "right"
                                    when: barRoot.rightSide
                                    PropertyChanges { bottomCorner.corner: RoundCorner.CornerEnum.BottomRight }
                                }
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

