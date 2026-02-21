import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import QtQuick.Shapes

AbstractBackgroundWidget {
    id: root

    configEntryName: "media"

    readonly property bool useAlbumColors: Config.options.background.widgets.media.useAlbumColors
    readonly property bool useDynamicColors: root.useAlbumColors && root.currentPlayer !== null
    readonly property bool showPreviousToggle: Config.options.background.widgets.media.showPreviousToggle

    readonly property var playerList: MprisController.players
    property var filteredPlayerList: playerList.filter(function(p) { return p !== null })
    property var filteredActivePlayer: MprisController.activePlayer
    property MprisPlayer currentPlayer: null

    function s(x) { return (x === undefined || x === null) ? "" : ("" + x) }

    function playerKey(p) {
        if (!p) return ""
        return (s(p.desktopEntry) + " " + s(p.identity) + " " + s(p.name)).toLowerCase()
    }
    function isBravePlayer(p) {
        var k = playerKey(p)
        return (k.indexOf("brave") !== -1) || (k.indexOf("brave-browser") !== -1)
    }
    function isFirefoxPlayer(p) {
        var k = playerKey(p)
        return (k.indexOf("firefox") !== -1)
    }

    readonly property bool isBrave: isBravePlayer(currentPlayer)
    readonly property bool isFirefox: isFirefoxPlayer(currentPlayer)

    function findFirstPlayer(pred) {
        for (var i = 0; i < root.playerList.length; i++) {
            var p = root.playerList[i]
            if (p && pred(p)) return p
        }
        return null
    }

    function toggleFirefoxBrave() {
        var ff = findFirstPlayer(isFirefoxPlayer)
        var br = findFirstPlayer(isBravePlayer)
        if (!ff && !br) return

        if (root.isFirefox && br) { root.currentPlayer = br; return }
        if (root.isBrave && ff) { root.currentPlayer = ff; return }
        root.currentPlayer = ff ? ff : br
    }

    onPlayerListChanged: {
        if (!root.filteredPlayerList || root.filteredPlayerList.length === 0) {
            root.currentPlayer = null
            return
        }

        var stillExists = false
        for (var i = 0; i < root.filteredPlayerList.length; i++) {
            if (root.filteredPlayerList[i] === root.currentPlayer) {
                stillExists = true
                break
            }
        }
        if (!stillExists) {
            root.currentPlayer = root.filteredPlayerList[0]
        }
    }

    property string playerctlId: ""

    function resolvePlayerctlId() {
        playerctlId = ""
        if (!playerctlResolve.running) playerctlResolve.running = true
    }

    Process {
        id: playerctlResolve
        running: false
        command: [
            "bash", "-lc",
            "set -e; " +
            "pat=''; " +
            "if echo '" + playerKey(root.currentPlayer) + "' | grep -qi 'brave'; then pat='brave|chrom'; " +
            "elif echo '" + playerKey(root.currentPlayer) + "' | grep -qi 'firefox'; then pat='firefox'; " +
            "else pat=''; fi; " +
            "if [ -n \"$pat\" ]; then " +
            "  playerctl -l 2>/dev/null | tr -d '\\r' | grep -i -m1 -E \"$pat\" || true; " +
            "else " +
            "  playerctl -l 2>/dev/null | tr -d '\\r' | head -n1 || true; " +
            "fi"
        ]
        stdout: SplitParser {
            onRead: function(data) {
                var id = (data ? ("" + data).trim() : "")
                if (!id) return
                root.playerctlId = id
            }
        }
        onExited: function() { playerctlResolve.running = false }
    }

    property string artUrl: (root.currentPlayer ? s(root.currentPlayer.trackArtUrl) : "")
    property string artUrlFallback: ""
    property string effectiveArtUrl: (root.artUrl !== "" ? root.artUrl : root.artUrlFallback)

    property string artDownloadLocation: Directories.coverArt
    property string artFileName: (root.effectiveArtUrl !== "" ? Qt.md5(root.effectiveArtUrl) : "")
    property string artFilePath: (root.artFileName !== "" ? (root.artDownloadLocation + "/" + root.artFileName) : "")

    // ✅ Igual que el original: cuando no hay player / no hay art => NO imagen, solo placeholder
    property string currentImageToShow: ""     // <- antes era wallpaper, ahora vacío por diseño
    property string displayedArtFilePath: ""

    function isFileLikeUrl(u) {
        if (!u) return false
        var str = ("" + u).trim()
        return (str.indexOf("file://") === 0) || (str.indexOf("/") === 0)
    }
    function normalizeFileUrl(u) {
        if (!u) return ""
        var str = ("" + u).trim()
        if (str.indexOf("file://") === 0) return str
        if (str.indexOf("/") === 0) return "file://" + str
        return str
    }

    // Cuando se logra una ruta válida => la mostramos
    onDisplayedArtFilePathChanged: {
        if (root.displayedArtFilePath && root.displayedArtFilePath !== "" && root.displayedArtFilePath !== "file://") {
            root.currentImageToShow = root.displayedArtFilePath
        } else {
            root.currentImageToShow = ""
        }
    }

    function refreshArt() {
        var u = root.effectiveArtUrl

        // Sin player => vacío (se verá music_off por el loader)
        if (!root.currentPlayer) {
            root.displayedArtFilePath = ""
            root.currentImageToShow = ""
            return
        }

        // Con player pero sin URL => vacío (se verá hourglass_bottom por el loader)
        if (!u || ("" + u).trim() === "") {
            root.displayedArtFilePath = ""
            root.currentImageToShow = ""
            return
        }

        if (root.isFileLikeUrl(u)) {
            root.displayedArtFilePath = root.normalizeFileUrl(u)
            return
        }

        updateArtDownload(u)
    }

    function updateArtDownload(url) {
        if (!url || url === "") return
        coverArtDownloader.targetFile = url
        coverArtDownloader.artFilePath = root.artFilePath
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetFile: ""
        property string artFilePath: ""
        running: false

        command: [
            "bash", "-lc",
            "set -e; " +
            "mkdir -p '" + root.artDownloadLocation + "'; " +
            "[ -z '" + coverArtDownloader.targetFile + "' ] && exit 1; " +
            "[ -z '" + coverArtDownloader.artFilePath + "' ] && exit 1; " +
            "if [ -f '" + coverArtDownloader.artFilePath + "' ]; then exit 0; fi; " +
            "curl -fLsS -L '" + coverArtDownloader.targetFile + "' -o '" + coverArtDownloader.artFilePath + "'"
        ]

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.displayedArtFilePath = Qt.resolvedUrl(coverArtDownloader.artFilePath)
            } else {
                // falla => vacío (placeholder)
                root.displayedArtFilePath = ""
                root.currentImageToShow = ""
            }
        }
    }

    property string lastTrackKey: ""

    function makeTrackKey() {
        if (!root.currentPlayer) return ""
        var t = s(root.currentPlayer.trackTitle)
        var a = s(root.currentPlayer.trackArtist)
        var l = s(root.currentPlayer.length)
        return t + "|" + a + "|" + l
    }

    function forceTrackRefresh() {
        // ✅ como el original: reset a vacío antes de recalcular
        root.currentImageToShow = ""
        root.displayedArtFilePath = ""
        root.artUrlFallback = ""

        refreshArt()

        if (root.currentPlayer && (root.isBrave || root.artUrl === "")) {
            if (!playerctlArtFetch.running) playerctlArtFetch.running = true
        }
    }

    Timer {
        id: trackWatcher
        interval: 450
        repeat: true
        running: root.currentPlayer !== null
        onTriggered: {
            var k = root.makeTrackKey()
            if (k !== root.lastTrackKey) {
                root.lastTrackKey = k
                root.forceTrackRefresh()
            }
        }
    }

    onArtUrlChanged: refreshArt()
    onArtUrlFallbackChanged: refreshArt()

    Process {
        id: playerctlArtFetch
        running: false

        command: [
            "bash", "-lc",
            "set -e; " +
            "pid='" + s(root.playerctlId) + "'; " +
            "pname='" + s(root.currentPlayer ? root.currentPlayer.name : "") + "'; " +
            "pident='" + s(root.currentPlayer ? root.currentPlayer.identity : "") + "'; " +
            "pdesk='" + s(root.currentPlayer ? root.currentPlayer.desktopEntry : "") + "'; " +
            "try_one(){ " +
            "  p=\"$1\"; [ -z \"$p\" ] && return 1; " +
            "  u=\"$(playerctl -p \"$p\" metadata mpris:artUrl 2>/dev/null || true)\"; u=\"$(echo \"$u\" | tr -d '\\r')\"; " +
            "  [ -n \"$u\" ] && { echo \"$u\"; return 0; }; " +
            "  u=\"$(playerctl -p \"$p\" metadata xesam:artUrl 2>/dev/null || true)\"; u=\"$(echo \"$u\" | tr -d '\\r')\"; " +
            "  [ -n \"$u\" ] && { echo \"$u\"; return 0; }; " +
            "  return 1; " +
            "}; " +
            "try_one \"$pid\" || try_one \"$pname\" || try_one \"$pident\" || try_one \"$pdesk\" || true"
        ]

        stdout: SplitParser {
            onRead: function(data) {
                var url = (data ? ("" + data).trim() : "")
                if (!url) return

                root.artUrlFallback = url

                if (root.isFileLikeUrl(url)) {
                    root.displayedArtFilePath = root.normalizeFileUrl(url)
                } else {
                    root.updateArtDownload(url)
                }
            }
        }

        onExited: function(exitCode, exitStatus) { playerctlArtFetch.running = false }
    }

    function doPrev() {
        if (!root.currentPlayer) return

        if (root.isBrave) {
            if (!playerctlPrev.running) playerctlPrev.running = true
            return
        }

        if (root.currentPlayer.previous) root.currentPlayer.previous()
        else if (root.currentPlayer.previousTrack) root.currentPlayer.previousTrack()
    }

    function doNext() {
        if (!root.currentPlayer) return

        if (root.isBrave) {
            if (!playerctlNext.running) playerctlNext.running = true
            return
        }

        if (root.currentPlayer.next) root.currentPlayer.next()
        else if (root.currentPlayer.nextTrack) root.currentPlayer.nextTrack()
    }

    Process {
        id: playerctlPrev
        running: false
        command: [
            "bash", "-lc",
            "do_playerctl(){ " +
            "  plist=\"$(playerctl -l 2>/dev/null | tr -d '\\r' | grep -i -E 'brave|chromium|chrome|chrom' || true)\"; " +
            "  if [ -n \"$plist\" ]; then " +
            "    while IFS= read -r p; do " +
            "      [ -z \"$p\" ] && continue; " +
            "      timeout 0.35s playerctl -p \"$p\" previous >/dev/null 2>&1 && return 0; " +
            "    done <<< \"$plist\"; " +
            "  fi; " +
            "  timeout 0.35s playerctl previous >/dev/null 2>&1 && return 0; " +
            "  return 1; " +
            "}; " +
            "do_dbus(){ " +
            "  command -v busctl >/dev/null 2>&1 || return 1; " +
            "  blist=\"$(busctl --user --no-pager list 2>/dev/null | awk '{print $1}' | grep -E '^org\\.mpris\\.MediaPlayer2\\.' | grep -i -E 'brave|chromium|chrome|chrom' || true)\"; " +
            "  if [ -n \"$blist\" ]; then " +
            "    while IFS= read -r b; do " +
            "      [ -z \"$b\" ] && continue; " +
            "      timeout 0.35s busctl --user call \"$b\" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player Previous >/dev/null 2>&1 && return 0; " +
            "    done <<< \"$blist\"; " +
            "  fi; " +
            "  return 1; " +
            "}; " +
            "do_key(){ " +
            "  command -v ydotool >/dev/null 2>&1 || return 1; " +
            "  timeout 0.35s ydotool key 165:1 165:0 >/dev/null 2>&1 && return 0; " +
            "  return 1; " +
            "}; " +
            "do_playerctl || do_dbus || do_key || true"
        ]
        onExited: function() { playerctlPrev.running = false }
    }

    Process {
        id: playerctlNext
        running: false
        command: [
            "bash", "-lc",
            "do_playerctl(){ " +
            "  plist=\"$(playerctl -l 2>/dev/null | tr -d '\\r' | grep -i -E 'brave|chromium|chrome|chrom' || true)\"; " +
            "  if [ -n \"$plist\" ]; then " +
            "    while IFS= read -r p; do " +
            "      [ -z \"$p\" ] && continue; " +
            "      timeout 0.35s playerctl -p \"$p\" next >/dev/null 2>&1 && return 0; " +
            "    done <<< \"$plist\"; " +
            "  fi; " +
            "  timeout 0.35s playerctl next >/dev/null 2>&1 && return 0; " +
            "  return 1; " +
            "}; " +
            "do_dbus(){ " +
            "  command -v busctl >/dev/null 2>&1 || return 1; " +
            "  blist=\"$(busctl --user --no-pager list 2>/dev/null | awk '{print $1}' | grep -E '^org\\.mpris\\.MediaPlayer2\\.' | grep -i -E 'brave|chromium|chrome|chrom' || true)\"; " +
            "  if [ -n \"$blist\" ]; then " +
            "    while IFS= read -r b; do " +
            "      [ -z \"$b\" ] && continue; " +
            "      timeout 0.35s busctl --user call \"$b\" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player Next >/dev/null 2>&1 && return 0; " +
            "    done <<< \"$blist\"; " +
            "  fi; " +
            "  return 1; " +
            "}; " +
            "do_key(){ " +
            "  command -v ydotool >/dev/null 2>&1 || return 1; " +
            "  timeout 0.35s ydotool key 163:1 163:0 >/dev/null 2>&1 && return 0; " +
            "  return 1; " +
            "}; " +
            "do_playerctl || do_dbus || do_key || true"
        ]
        onExited: function() { playerctlNext.running = false }
    }


    property real braveSystemVolume: 0.0
    property bool braveSystemVolumeValid: false

    function clamp01(v) {
        if (v < 0.0) return 0.0
        if (v > 1.0) return 1.0
        return v
    }

    property real volumeDisplay: {
        if (root.isBrave && root.braveSystemVolumeValid) return root.braveSystemVolume
        return (root.currentPlayer ? (root.currentPlayer.volume || 0) : 0)
    }

    function refreshSystemVolume() {
        if (!root.isBrave) return
        if (wpctlGet.running) return
        wpctlGet.running = true
    }

    function setVolumeSmart(v) {
        v = clamp01(v)
        if (!root.currentPlayer) return

        if (!root.isBrave) {
            root.currentPlayer.volume = v
            return
        }

        root.braveSystemVolume = v
        root.braveSystemVolumeValid = true
        wpctlSet.targetVol = v
        wpctlSet.running = true
    }

    Process {
        id: wpctlGet
        running: false
        command: [ "bash", "-lc", "set -e; wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}' | head -n1" ]
        stdout: SplitParser {
            onRead: function(data) {
                var sdata = (data ? ("" + data).trim() : "")
                var v = parseFloat(sdata)
                if (!isNaN(v)) {
                    root.braveSystemVolume = root.clamp01(v)
                    root.braveSystemVolumeValid = true
                }
            }
        }
        onExited: function() { wpctlGet.running = false }
    }

    Process {
        id: wpctlSet
        property real targetVol: 0.0
        running: false
        command: [ "bash", "-lc", "set -e; wpctl set-volume @DEFAULT_AUDIO_SINK@ '" + wpctlSet.targetVol + "'" ]
        onExited: function() { wpctlSet.running = false }
    }

    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: Config.options.background.widgets.media.visualizer.enable
        onRunningChanged: { if (!cavaProc.running) root.visualizerPoints = [] }
        command: ["cava", "-p", FileUtils.trimFileProtocol(Directories.scriptPath) + "/cava/raw_output_config.txt"]
        stdout: SplitParser {
            onRead: function(data) {
                var points = ("" + data).split(";").map(function(p) { return parseFloat(p.trim()) })
                    .filter(function(p) { return !isNaN(p) })
                root.visualizerPoints = points
            }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property color artDominantColor: ColorUtils.mix(
        (colorQuantizer && colorQuantizer.colors && colorQuantizer.colors.length > 0) ? colorQuantizer.colors[0] : Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer,
        0.8
    ) || Appearance.m3colors.m3secondaryContainer

    property QtObject blendedColors: AdaptedMaterialScheme { color: artDominantColor }

    property var dynamicColors: {
        return {
            colPrimary: root.useDynamicColors ? blendedColors.colPrimary : Appearance.colors.colPrimary,
            colPrimaryBackground: root.useDynamicColors ? blendedColors.colPrimaryContainer : Appearance.colors.colPrimaryContainer,
            colPrimaryBackgroundHover: root.useDynamicColors ? blendedColors.colPrimaryContainerHover : Appearance.colors.colPrimaryContainerHover,
            colPrimaryRipple: root.useDynamicColors ? blendedColors.colPrimaryContainerActive : Appearance.colors.colPrimaryContainerActive,

            colSecondary: root.useDynamicColors ? blendedColors.colSecondary : Appearance.colors.colSecondary,
            colSecondaryBackground: root.useDynamicColors ? blendedColors.colSecondaryContainer : Appearance.colors.colSecondaryContainer,
            colSecondaryBackgroundHover: root.useDynamicColors ? blendedColors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainerHover,
            colSecondaryRipple: root.useDynamicColors ? blendedColors.colSecondaryContainerActive : Appearance.colors.colSecondaryContainerActive,

            colTertiary: root.useDynamicColors ? blendedColors.colTertiary : Appearance.colors.colTertiary,
            colTertiaryBackground: root.useDynamicColors ? blendedColors.colTertiaryContainer : Appearance.colors.colTertiaryContainer,
            colTertiaryBackgroundHover: root.useDynamicColors ? blendedColors.colTertiaryContainerHover : Appearance.colors.colTertiaryContainerHover,
            colTertiaryRipple: root.useDynamicColors ? blendedColors.colTertiaryContainerActive : Appearance.colors.colTertiaryContainerActive
        }
    }

    property real widgetSize: 200
    property real controlsSize: 55
    property real buttonIconSize: 30

    property real mouseAngleForSeek: 0
    property bool isHoveringSeekZone: false

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    Component.onCompleted: {
        updatePlayer()
        resolvePlayerctlId()
        forceTrackRefresh()
        refreshSystemVolume()
    }

    onCurrentPlayerChanged: {
        root.artUrlFallback = ""
        root.lastTrackKey = ""
        resolvePlayerctlId()

          if (!root.currentPlayer) {
            root.displayedArtFilePath = ""
            root.currentImageToShow = ""
            return
        }

        forceTrackRefresh()
        refreshSystemVolume()
    }

    function updatePlayer() {
        if (root.filteredPlayerList.length === 0) { root.currentPlayer = null; return }
        if (root.filteredPlayerList.length > 0) { root.currentPlayer = root.filteredPlayerList[0]; return }
        root.currentPlayer = MprisController.activePlayer
    }


    Item {
        id: contentItem
        implicitWidth: root.widgetSize
        implicitHeight: root.widgetSize

        // Glow blur (solo si hay imagen)
        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.currentImageToShow
            sourceSize.width: contentItem.implicitWidth
            sourceSize.height: sourceSize.width
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            opacity: (Config.options.background.widgets.media.glow.enable && root.currentImageToShow !== "") ? 1 : 0
            Behavior on opacity { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }
            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
                brightness: 0.002 * Config.options.background.widgets.media.glow.brightness
            }
        }

        ControlButton {
            z: 4
            implicitWidth: 28
            implicitHeight: 28
            anchors { left: parent.left; top: parent.top; leftMargin: 6; topMargin: 6 }

            colBackground: root.dynamicColors.colTertiaryBackground
            colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
            colRipple: root.dynamicColors.colTertiaryRipple
            symbolColor: root.dynamicColors.colSecondary
            symbolText: "swap_horiz"
            onClicked: root.toggleFirefoxBrave()
        }

        // ✅ PLACEHOLDER ORIGINAL (music_off / hourglass_bottom)
        FadeLoader {
            z: 20
            anchors.centerIn: parent
            shown: (root.currentPlayer === null) || (root.currentPlayer !== null && root.currentImageToShow === "")
            sourceComponent: MaterialShapeWrappedMaterialSymbol {
                fill: 1
                padding: 20
                text: (root.currentPlayer === null) ? "music_off" : "hourglass_bottom"
                anchors.centerIn: parent
                iconSize: root.widgetSize / 4
                shape: MaterialShape.Shape.Cookie12Sided
                color: blendedColors.colOnSecondaryContainer
                colSymbol: Appearance.colors.colPrimaryContainer
            }
        }

        Rectangle {
            id: artBackground
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimaryContainer

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artBackground.width
                    height: artBackground.height
                    radius: artBackground.radius
                }
            }

            StyledImage {
                id: mediaArt
                anchors.fill: parent
                source: root.currentImageToShow
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                rotation: 0
                opacity: root.currentImageToShow !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            FadeLoader {
                shown: Config.options.background.widgets.media.tintArtCover && root.currentImageToShow !== ""
                anchors.fill: mediaArt
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false
                        anchors.fill: parent
                        source: mediaArt
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.9)
                    }
                }
            }

            RadialWaveVisualizer {
                z: 1
                anchors.fill: parent
                points: root.visualizerPoints
                live: root.currentPlayer ? root.currentPlayer.isPlaying : false
                color: dynamicColors.colPrimaryRipple
                waveOpacity: Config.options.background.widgets.media.visualizer.opacity
                waveBlur: Config.options.background.widgets.media.visualizer.blur
                smoothing: Config.options.background.widgets.media.visualizer.smoothing
            }
        }

        Timer { id: seekGraceTimer; interval: 2000; repeat: false }

        Rectangle {
            id: pausedOverlay
            anchors.fill: parent
            radius: Appearance.rounding.full
            z: 8
            opacity: (root.currentPlayer && !root.currentPlayer.isPlaying && !mouseControl.pressed && !seekGraceTimer.running) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 280 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.25) }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.80) }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 20
            spacing: 2
            z: 9
            opacity: pausedOverlay.opacity
            visible: pausedOverlay.visible
            Behavior on opacity { NumberAnimation { duration: 280 } }

            Text {
                Layout.fillWidth: true
                text: root.currentPlayer ? (s(root.currentPlayer.trackTitle) !== "" ? s(root.currentPlayer.trackTitle) : "Pausado") : "Pausado"
                color: "white"
                font.bold: true
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: root.currentPlayer ? s(root.currentPlayer.trackArtist) : ""
                color: root.dynamicColors.colSecondary
                font.bold: false
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Shape {
            anchors.fill: parent
            z: 4
            opacity: volTimer.running ? 0.1 : 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ShapePath {
                strokeColor: Qt.rgba(0, 0, 0, 0.2)
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: contentItem.width / 2; centerY: contentItem.height / 2
                    radiusX: (contentItem.width / 2) - 3
                    radiusY: (contentItem.height / 2) - 3
                    startAngle: 0; sweepAngle: 360
                }
            }

            ShapePath {
                strokeColor: root.dynamicColors.colSecondary
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: contentItem.width / 2; centerY: contentItem.height / 2
                    radiusX: (contentItem.width / 2) - 3
                    radiusY: (contentItem.height / 2) - 3
                    startAngle: -90
                    sweepAngle: (root.currentPlayer && root.currentPlayer.length > 0)
                                ? (root.currentPlayer.position / root.currentPlayer.length) * 360
                                : 0
                }
            }

            ShapePath {
                strokeColor: (root.isHoveringSeekZone && !volTimer.running) ? Qt.rgba(1, 1, 1, 0.25) : "transparent"
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: contentItem.width / 2; centerY: contentItem.height / 2
                    radiusX: (contentItem.width / 2) - 3
                    radiusY: (contentItem.height / 2) - 3
                    startAngle: -90
                    sweepAngle: root.mouseAngleForSeek
                }
            }
        }

        ControlButton {
            anchors { left: parent.left; bottom: parent.bottom }
            buttonRadius: (root.currentPlayer && root.currentPlayer.isPlaying) ? Appearance.rounding.normal : controlsSize / 2
            colBackground: root.dynamicColors.colSecondaryBackground
            colBackgroundHover: root.dynamicColors.colSecondaryBackgroundHover
            colRipple: root.dynamicColors.colSecondaryRipple
            symbolText: (root.currentPlayer && root.currentPlayer.isPlaying) ? "pause" : "play_arrow"
            symbolColor: useAlbumColors ? blendedColors.colTertiary : Appearance.colors.colTertiary
            onClicked: { if (root.currentPlayer) root.currentPlayer.togglePlaying() }
        }

        Rectangle {
            anchors { top: parent.top; right: parent.right }
            implicitWidth: root.showPreviousToggle ? controlsSize * 2 : controlsSize
            implicitHeight: controlsSize
            z: 2
            radius: Appearance.rounding.full
            color: dynamicColors.colTertiaryBackground
            Behavior on implicitWidth { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }

            FadeLoader {
                shown: root.showPreviousToggle
                sourceComponent: ControlButton {
                    anchors.left: parent.left
                    colBackground: root.dynamicColors.colTertiaryBackground
                    colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                    colRipple: root.dynamicColors.colTertiaryRipple
                    symbolColor: root.dynamicColors.colSecondary
                    symbolText: "skip_previous"
                    onClicked: root.doPrev()
                }
            }

            ControlButton {
                anchors.right: parent.right
                colBackground: root.dynamicColors.colTertiaryBackground
                colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                colRipple: root.dynamicColors.colTertiaryRipple
                symbolColor: root.dynamicColors.colSecondary
                symbolText: "skip_next"
                onClicked: root.doNext()
            }
        }

        Timer { id: volTimer; interval: 1500 }

        Shape {
            anchors.fill: parent
            anchors.margins: 4
            z: 10
            opacity: volTimer.running ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ShapePath {
                strokeColor: Qt.rgba(0,0,0, 0.5)
                strokeWidth: 6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: contentItem.width / 2; centerY: contentItem.height / 2
                    radiusX: (contentItem.width / 2) - 6
                    radiusY: (contentItem.height / 2) - 6
                    startAngle: 0; sweepAngle: 360
                }
            }
            ShapePath {
                strokeColor: root.dynamicColors.colTertiary
                strokeWidth: 6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: contentItem.width / 2; centerY: contentItem.height / 2
                    radiusX: (contentItem.width / 2) - 6
                    radiusY: (contentItem.height / 2) - 6
                    startAngle: -90
                    sweepAngle: root.volumeDisplay * 360
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 60; height: 30
            radius: 15
            color: "black"
            opacity: volTimer.running ? 0.7 : 0
            visible: opacity > 0
            z: 11
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: root.currentPlayer ? (Math.round(root.volumeDisplay * 100) + "%") : "--"
                color: "white"
                font.bold: true
                font.pixelSize: 14
            }
        }

        MouseArea {
            id: mouseControl
            anchors.fill: parent
            propagateComposedEvents: true
            scrollGestureEnabled: false
            hoverEnabled: true
            preventStealing: false

            function updateSeekCalculations(mouseX, mouseY) {
                var centerX = width / 2
                var centerY = height / 2
                var rad = Math.atan2(mouseY - centerY, mouseX - centerX)
                var deg = rad * (180 / Math.PI)
                deg += 90
                if (deg < 0) deg += 360

                root.mouseAngleForSeek = deg

                var dx = mouseX - centerX
                var dy = mouseY - centerY
                var distance = Math.sqrt(dx*dx + dy*dy)
                var maxRadius = width / 2

                root.isHoveringSeekZone = (distance > (maxRadius * 0.75))
                return deg / 360
            }

            onPositionChanged: function(mouse) { updateSeekCalculations(mouse.x, mouse.y) }

            onPressed: function(mouse) {
                var percent = updateSeekCalculations(mouse.x, mouse.y)
                if (root.isHoveringSeekZone) {
                    mouse.accepted = true
                    if (root.currentPlayer && root.currentPlayer.length > 0) {
                        root.currentPlayer.position = percent * root.currentPlayer.length
                    }
                } else {
                    mouse.accepted = false
                }
            }

            onReleased: function() { seekGraceTimer.restart() }

            onWheel: function(wheel) {
                if (!root.currentPlayer) return
                volTimer.restart()

                var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                var base = root.volumeDisplay
                var newVol = root.clamp01(base + delta)
                root.setVolumeSmart(newVol)
            }
        }
    }

    component ControlButton : RippleButton {
        id: button
        property string symbolText
        property color symbolColor

        z: 2
        implicitWidth: root.controlsSize
        implicitHeight: implicitWidth
        buttonRadius: Appearance.rounding.full

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.buttonIconSize
            text: button.symbolText
            fill: 1
            color: button.symbolColor
        }
    }
}

