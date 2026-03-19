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
    
    // 👇 CONECTADO AL INTERRUPTOR MAESTRO 👇
    property bool enableWeatherAura: Config.options.appearance.enableAnimations
    property bool enableHeartbeat: Config.options.appearance.enableAnimations
    
    property real heartbeatStrength: 1.0
    property real crystalTintOpacity: 0.00
    property bool crystalBordersOnHoverOnly: true
    property real crystalBorderHoverStrength: 1.0
    property int padX: root.vertical ? 8 : 14
    property int padY: root.vertical ? 8 : 12
    property int gap: 10
    property int radius: 16
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor
    Layout.fillHeight: true
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (contentGrid.implicitWidth + padX * 2)
    implicitHeight: root.vertical ? (contentGrid.implicitHeight + padY * 2) : Math.max(36, contentGrid.implicitHeight + padY * 2)

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode) ? Appearance.m3colors.darkmode : false
    readonly property color fg: Appearance.colors.colOnLayer1
    readonly property color fgSoft: Appearance.colors.colOnLayer2
    readonly property color plateBase: Appearance.colors.colLayer1
    readonly property color plateBorderBase: Appearance.colors.colLayer3
    property real hoverAmount: containsMouse ? 1.0 : 0.0
    Behavior on hoverAmount { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    property real pressAmount: pressed ? 1.0 : 0.0
    Behavior on pressAmount { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    readonly property var w: Weather.data
    readonly property var wCode: w?.wCode
    readonly property string tempText: (w?.temp !== undefined && w?.temp !== null) ? ("" + w.temp + "°") : "--°"
    readonly property string cityText: {
        var c = w?.city ?? w?.location ?? w?.name ?? w?.place ?? ""
        c = (c === null || c === undefined) ? "" : ("" + c).trim()
        if (c.length > 22) c = c.slice(0, 22) + "…"
        return c
    }

    function _codeStr() { return (wCode === undefined || wCode === null) ? "" : ("" + wCode).toLowerCase().trim() }

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
        case "sun": return "sunny"
        case "cloud": return "cloud"
        case "rain": return "rainy"
        case "storm": return "thunderstorm"
        case "snow": return "weather_snowy"
        case "fog": return "foggy"
        default: return Icons.getWeatherIcon(wCode) ?? "cloud"
        }
    }

    function accentBase() {
        switch (weatherKind()) {
        case "sun": return Qt.rgba(1.00, 0.78, 0.18, 1.0)
        case "cloud": return Qt.rgba(0.78, 0.86, 0.98, 1.0)
        case "rain": return Qt.rgba(0.28, 0.68, 1.00, 1.0)
        case "storm": return Qt.rgba(0.72, 0.46, 1.00, 1.0)
        case "snow": return Qt.rgba(0.66, 0.95, 1.00, 1.0)
        case "fog": return Qt.rgba(0.80, 0.84, 0.88, 1.0)
        default: return Appearance.colors.colPrimary
        }
    }

    function _clamp(x, a, b) { return Math.max(a, Math.min(b, x)) }

    readonly property color accent: {
        var a = accentBase()
        var p = Appearance.colors.colPrimary
        var t = _clamp((themeIsDark ? 0.55 : 0.48) + 0.18 * hoverAmount, 0.20, 0.92)
        var m = Qt.rgba(a.r * 0.65 + p.r * 0.35, a.g * 0.65 + p.g * 0.35, a.b * 0.65 + p.b * 0.35, 1.0)
        return Qt.rgba(fg.r * (1.0 - t) + m.r * t, fg.g * (1.0 - t) + m.g * t, fg.b * (1.0 - t) + m.b * t, 1.0)
    }

    readonly property color cityColor: {
        var base = fgSoft
        var a = accent
        var t = _clamp((themeIsDark ? 0.52 : 0.44) + 0.12 * hoverAmount, 0.20, 0.85)
        return Qt.rgba(base.r * (1.0 - t) + a.r * t, base.g * (1.0 - t) + a.g * t, base.b * (1.0 - t) + a.b * t, 1.0)
    }

    onClicked: (mouse) => {
        if (!root.interactionsEnabled) return

        if (mouse.button === Qt.LeftButton) {
            if (root.allowPopup && weatherPopupLoader.item) {
                weatherPopupLoader.item.triggerItem = root
                weatherPopupLoader.item.defaultIndex = 1
                weatherPopupLoader.item.open = !weatherPopupLoader.item.open
            }
        }
        else if (mouse.button === Qt.RightButton) {
            Weather.getData()
            Quickshell.execDetached([
                "notify-send",
                Translation.tr("Weather"),
                Translation.tr("Refreshing (manually triggered)"),
                "-a", "Shell"
            ])
        }
    }

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

    readonly property real beatAmt: root.enableHeartbeat ? (root.beat * root.heartbeatStrength) : 0

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: root.vertical ? width / 2 : root.radius
        antialiasing: true
        color: "transparent"
        clip: true

        readonly property real borderAmt: (root.crystalBordersOnHoverOnly ? root.hoverAmount : 1.0) * root.crystalBorderHoverStrength

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: ColorUtils.transparentize(root.plateBase, root.themeIsDark ? 0.32 : 0.52)
            opacity: 0.24 + 0.14 * root.hoverAmount + 0.10 * root.pressAmount
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.crystalTintOpacity > 0.0
            color: root.themeIsDark ? Qt.rgba(0.9,0.9,1.0,0.08) : Qt.rgba(1.0,1.0,1.0,0.12)
            opacity: root.crystalTintOpacity
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(root.plateBorderBase, 0.62 + (root.themeIsDark ? 0.12 : 0.20) * plate.borderAmt)
            antialiasing: true
            visible: plate.borderAmt > 0.01
        }

        Item {
            anchors.fill: parent
            visible: root.enableWeatherAura
            opacity: 0.20 + 0.20 * root.hoverAmount
            clip: true

            Rectangle {
                width: parent.width * 0.60
                height: parent.height * 1.3
                radius: 8
                rotation: -18
                x: (-parent.width * 0.55) + (parent.width * 1.25 * root.auraPhase)
                y: -parent.height * 0.25
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.00) }
                    GradientStop { position: 0.5; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.themeIsDark ? 0.14 : 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.00) }
                }
            }
        }
    }

    Item {
        id: contentBox
        anchors.fill: parent

        GridLayout {
            id: contentGrid
            anchors.centerIn: parent
            columns: root.vertical ? 1 : 2
            rows: root.vertical ? 2 : 1
            columnSpacing: root.gap

            Item {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.weatherIcon()
                    fill: 1
                    iconSize: Math.max(26, Appearance.font.pixelSize.small + 8)
                    color: root.accent
                    scale: 1.0 + 0.08 * root.beatAmt
                }
            }

            Item {
                id: textWrapper
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
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
                        spacing: 10

                        StyledText {
                            text: root.tempText
                            font.family: "Montserrat, Arial Black, Lexend, sans-serif"
                            font.pixelSize: Appearance.font.pixelSize.small + 6
                            font.weight: Font.Black
                            color: Appearance.m3colors.m3tertiary
                            renderType: Text.NativeRendering
                        }

                        StyledText {
                            visible: root.cityText !== ""
                            text: root.cityText
                            font.family: "Montserrat, Arial Black, Lexend, sans-serif"
                            font.pixelSize: Appearance.font.pixelSize.tiny + 4
                            font.weight: Font.Black
                            color: Appearance.m3colors.m3primary
                            elide: Text.ElideRight
                            Layout.maximumWidth: 170
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: weatherPopupLoader
        source: "../ClockWidgetPopup.qml"
    }
}
