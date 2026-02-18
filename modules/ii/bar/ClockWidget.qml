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

    // =====================================================
    // 1) THEME (igual)
    // =====================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property color smartTextColor: themeIsDark ? "#FFFFFF" : "#1A1A1A"
    readonly property color smartShadowColor: themeIsDark ? Qt.rgba(0,0,0,0.0) : Qt.rgba(1,1,1,0.0) // PERF: no sombra
    readonly property real basePillAlpha: themeIsDark ? 0.26 : 0.15

    // =====================================================
    // 2) FLAGS
    // =====================================================
    property bool borderless: Config.options.bar.borderless
    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false
    property bool tactileFeedback: true

    // PERF: desactiva animaciones “ambientales”
    property bool islandMotionEnabled: false
    property bool breatheEnabled: false
    property bool secondsPulseEnabled: false

    // =====================================================
    // 3) SHAPE / SPACING
    // =====================================================
    property int pillRadius: 999
    property int pillPadH: 14
    property int pillPadV: 8
    property int pillGap: 8
    property int timeColonGap: 2

    // =====================================================
    // 4) COLORS
    // =====================================================
    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary
    property color textColor: root.smartTextColor

    // =====================================================
    // 5) ADAPTIVE TUNING (se queda, es barato)
    // =====================================================
    readonly property int barH: Math.max(24, Math.floor(Appearance.sizes.barHeight))
    readonly property real barT: {
        var t = (barH - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    readonly property real pillAlphaIdle: root.basePillAlpha + (0.02 * barT)
    readonly property real pillAlphaHover: (root.basePillAlpha + 0.10) + (0.06 * barT)

    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // =====================================================
    // 6) TIME MODEL
    // =====================================================
    property string systemTime: DateTime.time
    readonly property string timeNumbers: {
        var m = (systemTime || "").match(/^(\d{1,2}:\d{2})/)
        return m ? m[1] : (systemTime || "")
    }
    readonly property string timeSuffix: (systemTime || "").replace(timeNumbers, "").replace(/\./g, "").trim()
    property string currentSeconds: Qt.formatTime(new Date(), "ss")

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.currentSeconds = Qt.formatTime(new Date(), "ss")
    }

    function _dateWithFullWeekday() {
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

    // =====================================================
    // 7) SIZE / LAYOUT  (PERF: sin animación de ancho)
    // =====================================================
    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: Appearance.sizes.barHeight

    // =====================================================
    // 8) CONTENT
    // =====================================================
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center
        // PERF: nada de layer.enabled ni effects
        // layer.enabled: false

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.pillGap

            // --- PILL BACKGROUND (PERF: sin efectos, sin sombra) ---
            component TonalPillBg: Rectangle {
                required property color tonal
                radius: root.pillRadius
                antialiasing: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: root._rgba(tonal, root.pillAlphaIdle + 0.04) }
                    GradientStop { position: 1.0; color: root._rgba(tonal, root.pillAlphaIdle) }
                }

                border.width: 1
                border.color: Qt.rgba(root.themeIsDark ? 1 : 0, root.themeIsDark ? 1 : 0, root.themeIsDark ? 1 : 0, 0.12)

                // PERF: sin layer.effect, sin samples
            }

            // --- TIME PILL ---
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
                            // PERF: sin layer.effect de sombra
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

            // --- SECONDS PILL ---
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

            // --- DIVIDER ---
            StyledText {
                visible: root.expanded
                text: "•"
                font.pixelSize: Appearance.font.pixelSize.large
                color: root.themeIsDark ? Appearance.colors.colOnLayer1Variant : "#444444"
                Layout.leftMargin: 6
                Layout.rightMargin: 2
                Layout.alignment: Qt.AlignVCenter
                renderType: Text.NativeRendering
                // PERF: sin animación de opacity
                opacity: visible ? 1 : 0
            }

            // --- DATE PILL ---
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

    // =====================================================
    // 9) INPUT (igual)
    // =====================================================
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

