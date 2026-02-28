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

    readonly property bool themeIsDark: Appearance.colors.isDark

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
        color: root.backgroundColor

        border.width: (root.cornerStyle === 1) ? 1 : 0
        border.color: root.showSolidBackground
            ? Appearance.colors.colLayer0Border
            : (root.themeIsDark
                ? Qt.rgba(1, 1, 1, 0.10)
                : Qt.rgba(1, 1, 1, 0.35))

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

         Item {
            anchors.fill: parent
            visible: root.useGlassMode && !root.showSolidBackground
            clip: true

            //  Base dark/light absorption (depth)
            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                antialiasing: true
                color: root.themeIsDark
                    ? Qt.rgba(0, 0, 0, 0.10)
                    : Qt.rgba(1, 1, 1, 0.08)
            }

            //  Volumetric vertical light
            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0.0
                        color: root.themeIsDark
                            ? Qt.rgba(1, 1, 1, 0.18)
                            : Qt.rgba(1, 1, 1, 0.75)
                    }

                    GradientStop {
                        position: 0.35
                        color: root.themeIsDark
                            ? Qt.rgba(1, 1, 1, 0.04)
                            : Qt.rgba(1, 1, 1, 0.25)
                    }

                    GradientStop {
                        position: 1.0
                        color: root.themeIsDark
                            ? Qt.rgba(1, 1, 1, 0.10)
                            : Qt.rgba(1, 1, 1, 0.45)
                    }
                }
            }

            // Radial inner glow (liquid feel)
            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                antialiasing: true
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root.themeIsDark
                            ? Qt.rgba(1, 1, 1, 0.06)
                            : Qt.rgba(1, 1, 1, 0.20)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            //  Specular highlight (refinado)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 1
                anchors.leftMargin: bg.radius > 0 ? bg.radius * 1.5 : 20
                anchors.rightMargin: bg.radius > 0 ? bg.radius * 1.5 : 20
                height: 2
                antialiasing: true
                smooth: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 0.5
                        color: root.themeIsDark
                            ? Qt.rgba(1, 1, 1, 0.65)
                            : Qt.rgba(1, 1, 1, 0.95)
                    }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Outer rim
            Rectangle {
                anchors.fill: parent
                radius: bg.radius
                color: "transparent"
                border.width: (root.cornerStyle === 0) ? 0 : 1
                antialiasing: true
                border.color: root.themeIsDark
                    ? Qt.rgba(1, 1, 1, 0.20)
                    : Qt.rgba(1, 1, 1, 0.55)
            }

            // Inner rim shadow (grosor real)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, bg.radius - 1)
                color: "transparent"
                border.width: (root.cornerStyle === 0) ? 0 : 1
                antialiasing: true
                border.color: root.themeIsDark
                    ? Qt.rgba(0, 0, 0, 0.35)
                    : Qt.rgba(0, 0, 0, 0.15)
            }
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
