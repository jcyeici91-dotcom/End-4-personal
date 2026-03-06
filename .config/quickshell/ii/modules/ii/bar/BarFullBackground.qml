import QtQuick

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.ui 1.0

import "." as Bar

Item {
    id: root

    property bool enabled: true

    property bool followGlobalStyle: false
    property int styleFromConfig: 1

    property bool hasActiveWindows: false
    property int cornerStyle: 0
    property bool isBottom: false

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
        const s = UIState.surfaceStyle
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(styleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"
    readonly property bool bgIsAdaptive: resolvedStyle === "adaptive"
    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)
    readonly property bool useOverlayBg: useGlassMode

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    readonly property color glassTint: themeIsDark
        ? ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35)
        : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)

    Loader {
        id: bgLoader
        anchors.fill: parent
        z: -10
        active: root.enabled
        sourceComponent: root.useOverlayBg ? overlayBgComponent : classicBgComponent
    }

    Component {
        id: classicBgComponent

        Item {
            anchors.fill: parent

            Loader {
                active: (root.cornerStyle === 1)
                    && !!(Config?.options?.bar?.floatStyleShadow)
                    && (root.showSolidBackground || root.useGlassMode)

                anchors.fill: barBackground

                sourceComponent: StyledRectangularShadow {
                    anchors.fill: undefined
                    target: barBackground
                    color: root.useGlassMode
                        ? (root.themeIsDark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.22))
                        : Qt.rgba(0, 0, 0, 0.20)
                    blur: root.useGlassMode ? 46 : 14
                    spread: -2
                }
            }

            Rectangle {
                id: barBackground
                z: -10
                anchors.fill: parent

                anchors.margins: (root.cornerStyle === 1)
                    ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
                    : 0

                radius: (root.cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
                antialiasing: true

                color: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint

                border.width: (root.cornerStyle === 1) ? 1 : 0
                border.color: root.showSolidBackground
                    ? Appearance.colors.colLayer0Border
                    : ColorUtils.transparentize(Appearance.colors.colOnLayer1, root.themeIsDark ? 0.90 : 0.84)
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
                cornerStyle: root.cornerStyle
                visibleWhen: (root.cornerStyle === 1)
                    && !!(Config?.options?.bar?.floatStyleShadow)
                    && (root.showSolidBackground || root.useGlassMode)
            }

            Loader {
                anchors.fill: overlayBg
                active: true
                sourceComponent: root.bgIsCrystal ? crystalBaseComponent : normalBaseComponent
            }

            Component {
                id: normalBaseComponent

                Bar.BarBgOverlay {
                    anchors.fill: parent
                    position: root.isBottom ? "bottom" : "top"
                    cornerStyle: root.cornerStyle
                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint
                }
            }

            Component {
                id: crystalBaseComponent

                Bar.BarBgOverlayGlassBlur {
                    anchors.fill: parent
                    position: root.isBottom ? "bottom" : "top"
                    cornerStyle: root.cornerStyle
                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.glassTint
                }
            }

            Loader {
                anchors.fill: overlayBg
                active: root.bgIsCrystal
                visible: root.bgIsCrystal

                sourceComponent: Bar.BarBgCrystalOverlay {
                    anchors.fill: parent
                    position: root.isBottom ? "bottom" : "top"
                    cornerStyle: root.cornerStyle
                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.glassTint
                }
            }
        }
    }
}

