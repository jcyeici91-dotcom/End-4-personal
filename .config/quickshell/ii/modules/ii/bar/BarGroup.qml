import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    // 👇 CONECTADO AL INTERRUPTOR MAESTRO 👇
    property bool enableAnimations: Config.options.appearance.enableAnimations

    property bool vertical: false

    property int padding: (!isContainer || forceNoContainer || unifyInside) ? 0 : 6
    property int edgeInset: 2

    property int spacing: 4

    property bool unifyInside: false
    property bool unifyChildChips: false
    
    // --- NUEVO: Modo especial para el Notch Central ---
    property bool isNotch: false

    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property bool showBorder: true
    property real borderOpacity: 0.08

    property bool autoHide: true

    property bool showHighlight: true
    property real highlightOpacity: 0.06
    property bool clipContent: true

    property bool isContainer: true
    property bool forceNoContainer: unifyChildChips

    property bool attachScreenLeft: false
    property bool attachScreenRight: false
    property bool disableFloatInset: false

    property bool bridgeMode: false

    property bool enableSizeAnimation: false
    property int sizeAnimDuration: 85

    property int notchWidth: 140
    property int notchDepth: 16
    property int notchInnerRadius: 14
    property int notchOuterRadius: 22

    readonly property string cornerStyle: (Config.options?.bar?.cornerStyle ?? "hug")
    readonly property bool cornerIsFloat: cornerStyle === "float"
    readonly property bool cornerIsRect: cornerStyle === "rect"

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)
    readonly property bool isBorderless: (Config.options?.bar?.borderless ?? false)
    property string groupBackgroundStyle: (Config.options?.bar?.groupBackgroundStyle ?? "pills")

    readonly property bool usePillsBg: (groupBackgroundStyle === "pills" || groupBackgroundStyle === "rounded" || groupBackgroundStyle === "")
    readonly property bool useRectBg: groupBackgroundStyle === "rect"
    readonly property bool useHybridBg: groupBackgroundStyle === "hybrid"
    readonly property bool useLineBg: groupBackgroundStyle === "line"
    readonly property bool useNotchBg: groupBackgroundStyle === "notch" && !vertical

    // 👇 NUEVO: Detecta la combinación Glass + Line 👇
    readonly property bool isGlassMode: (Config.options?.bar?.barBackgroundStyle === 0)
    readonly property bool isGlassLineEffect: isGlassMode && useLineBg

    readonly property bool isBottom: (Config.options?.bar?.bottom ?? false)

    readonly property bool hasContent: gridLayout.visibleChildren.length > 0
    readonly property bool shouldBeVisible: autoHide ? hasContent : true

    readonly property bool effectiveShowBorder: (!bridgeMode) && showBorder
    readonly property bool effectiveShowHighlight: (!bridgeMode) && showHighlight

    readonly property int effectiveEdgeInset: (bridgeMode || disableFloatInset) ? 0 : (cornerIsFloat ? Math.max(2, edgeInset) : edgeInset)

    readonly property real pillMeasure: {
        const m = vertical ? backgroundLoader.width : backgroundLoader.height
        return Math.max(1, m)
    }

    readonly property real pillRadius: Math.max(0, pillMeasure / 2)
    readonly property real rectRadius: Math.max(0, Appearance.rounding.small)

    readonly property real baseRadius: {
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return rectRadius
        if (isBorderless) return startRadius
        if (root.forcePillStyle) return pillRadius
        return pillRadius
    }

    property bool forcePillStyle: false

    readonly property bool allowFlatten: useHybridBg && !cornerIsFloat && !forcePillStyle
    readonly property bool flattenTop: allowFlatten && !vertical && !isBottom
    readonly property bool flattenBottom: allowFlatten && !vertical && isBottom
    readonly property bool allowAttach: allowFlatten && !cornerIsFloat

    // Esquinas calculadas: Si es Notch, fuerza base plana arriba
    readonly property real finalRTL: {
        if (isNotch && !isBottom) return 0
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenTop || (allowAttach && attachScreenLeft)) return 0
        return baseRadius
    }

    readonly property real finalRTR: {
        if (isNotch && !isBottom) return 0
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenTop || (allowAttach && attachScreenRight)) return 0
        return baseRadius
    }

    readonly property real finalRBL: {
        if (isNotch && isBottom) return 0
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenBottom || (allowAttach && attachScreenLeft)) return 0
        return baseRadius
    }

    readonly property real finalRBR: {
        if (isNotch && isBottom) return 0
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenBottom || (allowAttach && attachScreenRight)) return 0
        return baseRadius
    }

    readonly property color effectiveFill: {
        if (!root.isContainer || root.isBorderless)
            return "transparent"
        return root.colBackground
    }

    readonly property color effectiveBorderColor: Appearance.colors.colLayer0Border

    // --- CORRECCIÓN DE LAS LÍNEAS FINAS ---
    // Si isContainer es falso, devuelve grosor 0 estricto.
    readonly property real effectiveStrokeWidth: {
        if (!root.effectiveShowBorder) return 0
        if (!root.isContainer || root.isBorderless) return 0
        return 1
    }

    visible: shouldBeVisible || opacity > 0.01
    opacity: shouldBeVisible ? 1 : 0
    Behavior on opacity { 
        enabled: enableAnimations
        NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } 
    }

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
        enabled: root.enableSizeAnimation && enableAnimations
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        enabled: root.enableSizeAnimation && enableAnimations
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }

    default property alias items: gridLayout.data

    Loader {
        id: backgroundLoader
        anchors.fill: parent
        active: root.isContainer && !root.isBorderless && (root.shouldBeVisible || root.opacity > 0)

        anchors.margins: root.bridgeMode ? 0 : (root.cornerIsFloat ? root.effectiveEdgeInset : 0)

        anchors.topMargin: root.bridgeMode ? 0
            : (root.cornerIsFloat ? root.effectiveEdgeInset
                : ((useHybridBg && !vertical && !isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset)))

        anchors.bottomMargin: root.bridgeMode ? 0
            : (root.cornerIsFloat ? root.effectiveEdgeInset
                : ((useHybridBg && !vertical && isBottom) ? 0 : (root.vertical ? 0 : root.effectiveEdgeInset)))

        anchors.leftMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)
        anchors.rightMargin: root.bridgeMode ? 0 : (root.vertical ? root.effectiveEdgeInset : 0)

        sourceComponent: {
            // 👇 LLAMADA A NUESTRO NUEVO COMPONENTE 👇
            if (root.isGlassLineEffect) return glassLineBackgroundComponent
            
            if (root.useLineBg) return lineBackgroundComponent
            if (root.useNotchBg) return notchBackgroundComponent
            return (root.useRectBg || root.cornerIsRect) ? rectBackgroundComponent : roundedBackgroundComponent
        }
    }

    // 👇 EL COMPONENTE QUE INYECTA EL EFECTO 👇
    Component {
        id: glassLineBackgroundComponent
        GlassLineBackground {
            isBottom: root.isBottom
            themeIsDark: root.themeIsDark
            effectiveShowBorder: root.effectiveShowBorder && root.isContainer && !root.isBorderless
            borderOpacity: root.borderOpacity
        }
    }

    Component {
        id: notchBackgroundComponent
        Item { /* ... Mantenido igual ... */ }
    }

    Component {
        id: rectBackgroundComponent
        Rectangle {
            anchors.fill: parent
            antialiasing: true
            radius: root.rectRadius
            color: root.effectiveFill
            
            // --- USAMOS EL STROKE CALCULADO ---
            border.width: root.effectiveStrokeWidth
            border.color: border.width > 0 ? root.effectiveBorderColor : "transparent"

            Rectangle {
                anchors.fill: parent
                // Desactiva el brillo si no hay contenedor
                visible: root.effectiveShowHighlight && root.isContainer && !root.isBorderless
                color: "transparent"
                radius: parent.radius
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
            antialiasing: true
            color: root.effectiveFill

            // --- USAMOS EL STROKE CALCULADO ---
            border.width: root.effectiveStrokeWidth
            border.color: border.width > 0 ? root.effectiveBorderColor : "transparent"

            topLeftRadius: root.finalRTL
            topRightRadius: root.finalRTR
            bottomLeftRadius: root.finalRBL
            bottomRightRadius: root.finalRBR

            Rectangle {
                anchors.fill: parent
                // Desactiva el brillo si no hay contenedor
                visible: root.effectiveShowHighlight && root.isContainer && !root.isBorderless
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
                color: Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity * 2) : Qt.rgba(0, 0, 0, 0.20)
                visible: root.effectiveShowBorder && root.isContainer && !root.isBorderless
            }
        }
    }

    Item {
        anchors.fill: backgroundLoader
        // --- PREVENCIÓN DE APLASTAMIENTO (Rect Mode) ---
        // Empuja los widgets 4px hacia abajo cuando el notch está pegado arriba
        anchors.topMargin: root.padding + (root.isNotch && !root.cornerIsFloat && !root.isBottom ? 4 : 0)
        anchors.bottomMargin: root.padding + (root.isNotch && !root.cornerIsFloat && root.isBottom ? 4 : 0)
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        clip: root.clipContent

        GridLayout {
            id: gridLayout
            anchors.centerIn: parent

            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: root.vertical ? 1 : -1
            rows: root.vertical ? -1 : 1

            columnSpacing: root.unifyInside ? 0 : root.spacing
            rowSpacing: root.unifyInside ? 0 : root.spacing

            Component.onCompleted: updateChildContainers()
            onChildrenChanged: updateChildContainers()

            function updateChildContainers() {
                for (let i = 0; i < gridLayout.children.length; i++) {
                    let c = gridLayout.data[i]
                    if (!c) continue

                    if (c.hasOwnProperty("isContainer"))
                        c.isContainer = !root.unifyChildChips

                    if (c.hasOwnProperty("forceNoContainer"))
                        c.forceNoContainer = root.unifyChildChips
                }
            }
        }
    }
}
