import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick

// Variables are being auto cascaded, so this widget cannot be used anywhere else than MediaMode.qml (for now)

Item {
    id: coverArt

    property string backgroundShapeString: Config.options.background.mediaMode.backgroundShape

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width

        StyledDropShadow {
            target: artBackgroundLoader
        }
        
        Loader {
            id: artBackgroundLoader
            Layout.preferredWidth: 400
            Layout.preferredHeight: 400
            Layout.alignment: Qt.AlignHCenter
            active: true // we have to use a loader (or a wrapper object) in order to achieve a drop shadow
            sourceComponent: MaterialShape { // Art background
                id: artBackground
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)
                shapeString: coverArt.backgroundShapeString

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: MaterialShape {
                        width: artBackground.width
                        shapeString: coverArt.backgroundShapeString
                        height: artBackground.height
                    }
                }

                StyledImage { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true

                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size
                }

                MouseArea {
                    id: artMouseArea
                    z: 10
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.MiddleButton
                    onClicked: {
                        root.displayedArtFilePath = "" // Force
                        root.updateArt()
                    }
                    opacity: containsMouse ? 1 : 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }

                    MaterialMusicControls {
                        id: musicControls
                        anchors.centerIn: parent
                        
                        baseButtonHeight: 60
                        baseButtonWidth: 60
                        player: root.player
                        
                        Layout.preferredWidth: parent.width
                        Layout.preferredHeight: parent.height / 3
                    }

                    StyledSlider { 
                        implicitWidth: parent.width / 2

                        anchors.top: musicControls.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter

                        configuration: StyledSlider.Configuration.Wavy
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colSecondaryContainer
                        handleColor: Appearance.colors.colPrimary
                        value: root.player?.position / root.player?.length
                        onMoved: {
                            root.player.position = value * root.player.length;
                        }
                    }
                }
            }
        }  

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Layout.topMargin: 20

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist || Translation.tr("Unknown Artist")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.huge
                font.family: Appearance.font.family.title
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.variableAxes: ({
                        "ROND": 75
                    })
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || Translation.tr("Unknown Title")
                font.pixelSize: Appearance.font.pixelSize.hugeass * 1.5
                font.weight: Font.Bold
                font.family: Appearance.font.family.title
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                horizontalAlignment: Text.AlignHCenter
                font.variableAxes: ({
                        "ROND": 75
                    })
            }
        }
    }
}