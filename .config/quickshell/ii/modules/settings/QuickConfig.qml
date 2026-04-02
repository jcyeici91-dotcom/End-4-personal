import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    readonly property int index: 0
    property bool register: parent.register ?? false
    forceWidth: true
    interactive: true

    property bool allowHeavyLoad: false
    
    // Variables para la galería de wallpapers
    property string wallpapersDir: (Directories.home && ("" + Directories.home).length > 0)
                                  ? ("" + Directories.home + "/Pictures/Wallpapers")
                                  : ((Quickshell.env("HOME") || "/home/jcgomez91") + "/Pictures/Wallpapers")

    property int thumbSize: 72
    property bool roundedThumbs: false
    property bool allowThumbs: false

    Component.onCompleted: Qt.callLater(() => {
        page.allowHeavyLoad = true;
        page.allowThumbs = true;
    })

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: data => {
                randomWallProc.status = data ? ("" + data).trim() : "";
            }
        }
    }

    Process {
        id: modeSwitchProc
        property string pendingMode: ""
        command: []
        stdout: SplitParser { onRead: function(_) {} }
        stderr: SplitParser { onRead: function(_) {} }
    }

    // 👇 COMPONENTES DEL DISEÑO MODIFICADO 👇

    component LightDarkSegmented: Item {
        id: seg
        Layout.fillWidth: true
        implicitHeight: 56

        property bool enabled: true
        property bool hasPending: false
        property bool pendingDark: false

        readonly property bool appearanceDark: Appearance.m3colors.darkmode
        readonly property bool effectiveDark: hasPending ? pendingDark : appearanceDark

        function applyMode(dark) {
            hasPending = true
            pendingDark = dark
            pendingReset.restart()

            var script = ("" + Directories.wallpaperSwitchScriptPath)
            var args = ["--mode", (dark ? "dark" : "light")]

            modeSwitchProc.command = [script].concat(args)
            if (modeSwitchProc.running) {
                modeSwitchProc.kill()
            }
            modeSwitchProc.start()
        }

        onAppearanceDarkChanged: {
            if (hasPending && appearanceDark === pendingDark) {
                hasPending = false
            }
        }

        Timer {
            id: pendingReset
            interval: 1500
            repeat: false
            onTriggered: seg.hasPending = false
        }

        Rectangle {
            id: shell
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer2
            clip: true
            opacity: seg.enabled ? 1.0 : 0.65

            Rectangle {
                anchors.fill: parent
                radius: shell.radius
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.93)
                opacity: 0.40
            }

            Rectangle {
                id: indicator
                width: (shell.width - 10) / 2
                height: shell.height - 10
                y: 5
                x: seg.effectiveDark ? (shell.width - 5 - width) : 5
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.82)
                opacity: seg.enabled ? 1.0 : 0.6

                Behavior on x {
                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height * 0.45
                    radius: parent.radius
                    color: "white"
                    opacity: 0.08
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 6

                RippleButton {
                    enabled: seg.enabled
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92)
                    colRipple: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.80)
                    onClicked: seg.applyMode(false)
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "light_mode"
                            iconSize: 20
                            fill: seg.effectiveDark ? 0 : 1
                            color: seg.effectiveDark ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: Translation.tr("Light")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: seg.effectiveDark ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnPrimary
                        }
                    }
                }

                RippleButton {
                    enabled: seg.enabled
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92)
                    colRipple: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.80)
                    onClicked: seg.applyMode(true)
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "dark_mode"
                            iconSize: 20
                            fill: seg.effectiveDark ? 1 : 0
                            color: seg.effectiveDark ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Dark")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: seg.effectiveDark ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }

    component ThemePaletteStrip: Item {
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

        // 👇 CORRECCIÓN: Los Built-in originales se quedan como estaban 👇
        readonly property list<string> builtInColorSchemes: [
            "angel", "angel_light", "ayu", "cobalt2", "cursor", "dracula", "flexoki",
            "frappe", "github", "gruvbox", "kanagawa", "latte", "macchiato",
            "material_ocean", "matrix", "mercury", "mocha", "nord", "open_code",
            "orng", "osaka_jade", "rose_pine", "sakura", "samurai", "synthwave84",
            "vercel", "vesper", "zen_burn", "zen_garden"
        ]
        
        property list<string> customColorSchemes: (Config.options.appearance.customColorSchemes ?? [])
        
        // 👇 CORRECCIÓN: ¡Todos los temas de tu carpeta van aquí! (Custom Themes) 👇
        readonly property list<string> extraCustomSchemes: [
            "espresso", "mocha_cream", "ink_olive", "carbon_amber", "midnight_plum",
            "obsidian_teal", "cocoa_rose", "night_sand", "smoke_blue", "noir_copper",
            "cocoa_mint", "almond_cream", "amber_oat", "aqua_parchment", "blueberry_linen",
            "butter_biscuit", "cafe_con_leche", "cafe_con_leche_light", 
            "chamomile_cream", "chamomile_dune", "cinnamon_oatmilk", 
            "cream_sand", "golden_haze", "honey_cream", "kiwi_limeade", 
            "latte_honey", "lilac_oat", "linen_gold", "matcha_cream", 
            "mellow_mustard", "papaya_sherbet", "peach_biscuit", 
            "pistachio_oat", "plum_sorbet", "rose_almond", "saffron_latte", 
            "sakura_milk", "sky_cotton", "strawberry_cream", "sunset_apricot", 
            "turquoise_spritz", "vanilla_caramel"
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
                // 👇 Al ser 'customTheme: true', buscará en ~/.config/illogical-impulse/themes/ 👇
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
                                // Dejamos el LazyLoad original para que no se trabe, pero ahora en Custom.
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

    component WallpaperStrip: Item {
        id: ws
        property string dir: page.wallpapersDir
        property int size: page.thumbSize

        implicitHeight: titleRow.implicitHeight + 10 + (size + 28) + 8 + 8

        function ensureFileUrl(path) {
            if (!path) return ""
            var p = "" + path
            return p.indexOf("file://") === 0 ? p : ("file://" + p)
        }

        FolderListModel {
            id: folder
            folder: ws.ensureFileUrl(ws.dir)
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
            showDirs: false
            showDotAndDotDot: false
            sortField: FolderListModel.Name
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                id: titleRow
                Layout.fillWidth: true

                StyledText {
                    text: Translation.tr("Wallpaper gallery")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: ws.dir
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignRight
                    Layout.maximumWidth: 520
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                visible: folder.count === 0
                text: Translation.tr("No images found in: ") + ws.dir
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: ws.size + 28
                clip: true

                orientation: ListView.Horizontal
                spacing: 10
                model: folder

                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds

                function maxContentX() { return Math.max(0, list.contentWidth - list.width) }
                function clampContentX(x) {
                    var maxX = list.maxContentX()
                    if (x < 0) return 0
                    if (x > maxX) return maxX
                    return x
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(w) {
                        var delta = w.angleDelta.y
                        if (delta === 0) return
                        list.contentX = list.clampContentX(list.contentX - delta)
                        w.accepted = true
                    }
                }

                delegate: Item {
                    id: tile
                    width: ws.size
                    height: list.height

                    property string absPath: filePath
                    property string url: (typeof fileURL !== "undefined" && fileURL) ? ("" + fileURL)
                                      : ((typeof fileUrl !== "undefined" && fileUrl) ? ("" + fileUrl)
                                      : ws.ensureFileUrl(absPath))

                    property bool selected: Config.options.background.wallpaperPath === absPath

                    Rectangle {
                        id: frame
                        width: ws.size
                        height: ws.size
                        radius: page.roundedThumbs ? Appearance.rounding.normal : 0
                        color: Appearance.colors.colLayer2
                        border.width: selected ? 2 : 1
                        border.color: selected ? Appearance.colors.colPrimary : Appearance.colors.colLayer3

                        Image {
                            id: img
                            anchors.fill: parent
                            source: page.allowThumbs ? tile.url : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            sourceSize.width: ws.size * 2
                            sourceSize.height: ws.size * 2
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: (img.status === Image.Error) ? "broken_image" : "image"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer3
                            visible: img.status !== Image.Ready
                        }

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.92)
                            colRipple: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.72)
                            onClicked: { Config.options.background.wallpaperPath = tile.absPath }
                        }
                    }

                    StyledText {
                        anchors.top: frame.bottom
                        anchors.topMargin: 6
                        width: ws.size
                        text: fileName
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer3
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Item {
                id: scrubWrap2
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                visible: folder.count > 0 && list.contentWidth > list.width

                function maxHandleX() { return Math.max(0, scrubWrap2.width - handle2.width) }

                function handleWidth() {
                    if (list.contentWidth <= 0) return scrubWrap2.width
                    var ratio = Math.min(1.0, list.width / list.contentWidth)
                    return Math.max(28, scrubWrap2.width * ratio)
                }

                function xFromContent() {
                    var maxContent = Math.max(0, list.contentWidth - list.width)
                    if (maxContent <= 0) return 0
                    var t = list.contentX / maxContent
                    return t * scrubWrap2.maxHandleX()
                }

                function contentFromX(x) {
                    var maxContent = Math.max(0, list.contentWidth - list.width)
                    var maxHX = scrubWrap2.maxHandleX()
                    if (maxContent <= 0 || maxHX <= 0) return 0
                    var t = x / maxHX
                    return list.clampContentX(t * maxContent)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Appearance.colors.colLayer2
                    border.width: 1
                    border.color: Appearance.colors.colLayer3
                }

                Rectangle {
                    id: handle2
                    height: parent.height
                    width: scrubWrap2.handleWidth()
                    radius: height / 2
                    color: Appearance.colors.colPrimary
                    opacity: dragArea2.pressed ? 1.0 : 0.92

                    Binding {
                        target: handle2
                        property: "x"
                        value: scrubWrap2.xFromContent()
                        when: !dragArea2.pressed
                    }

                    MouseArea {
                        id: dragArea2
                        anchors.fill: parent
                        drag.target: handle2
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: scrubWrap2.maxHandleX()

                        onPositionChanged: {
                            if (!pressed) return
                            list.contentX = scrubWrap2.contentFromX(handle2.x)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: function(mouse) {
                        var maxHX = scrubWrap2.maxHandleX()
                        if (maxHX <= 0) return
                        var targetX = mouse.x - handle2.width / 2
                        if (targetX < 0) targetX = 0
                        if (targetX > maxHX) targetX = maxHX
                        list.contentX = scrubWrap2.contentFromX(targetX)
                    }
                }
            }

            Item { Layout.fillWidth: true; implicitHeight: 6 }
        }
    }

    // 👇 SECCIÓN PRINCIPAL: REEMPLAZADA CON EL DISEÑO NUEVO 👇

    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 290

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colLayer2
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Config.options.background.wallpaperPath ? ("file://" + Config.options.background.wallpaperPath) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: "black"
                            opacity: 0.12
                        }

                        Rectangle {
                            anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                            implicitWidth: Math.min(nameText.implicitWidth + 20, parent.width - 20)
                            implicitHeight: nameText.implicitHeight + 6
                            color: Appearance.colors.colPrimary
                            radius: Appearance.rounding.full

                            StyledText {
                                id: nameText
                                anchors.centerIn: parent
                                property string fileName: {
                                    var p = Config.options.background.wallpaperPath
                                    if (!p) return ""
                                    var parts = ("" + p).split("/")
                                    return parts[parts.length - 1]
                                }
                                text: fileName.length > 30 ? (fileName.slice(0, 27) + "...") : fileName
                                color: Appearance.colors.colOnPrimary
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }
                }

                LightDarkSegmented {
                    Layout.fillWidth: true
                }
            }

            ThemePaletteStrip { Layout.fillWidth: true }

            WallpaperStrip {
                Layout.fillWidth: true
                dir: page.wallpapersDir
                size: page.thumbSize
            }

            ConfigRow {
                uniform: true
                Layout.fillWidth: true

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
                        randomWallProc.running = true
                    }
                    StyledToolTip {
                        text: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_osu_wall.sh`
                        randomWallProc.running = true
                    }
                    StyledToolTip {
                        text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "ev_shadow"
                text: Translation.tr("Transparency")
                checked: Config.options.appearance.transparency.enable
                onCheckedChanged: { Config.options.appearance.transparency.enable = checked }
            }
        }
    }

    // 👇 SECCIÓN ORIGINAL: "BAR & SCREEN" (INTACTA) 👇

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")
        Layout.topMargin: -25

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        { displayName: Translation.tr("Top"), icon: "arrow_upward", value: 0 },
                        { displayName: Translation.tr("Left"), icon: "arrow_back", value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"), icon: "arrow_forward", value: 3 }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")
                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => { Config.options.bar.cornerStyle = newValue; }
                    options: [
                        { displayName: Translation.tr("Hug"), icon: "line_curve", value: 0 },
                        { displayName: Translation.tr("Float"), icon: "page_header", value: 1 }
                     ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")
                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => { Config.options.appearance.fakeScreenRounding = newValue; }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                        { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 },
                        { displayName: Translation.tr("Wrapped"), icon: "capture", value: 3 }
                    ]
                }
            }
        }

        ConfigSpinBox {
            visible: Config.options.appearance.fakeScreenRounding === 3
            icon: "line_weight"
            text: Translation.tr("Wrapped frame thickness")
            value: Config.options.appearance.wrappedFrameThickness
            from: 5
            to: 25
            stepSize: 1
            onValueChanged: { Config.options.appearance.wrappedFrameThickness = value; }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar background style")
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.bar.barBackgroundStyle
                    onSelected: newValue => { Config.options.bar.barBackgroundStyle = newValue; }
                    options: [ 
                        { displayName: Translation.tr("Visible"), icon: "visibility", value: 1 }, 
                      { displayName: Translation.tr("Transparent"), icon: "opacity", value: 0 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Rounding style")
                tooltip: Translation.tr("Sharp mode is experimental")
                Layout.fillWidth: false
                ConfigSelectionArray {
                    currentValue: Config.options.appearance.sharpMode
                    onSelected: newValue => {
                        Config.options.appearance.sharpMode = newValue;
                        if (!Config.options.appearance.toggleWindowRounding) return;
                        if (newValue) {
                            Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", "0"])
                        } else {
                            Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", "18"])
                        }
                    }
                    options: [ 
                        { displayName: Translation.tr("Default"), icon: "rounded_corner", value: false }, 
                        { displayName: Translation.tr("Sharp"), icon: "square", value: true }
                    ]
                }
            }
        }
    }

    // 👇 NUEVA SECCIÓN DE RENDIMIENTO 👇
    ContentSection {
        icon: "speed"
        title: Translation.tr("Performance & Animations")
        Layout.fillWidth: true

        ConfigRow {
            Layout.fillWidth: true
            ConfigSwitch {
                buttonIcon: "animation"
                text: Translation.tr("Enable GIFs and heavy animations")
                checked: Config.options.appearance.enableAnimations
                onCheckedChanged: { Config.options.appearance.enableAnimations = checked }
            }
        }
    }
    }
