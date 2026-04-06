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

    property int customMargin: -1
    property int customRadius: -1

    property int basePadding: 8
    property real blurAmount: 0.88
    property real tintIntensity: 0.12
    property real noiseOpacity: 0.03
    property real iridescenceStrength: 0.05

    readonly property bool themeIsDark: {
        var c = Appearance.colors.colLayer0
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) < 0.65
    }

    readonly property int outerMargin: customMargin >= 0 ? customMargin : (cornerStyle === 1 ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0)) : 0)

    readonly property int radiusPx: customRadius >= 0 ? customRadius : (cornerStyle === 1 ? (Appearance.rounding.windowRounding ?? 18) : 0)

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
        live: true
        visible: false
        smooth: true
    }

    MultiEffect {
        id: glassEffect
        anchors.fill: parent
        anchors.margins: root.outerMargin
        source: blurSource
        visible: root.useGlassMode && !root.showSolidBackground

        blurEnabled: true
        blur: root.blurAmount
        blurMax: 72
        blurMultiplier: 1.4

        colorization: 0.0
        colorizationColor: root.themeIsDark
            ? Qt.rgba(0.15, 0.18, 0.25, root.tintIntensity)
            : Qt.rgba(1.0, 1.0, 1.0, root.tintIntensity)

        brightness: root.themeIsDark ? 0.035 : 0.08
        saturation: root.themeIsDark ? 1.12 : 1.20
        contrast: 0.0

        maskEnabled: true
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: glassEffect.width
                height: glassEffect.height
                radius: root.radiusPx
                color: "white"
            }
        }

        shadowEnabled: false
    }

    ShaderEffect {
        id: noiseLayer
        anchors.fill: glassEffect
        visible: glassEffect.visible && root.noiseOpacity > 0.001
        blending: true

        property real time: 0.0
        property real opacity_val: root.noiseOpacity

        NumberAnimation on time {
            from: 0; to: 1000
            duration: 120000
            loops: Animation.Infinite
            running: noiseLayer.visible
        }

        fragmentShader: "
            #version 440
            in vec2 qt_TexCoord0;
            out vec4 fragColor;

            layout(std140, binding = 0) uniform buf {
                mat4 qt_Matrix;
                float qt_Opacity;
                float time;
                float opacity_val;
            };

            float hash(vec2 p) {
                p = fract(p * vec2(234.34, 435.345));
                p += dot(p, p + 34.23);
                return fract(p.x * p.y);
            }

            float noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(
                    mix(hash(i), hash(i + vec2(1,0)), f.x),
                    mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
                    f.y
                );
            }

            void main() {
                vec2 uv = qt_TexCoord0 * vec2(420.0, 240.0) + time * 0.08;
                float n = noise(uv) * 0.55 + noise(uv * 2.1 + 7.3) * 0.30 + noise(uv * 4.3 + 2.1) * 0.15;
                float grain = n * opacity_val * qt_Opacity;
                fragColor = vec4(vec3(1.0) * grain, grain * 0.7);
            }
        "
    }

    ShaderEffect {
        id: iridescenceLayer
        anchors.fill: glassEffect
        visible: glassEffect.visible && root.iridescenceStrength > 0.01

        property real strength: root.iridescenceStrength
        property real time: 0.0

        NumberAnimation on time {
            from: 0; to: 6.2831
            duration: 12000
            loops: Animation.Infinite
            running: iridescenceLayer.visible
        }

        fragmentShader: "
            #version 440
            in vec2 qt_TexCoord0;
            out vec4 fragColor;

            layout(std140, binding = 0) uniform buf {
                mat4 qt_Matrix;
                float qt_Opacity;
                float strength;
                float time;
            };

            vec3 spectral(float t) {
                return vec3(
                    0.5 + 0.5 * cos(6.2831 * (t + 0.00)),
                    0.5 + 0.5 * cos(6.2831 * (t + 0.33)),
                    0.5 + 0.5 * cos(6.2831 * (t + 0.67))
                );
            }

            void main() {
                vec2 uv = qt_TexCoord0;
                float angle = atan(uv.y - 0.5, uv.x - 0.5);
                float r = length(uv - 0.5);
                float wave = sin(angle * 3.0 + time * 0.4 + r * 6.0) * 0.5 + 0.5;
                float edgeFade = smoothstep(0.5, 0.15, r);
                float topBias = pow(1.0 - uv.y, 2.2) * 0.6;
                float alpha = wave * edgeFade * topBias * strength * qt_Opacity;
                vec3 col = spectral(wave * 0.18 + time * 0.04);
                fragColor = vec4(col * alpha, alpha * 0.65);
            }
        "
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }
}
