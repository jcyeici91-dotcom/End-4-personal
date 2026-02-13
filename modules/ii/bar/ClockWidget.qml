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
    // 1) DETECCIÓN AUTOMÁTICA DE TEMA (DARK vs LIGHT)
    // =====================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 } // Umbral de oscuridad

    // Detectamos si el fondo del sistema es oscuro
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    // =====================================================
    // 2) COLORES INTELIGENTES (SMART COLORS)
    // =====================================================
    // Texto: Blanco puro en Dark Mode, Negro profundo en Light Mode
    readonly property color smartTextColor: themeIsDark ? "#FFFFFF" : "#1A1A1A"

    // Sombra de texto: Negra en Dark Mode, Blanca (Glow) en Light Mode
    readonly property color smartShadowColor: themeIsDark ? Qt.rgba(0,0,0,0.4) : Qt.rgba(1,1,1,0.6)

    // Opacidad base de las píldoras (Más fuerte en Light Mode para que se noten)
    readonly property real basePillAlpha: themeIsDark ? 0.26 : 0.15

    // =====================================================
    // 3) FLAGS / API
    // =====================================================
    property bool borderless: Config.options.bar.borderless
    property bool interactionsEnabled: true
    property bool expanded: false
    property bool popupOpen: false
    property bool enableSheen: false
    property bool tactileFeedback: true

    // =====================================================
    // 4) SHAPE / SPACING
    // =====================================================
    property int pillRadius: 999
    property int pillPadH: 14
    property int pillPadV: 8
    property int pillGap: 8
    property int timeColonGap: 2

    // =====================================================
    // 5) TONAL COLORS (Adaptados)
    // =====================================================
    property color tonalTime: Appearance.m3colors.m3primary
    property color tonalSec: Appearance.m3colors.m3secondary
    property color tonalDate: Appearance.m3colors.m3tertiary
    // Usamos nuestra propiedad inteligente en lugar de la del sistema
    property color textColor: root.smartTextColor 

    // =====================================================
    // 6) ADAPTIVE TUNING
    // =====================================================
    readonly property int barH: Math.max(24, Math.floor(Appearance.sizes.barHeight))
    readonly property real barT: {
        var t = (barH - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    // Ajuste dinámico de opacidad según el tema
    readonly property real pillAlphaIdle: root.basePillAlpha + (0.02 * barT)
    readonly property real pillAlphaHover: (root.basePillAlpha + 0.10) + (0.06 * barT)

    readonly property real pillBorderAlphaIdle: 0.10 + (0.03 * barT)
    readonly property real pillBorderAlphaHover: 0.16 + (0.05 * barT)
    readonly property real pillInnerHighlightAlpha: 0.05 + (0.03 * barT)

    // Sombras de las Píldoras (más suaves en Light Mode)
    readonly property real pillShadowAlphaIdle: themeIsDark ? (0.08 + (0.04 * barT)) : 0.02
    readonly property real pillShadowAlphaHover: themeIsDark ? (0.12 + (0.05 * barT)) : 0.05

    readonly property real pillGradientLift: 0.045 + (0.020 * barT)

    // =====================================================
    // 7) ISLAND MOTION
    // =====================================================
    property bool islandMotionEnabled: true
    property real islandStretchX: 1.0 

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
        NumberAnimation { target: root; property: "islandStretchX"; to: 1.0; duration: 0 }
        NumberAnimation {
            target: root
            property: "islandStretchX"
            to: islandStretchAnim.expanding ? (1.010 + 0.008 * root.barT) : (0.992 - 0.004 * root.barT)
            duration: 95
            easing.type: Easing.OutCubic
        }
        NumberAnimation { target: root; property: "islandStretchX"; to: 1.0; duration: 165; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // 8) HOVER + HELPERS
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
    // 9) BREATHING
    // =====================================================
    property bool breatheEnabled: true
    property real breathePhase: 0.0
    readonly property bool _breatheRunning: breatheEnabled && !popupOpen

    readonly property int breatheCycleMs: Math.round(2700 + 500 * barT)
    readonly property real breatheStrength: 0.020 + (0.010 * barT)
    readonly property real breatheScaleStrength: 0.0055 + (0.0020 * barT)

    function _ease01(t) { return 0.5 + 0.5 * Math.sin((t * 2.0 * Math.PI) - (Math.PI / 2.0)) }
    function _signed(t) { return (_ease01(t) - 0.5) * 2.0 }

    readonly property real breathTime01: _ease01(breathePhase)
    readonly property real breathTimeSigned: _signed(breathePhase)
    readonly property real breathSecSigned: _signed((breathePhase + 0.50) % 1.0)

    readonly property real breatheScaleTime: 1.0 + (breathTimeSigned * breatheScaleStrength)
    readonly property real breatheScaleSec: 1.0 + (breathSecSigned * breatheScaleStrength)

    readonly property real breatheTimeExtra: breathTime01 * breatheStrength
    readonly property real breatheSecExtra: _ease01((breathePhase + 0.50) % 1.0) * breatheStrength
    readonly property real breatheDateExtra: breatheTimeExtra * 0.80

    NumberAnimation on breathePhase {
        from: 0.0; to: 1.0; duration: root.breatheCycleMs; loops: Animation.Infinite
        running: root._breatheRunning; easing.type: Easing.InOutSine
    }

    // =====================================================
    // 10) TIME MODEL
    // =====================================================
    property string systemTime: DateTime.time
    readonly property string timeNumbers: {
        var m = (systemTime || "").match(/^(\d{1,2}:\d{2})/)
        return m ? m[1] : (systemTime || "")
    }
    readonly property string timeSuffix: (systemTime || "").replace(timeNumbers, "").replace(/\./g, "").trim()
    property string currentSeconds: Qt.formatTime(new Date(), "ss")

    property bool secondsPulseEnabled: true
    property real secondsPulsePhase: 0.0
    readonly property int secondsPulseMs: Math.round(1950 + 350 * barT)
    readonly property real secondsPulseOpacity: {
        var t = _ease01(secondsPulsePhase)
        return 0.72 + (0.96 - 0.72) * t
    }

    NumberAnimation on secondsPulsePhase {
        from: 0.0; to: 1.0; duration: root.secondsPulseMs; loops: Animation.Infinite
        running: root.secondsPulseEnabled && !root.popupOpen; easing.type: Easing.InOutSine
    }

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
    // 11) SIZE / LAYOUT
    // =====================================================
    property real contentScale: 1.0
    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: Appearance.sizes.barHeight
    Behavior on implicitWidth { enabled: true; NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent; anchors.margins: 2; radius: 12
        color: "transparent"; border.width: 0; visible: false
    }

    // =====================================================
    // 12) CONTENT RENDERER
    // =====================================================
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        transform: Scale {
            origin.x: content.width / 2; origin.y: content.height / 2
            xScale: root.contentScale * root.islandStretchX; yScale: root.contentScale
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.pillGap

            // --- PILL BACKGROUND COMPONENT ---
            component TonalPillBg: Rectangle {
                required property color tonal
                required property real breatheExtra
                radius: root.pillRadius
                antialiasing: true

                // Gradiente inteligente
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root._rgba(
                            tonal,
                            root._a(root.pillAlphaIdle, root.pillAlphaHover) + root.pillGradientLift + breatheExtra
                        )
                    }
                    GradientStop {
                        position: 1.0
                        color: root._rgba(
                            tonal,
                            root._a(root.pillAlphaIdle, root.pillAlphaHover) + (breatheExtra * 0.55)
                        )
                    }
                }

                // Borde sutil
                border.width: 1
                // En modo claro el borde se oscurece un poco más para definir
                border.color: Qt.rgba(
                    root.themeIsDark ? 1 : 0, 
                    root.themeIsDark ? 1 : 0, 
                    root.themeIsDark ? 1 : 0, 
                    root._a(root.pillBorderAlphaIdle, root.pillBorderAlphaHover)
                )
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
                    anchors.fill: parent; anchors.margins: 1; radius: parent.radius
                    color: "transparent"; border.width: 1
                    border.color: Qt.rgba(1, 1, 1, root.pillInnerHighlightAlpha)
                    antialiasing: true
                }
            }

            // --- TIME PILL ---
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
                            
                            // Color inteligente aplicado
                            color: root.smartTextColor 
                            opacity: 0.95
                            Layout.alignment: Qt.AlignVCenter
                            renderType: Text.NativeRendering

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 0.50
                                // Sombra inteligente aplicada
                                shadowColor: root.smartShadowColor
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
                        color: root.smartTextColor
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
                opacity: visible ? 1 : 0
                text: "•"
                font.pixelSize: Appearance.font.pixelSize.large
                // En modo claro, el divisor también debe oscurecerse
                color: root.themeIsDark ? Appearance.colors.colOnLayer1Variant : "#444444"
                Layout.leftMargin: 6
                Layout.rightMargin: 2
                Layout.alignment: Qt.AlignVCenter
                Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                renderType: Text.NativeRendering
            }

            // --- DATE PILL ---
            Item {
                visible: root.expanded
                opacity: visible ? 1 : 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: pillDateRow.implicitWidth + (root.pillPadH * 2)
                implicitHeight: Math.round(Appearance.font.pixelSize.normal + (root.pillPadV * 2))
                Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                scale: root._breatheRunning ? (1.0 + (root.breathTimeSigned * (root.breatheScaleStrength * 0.28))) : 1.0
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
    // 13) TACTILE / INPUT
    // =====================================================
    SequentialAnimation {
        id: clickSquish
        running: false
        NumberAnimation { target: root; property: "contentScale"; to: 0.965; duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "contentScale"; to: 1.020; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "contentScale"; to: 1.000; duration: 190; easing.type: Easing.OutCubic }
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

    Loader {
        active: root.interactionsEnabled && root.popupOpen
        sourceComponent: ClockWidgetPopup { hoverTarget: mouseArea }
    }
}
