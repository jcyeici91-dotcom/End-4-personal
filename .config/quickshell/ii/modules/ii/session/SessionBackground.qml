import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string attachEdge: "right"
    property real rounding: Appearance.rounding.windowRounding ?? 18
    property real borderWidth: 1

    Rectangle {
        id: shadowTarget
        anchors.fill: parent
        radius: root.rounding
        color: "transparent"
    }

    StyledRectangularShadow {
        anchors.fill: parent
        target: shadowTarget
        color: Qt.rgba(0, 0, 0, 0.25)
        blur: 14
        spread: -2
    }

    Rectangle {
        anchors.fill: parent
        radius: root.rounding
        color: Appearance.colors.colLayer0
        border.width: root.borderWidth
        border.color: Appearance.colors.colLayer0Border
        antialiasing: true
        
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
