import QtQuick

Item {
    id: bridges
    anchors.fill: parent
    z: -9

    required property bool useHybridGroups
    required property int cornerStyle
    required property bool allowFullBarBackgroundInHybrid
    required property bool isBottom

    required property bool bgIsCrystal
    required property color glassTint

    readonly property bool bridgeEnabled: (useHybridGroups
        && (cornerStyle === 0 || cornerStyle === 1)
        && !allowFullBarBackgroundInHybrid)

    readonly property int seamOverlapPx: 3

    readonly property int bridgeOuterMargin: (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    readonly property int bridgeExtraBleed: (cornerStyle === 0) ? seamOverlapPx : 0

    readonly property int bridgeBandPx: bridgeEnabled
        ? Math.max(4, Math.min(8, Math.round((Appearance.rounding.normal ?? 12) * 0.40)))
        : 0

    readonly property color bridgeColor: bgIsCrystal
        ? glassTint
        : Appearance.colors.colLayer0

    Item {
        id: topBridge
        visible: (!bridges.isBottom) && bridges.bridgeEnabled
        clip: true

        layer.enabled: true
        layer.smooth: false

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: bridges.bridgeOuterMargin - bridges.bridgeExtraBleed
            rightMargin: bridges.bridgeOuterMargin - bridges.bridgeExtraBleed
        }

        height: Math.round(bridges.bridgeBandPx + bridges.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(bridges.bridgeBandPx + bridges.seamOverlapPx)
            antialiasing: false
            color: bridges.bridgeColor
            radius: 0
        }
    }

    Item {
        id: bottomBridge
        visible: (bridges.isBottom) && bridges.bridgeEnabled
        clip: true

        layer.enabled: true
        layer.smooth: false

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: bridges.bridgeOuterMargin - bridges.bridgeExtraBleed
            rightMargin: bridges.bridgeOuterMargin - bridges.bridgeExtraBleed
        }

        height: Math.round(bridges.bridgeBandPx + bridges.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(bridges.bridgeBandPx + bridges.seamOverlapPx)
            antialiasing: false
            color: bridges.bridgeColor
            radius: 0
        }
    }
}
