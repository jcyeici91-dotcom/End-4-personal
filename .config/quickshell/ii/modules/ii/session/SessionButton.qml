pragma ComponentBehavior: Bound

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
    property int iconSize: 24

    property bool isHovered: false
    property bool isPressed: false

    implicitWidth: 64
    implicitHeight: 64

    onClicked: {
        Quickshell.execDetached(["bash", "-c", command])
        root.parent.parent.resetViewTimer.restart(); // Cierra el wrapper
    }

    Item {
        anchors.fill: parent
        
        scale: root.isPressed ? 0.92 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuart }
        }

        // Fondo transparente seguro (Se ve bien en cualquier tema)
        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.windowRounding ?? 16
            
            color: root.isPressed 
                    ? Qt.rgba(1, 1, 1, 0.12) 
                    : (root.isHovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
            
            border.width: root.isHovered ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.15)
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Icono siempre visible (Color claro del tema)
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconName
            font.pixelSize: root.iconSize
            color: Appearance.colors.colOnSurface // Texto siempre claro/visible
            opacity: root.isPressed ? 0.7 : 1.0
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
