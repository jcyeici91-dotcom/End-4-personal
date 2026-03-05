import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property string iconName
    property string command
    property string tooltip: ""
    property int iconSize: 22

    property bool isHovered: false
    property bool isPressed: false

    implicitWidth: 74
    implicitHeight: 74

    onClicked: {
        Quickshell.execDetached(["bash", "-c", command])
        GlobalStates.sessionVisible = false
    }

    Item {
        anchors.fill: parent
        
        scale: root.isPressed ? 0.92 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuart
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            antialiasing: true

            color: root.isPressed
                   ? Qt.rgba(1, 1, 1, 0.12)
                   : root.isHovered
                     ? Qt.rgba(1, 1, 1, 0.08)
                     : Qt.rgba(1, 1, 1, 0.04)

            border.width: root.isHovered ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.width { NumberAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconName
            font.pixelSize: root.iconSize
            antialiasing: true

            color: root.isPressed
                   ? Qt.rgba(1, 1, 1, 0.92)
                   : root.isHovered
                     ? Qt.rgba(1, 1, 1, 1.0)
                     : Appearance.colors.colOnSurface

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton

        onEntered: root.isHovered = true
        onExited: {
            root.isHovered = false
            root.isPressed = false
        }

        onPressed: (mouse) => {
            root.isPressed = true
            mouse.accepted = false
        }

        onReleased: (mouse) => {
            root.isPressed = false
            mouse.accepted = false
        }
    }

    Rectangle {
        id: tip
        visible: root.isHovered && root.tooltip.length > 0
        z: 9999
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)

        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - 10

        implicitWidth: tipText.implicitWidth + 14
        implicitHeight: tipText.implicitHeight + 8

        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.tooltip
            color: "white"
            font.pixelSize: 12
        }
    }
}
