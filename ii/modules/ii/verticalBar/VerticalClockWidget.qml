pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar as Bar

Item {
    id: root

    // =====================================================
    // 1) FLAGS / API
    // =====================================================
    property bool borderless: Config.options.bar.borderless
    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false
    property bool tactileFeedback: true

    // =====================================================
    // 2) BAR WIDTH (Settings: 30..50) + AUTO-ADAPT
    // =====================================================
    readonly property int barW: Math.floor(Appearance.sizes.verticalBarWidth)

    // Normalize width in [0..1] based on settings range 30..50
    readonly property real barWT: {
        var t = (barW - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    function lerp(a, b, t) { return a + (b - a) * t }
    function lerpI(a, b, t) { return Math.round(lerp(a, b, t)) }
    function clampI(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    // Auto margins/padding/gap based on width (30 -> compact, 50 -> roomy)
    readonly property int sideMargin: lerpI(3, 6, barWT)
    readonly property int pillPadH: lerpI(5, 9, barWT)
    readonly property int pillPadV: lerpI(5, 8, barWT)
    readonly property int pillGap: lerpI(5, 8, barWT)
    readonly property int pillRadius: 999

    // Font sizing derived from bar width so it always fits
    readonly property int baseTimePx: clampI(lerpI(14, 20, barWT), 12, 22)
    readonly property int suffixPx: clampI(lerpI(9, 11, barWT), 8, 12)
    readonly property int datePx: clampI(lerpI(10, 13, barWT), 9, 14)

    // =====================================================
    // 3) TONAL COLORS
    // =====================================================
    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary
    property color textColor: Appearance.colors.colOnLayer1

    // =====================================================
    // 4) ADAPTIVE (kept as-is; used for alpha/animations)
    // =====================================================
    readonly property int barH: Math.max(24, Math.floor(Appearance.sizes.baseBarHeight ?? Appearance.sizes.barHeight))
    readonly property real barT: {
        var t = (barH - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    readonly property real pillAlphaIdle: 0.26 + (0.02 * barT)
    readonly property real pillAlphaHover: 0.36 + (0.06 * barT)

    readonly property real pillBorderAlphaIdle: 0.10 + (0.03 * barT)
    readonly property real pillBorderAlphaHover: 0.16 + (0.05 * barT)
    readonly property real pillInnerHighlightAlpha: 0.05 + (0.03 * barT)

    readonly property real pillShadowAlphaIdle: 0.08 + (0.04 * barT)
    readonly property real pillShadowAlphaHover: 0.12 + (0.05 * barT)

    readonly property real pillGradientLift: 0.045 + (0.020 * barT)

    // =====================================================
    // 4.5) ISLAND-LIKE MOTION (Y)
    // =====================================================
    property bool islandMotionEnabled: true
    property real islandStretchY: 1.0

    function _kickIsland(expanding) {
        if (!root.islandMotionEnabled || !root.interactionsEnabled) return
        islandStretchAnim.stop()
        islandStretchAnim.expanding = expanding
        islandStretchAnim.restart()
    }
    onExpandedChanged: _kickIsland(root.expanded)

    SequentialAnimation {
        id: islandStretchAnim
        property bool expanding: true

        NumberAnimation { target: root; property: "islandStretchY"; to: 1.0; duration: 0 }

        NumberAnimation {
            target: root
            property: "islandStretchY"
            to: islandStretchAnim.expanding
                ? (1.010 + 0.008 * root.barT)
                : (0.992 - 0.004 * root.barT)
            duration: 95
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "islandStretchY"
            to: 1.0
            duration: 165
            easing.type: Easing.OutCubic
        }
    }

    // =====================================================
    // 5) HOVER + helpers
    // =====================================================
    readonly property bool isHovered: mouseArea.containsMouse
    property real hoverAmount: isHovered ? 1.0 : 0.0
    Behavior on hoverAmount {
        enabled: root.interactionsEnabled
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    readonly property bool activeState: root.expanded || root.popupOpen
    readonly property real stateAmount: Math.max(hoverAmount, activeState ? 1.0 : 0.0)

    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function _mix(a, b, t) { return a + (b - a) * t }
    function _a(idleA, hoverA) { return _mix(idleA, hoverA, stateAmount) }

    // =====================================================
    // 6) BREATHING (pauses when popup open)
    // =====================================================
    property bool breatheEnabled: true
    property real breathePhase: 0.0
    readonly property bool _breatheRunning: breatheEnabled && !popupOpen

    readonly property int breatheCycleMs: Math.round(2700 + 500 * barT)
    readonly property real breatheStrength: 0.020 + (0.010 * barT)
    readonly property real breatheScaleStrength: 0.0055 + (0.0020 * barT)

    function _ease01(t) {
        return 0.5 + 0.5 * Math.sin((t * 2.0 * Math.PI) - (Math.PI / 2.0))
    }
    function _signed(t) { return (_ease01(t) - 0.5) * 2.0 }

    readonly property real breathTime01: _ease01(breathePhase)
    readonly property real breathSec01: _ease01((breathePhase + 0.50) % 1.0)
    readonly property real breathTimeSigned: _signed(breathePhase)
    readonly property real breathSecSigned: _signed((breathePhase + 0.50) % 1.0)

    readonly property real breatheScaleTime: 1.0 + (breathTimeSigned * breatheScaleStrength)
    readonly property real breatheScaleSec: 1.0 + (breathSecSigned * breatheScaleStrength)

    readonly property real breatheTimeExtra: breathTime01 * breatheStrength
    readonly property real breatheSecExtra: breathSec01 * breatheStrength
    readonly property real breatheDateExtra: breatheTimeExtra * 0.80

    NumberAnimation on breathePhase {
        from: 0.0
        to: 1.0
        duration: root.breatheCycleMs
        loops: Animation.Infinite
        running: root._breatheRunning
        easing.type: Easing.InOutSine
    }

    // =====================================================
    // 7) TIME MODEL
    // =====================================================
    property string systemTime: DateTime.time

    readonly property string timeNumbers: {
        var m = (systemTime || "").match(/^(\d{1,2}:\d{2})/)
        return m ? m[1] : (systemTime || "")
    }

    readonly property string timeSuffix: (systemTime || "")
        .replace(timeNumbers, "")
        .replace(/\./g, "")
        .trim()

    readonly property string timeHH: {
        var parts = (timeNumbers || "").split(":")
        return parts.length >= 1 ? parts[0] : ""
    }
    readonly property string timeMM: {
        var parts = (timeNumbers || "").split(":")
        return parts.length >= 2 ? parts[1] : ""
    }

    readonly property bool isLikely12h: root.timeSuffix !== ""
    readonly property bool hourIsSingleDigit: (root.timeHH.length === 1)

    // Make hour slightly bigger for 12h single digit, but keep it bounded by width
    readonly property int hourPx: (root.isLikely12h && root.hourIsSingleDigit)
        ? clampI(root.baseTimePx + lerpI(2, 4, barWT), 12, 24)
        : root.baseTimePx
    readonly property int minPx: root.baseTimePx

    property string currentSeconds: Qt.formatTime(new Date(), "ss")

    // Seconds pulse
    property bool secondsPulseEnabled: true
    property real secondsPulsePhase: 0.0
    readonly property int secondsPulseMs: Math.round(1950 + 350 * barT)
    readonly property real secondsPulseOpacity: {
        var t = _ease01(secondsPulsePhase)
        return 0.72 + (0.96 - 0.72) * t
    }

    NumberAnimation on secondsPulsePhase {
        from: 0.0
        to: 1.0
        duration: root.secondsPulseMs
        loops: Animation.Infinite
        running: root.secondsPulseEnabled && !root.popupOpen
        easing.type: Easing.InOutSine
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentSeconds = Qt.formatTime(new Date(), "ss")
    }

    // Date short from DateTime.longDate (reacts to Settings)
    function _pad2(n) { return (n < 10 ? "0" : "") + n }
    function _shortNumericFromLongDate() {
        var ld = (DateTime.longDate || "").toString().trim()
        var m = ld.match(/(\d{1,2})\s*([\/\-.])\s*(\d{1,2})/)
        if (m) {
            var a = _pad2(parseInt(m[1], 10))
            var b = _pad2(parseInt(m[3], 10))
            return a + "/" + b
        }
        return Qt.locale().toString(new Date(), "dd/MM")
    }
    readonly property string shortDate: _shortNumericFromLongDate()

    Process { id: openCalendar; command: ["gnome-calendar"] }

    // =====================================================
    // 8) SIZE
    // =====================================================
    property real contentScale: 1.0
    implicitWidth: root.barW
    implicitHeight: contentColumn.implicitHeight + (root.sideMargin * 2)

    // =====================================================
    // 8.5) POPUP: helpers + close on app focus loss
    // =====================================================
    function closePopup() { root.popupOpen = false }
    function openPopup() { root.popupOpen = true }

    Connections {
        target: Qt.application
        function onActiveChanged() {
            if (!Qt.application.active && root.popupOpen) root.closePopup()
        }
    }

    focus: true
    Keys.onEscapePressed: (event) => {
        if (root.popupOpen) {
            root.closePopup()
            event.accepted = true
        }
    }

    // =====================================================
    // 9) CONTENT
    // =====================================================
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.sideMargin
        transformOrigin: Item.Center

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.contentScale
            yScale: root.contentScale * root.islandStretchY
        }

        component TonalPillBg: Rectangle {
            required property color tonal
            required property real breatheExtra
            radius: root.pillRadius
            antialiasing: true

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root._rgba(
                        tonal,
                        root._a(root.pillAlphaIdle, root.pillAlphaHover)
                        + root.pillGradientLift
                        + breatheExtra
                    )
                }
                GradientStop {
                    position: 1.0
                    color: root._rgba(
                        tonal,
                        root._a(root.pillAlphaIdle, root.pillAlphaHover)
                        + (breatheExtra * 0.55)
                    )
                }
            }

            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root._a(root.pillBorderAlphaIdle, root.pillBorderAlphaHover))
            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            layer.enabled: true
            layer.smooth: true
            layer.samples: 4
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: root._a(root.pillShadowAlphaIdle, root.pillShadowAlphaHover) + (breatheExtra * 0.55)
                shadowBlur: 0.7 + (breatheExtra * 8.0)
                shadowVerticalOffset: 1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, root.pillInnerHighlightAlpha)
                antialiasing: true
            }
        }

        // Helper: enforce true centering inside Layouts
        component CenteredText: StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            // remove any internal padding that can bias the glyph box
            leftPadding: 0
            rightPadding: 0
        }

        ColumnLayout {
            id: contentColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: root.pillGap

            // --- TIME pill
            Item {
                id: timePill
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                implicitHeight: timeStack.implicitHeight + (root.pillPadV * 2)

                scale: root._breatheRunning ? root.breatheScaleTime : 1.0
                transformOrigin: Item.Center

                TonalPillBg { anchors.fill: parent; tonal: root.tonalTime; breatheExtra: root.breatheTimeExtra }

                ColumnLayout {
                    id: timeStack
                    anchors.centerIn: parent
                    width: parent.width - (root.pillPadH * 2)
                    spacing: 0

                    CenteredText {
                        text: root.timeHH
                        font.pixelSize: root.hourPx
                        font.bold: true
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        color: root.textColor
                        opacity: 0.95
                        renderType: Text.NativeRendering

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 0.50
                            shadowOpacity: 0.22
                            shadowVerticalOffset: 1
                        }
                    }

                    CenteredText {
                        text: root.timeMM
                        font.pixelSize: root.minPx
                        font.bold: true
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        color: root.textColor
                        opacity: 0.95
                        renderType: Text.NativeRendering
                    }

                    CenteredText {
                        visible: root.timeSuffix !== ""
                        text: root.timeSuffix
                        font.pixelSize: root.suffixPx
                        font.bold: true
                        font.weight: Font.Bold
                        color: root.textColor
                        opacity: 0.82
                        renderType: Text.NativeRendering
                    }
                }

                // Right-click ONLY on the hour pill toggles popup
                MouseArea {
                    id: timeRightClickArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    preventStealing: true
                    enabled: root.interactionsEnabled

                    onClicked: (event) => {
                        if (event.button !== Qt.RightButton) return
                        root.popupOpen = !root.popupOpen
                        root.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            // --- SECONDS pill
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                implicitHeight: secRow.implicitHeight + (root.pillPadV * 2)

                scale: root._breatheRunning ? root.breatheScaleSec : 1.0
                transformOrigin: Item.Center

                TonalPillBg { anchors.fill: parent; tonal: root.tonalSec; breatheExtra: root.breatheSecExtra }

                RowLayout {
                    id: secRow
                    anchors.centerIn: parent
                    width: parent.width - (root.pillPadH * 2)
                    spacing: 0

                    CenteredText {
                        text: root.currentSeconds
                        font.pixelSize: root.baseTimePx
                        font.bold: true
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        color: root.textColor
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        opacity: root.secondsPulseEnabled ? root.secondsPulseOpacity : 0.95
                        renderType: Text.NativeRendering
                    }
                }
            }

            // --- DATE pill (expand)
            Item {
                visible: root.expanded
                opacity: visible ? 1 : 0
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                implicitHeight: dateText.implicitHeight + (root.pillPadV * 2)

                Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

                scale: root._breatheRunning
                    ? (1.0 + (root.breathTimeSigned * (root.breatheScaleStrength * 0.28)))
                    : 1.0
                transformOrigin: Item.Center

                TonalPillBg { anchors.fill: parent; tonal: root.tonalDate; breatheExtra: root.breatheDateExtra }

                CenteredText {
                    id: dateText
                    anchors.centerIn: parent
                    // keep your padding behavior exactly the same:
                    width: parent.width - (root.pillPadH * 2)

                    text: root.shortDate
                    font.pixelSize: root.datePx
                    font.bold: true
                    font.weight: Font.Bold
                    color: root.textColor
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    // =====================================================
    // 10) POPUP (Loader so it never gets “stuck”)
    // =====================================================
    Loader {
        id: popupLoader
        active: root.interactionsEnabled && root.popupOpen
        sourceComponent: Bar.ClockWidgetPopup {
            hoverTarget: timeRightClickArea
        }
    }

    // =====================================================
    // 11) TACTILE SQUISH
    // =====================================================
    SequentialAnimation {
        id: clickSquish
        running: false
        NumberAnimation { target: root; property: "contentScale"; to: 0.965; duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "contentScale"; to: 1.020; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "contentScale"; to: 1.000; duration: 190; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // 12) INPUT (global): left click toggles expand anywhere
    //     + if popup open: left click closes only
    // =====================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        preventStealing: true
        enabled: root.interactionsEnabled

        onClicked: (event) => {
            if (!root.interactionsEnabled) {
                event.accepted = false
                return
            }

            if (root.tactileFeedback) clickSquish.restart()

            if (root.popupOpen) {
                root.closePopup()
                event.accepted = true
                return
            }

            root.expanded = !root.expanded
            event.accepted = true
        }

        onDoubleClicked: (event) => {
            if (!root.interactionsEnabled) return
            if (root.tactileFeedback) clickSquish.restart()
            if (event.button === Qt.LeftButton) openCalendar.running = true
        }
    }

    // =====================================================
    // 13) RIGHT CLICK outside hour pill closes popup
    // =====================================================
    MouseArea {
        id: closePopupCatcher
        anchors.fill: parent
        enabled: root.interactionsEnabled && root.popupOpen
        acceptedButtons: Qt.RightButton
        hoverEnabled: true
        z: 9999
        propagateComposedEvents: true

        onClicked: (event) => {
            if (!timeRightClickArea.containsMouse) {
                root.closePopup()
                event.accepted = true
            } else {
                event.accepted = false
            }
        }
    }
}

