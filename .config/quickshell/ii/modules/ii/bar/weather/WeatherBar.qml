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

    property int padX: root.vertical ? 8 : 14
    property int padY: root.vertical ? 8 : 12
    property int gap: 10
    property int radius: 16

    hoverEnabled: false
    preventStealing: true
    acceptedButtons: Qt.RightButton

    Layout.fillHeight: true
    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (contentGrid.implicitWidth + padX * 2)
    implicitHeight: root.vertical ? (contentGrid.implicitHeight + padY * 2) : Math.max(36, contentGrid.implicitHeight + padY * 2)

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode) ? Appearance.m3colors.darkmode : false
    readonly property color fg: Appearance.colors.colOnLayer1
    readonly property color fgSoft: Appearance.colors.colOnLayer2
    readonly property color plateBase: Appearance.colors.colLayer1
    readonly property color plateBorderBase: Appearance.colors.colLayer3

    readonly property var w: Weather.data
    readonly property var wCode: w?.wCode
    readonly property string tempText: (w?.temp !== undefined && w?.temp !== null) ? ("" + w.temp + "°") : "--°"
    readonly property string cityText: {
        var c = w?.city ?? w?.location ?? w?.name ?? w?.place ?? ""
        c = (c === null || c === undefined) ? "" : ("" + c).trim()
        if (c.length > 22) c = c.slice(0, 22) + "…"
        return c
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            Weather.getData()
            Quickshell.execDetached([
                "notify-send",
                Translation.tr("Weather"),
                Translation.tr("Refreshing (manually triggered)"),
                "-a", "Shell"
            ])
        }
    }

    function _codeStr() { return (wCode === undefined || wCode === null) ? "" : ("" + wCode).toLowerCase().trim() }

    function isNight() {
        if (w?.isDay !== undefined) return w.isDay === 0 || w.isDay === false;
        if (w?.is_day !== undefined) return w.is_day === 0;
        
        var hour = new Date().getHours();
        return hour < 6 || hour >= 18;
    }

    function weatherKind() {
        var s = _codeStr()
        var n = parseInt(s)
        if (!isNaN(n)) {
            if (n >= 200 && n < 300) return "storm"
            if (n >= 300 && n < 600) return "rain"
            if (n >= 600 && n < 700) return "snow"
            if (n >= 700 && n < 800) return "fog"
            if (n === 800) return "clear"
            if (n > 800 && n < 900) return "cloud"
        }
        if (s.indexOf("thunder") !== -1 || s.indexOf("storm") !== -1) return "storm"
        if (s.indexOf("rain") !== -1 || s.indexOf("drizzle") !== -1 || s.indexOf("shower") !== -1) return "rain"
        if (s.indexOf("snow") !== -1 || s.indexOf("sleet") !== -1 || s.indexOf("hail") !== -1) return "snow"
        if (s.indexOf("fog") !== -1 || s.indexOf("mist") !== -1 || s.indexOf("haze") !== -1) return "fog"
        if (s.indexOf("cloud") !== -1 || s.indexOf("overcast") !== -1) return "cloud"
        if (s.indexOf("clear") !== -1 || s.indexOf("sun") !== -1) return "clear"
        return "default"
    }

    function getWeatherIconPath() {
        var basePath = "file:///home/jcgomez91/.config/quickshell/ii/assets/icons/google-weather/"
        var night = isNight()

        switch (weatherKind()) {
            case "clear": return basePath + (night ? "clear_night.svg" : "clear_day.svg")
            case "cloud": return basePath + (night ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg")
            case "rain":  return basePath + (night ? "scattered_showers_night.svg" : "showers_rain.svg")
            case "storm": return basePath + (night ? "isolated_scattered_thunderstorms_night.svg" : "isolated_scattered_thunderstorms_day.svg")
            case "snow":  return basePath + (night ? "scattered_snow_showers_night.svg" : "scattered_snow_showers_day.svg")
            case "fog":   return basePath + "haze_fog_dust_smoke.svg"
            default:      return basePath + (night ? "mostly_clear_night.svg" : "mostly_clear_day.svg")
        }
    }

    function accentBase() {
        switch (weatherKind()) {
        case "clear": return Qt.rgba(1.00, 0.78, 0.18, 1.0)
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
        var t = _clamp(themeIsDark ? 0.55 : 0.48, 0.20, 0.92)
        var m = Qt.rgba(a.r * 0.65 + p.r * 0.35, a.g * 0.65 + p.g * 0.35, a.b * 0.65 + p.b * 0.35, 1.0)
        return Qt.rgba(fg.r * (1.0 - t) + m.r * t, fg.g * (1.0 - t) + m.g * t, fg.b * (1.0 - t) + m.b * t, 1.0)
    }

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: root.vertical ? width / 2 : root.radius
        antialiasing: true
        color: "transparent"
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: ColorUtils.transparentize(root.plateBase, root.themeIsDark ? 0.32 : 0.52)
            opacity: 0.24
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

                Image {
                    anchors.centerIn: parent
                    source: root.getWeatherIconPath()
                    sourceSize.width: Math.max(26, Appearance.font.pixelSize.small + 8)
                    sourceSize.height: Math.max(26, Appearance.font.pixelSize.small + 8)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
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
}
