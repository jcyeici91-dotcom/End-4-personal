import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: leftSidebarButton

    property bool showPing: false
    property string iconsDir: `${Quickshell.env("HOME")}/.config/quickshell/ii/assets/icons`

    // AJUSTA AQUÍ:
    property real iconSize: 28     // <-- tamaño del icono
    property real buttonPadding: 4 // <-- padding del botón

    implicitWidth: iconSize + buttonPadding * 2
    implicitHeight: iconSize + buttonPadding * 2

    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    toggled: GlobalStates.sidebarLeftOpen

    onClicked: GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen

    onToggledChanged: {
        if (!toggled) leftSidebarButton.scale = 1.0
    }

    SequentialAnimation on scale {
        running: leftSidebarButton.toggled
        loops: Animation.Infinite
        NumberAnimation { from: 1.00; to: 1.08; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { from: 1.08; to: 0.98; duration: 120; easing.type: Easing.InOutCubic }
        NumberAnimation { from: 0.98; to: 1.06; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { from: 1.06; to: 1.00; duration: 160; easing.type: Easing.InOutCubic }
        PauseAnimation { duration: 700 }
    }

    Rectangle {
        anchors.fill: parent
        radius: leftSidebarButton.buttonRadius
        color: "transparent"
        border.width: 1
        border.color: leftSidebarButton.toggled
            ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.55)
            : Qt.rgba(1, 1, 1, 0.0)
        opacity: leftSidebarButton.toggled ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Connections {
        target: Ai
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return
            leftSidebarButton.showPing = true
        }
    }

    Connections {
        target: Booru
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return
            leftSidebarButton.showPing = true
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            leftSidebarButton.showPing = false
        }
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        width: leftSidebarButton.iconSize
        height: leftSidebarButton.iconSize

        source: `${leftSidebarButton.iconsDir}/arch-symbolic.svg`

        colorize: true
        color: leftSidebarButton.toggled
            ? Appearance.colors.colOnSecondaryContainer
            : Appearance.colors.colOnLayer0

        Behavior on color {
            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Item {
            id: pingBadge
            opacity: leftSidebarButton.showPing ? 1 : 0
            visible: opacity > 0

            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -2
                rightMargin: -2
            }

            width: 10
            height: 10

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: Appearance.rounding.full
                color: Appearance.colors.colTertiary
            }

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: Appearance.rounding.full
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(
                    Appearance.colors.colTertiary.r,
                    Appearance.colors.colTertiary.g,
                    Appearance.colors.colTertiary.b,
                    0.55
                )
                scale: 1.0
                opacity: 0.9

                SequentialAnimation on scale {
                    running: leftSidebarButton.showPing
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.45; duration: 650; easing.type: Easing.OutCubic }
                    NumberAnimation { from: 1.45; to: 1.0; duration: 650; easing.type: Easing.InCubic }
                }
                SequentialAnimation on opacity {
                    running: leftSidebarButton.showPing
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.9; to: 0.15; duration: 650; easing.type: Easing.OutCubic }
                    NumberAnimation { from: 0.15; to: 0.9; duration: 650; easing.type: Easing.InCubic }
                }
            }
        }
    }
}

