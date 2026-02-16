pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

MouseArea {
    id: root

    // FIX: BarComponent a veces asigna `vertical: ...`
    property bool vertical: false

    // Controls
    property bool interactionsEnabled: true
    property bool tactileFeedback: true

    // Premium toggles
    property bool enableGlassBlur: true
    property bool enableSheen: true
    property bool enableShimmer: true
    property bool enableIconGlow: true

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    // =====================================================
    // SMART THEME (auto claro/oscuro)
    // =====================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property color smartTextColor: themeIsDark ? "#FFFFFF" : "#111111"
    readonly property color smartShadowColor: themeIsDark ? Qt.rgba(0,0,0,0.45) : Qt.rgba(0,0,0,0.18)

    // =====================================================
    // HOVER / PRESS
    // =====================================================
    property real hoverAmount: containsMouse ? 1.0 : 0.0
    Behavior on hoverAmount {
        enabled: root.interactionsEnabled
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    property real pressAmount: pressed ? 1.0 : 0.0
    Behavior on pressAmount {
        enabled: root.interactionsEnabled
        NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // WEATHER DATA
    // =====================================================
    readonly property var wCode: Weather.data?.wCode
    readonly property string tempText: Weather.data?.temp ?? "--°"

    function _codeStr() {
        return (wCode === undefined || wCode === null) ? "" : ("" + wCode).toLowerCase().trim()
    }

    function weatherKind() {
        var s = _codeStr()
        var n = parseInt(s)
        if (!isNaN(n)) {
            if (n >= 200 && n < 300) return "storm"
            if (n >= 300 && n < 600) return "rain"
            if (n >= 600 && n < 700) return "snow"
            if (n >= 700 && n < 800) return "fog"
            if (n === 800) return "sun"
            if (n > 800 && n < 900) return "cloud"
        }
        if (s.indexOf("thunder") !== -1 || s.indexOf("storm") !== -1) return "storm"
        if (s.indexOf("rain") !== -1 || s.indexOf("drizzle") !== -1 || s.indexOf("shower") !== -1) return "rain"
        if (s.indexOf("snow") !== -1 || s.indexOf("sleet") !== -1 || s.indexOf("hail") !== -1) return "snow"
        if (s.indexOf("fog") !== -1 || s.indexOf("mist") !== -1 || s.indexOf("haze") !== -1) return "fog"
        if (s.indexOf("cloud") !== -1 || s.indexOf("overcast") !== -1) return "cloud"
        if (s.indexOf("clear") !== -1 || s.indexOf("sun") !== -1) return "sun"
        return "default"
    }

    function weatherIcon() {
        switch (weatherKind()) {
        case "sun":   return "sunny"
        case "cloud": return "cloud"
        case "rain":  return "rainy"
        case "storm": return "thunderstorm"
        case "snow":  return "weather_snowy"
        case "fog":   return "foggy"
        default:      return Icons.getWeatherIcon(wCode) ?? "cloud"
        }
    }

    // =====================================================
    // ICON ACCENT (sol amarillo, lluvia azul, etc.)
    // Auto theme-safe + sube un poquito en hover
    // =====================================================
    function _clamp(x, a, b) { return Math.max(a, Math.min(b, x)) }

    function weatherAccentBase() {
        switch (weatherKind()) {
        case "sun":   return Qt.rgba(1.00, 0.78, 0.18, 1.0)  // amber
        case "cloud": return Qt.rgba(0.80, 0.86, 0.95, 1.0)  // cool gray/blue
        case "rain":  return Qt.rgba(0.33, 0.70, 1.00, 1.0)  // sky blue
        case "storm": return Qt.rgba(0.76, 0.46, 1.00, 1.0)  // violet
        case "snow":  return Qt.rgba(0.70, 0.95, 1.00, 1.0)  // icy cyan
        case "fog":   return Qt.rgba(0.78, 0.82, 0.86, 1.0)  // neutral gray
        default:      return Qt.rgba(1.00, 1.00, 1.00, 1.0)
        }
    }

    readonly property color weatherAccent: {
        var a = weatherAccentBase()

        // Claro: más controlado. Oscuro: más “vivo”.
        var tTheme = themeIsDark ? 0.72 : 0.50
        var tHover = _clamp(tTheme + (0.18 * hoverAmount), 0.35, 0.88)

        return Qt.rgba(
            smartTextColor.r * (1.0 - tHover) + a.r * tHover,
            smartTextColor.g * (1.0 - tHover) + a.g * tHover,
            smartTextColor.b * (1.0 - tHover) + a.b * tHover,
            1.0
        )
    }

    // =====================================================
    // TONAL PILL (mismo lenguaje que tu barra)
    // =====================================================
    readonly property color tonalWeather: Appearance.m3colors.m3secondary
    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function _mix(a, b, t) { return a + (b - a) * t }
    function _a(idleA, hoverA) { return _mix(idleA, hoverA, hoverAmount) }

    // =====================================================
    // POPUP
    // =====================================================
    function openWeatherPopup() {
        if (typeof weatherPopup.open === "function") { weatherPopup.open(); return }
        if (typeof weatherPopup.show === "function") { weatherPopup.show(); return }
        if (typeof weatherPopup.popup === "function") { weatherPopup.popup(); return }
        if (typeof weatherPopup.requestOpen === "function") { weatherPopup.requestOpen(); return }
    }

    onPressed: (mouse) => {
        if (!root.interactionsEnabled) { mouse.accepted = false; return }

        if (mouse.button === Qt.RightButton) {
            Weather.getData()
            Quickshell.execDetached([
                "notify-send",
                Translation.tr("Weather"),
                Translation.tr("Refreshing (manually triggered)"),
                "-a", "Shell"
            ])
            mouse.accepted = false
            return
        }

        if (mouse.button === Qt.LeftButton) {
            openWeatherPopup()
            mouse.accepted = true
        }
    }

    // =====================================================
    // SIZE / SPACING
    // =====================================================
    property int chipPadH: 9
    property int chipPadV: 5
    property int chipGap: 7
    property int chipRadius: 999

    implicitWidth: chip.implicitWidth
    implicitHeight: chip.implicitHeight

    // Subtle shimmer (solo en hover)
    property real shimmerPhase: 0.0
    NumberAnimation on shimmerPhase {
        running: root.enableShimmer && root.hoverAmount > 0.2
        loops: Animation.Infinite
        from: 0.0
        to: 1.0
        duration: 1400
        easing.type: Easing.InOutSine
    }

    Item {
        id: chip
        implicitWidth: row.implicitWidth + (root.chipPadH * 2)
        implicitHeight: Math.max(22, Math.round(Appearance.font.pixelSize.small + (root.chipPadV * 2)))

        // micro lift + squish
        transformOrigin: Item.Center
        transform: [
            Scale {
                origin.x: chip.width / 2
                origin.y: chip.height / 2
                xScale: 1.0 - (0.012 * root.pressAmount)
                yScale: 1.0 - (0.012 * root.pressAmount)
            },
            Translate { y: -0.6 * root.hoverAmount + 0.2 * root.pressAmount }
        ]

        // ---------- BACKPLATE (hover-to-pill) ----------
        Rectangle {
            id: plate
            anchors.fill: parent
            radius: root.chipRadius
            antialiasing: true

            // idle invisible, hover glass-tonal
            color: root._rgba(root.tonalWeather, root._a(0.00, root.themeIsDark ? 0.20 : 0.13))

            border.width: 1
            border.color: Qt.rgba(
                1, 1, 1,
                root._a(0.00, root.themeIsDark ? 0.16 : 0.12)
            )

            layer.enabled: root.hoverAmount > 0.01
            layer.smooth: true
            layer.samples: 4
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: (root.themeIsDark ? 0.12 : 0.05) * root.hoverAmount
                shadowBlur: 0.9 + (0.4 * root.hoverAmount)
                shadowVerticalOffset: 1
            }

            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        // Optional: subtle glass blur on hover
        Item {
            anchors.fill: plate
            visible: root.enableGlassBlur && root.hoverAmount > 0.05
            layer.enabled: visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.35 + (0.35 * root.hoverAmount)
                saturation: 1.05
                brightness: 1.02
            }
        }

        // iOS-like top sheen
        Rectangle {
            visible: root.enableSheen && root.hoverAmount > 0.05
            anchors.fill: plate
            radius: plate.radius
            clip: true
            color: "transparent"
            opacity: root.hoverAmount
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.55
                y: 1
                radius: 999
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.12 : 0.16) }
                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1, 0.00) }
                }
            }
        }

        // Diagonal shimmer (super sutil)
        Rectangle {
            visible: root.enableShimmer && root.hoverAmount > 0.20
            anchors.fill: plate
            radius: plate.radius
            clip: true
            color: "transparent"
            opacity: 0.55 * root.hoverAmount
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Rectangle {
                width: parent.width * 0.65
                height: parent.height * 0.9
                radius: 999
                rotation: -20

                x: (-parent.width * 0.55) + (parent.width * 1.25 * root.shimmerPhase)
                y: -parent.height * 0.15

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.00) }
                    GradientStop { position: 0.5; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.07 : 0.09) }
                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
                }
            }
        }

        // ---------- CONTENT ----------
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.chipGap

            MaterialSymbol {
                id: weatherIconItem
                Layout.alignment: Qt.AlignVCenter
                fill: 0
                text: root.weatherIcon()
                iconSize: Math.max(16, Appearance.font.pixelSize.small)

                // Aquí está lo importante: icono con color según clima
                color: root.weatherAccent

                opacity: 0.90 + (0.10 * root.hoverAmount)
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                // Glow muy sutil (se nota más en hover)
                layer.enabled: root.enableIconGlow
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.9
                    shadowVerticalOffset: 0
                    shadowOpacity: (root.themeIsDark ? 0.16 : 0.10) * root.hoverAmount
                    shadowColor: root.weatherAccent
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.tempText
                font.pixelSize: Appearance.font.pixelSize.small
                font.bold: true
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
                color: root.smartTextColor
                opacity: 0.86 + (0.14 * root.hoverAmount)
                renderType: Text.NativeRendering
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.45
                    shadowColor: root.smartShadowColor
                    shadowOpacity: root.themeIsDark ? 0.18 : 0.10
                    shadowVerticalOffset: 1
                }
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}


