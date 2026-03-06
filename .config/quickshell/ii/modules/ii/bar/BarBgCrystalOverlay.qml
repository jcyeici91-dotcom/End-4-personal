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
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.28)
    property real overlayStrength: Appearance.colors.isDark ? 1.0 : 0.95
    property real iridescenceStrength: 0.05

    function _lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }

    readonly property bool themeIsDark: _lum(Appearance.colors.colLayer0) < 0.65

    readonly property int outerMargin:
        cornerStyle === 1
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    readonly property int rad:
        cornerStyle === 1
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

        layer.enabled: true
        layer.smooth: true

        Rectangle {
            anchors.fill: parent
            radius: shell.radius
            antialiasing: true
            opacity: root.overlayStrength

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.46) }
                GradientStop { position: 0.12; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.06 : 0.14) }
                GradientStop { position: 0.48; color: "transparent" }
                GradientStop { position: 0.82; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.06 : 0.02) }
                GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.18 : 0.04) }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0.5
            radius: Math.max(0, shell.radius - 0.5)
            antialiasing: true
            color: "transparent"
            border.width: 1.0
            border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.13 : 0.38)
        }

        Rectangle {
            id: innerGlow
            anchors.fill: parent
            anchors.margins: 1.5
            radius: Math.max(0, shell.radius - 1.5)
            antialiasing: true
            color: "transparent"
            border.width: 0.8
            border.color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.05 : 0.18)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad * 1.5 : 18
            anchors.rightMargin: root.rad > 0 ? root.rad * 1.5 : 18
            anchors.topMargin: 0.5
            height: 1.2
            antialiasing: true
            smooth: true
            opacity: root.overlayStrength * 0.90

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.00; color: "transparent" }
                GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.28 : 0.60) }
                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.60 : 0.90) }
                GradientStop { position: 0.80; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.28 : 0.60) }
                GradientStop { position: 1.00; color: "transparent" }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.rad > 0 ? root.rad * 1.2 : 12
            anchors.rightMargin: root.rad > 0 ? root.rad * 1.2 : 12
            anchors.bottomMargin: 0.5
            height: 1.0
            antialiasing: true
            smooth: true
            opacity: root.overlayStrength * 0.55

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.18 : 0.40) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2.5
            radius: Math.max(0, shell.radius - 2.5)
            color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.025 : 0.05)
        }

        ShaderEffect {
            id: specularReflection
            anchors.fill: parent

            property real lightX: 0.5
            property real lightY: 0.15
            property real intensity: root.themeIsDark ? 0.10 : 0.18
            property real radius_norm: root.rad / Math.max(width, height)

            fragmentShader: "
                #version 440
                in vec2 qt_TexCoord0;
                out vec4 fragColor;

                layout(std140, binding = 0) uniform buf {
                    mat4 qt_Matrix;
                    float qt_Opacity;
                    float lightX;
                    float lightY;
                    float intensity;
                    float radius_norm;
                };

                void main() {
                    vec2 uv = qt_TexCoord0;
                    vec2 lp = vec2(lightX, lightY);
                    float d = distance(uv, lp);

                    float radialFalloff = exp(-d * 14.0);
                    float topBias = pow(1.0 - uv.y, 1.6) * 0.7;
                    float combined = radialFalloff * topBias;

                    float rim = smoothstep(0.48, 0.50, length(uv - 0.5));
                    combined = max(combined, rim * 0.06);

                    vec3 col = mix(vec3(1.0), vec3(0.92, 0.96, 1.0), d * 0.5);
                    float alpha = combined * intensity * qt_Opacity;

                    fragColor = vec4(col * alpha, alpha);
                }
            "
        }

        ShaderEffect {
            id: iridescenceOverlay
            anchors.fill: parent
            visible: root.iridescenceStrength > 0.001

            property real mouseX: 0.5
            property real mouseY: 0.5
            property real strength: root.iridescenceStrength
            property real time: 0.0

            NumberAnimation on time {
                from: 0; to: 6.2831
                duration: 14000
                loops: Animation.Infinite
                running: iridescenceOverlay.visible
            }

            fragmentShader: "
                #version 440
                in vec2 qt_TexCoord0;
                out vec4 fragColor;

                layout(std140, binding = 0) uniform buf {
                    mat4 qt_Matrix;
                    float qt_Opacity;
                    float mouseX;
                    float mouseY;
                    float strength;
                    float time;
                };

                vec3 spectral(float t) {
                    return clamp(vec3(
                        0.5 + 0.5 * cos(6.2831 * (t + 0.00)),
                        0.5 + 0.5 * cos(6.2831 * (t + 0.33)),
                        0.5 + 0.5 * cos(6.2831 * (t + 0.67))
                    ), 0.0, 1.0);
                }

                void main() {
                    vec2 uv = qt_TexCoord0;
                    vec2 mouse = vec2(mouseX, mouseY);
                    float d = distance(uv, mouse);

                    float angle = atan(uv.y - 0.5, uv.x - 0.5);
                    float wave = sin(angle * 2.5 + d * 5.0 - time * 0.3) * 0.5 + 0.5;

                    float topFade = pow(1.0 - uv.y, 1.8);
                    float radFade = exp(-d * 6.5);
                    float alpha = wave * topFade * radFade * strength * qt_Opacity;

                    alpha = clamp(alpha, 0.0, strength * 0.8);

                    vec3 col = spectral(wave * 0.20 + time * 0.03);
                    fragColor = vec4(col * alpha, alpha * 0.7);
                }
            "
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: function(mouse) {
                specularReflection.lightX = mouse.x / width
                specularReflection.lightY = mouse.y / height
                iridescenceOverlay.mouseX  = mouse.x / width
                iridescenceOverlay.mouseY  = mouse.y / height
            }

            onExited: {
                specularReflection.lightX = 0.5
                specularReflection.lightY = 0.15
                iridescenceOverlay.mouseX  = 0.5
                iridescenceOverlay.mouseY  = 0.5
            }
        }
    }
}

