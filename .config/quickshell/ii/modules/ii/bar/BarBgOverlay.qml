import QtQuick
import QtQuick.Effects
import qs
import qs.modules.common

Item {
    id: root

     property string position: "top" // "top" | "bottom"

    required property bool useGlassMode
    required property bool showSolidBackground
    required property color backgroundColor
    required property int cornerStyle

    // Ajustes finos
    property int basePadding: 4
    property bool enableMask: true

    readonly property int outerMargin: (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
        : 0

    readonly property int radiusPx: (cornerStyle === 1) ? Appearance.rounding.windowRounding : 0

    // Slot para contenido
    default property alias content: contentContainer.data

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: root.radiusPx
        antialiasing: true

        color: root.backgroundColor

        border.width: (root.cornerStyle === 1) ? 1 : 0
        border.color: root.showSolidBackground
            ? Appearance.colors.colLayer0Border
            : (Appearance.colors.isDark
                ? Qt.rgba(1, 1, 1, 0.08)
                : Qt.rgba(1, 1, 1, 0.28))

        Behavior on color {
            ColorAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }
        Behavior on border.color {
            ColorAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }

        // Rim / highlight cuando está en "glass"
        Item {
            anchors.fill: parent
            visible: root.useGlassMode
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                antialiasing: true
                color: Appearance.colors.isDark
                    ? Qt.rgba(0, 0, 0, 0.08)
                    : Qt.rgba(1, 1, 1, 0.10)
            }

            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0;  color: Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.65) }
                    GradientStop { position: 0.40; color: Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.22) }
                    GradientStop { position: 1.0;  color: Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.40) }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: Appearance.colors.isDark
                    ? Qt.rgba(1, 1, 1, 0.18)
                    : Qt.rgba(1, 1, 1, 0.55)
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, bg.radius - 1)
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: Appearance.colors.isDark
                    ? Qt.rgba(0, 0, 0, 0.26)
                    : Qt.rgba(0, 0, 0, 0.12)
            }
        }
    }

    // Contenido con padding 
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }

    // Máscara para recortar 
    layer.enabled: root.enableMask
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: bg
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}

