// ~/.config/quickshell/ii/modules/ii/sidebarLeft/WallpapersPage.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.modules.common.widgets
import qs.services
import qs.modules.common

Item {
    id: root
    required property QtObject theme
    anchors.fill: parent

    FolderListModel {
        id: wallpaperModel
        folder: "file:///home/jcgomez91/Pictures/Wallpapers"
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        showDotAndDotDot: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            implicitWidth: titleRow.implicitWidth + 40
            implicitHeight: 46
            radius: 23
            color: Qt.rgba(theme.colAccent.r, theme.colAccent.g, theme.colAccent.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(theme.colAccent.r, theme.colAccent.g, theme.colAccent.b, 0.3)

            RowLayout {
                id: titleRow
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol { text: "palette"; color: theme.colText; font.pixelSize: 22 }

                Text {
                    text: "GALERÍA DE FONDOS"
                    color: theme.colText
                    font.pixelSize: 18
                    font.bold: true
                    font.family: theme.fontMain
                    font.letterSpacing: 2
                    font.capitalization: Font.AllUppercase
                }
            }
        }

        GridView {
            id: wallGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            cellWidth: width / 2
            cellHeight: 160
            model: wallpaperModel

            ScrollBar.vertical: ScrollBar {
                id: vbar
                policy: ScrollBar.AlwaysOn
                active: true
                width: 16

                contentItem: Rectangle {
                    implicitWidth: 16
                    radius: 8
                    color: vbar.pressed ? theme.colText : Qt.rgba(theme.colText.r, theme.colText.g, theme.colText.b, 0.6)
                }

                background: Rectangle {
                    implicitWidth: 16
                    color: Qt.rgba(theme.colText.r, theme.colText.g, theme.colText.b, 0.1)
                    radius: 8
                }
            }

            delegate: Item {
                width: wallGrid.cellWidth
                height: wallGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 12
                    color: theme.colSurface
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: fileUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: wallMouse.pressed ? 0.3 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const cleanPath = fileUrl.toString().replace("file://", "")
                            Wallpapers.select(cleanPath, Appearance.m3colors.darkmode)
                        }
                    }
                }
            }

            Text {
                visible: wallpaperModel.count === 0
                text: "No images found in\n" + wallpaperModel.folder.toString().replace("file://", "")
                color: theme.colSubText
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                font.family: theme.fontMain
            }
        }
    }
}
