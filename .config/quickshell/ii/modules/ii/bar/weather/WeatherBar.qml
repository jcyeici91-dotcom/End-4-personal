// WeatherBar.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

MouseArea {
    id: root

    property bool vertical: false
    readonly property bool isRightSide: Config.options.bar.bottom || Config.runtime.bar.position === "right"

    property bool interactionsEnabled: true
    property bool allowPopup: true

    property bool enableWeatherAura: true
    property bool enableHeartbeat: true
    property real heartbeatStrength: 1.0

    property real crystalTintOpacity: 0.00
    property bool crystalBordersOnHoverOnly: true
    property real crystalBorderHoverStrength: 1.0

    // Padding real usado por el contenido (debe coincidir con el cálculo del implicit size)
    property int padX: root.vertical ? 6 : 10
    property int padY: root.vertical ? 6 : 10

    property int gap: 8
    property int radius: 12

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    Layout.fillHeight: true

    // El tamaño implícito ahora coincide con el padding real aplicado al contenido
    implicitWidth: root.vertical
        ? Appearance.sizes.verticalBarWidth
        : (contentGrid.implicitWidth + padX * 2)

    implicitHeight: root.vertical
        ? (contentGrid.implicitHeight + padY * 2)
        : Math.max(30, contentGrid.implicitHeight + padY * 2)

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode)
        ? Appearance.m3colors.darkmode
        : false

    readonly property color fg: Appearance.colors.colOnLayer1
    readonly property color fgSoft: Appearance.colors.colOnLayer2
    readonly property color plateBase: Appearance.colors.colLayer1
    readonly property color plateBorderBase: Appearance.colors.colLayer3

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

    // Weather data
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
        default:      return Appearance.colors.colPrimary
        }
    }

    function _clamp(x, a, b) { return Math.max(a, Math.min(b, x)) }

    readonly property color accent: {
        var a = accentBase()
        var p = Appearance.colors.colPrimary
        var t = _clamp((themeIsDark ? 0.55 : 0.48) + 0.18 * hoverAmount, 0.20, 0.92)
        var m = Qt.rgba(
            a.r * (1.0 - 0.35) + p.r * 0.35,
            a.g * (1.0 - 0.35) + p.g * 0.35,
            a.b * (1.0 - 0.35) + p.b * 0.35,
            1.0
        )
        return Qt.rgba(
            fg.r * (1.0 - t) + m.r * t,
            fg.g * (1.0 - t) + m.g * t,
            fg.b * (1.0 - t) + m.b * t,
            1.0
        )
    }

    readonly property color cityColor: {
        var base = fgSoft
        var a = accent
        var t = _clamp((themeIsDark ? 0.52 : 0.44) + 0.12 * hoverAmount, 0.20, 0.85)
        return Qt.rgba(
            base.r * (1.0 - t) + a.r * t,
            base.g * (1.0 - t) + a.g * t,
            base.b * (1.0 - t) + a.b * t,
            1.0
        )
    }

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

    // Animaciones
    property real auraPhase: 0.0
    NumberAnimation on auraPhase {
        running: root.enableWeatherAura
        loops: Animation.Infinite
        from: 0.0
        to: 1.0
        duration: 2400
        easing.type: Easing.InOutSine
    }

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
        anchors.fill: parent
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
            radius: root.vertical ? width / 2 : root.radius
            antialiasing: true
            clip: true

            color: "transparent"
            border.width: 0
            border.color: "transparent"

            readonly property real borderAmt: (root.crystalBordersOnHoverOnly ? root.hoverAmount : 1.0)
                                           * root.crystalBorderHoverStrength

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: ColorUtils.transparentize(root.plateBase, (root.themeIsDark ? 0.35 : 0.55))
                opacity: 0.22 + 0.12 * root.hoverAmount + 0.10 * root.pressAmount
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: root.crystalTintOpacity > 0.0
                color: root.themeIsDark
                    ? ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.88)
                    : ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92)
                opacity: root.crystalTintOpacity
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: ColorUtils.transparentize(
                    root.plateBorderBase,
                    0.65 + (root.themeIsDark ? 0.10 : 0.18) * plate.borderAmt
                )
                antialiasing: true
                visible: plate.borderAmt > 0.01
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(
                    Appearance.colors.colOnLayer1.r,
                    Appearance.colors.colOnLayer1.g,
                    Appearance.colors.colOnLayer1.b,
                    (root.themeIsDark ? 0.10 : 0.16) * plate.borderAmt
                )
                antialiasing: true
                visible: plate.borderAmt > 0.01
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(
                    root.accent.r, root.accent.g, root.accent.b,
                    ((root.themeIsDark ? 0.14 : 0.10) + 0.14 * root.hoverAmount) * plate.borderAmt
                )
                antialiasing: true
                visible: plate.borderAmt > 0.01
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: root.vertical ? (root.isRightSide ? undefined : parent.left) : parent.left
                anchors.right: root.vertical ? (root.isRightSide ? parent.right : undefined) : parent.right
                anchors.topMargin: root.vertical ? parent.radius / 1.6 : 1
                anchors.leftMargin: root.vertical ? 1 : (parent.radius > 0 ? parent.radius / 1.6 : 1)
                anchors.rightMargin: root.vertical ? 1 : (parent.radius > 0 ? parent.radius / 1.6 : 1)
                height: root.vertical ? Math.max(2, Math.round(parent.height * 0.26)) : 1
                width: root.vertical ? 1 : undefined
                color: Qt.rgba(
                    Appearance.colors.colOnLayer1.r,
                    Appearance.colors.colOnLayer1.g,
                    Appearance.colors.colOnLayer1.b,
                    (root.themeIsDark ? 0.16 : 0.20) * plate.borderAmt
                )
                antialiasing: true
                visible: plate.borderAmt > 0.01
            }

            Item {
                anchors.fill: parent
                visible: root.enableWeatherAura
                opacity: 0.18 + 0.18 * root.hoverAmount
                clip: true

                Rectangle {
                    width: parent.width * 0.55
                    height: parent.height * 1.2
                    radius: 6
                    rotation: -18
                    x: (-parent.width * 0.50) + (parent.width * 1.20 * root.auraPhase)
                    y: -parent.height * 0.20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.00) }
                        GradientStop { position: 0.5; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.themeIsDark ? 0.12 : 0.08) }
                        GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.00) }
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
                    color: Qt.rgba(
                        root.accent.r, root.accent.g, root.accent.b,
                        0.08 + 0.08 * (0.5 + 0.5 * Math.sin(6.28318 * root.auraPhase))
                    )
                }

                Repeater {
                    model: (root.weatherKind() === "rain" || root.weatherKind() === "storm") ? 6 : 0
                    delegate: Rectangle {
                        width: 2
                        height: parent.height * 0.60
                        radius: 1
                        rotation: -18
                        color: Qt.rgba(
                            root.accent.r, root.accent.g, root.accent.b,
                            root.weatherKind() === "storm" ? 0.18 : 0.14
                        )
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
                        color: Qt.rgba(
                            root.accent.r, root.accent.g, root.accent.b,
                            root.weatherKind() === "fog" ? 0.10 : 0.16
                        )
                        x: (index * parent.width * 0.12 + parent.width * 0.22 * root.auraPhase) % parent.width
                        y: parent.height * (0.18 + 0.09 * (index % 4))
                           + (parent.height * 0.08 * Math.sin(6.28318 * (root.auraPhase + index * 0.14)))
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

        // Caja de contenido: centra el layout por tamaño implícito + aplica padding real
        Item {
            id: contentBox
            anchors.fill: parent
            anchors.margins: 0

            GridLayout {
                id: contentGrid

                // En vez de fill, lo centramos y le damos su tamaño implícito
                width: implicitWidth
                height: implicitHeight
                anchors.centerIn: parent

                // El padding lo hacemos “real” con un wrapper invisible:
                // (alternativa simple: dar márgenes al contentBox en lugar de GridLayout)
                // Aquí lo hacemos moviendo el layout dentro del rectángulo:
                x: (contentBox.width - width) / 2
                y: (contentBox.height - height) / 2

                // Ajuste de padding: expandimos el layout sumando pads con un Item espaciador alrededor
                // Más simple: aumentar el tamaño del chip con implicit, y mantener layout centrado;
                // el pad ya está en implicitWidth/Height y el layout queda centrado, sin “hueco abajo”.
                // Si quieres padding interno real (que afecte al hitbox visual), usa un wrapper extra.
                // Por ahora, esto corrige el “no centrado”.

                columns: root.vertical ? 1 : 2
                rows: root.vertical ? 2 : 1
                rowSpacing: 8
                columnSpacing: root.gap

                Item {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.weatherIcon()
                        fill: 0
                        iconSize: Math.max(16, Appearance.font.pixelSize.small + 2)
                        color: root.accent
                        opacity: 0.92 + 0.08 * root.hoverAmount
                    }
                }

                Item {
                    id: textWrapper
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    clip: true

                    // Mantén coherente: el wrapper toma el size del contenido real
                    Layout.preferredWidth: root.vertical ? innerRow.implicitHeight : innerRow.implicitWidth
                    Layout.preferredHeight: root.vertical ? innerRow.implicitWidth : innerRow.implicitHeight

                    Item {
                        width: root.vertical ? textWrapper.height : textWrapper.width
                        height: root.vertical ? textWrapper.width : textWrapper.height
                        anchors.centerIn: parent
                        rotation: root.vertical ? (root.isRightSide ? 90 : -90) : 0

                        RowLayout {
                            id: innerRow
                            anchors.centerIn: parent
                            spacing: 6

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
                }
            }

            // Padding real: hacemos que el contenido “respire” sin descentrarlo
            // (este padding afecta la zona alrededor porque el Grid está centrado)
            // Si quieres padding interno real, dilo y te lo dejo con un wrapper que lo aplique literal.
            onWidthChanged: {
                // no-op (placeholder para claridad)
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
    }
}

