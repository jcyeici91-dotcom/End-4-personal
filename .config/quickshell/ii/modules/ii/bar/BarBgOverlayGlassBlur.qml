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

    property int basePadding: 8          
    property real blurAmount: 0.85       //  nuevo control más intuitivo
    property real tintIntensity: 0.22    //  brightness/saturation muy alto
    property real noiseOpacity: 0.07     //  ruido muy sutil
    property real chromaticAberration: 0.008  // bajado (era muy visible)
    property real iridescenceStrength: 0.08   // casi no tiene rainbow fuerte
    property real shadowOpacity: 0.12    // más suave
    property int shadowBlur: 16          // más pequeño y suave

    default property alias content: contentContainer.data

    // Fondo sólido 
    Rectangle {
        id: solidBg
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: root.radiusPx
        visible: root.showSolidBackground
        color: root.backgroundColor
        antialiasing: true
    }

    // Fuente para el desenfoque 
    ShaderEffectSource {
        id: blurSource
        anchors.fill: parent
        anchors.margins: root.outerMargin
        live: true
        visible: false
        recursive: true       
        smooth: true
        // textureSize: Qt.size(width * 0.5, height * 0.5)   opcional: bajar resolución para rendimiento
    }

    //   SOLO MultiEffect 
    MultiEffect {
        id: glassEffect
        anchors.fill: parent
        anchors.margins: root.outerMargin
        source: blurSource
        visible: root.useGlassMode && !root.showSolidBackground

        // Controles para look iOS
        blurEnabled: true
        blur: root.blurAmount           // 0.7–0.9 suele verse muy parecido a iOS
        blurMax: 64                     // 48–96 según densidad de pantalla
        blurMultiplier: 1.0

        // Tinte suave 
        colorization: root.themeIsDark ? 0.0 : 0.0
        colorizationColor: root.themeIsDark
            ? Qt.rgba(0.18, 0.22, 0.30, root.tintIntensity)
            : Qt.rgba(0.92, 0.94, 0.96, root.tintIntensity)

        brightness: root.themeIsDark ? -0.02 : 0.04     // muy sutil
        saturation: root.themeIsDark ? 1.05 : 1.10      // leve boost

        // Borde muy fino 
        maskEnabled: true
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: glassEffect.width
                height: glassEffect.height
                radius: root.radiusPx
                color: "white"          // máscara = borde redondeado
                border.width: 1
                border.color: "black"   // borde sutil
            }
        }

        // Sombra muy suave 
        shadowEnabled: true
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowColor: Qt.rgba(0,0,0,1)
        shadowHorizontalOffset: 0
        shadowVerticalOffset: root.themeIsDark ? 1 : 2
    }

    
    //    Ruido muy sutil (vidrio )
    ShaderEffect {
        anchors.fill: glassEffect
        visible: glassEffect.visible && root.noiseOpacity > 0.001

        property real noiseOpacity: root.noiseOpacity

        fragmentShader: "
            #version 440
            in vec2 qt_TexCoord0;
            out vec4 fragColor;

            float random(vec2 st) {
                return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
            }

            void main() {
                vec2 uv = qt_TexCoord0 * vec2(1280.0, 720.0); // escala del ruido
                float n = random(uv + mod(qt_TexCoord0 * 0.0001, 1.0)); // animación muy lenta opcional
                vec4 color = vec4(vec3(n), 1.0);
                fragColor = mix(vec4(0.0), color, noiseOpacity * 0.6);
            }"
    }

        ShaderEffect {
        id: iridescenceShader
        anchors.fill: parent
        anchors.margins: root.outerMargin

        visible: root.useGlassMode && !root.showSolidBackground && root.iridescenceStrength > 0.01
        property var source: blurSource
        property real aberration: root.chromaticAberration
        property real iridescence: root.iridescenceStrength
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.outerMargin + root.basePadding
    }
}
