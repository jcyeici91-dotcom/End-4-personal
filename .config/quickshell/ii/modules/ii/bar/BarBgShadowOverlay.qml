import QtQuick
import QtQuick.Effects
import qs
import qs.modules.common

Rectangle {
    id: root

    required property Item targetItem
    required property int cornerStyle
    required property bool visibleWhen

    property real shadowOpacity: 0.35
    property int shadowBlur: 30
    property color shadowColor: Qt.rgba(0, 0, 0, 1)

    visible: visibleWhen

    x: targetItem.x
    y: targetItem.y
    width: targetItem.width
    height: targetItem.height

    // Este rectángulo actúa como "shape" para máscara
    color: "black"
    radius: (cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
    antialiasing: true

    layer.enabled: true
    layer.smooth: true

    layer.effect: MultiEffect {
         maskEnabled: true
        maskSource: root
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0

        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowColor: root.shadowColor
    }
}

