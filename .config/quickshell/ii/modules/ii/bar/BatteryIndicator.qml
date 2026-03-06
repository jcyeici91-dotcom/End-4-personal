pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool vertical: false
    property bool forceNoContainer: true 

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)
    
    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary

    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false

    property string systemTime: DateTime.time

    readonly property string hoursStr: {
        var str = systemTime || ""
        var parts = str.split(":")
        return parts.length >= 1 ? parts[0] : ""
    }

    readonly property string minutesStr: {
        var str = systemTime || ""
        var parts = str.split(":")
        return parts.length >= 2 ? parts[1].substring(0, 2) : ""
    }

    readonly property string timeSuffix: (systemTime || "").replace(hoursStr + ":" + minutesStr, "").replace(/\./g, "").trim()
    property string currentSeconds: Qt.formatTime(new Date(), "ss")

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.currentSeconds = Qt.formatTime(new Date(), "ss")
    }

    function _dateWithFullWeekday() {
        if (root.vertical) return Qt.locale("en_US").toString(new Date(), "MM/dd")
        var ld = (DateTime.longDate || "").toString().trim()
        var numeric = ""
        var dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s*,\s*(.*)$/)
        if (!dm) dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s+(.*)$/)
        if (dm) numeric = (dm[2] || "").toString().trim()
        else numeric = ld.replace(/^[^,]+,?\s*/, "").trim()
        var enWeekday = Qt.locale("en_US").toString(new Date(), "dddd")
        return (numeric !== "") ? (enWeekday + " " + numeric) : enWeekday
    }

    Process { id: openCalendar; command: ["gnome-calendar"] }

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (contentRow.implicitWidth + 24)
    implicitHeight: root.vertical ? (contentRow.implicitHeight + 12) : Appearance.sizes.barHeight

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 16

        RowLayout {
            id: timeGroup
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            StyledText {
                text: root.hoursStr
                font.family: "Archivo Black, Archivo, sans-serif"
                font.pixelSize: Appearance.font.pixelSize.large * 1.5
                font.weight: Font.Black
                font.letterSpacing: -1.5
                color: root.tonalTime
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: ":"
                font.family: "Archivo Black"
                font.pixelSize: Appearance.font.pixelSize.large * 1.2
                font.weight: Font.Black
                color: root.themeIsDark ? "#FFFFFF" : "#1A1A1A"
                opacity: 0.3
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 2
                rightPadding: 2
            }

            StyledText {
                text: root.minutesStr
                font.family: "Archivo Black, Archivo, sans-serif"
                font.pixelSize: Appearance.font.pixelSize.large * 1.1
                font.weight: Font.Black
                font.letterSpacing: -1.0
                color: root.tonalDate 
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignVCenter
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            
            StyledText {
                text: root.currentSeconds
                font.family: "JetBrains Mono, Archivo Black"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                color: root.tonalSec
                opacity: 0.9
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignLeft
            }

            StyledText {
                visible: root.timeSuffix !== ""
                text: root.timeSuffix.toUpperCase()
                font.family: "Archivo Black"
                font.pixelSize: Appearance.font.pixelSize.small * 0.9
                font.weight: Font.Black
                font.letterSpacing: 0.5
                color: root.tonalSec
                opacity: 0.7
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignLeft
            }
        }

        RowLayout {
            visible: root.expanded
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
            
            StyledText {
                text: "•"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Black
                color: root.themeIsDark ? "#44FFFFFF" : "#44000000"
            }

            StyledText {
                text: root._dateWithFullWeekday()
                font.family: "Archivo Black, sans-serif"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                color: root.tonalDate
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) root.expanded = !root.expanded
            else if (event.button === Qt.RightButton) root.popupOpen = true
        }
        onDoubleClicked: (event) => {
            if (event.button === Qt.LeftButton) openCalendar.running = true
        }
    }

    Loader {
        active: root.interactionsEnabled && root.popupOpen
        sourceComponent: ClockWidgetPopup { hoverTarget: mouseArea }
    }
}
