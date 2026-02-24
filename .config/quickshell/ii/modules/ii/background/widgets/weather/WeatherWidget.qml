import QtQuick
import Qt5Compat.GraphicalEffects

import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

import qs.modules.ii.ui 1.0

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"

    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _styleFromUIState() {
        const s = (typeof UIState !== "undefined" && UIState) ? UIState.surfaceStyle : ""
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode !== undefined)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

        readonly property color bgShapeColor: bgIsCrystal
        ? Qt.rgba(Appearance.colors.colPrimaryContainer.r,
                  Appearance.colors.colPrimaryContainer.g,
                  Appearance.colors.colPrimaryContainer.b,
                  themeIsDark ? 0.28 : 0.22)
        : Appearance.colors.colPrimaryContainer

    readonly property color crystalTint: themeIsDark
        ? Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.18)
        : Qt.rgba(1, 1, 1, 0.14)

    readonly property color crystalRimOuter: themeIsDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.14)
    readonly property color crystalRimInner: themeIsDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.28)

    StyledDropShadow {
        target: backgroundShape
    }

    MaterialShape {
        id: backgroundShape
        anchors.fill: parent
        shape: MaterialShape.Shape.Pill
        color: root.bgShapeColor
        implicitSize: 200

        Loader {
            id: crystalOverlayLoader
            anchors.fill: parent
            z: 0.5
            active: root.bgIsCrystal
            asynchronous: false

            sourceComponent: Item {
                anchors.fill: parent

                ShaderEffectSource {
                    id: maskSource
                    sourceItem: backgroundShape
                    live: true
                    hideSource: false   // clave para que solid quede intacto al desactivar
                    visible: false
                }

                Item {
                    id: overlaySource
                    anchors.fill: parent
                    visible: false

                    // tint base
                    Rectangle { anchors.fill: parent; color: root.crystalTint }

                    // highlight vertical
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.30) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.06 : 0.12) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.14 : 0.08) }
                        }
                        opacity: 0.95
                    }

                    // sheen diagonal
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.10 : 0.16) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        transform: Rotation {
                            origin.x: overlaySource.width / 2
                            origin.y: overlaySource.height / 2
                            angle: -18
                        }
                        opacity: 0.85
                    }

                    // rims
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: root.crystalRimOuter
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: "transparent"
                        border.width: 1
                        border.color: root.crystalRimInner
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: overlaySource
                    maskSource: maskSource
                }
            }
        }

        StyledText {
            font {
                pixelSize: 80
                family: Appearance.font.family.expressive
                weight: Font.Medium
            }
            color: Appearance.colors.colPrimary
            text: Weather.data?.temp.substring(0, Weather.data?.temp.length - 1) ?? "--°"
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 16
                topMargin: 20
            }
        }

        MaterialSymbol {
            iconSize: 80
            color: Appearance.colors.colOnPrimaryContainer
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 16
                bottomMargin: 20
            }
        }
    }
}

