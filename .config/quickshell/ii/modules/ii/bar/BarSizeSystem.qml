import QtQuick
import qs
import qs.modules.common

QtObject {
    id: sys

    property var screen: null

    readonly property int shortenMode: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width)
        ? 2
        : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width)
            ? 1
            : 0

    readonly property real useShortenedForm: shortenMode

    readonly property int centerSideModuleWidth: (shortenMode === 2)
        ? Appearance.sizes.barCenterSideModuleWidthHellaShortened
        : (shortenMode === 1)
            ? Appearance.sizes.barCenterSideModuleWidthShortened
            : Appearance.sizes.barCenterSideModuleWidth

    readonly property int baseBarHeight: Appearance.sizes.baseBarHeight

    readonly property int classicEdgeInset: Math.ceil(Appearance.rounding.screenRounding / 2)

    readonly property int floatOuterGaps: Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))

    readonly property int moduleSpacing: 4
}
