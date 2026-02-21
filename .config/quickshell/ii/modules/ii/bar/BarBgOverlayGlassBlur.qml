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
    property bool enableMask: true
    property bool enableRealBlur: true

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    // Valores de Blur 
    property real blurRadius: 64 
    property real blurSaturation: themeIsDark ? 1.40 : 1.60
    property real blurContrast: 1.05
    property real blurBrightness: themeIsDark ? 1.05 : 1.10
    property int blurDownsampleFactor: 2 

    // Ligeramente más opaco 
    property color iosTint: themeIsDark ? Qt.rgba(0.08, 0.08, 0.10, 0.45) : Qt.rgba(0.96, 0.96, 0.98, 0.50)

    readonly property int outerMargin: (cornerStyle === 1) ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0)) : 0
    readonly property int radiusPx: (cornerStyle === 1) ? (Appearance.rounding.windowRounding ?? 18) : 0

    default property alias content: contentContainer.data

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: root.radiusPx
        antialiasing: true
        color: root.showSolidBackground ? root.backgroundColor : "transparent"
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }
    }

    Loader {
        id: blurEngineLoader
        anchors.fill: bg
        active: root.useGlassMode && !root.showSolidBackground && root.enableRealBlur
        sourceComponent: Component {
            Item {
                ShaderEffectSource {
                    id: backdropSource
                    anchors.fill: parent
                    live: true
                    recursive: false 
                    smooth: true
                    sourceItem: root.parent
                    readonly property int _ds: Math.max(1, Math.round(root.blurDownsampleFactor))
                    textureSize: Qt.size(Math.max(1, Math.round(width / _ds)), Math.max(1, Math.round(height / _ds)))
                }
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: root.blurRadius
                        blurMax: 64
                        saturation: root.blurSaturation
                        contrast: root.blurContrast
                        brightness: root.blurBrightness
                        maskEnabled: true
                        maskSource: bg
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                    ShaderEffectSource {
                        anchors.fill: parent
                        live: backdropSource.live
                        recursive: backdropSource.recursive
                        smooth: backdropSource.smooth
                        sourceItem: backdropSource.sourceItem
                        textureSize: backdropSource.textureSize
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: bg
        visible: root.useGlassMode && !root.showSolidBackground
        clip: true
        // Tinta base
        Rectangle { anchors.fill: parent; radius: bg.radius; antialiasing: true; color: root.iosTint }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }

    layer.enabled: root.enableMask
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: bg
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
