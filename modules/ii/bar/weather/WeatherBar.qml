pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

MouseArea {
    id: root

    // FIX: BarComponent a veces asigna `vertical: ...`
    property bool vertical: false

    // Controls
    property bool interactionsEnabled: true
    property bool allowPopup: true

    // Pixel/Google toggles
    property bool enablePixelGrid: true
    property bool enableWeatherAura: true

    // NEW: efecto “barrido” que pasa por todo el widget
    property bool enableSweep: true

    // Heartbeat (SIN brillo; solo escala/“palpitar”)
    property bool enableHeartbeat: true
    property real heartbeatStrength: 1.0 // 0..1

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    // =====================================================
    // THEME
    // =====================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property color fg: themeIsDark ? "#FFFFFF" : "#161616"
    readonly property color fgSoft: themeIsDark ? Qt.rgba(1,1,1,0.74) : Qt.rgba(0,0,0,0.60)

    // =====================================================
    // HOVER / PRESS
    // =====================================================
    property real hoverAmount: containsMouse ? 1.0 : 0.0
    Behavior on hoverAmount {
        enabled: root.interactionsEnabled
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    property real pressAmount: pressed ? 1.0 : 0.0
    Behavior on pressAmount {
        enabled: root.interactionsEnabled
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
    }

    // =====================================================
    // WEATHER DATA
    // =====================================================
    readonly property var w: Weather.data
    readonly property var wCode: w?.wCode

    readonly property string tempText: (w?.temp !== undefined && w?.temp !== null) ? ("" + w.temp + "°") : "--°"

    readonly property string cityText: {
        var c = w?.city ?? w?.location ?? w?.name ?? w?.place ?? ""
        c = (c === null || c === undefined) ? "" : ("" + c).trim()
        if (c.length > 22) c = c.slice(0, 22) + "…"
        return c
    }

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

    function accentBase() {
        switch (weatherKind()) {
        case "sun":   return Qt.rgba(1.00, 0.78, 0.18, 1.0)
        case "cloud": return Qt.rgba(0.78, 0.86, 0.98, 1.0)
        case "rain":  return Qt.rgba(0.28, 0.68, 1.00, 1.0)
        case "storm": return Qt.rgba(0.72, 0.46, 1.00, 1.0)
        case "snow":  return Qt.rgba(0.66, 0.95, 1.00, 1.0)
        case "fog":   return Qt.rgba(0.80, 0.84, 0.88, 1.0)
        default:      return Qt.rgba(1, 1, 1, 1.0)
        }
    }

    function _clamp(x, a, b) { return Math.max(a, Math.min(b, x)) }

    readonly property color accent: {
        var a = accentBase()
        var tTheme = themeIsDark ? 0.70 : 0.54
        var t = _clamp(tTheme + 0.18 * hoverAmount, 0.30, 0.92)
        return Qt.rgba(
            fg.r * (1.0 - t) + a.r * t,
            fg.g * (1.0 - t) + a.g * t,
            fg.b * (1.0 - t) + a.b * t,
            1.0
        )
    }

    readonly property color cityColor: {
        var base = fgSoft
        var a = accent
        var t = themeIsDark ? 0.60 : 0.48
        t = _clamp(t + 0.12 * hoverAmount, 0.30, 0.85)
        return Qt.rgba(
            base.r * (1.0 - t) + a.r * t,
            base.g * (1.0 - t) + a.g * t,
            base.b * (1.0 - t) + a.b * t,
            1.0
        )
    }

    // =====================================================
    // POPUP
    // =====================================================
    function openWeatherPopup() {
        if (!root.allowPopup) return

        if (typeof weatherPopup.toggle === "function") { weatherPopup.toggle(); return }
        if (typeof weatherPopup.requestOpen === "function") { weatherPopup.requestOpen(); return }

        if (typeof weatherPopup.popup === "function") {
            if (weatherPopup.popup.length >= 1) weatherPopup.popup(root)
            else weatherPopup.popup()
            return
        }

        if (typeof weatherPopup.open === "function") {
            if (weatherPopup.open.length >= 1) weatherPopup.open(root)
            else weatherPopup.open()
            return
        }

        if (typeof weatherPopup.show === "function") { weatherPopup.show(); return }
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
    // CHIP LAYOUT
    // =====================================================
    property int padX: 12
    property int padY: 7
    property int gap: 8
    property int radius: 12

    implicitWidth: chip.implicitWidth
    implicitHeight: chip.implicitHeight

    // Aura animation phase
    property real auraPhase: 0.0
    NumberAnimation on auraPhase {
        running: root.enableWeatherAura
        loops: Animation.Infinite
        from: 0.0
        to: 1.0
        duration: 2400
        easing.type: Easing.InOutSine
    }

    // NEW: Sweep phase (efecto que “pasa por todo el widget”)
    property real sweepPhase: 0.0
    NumberAnimation on sweepPhase {
        running: root.enableSweep
        loops: Animation.Infinite
        from: 0.0
        to: 1.0
        duration: 1800
        easing.type: Easing.InOutSine
    }

    // Heartbeat phase (doble latido) — SOLO escala
    property real beat: 0.0
    SequentialAnimation on beat {
        running: root.enableHeartbeat
        loops: Animation.Infinite

        NumberAnimation { from: 0.0; to: 1.0; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { from: 1.0; to: 0.0; duration: 190; easing.type: Easing.OutCubic }

        PauseAnimation { duration: 140 }

        NumberAnimation { from: 0.0; to: 0.78; duration: 105; easing.type: Easing.OutCubic }
        NumberAnimation { from: 0.78; to: 0.0; duration: 220; easing.type: Easing.OutCubic }

        PauseAnimation { duration: 900 }
    }

    readonly property real beatAmt: root.beat * root.heartbeatStrength

    Item {
        id: chip
        implicitWidth: row.implicitWidth + root.padX * 2
        implicitHeight: Math.max(24, row.implicitHeight + root.padY * 2)

        transformOrigin: Item.Center
        transform: [
            Scale {
                origin.x: chip.width / 2
                origin.y: chip.height / 2

                readonly property real s: (root.interactionsEnabled ? (1.0 + 0.0065 * root.beatAmt) : 1.0)
                xScale: s - 0.010 * root.pressAmount
                yScale: s - 0.010 * root.pressAmount
            },
            Translate { y: (-0.40 * root.hoverAmount) + (0.20 * root.pressAmount) }
        ]

        Rectangle {
            id: plate
            anchors.fill: parent
            radius: root.radius
            antialiasing: true
            clip: true

            color: Qt.rgba(
                Appearance.m3colors.m3secondary.r,
                Appearance.m3colors.m3secondary.g,
                Appearance.m3colors.m3secondary.b,
                (root.themeIsDark ? 0.22 : 0.14) + 0.06 * root.hoverAmount
            )

            border.width: 1
            border.color: Qt.rgba(
                root.accent.r, root.accent.g, root.accent.b,
                (root.themeIsDark ? 0.38 : 0.30) + 0.18 * root.hoverAmount
            )

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(
                    1, 1, 1,
                    root.themeIsDark ? (0.10 + 0.06 * root.hoverAmount) : (0.08 + 0.05 * root.hoverAmount)
                )
            }

            // =================================================
            // SWEEP EFFECT (pasa por todo el widget)
            //   - No es “brillo” ligado al latido
            //   - Es un barrido suave constante
            // =================================================
            Item {
                anchors.fill: parent
                visible: root.enableSweep
                clip: true
                opacity: 0.12 + 0.08 * root.hoverAmount

                Rectangle {
                    width: parent.width * 0.60
                    height: parent.height * 2.0
                    radius: 10
                    rotation: -18

                    // De izquierda a derecha
                    x: (-parent.width * 0.75) + (parent.width * 1.75 * root.sweepPhase)
                    y: -parent.height * 0.60

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.00) }
                        GradientStop { position: 0.5; color: Qt.rgba(1,1,1, root.themeIsDark ? 0.10 : 0.08) }
                        GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
                    }
                    opacity: 0.85
                }
            }

            // =================================================
            // PIXEL GRID
            //   FIX: quitada la “línea” cerca del icono:
            //   - ya NO dibuja una línea en x=0
            // =================================================
            Item {
                anchors.fill: parent
                visible: root.enablePixelGrid
                opacity: 0.10 + 0.10 * root.hoverAmount
                clip: true

                Repeater {
                    // antes: floor(width/10) empezaba en 0 => línea pegada al icono/borde
                    model: Math.max(0, Math.floor((plate.width - 10) / 10))
                    delegate: Rectangle {
                        width: 1
                        height: plate.height
                        x: 10 + index * 10   // <-- empieza en 10, no en 0
                        y: 0
                        color: Qt.rgba(1,1,1, root.themeIsDark ? 0.10 : 0.08)
                        opacity: 0.35
                    }
                }

                Repeater {
                    // también evitamos y=0 por simetría (opcional, se ve más limpio)
                    model: Math.max(0, Math.floor((plate.height - 10) / 10))
                    delegate: Rectangle {
                        width: plate.width
                        height: 1
                        x: 0
                        y: 10 + index * 10   // <-- empieza en 10
                        color: Qt.rgba(0,0,0, root.themeIsDark ? 0.14 : 0.10)
                        opacity: 0.28
                    }
                }
            }

            // Weather aura (tu efecto existente)
            Item {
                anchors.fill: parent
                visible: root.enableWeatherAura
                opacity: 0.20 + 0.18 * root.hoverAmount
                clip: true

                Rectangle {
                    width: parent.width * 0.55
                    height: parent.height * 1.2
                    radius: 6
                    rotation: -18
                    x: (-parent.width * 0.50) + (parent.width * 1.20 * root.auraPhase)
                    y: -parent.height * 0.20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.00) }
                        GradientStop { position: 0.5; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.themeIsDark ? 0.10 : 0.07) }
                        GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
                    }
                    opacity: 0.9
                }

                Rectangle {
                    visible: root.weatherKind() === "sun"
                    width: parent.height * 1.0
                    height: width
                    radius: 8
                    x: parent.width * 0.08
                    y: -parent.height * 0.40
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b,
                                  0.08 + 0.08 * (0.5 + 0.5 * Math.sin(6.28318 * root.auraPhase)))
                }

                Repeater {
                    model: (root.weatherKind() === "rain" || root.weatherKind() === "storm") ? 6 : 0
                    delegate: Rectangle {
                        width: 2
                        height: parent.height * 0.60
                        radius: 1
                        rotation: -18
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.weatherKind() === "storm" ? 0.18 : 0.14)
                        x: (index * parent.width * 0.16) + (parent.width * 0.30 * root.auraPhase)
                        y: parent.height * 0.10 + (index % 2) * 2
                        opacity: 0.55
                    }
                }

                Repeater {
                    model: (root.weatherKind() === "snow" || root.weatherKind() === "fog") ? 8 : 0
                    delegate: Rectangle {
                        width: 2 + (index % 2)
                        height: width
                        radius: 1
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.weatherKind() === "fog" ? 0.10 : 0.16)
                        x: (index * parent.width * 0.12 + parent.width * 0.22 * root.auraPhase) % parent.width
                        y: parent.height * (0.18 + 0.09 * (index % 4)) + (parent.height * 0.08 * Math.sin(6.28318 * (root.auraPhase + index * 0.14)))
                        opacity: 0.6
                    }
                }

                Repeater {
                    model: (root.weatherKind() === "cloud") ? 3 : 0
                    delegate: Rectangle {
                        width: parent.width * (0.24 + 0.10 * (index % 2))
                        height: 2
                        radius: 1
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
                        x: (-parent.width * 0.25) + (parent.width * 1.20 * root.auraPhase) - (index * 14)
                        y: parent.height * (0.26 + 0.22 * index)
                        opacity: 0.7
                    }
                }
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.gap

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: root.weatherIcon()
                fill: 0
                iconSize: Math.max(16, Appearance.font.pixelSize.small + 2)
                color: root.accent
                opacity: 0.92 + 0.08 * root.hoverAmount
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.tempText
                font.pixelSize: Appearance.font.pixelSize.small
                font.bold: true
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
                color: root.fg
                renderType: Text.NativeRendering
            }

            // FIX: quitado el “punto” al lado de la ciudad (se eliminó el separador)
            // (No hay Rectangle separador aquí)

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.cityText !== ""
                text: root.cityText
                font.pixelSize: (Appearance.font.pixelSize.tiny ?? Math.max(10, Appearance.font.pixelSize.small - 2)) + 1
                font.bold: true
                font.weight: Font.DemiBold
                font.letterSpacing: 0.35
                color: root.cityColor
                opacity: 0.94 + 0.05 * root.hoverAmount
                elide: Text.ElideRight
                Layout.maximumWidth: 170
                renderType: Text.NativeRendering
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
        // NO z: StyledPopup no es Item
    }
}

