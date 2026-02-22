// parts/BarBackground.qml
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// OJO: este archivo vive en /bar/parts,
// así que ".." es la carpeta /bar donde están BarBgShadowOverlay.qml etc.
import ".." as Bar

Item {
    id: bg
    anchors.fill: parent
    z: -10

    // Inputs necesarios (son los que tu BarContent usa)
    required property bool shouldDrawBackground
    required property bool useOverlayBg
    required property bool showSolidBackground
    required property bool useGlassMode
    required property bool bgIsCrystal

    required property bool themeIsDark
    required property color glassTint
    required property color glassRim
    required property color glassRimInner

    Loader {
        id: bgLoader
        anchors.fill: parent
        sourceComponent: bg.shouldDrawBackground
            ? (bg.useOverlayBg ? overlayBgComponent : classicBgComponent)
            : null
    }

    Component {
        id: classicBgComponent

        Item {
            anchors.fill: parent

            Loader {
                active: (Config?.options?.bar?.cornerStyle === 1)
                        && !!(Config?.options?.bar?.floatStyleShadow)
                        && (bg.showSolidBackground || bg.useGlassMode)

                anchors.fill: barBackground
                sourceComponent: StyledRectangularShadow {
                    anchors.fill: undefined
                    target: barBackground
                    color: bg.useGlassMode
                        ? (bg.themeIsDark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.22))
                        : Qt.rgba(0, 0, 0, 0.20)
                    blur: bg.useGlassMode ? 46 : 14
                    spread: -2
                }
            }

            Rectangle {
                id: barBackground
                z: -10

                anchors.fill: parent
                anchors.margins: (Config?.options?.bar?.cornerStyle === 1)
                    ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
                    : 0

                radius: (Config?.options?.bar?.cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
                antialiasing: true

                color: bg.showSolidBackground ? Appearance.colors.colLayer0 : bg.glassTint

                border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
                border.color: bg.showSolidBackground
                    ? Appearance.colors.colLayer0Border
                    : ColorUtils.transparentize(Appearance.colors.colOnLayer1, bg.themeIsDark ? 0.90 : 0.84)

                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }
                Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }

                Item {
                    anchors.fill: parent
                    visible: bg.useGlassMode
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, bg.themeIsDark ? 0.84 : 0.86)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, bg.themeIsDark ? 0.14 : 0.18) }
                            GradientStop { position: 0.40; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, bg.themeIsDark ? 0.03 : 0.08) }
                            GradientStop { position: 1.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, bg.themeIsDark ? 0.08 : 0.12) }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, bg.themeIsDark ? 0.06 : 0.10) }
                            GradientStop { position: 1.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.00) }
                        }
                        transform: Rotation { origin.x: barBackground.width / 2; origin.y: barBackground.height / 2; angle: -18 }
                        opacity: 0.85
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        color: "transparent"
                        border.width: 1
                        antialiasing: true
                        border.color: bg.glassRim
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, barBackground.radius - 1)
                        color: "transparent"
                        border.width: 1
                        antialiasing: true
                        border.color: bg.glassRimInner
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: barBackground.radius
                    color: "transparent"
                    border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
                    border.color: Appearance.colors.colLayer0Border
                    opacity: bg.showSolidBackground ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }
            }
        }
    }

    Component {
        id: overlayBgComponent

        Item {
            anchors.fill: parent

            Item {
                id: overlayBg
                anchors.fill: parent
            }

            Bar.BarBgShadowOverlay {
                targetItem: overlayBg
                cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)
                visibleWhen: (Config?.options?.bar?.cornerStyle === 1)
                    && !!(Config?.options?.bar?.floatStyleShadow)
                    && (bg.showSolidBackground || bg.useGlassMode)
            }

            Loader {
                id: overlayBase
                anchors.fill: overlayBg
                active: true
                sourceComponent: bg.bgIsCrystal ? crystalBaseComponent : normalBaseComponent
            }

            Component {
                id: normalBaseComponent
                Bar.BarBgOverlay {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: bg.useGlassMode
                    showSolidBackground: bg.showSolidBackground
                    backgroundColor: bg.showSolidBackground ? Appearance.colors.colLayer0 : bg.glassTint
                }
            }

            Component {
                id: crystalBaseComponent
                Bar.BarBgOverlayGlassBlur {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: bg.useGlassMode
                    showSolidBackground: bg.showSolidBackground
                    backgroundColor: bg.glassTint
                }
            }

            Loader {
                id: crystalTop
                anchors.fill: overlayBg
                active: bg.bgIsCrystal
                visible: bg.bgIsCrystal
                sourceComponent: crystalTopComponent
            }

            Component {
                id: crystalTopComponent
                Bar.BarBgCrystalOverlay {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: bg.useGlassMode
                    showSolidBackground: bg.showSolidBackground
                    backgroundColor: bg.glassTint
                }
            }
        }
    }
}

