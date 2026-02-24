// BarBackgroundSystem.qml
import QtQuick
import qs
import qs.modules.common 
import qs.modules.common.widgets
import qs.modules.common.functions
import "." as Bar

Item {
    id: sys
    
    // Solo recibe estado ambiental del BarState
    required property Bar.BarState state

    // =========================================================
    // 1. LECTURA DE CONFIGURACIÓN Y ESTILOS
    // =========================================================
    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)
    
    // Corner style es necesario aquí para saber si dibujar sombra o bordes rectos/flotantes
    readonly property int cornerStyle: Config?.options?.bar?.cornerStyle ?? 0

    // Función interna para mapear el número de configuración al nombre de estilo
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
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"
    readonly property bool bgIsAdaptive: resolvedStyle === "adaptive"
    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    // Comportamiento Adaptativo
    // - Con ventanas -> Solid (Visible)
    // - Sin ventanas -> Glass
    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && state.hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !state.hasActiveWindows)
    readonly property bool useOverlayBg: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !state.hasActiveWindows)

    // Necesario para saber si no dibujar el fondo si el grupo es híbrido
    readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")
    readonly property bool allowFullBarBackgroundInHybrid: (useHybridGroups && showSolidBackground)
    readonly property bool shouldDrawBackground: (!useHybridGroups) || allowFullBarBackgroundInHybrid

    // =========================================================
    // 2. CÁLCULO DE COLORES Y MATERIALES
    // =========================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    readonly property color glassTint: themeIsDark
        ? ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35)
        : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)

    readonly property color glassRim: themeIsDark
        ? Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.18)
        : Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.22)

    readonly property color glassRimInner: themeIsDark
        ? Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.10)
        : Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.08)

    // =========================================================
    // 3. RENDERIZADO VISUAL
    // =========================================================
    Loader {
        id: bgLoader
        z: -10
        anchors.fill: parent
        sourceComponent: sys.shouldDrawBackground
            ? (sys.useOverlayBg ? overlayBgComponent : classicBgComponent)
            : null
    }

    Component {
        id: classicBgComponent
        Item {
            anchors.fill: parent

            Loader {
                active: (sys.cornerStyle === 1)
                        && !!(Config?.options?.bar?.floatStyleShadow)
                        && (sys.showSolidBackground || sys.useGlassMode)
                anchors.fill: barBackground
                sourceComponent: StyledRectangularShadow {
                    anchors.fill: undefined
                    target: barBackground
                    color: sys.useGlassMode
                        ? (sys.themeIsDark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.22))
                        : Qt.rgba(0, 0, 0, 0.20)
                    blur: sys.useGlassMode ? 46 : 14
                    spread: -2
                }
            }

            Rectangle {
                id: barBackground
                z: -10
                anchors.fill: parent
                anchors.margins: (sys.cornerStyle === 1)
                    ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
                    : 0
                radius: (sys.cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
                antialiasing: true

                color: sys.showSolidBackground ? Appearance.colors.colLayer0 : sys.glassTint

                border.width: (sys.cornerStyle === 1) ? 1 : 0
                border.color: sys.showSolidBackground
                    ? Appearance.colors.colLayer0Border
                    : ColorUtils.transparentize(Appearance.colors.colOnLayer1, sys.themeIsDark ? 0.90 : 0.84)

                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }
                Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }

                // Tratamiento Glass
                Item {
                    anchors.fill: parent
                    visible: sys.useGlassMode
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, sys.themeIsDark ? 0.84 : 0.86)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, sys.themeIsDark ? 0.14 : 0.18) }
                            GradientStop { position: 0.40; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, sys.themeIsDark ? 0.03 : 0.08) }
                            GradientStop { position: 1.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, sys.themeIsDark ? 0.08 : 0.12) }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        antialiasing: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, sys.themeIsDark ? 0.06 : 0.10) }
                            GradientStop { position: 1.0; color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.00) }
                        }
                        transform: Rotation {
                            origin.x: barBackground.width / 2
                            origin.y: barBackground.height / 2
                            angle: -18
                        }
                        opacity: 0.85
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: barBackground.radius
                        color: "transparent"
                        border.width: 1
                        antialiasing: true
                        border.color: sys.glassRim
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, barBackground.radius - 1)
                        color: "transparent"
                        border.width: 1
                        antialiasing: true
                        border.color: sys.glassRimInner
                    }
                }

                // Border sólido
                Rectangle {
                    anchors.fill: parent
                    radius: barBackground.radius
                    color: "transparent"
                    border.width: (sys.cornerStyle === 1) ? 1 : 0
                    border.color: Appearance.colors.colLayer0Border
                    opacity: sys.showSolidBackground ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }
            }
        }
    }

    Component {
        id: overlayBgComponent
        Item {
            anchors.fill: parent

            Item { id: overlayBg; anchors.fill: parent }

            Bar.BarBgShadowOverlay {
                targetItem: overlayBg
                cornerStyle: sys.cornerStyle
                visibleWhen: (sys.cornerStyle === 1)
                    && !!(Config?.options?.bar?.floatStyleShadow)
                    && (sys.showSolidBackground || sys.useGlassMode)
            }

            Loader {
                anchors.fill: overlayBg
                active: true
                sourceComponent: sys.bgIsCrystal ? crystalBaseComponent : normalBaseComponent
            }

            Component {
                id: normalBaseComponent
                Bar.BarBgOverlay {
                    anchors.fill: parent
                    position: state.edge
                    cornerStyle: sys.cornerStyle
                    useGlassMode: sys.useGlassMode
                    showSolidBackground: sys.showSolidBackground
                    backgroundColor: sys.showSolidBackground ? Appearance.colors.colLayer0 : sys.glassTint
                }
            }

            Component {
                id: crystalBaseComponent
                Bar.BarBgOverlayGlassBlur {
                    anchors.fill: parent
                    position: state.edge
                    cornerStyle: sys.cornerStyle
                    useGlassMode: sys.useGlassMode
                    showSolidBackground: sys.showSolidBackground
                    backgroundColor: sys.glassTint
                }
            }

            Loader {
                anchors.fill: overlayBg
                active: sys.bgIsCrystal
                visible: sys.bgIsCrystal
                sourceComponent: crystalTopComponent
            }

            Component {
                id: crystalTopComponent
                Bar.BarBgCrystalOverlay {
                    anchors.fill: parent
                    position: state.edge
                    cornerStyle: sys.cornerStyle
                    useGlassMode: sys.useGlassMode
                    showSolidBackground: sys.showSolidBackground
                    backgroundColor: sys.glassTint
                }
            }
        }
    }
}
