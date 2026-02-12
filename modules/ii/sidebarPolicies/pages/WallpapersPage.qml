import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.folderlistmodel
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.platform 1.1

Item {
    id: page
    required property var theme
    // Ruta de tus fondos
    property url wallpapersFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] + "/Wallpapers"

    property string selectedPath: ""
    property bool reduceMotion: false

    readonly property color surface0: Appearance.colors.colLayer0
    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border
    readonly property color onSurface: Appearance.colors.colOnLayer0
    readonly property color onSurfaceMuted: Qt.rgba(onSurface.r, onSurface.g, onSurface.b, 0.75)

    readonly property color accent: (page.theme && page.theme.colAccent) ? page.theme.colAccent : Qt.rgba(0.45, 0.65, 1.0, 1.0)
    readonly property string fontMain: (page.theme && page.theme.fontMain) ? page.theme.fontMain : ""
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
                    color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.18)
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
                        text: "Galería de fondos"
                        color: page.onSurface
                        font.pixelSize: 16
                        font.bold: true
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }
                    Text {
                        text: wallpaperModel.count > 0 ? (wallpaperModel.count + " imágenes") : "Sin imágenes"
                        color: page.onSurfaceMuted
                        font.pixelSize: 11
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }
                }
                // Botones de acción
                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    // Botón: Aleatorio
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.10)
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
                            color: "black"
                            opacity: rndMouse.pressed ? 0.22 : (rndMouse.containsMouse ? 0.10 : 0.0)
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
                    // Botón: Re-escanear
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.10)
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
                            color: "black"
                            opacity: refMouse.pressed ? 0.22 : (refMouse.containsMouse ? 0.10 : 0.0)
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
                    // Botón: Reducir movimiento (toggle)
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: page.reduceMotion
                               ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.18)
                               : Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.06)
                        border.width: 1
                        border.color: page.reduceMotion
                                     ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.35)
                                     : Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.10)
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
                            color: "black"
                            opacity: motMouse.pressed ? 0.22 : (motMouse.containsMouse ? 0.10 : 0.0)
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
                // Chip de ruta 
                Rectangle {
                    radius: 14
                    implicitHeight: 28
                    implicitWidth: pathText.implicitWidth + 18
                    color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.10)
                    Text {
                        id: pathText
                        anchors.centerIn: parent
                        text: page.wallpapersFolder.toString().replace("file://", "")
                        color: page.onSurfaceMuted
                        font.pixelSize: 10
                        font.family: page.fontMain
                        elide: Text.ElideMiddle
                        width: Math.min(260, implicitWidth)
                    }
                }
            }
        }

        // GRID “TOP TOP” (pero sin brillos molestos)
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
                    color: vbar.pressed
                           ? Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.55)
                           : Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.35)
                }
                background: Rectangle {
                    radius: 4
                    color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.08)
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
                    border.color: isSelected
                                  ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.90)
                                  : page.border0
                    clip: true
      
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.35)
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
                        color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.06)
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
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: page.fontMain
                        elide: Text.ElideRight
                    }
                    // Indicador top-right
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: 30
                        height: 30
                        radius: 15
                        visible: isSelected || wallMouse.containsMouse || wallMouse.pressed
                        color: isSelected
                               ? Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.90)
                               : Qt.rgba(0, 0, 0, 0.35)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: isSelected ? "check" : "wallpaper"
                            color: "white"
                            font.pixelSize: 18
                        }
                    }
                    // Overlay hover/press
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: wallMouse.pressed ? 0.30 : (wallMouse.containsMouse ? 0.10 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }
                    // Ripple discreto (solo en press)
                    Rectangle {
                        id: ripple
                        width: 12
                        height: 12
                        radius: 999
                        color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.22)
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
                    // Elevación sutil en hover (muy leve)
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
                        onClicked: {
                            // Funcionalidad ORIGINAL: cambiar fondo
                            page.applyWallpaper(cleanPath)
                        }
                    }
                }
            }
        }
        // Estado vacío
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
                    text: "No se encontraron imágenes."
                    color: page.onSurface
                    font.pixelSize: 14
                    font.bold: true
                    font.family: page.fontMain
                }
                Text {
                    text: "Carpeta: " + wallpaperModel.folder.toString().replace("file://", "")
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
