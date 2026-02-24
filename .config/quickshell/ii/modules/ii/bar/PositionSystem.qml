import QtQuick
import qs
import qs.modules.common

QtObject {
    id: sys

    property var screen: null

    readonly property string configPosition: Config?.options?.bar?.position ?? (Config?.options?.bar?.bottom ? "bottom" : "top")

    readonly property bool isTop: configPosition === "top"
    readonly property bool isBottom: configPosition === "bottom"
    readonly property bool isLeft: configPosition === "left"
    readonly property bool isRight: configPosition === "right"

    readonly property string edge: configPosition

    readonly property bool vertical: isLeft || isRight
    readonly property bool horizontal: isTop || isBottom

    readonly property int floatOuterGaps: Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
}
