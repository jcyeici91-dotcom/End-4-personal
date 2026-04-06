pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import qs.modules.common.utils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property color color: "transparent"

    required property MprisPlayer player
    required property string settingsQmlPath

    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(String(artUrl || ""))
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    property color fallbackAccent: Appearance.colors.colPrimary || "#e11d48"
    property color artDominantColor: colorQuantizer?.colors?.length > 0
                                    ? colorQuantizer.colors[0]
                                    : fallbackAccent

    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1400
    property int visualizerSmoothing: 3

    property real radius: Appearance.rounding.large || 24
    property bool pinned: false
    signal togglePinned()

    readonly property string cleanTitle: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Sin reproducción"
    readonly property string cleanArtist: root.player?.trackArtist || "Artista desconocido"
    readonly property bool hasTrack: !!(root.player?.trackTitle && root.player.trackTitle.length > 0)
    readonly property bool canSeekTrack: root.player?.canSeek ?? false
    readonly property real progressValue: (root.player && root.player.length > 0)
                                        ? (root.player.position / root.player.length)
                                        : 0

    LrclibLyrics {
        id: lyricsManager
        enabled: !!root.player && !!(root.player?.trackTitle || "").length
        title: root.player?.trackTitle || ""
        artist: root.player?.trackArtist || ""
        duration: root.player?.length || 0
        position: root.player?.position || 0
        smoothPosition: true
    }

    Timer {
        id: lyricTick
        running: root.player?.playbackState === MprisPlaybackState.Playing
        interval: Math.max(80, Config.options.resources.updateInterval || 120)
        repeat: true
        onTriggered: {
            if (root.player)
                root.player.positionChanged()
        }
    }

    onArtFilePathChanged: {
        if (!root.artUrl || String(root.artUrl).length === 0) {
            root.downloaded = false
            return
        }

        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath

        command: [
            "bash", "-c",
            `[ -f "${artFilePath}" ] || curl -sSL '${targetFile}' -o '${artFilePath}'`
        ]

        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    function fmtTime(ms) {
        const total = Math.max(0, Math.floor((ms || 0) / 1000))
        const m = Math.floor(total / 60)
        const s = total % 60
        return `${m}:${s < 10 ? "0" : ""}${s}`
    }

    Rectangle {
        id: scene
        anchors.fill: parent
        radius: root.radius
        color: "#090a0f"
        clip: true
        border.width: 1
        border.color: "#181b23"

        Image {
            id: bgArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            visible: root.displayedArtFilePath !== ""
            opacity: root.displayedArtFilePath !== "" ? 0.42 : 0.0
            smooth: true
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: "#03040a"
            opacity: 0.72
        }

        // Tinte dinámico global
        Rectangle {
            anchors.fill: parent
            color: root.artDominantColor
            opacity: 0.08
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width * 0.58
            height: parent.height * 0.55
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.18) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.34
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#cc05060c" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.42
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#d905060c" }
            }
        }

          Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.22
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#aa04050a" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

           Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.34
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#e8040509" }
            }
        }

           WaveVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 160
            live: (root.player?.isPlaying ?? false)
                  && Config.options.background.mediaMode.enable
                  && Config.options.background.mediaMode.showVisualizer
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: root.artDominantColor
            opacity: 0.24
        }

       RowLayout {
            z: 40
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 22
            spacing: 10

            Rectangle {
                implicitWidth: 118
                implicitHeight: 36
                radius: 18
                color: "#10131a"
                border.width: 1
                border.color: "#20242d"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.player?.isPlaying ? root.artDominantColor : "#5d6472"
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player?.isPlaying ? "Now Playing" : "Paused"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "white"
                        opacity: 0.92
                    }
                }
            }

            RippleButton {
                implicitWidth: 42
                implicitHeight: 42
                buttonRadius: 21
                colBackground: root.pinned
                               ? Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.18)
                               : "#10131a"

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "push_pin"
                    iconSize: 20
                    color: root.pinned ? root.artDominantColor : "white"
                    opacity: root.pinned ? 1.0 : 0.7
                }

                onClicked: root.togglePinned()
            }

            RippleButton {
                implicitWidth: 42
                implicitHeight: 42
                buttonRadius: 21
                colBackground: "#10131a"

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "settings"
                    iconSize: 20
                    color: "white"
                    opacity: 0.7
                }

                onClicked: {
                    GlobalStates.mediaControlsOpen = false
                    Quickshell.execDetached([
                        "qs", "-p",
                        "/home/" + Quickshell.env("USER") + "/.config/quickshell/ii/settings.qml"
                    ])
                }
            }
        }

        ColumnLayout {
            z: 20
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 28
            anchors.topMargin: 34
            anchors.bottomMargin: 78
            width: Math.min(parent.width * 0.38, 390)
            spacing: 18

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    text: root.cleanTitle
                    font.pixelSize: 26
                    font.weight: Font.Black
                    color: "white"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.08
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.cleanArtist
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: root.artDominantColor
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: 8

                    Rectangle {
                        implicitWidth: 104
                        implicitHeight: 28
                        radius: 14
                        color: "#10131a"
                        border.width: 1
                        border.color: "#20242d"

                        StyledText {
                            anchors.centerIn: parent
                            text: root.player?.identity || "MPRIS"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "white"
                            opacity: 0.9
                        }
                    }

                    Rectangle {
                        implicitWidth: 74
                        implicitHeight: 28
                        radius: 14
                        color: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.18)

                        StyledText {
                            anchors.centerIn: parent
                            text: root.canSeekTrack ? "Seek" : "Static"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "white"
                            opacity: 0.9
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

                Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 26
                color: "#0c1017"
                opacity: 0.92
                border.width: 1
                border.color: "#1c212c"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 16

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: prevMouse.containsPress ? "#171c26" : (prevMouse.containsMouse ? "#131823" : "transparent")
                        border.width: 1
                        border.color: "#222838"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: 26
                            color: "white"
                            opacity: 0.92
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player?.previous()
                        }

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 72
                        height: 72
                        radius: 36
                        color: root.artDominantColor
                        opacity: playMouse.containsPress ? 0.80 : (playMouse.containsMouse ? 0.92 : 1.0)

                        Rectangle {
                            anchors.centerIn: parent
                            width: 58
                            height: 58
                            radius: 29
                            color: Qt.rgba(0, 0, 0, 0.08)
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.player?.isPlaying ? "pause" : "play_arrow"
                            iconSize: 38
                            color: "#090b10"
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player?.togglePlaying()
                        }

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: nextMouse.containsPress ? "#171c26" : (nextMouse.containsMouse ? "#131823" : "transparent")
                        border.width: 1
                        border.color: "#222838"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: 26
                            color: "white"
                            opacity: 0.92
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.player?.next()
                        }

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 4

                        StyledText {
                            text: root.fmtTime(root.player?.position || 0)
                            font.pixelSize: 18
                            font.weight: Font.Black
                            color: "white"
                            horizontalAlignment: Text.AlignRight
                        }

                        StyledText {
                            text: root.fmtTime(root.player?.length || 0)
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "white"
                            opacity: 0.45
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

                   RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: root.player?.isPlaying ? root.artDominantColor : "#5d6472"
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!root.hasTrack) return "Esperando pista..."
                        if (lyricsManager.loading) return "Buscando letras sincronizadas..."
                        if (lyricsManager.instrumental) return "Pista instrumental"
                        if (lyricsManager.error !== "") return "Letras no disponibles"
                        return root.player?.isPlaying ? "Letras sincronizadas activas" : "Pausado"
                    }
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.68
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }
        }

        Item {
            id: lyricsStage
            z: 18
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Math.min(parent.width * 0.42, 420)
            anchors.rightMargin: 34
            anchors.topMargin: 56
            anchors.bottomMargin: 86

            // Fallback
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.8, 460)
                spacing: 14

                visible: lyricsManager.loading
                         || lyricsManager.error !== ""
                         || lyricsManager.instrumental
                         || !root.hasTrack
                         || (!lyricsManager.currentLineText && !lyricsManager.prevLineText && !lyricsManager.nextLineText)

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!root.hasTrack) return "hourglass_empty"
                        if (lyricsManager.loading) return "sync"
                        if (lyricsManager.instrumental) return "music_note"
                        if (lyricsManager.error !== "") return "lyrics"
                        return "music_note"
                    }
                    iconSize: 62
                    color: "white"
                    opacity: 0.12
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!root.hasTrack) return "Esperando pista..."
                        if (lyricsManager.loading) return "Buscando letras..."
                        if (lyricsManager.instrumental) return "♪ Pista instrumental ♪"
                        if (lyricsManager.error !== "") return "Letras no disponibles"
                        return "Reproduciendo..."
                    }
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.5
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.hasTrack
                    text: root.cleanTitle + " — " + root.cleanArtist
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: root.artDominantColor
                    opacity: 0.8
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                visible: !(lyricsManager.loading
                           || lyricsManager.error !== ""
                           || lyricsManager.instrumental
                           || !root.hasTrack
                           || (!lyricsManager.currentLineText && !lyricsManager.prevLineText && !lyricsManager.nextLineText))

                Item { Layout.fillHeight: true }

                   StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: lyricsManager.prevLineText || ""
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.18
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                     Item {
                    Layout.fillWidth: true
                    implicitHeight: currentHeroText.implicitHeight + 22

                    Rectangle {
                        anchors.centerIn: currentHeroText
                        width: Math.min(currentHeroText.paintedWidth + 44, parent.width * 0.96)
                        height: currentHeroText.paintedHeight + 22
                        radius: 24
                        color: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.10)
                        border.width: 1
                        border.color: Qt.rgba(root.artDominantColor.r, root.artDominantColor.g, root.artDominantColor.b, 0.12)
                    }

                    StyledText {
                        id: currentHeroText
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.94, 560)
                        text: lyricsManager.currentLineText || "♪"
                        font.pixelSize: 34
                        font.weight: Font.Black
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        lineHeight: 1.08
                    }
                }

                    StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: lyricsManager.nextLineText || ""
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.18
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.player?.isPlaying ? root.artDominantColor : "#5d6472"
                    }

                    StyledText {
                        text: root.player?.isPlaying ? "Sync activo" : "Pausado"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "white"
                        opacity: 0.38
                    }
                }
            }
        }

        ColumnLayout {
            z: 35
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.bottomMargin: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: root.fmtTime(root.player?.position || 0)
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.40
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: root.fmtTime(root.player?.length || 0)
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "white"
                    opacity: 0.40
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 14

                Loader {
                    anchors.fill: parent
                    active: root.canSeekTrack

                    sourceComponent: StyledSlider {
                        configuration: StyledSlider.Configuration.Wavy
                        highlightColor: root.artDominantColor
                        trackColor: "#2a2f3b"
                        handleColor: root.artDominantColor
                        value: root.progressValue

                        onMoved: {
                            if (root.player && root.player.length > 0)
                                root.player.position = value * root.player.length
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: !root.canSeekTrack

                    sourceComponent: StyledProgressBar {
                        wavy: root.player?.isPlaying
                        highlightColor: root.artDominantColor
                        trackColor: "#2a2f3b"
                        value: root.progressValue
                    }
                }
            }
        }
    }
}
