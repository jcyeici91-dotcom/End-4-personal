import QtQuick
import qs.modules.common

QtObject {
    id: theme


    function safeColor(v, fallback) { return (v !== undefined && v !== null) ? v : fallback }
    function safeString(v, fallback) { return (typeof v === "string" && v.length > 0) ? v : fallback }

    // Parse % / °C para progress bars
    function parsePercentage(valueString) {
        if (!valueString) return 0
        var num = parseFloat(("" + valueString).replace(/[^0-9.]/g, ""))
        if (isNaN(num)) return 0
        return Math.max(0, Math.min(1, num / 100))
    }

    // Paleta base
    property color colBase: safeColor(Appearance && Appearance.colors ? Appearance.colors.colLayer0 : undefined, "#121212")
    property color colSurface: safeColor(Appearance && Appearance.colors ? Appearance.colors.colLayer1 : undefined, "#1a1a1a")
    property color colDark: safeColor(Appearance && Appearance.colors ? Appearance.colors.colLayerBorder : undefined, "#2a2a2a")
    property color colAccent: safeColor(Appearance && Appearance.colors ? Appearance.colors.colAccent : undefined, "#8ab4f8")
    property color colText: safeColor(Appearance && Appearance.colors ? Appearance.colors.colOnLayer0 : undefined, "#ffffff")

    property color colSubText: Qt.rgba(colText.r, colText.g, colText.b, 0.6)
    property color colHighlight: "#ffffff"

    property string fontMain: safeString(
        (Appearance && Appearance.font && typeof Appearance.font.family === "string") ? Appearance.font.family
        : (Appearance && Appearance.font && Appearance.font.family !== undefined) ? ("" + Appearance.font.family)
        : "",
        "Sans Serif"
    )

    // Extensiones
    property color colAccentDim: Qt.rgba(colAccent.r, colAccent.g, colAccent.b, 0.15)
    property color colSurfaceHighlight: Qt.lighter(colSurface, 1.12)
    property color colBorderSoft: Qt.rgba(1, 1, 1, 0.06)
    property color colBorderHover: Qt.rgba(colAccent.r, colAccent.g, colAccent.b, 0.28)
}
