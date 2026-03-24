pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property bool vertical: false
    property bool forceNoContainer: true
    property color colH1: Appearance.m3colors.m3primary
    property color colH2: Appearance.m3colors.m3secondary
    property color colPuntos: Appearance.m3colors.m3outlineVariant
    property color colM1: Appearance.m3colors.m3tertiary
    property color colM2: Appearance.m3colors.m3error
    property color colS1: Appearance.m3colors.m3primaryFixed
    property color colS2: Appearance.m3colors.m3secondaryFixed
    property color colSuffix: Appearance.m3colors.m3onSurfaceVariant
    property color colDateDot: Appearance.m3colors.m3outline
    property color colDateW: Appearance.m3colors.m3primary
    property color colDateN: Appearance.m3colors.m3tertiary
    property bool interactionsEnabled: true
    property bool expanded: false
    property string systemTime: DateTime.time
    
    property bool enableAnimations: Config.options.appearance.enableAnimations

    readonly property string hoursStr: {
        var parts = (systemTime || "").split(":")
        return parts.length >= 1 ? parts[0] : ""
    }
    readonly property string minutesStr: {
        var parts = (systemTime || "").split(":")
        return parts.length >= 2 ? parts[1].substring(0, 2) : ""
    }
    readonly property string timeSuffix:
        (systemTime || "").replace(hoursStr + ":" + minutesStr, "")
                           .replace(/\./g, "")
                           .trim()
    readonly property string paddedHours:
        hoursStr.length === 1 ? "0" + hoursStr : (hoursStr || "00")
    readonly property string h1: paddedHours.substring(0, 1)
    readonly property string h2: paddedHours.substring(1, 2)
    readonly property string paddedMinutes: minutesStr.padStart(2, "0")
    readonly property string m1: paddedMinutes.substring(0, 1)
    readonly property string m2: paddedMinutes.substring(1, 2)
    property string currentSeconds: Qt.formatTime(new Date(), "ss")
    readonly property string s1: currentSeconds.substring(0, 1)
    readonly property string s2: currentSeconds.substring(1, 2)

    readonly property string dateWeekdayStr:
        Qt.locale("en_US").toString(new Date(), "dddd")
    readonly property string dateNumericStr: {
        var ld = (DateTime.longDate || "").toString().trim()
        var numeric = ""
        var dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s*,\s*(.*)$/)
        if (!dm) dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s+(.*)$/)
        if (dm) numeric = (dm[2] || "").toString().trim()
        else numeric = ld.replace(/^[^,]+,?\s*/, "").trim()
        return numeric !== "" ? numeric : Qt.locale("en_US").toString(new Date(), "MM/dd")
    }

    Timer {
        interval: 1000
        running: root.enableAnimations 
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentSeconds = Qt.formatTime(new Date(), "ss")
    }

    implicitWidth: root.vertical
        ? Appearance.sizes.verticalBarWidth
        : (contentRow.implicitWidth + 24)
    implicitHeight: root.vertical
        ? (contentRow.implicitHeight + 12)
        : Appearance.sizes.barHeight

    hoverEnabled: true
    preventStealing: true 
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: (mouse) => {
        if (!root.interactionsEnabled) return;

        if (mouse.button === Qt.LeftButton) {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            if (GlobalStates.mediaControlsOpen) Notifications.timeoutAll();
        }
        else if (mouse.button === Qt.RightButton) {
            root.expanded = !root.expanded;
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        RowLayout {
            spacing: 2
            StyledText { text: root.h1; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.large * 1.30; font.weight: Font.Black; color: root.colH1 }
            StyledText { text: root.h2; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.large * 1.30; font.weight: Font.Black; color: root.colH2 }
            StyledText {
                text: ":"
                font.family: "Anton"
                font.pixelSize: Appearance.font.pixelSize.large * 1.25
                font.weight: Font.Black
                color: root.colPuntos
                leftPadding: 2
                rightPadding: 2
            }
            StyledText { text: root.m1; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.large * 1.25; font.weight: Font.Black; color: root.colM1 }
            StyledText { text: root.m2; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.large * 1.25; font.weight: Font.Black; color: root.colM2 }
        }

        RowLayout {
            spacing: 2
            visible: root.enableAnimations 
            StyledText { text: root.s1; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.normal * 0.95; font.weight: Font.Black; color: root.colS1; leftPadding: 4 }
            StyledText { text: root.s2; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.normal * 0.95; font.weight: Font.Black; color: root.colS2 }
            StyledText {
                visible: root.timeSuffix !== ""
                text: root.timeSuffix
                font.family: "Anton"
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Black
                color: root.colSuffix
                opacity: 0.8
                leftPadding: 4
            }
        }

        RowLayout {
            visible: root.expanded
            spacing: 4
            StyledText { text: "•"; font.family: "Anton"; font.pixelSize: Appearance.font.pixelSize.normal; color: root.colDateDot }
            StyledText {
                visible: !root.vertical
                text: root.dateWeekdayStr
                font.family: "Anton"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.colDateW
            }
            StyledText {
                text: root.vertical
                      ? Qt.locale("en_US").toString(new Date(), "MM/dd")
                      : root.dateNumericStr
                font.family: "Anton"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.colDateN
            }
        }
    }
}
