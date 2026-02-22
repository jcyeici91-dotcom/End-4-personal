// parts/BarStyle.qml
import QtQuick
import qs
import qs.modules.common
import qs.modules.common.functions

QtObject {
    id: s

    // Inputs
    required property bool hasActiveWindows

    // Expones esto para que BarContent siga usando "screen?.width"
    property var screen: null

    // Config/State
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
        const st = UIState.surfaceStyle
        return (st === "solid" || st === "glass" || st === "crystal" || st === "adaptive") ? st : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const st = _styleFromUIState()
            if (st !== "") return st
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"
    readonly property bool bgIsAdaptive: resolvedStyle === "adaptive"
    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    // Adaptive behavior:
    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)
    readonly property bool useOverlayBg: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)

    readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")
    readonly property int cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0) // 0 Hug | 1 Float | 2 Rect
    readonly property bool isBottom: (Config?.options?.bar?.bottom ?? false)

    readonly property bool allowFullBarBackgroundInHybrid: (useHybridGroups && showSolidBackground)
    readonly property bool shouldDrawBackground: (!useHybridGroups) || allowFullBarBackgroundInHybrid

    // Hybrid resize
    readonly property int hybridResizeMs: 85

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

    readonly property color barBgColor: showSolidBackground ? Appearance.colors.colLayer0 : glassTint

    readonly property color onBarStrong: Appearance.colors.colOnLayer1
    readonly property color onBar: Appearance.colors.colOnLayer1
    readonly property color onBarMuted: Appearance.colors.colOnLayer2
    readonly property color onBarIcon: Appearance.colors.colOnLayer1

    readonly property color chipBg: themeIsDark
        ? ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.86)
        : ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.90)
    readonly property color chipBorder: themeIsDark
        ? ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.82)
        : ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.86)

    // Shortening logic
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width)
        ? 2
        : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width)
            ? 1
            : 0

    readonly property int centerSideModuleWidth: (useShortenedForm == 2)
        ? Appearance.sizes.barCenterSideModuleWidthHellaShortened
        : (useShortenedForm == 1)
            ? Appearance.sizes.barCenterSideModuleWidthShortened
            : Appearance.sizes.barCenterSideModuleWidth
}
