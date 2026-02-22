// ~/.config/quickshell/ii/modules/ii/bar/BarCornerStyle.qml
import qs.modules.common
import QtQuick

QtObject {
    id: s

    // Inputs
    property bool vertical: false
    property bool isBottom: false

    // cornerStyle: "hug" | "float" | "rect" | "line"
    // (puedes mapear esto desde Config.options.bar.groupBackgroundStyle)
    property string cornerStyle: "hug"

    // flags generales
    property bool isBorderless: false
    property bool attachScreenLeft: false
    property bool attachScreenRight: false

    // radios base (si borderless o si quieres forzar)
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // geometría para hug (píldora)
    property real pillRadius: 9999

    // geometría para rect
    property real rectRadius: 4

    // ======= Derived booleans =======
    readonly property bool useRect: cornerStyle === "rect"
    readonly property bool useLine: cornerStyle === "line"
    readonly property bool useFloat: cornerStyle === "float"
    readonly property bool useHug: cornerStyle === "hug" || cornerStyle === "rounded" // compat

    // “base radius” (lo que antes llamabas baseRadius)
    readonly property real baseRadius: {
        if (useLine) return 0;
        if (useRect) return rectRadius;
        if (isBorderless) return startRadius;
        // hug/float por defecto usan pillRadius
        return pillRadius;
    }

    // Float = hybrid flattening
    readonly property bool flattenTop: useFloat && !vertical && !isBottom
    readonly property bool flattenBottom: useFloat && !vertical && isBottom

    // Output radii
    readonly property real rtl: {
        if (useRect) return baseRadius;
        if (useLine) return 0;
        if (!useFloat) return baseRadius;           // hug
        if (flattenTop || attachScreenLeft) return 0;
        return baseRadius;
    }

    readonly property real rtr: {
        if (useRect) return baseRadius;
        if (useLine) return 0;
        if (!useFloat) return baseRadius;           // hug
        if (flattenTop || attachScreenRight) return 0;
        return baseRadius;
    }

    readonly property real rbl: {
        if (useRect) return baseRadius;
        if (useLine) return 0;
        if (!useFloat) return baseRadius;           // hug
        if (flattenBottom || attachScreenLeft) return 0;
        return baseRadius;
    }

    readonly property real rbr: {
        if (useRect) return baseRadius;
        if (useLine) return 0;
        if (!useFloat) return baseRadius;           // hug
        if (flattenBottom || attachScreenRight) return 0;
        return baseRadius;
    }
}
