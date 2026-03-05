pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    
    // -Orientación ---
    property bool vertical: false

    // ESTADO
     property bool showUtilButtons: false

    // evita cambios múltiples por una sola “pasada” de rueda
    property int wheelCooldownMs: 180
    property bool wheelLocked: false

    function togglePage() {
        showUtilButtons = !showUtilButtons
    }

    Timer {
        id: wheelCooldown
        interval: root.wheelCooldownMs
        repeat: false
        onTriggered: root.wheelLocked = false
    }

    // TAMAÑO AUTOMÁTICO (según el componente visible y la orientación)
    readonly property real contentWidth: showUtilButtons
        ? (utilLoader.item ? utilLoader.item.implicitWidth : 100)
        : (resourcesLoader.item ? resourcesLoader.item.implicitWidth : 100)

    readonly property real contentHeight: showUtilButtons
        ? (utilLoader.item ? utilLoader.item.implicitHeight : 45)
        : (resourcesLoader.item ? resourcesLoader.item.implicitHeight : 45)

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : Math.max(1, contentWidth)
    implicitHeight: root.vertical ? Math.max(1, contentHeight) : (Appearance.sizes.barHeight > 0 ? Appearance.sizes.barHeight : 45)

    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    Behavior on implicitHeight {
        enabled: root.vertical
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: wheelOnly
        anchors.fill: parent
        z: 100
        hoverEnabled: false
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            if (wheel.angleDelta.y === 0)
                return

            if (root.wheelLocked) {
                wheel.accepted = true
                return
            }
            root.wheelLocked = true
            wheelCooldown.restart()

            root.togglePage()
            wheel.accepted = true
        }
    }

    component AnimatedPage: Loader {
        id: page
        property bool shown: false

        anchors.centerIn: parent
        active: true

        visible: shown
        opacity: shown ? 1 : 0
        scale: shown ? 1.0 : 0.8

        // propiedad vertical 
        onLoaded: {
            if (item && item.hasOwnProperty("vertical")) {
                item.vertical = root.vertical;
            }
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
    }

        AnimatedPage {
        id: resourcesLoader
        source: "Resources.qml"
        shown: !root.showUtilButtons
    }

    AnimatedPage {
        id: utilLoader
        source: "UtilButtons.qml"
        shown: root.showUtilButtons
    }
}
