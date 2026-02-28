// BarBgCrystalOverlay.qml
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
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.40) }
                GradientStop { position: 0.15; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.03 : 0.10) }
                GradientStop { position: 0.5; color: "transparent" }
                // Sombras más sutiles para el volumen
                GradientStop { position: 0.85; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.10 : 0.01) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.30 : 0.05) }
            }
            opacity: root.overlayStrength
        }

            Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, shell.radius - 1)
            antialiasing: true
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.12 : 0.35)
        }

           Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad * 1.5 : 20
            anchors.rightMargin: root.rad > 0 ? root.rad * 1.5 : 20
            anchors.topMargin: 1
            
          height: 1.5 
            
          opacity: root.overlayStrength * 0.85 
            
            antialiasing: true
            smooth: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                
            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.50) }
                
             GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.60 : 0.85) } 
                
                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.50) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad : 10
            anchors.rightMargin: root.rad > 0 ? root.rad : 10
            anchors.bottomMargin: 1
            height: 1.5
            opacity: root.overlayStrength * 0.7
            antialiasing: true
            smooth: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.18 : 0.40) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
