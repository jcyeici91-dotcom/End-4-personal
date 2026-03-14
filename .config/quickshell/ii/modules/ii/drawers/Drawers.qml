pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        property bool fullscreen: activeWorkspaceWithFullscreen != undefined

        Loader {
            active: scope.fullscreen || (DrawerVisibilityConfig.fullScreenOsdVisible || DrawerVisibilityConfig.fullScreenSearchOverviewVisible)
            sourceComponent: PanelWindow {
                id: win

                color: "transparent"
                screen: scope.modelData
                exclusiveZone: Hyprland.focusedWorkspace?.hasFullscreen ? -1 : 0
                WlrLayershell.namespace: "quickshell:drawer"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                mask: Region {
                    width: win.width// - bar.implicitWidth - Config.border.thickness - win.dragMaskPadding * 2
                    height: win.height// - Config.border.thickness * 2 - win.dragMaskPadding * 2
                    intersection: Intersection.Xor

                    regions: regions.instances
                }

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Variants {
                    id: regions

                    model: panels.children

                    Region {
                        required property Item modelData

                        x: modelData.x
                        y: modelData.y + 40
                        width: modelData.width
                        height: modelData.height
                        intersection: Intersection.Subtract
                    }
                }

                HyprlandFocusGrab {
                    id: focusGrab

                    active: Config.options.appearance.panelAnimation.enableBackgroundAnimation && (GlobalStates.overviewOpen) // false
                    windows: [win]
                    onCleared: {
                        GlobalStates.overviewOpen = false
                    }
                }

                Item {
                    anchors.fill: parent
                    // layer.enabled: true
                    // layer.effect: MultiEffect {
                    //     shadowEnabled: true
                    //     blurMax: 0.9 * Appearance.sizes.elevationMargin
                    //     shadowColor: Appearance.colors.colShadow
                    // }

                    Backgrounds {
                        id: backgrounds
                        panels: panels
                        // layer.enabled: true
                        // layer.effect: DropShadow {
                        //     radius: 20
                        //     samples: 1 + radius * 2 // https://doc.qt.io/qt-6/qml-qt5compat-graphicaleffects-dropshadow.html#radius-prop
                        //     color: Appearance.colors.colShadow
                        //     spread: 0.1
                        //     verticalOffset: -2
                        // }
                    }

                    Panels {
                        id: panels

                        screen: scope.modelData
                        visibilities: Visibilities.getForScreen(scope.modelData)
                    }
                }
            }
        }
    }
}
