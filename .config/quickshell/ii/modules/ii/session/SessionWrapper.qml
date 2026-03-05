pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "../../components"

PanelWindow {
    id: root

    anchors { right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property int handleWidth: 10
    property bool open: false

    readonly property int contentWidth: contentItem.implicitWidth
    readonly property int contentHeight: contentItem.implicitHeight

    visible: implicitWidth > 0
    implicitWidth: open ? contentWidth : handleWidth
    implicitHeight: contentHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }

    function openNow() {
        closeDebounce.stop()
        open = true
    }

    function closeNowIfOutside() {
        // Solo cierra si NO está el mouse en ninguna zona activa
        if (!panelHover.containsMouse && !handle.containsMouse) {
            open = false
        }
    }

    // Pequeño retardo para evitar falsos "Exited" en el borde/animación
    Timer {
        id: closeDebounce
        interval: 80
        repeat: false
        onTriggered: root.closeNowIfOutside()
    }

    Item {
        anchors.fill: parent
        clip: true

        SessionContent {
            id: contentItem
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            id: panelHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onEntered: root.openNow()
            onExited: closeDebounce.restart()
        }
    }

    MouseArea {
        id: handle
        z: 9999

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.handleWidth

        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: root.openNow()
        onExited: closeDebounce.restart()
    }
}

