pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs
import qs.services
import qs.modules.common
import Quickshell.Io
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.panels.lock

LockScreen {
    id: root

    // ============================================================
    // position (TU CONFIG ORIGINAL)
    // ============================================================
    property int mediaBottomMargin: 490  //sube
    property int mediaSideMargin: 34
    property int mediaHeight: 60

    // ajuste (TU CONFIG ORIGINAL)
    property int mediaMaxWidth: 400

    // ============================================================
    // ✅ NUEVO: OFFSETS PARA MOVERLO
    // - mediaXOffset:  (-) izquierda, (+) derecha
    // - mediaYOffset:  (+) más arriba, (-) más abajo  (porque usamos bottomMargin)
    // ============================================================
    property int mediaXOffset: -555
    property int mediaYOffset:  -473

    readonly property url fallbackCover: Qt.resolvedUrl("../../assets/icons/cover.png")

    lockSurface: LockSurface {
        id: lockSurf
        context: root.context

        Item {
            id: lockMediaHost
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.mediaSideMargin
            anchors.rightMargin: root.mediaSideMargin

            // ✅ CAMBIO: ahora respeta offset vertical
            anchors.bottomMargin: root.mediaBottomMargin + root.mediaYOffset

            height: root.mediaHeight
            z: 500

            property var activePlayer: MprisController.activePlayer

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

            readonly property bool hasMedia: !!lockMediaHost.activePlayer
                                            && (
                                                lockMediaHost.trackTitle !== ""
                                                || lockMediaHost.trackId !== ""
                                                || ((lockMediaHost.activePlayer.length || 0) > 0)
                                            )

            readonly property bool isStopped: lockMediaHost.activePlayer
                                             ? (lockMediaHost.activePlayer.playbackState === MprisPlaybackState.Stopped)
                                             : true

            visible: GlobalStates.screenLocked && lockMediaHost.hasMedia && !lockMediaHost.isStopped

            property list<real> visualizerPoints: []

            Process {
                id: cavaProc

                // cava solo corre cuando realmente está reproduciendo (ok para pausa)
                running: GlobalStates.screenLocked
                      && lockMediaHost.activePlayer !== null
                      && lockMediaHost.isPlaying

                onRunningChanged: {
                    if (!cavaProc.running)
                        lockMediaHost.visualizerPoints = []
                }

                command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]

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
                albumArtImage.source = ""
                albumArtImage.source = (artUrl !== "") ? artUrl : root.fallbackCover
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

            Rectangle {
                id: mediaCard

                //  mover izquierda/derecha 
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: root.mediaXOffset

                width: Math.min(parent.width, root.mediaMaxWidth)
                height: parent.height
                radius: 24

                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.85
                    shadowOpacity: 0.22
                    shadowColor: Qt.rgba(
                        Appearance.m3colors.m3primary.r,
                        Appearance.m3colors.m3primary.g,
                        Appearance.m3colors.m3primary.b,
                        1.0
                    )
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }

                Rectangle {
                    id: pulseHalo
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(
                        Appearance.m3colors.m3primary.r,
                        Appearance.m3colors.m3primary.g,
                        Appearance.m3colors.m3primary.b,
                        0.18
                    )
                    opacity: lockMediaHost.isPlaying ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    property real glow: 0.0
                    SequentialAnimation on glow {
                        running: lockMediaHost.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.0; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.0; duration: 900; easing.type: Easing.InOutSine }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(
                            Appearance.m3colors.m3primary.r,
                            Appearance.m3colors.m3primary.g,
                            Appearance.m3colors.m3primary.b,
                            0.04 + 0.05 * pulseHalo.glow
                        )
                        visible: false //lockMediaHost.isPlaying
                    }
                }

                Item {
                    id: visualizerMasked
                    anchors.fill: parent
                    z: 0
                    clip: true

                    WaveVisualizer {
                        id: visualizerCanvas
                        anchors.fill: parent
                        anchors.margins: 10
                        live: lockMediaHost.isPlaying
                        points: lockMediaHost.visualizerPoints
                        maxVisualizerValue: 1000
                        smoothing: 2
                        color: Appearance.m3colors.m3primary
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: visualizerMasked.width
                            height: visualizerMasked.height
                            radius: mediaCard.radius
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    z: 2

                    Item {
                        id: albumBlock
                        Layout.alignment: Qt.AlignVCenter
                        width: 46
                        height: 46

                        Item {
                            id: ringFx
                            anchors.fill: parent
                            visible: lockMediaHost.activePlayer !== null
                            opacity: lockMediaHost.isPlaying ? 1.0 : 0.90
                            z: 10

                            property real phase: 0

                            Timer {
                                interval: 38
                                running: ringFx.visible && lockMediaHost.isPlaying
                                repeat: true
                                onTriggered: ringFx.phase += 0.08
                            }

                            Canvas {
                                id: ringCanvas
                                anchors.fill: parent
                                antialiasing: true

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    var c = Appearance.m3colors.m3primary
                                    var cx = width / 2
                                    var cy = height / 2

                                    var r0 = Math.min(width, height) * 0.60
                                    var breathe = lockMediaHost.isPlaying ? (Math.sin(ringFx.phase * 2.0) * 0.045) : 0.0

                                    for (var i = 0; i < 4; i++) {
                                        var k = i / 4.0
                                        var r = r0 + (k * 8.2)
                                                + (Math.sin(ringFx.phase * 1.7 + i) * (lockMediaHost.isPlaying ? 1.15 : 0.35))
                                                + (r0 * breathe)

                                        var a = lockMediaHost.isPlaying ? (0.38 - k * 0.08) : (0.20 - k * 0.05)
                                        ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, Math.max(0, a))
                                        ctx.lineWidth = 2.1

                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
                                        ctx.stroke()
                                    }
                                }

                                Connections { target: ringFx; function onPhaseChanged() { ringCanvas.requestPaint() } }
                                Connections { target: lockMediaHost; function onIsPlayingChanged() { ringCanvas.requestPaint() } }

                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(
                                Appearance.m3colors.m3primary.r,
                                Appearance.m3colors.m3primary.g,
                                Appearance.m3colors.m3primary.b,
                                lockMediaHost.isPlaying ? 0.45 : 0.28
                            )
                            z: 3

                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 0
                                verticalOffset: 0
                                radius: 12
                                samples: 24
                                color: Qt.rgba(
                                    Appearance.m3colors.m3primary.r,
                                    Appearance.m3colors.m3primary.g,
                                    Appearance.m3colors.m3primary.b,
                                    lockMediaHost.isPlaying ? 0.18 : 0.10
                                )
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)
                            z: 1
                        }

                        Image {
                            id: albumArtImage
                            anchors.fill: parent
                            anchors.margins: 2

                            source: (lockMediaHost.artUrl !== "")
                                    ? lockMediaHost.artUrl
                                    : root.fallbackCover

                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                            smooth: true
                            antialiasing: true
                            z: 2

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: albumBlock.width
                                    height: albumBlock.height
                                    radius: 14
                                }
                            }

                            opacity: (status === Image.Ready) ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 220 } }

                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = ""
                                    source = root.fallbackCover
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Appearance.colors.colLayer1
                            visible: albumArtImage.status !== Image.Ready
                            z: 2

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "music_note"
                                iconSize: 22
                                color: Appearance.colors.colSubtext
                                opacity: 0.65
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Column {
                            width: parent.width
                            spacing: 1

                            StyledText {
                                width: parent.width
                                text: lockMediaHost.activePlayer
                                      ? lockMediaHost.trackArtist
                                      : "Sin reproductor"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: lockMediaHost.activePlayer
                                      ? (lockMediaHost.trackTitle !== "" ? lockMediaHost.trackTitle : "No Title")
                                      : "Abre tu reproductor"
                                color: "white"
                                font.weight: Font.Medium
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: 12
                                color: Qt.rgba(1, 1, 1, 0.90)
                                text: lockMediaHost.activePlayer
                                      ? (lockMediaHost.friendlyTime(lockMediaHost.trackPos) + " / " + lockMediaHost.friendlyTime(lockMediaHost.trackLen))
                                      : ""
                            }

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 26; height: 26
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_previous"
                                    iconSize: 26
                                    color: Appearance.colors.colOnLayer1
                                    opacity: (lockMediaHost.activePlayer && lockMediaHost.canGoPrevious) ? 1.0 : 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!lockMediaHost.activePlayer && lockMediaHost.canGoPrevious
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: lockMediaHost.activePlayer.previous()
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 32
                                height: 26
                                radius: 13
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.10)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: lockMediaHost.isPlaying ? "pause" : "play_arrow"
                                    iconSize: 32
                                    color: "white"
                                    opacity: lockMediaHost.activePlayer ? 1.0 : 0.35
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!lockMediaHost.activePlayer
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: lockMediaHost.activePlayer.togglePlaying()
                                }
                            }

                            Item {
                                id: miniBar
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 14

                                property real phase: 0.0
                                NumberAnimation on phase {
                                    from: 0
                                    to: Math.PI * 2
                                    duration: 780
                                    loops: Animation.Infinite
                                    running: lockMediaHost.activePlayer !== null && lockMediaHost.isPlaying
                                }

                                function seekToRatio(r) {
                                    if (!lockMediaHost.activePlayer || !lockMediaHost.canSeek || lockMediaHost.trackLen <= 0) return
                                    r = lockMediaHost.clamp(r, 0, 1)
                                    lockMediaHost.activePlayer.position = r * lockMediaHost.trackLen
                                    lockMediaHost.displayedPos = lockMediaHost.activePlayer.position
                                }

                                Rectangle {
                                    id: track
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 4
                                    radius: 8
                                    color: Appearance.colors.colLayer1
                                    opacity: 0.95
                                }

                                Canvas {
                                    id: waveCanvas
                                    anchors.fill: parent
                                    antialiasing: true

                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset?.()
                                        ctx.clearRect(0, 0, width, height)

                                        if (!lockMediaHost.activePlayer || lockMediaHost.trackLen <= 0) return

                                        const xPlay = Math.max(0, Math.min(track.width, track.width * lockMediaHost.ratio))
                                        const yMid = track.y + track.height / 2

                                        if (xPlay > 1) {
                                            ctx.save()
                                            ctx.strokeStyle = Qt.rgba(
                                                Appearance.m3colors.m3primary.r,
                                                Appearance.m3colors.m3primary.g,
                                                Appearance.m3colors.m3primary.b,
                                                0.98
                                            )
                                            ctx.lineWidth = 3.0
                                            ctx.lineCap = "round"
                                            ctx.beginPath()

                                            const step = 1.0
                                            for (let x = 0; x <= xPlay; x += step) {
                                                const t = xPlay > 0 ? (x / xPlay) : 0
                                                const amp = 0.4 + 4.6 * Math.pow(t, 1.7)
                                                const ang = (x / 20.0) * (Math.PI * 2) + miniBar.phase
                                                const y = yMid + Math.sin(ang) * amp
                                                if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                                            }
                                            ctx.stroke()
                                            ctx.restore()
                                        }
                                    }

                                    Connections {
                                        target: lockMediaHost.activePlayer
                                        enabled: lockMediaHost.activePlayer !== null
                                        function onPositionChanged() { waveCanvas.requestPaint() }
                                        function onLengthChanged() { waveCanvas.requestPaint() }
                                    }
                                }

                                onPhaseChanged: waveCanvas.requestPaint()

                                Rectangle {
                                    id: playhead
                                    width: 2
                                    height: 14
                                    radius: 1
                                    anchors.verticalCenter: track.verticalCenter
                                    x: Math.round(lockMediaHost.clamp(track.width * lockMediaHost.ratio, 0, track.width) - width / 2)
                                    color: Qt.rgba(1, 1, 1, 0.95)
                                    visible: lockMediaHost.activePlayer !== null && lockMediaHost.trackLen > 0

                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        horizontalOffset: 0
                                        verticalOffset: 0
                                        radius: 6
                                        samples: 16
                                        color: Qt.rgba(0, 0, 0, 0.40)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: lockMediaHost.canSeek
                                    cursorShape: Qt.PointingHandCursor
                                    function _seekAt(x) { miniBar.seekToRatio(x / miniBar.width) }
                                    onPressed: (m) => _seekAt(m.x)
                                    onPositionChanged: (m) => { if (pressed) _seekAt(m.x) }
                                }
                            }

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 26; height: 26
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    iconSize: 26
                                    color: Appearance.colors.colOnLayer1
                                    opacity: (lockMediaHost.activePlayer && lockMediaHost.canGoNext) ? 1.0 : 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!lockMediaHost.activePlayer && lockMediaHost.canGoNext
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: lockMediaHost.activePlayer.next()
                                }
                            }
                        }
                    }
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
                        `keyword animation workspaces,1,7,menu_decel,slidevert; dispatch workspace ${2147483647 - lastWorkspaceId}`
                    ])
                } else {
                    Quickshell.execDetached(["hyprctl", "--batch", `dispatch workspace ${lastWorkspaceId}; reload`])
                }
            }
        }
    }
}

