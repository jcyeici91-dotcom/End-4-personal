import qs.modules.common
import QtQuick

QtObject {
    id: s

    // Inputs
    property bool shouldBeVisible: true
    property bool vertical: false

    property int padding: 6
    property int effectiveEdgeInset: 2

    // Estos te los pasa BarGroup desde el layout
    property real contentImplicitWidth: 0
    property real contentImplicitHeight: 0

    // Outputs
    readonly property real implicitWidth: shouldBeVisible
        ? (vertical
            ? (Appearance.sizes.baseVerticalBarWidth + effectiveEdgeInset * 2)
            : (contentImplicitWidth + (padding * 2) + effectiveEdgeInset * 2))
        : 0

    readonly property real implicitHeight: shouldBeVisible
        ? (vertical
            ? (contentImplicitHeight + (padding * 2) + effectiveEdgeInset * 2)
            : (Appearance.sizes.baseBarHeight + effectiveEdgeInset * 2))
        : 0
}
