import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtQuick.Controls as QQC2

import Quickshell
import Quickshell.Io

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true
    interactive: true

     property string wallpapersDir: (Directories.home && ("" + Directories.home).length > 0)
                                  ? ("" + Directories.home + "/Pictures/Wallpapers")
                                  : ((Quickshell.env("HOME") || "/home/jcgomez91") + "/Pictures/Wallpapers")

    property int thumbSize: 72
    property bool roundedThumbs: false

     property bool allowThumbs: false
    Component.onCompleted: Qt.callLater(function() { page.allowThumbs = true })

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: function(data) {
                randomWallProc.status = (data ? ("" + data).trim() : "")
            }
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: btn
        required property bool dark

        property color colText: enabled
                               ? (toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2)
                               : Appearance.colors.colOnLayer3

        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2

        onClicked: {
            Quickshell.execDetached(["bash", "-c",
                `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`
            ])
        }

        StyledToolTip {
            extraVisibleCondition: !btn.enabled
            text: Translation.tr("Custom color scheme has been selected")
        }

        contentItem: Item {
            anchors.centerIn: parent
            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                MaterialSymbol {
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    fill: toggled ? 1 : 0
                    color: btn.colText
                }

                StyledText {
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: btn.colText
                }
            }
        }
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
                id: scrubWrap
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                visible: folder.count > 0 && list.contentWidth > list.width

                function maxHandleX() { return Math.max(0, scrubWrap.width - handle.width) }

                function handleWidth() {
                    if (list.contentWidth <= 0) return scrubWrap.width
                    var ratio = Math.min(1.0, list.width / list.contentWidth)
                    return Math.max(28, scrubWrap.width * ratio)
                }

                function xFromContent() {
                    var maxContent = Math.max(0, list.contentWidth - list.width)
                    if (maxContent <= 0) return 0
                    var t = list.contentX / maxContent
                    return t * scrubWrap.maxHandleX()
                }

                function contentFromX(x) {
                    var maxContent = Math.max(0, list.contentWidth - list.width)
                    var maxHX = scrubWrap.maxHandleX()
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
                    id: handle
                    height: parent.height
                    width: scrubWrap.handleWidth()
                    radius: height / 2
                    color: Appearance.colors.colPrimary
                    opacity: dragArea.pressed ? 1.0 : 0.92

                        Binding {
                        target: handle
                        property: "x"
                        value: scrubWrap.xFromContent()
                        when: !dragArea.pressed
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        drag.target: handle
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: scrubWrap.maxHandleX()

                        onPositionChanged: {
                            if (!pressed) return
                            list.contentX = scrubWrap.contentFromX(handle.x)
                        }
                    }
                }

                    MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: function(mouse) {
                        var maxHX = scrubWrap.maxHandleX()
                        if (maxHX <= 0) return

                        var targetX = mouse.x - handle.width / 2
                        if (targetX < 0) targetX = 0
                        if (targetX > maxHX) targetX = maxHX
                        list.contentX = scrubWrap.contentFromX(targetX)
                    }
                }
            }

            Item { Layout.fillWidth: true; implicitHeight: 6 }
        }
    }

    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Item {
                    implicitWidth: 360
                    implicitHeight: 220

                    Image {
                        anchors.fill: parent
                        source: Config.options.background.wallpaperPath ? ("file://" + Config.options.background.wallpaperPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        smooth: true
                    }

                    Rectangle {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                        implicitWidth: Math.min(nameText.implicitWidth + 20, parent.width - 20)
                        implicitHeight: nameText.implicitHeight + 5
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

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        uniformCellSizes: true

                        SmallLightDarkPreferenceButton {
                            Layout.preferredHeight: 60
                            dark: false
                            enabled: Config.options.appearance.palette.type.startsWith("scheme")
                        }
                        SmallLightDarkPreferenceButton {
                            Layout.preferredHeight: 60
                            dark: true
                            enabled: Config.options.appearance.palette.type.startsWith("scheme")
                        }
                    }

                    StyledFlickable {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        clip: true
                        contentHeight: themeLayout.implicitHeight
                        contentWidth: width

                        ColumnLayout {
                            id: themeLayout
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: [
                                    { customTheme: false, builtInTheme: false },
                                    { customTheme: false, builtInTheme: true },
                                    { customTheme: true,  builtInTheme: false }
                                ]
                                delegate: ColorPreviewGrid {
                                    customTheme: modelData.customTheme
                                    builtInTheme: modelData.builtInTheme
                                }
                            }
                        }
                    }
                }
            }

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

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")
        Layout.topMargin: -25

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: function(newValue) {
                        Config.options.bar.bottom = (newValue & 1) !== 0
                        Config.options.bar.vertical = (newValue & 2) !== 0
                    }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Bar style")
                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: function(newValue) { Config.options.bar.cornerStyle = newValue }
                    options: [
                        { displayName: Translation.tr("Hug"),   icon: "line_curve",  value: 0 },
                        { displayName: Translation.tr("Float"), icon: "page_header", value: 1 },
                        { displayName: Translation.tr("Rect"),  icon: "toolbar",     value: 2 }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")
                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: function(newValue) { Config.options.appearance.fakeScreenRounding = newValue }
                    options: [
                        { displayName: Translation.tr("No"),                  icon: "close",           value: 0 },
                        { displayName: Translation.tr("Yes"),                 icon: "check",           value: 1 },
                        { displayName: Translation.tr("When not fullscreen"), icon: "fullscreen_exit", value: 2 },
                        { displayName: Translation.tr("Wrapped"),             icon: "capture",         value: 3 }
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
            onValueChanged: { Config.options.appearance.wrappedFrameThickness = value }
        }

        ContentSubsection {
            title: Translation.tr("Bar background style")
            tooltip: Translation.tr("Adaptive style makes the bar background transparent when there are no active windows")
            Layout.fillWidth: false

            ConfigSelectionArray {
                currentValue: Config.options.bar.barBackgroundStyle
                onSelected: function(newValue) { Config.options.bar.barBackgroundStyle = newValue }
                options: [
                    { displayName: Translation.tr("Visible"),     icon: "visibility",         value: 1 },
                    { displayName: Translation.tr("Adaptive"),    icon: "masked_transitions", value: 2 },
                    { displayName: Translation.tr("Transparent"), icon: "opacity",            value: 0 }
                ]
            }
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        Layout.topMargin: -20
        text: Translation.tr("Not all options are available in this app. You should also check the config file by hitting the \"Config file\" button on the topleft corner or opening ~/.config/illogical-impulse/config.json manually.")

        RippleButtonWithIcon {
            id: copyPathButton
            property bool justCopied: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")

            onClicked: {
                copyPathButton.justCopied = true
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`)
                revertTextTimer.restart()
            }

            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer
                interval: 1500
                onTriggered: function() { copyPathButton.justCopied = false }
            }
        }
    }
}

