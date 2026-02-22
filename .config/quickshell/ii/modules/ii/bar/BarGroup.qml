import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool vertical: false
    property int padding: 6
    property int spacing: theme.bgIsCrystal ? 0 : 4
    property int edgeInset: 2

    // En modo Cristal, unificados.
    property bool unifyInside: theme.bgIsCrystal ? true : false
    property bool unifyChildChips: theme.bgIsCrystal ? true : false

    // Props requeridas
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // Colores/Bordes
    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property bool showBorder: true
    property real borderOpacity: 0.08

    // Auto-hide
    property bool autoHide: true

    // Estética extra
    property bool showHighlight: true
    property real highlightOpacity: 0.06
    property bool clipContent: true

    property bool isContainer: true

    // “float/hybrid” attachments
    property bool attachScreenLeft: false
    property bool attachScreenRight: false

    property bool bridgeMode: false

    // Animación tamaño
    property bool enableSizeAnimation: false
    property int sizeAnimDuration: 85

    // ===== Theme resolver extracted =====
    BarThemeResolver {
        id: theme
        options: Config.options
        layer0: Appearance.colors.colLayer0
    }

    // Map a cornerStyle unificado: hug/float/rect/line
    readonly property string cornerStyle: {
        if (theme.groupBackgroundStyle === "rect") return "rect";
        if (theme.groupBackgroundStyle === "line") return "line";
        if (theme.groupBackgroundStyle === "hybrid") return "float";
        return "hug";
    }

    readonly property bool effectiveShowBorder: (!bridgeMode) && showBorder
    readonly property bool effectiveShowHighlight: (!bridgeMode) && showHighlight
    readonly property int effectiveEdgeInset: bridgeMode ? 0 : edgeInset

    readonly property real bgSize: Math.min(width, height)
    readonly property real pillRadius: Math.max(0, bgSize / 2)

    // ===== Corner style extracted (hug/float/rect/line) =====
    BarCornerStyle {
        id: corners
        vertical: root.vertical
        isBottom: theme.isBottom
        cornerStyle: root.cornerStyle

        isBorderless: theme.isBorderless
        attachScreenLeft: root.attachScreenLeft
        attachScreenRight: root.attachScreenRight

        startRadius: root.startRadius
        endRadius: root.endRadius

        pillRadius: root.pillRadius
        rectRadius: 4
    }

    // ===== Visibility/auto-hide extracted =====
    BarVisibilityLogic {
        id: vis
        autoHide: root.autoHide
        visibleChildrenCount: gridLayout.visibleChildren.length
    }

    // ===== Implicit sizes extracted =====
    BarImplicitSizeLogic {
        id: sz
        shouldBeVisible: vis.shouldBeVisible
        vertical: root.vertical
        padding: root.padding
        effectiveEdgeInset: root.effectiveEdgeInset
        contentImplicitWidth: gridLayout.implicitWidth
        contentImplicitHeight: gridLayout.implicitHeight
    }

    // ===== Background insets extracted (NUEVO) =====
    BarBackgroundInsetsLogic {
        id: insets
        bridgeMode: root.bridgeMode
        vertical: root.vertical
        isBottom: theme.isBottom
        cornerStyle: root.cornerStyle
        effectiveEdgeInset: root.effectiveEdgeInset
    }

    // Geometría / visibilidad
    visible: vis.shouldBeVisible || opacity > 0
    opacity: vis.shouldBeVisible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

    implicitWidth: sz.implicitWidth
    implicitHeight: sz.implicitHeight

    Behavior on implicitWidth {
        enabled: root.enableSizeAnimation
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        enabled: root.enableSizeAnimation
        NumberAnimation { duration: root.sizeAnimDuration; easing.type: Easing.OutCubic }
    }

    default property alias items: gridLayout.data

    // Background
    Loader {
        id: backgroundLoader
        anchors.fill: parent

        // (REEMPLAZO) márgenes desde BarBackgroundInsetsLogic
        anchors.topMargin: insets.topMargin
        anchors.bottomMargin: insets.bottomMargin
        anchors.leftMargin: insets.leftMargin
        anchors.rightMargin: insets.rightMargin

        sourceComponent: (root.cornerStyle === "line") ? lineBackgroundComponent : backgroundComponent
    }

    Component {
        id: lineBackgroundComponent
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                width: parent.width
                height: 2
                anchors.bottom: theme.isBottom ? undefined : parent.bottom
                anchors.top: theme.isBottom ? parent.top : undefined
                color: {
                    if (theme.bgIsCrystal)
                        return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3)
                    return Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity * 2) : Qt.rgba(0, 0, 0, 0.2)
                }
                visible: root.effectiveShowBorder && root.isContainer
            }
        }
    }

    Component {
        id: backgroundComponent

        HybridBackground {
            bridgeMode: root.bridgeMode
            isContainer: root.isContainer
            isBorderless: theme.isBorderless

            bgIsCrystal: theme.bgIsCrystal
            themeIsDark: theme.themeIsDark
            effectiveShowBorder: root.effectiveShowBorder
            effectiveShowHighlight: root.effectiveShowHighlight

            colBackground: root.colBackground
            borderOpacity: root.borderOpacity
            highlightOpacity: root.highlightOpacity

            useRectBg: (root.cornerStyle === "rect")
            rectRadius: corners.baseRadius

            rtl: corners.rtl
            rtr: corners.rtr
            rbl: corners.rbl
            rbr: corners.rbr
        }
    }

    // Content
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

            columnSpacing: root.unifyInside ? 0 : root.spacing
            rowSpacing: root.unifyInside ? 0 : root.spacing
        }
    }
}

