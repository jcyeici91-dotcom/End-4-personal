import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root

    property string position: "top"
    property int cornerStyle: 0
    property bool useGlassMode: true
    property bool showSolidBackground: false
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.30)
    property real overlayStrength: Appearance.colors.isDark ? 1.0 : 0.95

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property int outerMargin: (cornerStyle === 1) ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0)) : 0
    readonly property int rad: (cornerStyle === 1) ? (Appearance.rounding.windowRounding ?? 18) : 0

    anchors.margins: outerMargin

    Rectangle {
        id: shell
        anchors.fill: parent
        radius: root.rad
        antialiasing: true
        color: "transparent"
        clip: true
        visible: root.useGlassMode && !root.showSolidBackground

        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.08 : 0.25) }
                GradientStop { position: 0.4; color: "transparent" }
                GradientStop { position: 0.8; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.35 : 0.06) }
            }
            opacity: root.overlayStrength
        }

        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            color: "transparent"
            border.width: 1
            border.color: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.70) : Qt.rgba(0, 0, 0, 0.18)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, shell.radius - 1)
            antialiasing: true
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.12 : 0.60)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad : 2
            anchors.rightMargin: root.rad > 0 ? root.rad : 2
            anchors.topMargin: 1
            height: 1
            opacity: root.overlayStrength
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.60) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.40 : 0.95) }
                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.60) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
