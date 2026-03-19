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

    // NTERRUPTOR MAESTRO 
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
        if (typeof UIState === 'undefined') return ""
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
                active: !!(Config?.options?.bar?.floatStyleShadow) && enableAnimations // Apaga la sombra si las animaciones están apagadas
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
                
                // - MÁRGENES PARA EL MARCO ---
                anchors.topMargin: 6    // Despega el techo para ver el borde
                anchors.leftMargin: 8   // Despega la izquierda
                anchors.rightMargin: 8  // Despega la derecha
                // end 
                
                anchors.margins: Appearance.sizes.hyprlandGapsOut - 1 
                radius: Appearance.rounding.full 
                antialiasing: true

                color: root.showSolidBackground ? Appearance.colors.colLayer0 : "transparent"

                // Borde eliminado (estaba forzado en 1)
                border.width: 0 
                border.color: "transparent"

                Behavior on color {
                    enabled: enableAnimations
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            // --- Corregido ---
            // Forzamos un borde superior delgado y nítido a lo largo de toda la barra
            Rectangle {
                id: barTopBorder
                height: 1
                color: Appearance.colors.colLayer0Border
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: classicBgComponent.visible
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
                anchors.margins: Appearance.sizes.hyprlandGapsOut - 1
            }

            Bar.BarBgShadowOverlay {
                targetItem: overlayBg
                cornerStyle: 1 
                visibleWhen: !!(Config?.options?.bar?.floatStyleShadow) && enableAnimations // Apaga la sombra si las animaciones están apagadas
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
                }
            }
        }
    }
}
