import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import Quickshell
import Quickshell.Io

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: tp
    Layout.fillWidth: true

    property int itemWidth: 112
    property int itemHeight: 60
    property int chipHeight: 20
    property int stripPadding: 6
    property int stripRadius: Appearance.rounding.normal
    property int stripSpacing: 6
    property int scrubHeight: 6
    property int scrubMinHandle: 26

    implicitHeight: titleRow.implicitHeight + 10 + (tp.itemHeight + tp.stripPadding * 2) + (scrubWrap.visible ? (6 + tp.scrubHeight) : 0)

    readonly property list<string> builtInColorSchemes: [
        "angel_light", "angel", "ayu", "cobalt2", "cursor", "dracula", "flexoki",
        "frappe", "github", "gruvbox", "kanagawa", "latte", "macchiato",
        "material_ocean", "matrix", "mercury", "mocha", "nord", "open_code",
        "orng", "osaka_jade", "rose_pine", "sakura", "samurai", "synthwave84",
        "vercel", "vesper", "zen_burn", "zen_garden"
    ]
    property list<string> customColorSchemes: (Config.options.appearance.customColorSchemes ?? [])
    readonly property list<string> extraCustomSchemes: [
        "espresso", "mocha_cream", "ink_olive", "carbon_amber", "midnight_plum",
        "obsidian_teal", "cocoa_rose", "night_sand", "smoke_blue", "noir_copper"
    ]
    readonly property list<string> wallpaperColorSchemes: [
        "scheme-auto", "scheme-content", "scheme-tonal-spot", "scheme-fidelity",
        "scheme-fruit-salad", "scheme-expressive", "scheme-rainbow", "scheme-neutral", "scheme-monochrome"
    ]

    function uniq(list) {
        const out = []
        const seen = {}
        for (let i = 0; i < (list ? list.length : 0); i++) {
            const v = "" + list[i]
            if (!v || seen[v]) continue
            seen[v] = true
            out.push(v)
        }
        return out
    }

    readonly property list<string> effectiveCustomSchemes: uniq(customColorSchemes.concat(extraCustomSchemes))

    function formatText(text, isWallpaperScheme) {
        if (!isWallpaperScheme) return text.charAt(0).toUpperCase() + text.slice(1)
        const sliced = ("" + text).split("-").slice(1).join(" ")
        return sliced.charAt(0).toUpperCase() + sliced.slice(1)
    }

    property var combinedModel: ([])

    function rebuildModel() {
        const m = []
        m.push({ kind: "chip", title: Translation.tr("Schemes") })
        for (let i = 0; i < tp.wallpaperColorSchemes.length; i++) {
            const s = tp.wallpaperColorSchemes[i]
            m.push({ kind: "theme", scheme: s, display: tp.formatText(s, true), customTheme: false, builtInTheme: false })
        }
        m.push({ kind: "chip", title: Translation.tr("Built-in") })
        for (let j = 0; j < tp.builtInColorSchemes.length; j++) {
            const b = tp.builtInColorSchemes[j]
            m.push({ kind: "theme", scheme: b, display: tp.formatText(b, false), customTheme: false, builtInTheme: true })
        }
        m.push({ kind: "chip", title: Translation.tr("Custom") })
        for (let k = 0; k < tp.effectiveCustomSchemes.length; k++) {
            const c = tp.effectiveCustomSchemes[k]
            m.push({ kind: "theme", scheme: c, display: tp.formatText(c, false), customTheme: true, builtInTheme: false })
        }
        tp.combinedModel = m
        tp.restartLazyLoad()
    }

    property int loadedThemeCount: 0
    property int totalThemes: 0

    function restartLazyLoad() {
        let n = 0
        for (let i = 0; i < tp.combinedModel.length; i++) {
            if (tp.combinedModel[i].kind === "theme") n++
        }
        tp.totalThemes = n
        tp.loadedThemeCount = 0
        loadTimer.stop()
        Qt.callLater(function() { loadTimer.start() })
    }

    function maxContentX() { return Math.max(0, themeList.contentWidth - themeList.width) }
    function clampContentX(x) {
        var maxX = tp.maxContentX()
        if (x < 0) return 0
        if (x > maxX) return maxX
        return x
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            id: titleRow
            Layout.fillWidth: true
            StyledText {
                text: Translation.tr("Themes")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: tp.itemHeight + tp.stripPadding * 2
            radius: tp.stripRadius
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer2
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: tp.stripRadius
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.93)
                opacity: 0.40
            }

            ListView {
                id: themeList
                anchors.fill: parent
                anchors.margins: tp.stripPadding
                orientation: ListView.Horizontal
                spacing: tp.stripSpacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds
                model: tp.combinedModel

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(w) {
                        var delta = w.angleDelta.y
                        if (delta === 0) return
                        themeList.contentX = tp.clampContentX(themeList.contentX - delta)
                        w.accepted = true
                    }
                }

                delegate: Item {
                    height: themeList.height
                    width: (modelData.kind === "chip") ? chip.implicitWidth : tp.itemWidth

                    Rectangle {
                        id: chip
                        anchors.verticalCenter: parent.verticalCenter
                        height: tp.chipHeight
                        radius: height / 2
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colLayer3
                        visible: modelData.kind === "chip"
                        implicitWidth: Math.max(74, chipText.implicitWidth + 16)

                        StyledText {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData.kind === "chip" ? modelData.title : ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                        }
                    }

                    Item {
                        id: themeWrap
                        anchors.verticalCenter: parent.verticalCenter
                        width: tp.itemWidth
                        height: tp.itemHeight
                        visible: modelData.kind === "theme"

                        property int themeIndex: {
                            var c = -1
                            for (var i = 0; i <= index && i < tp.combinedModel.length; i++) {
                                if (tp.combinedModel[i].kind === "theme") c++
                            }
                            return c
                        }

                        ColorPreviewButton {
                            anchors.fill: parent
                            colorScheme: modelData.scheme
                            colorSchemeDisplayName: modelData.display
                            customTheme: modelData.customTheme
                            builtInTheme: modelData.builtInTheme
                            shouldLoad: themeWrap.themeIndex < tp.loadedThemeCount
                        }
                    }
                }
            }
        }

        Item {
            id: scrubWrap
            Layout.fillWidth: true
            implicitHeight: tp.scrubHeight
            visible: themeList.contentWidth > themeList.width

            function maxHandleX() { return Math.max(0, scrubWrap.width - handle.width) }
            function handleWidth() {
                if (themeList.contentWidth <= 0) return scrubWrap.width
                var ratio = Math.min(1.0, themeList.width / themeList.contentWidth)
                return Math.max(tp.scrubMinHandle, scrubWrap.width * ratio)
            }
            function xFromContent() {
                var maxContent = Math.max(0, themeList.contentWidth - themeList.width)
                if (maxContent <= 0) return 0
                var t = themeList.contentX / maxContent
                return t * scrubWrap.maxHandleX()
            }
            function contentFromX(x) {
                var maxContent = Math.max(0, themeList.contentWidth - themeList.width)
                var maxHX = scrubWrap.maxHandleX()
                if (maxContent <= 0 || maxHX <= 0) return 0
                var t = x / maxHX
                return tp.clampContentX(t * maxContent)
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colLayer3
                opacity: 0.55
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.LeftButton
                onClicked: function(mouse) {
                    var maxHX = scrubWrap.maxHandleX()
                    if (maxHX <= 0) return
                    var targetX = mouse.x - handle.width / 2
                    if (targetX < 0) targetX = 0
                    if (targetX > maxHX) targetX = maxHX
                    themeList.contentX = scrubWrap.contentFromX(targetX)
                }
            }

            Rectangle {
                id: handle
                z: 1
                height: parent.height
                width: scrubWrap.handleWidth()
                radius: height / 2
                color: Appearance.colors.colPrimary
                opacity: dragArea.drag.active ? 1.0 : 0.82

                Binding {
                    target: handle
                    property: "x"
                    value: scrubWrap.xFromContent()
                    when: !dragArea.drag.active
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    z: 2
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true

                    drag.target: handle
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: scrubWrap.maxHandleX()

                    onPositionChanged: {
                        if (!pressed) return
                        themeList.contentX = scrubWrap.contentFromX(handle.x)
                    }
                }
            }
        }
    }

    Timer {
        id: loadTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            tp.loadedThemeCount += 1
            if (tp.loadedThemeCount >= tp.totalThemes)
                loadTimer.stop()
        }
    }

    Component.onCompleted: tp.rebuildModel()
    onCustomColorSchemesChanged: tp.rebuildModel()
}
