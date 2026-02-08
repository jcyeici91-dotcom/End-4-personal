pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs
import qs.services
import qs.modules.common
import qs.modules.common.utils
import Quickshell.Io
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.panels.lock

LockScreen {
    id: root

    // ============================================================
    // position (TU CONFIG ORIGINAL)
    // ============================================================
    property int mediaSideMargin: 34
    property int mediaTopMargin: 1450     //altura 

    // Alto del nuevo diseño
    property int mediaHeight: 230

    // ajuste (TU CONFIG ORIGINAL)
    property int mediaMaxWidth: 400

    // ============================================================
    // OFFSETS PARA MOVERLO
    // - mediaXOffset:  (-) izquierda, (+) derecha
    // - mediaYOffset:  (+) más abajo, (-) más arriba  (ahora usando topMargin)
    // ============================================================
    property int mediaXOffset: -010
    property int mediaYOffset: 0

    readonly property url fallbackCover: Qt.resolvedUrl("../../assets/icons/cover.png")

    lockSurface: LockSurface {
        id: lockSurf
        context: root.context

        Item {
            id: lockMediaHost
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.mediaSideMargin
            anchors.rightMargin: root.mediaSideMargin

            // ✅ Debajo de la hora/mensaje (zona superior)
            anchors.topMargin: root.mediaTopMargin + root.mediaYOffset

            height: root.mediaHeight
            z: 500

            property var activePlayer: MprisController.activePlayer

            // ====== LETRAS (integrado) ======
            property bool lyricsMode: false

            LrclibLyrics {
                id: lyricsEngine
                enabled: !!lockMediaHost.activePlayer
                         && lockMediaHost.activePlayer.playbackState !== MprisPlaybackState.Stopped
                         && (lockMediaHost.trackTitle && lockMediaHost.trackTitle.length > 0)

                title: lockMediaHost.trackTitle
                artist: lockMediaHost.trackArtist
                duration: lockMediaHost.activePlayer ? (lockMediaHost.activePlayer.length || 0) : 0
                position: lockMediaHost.activePlayer ? (lockMediaHost.activePlayer.position || 0) : 0

                adaptiveSync: true
                smoothPosition: true
            }

            property bool hasSyncedLyrics: {
                if (!lyricsEngine.enabled) return false
                var txt = (lyricsEngine.displayText || "").toString()
                if (!txt || txt === "") return false
                if (txt === "...") return false
                if (txt.indexOf("No hay letras") !== -1) return false
                if (txt.indexOf("Buscando") !== -1) return false
                if (txt.indexOf("No synced lyrics") !== -1) return false
                if (txt.indexOf("Fetching") !== -1) return false
                if (txt.length < 5) return false
                return true
            }

            // ===== Helpers originales =====
            function s(x) { return (x === undefined || x === null) ? "" : ("" + x) }

            function normalizeArtUrl(u) {
                var str = s(u).trim()
                if (str === "") return ""

                if (str.indexOf("file:/") === 0 && str.indexOf("file://") !== 0) {
                    str = "file://" + str.slice("file:/".length)
                }

                if (str.indexOf("/") === 0) str = "file://" + str

                str = str.replace(/ /g, "%20")
                return str
            }

            function getMeta(key) {
                if (!activePlayer || !activePlayer.metadata) return ""
                var v = activePlayer.metadata[key]
                if (v && (v instanceof Array) && v.length > 0) return s(v[0])
                return s(v)
            }

            property string trackTitle: {
                var t = s(activePlayer ? activePlayer.trackTitle : "")
                if (t === "") t = getMeta("xesam:title")
                return t
            }

            property string trackArtist: {
                var a = s(activePlayer ? activePlayer.trackArtist : "")
                if (a === "") a = getMeta("xesam:artist")
                return a !== "" ? a : "Unknown Artist"
            }

            property string artUrl: {
                var u = s(activePlayer ? activePlayer.trackArtUrl : "")
                if (u === "") u = getMeta("mpris:artUrl")
                return normalizeArtUrl(u)
            }

            property string trackId: getMeta("mpris:trackid")

            // hasMedia: hay algo “relevante” del player
            readonly property bool hasMedia: !!lockMediaHost.activePlayer
                                            && (
                                                lockMediaHost.trackTitle !== ""
                                                || lockMediaHost.trackId !== ""
                                                || ((lockMediaHost.activePlayer.length || 0) > 0)
                                            )

            readonly property bool isStopped: lockMediaHost.activePlayer
                                             ? (lockMediaHost.activePlayer.playbackState === MprisPlaybackState.Stopped)
                                             : true

            // ✅ Cuando no se reproduce nada: NO mostramos el card.
            // Así se ve tu blur del lock de fondo (como pediste).
            visible: GlobalStates.screenLocked && lockMediaHost.hasMedia && !lockMediaHost.isStopped

            property list<real> visualizerPoints: []

            Process {
                id: cavaProc

                running: GlobalStates.screenLocked
                      && lockMediaHost.activePlayer !== null
                      && lockMediaHost.isPlaying

                onRunningChanged: {
                    if (!cavaProc.running)
                        lockMediaHost.visualizerPoints = []
                }

                command: [
                    "cava",
                    "-p",
                    FileUtils.trimFileProtocol(Directories.scriptPath) + "/cava/raw_output_config.txt"
                ]

                stdout: SplitParser {
                    onRead: data => {
                        let points = data.split(";")
                            .map(p => parseFloat(p.trim()))
                            .filter(p => !isNaN(p))
                        lockMediaHost.visualizerPoints = points
                    }
                }
            }

            function forceReloadCover() {
                coverArt.source = ""
                coverArt.source = (artUrl !== "") ? artUrl : root.fallbackCover
                bgSource.source = coverArt.source
            }

            onActivePlayerChanged: forceReloadCover()
            onArtUrlChanged: forceReloadCover()
            onTrackTitleChanged: forceReloadCover()

            Connections {
                target: lockMediaHost.activePlayer
                enabled: lockMediaHost.activePlayer !== null
                function onTrackArtUrlChanged() { lockMediaHost.forceReloadCover() }
                function onTrackTitleChanged() { lockMediaHost.forceReloadCover() }
                function onLengthChanged() { lockMediaHost._syncDisplayedPosition(true) }
                function onPositionChanged() { lockMediaHost._syncDisplayedPosition(false) }
            }

            property string _lastTrackId: ""
            property real displayedPos: 0

            function _syncDisplayedPosition(hardReset) {
                var len = Math.max(0, activePlayer ? (activePlayer.length || 0) : 0)
                var pos = Math.max(0, activePlayer ? (activePlayer.position || 0) : 0)

                var tid = trackId
                if (tid !== "" && tid !== _lastTrackId) {
                    _lastTrackId = tid
                    displayedPos = 0
                    return
                }

                if (hardReset && len > 0 && pos > len + 0.05 * len) {
                    displayedPos = 0
                    return
                }

                if (len > 0) {
                    if (pos > len) {
                        displayedPos = 0
                        return
                    }
                    displayedPos = pos
                } else {
                    displayedPos = pos
                }
            }

            Timer {
                interval: 350
                repeat: true
                running: GlobalStates.screenLocked
                      && lockMediaHost.activePlayer !== null
                      && lockMediaHost.visible
                onTriggered: lockMediaHost._syncDisplayedPosition(false)
            }

            property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false

            readonly property bool canSeek: (activePlayer?.canSeek ?? false) && (activePlayer?.length ?? 0) > 0
            readonly property bool canGoNext: activePlayer?.canGoNext ?? true
            readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? true

            readonly property real trackLen: Math.max(0, activePlayer?.length ?? 0)
            readonly property real trackPos: Math.max(0, displayedPos)
            readonly property real ratio: (trackLen > 0) ? Math.max(0, Math.min(1, trackPos / trackLen)) : 0

            function clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }

            function friendlyTime(secOrUs) {
                var v = Number(secOrUs || 0)
                if (v > 1000000 * 20) v = v / 1000000.0
                v = Math.max(0, Math.floor(v))
                var m = Math.floor(v / 60)
                var s2 = v % 60
                return m + ":" + (s2 < 10 ? "0" + s2 : s2)
            }

            function iconForIdentity(identity) {
                var id2 = (identity || "").toString().toLowerCase()
                if (id2.indexOf("firefox") !== -1) return "firefox"
                if (id2.indexOf("chrome") !== -1) return "google-chrome"
                if (id2.indexOf("spotify") !== -1) return "spotify"
                if (id2.indexOf("vlc") !== -1) return "vlc"
                return "audio-x-generic"
            }

            // ============================================================
            // CARD (reproductor + modo letras)
            // ============================================================
            Item {
                id: mediaCard

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: root.mediaXOffset

                width: Math.min(parent.width, root.mediaMaxWidth)
                height: parent.height

                // FONDO (blur carátula SOLO cuando hay reproducción visible)
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
                        radius: 28
                        color: Appearance.colors.colLayer1
                        visible: bgSource.status !== Image.Ready
                    }

                    Image {
                        id: bgSource
                        anchors.fill: parent
                        source: (lockMediaHost.artUrl !== "") ? lockMediaHost.artUrl : root.fallbackCover
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        cache: false
                    }

                    FastBlur {
                        anchors.fill: parent
                        source: bgSource
                        radius: 50
                        transparentBorder: false
                        visible: bgSource.status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 28
                        color: lockMediaHost.lyricsMode ? "#85000000" : "#35000000"
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 28
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                    }
                }

                // CONTENIDO
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
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
                            source: "image://icon/" + lockMediaHost.iconForIdentity(lockMediaHost.activePlayer?.identity)
                            sourceSize.width: 64
                            sourceSize.height: 64
                            onStatusChanged: { if (status === Image.Error) source = "" }
                        }

                        MaterialSymbol {
                            visible: parent.children[0].status !== Image.Ready
                            text: "music_note"
                            iconSize: 20
                            color: "#ffffff"
                        }

                        Text {
                            text: lockMediaHost.activePlayer?.identity || "Reproductor"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#eeeeee"
                            opacity: 0.9
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // ÁREA CENTRAL (swap)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                        clip: true

                        // VISTA 1: REPRODUCTOR
                        RowLayout {
                            anchors.fill: parent
                            visible: !lockMediaHost.lyricsMode
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
                                border.color: Qt.rgba(1, 1, 1, 0.10)

                                Image {
                                    id: coverArt
                                    anchors.fill: parent
                                    source: (lockMediaHost.artUrl !== "") ? lockMediaHost.artUrl : root.fallbackCover
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    mipmap: true
                                    visible: status === Image.Ready
                                    cache: false
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "album"
                                    visible: coverArt.status !== Image.Ready
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
                                        text: StringUtils.cleanMusicTitle(lockMediaHost.trackTitle) || "Sin reproducción"
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: "#ffffff"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: lockMediaHost.trackArtist || "..."
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
                                        text: lockMediaHost.isPlaying ? "pause" : "play_arrow"
                                        iconSize: 32
                                        color: "#000000"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !!lockMediaHost.activePlayer
                                        onClicked: lockMediaHost.activePlayer.togglePlaying()
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
                            visible: lockMediaHost.lyricsMode
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
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
                                        text: lockMediaHost.hasSyncedLyrics ? lyricsEngine.displayText : "Buscando letras..."
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
                                        color: Appearance.m3colors.m3primary
                                        opacity: 0.6
                                        spread: 0.3
                                        visible: lockMediaHost.hasSyncedLyrics
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
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
                            enabled: !!lockMediaHost.activePlayer && lockMediaHost.canGoPrevious
                            opacity: enabled ? 1.0 : 0.5
                            onClicked: lockMediaHost.activePlayer.previous()
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: lockMediaHost.activePlayer ? lockMediaHost.friendlyTime(lockMediaHost.activePlayer.position) : "0:00"
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
                                    progress: lockMediaHost.ratio
                                    playing: lockMediaHost.isPlaying
                                    accentColor: Appearance.m3colors.m3primary
                                    onSeek: (pct) => {
                                        if (!lockMediaHost.activePlayer || !lockMediaHost.canSeek) return
                                        lockMediaHost.activePlayer.position = pct * lockMediaHost.trackLen
                                        lockMediaHost.displayedPos = lockMediaHost.activePlayer.position
                                    }
                                }
                            }

                            Text {
                                text: lockMediaHost.activePlayer ? lockMediaHost.friendlyTime(lockMediaHost.activePlayer.length) : "0:00"
                                font.pixelSize: 12
                                color: "#cccccc"
                                font.bold: true
                            }
                        }

                        ControlButton {
                            icon: "skip_next"
                            size: 42
                            enabled: !!lockMediaHost.activePlayer && lockMediaHost.canGoNext
                            opacity: enabled ? 1.0 : 0.5
                            onClicked: lockMediaHost.activePlayer.next()
                        }

                        // BOTÓN LETRAS
                        ControlButton {
                            icon: lockMediaHost.lyricsMode ? "music_note" : "lyrics"
                            size: 36
                            enabled: true
                            opacity: (lockMediaHost.hasSyncedLyrics || lockMediaHost.lyricsMode) ? 1.0 : 0.5

                            color: {
                                if (lockMediaHost.lyricsMode) return Qt.rgba(1, 1, 1, 0.18)
                                if (lockMediaHost.hasSyncedLyrics && lockMediaHost.isPlaying) return pulseColor
                                return "transparent"
                            }

                            property color pulseColor: Qt.rgba(1, 1, 1, 0.10)
                            SequentialAnimation on pulseColor {
                                running: lockMediaHost.hasSyncedLyrics && !lockMediaHost.lyricsMode && lockMediaHost.isPlaying
                                loops: Animation.Infinite
                                ColorAnimation {
                                    from: Qt.rgba(1, 1, 1, 0.05)
                                    to: Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.40)
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                                ColorAnimation {
                                    from: Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.40)
                                    to: Qt.rgba(1, 1, 1, 0.05)
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            onClicked: lockMediaHost.lyricsMode = !lockMediaHost.lyricsMode
                        }
                    }
                }

                // ===== Componentes auxiliares =====
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
                            NumberAnimation {
                                to: -(txt.implicitWidth - parent.width)
                                duration: (txt.implicitWidth - parent.width) * 30 + 1000
                                easing.type: Easing.Linear
                            }
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
                    NumberAnimation on phase {
                        running: playing
                        from: 0
                        to: Math.PI * 2
                        duration: 3000
                        loops: Animation.Infinite
                    }

                    readonly property real amp: 1.5
                    readonly property real freq: 1.5

                    Slider {
                        anchors.fill: parent
                        from: 0
                        to: 1
                        value: progress
                        background: Item {}
                        handle: Item {}
                        onMoved: seek(value)
                        enabled: lockMediaHost.canSeek
                    }

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4

                        ShapePath {
                            strokeColor: Qt.rgba(1,1,1,0.3)
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 0
                            startY: parent.height / 2
                            PathSvg { path: generateSvgPath(parent.width, parent.height, amp, freq, phase) }
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, progress))
                        clip: true

                        Shape {
                            width: parent.parent.width
                            height: parent.height

                            ShapePath {
                                strokeColor: accentColor
                                strokeWidth: 2
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                startX: 0
                                startY: parent.height / 2
                                PathSvg { path: generateSvgPath(parent.width, parent.height, amp, freq, phase) }
                            }
                        }
                    }

                    Item {
                        id: tracker
                        width: 1
                        height: 1
                        x: parent.width * Math.max(0, Math.min(1, progress))
                        y: (parent.height / 2) + (Math.sin((progress * Math.PI * 2 * freq) + phase) * amp)
                    }

                    Rectangle {
                        width: 3
                        height: 24
                        radius: 1.5
                        color: accentColor
                        anchors.centerIn: tracker
                        layer.enabled: true
                        layer.effect: DropShadow { radius: 4; color: "#aa000000" }
                        visible: lockMediaHost.trackLen > 0
                    }

                    function generateSvgPath(w, h, a, f, ph) {
                        var str = "M 0 " + (h/2 + Math.sin(ph) * a)
                        for (var i = 1; i <= 40; i++) {
                            var x = (w / 40) * i
                            var angle = (i / 40) * Math.PI * 2 * f + ph
                            var y = (h / 2) + Math.sin(angle) * a
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

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: icon
                        font.pixelSize: size * 0.65
                        color: "#ffffff"
                    }

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
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int lastWorkspaceId

            onShouldPushChanged: {
                if (shouldPush) {
                    lastWorkspaceId = HyprlandData.monitors.find(m => m.name == targetMonitorName).activeWorkspace.id
                    Quickshell.execDetached(["hyprctl", "--batch",
                        "keyword animation workspaces,1,7,menu_decel,slidevert; dispatch workspace " + (2147483647 - lastWorkspaceId)
                    ])
                } else {
                    Quickshell.execDetached(["hyprctl", "--batch", "dispatch workspace " + lastWorkspaceId + "; reload"])
                }
            }
        }
    }
}

