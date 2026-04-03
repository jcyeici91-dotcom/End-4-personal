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

Scope {
    id: bar

    Variants {
        id: barVariant

        readonly property var variantModel: {
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
            property int monitorIndex: barVariant.variantModel.indexOf(modelData)
            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                property int monitorIndex: barLoader.monitorIndex
                property bool hasActiveWindows: false
                property bool showBarBackground: barRoot.hasActiveWindows && Config.options.bar.barBackgroundStyle === 2 || Config.options.bar.barBackgroundStyle === 1

                property bool isFloatTranspHybrid: Config.options.bar.cornerStyle === 1 && !showBarBackground && Config.options.bar.groupBackgroundStyle === "hybrid"
                property int floatGap: (Config.options.bar.cornerStyle === 1 && !isFloatTranspHybrid) ? (Appearance.sizes.hyprlandGapsOut > 0 ? Appearance.sizes.hyprlandGapsOut : 8) : 0

                property bool isHugTranspHybrid: Config.options.bar.cornerStyle === 0 && !showBarBackground && Config.options.bar.groupBackgroundStyle === "hybrid"
                property int hugPushGap: isHugTranspHybrid ? (Appearance.sizes.hyprlandGapsOut > 0 ? Appearance.sizes.hyprlandGapsOut : 8) : 0

                Connections {
                    enabled: Config.options.bar.barBackgroundStyle === 2
                    target: HyprlandData
                    function onWindowListChanged() {
                        const monitor = HyprlandData.monitors.find(m => m.id === monitorIndex);
                        const wsId = monitor?.activeWorkspace?.id;

                        const hasWindow = wsId ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating) : false;

                        barRoot.hasActiveWindows = hasWindow
                    }
                }
                
                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
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
                
                property int totalReservedSpace: Appearance.sizes.barHeight + floatGap + hugPushGap

                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 : totalReservedSpace
                exclusionMode: exclusiveZone > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore
                
                WlrLayershell.namespace: "quickshell:bar"
                
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding + floatGap + hugPushGap
                mask: Region {
                    item: hoverMaskRegion
                }
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    right: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                    bottom: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                }

                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(barRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                }

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors {
                        fill: parent
                        rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * 1
                        bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * 1
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            topMargin: -Config.options.bar.autoHide.hoverRegionWidth
                            bottomMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        }
                    }

                    BarContent {
                        id: barContent
                        
                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            right: parent.right
                            left: parent.left
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : barRoot.floatGap
                            bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                            rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                        }
                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: parent.bottom
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: ((Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : barRoot.floatGap) + ((Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1)
                            }
                        }
                    }

                    Loader {
                        id: roundDecorators
                        
                        anchors.left: parent.left
                        anchors.right: parent.right
                        
                        property bool hugSolid: Config.options.bar.cornerStyle === 0 && showBarBackground
                        
                        y: !Config.options.bar.bottom 
                            ? (hugSolid ? barContent.y + barContent.height : 0) 
                            : (hugSolid ? barContent.y - height : parent.height - height)
                        
                        height: Appearance.rounding.screenRounding
                        
                        active: true

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding
                            readonly property real overlap: 1.0 
                            readonly property color decorColor: Appearance.colors.colLayer0

                            RoundCorner {
                                id: leftCorner
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                
                                anchors.topMargin: !Config.options.bar.bottom ? -overlap : 0
                                anchors.bottomMargin: Config.options.bar.bottom ? -overlap : 0
                                anchors.leftMargin: -overlap
                                
                                implicitSize: Appearance.rounding.screenRounding
                                color: decorColor
                                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.BottomLeft
                            }

                            RoundCorner {
                                id: rightCorner
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                
                                anchors.topMargin: !Config.options.bar.bottom ? -overlap : 0
                                anchors.bottomMargin: Config.options.bar.bottom ? -overlap : 0
                                anchors.rightMargin: -overlap
                                
                                implicitSize: Appearance.rounding.screenRounding
                                color: decorColor
                                corner: !Config.options.bar.bottom ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.BottomRight
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
