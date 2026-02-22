import qs.modules.common
import QtQuick

QtObject {
    id: t

    // Inputs (config)
    property var options: null   // pásale: Config.options
    property color layer0: Appearance.colors.colLayer0

    // Helpers
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    // Outputs
    readonly property int barBackgroundStyleInt: options?.bar?.barBackgroundStyle ?? 1
    readonly property bool bgIsCrystal: barBackgroundStyleInt === 3

    readonly property bool themeIsDark: _isDark(layer0)

    // opcional pero útil (centraliza)
    readonly property bool isBorderless: options?.bar?.borderless ?? false

    // tu selector original (lo dejamos aquí para que BarGroup no piense de más)
    readonly property string groupBackgroundStyle: options?.bar?.groupBackgroundStyle ?? "rounded"
    readonly property bool isBottom: options?.bar?.bottom ?? false
}
