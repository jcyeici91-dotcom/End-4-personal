import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Qt.labs.platform 1.1

import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: page
    required property var theme

    property url wallpapersFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] + "/Wallpapers"

    property string selectedPath: ""
    property bool reduceMotion: false

    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    readonly property color surface0: Appearance.colors.colLayer0
    readonly property color surface1: Appearance.colors.colLayer1

    readonly property color border0: (Appearance.colors.colLayer1Border !== undefined)
        ? Appearance.colors.colLayer1Border
        : _rgba(Appearance.colors.colOnLayer1, themeIsDark ? 0.14 : 0.18)

    readonly property color onSurface: Appearance.colors.colOnLayer1
    readonly property color onSurfaceMuted: _rgba(onSurface, 0.75)

    readonly property color accent: (page.theme && page.theme.colAccent)
        ? page.theme.colAccent
        : (Appearance.colors.colPrimary !== undefined ? Appearance.colors.colPrimary : Qt.rgba(0.45, 0.65, 1.0, 1.0))

    readonly property string fontMain: (page.theme && page.theme.fontMain) ? page.theme.fontMain : ""

    readonly property color overlayInk: _rgba(onSurface, 0.10)
    readonly property color overlayInkPressed: _rgba(onSurface, 0.22)

    readonly property color selectionChipBg: _rgba(accent, 0.16)
    readonly property color selectionChipBorder: _rgba(accent, 0.18)

    readonly property color cardShadow: Qt.rgba(0, 0, 0, themeIsDark ? 0.35 : 0.22)
    readonly property color imagePlaceholder: _rgba(onSurface, 0.06)

    function toCleanPath(fileUrl) {
        return fileUrl.toString().replace("file://", "")
    }

    function applyWallpaper(cleanPath) {
        page.selectedPath = cleanPath
        Wallpapers.select(cleanPath, Appearance.m3colors.darkmode)
    }

    function pickRandomWallpaper() {
        if (wallpaperModel.count <= 0) return
        var idx = Math.floor(Math.random() * wallpaperModel.count)
        var url = wallpaperModel.get(idx, "fileUrl")
        var clean = page.toCleanPath(url)
        page.applyWallpaper(clean)
    }

    function rescanWallpapers() {
        var f = page.wallpapersFolder
        wallpaperModel.folder = ""
        wallpaperModel.folder = f
    }

    FolderListModel {
        id: wallpaperModel
        folder: page.wallpapersFolder
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            id: headerCard
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 18
            color: page.surface1
            border.width: 1
            border.color: page.border0
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: page.selectionChipBg
                    border.width: 1
                    border.color: page.selectionChipBorder

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "palette"
                        color: page.accent
                        font.pixelSize: 20
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: Translation.tr("Wallpapers.GalleryTitle")
                        color: page.onSurface
                        font.pixelSize: 16
                        font.bold: true
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }

                    Text {
                        text: wallpaperModel.count > 0
                              ? Translation.tr("Wallpapers.ImageCount").arg(wallpaperModel.count)
                              : Translation.tr("Wallpapers.NoImages")
                        color: page.onSurfaceMuted
                        font.pixelSize: 11
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: page.overlayInk
                        border.width: 1
                        border.color: _rgba(page.onSurface, 0.10)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "shuffle"
                            color: page.onSurface
                            font.pixelSize: 18
                            opacity: 0.90
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 17
                            color: _rgba(page.onSurface, 1.0)
                            opacity: rndMouse.pressed ? 0.12 : (rndMouse.containsMouse ? 0.06 : 0.0)
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                        }

                        MouseArea {
                            id: rndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.pickRandomWallpaper()
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: page.overlayInk
                        border.width: 1
                        border.color: _rgba(page.onSurface, 0.10)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            color: page.onSurface
                            font.pixelSize: 18
                            opacity: 0.90
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 17
                            color: _rgba(page.onSurface, 1.0)
                            opacity: refMouse.pressed ? 0.12 : (refMouse.containsMouse ? 0.06 : 0.0)
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                        }

                        MouseArea {
                            id: refMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.rescanWallpapers()
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: page.reduceMotion ? _rgba(page.accent, 0.18) : page.overlayInk
                        border.width: 1
                        border.color: page.reduceMotion ? _rgba(page.accent, 0.35) : _rgba(page.onSurface, 0.10)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: page.reduceMotion ? "motion_photos_off" : "motion_photos_on"
                            color: page.reduceMotion ? page.accent : page.onSurface
                            font.pixelSize: 18
                            opacity: 0.95
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 17
                            color: _rgba(page.onSurface, 1.0)
                            opacity: motMouse.pressed ? 0.12 : (motMouse.containsMouse ? 0.06 : 0.0)
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                        }

                        MouseArea {
                            id: motMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.reduceMotion = !page.reduceMotion
                        }
                    }
                }
            }
        }

        GridView {
            id: wallGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            readonly property int columns: width < 420 ? 1 : 2
            readonly property int gap: 10

            cellWidth: Math.floor((width - (gap * (columns - 1))) / columns)
            cellHeight: 176

            model: wallpaperModel
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 800

            ScrollBar.vertical: ScrollBar {
                id: vbar
                policy: ScrollBar.AsNeeded
                width: 8
                active: wallGrid.moving || wallGrid.flicking

                contentItem: Rectangle {
                    radius: 4
                    color: vbar.pressed ? _rgba(page.onSurface, 0.55) : _rgba(page.onSurface, 0.35)
                }

                background: Rectangle {
                    radius: 4
                    color: _rgba(page.onSurface, 0.08)
                }
            }

            delegate: Item {
                width: wallGrid.cellWidth
                height: wallGrid.cellHeight

                readonly property string cleanPath: page.toCleanPath(fileUrl)
                readonly property bool isSelected: page.selectedPath === cleanPath

                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.rightMargin: (index % wallGrid.columns === wallGrid.columns - 1) ? 0 : wallGrid.gap
                    radius: 16
                    color: page.surface1
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? _rgba(page.accent, 0.90) : page.border0
                    clip: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: page.cardShadow
                        shadowBlur: 0.70
                        shadowVerticalOffset: 2
                        shadowHorizontalOffset: 0
                    }

                    Image {
                        id: img
                        anchors.fill: parent
                        source: fileUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 600
                        smooth: true
                    }

                    Rectangle {
                        id: placeholder
                        anchors.fill: parent
                        visible: img.status !== Image.Ready
                        color: page.imagePlaceholder

                        Rectangle {
                            id: shimmer
                            width: parent.width * 0.45
                            height: parent.height
                            x: -width
                            color: "transparent"

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.00) }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.08) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                            }

                            NumberAnimation on x {
                                running: placeholder.visible && !page.reduceMotion
                                loops: Animation.Infinite
                                from: -shimmer.width
                                to: placeholder.width + shimmer.width
                                duration: 1200
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 58
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.00) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.60) }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        text: fileName
                        color: Qt.rgba(1, 1, 1, 1)
                        font.pixelSize: 12
                        font.bold: true
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: 30
                        height: 30
                        radius: 15
                        visible: isSelected || wallMouse.containsMouse || wallMouse.pressed
                        color: isSelected ? _rgba(page.accent, 0.90) : Qt.rgba(0, 0, 0, 0.35)
                        border.width: 1
                        border.color: _rgba(Qt.rgba(1, 1, 1, 1), 0.18)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: isSelected ? "check" : "wallpaper"
                            color: Qt.rgba(1, 1, 1, 1)
                            font.pixelSize: 18
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: _rgba(page.onSurface, 1.0)
                        opacity: wallMouse.pressed ? 0.16 : (wallMouse.containsMouse ? 0.07 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }

                    Rectangle {
                        id: ripple
                        width: 12
                        height: 12
                        radius: 999
                        color: _rgba(page.accent, 0.22)
                        visible: false
                        x: cx - width / 2
                        y: cy - height / 2
                        opacity: 1.0

                        property real cx: card.width / 2
                        property real cy: card.height / 2

                        function burst(px, py) {
                            if (page.reduceMotion) return
                            cx = px
                            cy = py
                            visible = true
                            opacity = 1.0
                            width = 12
                            height = 12
                            anim.restart()
                        }

                        ParallelAnimation {
                            id: anim
                            NumberAnimation { target: ripple; property: "width"; to: Math.max(card.width, card.height) * 1.25; duration: 320; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ripple; property: "height"; to: Math.max(card.width, card.height) * 1.25; duration: 320; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ripple; property: "opacity"; to: 0.0; duration: 340; easing.type: Easing.OutQuad }
                            onFinished: ripple.visible = false
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    scale: wallMouse.containsMouse ? 1.008 : 1.0
                    y: wallMouse.containsMouse ? -1 : 0

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => ripple.burst(mouse.x, mouse.y)
                        onClicked: page.applyWallpaper(cleanPath)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: wallpaperModel.count === 0
            radius: 16
            color: page.surface1
            border.width: 1
            border.color: page.border0
            implicitHeight: 86

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: Translation.tr("Wallpapers.EmptyTitle")
                    color: page.onSurface
                    font.pixelSize: 14
                    font.bold: true
                    font.family: page.fontMain
                }

                Text {
                    text: Translation.tr("Wallpapers.FolderLabel")
                        .arg(wallpaperModel.folder.toString().replace("file://", ""))
                    color: page.onSurfaceMuted
                    font.pixelSize: 11
                    font.family: page.fontMain
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}

