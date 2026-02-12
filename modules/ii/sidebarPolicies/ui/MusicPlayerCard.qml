import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import "../../../common/utils" as Utils
Item {
    id: root

    required property var theme
    required property var musicModel
    property var player: musicModel.activePlayer
    property bool lyricsMode: false 
    // --- CARÁTULA ---
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl || "")
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    property bool hasCover: (artUrl && artUrl.toString().length > 0 && artUrl.toString().indexOf("music_note") === -1)
    property string displayedArtFilePath: (hasCover && artUrl.toString().startsWith("file://"))
                                          ? artUrl
                                          : (downloaded ? "file://" + artFilePath : "")
    // --- COLORES ---
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8)
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }
    // --- ICONOS ---
    function getIconName(identity) {
        if (!identity) return "audio-x-generic"
        var id = identity.toLowerCase()
        if (id.includes("firefox")) return "firefox"
        if (id.includes("chrome")) return "google-chrome"
        if (id.includes("spotify")) return "spotify"
        if (id.includes("vlc")) return "vlc"
        return id
    }
    // --- DESCARGA ---
    onArtUrlChanged: {
        if (!hasCover || artUrl.toString().startsWith("file://")) return
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }
    Process {
        id: coverArtDownloader
        property string targetFile
        property string artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => { root.downloaded = true }
    }
    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0; rescaleSize: 1
    }
    Timer {
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: 50
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // MOTOR DE LETRAS 
    Utils.LrclibLyrics {
        id: lyricsEngine
        enabled: !!root.player && root.player.playbackState !== MprisPlaybackState.Stopped && root.player.trackTitle.length > 0
        title: root.player ? root.player.trackTitle : ""
        artist: root.player ? root.player.trackArtist : ""
        duration: root.player ? root.player.length : 0
        position: root.player ? root.player.position : 0
        adaptiveSync: true
        smoothPosition: true
    }
  
    property bool hasSyncedLyrics: {
        if (!lyricsEngine.enabled) return false
        var txt = lyricsEngine.displayText
        if (!txt || txt === "") return false
        if (txt === "...") return false
        if (txt.indexOf("No hay letras") !== -1) return false
        if (txt.indexOf("Buscando") !== -1) return false
        // Si el texto es muy corto (menos de 5 letras), probablemente no sea una canción real
        if (txt.length < 5) return false
        return true
    }
    // 2. DISEÑO VISUAL
    Layout.fillWidth: true
    implicitHeight: 230 

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: maskRect }
        Rectangle {
            id: maskRect
            anchors.fill: parent
            radius: 28
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            // Unificamos al 0.60 de opacidad como en el Reloj/Sistema
            color: Appearance.colors.colLayer1
            visible: !root.hasCover || bgSource.status !== Image.Ready
        }
        Image {
            id: bgSource
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            visible: false
            cache: false
        }
        FastBlur {
            anchors.fill: parent
            source: bgSource
            radius: 50
            transparentBorder: false
            visible: root.hasCover && bgSource.status === Image.Ready
        }
        // Tinte de color dominante suave
        Rectangle {
            anchors.fill: parent
            color: root.hasCover ? ColorUtils.applyAlpha(root.artDominantColor, 0.20) : "transparent"
        }
      
        Rectangle {
            anchors.fill: parent
            color: root.lyricsMode ? "#85000000" : "#35000000" 
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            radius: 28
        }
    }
    // --- CONTENIDO ---
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0
        // CABECERA
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 10
            Image {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                fillMode: Image.PreserveAspectFit
                source: "image://icon/" + root.getIconName(root.player?.identity)
                sourceSize.width: 64; sourceSize.height: 64
                onStatusChanged: { if (status === Image.Error) source = "" }
            }
            MaterialSymbol {
                visible: parent.children[0].status !== Image.Ready
                text: "music_note"
                iconSize: 20
                color: "#ffffff"
            }
            Text {
                text: root.player?.identity || "Reproductor"
                font.pixelSize: 14
                font.bold: true
                color: "#eeeeee"
                opacity: 0.9
            }
            Item { Layout.fillWidth: true }
        }
        // ÁREA CENTRAL (SWAP)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 110 
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            clip: true
            // VISTA 1: REPRODUCTOR
            RowLayout {
                anchors.fill: parent
                visible: !root.lyricsMode
                spacing: 16
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 90
                    Layout.alignment: Qt.AlignVCenter
                    radius: 16
                    color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    Image {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop 
                        smooth: true
                        mipmap: true
                        visible: root.hasCover && status === Image.Ready
                        cache: false
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "album"
                        visible: !root.hasCover
                        iconSize: 40
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        MarqueeText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Sin reproducción"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#ffffff"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackArtist || "..."
                            font.pixelSize: 14
                            font.family: Appearance.font.name
                            color: "#cccccc"
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 54
                        height: 54
                        radius: 27
                        color: "#ffffff"
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: (root.player?.playbackState === MprisPlaybackState.Playing) ? "pause" : "play_arrow"
                            iconSize: 32
                            color: "#000000"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player?.togglePlaying()
                            onPressed: parent.scale = 0.90
                            onReleased: parent.scale = 1.0
                        }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }
                }
            }
            // VISTA 2: KARAOKE
            ColumnLayout {
                anchors.fill: parent
                visible: root.lyricsMode
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                spacing: 4
                Item { Layout.fillWidth: true; Layout.preferredHeight: 20
                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: lyricsEngine.prevLineText
                        font.pixelSize: 14
                        font.family: Appearance.font.name
                        color: "#dddddd"
                        opacity: 0.5
                        elide: Text.ElideRight
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Item {
                        anchors.centerIn: parent
                        width: parent.width
                        height: currentLyricText.implicitHeight
                        Text {
                            id: currentLyricText
                            anchors.centerIn: parent
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // Texto que se muestra en modo karaoke
                            text: root.hasSyncedLyrics ? lyricsEngine.displayText : "Buscando letras..."
                            font.pixelSize: 22
                            font.bold: true
                            font.family: Appearance.font.name
                            color: "#ffffff"
                            wrapMode: Text.Wrap
                            Behavior on text { 
                                SequentialAnimation {
                                    NumberAnimation { target: currentLyricText; property: "opacity"; to: 0.5; duration: 50 }
                                    PropertyAction { target: currentLyricText; property: "text" }
                                    NumberAnimation { target: currentLyricText; property: "opacity"; to: 1.0; duration: 150 }
                                }
                            }
                        }
                        Glow {
                            anchors.fill: currentLyricText
                            source: currentLyricText
                            radius: 12
                            samples: 24
                            color: root.hasCover ? root.artDominantColor : "#ffffff"
                            opacity: 0.6
                            spread: 0.3
                            // El brillo solo es visible si hay letras reales
                            visible: root.hasSyncedLyrics
                        }
                    }
                }
                Item { Layout.fillWidth: true; Layout.preferredHeight: 20
                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: lyricsEngine.nextLineText
                        font.pixelSize: 14
                        font.family: Appearance.font.name
                        color: "#dddddd"
                        opacity: 0.5
                        elide: Text.ElideRight
                    }
                }
            }
        }
        // ZONA INFERIOR
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            spacing: 10
            ControlButton {
                icon: "skip_previous"
                size: 42
                onClicked: root.player?.previous()
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position)
                    font.pixelSize: 12
                    color: "#cccccc"
                    font.bold: true
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    WavySlider {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 40
                        progress: (root.player && root.player.length > 0) ? (root.player.position / root.player.length) : 0
                        playing: root.player?.playbackState === MprisPlaybackState.Playing
                        accentColor: (root.hasCover) ? root.artDominantColor : Appearance.colors.colPrimary
                        onSeek: (pct) => { if (root.player) root.player.position = pct * root.player.length }
                    }
                }
                Text {
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length)
                    font.pixelSize: 12
                    color: "#cccccc"
                    font.bold: true
                }
            }
            ControlButton {
                icon: "skip_next"
                size: 42
                onClicked: root.player?.next()
            }
            // BOTÓN LETRAS (CORREGIDO PARA DETENER ANIMACIÓN)
            ControlButton {
                icon: root.lyricsMode ? "music_note" : "lyrics"
                size: 36 
                // Habilitado siempre para poder entrar a ver "Buscando..." si uno quiere
                enabled: true
                // Opacidad baja si no hay letras confirmadas, alta si hay o si está activo
                opacity: (root.hasSyncedLyrics || root.lyricsMode) ? 1.0 : 0.5
                color: {
                    if (root.lyricsMode) return Qt.rgba(1, 1, 1, 0.2) // Fondo fijo activo
                    if (root.hasSyncedLyrics && root.player.playbackState === MprisPlaybackState.Playing) return pulseColor // Animación
                    return "transparent"
                }
                property color pulseColor: Qt.rgba(1, 1, 1, 0.1)
                SequentialAnimation on pulseColor {
                    // LA CLAVE: Solo corre si hasSyncedLyrics es VERDADERO (verificado arriba)
                    running: root.hasSyncedLyrics 
                             && !root.lyricsMode 
                             && root.player.playbackState === MprisPlaybackState.Playing
                    loops: Animation.Infinite
                    ColorAnimation { from: Qt.rgba(1, 1, 1, 0.05); to: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.4); duration: 1000; easing.type: Easing.InOutQuad }
                    ColorAnimation { from: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.4); to: Qt.rgba(1, 1, 1, 0.05); duration: 1000; easing.type: Easing.InOutQuad }
                }
                onClicked: { root.lyricsMode = !root.lyricsMode }
            }
        }
    }

    // COMPONENTES AUXILIARES
    component MarqueeText : Item {
        property alias text: txt.text
        property alias font: txt.font
        property alias color: txt.color
        clip: true 
        Text {
            id: txt
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            SequentialAnimation on x {
                running: txt.implicitWidth > parent.width
                loops: Animation.Infinite
                PauseAnimation { duration: 2000 }
                NumberAnimation { to: -(txt.implicitWidth - parent.width); duration: (txt.implicitWidth - parent.width) * 30 + 1000; easing.type: Easing.Linear }
                PauseAnimation { duration: 1000 }
                NumberAnimation { to: 0; duration: 0 }
            }
        }
    }
    component WavySlider : Item {
        property real progress: 0.0
        property bool playing: false
        property color accentColor: "white"
        signal seek(real pct)
        property real phase: 0.0
        NumberAnimation on phase { running: playing; from: 0; to: Math.PI * 2; duration: 3000; loops: Animation.Infinite }
        readonly property real amp: 1.5
        readonly property real freq: 1.5
        Slider {
            anchors.fill: parent
            from: 0; to: 1
            value: progress
            background: Item {}
            handle: Item {}
            onMoved: seek(value)
        }
        Shape {
            anchors.fill: parent; layer.enabled: true; layer.samples: 4
            ShapePath {
                strokeColor: Qt.rgba(1,1,1,0.3); strokeWidth: 2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                startX: 0; startY: parent.height / 2
                PathSvg { path: generateSvgPath(parent.width, parent.height, amp, freq, phase) }
            }
        }
        Item {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width * progress; clip: true
            Shape {
                width: parent.parent.width; height: parent.height
                ShapePath {
                    strokeColor: accentColor; strokeWidth: 2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    startX: 0; startY: parent.height / 2
                    PathSvg { path: generateSvgPath(parent.width, parent.height, amp, freq, phase) }
                }
            }
        }
        Item {
            id: tracker
            width: 1; height: 1
            x: parent.width * progress
            y: (parent.height / 2) + (Math.sin((progress * Math.PI * 2 * freq) + phase) * amp)
        }
        Rectangle {
            width: 3; height: 24; radius: 1.5; color: accentColor; anchors.centerIn: tracker
            layer.enabled: true; layer.effect: DropShadow { radius: 4; color: "#aa000000" }
        }
        function generateSvgPath(w, h, amp, freq, ph) {
            var str = "M 0 " + (h/2 + Math.sin(ph) * amp)
            for (var i = 1; i <= 40; i++) {
                var x = (w / 40) * i
                var angle = (i / 40) * Math.PI * 2 * freq + ph
                var y = (h / 2) + Math.sin(angle) * amp
                str += " L " + x + " " + y
            }
            return str
        }
    }
    component ControlButton : Rectangle {
        property string icon
        property int size: 40
        signal clicked()
        Layout.preferredWidth: size
        Layout.preferredHeight: size
        radius: size / 2
        color: mouseArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
        MaterialSymbol { anchors.centerIn: parent; text: icon; font.pixelSize: size * 0.65; color: "#ffffff" }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
            onPressed: parent.scale = 0.9
            onReleased: parent.scale = 1.0
        }
        Behavior on scale { NumberAnimation { duration: 100 } }
    }
}
