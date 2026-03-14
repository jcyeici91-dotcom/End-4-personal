pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { 
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    
    // 🔥 CORRECCIÓN 1: Exigimos la ruta desde MediaControls para no perderla 🔥
    required property string settingsQmlPath     
    
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 
    property int visualizerSmoothing: 2 
    property real radius

    property bool pinned: false
    signal togglePinned()

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    property date today: new Date()

    function getDayName(offset) {
        let d = new Date(today)
        d.setDate(today.getDate() + offset)
        const days = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
        const daysShort = ["S","M","T","W","T","F","S"]
        return offset === 0 ? days[d.getDay()] : daysShort[d.getDay()]
    }

    function getDayNum(offset) {
        let d = new Date(today)
        d.setDate(today.getDate() + offset)
        return d.getDate().toString().padStart(2,'0')
    }

    function getCurrentMonth() {
        const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return months[today.getMonth()]
    }

    component TrackChangeButton: RippleButton {
        id: button
        property int buttonSize: 24
        property bool fill: true
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        property var iconName
        
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: buttonSize
            fill: button.fill ? 1 : 0
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: { root.player.positionChanged() }
    }

    onArtFilePathChanged: {
        if (!root.artUrl || root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer;
            return;
        }
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = root.artFilePath;
        root.downloaded = false;
        coverArtDownloader.running = true;
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => { root.downloaded = true }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 
        rescaleSize: 1 
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "transparent" 
        clip: true

        // --- 1. WAVES CLAVADAS AL FONDO CON MÁSCARA CURVA ---
        Item {
            id: waveContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom 
            height: 85
            
            // Efecto mágico de recorte circular
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: waveContainer.width
                    height: waveContainer.height + root.radius // Más alto para que arriba no recorte
                    y: -root.radius // Desfasado hacia arriba
                    radius: root.radius // Clona la curva perfecta de tu ventana
                }
            }
            
            WaveVisualizer {
                anchors.fill: parent
                live: root.player?.isPlaying
                points: root.visualizerPoints
                maxVisualizerValue: root.maxVisualizerValue
                smoothing: root.visualizerSmoothing
                color: ColorUtils.transparentize(blendedColors.colPrimary, 0.15)
            }
        }

        // --- 2. ÍCONOS SUPERIORES ---
        RowLayout {
            z: 10
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 15 
            anchors.leftMargin: 20  
            spacing: 12

            TrackChangeButton {
                iconName: "push_pin"
                buttonSize: 18
                fill: root.pinned
                downAction: () => root.togglePinned()
            }
            TrackChangeButton { 
                iconName: Persistent.states.background.mediaMode.enabled ? "music_note" : "music_off"
                buttonSize: 18
                fill: Persistent.states.background.mediaMode.enabled
                downAction: () => {
                    Persistent.states.background.mediaMode.enabled = !Persistent.states.background.mediaMode.enabled
                }
            }
        }

        TrackChangeButton {
            id: settingsBtn
            iconName: "settings"
            buttonSize: 22
            fill: false
            z: 10 
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 15 
            anchors.rightMargin: 20  
            // 🔥 CORRECCIÓN 2: Restauramos 'downAction' para que el botón "escuche" el clic 🔥
            downAction: () => {
                GlobalStates.mediaControlsOpen = false;
                // Ruta absoluta directa a prueba de fallos
                Quickshell.execDetached(["qs", "-p", "/home/" + Quickshell.env("USER") + "/.config/quickshell/ii/settings.qml"]);
            }
        }

        // --- 3. CONTENIDO CENTRAL ---
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter 
            anchors.verticalCenterOffset: 5 
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 15

            // MÚSICA
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                Item {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 76

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: Appearance.colors.colLayer1
                        layer.enabled: true
                        layer.effect: OpacityMask { maskSource: Rectangle { width: 76; height: 76; radius: 16 } }
                        
                        Image {
                            anchors.fill: parent
                            source: root.displayedArtFilePath
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: -4
                        width: 20
                        height: 20
                        radius: 8
                        color: "#fa233b"

                        Image {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            source: root.player ? "image://icon/" + root.player.desktopEntry : ""
                            fillMode: Image.PreserveAspectFit
                            visible: root.player
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "No Media"
                        font.pixelSize: 15
                        font.bold: true
                        color: blendedColors.colOnLayer0
                        Layout.maximumWidth: 140
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: root.player?.trackArtist || "Unknown Artist"
                        font.pixelSize: 11
                        color: blendedColors.colSubtext
                        Layout.maximumWidth: 140
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.topMargin: 4
                        spacing: 10

                        TrackChangeButton {
                            iconName: "skip_previous"
                            buttonSize: 22
                            fill: false
                            downAction: () => root.player?.previous()
                        }
                        
                        RippleButton {
                            id: playPauseButton
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: root.player?.isPlaying ? Appearance?.rounding.normal : 16
                            colBackground: root.player?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                            colBackgroundHover: root.player?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                            colRipple: root.player?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                            downAction: () => root.player.togglePlaying()

                            contentItem: MaterialSymbol {
                                iconSize: 20
                                fill: 1
                                horizontalAlignment: Text.AlignHCenter
                                color: root.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                                text: root.player?.isPlaying ? "pause" : "play_arrow"
                                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                            }
                        }
                        
                        TrackChangeButton {
                            iconName: "skip_next"
                            buttonSize: 22
                            fill: false
                            downAction: () => root.player?.next()
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } 

            // CALENDARIO
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8 

                HorizontalMiniCalendar {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: false
                    highlightColor: blendedColors.colPrimary 
                    normalColor: Appearance.colors.colSubtext
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    spacing: 8

                    MaterialSymbol {
                        text: "event_upcoming"
                        iconSize: 18 
                        color: Appearance.colors.colSubtext
                        opacity: 0.75 
                    }
                    StyledText {
                        text: Translation.tr("Nothing for today")
                        font.pixelSize: 14 
                        font.weight: Font.Medium 
                        color: Appearance.colors.colSubtext
                        opacity: 0.75
                    }
                }
            }

            Item { Layout.fillWidth: true } 

            // USUARIO 
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 90 
                Layout.preferredHeight: 90 
                radius: 40
                color: Appearance.colors.colLayer1 
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 50  
                        height: 50 
                        radius: 25
                        color: "transparent"
                        layer.enabled: true
                        layer.effect: OpacityMask { maskSource: Rectangle { width: 50; height: 50; radius: 25 } }
                        
                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            source: "file:///home/" + (Quickshell.env("USER") || "") + "/.face"
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            cache: false
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "person"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                            visible: !userAvatar.visible
                        }
                    }
                    
                    StyledText {
                        text: SystemInfo.username || "User"
                        font.pixelSize: 12 
                        font.bold: true
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 65
                        elide: Text.ElideRight
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Appearance.colors.colLayer2
                    onExited:  parent.color = Appearance.colors.colLayer1
                }
            }
        }

        // --- 4. BARRA DE PROGRESO ---
        Item {
            id: progressBarContainer
            z: 15
            height: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 8 
            
            Loader {
                id: sliderLoader
                anchors.fill: parent
                active: root.player?.canSeek ?? false

                sourceComponent: StyledSlider {
                    configuration: StyledSlider.Configuration.Wavy
                    highlightColor: blendedColors.colPrimary
                    trackColor: blendedColors.colSecondaryContainer
                    handleColor: blendedColors.colPrimary

                    value: (root.player && root.player.length > 0)
                           ? (root.player.position / root.player.length)
                           : 0

                    onMoved: {
                        if (!root.player) return
                        root.player.position = value * root.player.length
                    }
                }
            }

            Loader {
                id: progressBarLoader
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }
                active: !(root.player?.canSeek ?? false)

                sourceComponent: StyledProgressBar {
                    wavy: root.player?.isPlaying
                    highlightColor: blendedColors.colPrimary
                    trackColor: blendedColors.colSecondaryContainer

                    value: (root.player && root.player.length > 0)
                           ? (root.player.position / root.player.length)
                           : 0
                }
            }
        }
    }
}
