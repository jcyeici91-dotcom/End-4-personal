import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.ii.ui 1.0
import "." as Bar

Item {
    id: root

    property bool enabled: true
    property bool followGlobalStyle: false
    property int styleFromConfig: 1
    property bool hasActiveWindows: false
    property bool isBottom: false

    property bool enableAnimations: Config.options.appearance.enableAnimations

    function _styleFromConfig(v) {
        switch (v) {
            case 0: return "glass"
            case 1: return "solid"
            case 2: return "adaptive"
            default: return "solid"
        }
    }

    function _styleFromUIState() {
        if (typeof UIState === "undefined") return ""
        const s = UIState.surfaceStyle
        return (s === "solid" || s === "glass" || s === "adaptive") ? s : ""
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

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || (bgIsAdaptive && !hasActiveWindows)
    readonly property bool useOverlayBg: useGlassMode

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    readonly property color glassTint: themeIsDark
        ? CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35)
        : CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)

    readonly property int safeFloatMargin: Config.options.bar.cornerStyle === 1
        ? Math.max(0, Appearance.sizes.hyprlandGapsOut)
        : 0

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
                active: !!(Config?.options?.bar?.floatStyleShadow) && enableAnimations
                anchors.fill: barBackground
                sourceComponent: StyledRectangularShadow {
                    anchors.fill: undefined
                    target: barBackground
                    color: Qt.rgba(0, 0, 0, 0.25)
                    blur: 14
                    spread: -2
                }
            }

            Rectangle {
                id: barBackground
                z: -10
                anchors.fill: parent
                anchors.margins: root.safeFloatMargin

                radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.full : 0
                antialiasing: radius > 0

                color: root.showSolidBackground ? Appearance.colors.colLayer0 : "transparent"

                border.width: 0
                border.color: "transparent"

                layer.enabled: radius > 0
                layer.smooth: true

                Behavior on color {
                    enabled: enableAnimations
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            Rectangle {
                id: barTopBorder
                height: 0
                visible: false
                color: Appearance.colors.colLayer0Border
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
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
                anchors.margins: Math.max(0, Appearance.sizes.hyprlandGapsOut)
            }

            Bar.BarBgShadowOverlay {
                targetItem: overlayBg
                cornerStyle: 1
                visibleWhen: !!(Config?.options?.bar?.floatStyleShadow) && enableAnimations
            }

            Bar.BarBgOverlay {
                anchors.fill: overlayBg
                position: root.isBottom ? "bottom" : "top"
                cornerStyle: 1
                useGlassMode: true
                showSolidBackground: false
                backgroundColor: root.glassTint

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 0
                    border.color: "transparent"
                    radius: Appearance.rounding.full
                    antialiasing: radius > 0
                    layer.enabled: radius > 0
                    layer.smooth: true
                }
            }
        }
    }
}
