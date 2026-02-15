import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // =========================
    // Configuración Pública
    // =========================
    property bool vertical: false
    property int padding: 6
    property int spacing: 6
    property int edgeInset: 2

    // Radios de esquina
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // Colores y Bordes
    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property bool showBorder: true
    property real borderOpacity: 0.08

    // Auto-hide
    property bool autoHide: true

    // Estética extra (no rompe nada)
    property bool showHighlight: true          // luz sutil
    property real highlightOpacity: 0.06       // ajusta 0.03–0.10
    property bool clipContent: true            // recorta overflow (rectangular)

    // =========================
    // Propiedades Internas / Calculadas
    // =========================
    readonly property bool isBorderless: (Config.options?.bar?.borderless ?? false)

    // Ojo: visibleChildren cuenta hijos "visible == true" (no depende de tamaño).
    readonly property bool hasContent: gridLayout.visibleChildren.length > 0

    readonly property bool shouldBeVisible: autoHide ? hasContent : true

    // Radios calculados (para reutilizar sin repetir lógica)
    readonly property real rTL: startRadius
    readonly property real rBL: vertical ? endRadius : startRadius
    readonly property real rTR: vertical ? startRadius : endRadius
    readonly property real rBR: endRadius

    // =========================
    // Geometría y Visibilidad
    // =========================
    // Mejor que visible: opacity > 0 (evita “desaparece” por animación)
    // pero sin dejar el item “pintando” cuando está oculto:
    visible: shouldBeVisible || opacity > 0
    opacity: shouldBeVisible ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    // IMPORTANTE:
    // - Sumamos edgeInset*2 porque el fondo se mete hacia adentro con márgenes.
    // - El contenido ahora tendrá padding REAL (contentArea).
    implicitWidth: shouldBeVisible
        ? (vertical
            ? (Appearance.sizes.baseVerticalBarWidth + edgeInset * 2)
            : (gridLayout.implicitWidth + (padding * 2) + edgeInset * 2))
        : 0

    implicitHeight: shouldBeVisible
        ? (vertical
            ? (gridLayout.implicitHeight + (padding * 2) + edgeInset * 2)
            : (Appearance.sizes.baseBarHeight + edgeInset * 2))
        : 0

    Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
    Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

    default property alias items: gridLayout.data

    // =========================
    // Fondo Estilizado
    // =========================
    Rectangle {
        id: background
        anchors.fill: parent

        // inset visual
        anchors.topMargin: root.vertical ? 0 : root.edgeInset
        anchors.bottomMargin: root.vertical ? 0 : root.edgeInset
        anchors.leftMargin: root.vertical ? root.edgeInset : 0
        anchors.rightMargin: root.vertical ? root.edgeInset : 0

        antialiasing: true
        color: root.isBorderless ? "transparent" : root.colBackground

        border.width: (!root.isBorderless && root.showBorder) ? 1 : 0
        border.color: {
            if (root.isBorderless || !root.showBorder) return "transparent"
            return Appearance.colors.isDark
                ? Qt.rgba(1, 1, 1, root.borderOpacity)
                : Qt.rgba(0, 0, 0, 0.14)
        }

        topLeftRadius: root.rTL
        bottomLeftRadius: root.rBL
        topRightRadius: root.rTR
        bottomRightRadius: root.rBR

        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        // Highlight sutil para “mejor look” (no cambia tamaños, no rompe nada)
        Rectangle {
            anchors.fill: parent
            visible: root.showHighlight && !root.isBorderless
            radius: 0 // no usamos radius porque ya está el padre redondeado

            // Truco: overlay con degradado muy leve (se ve más “premium”)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? root.highlightOpacity : root.highlightOpacity * 0.6) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }

            // Para que no “ensucie” el borde:
            opacity: 1
        }
    }

    // =========================
    // Área de contenido (padding REAL)
    // =========================
    Item {
        id: contentArea
        anchors.fill: background
        anchors.margins: root.padding

        // Esto evita que algunos widgets se salgan del rect (rectangular).
        // Si te molesta que recorte animaciones, pon clipContent: false.
        clip: root.clipContent && root.shouldBeVisible

        GridLayout {
            id: gridLayout
            anchors.centerIn: parent

            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: root.vertical ? 1 : -1
            rows: root.vertical ? -1 : 1

            columnSpacing: root.spacing
            rowSpacing: root.spacing
        }
    }
}

