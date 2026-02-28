import QtQuick
import QtQuick.Effects
import qs
import qs.modules.common

Item {
    id: root

    required property Item targetItem
    required property int cornerStyle
    required property bool visibleWhen

    property real shadowOpacity: 0.32
    property int shadowBlur: 38
    property color shadowColor: Qt.rgba(0, 0, 0, 1)

    readonly property bool themeIsDark: Appearance.colors.isDark
    readonly property int radiusPx: (cornerStyle === 1)
        ? (Appearance.rounding.windowRounding ?? 18)
        : 0

    visible: visibleWhen

    x: targetItem.x
    y: targetItem.y
    width: targetItem.width
    height: targetItem.height

    layer.enabled: true
    layer.smooth: true

    Item {
        id: shadowContainer
        anchors.fill: parent

        Rectangle {
            id: coreShadow
            anchors.fill: parent
            radius: root.radiusPx
            color: "transparent"
            antialiasing: true
        }

        Rectangle {
            id: ambientShadow
            anchors.fill: parent
            anchors.margins: -12
            radius: root.radiusPx + 12
            color: "transparent"
            antialiasing: true
        }
    }

    layer.effect: MultiEffect {
        source: shadowContainer

        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: root.themeIsDark ? 8 : 6
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowColor: root.shadowColor

        blurEnabled: true
        blurMax: 64
        blur: root.themeIsDark ? 0.18 : 0.12
    }
}
