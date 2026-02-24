import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property bool vertical: false

    property int padding: unifyInside ? 0 : 6
    property int edgeInset: 2

readonly property bool useUnifiedLayout:
    root.bgIsCrystal && (root.useHybridBg || root.useLineBg)

property int spacing: useUnifiedLayout ? 0 : 4

property bool unifyInside: useUnifiedLayout
property bool unifyChildChips: useUnifiedLayout

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

    property bool bridgeMode: false

    property bool enableSizeAnimation: false
    property int sizeAnimDuration: 85

    property int notchWidth: 140
    property int notchDepth: 16
    property int notchInnerRadius: 14
    property int notchOuterRadius: 22

    readonly property int styleIntFromConfig: Config.options?.bar?.barBackgroundStyle ?? 1
    readonly property bool bgIsCrystal: styleIntFromConfig === 3

    readonly property string cornerStyle: (Config.options?.bar?.cornerStyle ?? "hug")
    readonly property bool cornerIsFloat: cornerStyle === "float"
    readonly property bool cornerIsRect: cornerStyle === "rect"

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property bool isBorderless: (Config.options?.bar?.borderless ?? false)

    readonly property string groupBackgroundStyle: (Config.options?.bar?.groupBackgroundStyle ?? "pills")

    readonly property bool usePillsBg: (groupBackgroundStyle === "pills" || groupBackgroundStyle === "rounded" || groupBackgroundStyle === "")
    readonly property bool useRectBg: groupBackgroundStyle === "rect"
    readonly property bool useHybridBg: groupBackgroundStyle === "hybrid"
    readonly property bool useLineBg: groupBackgroundStyle === "line"
    readonly property bool useNotchBg: groupBackgroundStyle === "notch" && !vertical

    readonly property bool isBottom: (Config.options?.bar?.bottom ?? false)

    readonly property bool hasContent: gridLayout.visibleChildren.length > 0
    readonly property bool shouldBeVisible: autoHide ? hasContent : true

    readonly property bool effectiveShowBorder: (!bridgeMode) && showBorder
    readonly property bool effectiveShowHighlight: (!bridgeMode) && showHighlight

    readonly property int effectiveEdgeInset: bridgeMode ? 0 : (cornerIsFloat ? Math.max(2, edgeInset) : edgeInset)

    //prueba
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
        return pillRadius
    }

    readonly property bool allowFlatten: useHybridBg && !cornerIsFloat
    readonly property bool flattenTop: allowFlatten && !vertical && !isBottom
    readonly property bool flattenBottom: allowFlatten && !vertical && isBottom
    readonly property bool allowAttach: allowFlatten && !cornerIsFloat

    readonly property real finalRTL: {
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenTop || (allowAttach && attachScreenLeft)) return 0
        return baseRadius
    }
    readonly property real finalRTR: {
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenTop || (allowAttach && attachScreenRight)) return 0
        return baseRadius
    }
    readonly property real finalRBL: {
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenBottom || (allowAttach && attachScreenLeft)) return 0
        return baseRadius
    }
    readonly property real finalRBR: {
        if (useLineBg) return 0
        if (useRectBg || cornerIsRect) return baseRadius
        if (!useHybridBg) return baseRadius
        if (flattenBottom || (allowAttach && attachScreenRight)) return 0
        return baseRadius
    }

readonly property color effectiveFill: {
    if (!root.isContainer || root.isBorderless)
        return "transparent"

    if (root.bgIsCrystal) {
        return Qt.rgba(
            root.colBackground.r,
            root.colBackground.g,
            root.colBackground.b,
            root.themeIsDark ? 0.035 : 0.065   //  mucho más limpio
        )
    }

    return root.colBackground
}
    readonly property color effectiveBorderColor: {
        if (Appearance.colors.isDark) return Qt.rgba(1, 1, 1, root.borderOpacity)
        return Qt.rgba(0, 0, 0, 0.14)
    }

    readonly property color crystalRimOuterLight: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.34)
    readonly property color crystalRimOuterDark: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.58) : Qt.rgba(0, 0, 0, 0.22)
    readonly property color crystalRimInnerLight: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.62)
    readonly property color crystalRimInnerDark: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(0, 0, 0, 0.10)

    readonly property real effectiveStrokeWidth: {
        if (!root.effectiveShowBorder) return 0
        if (!root.isContainer || root.isBorderless) return 0
        return 1
    }

    visible: shouldBeVisible || opacity > 0.01
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
            if (root.useLineBg) return lineBackgroundComponent
            if (root.useNotchBg) return notchBackgroundComponent
            return (root.useRectBg || root.cornerIsRect) ? rectBackgroundComponent : roundedBackgroundComponent
        }
    }

    Component {
        id: notchBackgroundComponent

        Item {
            anchors.fill: parent

            readonly property real w: width
            readonly property real h: height

            readonly property real outerR: Math.max(0, Math.min(root.notchOuterRadius, Math.min(w, h) / 2))
            readonly property real depth: Math.max(0, Math.min(root.notchDepth, h - 2))
            readonly property real notchW: Math.max(0, Math.min(root.notchWidth, w - outerR * 2 - 6))
            readonly property real innerR: Math.max(0, Math.min(root.notchInnerRadius, depth))

            readonly property real cx: w / 2
            readonly property real leftNotchX: cx - notchW / 2
            readonly property real rightNotchX: cx + notchW / 2

            Shape {
                anchors.fill: parent
                antialiasing: true

                transform: [
                    Scale {
                        xScale: 1
                        yScale: root.isBottom ? -1 : 1
                        origin.x: width / 2
                        origin.y: height / 2
                    }
                ]

                ShapePath {
                    fillColor: root.effectiveFill
                    strokeColor: (root.effectiveStrokeWidth > 0)
                                 ? (root.bgIsCrystal ? root.crystalRimOuterDark : root.effectiveBorderColor)
                                 : "transparent"
                    strokeWidth: root.effectiveStrokeWidth
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: outerR
                    startY: 0

                    PathLine { x: leftNotchX - innerR; y: 0 }
                    PathArc { x: leftNotchX; y: innerR; radiusX: innerR; radiusY: innerR; direction: PathArc.Clockwise }
                    PathLine { x: leftNotchX; y: depth - innerR }
                    PathArc { x: leftNotchX + innerR; y: depth; radiusX: innerR; radiusY: innerR; direction: PathArc.Counterclockwise }

                    PathLine { x: rightNotchX - innerR; y: depth }

                    PathArc { x: rightNotchX; y: depth - innerR; radiusX: innerR; radiusY: innerR; direction: PathArc.Counterclockwise }
                    PathLine { x: rightNotchX; y: innerR }
                    PathArc { x: rightNotchX + innerR; y: 0; radiusX: innerR; radiusY: innerR; direction: PathArc.Clockwise }

                    PathLine { x: w - outerR; y: 0 }

                    PathArc { x: w; y: outerR; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: w; y: h - outerR }
                    PathArc { x: w - outerR; y: h; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: outerR; y: h }
                    PathArc { x: 0; y: h - outerR; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: 0; y: outerR }
                    PathArc { x: outerR; y: 0; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                }
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                visible: root.bgIsCrystal && root.effectiveStrokeWidth > 0

                transform: [
                    Scale {
                        xScale: 0.985
                        yScale: root.isBottom ? -0.985 : 0.985
                        origin.x: width / 2
                        origin.y: height / 2
                    }
                ]

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.crystalRimInnerLight
                    strokeWidth: 1
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: outerR
                    startY: 0

                    PathLine { x: leftNotchX - innerR; y: 0 }
                    PathArc { x: leftNotchX; y: innerR; radiusX: innerR; radiusY: innerR; direction: PathArc.Clockwise }
                    PathLine { x: leftNotchX; y: depth - innerR }
                    PathArc { x: leftNotchX + innerR; y: depth; radiusX: innerR; radiusY: innerR; direction: PathArc.Counterclockwise }

                    PathLine { x: rightNotchX - innerR; y: depth }

                    PathArc { x: rightNotchX; y: depth - innerR; radiusX: innerR; radiusY: innerR; direction: PathArc.Counterclockwise }
                    PathLine { x: rightNotchX; y: innerR }
                    PathArc { x: rightNotchX + innerR; y: 0; radiusX: innerR; radiusY: innerR; direction: PathArc.Clockwise }

                    PathLine { x: w - outerR; y: 0 }

                    PathArc { x: w; y: outerR; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: w; y: h - outerR }
                    PathArc { x: w - outerR; y: h; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: outerR; y: h }
                    PathArc { x: 0; y: h - outerR; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                    PathLine { x: 0; y: outerR }
                    PathArc { x: outerR; y: 0; radiusX: outerR; radiusY: outerR; direction: PathArc.Clockwise }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: root.isBottom ? undefined : parent.top
                anchors.bottom: root.isBottom ? parent.bottom : undefined
                height: 1
                visible: root.effectiveShowHighlight
                color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.34 : 0.70)
                opacity: root.bgIsCrystal ? 0.95 : 0.55
            }
        }
    }

    Component {
        id: rectBackgroundComponent

        Rectangle {
            anchors.fill: parent

            antialiasing: true
            layer.enabled: root.bgIsCrystal && !root.bridgeMode && root.opacity > 0
            layer.smooth: true
            layer.samples: 4

            radius: root.rectRadius

            readonly property bool showCrystal: root.bgIsCrystal
            readonly property bool showSolid: !root.bgIsCrystal

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.bgIsCrystal
                           ? Qt.rgba(1, 1, 1, root.themeIsDark ? 0.04 : 0.12)
                           : root.effectiveFill
                }
                GradientStop {
                    position: 1
                    color: root.effectiveFill
                }
            }

            color: root.bgIsCrystal ? "transparent" : root.effectiveFill

            border.width: (showSolid && root.effectiveShowBorder) ? 1 : 0
            border.color: border.width > 0 ? root.effectiveBorderColor : "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: parent.showCrystal && root.effectiveStrokeWidth > 0

                color: "transparent"
                border.width: 1
                border.color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: root.themeIsDark
                                  ? Qt.rgba(1, 1, 1, 0.35)
                                  : Qt.rgba(1, 1, 1, 0.75)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Math.max(0, parent.radius - 1)
                    color: "transparent"
                    border.width: 1
                    border.color: root.themeIsDark
                                  ? Qt.rgba(0, 0, 0, 0.20)
                                  : Qt.rgba(0, 0, 0, 0.10)
                }
    }

           
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: parent.radius / 1.35
                anchors.rightMargin: parent.radius / 1.35
                anchors.topMargin: 1
                height: 1
                visible: parent.showCrystal && root.effectiveShowHighlight
                color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.25 : 0.55)
            }

            Rectangle {
                anchors.fill: parent
                visible: parent.showSolid && root.effectiveShowHighlight
                color: "transparent"
                radius: parent.radius

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(
                            1, 1, 1,
                            Appearance.colors.isDark
                                ? root.highlightOpacity
                                : root.highlightOpacity * 0.6
                        )
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0.0)
                    }
                }
            }
        }
    }

    Component {
        id: roundedBackgroundComponent

        Rectangle {
            anchors.fill: parent

            antialiasing: true
            layer.enabled: root.bgIsCrystal && !root.bridgeMode && root.opacity > 0
            layer.smooth: true
            layer.samples: 4

            readonly property bool showCrystal: root.bgIsCrystal
            readonly property bool showSolid: !root.bgIsCrystal

           gradient: Gradient {
    GradientStop {
        position: 0
        color: root.bgIsCrystal
               ? Qt.rgba(1, 1, 1, root.themeIsDark ? 0.06 : 0.18)
               : root.effectiveFill
    }
    GradientStop {
        position: 1
        color: root.effectiveFill
    }
}

            color: root.bgIsCrystal ? "transparent" : root.effectiveFill

            border.width: (showSolid && root.effectiveShowBorder) ? 1 : 0
            border.color: border.width > 0 ? root.effectiveBorderColor : "transparent"

            topLeftRadius: root.finalRTL
            topRightRadius: root.finalRTR
            bottomLeftRadius: root.finalRBL
            bottomRightRadius: root.finalRBR

            Rectangle {
                anchors.fill: parent
                visible: parent.showCrystal && root.effectiveStrokeWidth > 0

                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius

                color: "transparent"
                border.width: 1
                border.color: "transparent"

                Rectangle {
                    anchors.fill: parent

                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    color: "transparent"
                    border.width: 1
                    border.color: root.themeIsDark
                                  ? Qt.rgba(1, 1, 1, 0.35)
                                  : Qt.rgba(1, 1, 1, 0.75)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1

                    topLeftRadius: Math.max(0, parent.topLeftRadius - 1)
                    topRightRadius: Math.max(0, parent.topRightRadius - 1)
                    bottomLeftRadius: Math.max(0, parent.bottomLeftRadius - 1)
                    bottomRightRadius: Math.max(0, parent.bottomRightRadius - 1)

                    color: "transparent"
                    border.width: 1
                    border.color: root.themeIsDark
                                  ? Qt.rgba(0, 0, 0, 0.25)
                                  : Qt.rgba(0, 0, 0, 0.12)
                }

               }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: parent.showCrystal && root.effectiveShowHighlight
                anchors.leftMargin: parent.topLeftRadius > 0 ? parent.topLeftRadius / 1.30 : 1
                anchors.rightMargin: parent.topRightRadius > 0 ? parent.topRightRadius / 1.30 : 1
                anchors.topMargin: 1
                height: 1
                color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.35 : 0.75)
            }

            Rectangle {
                anchors.fill: parent
                visible: parent.showSolid && root.effectiveShowHighlight
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
                color: {
                    if (root.bgIsCrystal)
                        return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(0, 0, 0, 0.26)
                    return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity * 2) : Qt.rgba(0, 0, 0, 0.20)
                }
                visible: root.effectiveShowBorder && root.isContainer && !root.isBorderless
            }
        }
    }

    Item {
        anchors.fill: backgroundLoader
        anchors.margins: root.padding
        clip: root.clipContent

        GridLayout {
            id: gridLayout
            anchors.centerIn: parent

            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: root.vertical ? 1 : -1
            rows: root.vertical ? -1 : 1

            columnSpacing: root.unifyInside ? 0 : root.spacing
            rowSpacing: root.unifyInside ? 0 : root.spacing

            // Ajuste hijos NO dibujen cápsulas cuando es cristal unificado
          Component.onCompleted: updateChildContainers()
onVisibleChildrenChanged: updateChildContainers()

function updateChildContainers() {
    for (let i = 0; i < gridLayout.data.length; i++) {
        let c = gridLayout.data[i]
        if (!c)
            continue

        if (c.hasOwnProperty("isContainer"))
            c.isContainer = !root.unifyChildChips

        if (c.hasOwnProperty("forceNoContainer"))
            c.forceNoContainer = root.unifyChildChips
    }
}
         }
    }
}
    

