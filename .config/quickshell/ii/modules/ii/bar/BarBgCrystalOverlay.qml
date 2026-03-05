import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root

    property string position: "top"
    property int cornerStyle: 0
    property bool useGlassMode: true
    property bool showSolidBackground: false
    property color backgroundColor: Qt.rgba(1,1,1,0.30)
    property real overlayStrength: Appearance.colors.isDark ? 1.0 : 0.95

    property real iridescenceStrength: 0.06

    function _lin(c){ return 0.2126*c.r + 0.7152*c.g + 0.0722*c.b }
    function _isDark(c){ return _lin(c) < 0.65 }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property int outerMargin:
        (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    readonly property int rad:
        (cornerStyle === 1)
        ? (Appearance.rounding.windowRounding ?? 18)
        : 0

    anchors.margins: outerMargin

    Rectangle {
        id: shell
        anchors.fill: parent
        radius: root.rad
        antialiasing: true
        color: "transparent"
        clip: true
        visible: root.useGlassMode && !root.showSolidBackground

        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0;  color: Qt.rgba(1,1,1, root.themeIsDark ? 0.18 : 0.42) }
                GradientStop { position: 0.15; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.05 : 0.12) }
                GradientStop { position: 0.50; color: "transparent" }
                GradientStop { position: 0.85; color: Qt.rgba(0,0,0, root.themeIsDark ? 0.08 : 0.02) }
                GradientStop { position: 1.0;  color: Qt.rgba(0,0,0, root.themeIsDark ? 0.20 : 0.04) }
            }

            opacity: root.overlayStrength
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, shell.radius - 1)
            antialiasing: true
            color: "transparent"

            border.width: 1.2
            border.color: Qt.rgba(1,1,1, root.themeIsDark ? 0.10 : 0.32)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: root.rad > 0 ? root.rad * 1.4 : 20
            anchors.rightMargin: root.rad > 0 ? root.rad * 1.4 : 20
            anchors.topMargin: 1

            height: 1.4
            opacity: root.overlayStrength * 0.85

            antialiasing: true
            smooth: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.25 : 0.55) }
                GradientStop { position: 0.5;  color: Qt.rgba(1,1,1, root.themeIsDark ? 0.55 : 0.85) }
                GradientStop { position: 0.75; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.25 : 0.55) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: root.rad > 0 ? root.rad : 10
            anchors.rightMargin: root.rad > 0 ? root.rad : 10
            anchors.bottomMargin: 1

            height: 1.3
            opacity: root.overlayStrength * 0.65

            antialiasing: true
            smooth: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.16 : 0.38) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Math.max(0, shell.radius - 2)
            color: Qt.rgba(1,1,1, root.themeIsDark ? 0.02 : 0.04)
        }

        ShaderEffect {
            id: specularReflection
            anchors.fill: parent

            visible: root.useGlassMode && !root.showSolidBackground

            property real mouseX: 0.5
            property real mouseY: 0.5
            property real intensity: root.themeIsDark ? 0.08 : 0.14

            fragmentShader: "
                #version 440
                in vec2 qt_TexCoord0;
                out vec4 fragColor;

                uniform float mouseX;
                uniform float mouseY;
                uniform float intensity;

                void main() {

                    vec2 uv = qt_TexCoord0;
                    vec2 lightPos = vec2(mouseX, mouseY);

                    float dist = distance(uv, lightPos);

                    float highlight = exp(-dist * 20.0);

                    vec3 specular = vec3(1.0) * highlight * intensity;

                    fragColor = vec4(specular, highlight * intensity);
                }
            "
        }

        ShaderEffect {
            id: iridescence
            anchors.fill: parent

            visible: root.useGlassMode && !root.showSolidBackground && root.iridescenceStrength > 0.001

            property real mouseX: specularReflection.mouseX
            property real mouseY: specularReflection.mouseY
            property real strength: root.iridescenceStrength

            fragmentShader: "
                #version 440
                in vec2 qt_TexCoord0;
                out vec4 fragColor;

                uniform float mouseX;
                uniform float mouseY;
                uniform float strength;

                vec3 rainbow(float t){
                    return vec3(
                        0.5 + 0.5*cos(6.2831*(t+0.0)),
                        0.5 + 0.5*cos(6.2831*(t+0.33)),
                        0.5 + 0.5*cos(6.2831*(t+0.66))
                    );
                }

                void main(){

                    vec2 uv = qt_TexCoord0;

                    vec2 light = vec2(mouseX,mouseY);

                    float d = distance(uv, light);

                    float band = sin((uv.x + uv.y + d*2.0)*12.0);

                    vec3 color = rainbow(band*0.15);

                    float fade = exp(-d*8.0);

                    fragColor = vec4(color * strength * fade, strength * fade);
                }
            "
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: {
                specularReflection.mouseX = mouse.x / width
                specularReflection.mouseY = mouse.y / height
            }
        }
    }
}
