import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import Quickshell

Item {
    id: root

    property bool isBottom: false
    property bool themeIsDark: true
    property bool effectiveShowBorder: true
    property real borderOpacity: 0.1

    readonly property real radiusValue: 12

    layer.enabled: false

    Rectangle {
        anchors.fill: parent
        radius: root.radiusValue
        antialiasing: true
        color: root.themeIsDark
            ? Qt.rgba(0.08, 0.08, 0.08, 0.34)
            : Qt.rgba(0.97, 0.97, 0.97, 0.28)

        border.width: 1
        border.color: root.themeIsDark
            ? Qt.rgba(1, 1, 1, 0.10)
            : Qt.rgba(1, 1, 1, 0.48)
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radiusValue
        antialiasing: true
        color: "transparent"
        visible: true

        gradient: Gradient {
            orientation: root.isBottom ? Gradient.BottomToTop : Gradient.TopToBottom
            GradientStop {
                position: 0.0
                color: root.themeIsDark
                    ? Qt.rgba(1, 1, 1, 0.075)
                    : Qt.rgba(1, 1, 1, 0.16)
            }
            GradientStop {
                position: 0.22
                color: root.themeIsDark
                    ? Qt.rgba(1, 1, 1, 0.035)
                    : Qt.rgba(1, 1, 1, 0.08)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0.0)
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        radius: 1
        antialiasing: true
        anchors.top: root.isBottom ? undefined : parent.top
        anchors.bottom: root.isBottom ? parent.bottom : undefined
        color: root.themeIsDark
            ? Qt.rgba(1, 1, 1, 0.12)
            : Qt.rgba(1, 1, 1, 0.24)
    }

    Rectangle {
        width: parent.width
        height: 2
        anchors.bottom: root.isBottom ? undefined : parent.bottom
        anchors.top: root.isBottom ? parent.top : undefined
        color: root.themeIsDark
            ? Qt.rgba(1, 1, 1, Math.max(0.08, root.borderOpacity * 1.8))
            : Qt.rgba(0, 0, 0, 0.18)
        visible: root.effectiveShowBorder
    }
}
