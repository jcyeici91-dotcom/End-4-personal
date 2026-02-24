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

    readonly property Bar.BarState state: Bar.BarState {
        screen: root.screen
        monitorIndex: root.monitorIndex
    }

    readonly property Bar.PositionSystem positionSys: Bar.PositionSystem {
        screen: root.screen
    }

    readonly property Bar.GroupStyleSystem groups: Bar.GroupStyleSystem {
        state: root.state
    }

    function sendWrappedFrameState() {
        try {
            Quickshell.Io.Ipc.call("wrappedFrame", "setBarState", [
                backgroundSystem.resolvedStyle,
                root.state.hasActiveWindows,
                root.groups.isHybrid,
                cornerSystem.cornerStyleValue
            ])
        } catch (e) {
        }
    }

    Connections {
        target: root.state
        function onHasActiveWindowsChanged() { root.sendWrappedFrameState() }
    }

    Bar.BarSizeSystem {
        id: sizeSystem
        screen: root.screen
    }

    Bar.BarBackgroundSystem {
        id: backgroundSystem
        anchors.fill: parent
        state: root.state
    }

    Bar.CornerStyleSystem {
        id: cornerSystem
        anchors.fill: parent
        state: root.state
    }

    FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: middleSection.left
        implicitHeight: sizeSystem.baseBarHeight

        onScrollDown: if (root.state.brightnessMonitor) root.state.brightnessMonitor.setBrightness(root.state.brightnessMonitor.brightness - 0.05)
        onScrollUp: if (root.state.brightnessMonitor) root.state.brightnessMonitor.setBrightness(root.state.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
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
        anchors.leftMargin: root.groups.screenMargin
        width: 1
    }

    Loader {
        id: leftContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftStopper.right
        active: true
        sourceComponent: root.groups.isHybrid ? leftHybridComponent : leftClassicComponent
    }

    Component {
        id: leftClassicComponent
        RowLayout {
            spacing: root.groups.spacing
            Repeater {
                model: Config.options.bar.layouts.left
                delegate: BarComponent { list: Config.options.bar.layouts.left; barSection: 0 }
            }
        }
    }

    Component {
        id: leftHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: root.groups.spacing
            isContainer: true
            autoHide: false
            padding: root.groups.padding
            edgeInset: root.groups.edgeInset
            attachScreenLeft: true
            width: implicitWidth

            Behavior on width { NumberAnimation { duration: root.groups.hybridResizeMs; easing.type: Easing.OutCubic } }

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
            sourceComponent: root.groups.isHybrid ? middleHybridComponent : middleClassicComponent
        }

        Component {
            id: middleClassicComponent
            Item {
                anchors.fill: parent

                RowLayout {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: centerCenter.left
                    anchors.rightMargin: root.groups.spacing
                    Repeater {
                        model: root.groups.leftList
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
                    spacing: root.groups.spacing
                    Repeater {
                        model: root.groups.centerList
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
                    anchors.leftMargin: root.groups.spacing
                    Repeater {
                        model: root.groups.rightList
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

                Loader {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: centerCenterGroup.left
                    anchors.rightMargin: root.groups.spacing
                    active: (root.groups.leftList && root.groups.leftList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: root.groups.spacing
                        isContainer: true
                        autoHide: true
                        padding: root.groups.padding
                        edgeInset: root.groups.edgeInset
                        width: implicitWidth
                        Behavior on width { NumberAnimation { duration: root.groups.hybridResizeMs; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: root.groups.leftList
                            delegate: BarComponent {
                                list: Config.options.bar.layouts.center
                                barSection: 1
                                originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                            }
                        }
                    }
                }

                Bar.BarGroup {
                    id: centerCenterGroup
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    vertical: false
                    spacing: root.groups.spacing
                    isContainer: true
                    autoHide: true
                    padding: root.groups.padding
                    edgeInset: root.groups.edgeInset
                    width: implicitWidth
                    Behavior on width { NumberAnimation { duration: root.groups.hybridResizeMs; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: root.groups.centerList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }

                Loader {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: centerCenterGroup.right
                    anchors.leftMargin: root.groups.spacing
                    active: (root.groups.rightList && root.groups.rightList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: root.groups.spacing
                        isContainer: true
                        autoHide: true
                        padding: root.groups.padding
                        edgeInset: root.groups.edgeInset
                        width: implicitWidth
                        Behavior on width { NumberAnimation { duration: root.groups.hybridResizeMs; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: root.groups.rightList
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
        anchors.rightMargin: root.groups.screenMargin
        active: true
        sourceComponent: root.groups.isHybrid ? rightHybridComponent : rightClassicComponent
    }

    Component {
        id: rightClassicComponent
        RowLayout {
            spacing: root.groups.spacing
            Repeater {
                model: Config.options.bar.layouts.right
                delegate: BarComponent { list: Config.options.bar.layouts.right; barSection: 2 }
            }
        }
    }

    Component {
        id: rightHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: root.groups.spacing
            isContainer: true
            autoHide: false
            padding: root.groups.padding
            edgeInset: root.groups.edgeInset
            attachScreenRight: true
            width: implicitWidth
            Behavior on width { NumberAnimation { duration: root.groups.hybridResizeMs; easing.type: Easing.OutCubic } }
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
        implicitHeight: sizeSystem.baseBarHeight

        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
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
        root.state.recomputeBrightnessMonitor()
        sendWrappedFrameState()
    }
}
