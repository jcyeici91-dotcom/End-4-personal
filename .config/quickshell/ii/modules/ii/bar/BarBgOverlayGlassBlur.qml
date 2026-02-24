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

    // Blur real usando screencopy (grim)
    property bool enableRealBlur: true
    property bool useScreenCaptureBlur: true
    property int captureIntervalMs: 140
    property string captureOutputPath: "/tmp/quickshell_sidebar_backdrop.png"

    // ==========================
    // TUNING (expuesto)
    // ==========================
    // Blur tuning
    property real blurRadius: 56
    property real blurSaturation: themeIsDark ? 1.55 : 1.65
    property real blurContrast: 1.08
    property real blurBrightness: themeIsDark ? 1.12 : 1.10

    // Tint tuning (CLAVE para que no se vea opaco)
    property color tintColor: themeIsDark
        ? Qt.rgba(0.08, 0.08, 0.10, 1.0)
        : Qt.rgba(0.96, 0.96, 0.98, 1.0)

    // Baja opacidad por defecto (antes era demasiado alta)
    property real tintOpacity: themeIsDark ? 0.22 : 0.18

    // Si quieres apagar tint desde fuera
    property bool tintEnabled: true

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property int outerMargin: (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0
    readonly property int radiusPx: (cornerStyle === 1)
        ? (Appearance.rounding.windowRounding ?? 18)
        : 0

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

    // =========
    // BLUR REAL (captura real con grim -> PNG -> Image -> MultiEffect blur)
    // =========
    Item {
        id: realBlurLayer
        anchors.fill: bg
        visible: root.useGlassMode
                 && !root.showSolidBackground
                 && root.enableRealBlur
                 && root.useScreenCaptureBlur
        clip: true

        RealScreenBackdrop {
            id: cap
            anchors.fill: parent
            enabled: realBlurLayer.visible
            intervalMs: root.captureIntervalMs
            outputPath: root.captureOutputPath
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

            Image {
                anchors.fill: parent
                source: cap.imageItem.source
                asynchronous: true
                cache: false
                smooth: true
                fillMode: Image.Stretch
            }
        }
    }

    // =========
    // TINT (antes era el causante del look “opaco”)
    // =========
    Item {
        anchors.fill: bg
        visible: root.useGlassMode && !root.showSolidBackground && root.tintEnabled
        clip: true
        Rectangle {
            anchors.fill: parent
            radius: bg.radius
            antialiasing: true
            color: Qt.rgba(root.tintColor.r, root.tintColor.g, root.tintColor.b, root.tintOpacity)
        }
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

