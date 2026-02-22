import qs.modules.common
import QtQuick

QtObject {
    id: engine

     // Inputs comunes (para que el motor sea el único entrypoint)

    // Config completo
    property var options: null

    // A menudo esto vive en Appearance, pero lo dejamos como input para testear/override
    property color layer0: Appearance.colors.colLayer0

    // Inputs para “corner”
    property bool vertical: false
    property bool isBottom: false

    // cornerStyle: "hug" | "float" | "rect" | "line"
    property string cornerStyle: "hug"

    // flags generales
    // (si no los seteas, se toma el valor del Config en "resolved...")
    property bool isBorderless: false
    property bool attachScreenLeft: false
    property bool attachScreenRight: false

    // radios base (si borderless )
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // geometría para hug (píldora)
    property real pillRadius: 9999

    // geometría para rect
    property real rectRadius: 4

    // Inputs para “visibility”
    property bool autoHide: true
    property int visibleChildrenCount: 0

    // Inputs para “implicit size”
    property int padding: 6
    property int effectiveEdgeInset: 2

    // Estos los pasa BarGroup desde el layout
    property real contentImplicitWidth: 0
    property real contentImplicitHeight: 0

    // Inputs para “background insets”
    property bool bridgeMode: false

     // 1) THEME RESOLVER (BarThemeResolver.qml) 
      property QtObject theme: QtObject {
        id: t

        // Inputs (config)
        property var options: engine.options   // pásale: Config.options
        property color layer0: engine.layer0

        // Helpers
        function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
        function _isDark(c) { return _lin(c) < 0.65 }

        // Outputs
        readonly property int barBackgroundStyleInt: options?.bar?.barBackgroundStyle ?? 1
        readonly property bool bgIsCrystal: barBackgroundStyleInt === 3

        readonly property bool themeIsDark: _isDark(layer0)

        // opcional pero útil (centraliza)
        readonly property bool isBorderless: options?.bar?.borderless ?? false

        // tu selector original (lo dejamos aquí para que BarGroup no piense de más)
        readonly property string groupBackgroundStyle: options?.bar?.groupBackgroundStyle ?? "rounded"
        readonly property bool isBottom: options?.bar?.bottom ?? false
    }

    // 2) CORNER STYLE (BarCornerStyle.qml) 
    property QtObject corners: QtObject {
        id: s

        // Inputs
        property bool vertical: engine.vertical
        property bool isBottom: engine.isBottom
        property string cornerStyle: engine.cornerStyle

        // flags generales
        // Nota: aquí usamos el "resolvedIsBorderless" para que respete Config si no overrideas.
        property bool isBorderless: engine.resolvedIsBorderless
        property bool attachScreenLeft: engine.attachScreenLeft
        property bool attachScreenRight: engine.attachScreenRight

        // radios base
        property real startRadius: engine.startRadius
        property real endRadius: engine.endRadius

        // geometría
        property real pillRadius: engine.pillRadius
        property real rectRadius: engine.rectRadius

        // ======= Derived booleans =======
        readonly property bool useRect: cornerStyle === "rect"
        readonly property bool useLine: cornerStyle === "line"
        readonly property bool useFloat: cornerStyle === "float"
        readonly property bool useHug: cornerStyle === "hug" || cornerStyle === "rounded" // compat

        // “base radius”
        readonly property real baseRadius: {
            if (useLine) return 0;
            if (useRect) return rectRadius;
            if (isBorderless) return startRadius;
            // hug/float por defecto usan pillRadius
            return pillRadius;
        }

        // Float = hybrid flattening
        readonly property bool flattenTop: useFloat && !vertical && !isBottom
        readonly property bool flattenBottom: useFloat && !vertical && isBottom

        // Output radii
        readonly property real rtl: {
            if (useRect) return baseRadius;
            if (useLine) return 0;
            if (!useFloat) return baseRadius;           // hug
            if (flattenTop || attachScreenLeft) return 0;
            return baseRadius;
        }

        readonly property real rtr: {
            if (useRect) return baseRadius;
            if (useLine) return 0;
            if (!useFloat) return baseRadius;           // hug
            if (flattenTop || attachScreenRight) return 0;
            return baseRadius;
        }

        readonly property real rbl: {
            if (useRect) return baseRadius;
            if (useLine) return 0;
            if (!useFloat) return baseRadius;           // hug
            if (flattenBottom || attachScreenLeft) return 0;
            return baseRadius;
        }

        readonly property real rbr: {
            if (useRect) return baseRadius;
            if (useLine) return 0;
            if (!useFloat) return baseRadius;           // hug
            if (flattenBottom || attachScreenRight) return 0;
            return baseRadius;
        }
    }

      // 3) VISIBILITY (BarVisibilityLogic.qml) 
    property QtObject visibility: QtObject {
        id: v

        // Inputs
        property bool autoHide: engine.autoHide
        property int visibleChildrenCount: engine.visibleChildrenCount

        // Outputs
        readonly property bool hasContent: visibleChildrenCount > 0
        readonly property bool shouldBeVisible: autoHide ? hasContent : true
    }

       // 4) IMPLICIT SIZE (BarImplicitSizeLogic.qml) 
       property QtObject sizeLogic: QtObject {
        id: sizeLogic

        // Inputs
        property bool shouldBeVisible: v.shouldBeVisible
        property bool vertical: engine.vertical

        property int padding: engine.padding
        property int effectiveEdgeInset: engine.effectiveEdgeInset

        // layout
        property real contentImplicitWidth: engine.contentImplicitWidth
        property real contentImplicitHeight: engine.contentImplicitHeight

        // Outputs
        readonly property real implicitWidth: shouldBeVisible
            ? (vertical
                ? (Appearance.sizes.baseVerticalBarWidth + effectiveEdgeInset * 2)
                : (contentImplicitWidth + (padding * 2) + effectiveEdgeInset * 2))
            : 0

        readonly property real implicitHeight: shouldBeVisible
            ? (vertical
                ? (contentImplicitHeight + (padding * 2) + effectiveEdgeInset * 2)
                : (Appearance.sizes.baseBarHeight + effectiveEdgeInset * 2))
            : 0
    }

      // 5) BACKGROUND INSETS (BarBackgroundInsetsLogic.qml) 
      property QtObject insets: QtObject {
        id: i

        // Inputs
        property bool bridgeMode: engine.bridgeMode
        property bool vertical: engine.vertical
        property bool isBottom: engine.isBottom
        property string cornerStyle: engine.cornerStyle

        property int effectiveEdgeInset: engine.effectiveEdgeInset

        // Outputs
        readonly property int topMargin: {
            if (bridgeMode) return 0;
            if (cornerStyle === "float" && !vertical && !isBottom) return 0;
            if (vertical) return 0;
            return effectiveEdgeInset;
        }

        readonly property int bottomMargin: {
            if (bridgeMode) return 0;
            if (cornerStyle === "float" && !vertical && isBottom) return 0;
            if (vertical) return 0;
            return effectiveEdgeInset;
        }

        readonly property int leftMargin: {
            if (bridgeMode) return 0;
            if (!vertical) return 0;
            return effectiveEdgeInset;
        }

        readonly property int rightMargin: {
            if (bridgeMode) return 0;
            if (!vertical) return 0;
            return effectiveEdgeInset;
        }
    }

    // Resolved helpers (para que engine se use “directo”)

    // Si no overrideas isBorderless en el grupo, toma Config
    readonly property bool resolvedIsBorderless: (engine.isBorderless === true) ? true : theme.isBorderless

    // Convenience exports (para usar engine.xxx sin entrar a sub-objetos)
      // theme exports
    readonly property int barBackgroundStyleInt: theme.barBackgroundStyleInt
    readonly property bool bgIsCrystal: theme.bgIsCrystal
    readonly property bool themeIsDark: theme.themeIsDark
    readonly property bool isBorderlessEffective: resolvedIsBorderless

    readonly property string groupBackgroundStyle: theme.groupBackgroundStyle

    // Nota: aquí exponemos un "isBottom" consistente: el input del engine.
    // Si  siempre venga del Config, no pase engine.isBottom desde BarGroup.
    readonly property bool isBottomValue: engine.isBottom

    // corner exports
    readonly property bool useRect: corners.useRect
    readonly property bool useLine: corners.useLine
    readonly property bool useFloat: corners.useFloat
    readonly property bool useHug: corners.useHug

    readonly property real baseRadius: corners.baseRadius
    readonly property bool flattenTop: corners.flattenTop
    readonly property bool flattenBottom: corners.flattenBottom

    readonly property real rtl: corners.rtl
    readonly property real rtr: corners.rtr
    readonly property real rbl: corners.rbl
    readonly property real rbr: corners.rbr

    // visibility exports
    readonly property bool hasContent: visibility.hasContent
    readonly property bool shouldBeVisible: visibility.shouldBeVisible

    // implicit size exports
    readonly property real implicitWidth: sizeLogic.implicitWidth
    readonly property real implicitHeight: sizeLogic.implicitHeight

    // insets exports
    readonly property int topMargin: insets.topMargin
    readonly property int bottomMargin: insets.bottomMargin
    readonly property int leftMargin: insets.leftMargin
    readonly property int rightMargin: insets.rightMargin
}

