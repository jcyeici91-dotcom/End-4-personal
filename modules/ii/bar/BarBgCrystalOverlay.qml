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

        // 1. LUZ VOLUMÉTRICA (Difusión superior suave para el efecto 3D)
        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, themeIsDark ? 0.18 : 0.35) }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.00) }
            }
            opacity: root.overlayStrength
        }

        // 2. SOMBRA INFERIOR CORREGIDA (Casi transparente para evitar la línea gruesa)
        // Redujimos la opacidad negra de 0.45 a 0.15 para que no manche la barra superior.
        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.00) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, themeIsDark ? 0.15 : 0.05) }
            }
            opacity: root.overlayStrength
        }

        // 3. BORDE EXTERIOR (Más suave y elegante)
        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            color: "transparent"
            border.width: 1
            border.color: themeIsDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.15)
        }

        // 4. REFLEJO INTERNO PRINCIPAL (Bisel de iOS)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, shell.radius - 1)
            antialiasing: true
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, themeIsDark ? 0.25 : 0.50)
        }

        // 5. HIGHLIGHT SUPERIOR (El filo de luz brillante de Apple)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad / 1.2 : 1
            anchors.rightMargin: root.rad > 0 ? root.rad / 1.2 : 1
            anchors.topMargin: 1
            height: 1
            color: Qt.rgba(1, 1, 1, themeIsDark ? 0.35 : 0.80)
            opacity: root.overlayStrength
            antialiasing: true
        }
    }
}
