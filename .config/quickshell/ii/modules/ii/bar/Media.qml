pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Io
import "../../common/utils"

Item {
    id: root

    // --- NUEVO: Orientación ---
    property bool vertical: false
    // Propiedad útil para saber si la barra está a la derecha
    property bool rightSide: Config.options.bar.bottom || Config.runtime.bar.position === "right"

    readonly property bool barIsVertical: root.vertical || (
        Config.runtime.bar.position === "left" ||
        Config.runtime.bar.position === "right"
    )

    // =====================================================
    // 1.1) CONFIG BASE
    // =====================================================
    property bool islandEnabled: true
    property bool expandOnHover: true
    property int  islandCollapsedWidth: 260

    property int islandExpandedHeight: root.barHeightLimit
    property int islandRadius: 999

    property int islandPaddingH: Math.round(8 + 4 * root.barT)
    property int islandPaddingV: Math.round(2 + 4 * root.barT)

    property int islandExpandAnimMs: 240
    property int islandFadeAnimMs: 170

    property bool islandPulseOnLyricChange: true
    property int  islandPulseAnimMs: 220
    property real islandPulseScale: 1.000

    property int islandBorderWidthCollapsed: Math.round(2 + 2 * root.barT)
    property int islandBorderWidthExpanded:  Math.round(2 + 2 * root.barT)
    property int islandMaxWidth: 780

    // =====================================================
    // 1.2) EFECTOS VISUALES
    // =====================================================
    property bool fxDropShadows: true
    property bool fxCoverMaskCircle: false
    property bool fxCoverRing: false
    property bool fxWaves: true
    property bool fxLyricsGradientMask: true

    // =====================================================
    // 1.3) ANIMACIONES
    // =====================================================
    property bool animEnabled: true
    property bool animMarquee: true
    property bool animLyricScroller: true
    property bool animLayoutTransitions: true

    // =====================================================
    // 1.4) “ALIVE FX” & OVERSHOOT
    // =====================================================
    property bool islandAliveFx: true

    property real islandBreatheScaleIdle: tunedBreatheIdle
    property real islandBreatheScalePlay: tunedBreathePlay
    property int  islandBreatheMsPlay: tunedBreatheMsPlay
    property int  islandBreatheMsIdle: tunedBreatheMsIdle

    property bool islandOvershootEnabled: true
    property real islandOvershootScaleExpand: tunedOvershootExpand
    property real islandOvershootScaleCollapse: tunedOvershootCollapse
    property int  islandOvershootMs: tunedOvershootMs

    property bool uiShowLoadingIndicator: true

    property int  pollIntervalMs: 80
    property int  lyricScrollAnimMs: 240
    property int  progressAnimMs: 120

    property int ringCycleMsPlay: tunedRingMsPlay
    property int ringCycleMsIdle: tunedRingMsIdle

    // 2) MPRIS
    property int _mprisRefreshTick: 0

    Timer {
        id: mprisBootstrap
        interval: 500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            _mprisRefreshTick++
            if (MprisController.activePlayer !== null)
                running = false
        }
    }

    readonly property MprisPlayer activePlayer: {
        _mprisRefreshTick
        return MprisController.activePlayer
    }

    readonly property bool hasMedia: activePlayer != null
        && activePlayer.playbackState !== MprisPlaybackState.Stopped

    readonly property bool isPlaying: activePlayer != null
        && activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property string trackTitle: StringUtils.cleanMusicTitle(activePlayer ? activePlayer.trackTitle : "") || ""
    readonly property string trackArtist: (activePlayer ? activePlayer.trackArtist : "") || ""
    readonly property string fullText: trackTitle + (trackArtist ? " • " + trackArtist : "")

    // THEME
    function _luma(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    }

    readonly property bool isLightTheme: _luma(Appearance.colors.colLayer1) > 0.55

    readonly property color islandBgColor: isLightTheme
        ? Qt.rgba(1.0, 1.0, 1.0, 0.72)
        : Qt.rgba(0.08, 0.08, 0.10, 0.72)

    readonly property color islandBorderColor: isLightTheme
        ? Qt.rgba(0.0, 0.0, 0.0, (root.islandExpanded ? 0.14 : 0.10))
        : Qt.rgba(1.0, 1.0, 1.0, (root.islandExpanded ? 0.13 : 0.11))

    readonly property color islandTextPrimary: isLightTheme
        ? Qt.rgba(0.06, 0.06, 0.07, 0.98)
        : Qt.rgba(1.0, 1.0, 1.0, 0.92)

    readonly property color islandTextSecondary: isLightTheme
        ? Qt.rgba(0.10, 0.10, 0.12, 0.72)
        : Qt.rgba(1.0, 1.0, 1.0, 0.72)

    readonly property color islandTextShadowColor: isLightTheme
        ? Qt.rgba(1.0, 1.0, 1.0, 0.35)
        : Qt.rgba(0.0, 0.0, 0.0, 0.55)

    // 3) ART
    function normalizeArtUrl(u) {
        if (!u) return ""
        if (u.startsWith("http://") || u.startsWith("https://") || u.startsWith("file://") || u.startsWith("image://"))
            return u
        if (u.startsWith("file:/") && !u.startsWith("file://"))
            return "file://" + u.slice("file:".length)
        if (u.startsWith("/"))
            return "file://" + u
        return u
    }

    readonly property string trackArtRaw: {
        if (!activePlayer) return ""
        var u = activePlayer.artUrl
        if (!u) u = activePlayer.trackArtUrl
        if (!u) u = activePlayer.coverUrl
        return u || ""
    }
    readonly property string trackArt: normalizeArtUrl(trackArtRaw)

    // 4) LYRICS
    readonly property bool lyricsEnabled: Config.options.bar.mediaPlayer.lyrics.enable
    readonly property bool useGradientMask: Config.options.bar.mediaPlayer.lyrics.useGradientMask
    readonly property string lyricsStyle: Config.options.bar.mediaPlayer.lyrics.style
    readonly property bool showLoadingIndicator: Config.options.bar.mediaPlayer.lyrics.showLoadingIndicator
    readonly property int  lyricsManualOffsetMs: (Config.options?.bar?.mediaPlayer?.lyrics?.manualOffsetMs ?? 1500)
    readonly property bool lyricsAdaptiveSync: (Config.options?.bar?.mediaPlayer?.lyrics?.adaptiveSync ?? true)
    readonly property int  lyricsSmoothSlackMs: (Config.options?.bar?.mediaPlayer?.lyrics?.smoothSlackMs ?? 160)

    property int polledPositionMs: 0
    property int polledDurationMs: 0

    function _looksLikeUs(x) { return x >= 100000000 }
    function _looksLikeMs(x) { return x >= 20000 }
    function _toMs(x) {
        if (x === null || x === undefined) return 0
        if (isNaN(x)) return 0
        if (x < 0) return 0
        if (_looksLikeUs(x)) return Math.round(x / 1000.0)
        if (_looksLikeMs(x)) return Math.round(x)
        return Math.round(x * 1000.0)
    }

    Timer {
        id: positionPoller
        running: root.animEnabled
              && root.hasMedia
              && (root.lyricsEnabled || root.isPlaying || GlobalStates.mediaControlsOpen)
        interval: root.pollIntervalMs
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.activePlayer) return
            root.polledPositionMs = _toMs(root.activePlayer.position ?? 0)
            root.polledDurationMs = _toMs(root.activePlayer.length ?? 0)
        }
    }

    Loader {
        id: lyricsLoader
        active: root.lyricsEnabled && root.hasMedia
        sourceComponent: LrclibLyrics {
            enabled: (root.trackTitle.length > 0)
                  && (root.trackArtist.length > 0)
                  && root.visible
                  && root.lyricsEnabled
                  && root.hasMedia

            title: root.trackTitle
            artist: root.trackArtist
            duration: root.polledDurationMs
            position: root.polledPositionMs
            selectedId: 0
            manualOffsetMs: root.lyricsManualOffsetMs
            adaptiveSync: root.lyricsAdaptiveSync
            smoothPosition: true
            smoothSlackMs: root.lyricsSmoothSlackMs
        }
    }

    readonly property bool hasLyricsItem: root.lyricsEnabled && root.hasMedia
        && (lyricsLoader.item !== null) && (lyricsLoader.item !== undefined)

    readonly property bool hasSyncedLines: hasLyricsItem
        && (lyricsLoader.item?.lines && lyricsLoader.item.lines.length > 0)

    readonly property bool lyricsLoading: root.uiShowLoadingIndicator
        && root.showLoadingIndicator
        && root.lyricsEnabled
        && root.hasMedia
        && !root.hasSyncedLines
        && (lyricsLoader.item?.loading === true)

    readonly property int effectiveLyricsPositionMsForUi: {
        var ms = root.polledPositionMs + root.lyricsManualOffsetMs
        if (root.lyricsAdaptiveSync && root.hasLyricsItem)
            ms += (lyricsLoader.item?.autoOffsetMs ?? 0)
        return Math.max(0, ms)
    }

    readonly property string currentLyricText: root.hasSyncedLines
        ? ((lyricsLoader.item?.currentLineText ?? "") || "♪")
        : ""

    readonly property int currentLyricIndex: root.hasSyncedLines
        ? (lyricsLoader.item?.currentIndex ?? -1)
        : -1

    // 5) WIDTH
    property int maxWidthLyrics: 900
    property int maxWidthNoLyrics: 430
    property int minWidthNoLyrics: 180
    property int noLyricsSidePadding: 14
    property int lyricsSidePadding: 30
    property int rowSpacing: 8
    property int rightMargin: 10
    property int leftMargin: 0

    property int stableWidthLyrics: 0
    property int shrinkDelayMsLyrics: 900

    TextMetrics {
        id: lyricMetrics
        font.pixelSize: Appearance.font.pixelSize.smallie + 2
        font.bold: true
        text: root.currentLyricText
    }

    TextMetrics {
        id: titleMetrics
        font.pixelSize: Appearance.font.pixelSize.smallie + 2
        font.bold: true
        text: root.fullText
    }

    readonly property int coverW: 38
    readonly property int bongoH: Math.max(22, root.islandExpandedHeight - 8)
    readonly property int bongoW: Math.round(bongoH * 1.35)

    readonly property int lyricsImplicitWidth: {
        if (!root.lyricsEnabled || !root.hasSyncedLines) return 0
        var softMin = Math.round(root.islandExpandedHeight * 5.2)
        var measured = Math.round(lyricMetrics.width) + root.lyricsSidePadding
        return Math.min(root.maxWidthLyrics, Math.max(softMin, measured))
    }

    readonly property int noLyricsViewportWidth: {
        var measured = Math.round(titleMetrics.width) + root.noLyricsSidePadding
        return Math.min(root.maxWidthNoLyrics, Math.max(root.minWidthNoLyrics, measured))
    }

    readonly property int targetWidthNoLyrics: {
        var w = root.leftMargin
              + root.bongoW + root.rowSpacing
              + root.coverW + root.rowSpacing
              + root.noLyricsViewportWidth
              + root.rightMargin
        return Math.min(root.maxWidthNoLyrics, Math.max(0, w))
    }

    readonly property int targetWidthLyrics: {
        var w = root.leftMargin
              + root.bongoW + root.rowSpacing
              + root.coverW + root.rowSpacing
              + root.lyricsImplicitWidth
              + root.rightMargin
        return Math.min(root.maxWidthLyrics, Math.max(0, w))
    }

    Timer {
        id: shrinkTimerLyrics
        interval: root.shrinkDelayMsLyrics
        repeat: false
        onTriggered: {
            if (!root.hasMedia || !root.hasSyncedLines) return
            if (root.targetWidthLyrics > 0 && root.targetWidthLyrics < root.stableWidthLyrics)
                root.stableWidthLyrics = root.targetWidthLyrics
        }
    }

    function syncLyricsWidthNow() {
        if (!root.hasMedia || !root.hasSyncedLines) return
        if (root.targetWidthLyrics <= 0) return
        root.stableWidthLyrics = root.targetWidthLyrics
        shrinkTimerLyrics.stop()
    }

    function updateStableLyricsWidth() {
        if (!root.hasMedia || !root.hasSyncedLines) return
        if (root.targetWidthLyrics <= 0) return

        if (root.stableWidthLyrics <= 0) {
            root.stableWidthLyrics = root.targetWidthLyrics
            return
        }

        if (root.targetWidthLyrics > root.stableWidthLyrics) {
            root.stableWidthLyrics = root.targetWidthLyrics
            shrinkTimerLyrics.stop()
        } else if (root.targetWidthLyrics < root.stableWidthLyrics) {
            shrinkTimerLyrics.restart()
        }
    }

    onTargetWidthLyricsChanged: updateStableLyricsWidth()

    onHasSyncedLinesChanged: {
        if (root.hasSyncedLines) syncLyricsWidthNow()
        else {
            stableWidthLyrics = 0
            shrinkTimerLyrics.stop()
        }
    }

    onHasMediaChanged: {
        if (!hasMedia) {
            stableWidthLyrics = 0
            shrinkTimerLyrics.stop()
            polledPositionMs = 0
            polledDurationMs = 0
        } else {
            if (root.hasSyncedLines) syncLyricsWidthNow()
        }
    }

    // 6) WAVEVISUALIZER (cava)
    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: root.animEnabled
              && root.hasMedia
              && root.visible
              && root.fxWaves
              && (!root.lyricsEnabled || !root.hasSyncedLines)
              && (root.isPlaying || GlobalStates.mediaControlsOpen)

        onRunningChanged: {
            if (!cavaProc.running)
                root.visualizerPoints = []
        }

        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]

        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";")
                    .map(p => parseFloat(p.trim()))
                    .filter(p => !isNaN(p))
                root.visualizerPoints = points
            }
        }
    }

    // 7) Anti-recorte y adaptabilidad
    property int _bootRefresh: 0

    Timer {
        id: bootTimer
        interval: 200
        repeat: true
        running: _bootRefresh < 20
        triggeredOnStart: true
        onTriggered: _bootRefresh++
    }

    readonly property int _parentBarThickness: {
        if (!root.parent) return 0
        // En vertical, el ancho de la barra es el grosor. En horizontal es el alto.
        return Math.floor(root.vertical ? root.parent.width : root.parent.height)
    }

    readonly property int _cfgBarH: {
        var h = Math.floor(Appearance.sizes.barHeight)
        if (h <= 0) h = 44
        return h
    }

    readonly property int barHeightLimit: {
        _bootRefresh
        var t = (_parentBarThickness > 10) ? _parentBarThickness : _cfgBarH
        return Math.max(24, t)
    }

    readonly property real barT: {
        var t = (root.barHeightLimit - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    readonly property real tunedOvershootExpand: 1.012 + (0.010 * barT)
    readonly property real tunedOvershootCollapse: 0.992 - (0.006 * barT)
    readonly property int  tunedOvershootMs: Math.round(190 + 60 * barT)

    readonly property real tunedBreatheIdle: 1.0022 + (0.0010 * barT)
    readonly property real tunedBreathePlay: 1.0070 + (0.0040 * barT)
    readonly property int  tunedBreatheMsIdle: Math.round(2600 + 300 * barT)
    readonly property int  tunedBreatheMsPlay: Math.round(1700 + 250 * barT)

    readonly property int tunedRingMsIdle: Math.round(1850 + 250 * barT)
    readonly property int tunedRingMsPlay: Math.round(1050 + 200 * barT)

    // 8) Expand/Collapse y Tamaños
    readonly property bool islandExpanded: !root.vertical && root.hasMedia && (
        GlobalStates.mediaControlsOpen ||
        (root.islandEnabled && root.expandOnHover && islandHover.hovered) ||
        (root.lyricsEnabled && root.hasSyncedLines)
    )

    readonly property int expandedWidth: root.hasMedia
        ? (root.hasSyncedLines
            ? Math.max(1, (root.stableWidthLyrics > 0 ? root.stableWidthLyrics : root.targetWidthLyrics))
            : root.targetWidthNoLyrics)
        : 0

    readonly property int collapsedWidth: Math.max(root.islandCollapsedWidth, 240)

    readonly property int targetIslandWidth: {
        if (!root.hasMedia) return 0
        if (root.vertical) {
            return Math.max(24, Math.floor(root.barHeightLimit))
        }
        if (!root.islandEnabled) return Math.min(expandedWidth, root.islandMaxWidth)
        var w = root.islandExpanded ? expandedWidth : collapsedWidth
        return Math.min(w, root.islandMaxWidth)
    }

    readonly property int targetIslandHeight: {
        if (!root.hasMedia) return 0
        
        if (root.vertical) {
            // ALTURA VERTICAL: Carátula + Botón Play/Pause apilados
            var pad = root.islandPaddingV * 2
            var thickness = Math.max(1, root.targetIslandWidth - pad)
            var slotSize = Math.max(18, Math.min(28, thickness))
            var spc = Math.round(6 + 4 * root.barT)
            // Altura = padding + carátula + espacio + botón
            return pad + slotSize + spc + slotSize
        }

        var hLimit = Math.max(24, Math.floor(root.barHeightLimit))
        var minSafeH = Math.min(24, hLimit)
        var expandedH  = Math.max(minSafeH, hLimit)
        var collapsedH = Math.max(minSafeH, Math.floor(hLimit))
        collapsedH = Math.min(collapsedH, hLimit)

        var desired = (!root.islandEnabled)
            ? expandedH
            : (root.islandExpanded ? expandedH : collapsedH)

        return Math.max(minSafeH, Math.min(desired, hLimit))
    }

    property real hoverAmount: islandHover.hovered ? 1.0 : 0.0
    Behavior on hoverAmount {
        enabled: root.animEnabled && root.animLayoutTransitions
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    property real islandScale: 1.0
    property int _lastPulseIndex: -999

    function maybePulseIsland() {
        if (!root.animEnabled || !root.animLayoutTransitions) return
        if (!root.islandEnabled || !root.islandPulseOnLyricChange) return
        if (!root.hasSyncedLines || !root.islandExpanded || root.vertical) return

        if (root.currentLyricIndex === root._lastPulseIndex) return
        root._lastPulseIndex = root.currentLyricIndex
        islandPulse.restart()
    }

    onCurrentLyricIndexChanged: maybePulseIsland()

    SequentialAnimation {
        id: islandPulse
        running: false
        PropertyAction { target: root; property: "islandScale"; value: 1.0 }
        NumberAnimation {
            target: root
            property: "islandScale"
            to: root.islandPulseScale
            duration: Math.round(root.islandPulseAnimMs * 0.45)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "islandScale"
            to: 1.0
            duration: Math.round(root.islandPulseAnimMs * 0.55)
            easing.type: Easing.OutCubic
        }
    }

    property real overshootX: 1.0

    function triggerOvershoot(expanding) {
        if (!root.animEnabled || !root.animLayoutTransitions || !root.islandOvershootEnabled || root.vertical) return
        overshootAnim.stop()
        overshootAnim.expanding = expanding
        overshootAnim.restart()
    }

    onIslandExpandedChanged: {
        if (!root.hasMedia) return
        triggerOvershoot(root.islandExpanded)
    }

    SequentialAnimation {
        id: overshootAnim
        property bool expanding: true
        running: false

        PropertyAction { target: root; property: "overshootX"; value: 1.0 }

        NumberAnimation {
            target: root
            property: "overshootX"
            to: overshootAnim.expanding ? root.islandOvershootScaleExpand : root.islandOvershootScaleCollapse
            duration: Math.round(root.islandOvershootMs * 0.50)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "overshootX"
            to: 1.0
            duration: Math.round(root.islandOvershootMs * 0.50)
            easing.type: Easing.OutCubic
        }
    }

    // DIMENSIONES RAÍZ
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false
    Layout.fillWidth: false

    Layout.minimumHeight: root.targetIslandHeight
    Layout.preferredHeight: root.targetIslandHeight

    Layout.minimumWidth: root.targetIslandWidth
    Layout.preferredWidth: root.targetIslandWidth

    implicitWidth: root.targetIslandWidth
    implicitHeight: root.targetIslandHeight

    clip: true
    visible: root.hasMedia && (root.targetIslandWidth > 10)
    opacity: root.hasMedia ? 1 : 0

    Behavior on implicitWidth {
        enabled: root.animLayoutTransitions && root.animEnabled && !root.vertical
        NumberAnimation { duration: root.islandExpandAnimMs; easing.type: Easing.InOutCubic }
    }
    Behavior on implicitHeight {
        enabled: root.animLayoutTransitions && root.animEnabled && root.vertical
        NumberAnimation { duration: root.islandExpandAnimMs; easing.type: Easing.InOutCubic }
    }
    Behavior on opacity {
        enabled: root.animLayoutTransitions && root.animEnabled
        NumberAnimation { duration: root.islandFadeAnimMs; easing.type: Easing.OutCubic }
    }

    // 13) SHELL VISUAL
    Item {
        id: islandShell
        anchors.fill: parent
        visible: root.hasMedia
        clip: true

        transform: Scale {
            origin.x: islandShell.width / 2
            origin.y: islandShell.height / 2

            xScale: root.islandScale
                  * root.overshootX
                  * ((root.animEnabled && root.islandAliveFx && root.hasMedia) ? aliveFx.breatheX : 1.0)

            yScale: root.islandScale
                  * ((root.animEnabled && root.islandAliveFx && root.hasMedia) ? aliveFx.breatheY : 1.0)
        }

        Rectangle {
            id: islandBg
            anchors.fill: parent
            radius: root.vertical ? (width / 2) : root.islandRadius
            color: "transparent"
            border.width: 0
            border.color: "transparent"
            antialiasing: true
            clip: true

            readonly property real tintOpacity: 0.00

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: root.isLightTheme
                    ? Qt.rgba(1, 1, 1, islandBg.tintOpacity)
                    : Qt.rgba(0, 0, 0, islandBg.tintOpacity)
                visible: islandBg.tintOpacity > 0.0
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: root.islandExpanded ? root.islandBorderWidthExpanded : root.islandBorderWidthCollapsed
                border.color: root.isLightTheme
                    ? Qt.rgba(0.0, 0.0, 0.0, (root.islandExpanded ? 0.16 : 0.12))
                    : Qt.rgba(0.0, 0.0, 0.0, (root.islandExpanded ? 0.48 : 0.42))
                antialiasing: true
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, parent.radius - 1)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, root.isLightTheme ? 0.55 : 0.16)
                antialiasing: true
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: root.vertical ? (root.rightSide ? undefined : parent.left) : parent.left
                anchors.right: root.vertical ? (root.rightSide ? parent.right : undefined) : parent.right
                
                anchors.topMargin: root.vertical ? parent.radius / 1.6 : 1
                anchors.leftMargin: root.vertical ? 1 : (parent.radius > 0 ? parent.radius / 1.6 : 1)
                anchors.rightMargin: root.vertical ? 1 : (parent.radius > 0 ? parent.radius / 1.6 : 1)
                
                height: root.vertical ? Math.max(2, Math.round(parent.height * 0.26)) : 1
                width: root.vertical ? 1 : undefined

                color: Qt.rgba(1, 1, 1, root.isLightTheme ? 0.85 : 0.35)
                antialiasing: true
            }
        }

        layer.enabled: root.fxDropShadows
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: (root.barHeightLimit <= 32) ? 0 : 1
            radius: (root.barHeightLimit <= 32) ? 6 : 10
            samples: (root.barHeightLimit <= 32) ? 12 : 18
            color: Qt.rgba(0, 0, 0, root.islandExpanded ? 0.34 : 0.30)
        }

        HoverHandler {
            id: islandHover
            enabled: root.islandEnabled && root.expandOnHover && !root.vertical
        }

        Item {
            id: aliveFx
            anchors.fill: parent
            visible: root.animEnabled && root.animLayoutTransitions && root.islandAliveFx && root.hasMedia
            clip: true

            property real breatheX: 1.0
            property real breatheY: 1.0

            readonly property bool active: root.hasMedia

            readonly property real targetScale: root.isPlaying
                ? root.islandBreatheScalePlay
                : root.islandBreatheScaleIdle

            readonly property int breatheMs: root.isPlaying
                ? root.islandBreatheMsPlay
                : root.islandBreatheMsIdle

            SequentialAnimation on breatheX {
                running: aliveFx.visible && aliveFx.active
                loops: Animation.Infinite
                NumberAnimation {
                    to: aliveFx.targetScale
                    duration: Math.round(aliveFx.breatheMs * 0.52)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: Math.round(aliveFx.breatheMs * 0.48)
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on breatheY {
                running: aliveFx.visible && aliveFx.active
                loops: Animation.Infinite
                NumberAnimation {
                    to: Math.min(1.03, aliveFx.targetScale + 0.002)
                    duration: Math.round(aliveFx.breatheMs * 0.52)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: Math.round(aliveFx.breatheMs * 0.48)
                    easing.type: Easing.InOutSine
                }
            }
        }

        MouseArea {
            id: mouseControl
            anchors.fill: parent
            hoverEnabled: true
            z: 50
            preventStealing: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

            onPressed: function (event) {
                event.accepted = true
                if (!root.activePlayer) return

                if (event.button === Qt.MiddleButton) {
                    root.activePlayer.togglePlaying()
                } else if (event.button === Qt.BackButton) {
                    root.activePlayer.previous()
                } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                    root.activePlayer.next()
                } else if (event.button === Qt.LeftButton) {
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
                }
            }

            onWheel: function (wheel) {
                wheel.accepted = true
                if (wheel.angleDelta.y > 0) Audio.incrementVolume()
                else Audio.decrementVolume()
            }
        }

        Item {
            id: contentRoot
            anchors.fill: parent

            states: [
                State {
                    name: "collapsed"
                    when: root.islandEnabled && !root.islandExpanded
                    PropertyChanges { target: collapsedView; opacity: 1 }
                    PropertyChanges { target: expandedView;  opacity: 0 }
                },
                State {
                    name: "expanded"
                    when: !root.islandEnabled || root.islandExpanded
                    PropertyChanges { target: collapsedView; opacity: 0 }
                    PropertyChanges { target: expandedView;  opacity: 1 }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"; to: "expanded"
                    enabled: root.animEnabled && root.animLayoutTransitions && root.islandEnabled
                    NumberAnimation { properties: "opacity"; duration: 170; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "expanded"; to: "collapsed"
                    enabled: root.animEnabled && root.animLayoutTransitions && root.islandEnabled
                    NumberAnimation { properties: "opacity"; duration: 160; easing.type: Easing.OutCubic }
                }
            ]

            // 15.1) Vista COLAPSADA (Horizontal y Vertical)
            Item {
                id: collapsedView
                anchors.fill: parent
                opacity: 1
                visible: opacity > 0.01
                clip: true

                readonly property int _contentThickness: root.vertical 
                    ? Math.max(1, width - (root.islandPaddingV * 2)) 
                    : Math.max(1, height - (root.islandPaddingV * 2))

                readonly property int _bongoH: Math.max(16, Math.min(30, _contentThickness))
                readonly property int _bongoW: Math.round(_bongoH * 1.35)
                readonly property int _coverSlot: Math.max(18, Math.min(28, _contentThickness))
                readonly property int _coverCircle: Math.max(16, Math.min(_coverSlot, 24))
                readonly property int _dotSize: Math.max(6, Math.min(8, Math.round(_contentThickness * 0.28)))

                GridLayout {
                    anchors.fill: parent
                    
                    anchors.leftMargin: root.vertical ? root.islandPaddingV : root.islandPaddingH
                    anchors.rightMargin: root.vertical ? root.islandPaddingV : root.islandPaddingH
                    anchors.topMargin: root.islandPaddingV
                    anchors.bottomMargin: root.islandPaddingV
                    
                    rowSpacing: Math.round(6 + 4 * root.barT)
                    columnSpacing: Math.round(6 + 4 * root.barT)

                    columns: root.vertical ? 1 : 4
                    rows: root.vertical ? 4 : 1
                    flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight

                    // 1) Bongo Cat (Solo horizontal)
                    BongoCat {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: collapsedView._bongoW
                        Layout.preferredHeight: collapsedView._bongoH
                        Layout.minimumWidth: collapsedView._bongoW
                        Layout.minimumHeight: collapsedView._bongoH

                        visible: root.hasMedia && !root.vertical
                        animate: root.animEnabled && root.isPlaying
                        gifSource: Qt.resolvedUrl("../../../assets/gifs/bongo-cat.gif")
                        isVertical: false
                    }

                    // 2) Slot de la Portada
                    Item {
                        id: coverSlotSmall
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: collapsedView._coverSlot
                        Layout.preferredHeight: collapsedView._coverSlot
                        Layout.minimumWidth: collapsedView._coverSlot
                        Layout.minimumHeight: collapsedView._coverSlot

                        Item {
                            id: coverCircleSmall
                            anchors.centerIn: parent
                            width: collapsedView._coverCircle
                            height: collapsedView._coverCircle

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.10)
                                antialiasing: true
                            }

                            Image {
                                id: coverImgSmall
                                anchors.fill: parent
                                source: (root.trackArt && root.trackArt.length > 0) ? root.trackArt : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                cache: true
                                visible: true
                                layer.enabled: false
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "music_note"
                                fill: 1
                                iconSize: Math.max(12, Math.round(coverCircleSmall.width * 0.65))
                                color: Qt.rgba(1, 1, 1, 0.80)
                                visible: (coverImgSmall.status !== Image.Ready)
                            }
                        }
                    }

                    // NUEVO: Botón Play/Pause grande (Solo vertical)
                    Item {
                        visible: root.vertical && root.hasMedia
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: collapsedView._coverSlot
                        Layout.preferredHeight: collapsedView._coverSlot
                        Layout.minimumWidth: collapsedView._coverSlot
                        Layout.minimumHeight: collapsedView._coverSlot

                        Rectangle {
                            anchors.centerIn: parent
                            width: collapsedView._coverCircle
                            height: collapsedView._coverCircle
                            radius: width / 2
                            color: Qt.rgba(0.2, 0.2, 0.2, 0.8)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)
                            antialiasing: true

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.isPlaying ? "pause" : "play_arrow"
                                fill: 1
                                iconSize: Math.max(12, Math.round(parent.width * 0.7))
                                color: "white"
                            }
                        }
                    }

                    // 3) Textos (Solo horizontal)
                    ColumnLayout {
                        visible: !root.vertical
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.trackArtist.length ? root.trackArtist
                                 : (root.trackTitle.length ? root.trackTitle : "Reproduciendo")
                            color: root.islandTextPrimary
                            font.pixelSize: Appearance.font.pixelSize.smallie + 1
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            opacity: 0.98
                        }

                        Item {
                            id: collapsedLyricViewport
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(12, Math.min(14, Math.round(collapsedView._contentThickness * 0.45)))
                            clip: true
                            visible: root.hasMedia

                            readonly property string lineText: root.hasSyncedLines
                                ? root.currentLyricText
                                : (root.trackTitle.length ? root.trackTitle : "")

                            TextMetrics {
                                id: collapsedLyricMetrics
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                text: collapsedLyricViewport.lineText
                            }

                            readonly property int textW: Math.round(collapsedLyricMetrics.width)
                            readonly property int delta: Math.max(0, textW - collapsedLyricViewport.width)
                            readonly property bool shouldScroll: root.animEnabled && root.animMarquee && delta > 2

                            Item {
                                id: collapsedStrip
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                x: 0
                                width: Math.max(parent.width, collapsedLyricViewport.textW)
                                function reset() { x = 0 }
                            }

                            StyledText {
                                parent: collapsedStrip
                                anchors.verticalCenter: parent.verticalCenter
                                text: collapsedLyricViewport.lineText
                                color: root.islandTextSecondary
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                elide: Text.ElideNone
                            }

                            SequentialAnimation {
                                running: collapsedLyricViewport.shouldScroll && collapsedView.visible
                                loops: Animation.Infinite
                                onRunningChanged: collapsedStrip.reset()
                                PauseAnimation { duration: 1000 }
                                NumberAnimation {
                                    target: collapsedStrip; property: "x"
                                    from: 0; to: -collapsedLyricViewport.delta
                                    duration: Math.max(2000, collapsedLyricViewport.textW * 20)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation { duration: 800 }
                                PropertyAction { target: collapsedStrip; property: "x"; value: 0 }
                            }
                        }
                    }

                    // 4) Indicador de estado (Dot) (Solo horizontal)
                    Rectangle {
                        visible: !root.vertical && root.isPlaying
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: collapsedView._dotSize
                        Layout.preferredHeight: collapsedView._dotSize
                        Layout.minimumWidth: collapsedView._dotSize
                        radius: width / 2
                        color: Qt.rgba(
                            Appearance.m3colors.m3primary.r,
                            Appearance.m3colors.m3primary.g,
                            Appearance.m3colors.m3primary.b,
                            root.isPlaying ? 0.85 : 0.25
                        )
                        antialiasing: true
                    }
                }
            }

            // 15.2) Vista EXPANDIDA (Solo Horizontal)
            Item {
                id: expandedView
                anchors.fill: parent
                opacity: 0
                visible: opacity > 0.01 && !root.vertical
                clip: true

                readonly property int contentH: Math.max(1, height - (root.islandPaddingV * 2))
                readonly property int bongoH: Math.max(18, Math.min(30, contentH))
                readonly property int bongoW: Math.round(bongoH * 1.35)
                readonly property int coverSlotSize: Math.max(20, Math.min(root.coverW, contentH))
                readonly property int coverCircleSize: Math.max(18, Math.min(24, coverSlotSize - 2))

                RowLayout {
                    id: rowLayout
                    spacing: root.rowSpacing
                    anchors.fill: parent
                    anchors.leftMargin: root.islandPaddingH
                    anchors.rightMargin: root.islandPaddingH
                    anchors.topMargin: root.islandPaddingV
                    anchors.bottomMargin: root.islandPaddingV
                    visible: root.hasMedia
                    clip: true

                    BongoCat {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 2
                        visible: root.hasMedia
                        animate: root.animEnabled && root.isPlaying
                        Layout.preferredHeight: expandedView.bongoH
                        Layout.preferredWidth: expandedView.bongoW
                        gifSource: Qt.resolvedUrl("../../../assets/gifs/bongo-cat.gif")
                        isVertical: false
                        layer.enabled: false
                    }

                    Item {
                        id: coverSlot
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: expandedView.coverSlotSize
                        implicitHeight: expandedView.coverSlotSize
                        clip: false

                        Item {
                            id: coverCircle
                            anchors.centerIn: parent
                            width: expandedView.coverCircleSize
                            height: expandedView.coverCircleSize

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.10)
                            }

                            Image {
                                id: coverImg
                                anchors.fill: parent
                                source: root.trackArt
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                cache: true
                                visible: (status === Image.Ready)
                                layer.enabled: false
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "music_note"
                                fill: 1
                                iconSize: Math.max(14, Math.round(expandedView.coverCircleSize * 0.75))
                                color: Qt.rgba(1, 1, 1, 0.70)
                                visible: (coverImg.status !== Image.Ready)
                            }

                            Rectangle {
                                id: coverStroke
                                anchors.fill: parent
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.rgba(
                                    Appearance.m3colors.m3primary.r,
                                    Appearance.m3colors.m3primary.g,
                                    Appearance.m3colors.m3primary.b,
                                    root.isPlaying ? 0.70 : (0.45 + 0.18 * root.hoverAmount)
                                )
                                layer.enabled: false
                            }

                            Rectangle {
                                id: coverGlowSource
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.rgba(
                                    Appearance.m3colors.m3primary.r,
                                    Appearance.m3colors.m3primary.g,
                                    Appearance.m3colors.m3primary.b,
                                    0.95
                                )

                                visible: root.lyricsLoading
                                opacity: root.lyricsLoading ? 1.0 : 0.0

                                layer.enabled: visible && root.fxDropShadows
                                layer.effect: DropShadow {
                                    horizontalOffset: 0
                                    verticalOffset: 0
                                    radius: 14
                                    samples: 28
                                    color: Qt.rgba(
                                        Appearance.m3colors.m3primary.r,
                                        Appearance.m3colors.m3primary.g,
                                        Appearance.m3colors.m3primary.b,
                                        0.35
                                    )
                                }

                                Behavior on opacity {
                                    enabled: root.animEnabled && root.animLayoutTransitions
                                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        Loader {
                            anchors.centerIn: parent
                            active: root.lyricsLoading
                            sourceComponent: MaterialLoadingIndicator {
                                implicitSize: 18
                                loading: true
                                color: Appearance.colors.colPrimaryContainer
                                shapeColor: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }

                    // LYRICS SCROLLER
                    Item {
                        id: lyricScroller
                        Layout.fillWidth: false
                        Layout.preferredWidth: implicitWidth
                        Layout.fillHeight: true
                        clip: true

                        visible: root.lyricsEnabled && root.hasSyncedLines
                        implicitWidth: root.lyricsImplicitWidth

                        readonly property int rowHeight: Math.max(12, Math.min(Math.floor(height / 3), Appearance.font.pixelSize.smallie + 2))
                        readonly property real baseY: Math.max(0, Math.round((height - rowHeight * 3) / 2))
                        readonly property real downScale: Math.max(0.86, Appearance.font.pixelSize.smaller / Math.max(1, (Appearance.font.pixelSize.smallie + 2)))

                        readonly property int targetCurrentIndex: root.hasSyncedLines ? (lyricsLoader.item?.currentIndex ?? -1) : -1
                        readonly property string targetPrev: root.hasSyncedLines ? (lyricsLoader.item?.prevLineText ?? "") : ""
                        readonly property string targetCurrent: root.hasSyncedLines ? (((lyricsLoader.item?.currentLineText ?? "") || "♪")) : "♪"
                        readonly property string targetNext: root.hasSyncedLines ? (lyricsLoader.item?.nextLineText ?? "") : ""

                        readonly property int curLineStartMs: (root.hasSyncedLines && targetCurrentIndex >= 0)
                            ? (lyricsLoader.item?.lines?.[targetCurrentIndex]?.timeMs ?? 0)
                            : 0

                        readonly property int nextLineStartMs: (root.hasSyncedLines && targetCurrentIndex >= 0)
                            ? (lyricsLoader.item?.lines?.[targetCurrentIndex + 1]?.timeMs ?? (curLineStartMs + 3000))
                            : (curLineStartMs + 3000)

                        readonly property real lineProgress: {
                            if (!root.hasSyncedLines || targetCurrentIndex < 0) return 0
                            var currentPos = root.effectiveLyricsPositionMsForUi
                            if (currentPos < curLineStartMs) return 0
                            if (currentPos >= nextLineStartMs) return 1
                            var span = Math.max(1, nextLineStartMs - curLineStartMs)
                            return (currentPos - curLineStartMs) / span
                        }

                        property int lastIndex: -1
                        property bool isMovingForward: true
                        property real scrollOffset: 0

                        readonly property real animProgress: Math.abs(scrollOffset) / rowHeight
                        readonly property real dimOpacity: 0.55
                        readonly property real activeOpacity: 1.0
                        property int staticLineAnimDuration: 110

                        readonly property real activeLineBottomY: Math.round(
                            (lyricScroller.baseY - lyricScroller.scrollOffset) + (lyricScroller.rowHeight * 2)
                        )

                        Item {
                            x: 0
                            width: parent.width
                            height: 2
                            y: Math.max(0, Math.min(parent.height - height, lyricScroller.activeLineBottomY + 1))
                            opacity: 0.95
                            visible: root.lyricsEnabled && root.hasSyncedLines

                            Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(1, 1, 1, 0.10) }

                            Rectangle {
                                width: Math.round(parent.width * lyricScroller.lineProgress)
                                height: parent.height
                                radius: 2
                                color: Qt.rgba(
                                    Appearance.m3colors.m3primary.r,
                                    Appearance.m3colors.m3primary.g,
                                    Appearance.m3colors.m3primary.b,
                                    0.52
                                )
                                Behavior on width { enabled: false }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: parent.height
                                    radius: 2
                                    color: Qt.rgba(1, 1, 1, 0.18)
                                    visible: parent.width > 12
                                }
                            }
                        }

                        onTargetCurrentIndexChanged: {
                            if (!root.animEnabled || !root.animLyricScroller) {
                                lastIndex = targetCurrentIndex
                                isMovingForward = true
                                scrollOffset = 0
                                staticLyricLine.text = targetCurrent
                                staticLyricLine.opacity = 1.0
                                return
                            }

                            if (targetCurrentIndex !== lastIndex) {
                                staticLyricBlinkAnimation.start()
                                isMovingForward = targetCurrentIndex > lastIndex
                                lastIndex = targetCurrentIndex
                                scrollAnimation.restart()
                            }
                        }

                        SequentialAnimation {
                            id: scrollAnimation
                            running: false
                            PropertyAction {
                                target: lyricScroller
                                property: "scrollOffset"
                                value: lyricScroller.isMovingForward ? -lyricScroller.rowHeight : lyricScroller.rowHeight
                            }
                            NumberAnimation {
                                target: lyricScroller
                                property: "scrollOffset"
                                to: 0
                                duration: root.lyricScrollAnimMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        SequentialAnimation {
                            id: staticLyricBlinkAnimation
                            running: false
                            NumberAnimation {
                                target: staticLyricLine
                                property: "opacity"
                                from: 1.0
                                to: 0.0
                                duration: lyricScroller.staticLineAnimDuration
                                easing.type: Easing.InOutSine
                            }
                            PropertyAction {
                                target: staticLyricLine
                                property: "text"
                                value: lyricScroller.targetCurrent
                            }
                            NumberAnimation {
                                target: staticLyricLine
                                property: "opacity"
                                from: 0.0
                                to: 1.0
                                duration: lyricScroller.staticLineAnimDuration
                                easing.type: Easing.InOutSine
                            }
                        }

                        LyricLine {
                            id: staticLyricLine
                            anchors.centerIn: parent
                            highlight: true
                            opacity: 0
                            text: "♪"
                            visible: root.lyricsStyle === "static"
                            fillProgress: lyricScroller.lineProgress
                            lineHeight: lyricScroller.rowHeight
                        }

                        Loader {
                            anchors.fill: parent
                            active: root.lyricsStyle === "scrolling"
                            sourceComponent: Column {
                                width: parent.width
                                spacing: 0
                                y: lyricScroller.baseY - lyricScroller.scrollOffset

                                LyricLine {
                                    text: lyricScroller.targetPrev
                                    highlight: false
                                    useGradient: true
                                    gradientDirection: "top"
                                    opacity: (lyricScroller.isMovingForward)
                                        ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                                        : lyricScroller.dimOpacity
                                    scale: (lyricScroller.isMovingForward)
                                        ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                                        : lyricScroller.downScale
                                    lineHeight: lyricScroller.rowHeight
                                }

                                LyricLine {
                                    text: lyricScroller.targetCurrent
                                    highlight: true
                                    useGradient: false
                                    opacity: lyricScroller.activeOpacity
                                        - (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                                    scale: 1.0 - (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                                    fillProgress: lyricScroller.lineProgress
                                    lineHeight: lyricScroller.rowHeight
                                }

                                LyricLine {
                                    text: lyricScroller.targetNext
                                    highlight: false
                                    useGradient: true
                                    gradientDirection: "bottom"
                                    opacity: (!lyricScroller.isMovingForward)
                                        ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                                        : lyricScroller.dimOpacity
                                    scale: (!lyricScroller.isMovingForward)
                                        ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                                        : lyricScroller.downScale
                                    lineHeight: lyricScroller.rowHeight
                                }
                            }
                        }
                    }

                    // NO LYRICS: marquee + waves
                    Item {
                        id: marqueeViewport
                        Layout.fillWidth: false
                        Layout.preferredWidth: implicitWidth
                        Layout.fillHeight: true
                        clip: true

                        implicitWidth: root.noLyricsViewportWidth
                        visible: root.hasMedia && (!root.lyricsEnabled || !root.hasSyncedLines)

                        readonly property int textW: Math.max(0, Math.round(titleMetrics.width))
                        readonly property int delta: Math.max(0, textW - marqueeViewport.width)

                        Item {
                            id: movingStrip
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            x: 0
                            width: Math.max(marqueeViewport.width, marqueeViewport.textW)
                            property bool shouldScroll: marqueeViewport.delta > 1
                            function reset() { x = 0 }
                        }

                        Text {
                            id: scrollingText
                            parent: movingStrip
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.fullText
                            color: root.islandTextPrimary
                            font.pixelSize: Appearance.font.pixelSize.smallie + 2
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.NoWrap
                            elide: Text.ElideNone
                            width: marqueeViewport.textW
                            layer.enabled: false
                            onTextChanged: movingStrip.reset()
                        }

                        SequentialAnimation {
                            id: marqueeAnim
                            running: root.animEnabled
                                  && root.animMarquee
                                  && movingStrip.shouldScroll
                                  && root.hasMedia
                                  && marqueeViewport.visible
                            loops: Animation.Infinite
                            onRunningChanged: movingStrip.reset()

                            PauseAnimation { duration: 2000 }
                            NumberAnimation {
                                target: movingStrip
                                property: "x"
                                from: 0
                                to: -marqueeViewport.delta
                                duration: Math.max(2500, marqueeViewport.textW * 18)
                                easing.type: Easing.Linear
                            }
                            PauseAnimation { duration: 1000 }
                            PropertyAction { target: movingStrip; property: "x"; value: 0 }
                        }

                        Item {
                            id: waveBand
                            parent: movingStrip
                            anchors.left: scrollingText.left
                            anchors.right: scrollingText.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 0
                            height: Math.min(18, Math.max(0, marqueeViewport.height - 2))
                            opacity: root.hasMedia ? 1 : 0
                            visible: root.hasMedia && root.fxWaves && marqueeViewport.visible
                            clip: true

                            WaveVisualizer {
                                anchors.fill: parent
                                live: root.isPlaying
                                points: root.visualizerPoints
                                maxVisualizerValue: 650
                                smoothing: 2
                                color: Appearance.m3colors.m3primary
                            }
                        }

                        onWidthChanged: movingStrip.reset()
                    }
                }
            }
        }
    }

    // 16) COMPONENTE: LyricLine
    component LyricLine: Item {
        id: lyricLineItem

        required property string text
        property bool highlight: false
        property bool useGradient: false
        property string gradientDirection: "top" 
        property real fillProgress: 0.0

        property int lineHeight: Math.max(12, Appearance.font.pixelSize.smallie + 4)
        property bool reallyUseGradient: useGradient && root.useGradientMask && root.fxLyricsGradientMask

        width: parent.width
        height: lineHeight

        TextMetrics {
            id: textMeasurer
            font.pixelSize: Appearance.font.pixelSize.smallie + (lyricLineItem.highlight ? 2 : 1)
            font.bold: lyricLineItem.highlight
            text: lyricLineItem.text
        }

        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, textMeasurer.width)
            height: textMeasurer.height

            StyledText {
                anchors.centerIn: parent
                text: lyricLineItem.text
                color: lyricLineItem.highlight ? root.islandTextSecondary : root.islandTextSecondary
                font: textMeasurer.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                visible: !lyricLineItem.reallyUseGradient
            }

            Item {
                anchors.fill: parent
                width: textMeasurer.width * lyricLineItem.fillProgress
                clip: true
                visible: lyricLineItem.highlight
                      && lyricLineItem.fillProgress > 0.01
                      && !lyricLineItem.reallyUseGradient

                StyledText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: lyricLineItem.text
                    color: root.islandTextPrimary
                    font: textMeasurer.font
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    width: textMeasurer.width

                    layer.enabled: root.fxDropShadows
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 1
                        radius: 6
                        samples: 16
                        color: root.islandTextShadowColor
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: lyricLineItem.reallyUseGradient
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: lyricLineItem.width
                    height: lyricLineItem.height
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: lyricLineItem.gradientDirection === "top" ? "transparent" : "black"
                        }
                        GradientStop {
                            position: 1.0
                            color: lyricLineItem.gradientDirection === "top" ? "black" : "transparent"
                        }
                    }
                }
            }

            StyledText {
                anchors.fill: parent
                text: lyricLineItem.text
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie + 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }
        }
    }
}
