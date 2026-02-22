// ~/.config/quickshell/ii/modules/ii/bar/HybridStyle.qml
import qs.modules.common
import QtQuick

QtObject {
    id: s

    // Inputs (los setea BarGroup)
    property bool vertical: false
    property bool isBottom: false

    property bool useRectBg: false
    property bool useHybridBg: false
    property bool useLineBg: false

    property bool isBorderless: false
    property bool attachScreenLeft: false
    property bool attachScreenRight: false

    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // Para el modo pill clásico
    property real pillRadius: 9999

    // ===== Outputs (cálculos) =====
    readonly property real baseRadius: {
        if (useRectBg) return 4;
        if (useLineBg) return 0;
        if (isBorderless) return startRadius;
        return pillRadius;
    }

    readonly property bool flattenTop: useHybridBg && !vertical && !isBottom
    readonly property bool flattenBottom: useHybridBg && !vertical && isBottom

    readonly property real rtl: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenTop || attachScreenLeft) return 0;
        return baseRadius;
    }
    readonly property real rtr: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenTop || attachScreenRight) return 0;
        return baseRadius;
    }
    readonly property real rbl: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenBottom || attachScreenLeft) return 0;
        return baseRadius;
    }
    readonly property real rbr: {
        if (useRectBg) return baseRadius;
        if (!useHybridBg) return baseRadius;
        if (flattenBottom || attachScreenRight) return 0;
        return baseRadius;
    }
}
