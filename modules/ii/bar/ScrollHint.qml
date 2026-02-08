import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Revealer { // Scroll hint
    id: root

    // =========================================================
    // 1) API pública
    // =========================================================
    // Icono central (MaterialSymbol.text)
    property string icon: ""

    // "left" o "right" (lado donde se pega el hint)
    property string side: "left"

    // Texto del tooltip (vacío = no tooltip)
    property string tooltipText: ""

    // NUEVO (robustez): valida side y expone un flag interno
    readonly property bool _isLeft: (root.side !== "right") // cualquier cosa distinta de "right" se trata como "left"

    // =========================================================
    // 2) Área interactiva (hover + tooltip)
    // =========================================================
    MouseArea {
        id: mouseArea

        // Pegado al borde según lado
        anchors.right: root._isLeft ? parent.right : undefined
        anchors.left: root._isLeft ? undefined : parent.left

        implicitWidth: contentColumn.implicitWidth
        implicitHeight: contentColumn.implicitHeight

        // Hover (solo para hint/tooltip; no captura clicks)
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        // NUEVO (limpieza): reutilizamos containsMouse, no hace falta propiedad hovered manual
        readonly property bool hovered: containsMouse

        // =====================================================
        // 3) Lógica: delay antes de mostrar tooltip
        // =====================================================
        property bool showHintTimedOut: false

        // Reset al entrar/salir del hover
        onHoveredChanged: showHintTimedOut = false

        Timer {
            id: hintDelayTimer

            // NUEVO (robustez): se reinicia correctamente al re-hover
            running: mouseArea.hovered
            repeat: false
            interval: 500

            onTriggered: mouseArea.showHintTimedOut = true
        }

        // =====================================================
        // 4) Tooltip
        // =========================================================
        PopupToolTip {
            // NUEVO: trim() para evitar tooltip "vacío con espacios"
            extraVisibleCondition: (root.tooltipText.trim().length > 0 && mouseArea.showHintTimedOut)
            text: root.tooltipText
        }

        // =========================================================
        // 5) UI (iconos arriba/centro/abajo)
        // =========================================================
        Column {
            id: contentColumn
            anchors.fill: parent
            spacing: -5

            MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }

            MaterialSymbol {
                // NUEVO (robustez): si icon viene vacío, no crashea; solo no muestra nada útil
                text: root.icon
                iconSize: 14
                color: Appearance.colors.colSubtext
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
        }
    }
  }

