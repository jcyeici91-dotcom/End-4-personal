pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

import qs.modules.ii.background.widgets.clock.dateIndicator
import qs.modules.ii.background.widgets.clock.minuteMarks

import qs.modules.ii.ui 1.0

Item {
    id: root

    readonly property string clockStyle: Config.options.background.widgets.clock.style

    property real implicitSize: 230

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colPrimaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colSecondary, Appearance.colors.colPrimaryContainer, 0.15)
    property color colBackgroundInfo: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.55)
    property color colHourHand: Appearance.colors.colPrimary
    property color colMinuteHand: Appearance.colors.colTertiary
    property color colSecondHand: Appearance.colors.colPrimary

    readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: DateTime.clock.minutes
    readonly property int clockSecond: DateTime.clock.seconds

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _styleFromUIState() {
        const s = (typeof UIState !== "undefined" && UIState) ? UIState.surfaceStyle : ""
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode !== undefined)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    // Color del shape: SOLID = original, CRYSTAL = translúcido
    readonly property color bgShapeColor: bgIsCrystal
        ? Qt.rgba(root.colBackground.r, root.colBackground.g, root.colBackground.b, themeIsDark ? 0.28 : 0.22)
        : root.colBackground

    readonly property color crystalTint: themeIsDark
        ? Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.18)
        : Qt.rgba(1, 1, 1, 0.14)

    readonly property color crystalRimOuter: themeIsDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.14)
    readonly property color crystalRimInner: themeIsDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.28)

    function applyStyle(sides, dialStyle, hourHandStyle, minuteHandStyle, secondHandStyle, dateStyle) {
        Config.options.background.widgets.clock.cookie.sides = sides
        Config.options.background.widgets.clock.cookie.dialNumberStyle = dialStyle
        Config.options.background.widgets.clock.cookie.hourHandStyle = hourHandStyle
        Config.options.background.widgets.clock.cookie.minuteHandStyle = minuteHandStyle
        Config.options.background.widgets.clock.cookie.secondHandStyle = secondHandStyle
        Config.options.background.widgets.clock.cookie.dateStyle = dateStyle
    }

    function setClockPreset(category) {
        if (!Config.options.background.widgets.clock.cookie.aiStyling) return;
        if (category === "") return;
        print("[Cookie clock] Setting clock preset for category: " + category)
        if (category == "abstract") {
            applyStyle(9, "none", "fill", "medium", "dot", "bubble")
        } else if (category == "anime") {
            applyStyle(7, "none", "fill", "bold", "dot", "bubble")
        } else if (category == "city" || category == "space") {
            applyStyle(23, "full", "hollow", "thin", "classic", "bubble")
        } else if (category == "minimalist") {
            applyStyle(6, "none", "fill", "bold", "dot", "hide")
        } else if (category == "landscape") {
            applyStyle(14, "full", "hollow", "medium", "classic", "bubble")
        } else if (category == "plants") {
            applyStyle(9, "dots", "fill", "bold", "dot", "border")
        } else if (category == "person") {
            applyStyle(14, "full", "classic", "classic", "classic", "rect")
        }
    }

    FileView {
        id: categoryFileView
        path: Directories.generatedWallpaperCategoryPath
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: root.setClockPreset(categoryFileView.text().trim())
    }

    property string backgroundStyle: Config.options.background.widgets.clock.cookie.backgroundStyle

    readonly property Item activeBgItem: (backgroundStyle === "sine")
        ? sineCookieLoader.item
        : (backgroundStyle === "cookie")
            ? roundedPolygonCookieLoader.item
            : materialShapeCookieLoader.item

    StyledDropShadow {
        target: backgroundStyle === "sine" ? sineCookieLoader
             : backgroundStyle === "cookie" ? roundedPolygonCookieLoader
             : materialShapeCookieLoader

        RotationAnimation on rotation {
            running: Config.options.background.widgets.clock.cookie.constantlyRotate
            duration: 30000
            easing.type: Easing.Linear
            loops: Animation.Infinite
            from: 360
            to: 0
        }
    }

    Loader {
        id: sineCookieLoader
        z: 0
        visible: false // DropShadow lo dibuja
        active: backgroundStyle === "sine"
        sourceComponent: SineCookie {
            implicitSize: root.implicitSize
            sides: Config.options.background.widgets.clock.cookie.sides
            color: root.bgShapeColor
        }
    }

    Loader {
        id: roundedPolygonCookieLoader
        z: 0
        visible: false // DropShadow lo dibuja
        active: backgroundStyle === "cookie"
        sourceComponent: MaterialCookie {
            implicitSize: root.implicitSize
            sides: Config.options.background.widgets.clock.cookie.sides
            color: root.bgShapeColor
        }
    }

    Loader {
        id: materialShapeCookieLoader
        z: 0
        visible: false // DropShadow lo dibuja
        active: backgroundStyle === "shape"
        sourceComponent: MaterialShape {
            implicitSize: root.implicitSize
            color: root.bgShapeColor
            shapeString: Config.options.background.widgets.clock.cookie.backgroundShape
        }
    }

    Loader {
        id: crystalOverlayLoader
        active: root.bgIsCrystal && root.activeBgItem !== null
        asynchronous: false
        z: 0.5
        anchors.fill: parent

        sourceComponent: Item {
            anchors.fill: parent

            ShaderEffectSource {
                id: maskSource
                sourceItem: root.activeBgItem
                live: true
                hideSource: false   // <- clave: NO tocar el source del fondo
                visible: false
            }

            Item {
                id: overlaySource
                anchors.fill: parent
                visible: false

                Rectangle { anchors.fill: parent; color: root.crystalTint }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.20 : 0.30) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.06 : 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.themeIsDark ? 0.14 : 0.08) }
                    }
                    opacity: 0.95
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.10 : 0.16) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    transform: Rotation {
                        origin.x: overlaySource.width / 2
                        origin.y: overlaySource.height / 2
                        angle: -18
                    }
                    opacity: 0.85
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: root.crystalRimOuter
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: "transparent"
                    border.width: 1
                    border.color: root.crystalRimInner
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: overlaySource
                maskSource: maskSource
            }
        }
    }

    // Hour/minutes marks
    MinuteMarks {
        anchors.fill: parent
        color: root.colOnBackground
        z: 1
    }

    FadeLoader {
        id: hourMarksLoader
        anchors.centerIn: parent
        shown: Config.options.background.widgets.clock.cookie.hourMarks
        z: 2
        sourceComponent: HourMarks {
            implicitSize: 135 * (1.75 - 0.75 * hourMarksLoader.opacity)
            color: root.colOnBackground
            colOnBackground: ColorUtils.mix(root.colBackgroundInfo, root.colOnBackground, 0.5)
        }
    }

    FadeLoader {
        id: timeColumnLoader
        anchors.centerIn: parent
        shown: Config.options.background.widgets.clock.cookie.timeIndicators
        z: 3
        scale: 1.4 - 0.4 * timeColumnLoader.shown
        Behavior on scale { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }
        sourceComponent: TimeColumn { color: root.colBackgroundInfo }
    }

    FadeLoader {
        anchors.fill: parent
        z: 4
        shown: Config.options.background.widgets.clock.cookie.minuteHandStyle !== "hide"
        sourceComponent: MinuteHand {
            anchors.fill: parent
            clockMinute: root.clockMinute
            style: Config.options.background.widgets.clock.cookie.minuteHandStyle
            color: root.colMinuteHand
        }
    }

    FadeLoader {
        anchors.fill: parent
        z: item?.style === "hollow" ? 3 : 5
        shown: Config.options.background.widgets.clock.cookie.hourHandStyle !== "hide"
        sourceComponent: HourHand {
            clockHour: root.clockHour
            clockMinute: root.clockMinute
            style: Config.options.background.widgets.clock.cookie.hourHandStyle
            color: root.colHourHand
        }
    }

    FadeLoader {
        id: secondHandLoader
        z: (Config.options.background.widgets.clock.cookie.secondHandStyle === "line") ? 6 : 7
        shown: Config.options.time.secondPrecision && Config.options.background.widgets.clock.cookie.secondHandStyle !== "hide"
        anchors.fill: parent
        sourceComponent: SecondHand {
            id: secondHand
            clockSecond: root.clockSecond
            style: Config.options.background.widgets.clock.cookie.secondHandStyle
            color: root.colSecondHand
        }
    }

    FadeLoader {
        z: 8
        anchors.centerIn: parent
        shown: Config.options.background.widgets.clock.cookie.minuteHandStyle !== "bold"
        sourceComponent: Rectangle {
            color: Config.options.background.widgets.clock.cookie.minuteHandStyle === "medium"
                ? root.bgShapeColor
                : root.colMinuteHand
            implicitWidth: 6
            implicitHeight: implicitWidth
            radius: width / 2
        }
    }

    FadeLoader {
        anchors.fill: parent
        z: 9
        shown: Config.options.background.widgets.clock.cookie.dateStyle !== "hide"
        sourceComponent: DateIndicator {
            color: root.colBackgroundInfo
            style: Config.options.background.widgets.clock.cookie.dateStyle
        }
    }
}

