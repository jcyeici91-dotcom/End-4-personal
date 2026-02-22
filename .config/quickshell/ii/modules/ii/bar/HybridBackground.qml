// ~/.config/quickshell/ii/modules/ii/bar/HybridBackground.qml
import qs.modules.common
import QtQuick

Item {
    id: root
    anchors.fill: parent

    // Entradas
    property bool bridgeMode: false
    property bool isContainer: true
    property bool isBorderless: false

    property bool bgIsCrystal: false
    property bool themeIsDark: false
    property bool effectiveShowBorder: true
    property bool effectiveShowHighlight: true

    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property real borderOpacity: 0.08
    property real highlightOpacity: 0.06

    // Geometría (radios ya calculados afuera)
    property bool useRectBg: false
    // para rect
    property real rectRadius: 4

    // para rounded/hybrid
    property real rtl: 16
    property real rtr: 16
    property real rbl: 16
    property real rbr: 16

    // ===== Render =====

    // RECT
    Rectangle {
        id: rectBg
        anchors.fill: parent
        visible: root.useRectBg
        antialiasing: !root.bridgeMode
        radius: root.rectRadius

        readonly property bool showCrystal: root.bgIsCrystal && root.isContainer && !root.isBorderless
        readonly property bool showSolid: !root.bgIsCrystal && root.isContainer && !root.isBorderless

        color: {
            if (!root.isContainer || root.isBorderless) return "transparent"
            if (root.bgIsCrystal)
                return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b,
                               Appearance.colors.isDark ? 0.10 : 0.15)
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

    // ROUNDED / HYBRID (mismo renderer; el “hybrid” ya viene en los radios)
    Rectangle {
        id: roundedBg
        anchors.fill: parent
        visible: !root.useRectBg
        antialiasing: !root.bridgeMode

        readonly property bool showCrystal: root.bgIsCrystal && root.isContainer && !root.isBorderless
        readonly property bool showSolid: !root.bgIsCrystal && root.isContainer && !root.isBorderless

        color: {
            if (!root.isContainer || root.isBorderless) return "transparent"
            if (root.bgIsCrystal)
                return Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b,
                               Appearance.colors.isDark ? 0.10 : 0.15)
            return root.colBackground
        }

        border.width: (showSolid && root.effectiveShowBorder) ? 1 : 0
        border.color: border.width > 0
            ? (Appearance.colors.isDark ? Qt.rgba(1, 1, 1, root.borderOpacity) : Qt.rgba(0, 0, 0, 0.14))
            : "transparent"

        topLeftRadius: root.rtl
        topRightRadius: root.rtr
        bottomLeftRadius: root.rbl
        bottomRightRadius: root.rbr

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
