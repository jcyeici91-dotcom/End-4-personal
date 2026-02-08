import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // =========================================================
    // 1) API pública (props)
    // =========================================================
    property bool vertical: false
    property real padding: 5

    // Radios de esquina "lógicos" del grupo:
    // - startRadius: esquina de inicio (horizontal: izquierda, vertical: arriba)
    // - endRadius: esquina de fin (horizontal: derecha, vertical: abajo)
    //
    // NUEVO: por seguridad los normalizamos a 0 si vienen undefined/null/no numéricos.
    property var startRadius
    property var endRadius
    readonly property real _startR: (typeof startRadius === "number") ? startRadius : 0
    readonly property real _endR: (typeof endRadius === "number") ? endRadius : 0

    property color colBackground: Appearance.colors.colLayer2

    // Los componentes hijos se declaran dentro de BarGroup { ... } gracias a este alias
    // (se mantiene igual que tu original).
    default property alias items: gridLayout.children

    // =========================================================
    // 2) Tamaño implícito (layout-driven)
    // =========================================================
    // Mantiene la lógica original:
    // - Horizontal: ancho según contenido + padding; alto fijo (baseBarHeight)
    // - Vertical: ancho fijo (baseVerticalBarWidth); alto según contenido + padding
    implicitWidth: root.vertical
        ? Appearance.sizes.baseVerticalBarWidth
        : (gridLayout.implicitWidth + root.padding * 2)

    implicitHeight: root.vertical
        ? (gridLayout.implicitHeight + root.padding * 2)
        : Appearance.sizes.baseBarHeight

    // =========================================================
    // 3) Fondo (background)
    // =========================================================
    Rectangle {
        id: background
        anchors {
            fill: parent

            // Mantiene tu “inset” de 4px dependiendo de orientación.
            // Esto suele ayudar a que el grupo no toque bordes externos.
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }

        // NUEVO (corrección): optional chaining completo para evitar errores si `bar` no existe.
        // Antes: Config.options?.bar.borderless  (podía fallar si options existe pero bar no).
        color: (Config.options?.bar?.borderless === true) ? "transparent" : root.colBackground

        // Esquinas:
        // Horizontal:
        //  - left corners usan startRadius
        //  - right corners usan endRadius
        //
        // Vertical (rotación lógica):
        //  - top corners usan startRadius
        //  - bottom corners usan endRadius
        topLeftRadius: root._startR
        bottomRightRadius: root._endR

        // NUEVO (robustez): usar valores normalizados (_startR/_endR)
        bottomLeftRadius: root.vertical ? root._endR : root._startR
        topRightRadius: root.vertical ? root._startR : root._endR
    }

    // =========================================================
    // 4) Contenedor de items (GridLayout)
    // =========================================================
    GridLayout {
        id: gridLayout

        // Igual que el original:
        // - vertical => 1 columna
        // - horizontal => flujo por filas (columns = -1 en Qt Quick Layouts)
        columns: root.vertical ? 1 : -1

        anchors {
            // Horizontal: centrado vertical, ocupa todo el ancho
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right

            // Vertical: centrado horizontal, ocupa todo el alto
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined

            margins: root.padding
        }

        // Spacing original
        columnSpacing: 4
        rowSpacing: 12
    }
}

