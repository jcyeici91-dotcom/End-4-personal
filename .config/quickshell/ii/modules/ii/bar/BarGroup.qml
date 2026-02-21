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

    // ==============================================================
    // FIX MAESTRO PARA LAS "MINI PÍLDORAS" INTERNAS:
    // Si estamos en modo Cristal (bgIsCrystal), el espaciado interno
    // se vuelve 0 para que los elementos se peguen y formen un solo
    // cuerpo de vidrio sin líneas separadoras en el medio.
    // Si NO es Cristal, respeta el espaciado original de 4.
    // ==============================================================
    property int spacing: root.bgIsCrystal ? 0 : 4

    property int edgeInset: 2

    // NUEVO: unificar visualmente el interior del grupo
    // En modo Cristal, siempre los unificamos. En otros modos, según preferencia.
    property bool unifyInside: root.bgIsCrystal ? true : false

    // (Opcional) Señal para que los widgets hijos apaguen su propio “chip background”
    property bool unifyChildChips: root.bgIsCrystal ? true : false

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
    // Bridge mode (para PUENTES)
    // =========================
    property bool bridgeMode: false

    // =========================
    // Animación de tamaño
    // =========================
    property bool enableSizeAnimation: false
    property int sizeAnimDuration: 85

    // =========================
    // Detección de Cristal y Tema
    // =========================
    readonly property int styleIntFromConfig: Config.options?.bar?.barBackgroundStyle ?? 1
    readonly property bool bgIsCrystal: styleIntFromConfig === 3

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    // =========================
    // Lógica Interna y Selector de Estilo
    // =========================
    readonly property bool isBorderless: (Config.options?.bar?.borderless ?? false)

    readonly property string groupBackgroundStyle: (Config.options?.bar?.groupBackgroundStyle ?? "rounded")
    readonly property bool useRectBg: groupBackgroundStyle === "rect"
    readonly property bool useHybridBg: groupBackgroundStyle === "hybrid"
    readonly property bool useLineBg: groupBackgroundStyle === "line"

    // Barra arriba/abajo
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
        if (useRectBg) return 4;
        if (useLineBg) return 0;
        if (isBorderless) return startRadius;
        return pillRadius;
    }

    readonly property bool flattenTop: useHybridBg && !vertical && !isBottom
    readonly property bool flattenBottom: useHybridBg && !vertical && isBottom

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

        anchors.topMargin: root.bridgeMode ? 0 : ((useHybridBg && !vertical && !isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset))
        anchors.bottomMargin: root.bridgeMode ? 0 : ((useHybridBg && !vertical && isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset))
        anchors.leftMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)
        anchors.rightMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)

        sourceComponent: {
            if (root.useLineBg) return lineBackgroundComponent;
            return root.useRectBg ? rectBackgroundComponent : roundedBackgroundComponent;
        }
    }

    // =========================================================
    // RECT
    // =========================================================
    Component {
        id: rectBackgroundComponent

        Rectangle {
            anchors.fill: parent
            antialiasing: !root.bridgeMode
            radius: root.baseRadius

            readonly property bool showCrystal: root.bgIsCrystal && root.isContainer && !root.isBorderless
            readonly property bool showSolid: !root.bgIsCrystal && root.isContainer && !root.isBorderless

            color: {
                if (!root.isContainer || root.isBorderless) return "transparent"
                if (root.bgIsCrystal)
                    return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, Appearance.colors.isDark ? 0.10 : 0.15)
                return root.colBackground
            }

            border.width: (showSolid && root.effectiveShowBorder) ? 1 : 0
            border.color: border.width > 0
                ? (Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity) : Qt.rgba(0, 0, 0, 0.14))
                : "transparent"

            // 1) Luz superior
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: parent.showCrystal
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.15 : 0.35) }
                    GradientStop { position: 0.4; color: "transparent" }
                }
            }

            // 2) Sombra inferior
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: parent.showCrystal
                gradient: Gradient {
                    GradientStop { position: 0.6; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.30 : 0.10) }
                }
            }

            // 3) Borde exterior
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: parent.showCrystal
                color: "transparent"
                border.width: 1
                border.color: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.50) : Qt.rgba(0, 0, 0, 0.15)
            }

            // 4) Bisel interior
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                visible: parent.showCrystal
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.15 : 0.40)
            }

            // 5) Highlight superior
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: parent.radius / 1.2
                anchors.rightMargin: parent.radius / 1.2
                anchors.topMargin: 1
                height: 1
                visible: parent.showCrystal
                color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.40 : 0.80)
            }

            // Highlight normal
            Rectangle {
                anchors.fill: parent
                visible: showSolid && root.effectiveShowHighlight
                color: "transparent"
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? root.highlightOpacity : root.highlightOpacity * 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }
    }

    // =========================================================
    // PILLS / ROUNDED
    // =========================================================
    Component {
        id: roundedBackgroundComponent

        Rectangle {
            anchors.fill: parent
            antialiasing: !root.bridgeMode

            readonly property bool showCrystal: root.bgIsCrystal && root.isContainer && !root.isBorderless
            readonly property bool showSolid: !root.bgIsCrystal && root.isContainer && !root.isBorderless

            color: {
                if (!root.isContainer || root.isBorderless) return "transparent"
                if (root.bgIsCrystal)
                    return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, Appearance.colors.isDark ? 0.10 : 0.15)
                return root.colBackground
            }

            border.width: (showSolid && root.effectiveShowBorder) ? 1 : 0
            border.color: border.width > 0
                ? (Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity) : Qt.rgba(0, 0, 0, 0.14))
                : "transparent"

            topLeftRadius: root.finalRTL
            topRightRadius: root.finalRTR
            bottomLeftRadius: root.finalRBL
            bottomRightRadius: root.finalRBR

            // 1) Luz superior
            Rectangle {
                anchors.fill: parent
                visible: parent.showCrystal
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.15 : 0.35) }
                    GradientStop { position: 0.4; color: "transparent" }
                }
            }

            // 2) Sombra inferior
            Rectangle {
                anchors.fill: parent
                visible: parent.showCrystal
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                gradient: Gradient {
                    GradientStop { position: 0.6; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.30 : 0.10) }
                }
            }

            // 3) Borde exterior
            Rectangle {
                anchors.fill: parent
                visible: parent.showCrystal
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                color: "transparent"
                border.width: 1
                border.color: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.50) : Qt.rgba(0, 0, 0, 0.15)
            }

            // 4) Bisel interior
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                visible: parent.showCrystal
                topLeftRadius: Math.max(0, parent.topLeftRadius - 1)
                topRightRadius: Math.max(0, parent.topRightRadius - 1)
                bottomLeftRadius: Math.max(0, parent.bottomLeftRadius - 1)
                bottomRightRadius: Math.max(0, parent.bottomRightRadius - 1)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.15 : 0.40)
            }

            // 5) Highlight superior
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: parent.showCrystal
                anchors.leftMargin: parent.topLeftRadius > 0 ? parent.topLeftRadius / 1.2 : 1
                anchors.rightMargin: parent.topRightRadius > 0 ? parent.topRightRadius / 1.2 : 1
                anchors.topMargin: 1
                height: 1
                color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.40 : 0.80)
            }

            // Highlight normal
            Rectangle {
                anchors.fill: parent
                visible: showSolid && root.effectiveShowHighlight
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

    // =========================================================
    // LINE
    // =========================================================
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
                    if (root.bgIsCrystal)
                        return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3)
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

            // CAMBIO CLAVE para lo que pediste:
            // esto elimina la “mini separación/píldora” entre widgets
            columnSpacing: root.unifyInside ? 0 : root.spacing
            rowSpacing: root.unifyInside ? 0 : root.spacing
        }
    }
}
