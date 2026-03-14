import qs
import qs.modules.ii.onScreenDisplay.drawer as Osd
import qs.modules.ii.overview.drawer as SearchOverview
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    readonly property alias osd: osd
    readonly property alias searchOverview: searchOverview
    required property var visibilities

    anchors.fill: parent
    // anchors.margins: Config.border.thickness
    // anchors.leftMargin: bar.implicitWidth

    Osd.Wrapper {
        id: osd
        shown: root.visibilities.osd
        opacity: visible ? 1 : 0

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    SearchOverview.Wrapper {
        id: searchOverview
        shown: root.visibilities.searchOverview
        opacity: visible ? 1 : 0

        screen: root.screen

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
