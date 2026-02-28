// BarBgOverlayGlassBlur.qml
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

    property real chromaticAberration: 0.015 // Intensidad del desfase de color
    property real iridescenceStrength: 0.30 // Intensidad del gradiente iridiscente (como image_0.png)
    property real shadowOpacity: 0.18 // Opacidad de la sombra
    property int shadowBlur: 20 // Desenfoque de la sombra

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

    // 1. Sólido
    Rectangle {
        id: solidBg
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: root.radiusPx
        visible: root.showSolidBackground
        color: root.backgroundColor
        antialiasing: true
    }

    // 2. Fuente de Desenfoque
    ShaderEffectSource {
        id: blurSource
        anchors.fill: parent
        anchors.margins: root.outerMargin
      live: true
        visible: false
        recursive: true
        smooth: true
    }

    // 3. Efecto de Cristal Envolvente 
    MultiEffect {
        id: glassEffect
        anchors.fill: parent
        anchors.margins: root.outerMargin
        source: blurSource
        visible: root.useGlassMode && !root.showSolidBackground

        // Desenfoque base suave
        blurEnabled: true
        blurMax: 80
        blur: 1.0

        // Sombra paralela suave 
        shadowEnabled: true
        shadowBlur: root.shadowBlur
        shadowColor: Qt.rgba(0, 0, 0, root.shadowOpacity)
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 2

        brightness: themeIsDark ? 0.08 : 0.12
        saturation: 1.15 // Un aumento modesto para los colores de fondo

        opacity: 0.95

            Rectangle {
            anchors.fill: parent
            radius: root.radiusPx
            border.width: 1
            border.color: themeIsDark
                ? Qt.rgba(1, 1, 1, 0.12)
                : Qt.rgba(0, 0, 0, 0.08)
            color: "transparent"
        }
    }

   ShaderEffect {
        id: iridescenceShader
        anchors.fill: parent
        anchors.margins: root.outerMargin
        
      property var source: blurSource 
        
        visible: root.useGlassMode && !root.showSolidBackground

        // Propiedades uniformes para el shader
        property real aberration: root.chromaticAberration
        property real iridescence: root.iridescenceStrength
        property real radius: root.radiusPx
        property real itemWidth: width
        property real itemHeight: height

        // Vertex Shader Passthrough
        vertexShader: "
            #version 150
            in vec4 qt_Vertex;
            in vec2 qt_MultiTexCoord0;
            out vec2 qt_TexCoord0;
            uniform mat4 qt_Matrix;
            void main() {
                qt_TexCoord0 = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }
        "

        // Fragment Shader: Dispersión Cromática e Iridiscencia (Efecto Prismático)
        fragmentShader: "
            #version 150
            in vec2 qt_TexCoord0;
            out vec4 finalColor;
            uniform sampler2D source;
            uniform float aberration;
            uniform float iridescence;
            uniform float itemWidth;
            uniform float itemHeight;

            void main() {
                vec2 uv = qt_TexCoord0;

                // --- 1. Dispersión Cromática ---
                vec2 center = vec2(0.5, 0.5);
                vec2 fromCenter = uv - center;
                float dist = length(fromCenter);
                vec2 offset_R = fromCenter * aberration * (1.0 + 2.0 * dist * dist);
                vec2 offset_B = -offset_R * 0.8;

                vec3 sample_R = texture(source, uv + offset_R).rgb;
                vec3 sample_G = texture(source, uv).rgb;
                vec3 sample_B = texture(source, uv + offset_B).rgb;

                vec3 blurredBg = vec3(sample_R.r, sample_G.g, sample_B.b);

                // --- 2. Iridiscencia de Fina Capa ---
                float irid_dist = length((uv * 2.0 - 1.0) * vec2(1.0, itemWidth/itemHeight));
                float normalizedDist = smoothstep(0.0, 1.0, irid_dist);

                vec3 irid_color = vec3(0.0);
                float hueOffset = 0.45 + normalizedDist * 0.65;
                
                irid_color.r = 0.5 * (1.0 + cos(6.28318 * (hueOffset + 0.0)));
                irid_color.g = 0.5 * (1.0 + cos(6.28318 * (hueOffset + 0.33)));
                irid_color.b = 0.5 * (1.0 + cos(6.28318 * (hueOffset + 0.67)));

                vec3 finalRGB = mix(blurredBg, irid_color, iridescence * smoothstep(0.3, 0.9, normalizedDist));

                finalColor = vec4(finalRGB, 1.0);
            }
        "
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }
}
