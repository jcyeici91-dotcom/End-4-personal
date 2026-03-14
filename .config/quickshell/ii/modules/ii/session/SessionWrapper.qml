pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import "../../components"

PanelWindow {
    id: root

    anchors {
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay // encima de las ventanas

    //área para atrapar el mouse sea más gruesa
    property int handleWidth: 10 
    property bool open: false

    readonly property int contentWidth: contentItem.implicitWidth
    readonly property int contentHeight: contentItem.implicitHeight

    // TAMAÑO FIJO
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    // Permite hacer clic en las ventanas de fondo cuando el panel está oculto
    mask: Region {
        item: panelHover
    }

    MouseArea {
        id: panelHover
        width: root.contentWidth
        height: root.contentHeight
        
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        
        // Cuando se oculta, empuja el contenido hacia la derecha (fuera de la pantalla)
        anchors.rightMargin: root.open ? 0 : -(root.contentWidth - root.handleWidth)

        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuart
            }
        }

        onEntered: {
            closeDebounce.stop()
            root.open = true
        }
        onExited: {
            closeDebounce.restart()
        }

        SessionContent {
            id: contentItem
            anchors.fill: parent
        }
    }

    Timer {
        id: closeDebounce
        interval: 150 // Un retardo ligeramente mayor para evitar que parpadee al salir rápido
        repeat: false
        onTriggered: {
            if (!panelHover.containsMouse) {
                root.open = false
            }
        }
    }
}
