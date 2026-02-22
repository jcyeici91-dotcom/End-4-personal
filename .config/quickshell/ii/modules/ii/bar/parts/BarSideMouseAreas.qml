import QtQuick
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets as Widgets

import ".." as Bar

Item {
    id: side

    required property var brightnessMonitor
    required property Item middleSection

    anchors.fill: parent

    Widgets.FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: side.middleSection.left
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: if (side.brightnessMonitor) side.brightnessMonitor.setBrightness(side.brightnessMonitor.brightness - 0.05)
        onScrollUp: if (side.brightnessMonitor) side.brightnessMonitor.setBrightness(side.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        Bar.ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Widgets.FocusedScrollMouseArea {
        id: barRightSideMouseArea
        z: -1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: side.middleSection.right
        anchors.right: parent.right
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        Bar.ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

