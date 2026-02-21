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

    // Propiedades requeridas (No borrar)
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // Colores y Bordes
    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property bool showBorder: true
    property real borderOpacity: 0.08

    // Auto-hide
    property bool autoHide: true

    // Estética extra
    property bool showHighlight: true
    property real highlightOpacity: 0.06
    property bool clipContent: true

    // true  => dibuja fondo/borde/highlight
    // false => transparente (solo layout)
    property bool isContainer: true

    // Aplanar borde externo en Hybrid (islas extremas)
    property bool attachScreenLeft: false
    property bool attachScreenRight: false

    // =========================
    // NUEVO: Bridge mode (para PUENTES)
    // =========================
    property bool bridgeMode: false

    // =========================
    // NUEVO: Animación de tamaño (FIX “relentizado”)
    // =========================
    property bool enableSizeAnimation: false // prueba relentizado 
    property int sizeAnimDuration: 85

    // =========================
    // NUEVO: Detección de Cristal
    // =========================
    readonly property int styleIntFromConfig: Config.options?.bar?.barBackgroundStyle ?? 1
    readonly property bool bgIsCrystal: styleIntFromConfig === 3

    // =========================
    // Lógica Interna y Selector de Estilo
    // =========================
    readonly property bool isBorderless: (Config.options?.bar?.borderless ?? false)

    readonly property string groupBackgroundStyle: (Config.options?.bar?.groupBackgroundStyle ?? "rounded")
    readonly property bool useRectBg: groupBackgroundStyle === "rect"
    readonly property bool useHybridBg: groupBackgroundStyle === "hybrid"
    readonly property bool useLineBg: groupBackgroundStyle === "line" // Soporte para Line agregado

    // Barra arriba/abajo (para Hybrid notch)
    readonly property bool isBottom: (Config.options?.bar?.bottom ?? false)

    readonly property bool hasContent: gridLayout.visibleChildren.length > 0
    readonly property bool shouldBeVisible: autoHide ? hasContent : true

    // =========================
    // Derivados (bridge)
    // =========================
    readonly property bool effectiveShowBorder: (!bridgeMode) && showBorder
    readonly property bool effectiveShowHighlight: (!bridgeMode) && showHighlight
    readonly property int effectiveEdgeInset: bridgeMode ? 0 : edgeInset

    // =========================
    // CÁLCULO DE RADIOS
    // =========================
    readonly property real bgSize: Math.min(width, height)
    readonly property real pillRadius: Math.max(0, bgSize / 2)

    readonly property real baseRadius: {
        // CORRECCIÓN: Para el modo Rect usamos radio 4 (esquinas apenas redondeadas)
        if (useRectBg) return 4; 
        if (useLineBg) return 0;
        if (isBorderless) return startRadius;
        return pillRadius;
    }

    // Hybrid: aplanar el lado “pegado” (top o bottom)
    readonly property bool flattenTop: useHybridBg && !vertical && !isBottom
    readonly property bool flattenBottom: useHybridBg && !vertical && isBottom

    // Radios finales por esquina
    readonly property real finalRTL: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenTop || attachScreenLeft) return 0;
        return baseRadius;
    }
    readonly property real finalRTR: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenTop || attachScreenRight) return 0;
        return baseRadius;
    }
    readonly property real finalRBL: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenBottom || attachScreenLeft) return 0;
        return baseRadius;
    }
    readonly property real finalRBR: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenBottom || attachScreenRight) return 0;
        return baseRadius;
    }

    // =========================
    // Geometría
    // =========================
    visible: shouldBeVisible || opacity > 0
    opacity: shouldBeVisible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

    implicitWidth: shouldBeVisible
        ? (vertical
            ? (Appearance.sizes.baseVerticalBarWidth + effectiveEdgeInset * 2)
            : (gridLayout.implicitWidth + (padding * 2) + effectiveEdgeInset * 2))
        : 0

    implicitHeight: shouldBeVisible
        ? (vertical
            ? (gridLayout.implicitHeight + (padding * 2) + effectiveEdgeInset * 2)
            : (Appearance.sizes.baseBarHeight + effectiveEdgeInset * 2))
        : 0

    Behavior on implicitWidth {
        enabled: root.enableSizeAnimation
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        enabled: root.enableSizeAnimation
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }

    default property alias items: gridLayout.data

    // =========================
    // Fondo
    // =========================
    Loader {
        id: backgroundLoader
        anchors.fill: parent

        // En bridgeMode => 0 todo (evita micro-gaps)
        anchors.topMargin: root.bridgeMode
            ? 0
            : ((useHybridBg && !vertical && !isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset))
        anchors.bottomMargin: root.bridgeMode
            ? 0
            : ((useHybridBg && !vertical && isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset))
        anchors.leftMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)
        anchors.rightMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)

        // Selección dinámica de los 3 componentes
        sourceComponent: {
            if (root.useLineBg) return lineBackgroundComponent;
            return root.useRectBg ? rectBackgroundComponent : roundedBackgroundComponent;
        }
    }

    Component {
        id: rectBackgroundComponent

        Canvas {
            anchors.fill: parent
            antialiasing: true
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Cooperative

            property color bgColor: {
                if (!root.isContainer || root.isBorderless) return "transparent"
                // MAGIA CRISTAL: Si el cristal está activo, hacemos el color semi-transparente
                if (root.bgIsCrystal) return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, 0.25)
                return root.colBackground
            }
            property color borderColor: {
                if (!root.isContainer || root.isBorderless || !root.effectiveShowBorder) return "transparent"
                if (root.bgIsCrystal) return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.05)
                return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity) : Qt.rgba(0, 0, 0, 0.14)
            }
            property real borderWidth: (root.isContainer && !root.isBorderless && root.effectiveShowBorder) ? 1 : 0

            onBgColorChanged: requestPaint()
            onBorderColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onBorderWidthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                var w = width;
                var h = height;

                ctx.reset();
                ctx.clearRect(0, 0, w, h);
                ctx.beginPath();

                var r = root.baseRadius; // Usamos el baseRadius corregido

                ctx.moveTo(0, r);
                if (r > 0) ctx.arc(r, r, r, Math.PI, 1.5 * Math.PI); else ctx.lineTo(0, 0);

                ctx.lineTo(w - r, 0);
                if (r > 0) ctx.arc(w - r, r, r, 1.5 * Math.PI, 0); else ctx.lineTo(w, 0);

                ctx.lineTo(w, h - r);
                if (r > 0) ctx.arc(w - r, h - r, r, 0, 0.5 * Math.PI); else ctx.lineTo(w, h);

                ctx.lineTo(r, h);
                if (r > 0) ctx.arc(r, h - r, r, 0.5 * Math.PI, Math.PI); else ctx.lineTo(0, h);

                ctx.closePath();
                ctx.fillStyle = bgColor;
                ctx.fill();

                if (borderWidth > 0) {
                    ctx.lineWidth = borderWidth;
                    ctx.strokeStyle = borderColor;
                    ctx.stroke();
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: root.isContainer && root.effectiveShowHighlight && !root.isBorderless
                color: "transparent"
                radius: root.baseRadius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? root.highlightOpacity : root.highlightOpacity * 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }
    }

    Component {
        id: roundedBackgroundComponent

        Rectangle {
            anchors.fill: parent
            // En bridgeMode desactivamos AA para evitar hairlines al recortar
            antialiasing: !root.bridgeMode

            color: {
                if (!root.isContainer || root.isBorderless) return "transparent"
                // MAGIA CRISTAL
                if (root.bgIsCrystal) return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, 0.25)
                return root.colBackground
            }

            border.width: (root.isContainer && !root.isBorderless && root.effectiveShowBorder) ? 1 : 0
            border.color: {
                if (!root.isContainer || root.isBorderless || !root.effectiveShowBorder) return "transparent"
                if (root.bgIsCrystal) return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.05)
                return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity) : Qt.rgba(0, 0, 0, 0.14)
            }

            topLeftRadius: root.finalRTL
            topRightRadius: root.finalRTR
            bottomLeftRadius: root.finalRBL
            bottomRightRadius: root.finalRBR

            Rectangle {
                anchors.fill: parent
                visible: root.isContainer && root.effectiveShowHighlight && !root.isBorderless
                color: "transparent"
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? root.highlightOpacity : root.highlightOpacity * 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }
    }

    // Componente Agregado para soportar modo Line sin romper lo demás
    Component {
        id: lineBackgroundComponent
        
        Rectangle {
            anchors.fill: parent
            color: "transparent" 
            
            Rectangle {
                width: parent.width
                height: 2
                anchors.bottom: root.isBottom ? undefined : parent.bottom
                anchors.top: root.isBottom ? parent.top : undefined
                color: {
                    if (root.bgIsCrystal) return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3)
                    return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity * 2) : Qt.rgba(0, 0, 0, 0.2)
                }
                visible: root.effectiveShowBorder && root.isContainer
            }
        }
    }

    // =========================
    // Contenido
    // =========================
    Item {
        id: contentArea
        anchors.fill: backgroundLoader
        anchors.margins: root.padding
        clip: root.clipContent

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
