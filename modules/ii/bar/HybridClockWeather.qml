pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    // =====================================================================
    // ESTADO
    // =====================================================================
    // false = reloj, true = clima
    property bool showWeather: false

    // (Opcional) evita cambios múltiples por una sola “pasada” de rueda
    property int wheelCooldownMs: 180
    property bool wheelLocked: false

    function togglePage() {
        showWeather = !showWeather
    }

    Timer {
        id: wheelCooldown
        interval: root.wheelCooldownMs
        repeat: false
        onTriggered: root.wheelLocked = false
    }

    // =====================================================================
    // TAMAÑO AUTOMÁTICO (según el componente visible)
    // =====================================================================
    readonly property real contentWidth: showWeather
        ? (weatherLoader.item ? weatherLoader.item.implicitWidth : 100)
        : (clockLoader.item ? clockLoader.item.implicitWidth : 100)

    implicitWidth: Math.max(1, contentWidth)
    implicitHeight: Appearance.sizes.barHeight > 0 ? Appearance.sizes.barHeight : 45

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // =====================================================================
    // ÚNICO CONTROL: RUEDA DEL RATÓN PARA ALTERNAR VISTA
    // (No bloquea clicks, no cierra popups, no toca hoverTarget, nada.)
    // =====================================================================
    MouseArea {
        id: wheelOnly
        anchors.fill: parent
        z: 100
        hoverEnabled: false
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            if (wheel.angleDelta.y === 0)
                return

            // (Opcional) “anti-scroll spam”
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

    // =====================================================================
    // COMPONENTE REUSABLE: Loader con animación y show/hide
    // =====================================================================
    component AnimatedPage: Loader {
        id: page

        // propiedad para controlar si se muestra
        property bool shown: false

        anchors.centerIn: parent
        active: true

        visible: shown
        opacity: shown ? 1 : 0
        scale: shown ? 1.0 : 0.8

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
    }

    // =====================================================================
    // RELOJ / CLIMA (ya sin duplicación de animaciones)
    // =====================================================================
    AnimatedPage {
        id: clockLoader
        source: "ClockWidget.qml"
        shown: !root.showWeather
    }

    AnimatedPage {
        id: weatherLoader
        source: "weather/WeatherBar.qml"
        shown: root.showWeather
    }
}

