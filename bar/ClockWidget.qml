pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =====================================================
    // 1) FLAGS / API
    // =====================================================
    property bool borderless: Config.options.bar.borderless

    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false

    // No brillo nunca
    property bool enableSheen: false
    property bool tactileFeedback: true

    // =====================================================
    // 2) SHAPE / SPACING
    // =====================================================
    property int pillRadius: 999
    property int pillPadH: 14
    property int pillPadV: 8
    property int pillGap: 8
    property int timeColonGap: 2

    // =====================================================
    // 3) TONAL COLORS
    // =====================================================
    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary
    property color textColor: Appearance.colors.colOnLayer1

    // =====================================================
    // 4) ADAPTIVE TUNING (barHeight 30..50)
    // =====================================================
    readonly property int barH: Math.max(24, Math.floor(Appearance.sizes.barHeight))
    readonly property real barT: {
        var t = (barH - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    // Pills: mate, sin “flash” al click
    readonly property real pillAlphaIdle: 0.26 + (0.02 * barT)        // 0.26..0.28
    readonly property real pillAlphaHover: 0.36 + (0.06 * barT)       // 0.36..0.42

    readonly property real pillBorderAlphaIdle: 0.10 + (0.03 * barT)  // 0.10..0.13
    readonly property real pillBorderAlphaHover: 0.16 + (0.05 * barT) // 0.16..0.21
    readonly property real pillInnerHighlightAlpha: 0.05 + (0.03 * barT)

    readonly property real pillShadowAlphaIdle: 0.08 + (0.04 * barT)
    readonly property real pillShadowAlphaHover: 0.12 + (0.05 * barT)

    readonly property real pillGradientLift: 0.045 + (0.020 * barT)

    // =====================================================
    // 4.5) ISLAND-LIKE MOTION (solo transform, nada de brillo)
    // =====================================================
    property bool islandMotionEnabled: true
    property real islandStretchX: 1.0 // estiramiento horizontal sutil al expandir/colapsar

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

        // Reset suave por si quedó en medio
        NumberAnimation {
            target: root
            property: "islandStretchX"
            to: 1.0
            duration: 0
        }

        // micro overshoot
        NumberAnimation {
            target: root
            property: "islandStretchX"
            to: islandStretchAnim.expanding
                ? (1.010 + 0.008 * root.barT)     // 1.010..1.018
                : (0.992 - 0.004 * root.barT)     // 0.992..0.988
            duration: 95
            easing.type: Easing.OutCubic
        }

        // settle
        NumberAnimation {
            target: root
            property: "islandStretchX"
            to: 1.0
            duration: 165
            easing.type: Easing.OutCubic
        }
    }

    // =====================================================
    // 5) HOVER (desde MouseArea) + helpers
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
    // 6) BREATHING (sutil; se pausa en popup)
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

    function _dateWithFullWeekday() {
        var ld = (DateTime.longDate || "").toString().trim()
        var numeric = ""

        var dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s*,\s*(.*)$/)
        if (!dm) dm = ld.match(/^([A-Za-zÀ-ÿ.\u00C0-\u017F]+)\s+(.*)$/)

        if (dm)
            numeric = (dm[2] || "").toString().trim()
        else
            numeric = ld.replace(/^[^,]+,?\s*/, "").trim()

        var enWeekday = Qt.locale("en_US").toString(new Date(), "dddd")
        return (numeric !== "") ? (enWeekday + " " + numeric) : enWeekday
    }

    Process { id: openCalendar; command: ["gnome-calendar"] }

    // =====================================================
    // 8) SIZE / LAYOUT
    // =====================================================
    property real contentScale: 1.0
    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: Appearance.sizes.barHeight

    // Mantengo esto porque es tu “como estaba”.
    // Le cambio easing a OutCubic para que no se sienta “pausado”.
    Behavior on implicitWidth {
        enabled: true
        NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // 9) BACKPLATE: SIEMPRE TRANSPARENTE (sin brillo)
    // =====================================================
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: 12
        color: "transparent"
        border.width: 0
        visible: false
    }

    // =====================================================
    // 10) CONTENT
    // =====================================================
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

        // Anti-pixelado al escalar: render a texture con AA
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        // Transform: scale normal + stretch X tipo “isla”
        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.contentScale * root.islandStretchX
            yScale: root.contentScale
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.pillGap

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

            // --- Time + colon
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: root.timeColonGap

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: pillTimeRow.implicitWidth + (root.pillPadH * 2)
                    implicitHeight: Math.round(Appearance.font.pixelSize.large + (root.pillPadV * 2))

                    scale: root._breatheRunning ? root.breatheScaleTime : 1.0
                    transformOrigin: Item.Center

                    TonalPillBg { anchors.fill: parent; tonal: root.tonalTime; breatheExtra: root.breatheTimeExtra }

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
                            color: root.textColor
                            opacity: 0.95
                            Layout.alignment: Qt.AlignVCenter

                            // mejor legibilidad, sin “pixeleo”
                            renderType: Text.NativeRendering

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 0.50
                                shadowOpacity: 0.22
                                shadowVerticalOffset: 1
                            }
                        }
                    }
                }

                StyledText {
                    text: ":"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: root.textColor
                    opacity: 0.94
                    Layout.alignment: Qt.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            // --- Seconds pill
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: pillSecRow.implicitWidth + (root.pillPadH * 2)
                implicitHeight: Math.round(Appearance.font.pixelSize.large + (root.pillPadV * 2))

                scale: root._breatheRunning ? root.breatheScaleSec : 1.0
                transformOrigin: Item.Center

                TonalPillBg { anchors.fill: parent; tonal: root.tonalSec; breatheExtra: root.breatheSecExtra }

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
                        color: root.textColor
                        Layout.alignment: Qt.AlignVCenter
                        opacity: root.secondsPulseEnabled ? root.secondsPulseOpacity : 0.95
                        renderType: Text.NativeRendering
                    }

                    Item { visible: root.timeSuffix !== ""; implicitWidth: 7; implicitHeight: 1 }

                    StyledText {
                        visible: root.timeSuffix !== ""
                        text: root.timeSuffix
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.bold: true
                        font.weight: Font.Bold
                        color: root.textColor
                        opacity: 0.86
                        Layout.alignment: Qt.AlignVCenter
                        renderType: Text.NativeRendering
                    }
                }
            }

            // --- Divider + Date (como lo tenías)
            StyledText {
                visible: root.expanded
                opacity: visible ? 1 : 0
                text: "•"
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1Variant
                Layout.leftMargin: 6
                Layout.rightMargin: 2
                Layout.alignment: Qt.AlignVCenter
                Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                renderType: Text.NativeRendering
            }

            Item {
                visible: root.expanded
                opacity: visible ? 1 : 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: pillDateRow.implicitWidth + (root.pillPadH * 2)
                implicitHeight: Math.round(Appearance.font.pixelSize.normal + (root.pillPadV * 2))

                Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

                scale: root._breatheRunning
                    ? (1.0 + (root.breathTimeSigned * (root.breatheScaleStrength * 0.28)))
                    : 1.0
                transformOrigin: Item.Center

                TonalPillBg { anchors.fill: parent; tonal: root.tonalDate; breatheExtra: root.breatheDateExtra }

                RowLayout {
                    id: pillDateRow
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        text: root._dateWithFullWeekday()
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.bold: true
                        font.weight: Font.Bold
                        color: root.textColor
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    // =====================================================
    // 11) TACTILE SQUISH (solo escala, sin flash)
    // =====================================================
    SequentialAnimation {
        id: clickSquish
        running: false
        NumberAnimation { target: root; property: "contentScale"; to: 0.965; duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "contentScale"; to: 1.020; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "contentScale"; to: 1.000; duration: 190; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // 12) INPUT (MouseArea) — popup arreglado
    // =====================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        enabled: root.interactionsEnabled

        onClicked: (event) => {
            if (!root.interactionsEnabled) {
                event.accepted = false
                return
            }

            if (root.tactileFeedback) clickSquish.restart()

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
            if (root.tactileFeedback) clickSquish.restart()
            if (event.button === Qt.LeftButton) openCalendar.running = true
        }
    }

    // =====================================================
    // 13) POPUP (FIX: pasa MouseArea real)
    // =====================================================
    Loader {
        active: root.interactionsEnabled && root.popupOpen
        sourceComponent: ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}

