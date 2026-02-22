import QtQuick

QtObject {
    id: i

    // Inputs
    property bool bridgeMode: false
    property bool vertical: false
    property bool isBottom: false
    property string cornerStyle: "hug"   // "hug" | "float" | "rect" | "line" | ...

    property int effectiveEdgeInset: 2

    // Outputs (márgenes para backgroundLoader)
    readonly property int topMargin: {
        if (bridgeMode) return 0;
        if (cornerStyle === "float" && !vertical && !isBottom) return 0;
        if (vertical) return 0;
        return effectiveEdgeInset;
    }

    readonly property int bottomMargin: {
        if (bridgeMode) return 0;
        if (cornerStyle === "float" && !vertical && isBottom) return 0;
        if (vertical) return 0;
        return effectiveEdgeInset;
    }

    readonly property int leftMargin: {
        if (bridgeMode) return 0;
        if (!vertical) return 0;
        return effectiveEdgeInset;
    }

    readonly property int rightMargin: {
        if (bridgeMode) return 0;
        if (!vertical) return 0;
        return effectiveEdgeInset;
    }
}
