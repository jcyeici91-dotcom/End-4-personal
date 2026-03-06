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
    property bool forceNoContainer: false

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)
    readonly property color smartTextColor: themeIsDark ? "#FFFFFF" : "#1A1A1A"
    readonly property color smartShadowColor: themeIsDark ? Qt.rgba(0,0,0,0.0) : Qt.rgba(1,1,1,0.0)
    readonly property real basePillAlpha: themeIsDark ? 0.26 : 0.15

    property bool borderless: Config.options.bar.borderless
    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false
    property bool tactileFeedback: true
    property bool islandMotionEnabled: false
    property bool breatheEnabled: false
    property bool secondsPulseEnabled: false

    property int pillRadius: 999
    property int pillPadH: 14
    property int pillPadV: 8
    property int pillGap: 8
    property int timeColonGap: 2
    property int expandedGap: 0
    property int dividerSideMargin: 0

    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary
    property color textColor: root.smartTextColor

    readonly property int barH: Math.max(24, Math.floor(Appearance.sizes.barHeight))
    readonly property real barT: {
        var t = (barH - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    readonly property real pillAlphaIdle: root.basePillAlpha + (0.02 * barT)
    readonly property real pillAlphaHover: (root.basePillAlpha + 0.10) + (0.06 * barT)

    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    property string systemTime: DateTime.time

    readonly property string timeNumbers: {
        var str = systemTime || ""
        var parts = str.split(":")
        if (parts.length >= 2) {
            var hours = parts[0]
            var minutes = parts[1].substring(0, 2)
            if (/^\d{1,2}$/.test(hours) && /^\d{2}$/.test(minutes)) {
                return hours + ":" + minutes
            }
        }
        return str
    }

    readonly property string timeSuffix: (systemTime || "").replace(timeNumbers, "").replace(/\./g, "").trim()

    property string currentSeconds: Qt.formatTime(new Date(), "ss")

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.currentSeconds = Qt.formatTime(new Date(), "ss")
    }

    function _dateWithFullWeekday() {
        if (root.vertical) {
            return Qt.locale("en_US").toString(new Date(), "MM/dd")
        }
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
    implicitHeight: root.vertical ? (contentRow.implicitHeight + 24) : Appearance.sizes.barHeight

    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.expanded ? root.expandedGap : root.pillGap

            component TonalPillBg: Rectangle {
                required property color tonal
                visible: !root.forceNoContainer
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                radius: root.pillRadius
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root._rgba(tonal, root.pillAlphaIdle + 0.04) }
                    GradientStop { position: 1.0; color: root._rgba(tonal, root.pillAlphaIdle) }
                }
                border.width: 1
                border.color: Qt.rgba(
                    root.themeIsDark ? 1 : 0,
                    root.themeIsDark ? 1 : 0,
                    root.themeIsDark ? 1 : 0,
                    0.12
                )
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: root.timeColonGap

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: pillTimeRow.implicitWidth + (root.pillPadH * 2)
                    implicitHeight: Math.round(Appearance.font.pixelSize.large + (root.pillPadV * 2))
                    transformOrigin: Item.Center
                    TonalPillBg { anchors.fill: parent; tonal: root.tonalTime }

                    RowLayout {
                        id: pillTimeRow
                        anchors.centerIn: parent
                        spacing: 0
                        StyledText {
                            text: root.timeNumbers
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.bold: true
                            font.weight: Font.Bold
                            font.features: ({ "tnum": 1 })
                            color: root.smartTextColor
                            opacity: 0.95
                            Layout.alignment: Qt.AlignVCenter
                            renderType: Text.NativeRendering
                            layer.enabled: false
                        }
                    }
                }

                StyledText {
                    text: ":"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: root.smartTextColor
                    opacity: 0.94
                    Layout.alignment: Qt.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: pillSecRow.implicitWidth + (root.pillPadH * 2)
                implicitHeight: Math.round(Appearance.font.pixelSize.large + (root.pillPadV * 2))
                transformOrigin: Item.Center
                TonalPillBg { anchors.fill: parent; tonal: root.tonalSec }

                RowLayout {
                    id: pillSecRow
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        text: root.currentSeconds
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        color: root.smartTextColor
                        Layout.alignment: Qt.AlignVCenter
                        opacity: 0.95
                        renderType: Text.NativeRendering
                    }

                    Item { visible: root.timeSuffix !== ""; implicitWidth: 7; implicitHeight: 1 }

                    StyledText {
                        visible: root.timeSuffix !== ""
                        text: root.timeSuffix
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.bold: true
                        font.weight: Font.Bold
                        color: root.smartTextColor
                        opacity: 0.86
                        Layout.alignment: Qt.AlignVCenter
                        renderType: Text.NativeRendering
                    }
                }
            }

            StyledText {
                visible: root.expanded
                text: "•"
                font.pixelSize: Appearance.font.pixelSize.large
                color: root.themeIsDark ? Appearance.colors.colOnLayer1Variant : "#444444"
                Layout.leftMargin: root.dividerSideMargin
                Layout.rightMargin: root.dividerSideMargin
                Layout.alignment: Qt.AlignVCenter
                renderType: Text.NativeRendering
                opacity: visible ? 1 : 0
            }

            Item {
                visible: root.expanded
                opacity: visible ? 1 : 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: pillDateRow.implicitWidth + (root.pillPadH * 2)
                implicitHeight: Math.round(Appearance.font.pixelSize.normal + (root.pillPadV * 2))
                transformOrigin: Item.Center
                TonalPillBg { anchors.fill: parent; tonal: root.tonalDate }

                RowLayout {
                    id: pillDateRow
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        text: root._dateWithFullWeekday()
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.bold: true
                        font.weight: Font.Bold
                        color: root.smartTextColor
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        enabled: root.interactionsEnabled

        onClicked: (event) => {
            if (!root.interactionsEnabled) { event.accepted = false; return }
            if (event.button === Qt.LeftButton) {
                root.popupOpen = false
                root.expanded = !root.expanded
                event.accepted = true
                return
            }
            if (event.button === Qt.RightButton) {
                root.popupOpen = true
                event.accepted = true
                return
            }
        }

        onDoubleClicked: (event) => {
            if (!root.interactionsEnabled) return
            if (event.button === Qt.LeftButton) openCalendar.running = true
        }
    }

    Loader {
        active: root.interactionsEnabled && root.popupOpen
        sourceComponent: ClockWidgetPopup { hoverTarget: mouseArea }
    }
}
