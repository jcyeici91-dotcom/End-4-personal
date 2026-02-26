import QtQuick
import QtQuick.Effects
import qs
import qs.modules.common

Item {
    id: root

    property string position: "top"
    required property bool useGlassMode
    required property bool showSolidBackground
    required property color backgroundColor
    required property int cornerStyle
    property int basePadding: 4

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.6 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property int outerMargin: (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    readonly property int radiusPx: (cornerStyle === 1)
        ? (Appearance.rounding.windowRounding ?? 18)
        : 0

    default property alias content: contentContainer.data

    Rectangle {
        id: solidBg
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: root.radiusPx
        visible: root.showSolidBackground
        color: root.backgroundColor
        antialiasing: true
    }

    ShaderEffectSource {
        id: blurSource
        anchors.fill: parent
        anchors.margins: root.outerMargin
        sourceItem: null
        live: true
        visible: false
        recursive: true
    }

    MultiEffect {
        id: glassEffect
        anchors.fill: parent
        anchors.margins: root.outerMargin
        source: blurSource
        visible: root.useGlassMode && !root.showSolidBackground

        blurEnabled: true
        blurMax: 64
        blur: 0.8

        brightness: themeIsDark ? -0.05 : 0.05
        saturation: 1.05

        colorization: 0.25
        colorizationColor: themeIsDark
            ? Qt.rgba(0.08, 0.08, 0.1, 1.0)
            : Qt.rgba(1.0, 1.0, 1.0, 1.0)

        opacity: 0.9

        Rectangle {
            anchors.fill: parent
            radius: root.radiusPx
            border.width: 1
            border.color: themeIsDark
                ? Qt.rgba(1,1,1,0.08)
                : Qt.rgba(0,0,0,0.08)
            color: "transparent"
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }
}
