import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root

    // Carpeta donde tienes wallpapers
    // Cambia esto a tu ruta real si no coincide.
    // Muchos setups usan ~/Pictures/Wallpapers
    property string wallpapersDir: (Directories.home + "/Pictures/Wallpapers")

    // Para evitar cargar mil thumbnails de golpe
    property bool allowHeavyLoad: true

    // Tamaño de cada tile
    property int cellSize: 160
    property int cellRadius: Appearance.rounding.normal

    implicitHeight: grid.implicitHeight

    // Listado de archivos de imagen
    FolderListModel {
        id: folder
        folder: "file://" + root.wallpapersDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Translation.tr("Wallpapers")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: root.wallpapersDir
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer3
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                Layout.maximumWidth: 420
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 520)
            clip: true

            cellWidth: root.cellSize + 12
            cellHeight: root.cellSize + 26

            model: folder

            delegate: Item {
                id: tile
                width: grid.cellWidth
                height: grid.cellHeight

                property string filePath: FileUtils.trimFileProtocol(folder.folder) + "/" + fileName
                property bool selected: Config.options.background.wallpaperPath === filePath

                Rectangle {
                    id: frame
                    width: root.cellSize
                    height: root.cellSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: root.cellRadius
                    color: Appearance.colors.colLayer2
                    border.width: selected ? 2 : 1
                    border.color: selected ? Appearance.colors.colPrimary : Appearance.colors.colLayer3

                    StyledImage {
                        id: thumb
                        anchors.fill: parent
                        source: "file://" + tile.filePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        visible: root.allowHeavyLoad

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: frame.width
                                height: frame.height
                                radius: frame.radius
                            }
                        }
                    }

                    // Hover overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: frame.radius
                        color: Qt.rgba(1, 1, 1, 0.0)
                        visible: mouse.containsMouse
                    }

                    RippleButton {
                        id: mouse
                        anchors.fill: parent
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.92)
                        colRipple: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.72)
                        onClicked: {
                            // 1) Actualiza config
                            Config.options.background.wallpaperPath = tile.filePath

                            // 2) Aplica wallpaper + recolor (si tu script lo hace)
                            // En tu código ya llamas Directories.wallpaperSwitchScriptPath
                            Quickshell.execDetached(["bash", "-c", FileUtils.trimFileProtocol(Directories.wallpaperSwitchScriptPath)])
                        }
                    }
                }

                StyledText {
                    anchors.top: frame.bottom
                    anchors.topMargin: 6
                    anchors.horizontalCenter: frame.horizontalCenter
                    width: root.cellSize
                    text: fileName
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Tip: si la carpeta está vacía
        NoticeBox {
            Layout.fillWidth: true
            visible: folder.count === 0
            text: Translation.tr("No wallpapers found in: ") + root.wallpapersDir
        }
    }
}
