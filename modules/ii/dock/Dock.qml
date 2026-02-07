import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import QtCore

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    // =========================================================================
    // 0) QUALITY + AUTO-HZ
    // =========================================================================
    property string qualityPreset: "auto"   // "auto" | "low" | "normal" | "high"
    property bool manualOverrides: false

    readonly property real detectedRefreshRateHz: {
        const w = Window.window
        const hz = (w && w.screen) ? w.screen.refreshRate : 0
        if (!hz || hz < 1) return 60
        return hz
    }
    readonly property bool highRefresh: detectedRefreshRateHz >= 90

    readonly property int revealAnimMs: highRefresh ? 190 : 240
    readonly property int waveformIntervalMs: highRefresh ? 22 : 33

    function _resolvedPreset() {
        if (qualityPreset === "auto") return highRefresh ? "high" : "normal"
        if (qualityPreset === "low") return "low"
        if (qualityPreset === "high") return "high"
        return "normal"
    }

    function applyQualityPreset() {
        if (manualOverrides) return

        const p = _resolvedPreset()
        if (p === "low") {
            premiumDock = true
            premiumDockGlass = false
            premiumDockGlow = false
            premiumWaveform = false

            animEnabled = true
            animMarquee = false
            animRevealTransitions = true
            animWaveform = false
        } else if (p === "high") {
            premiumDock = true
            premiumDockGlass = true
            premiumDockGlow = true
            premiumWaveform = true

            animEnabled = true
            animMarquee = true
            animRevealTransitions = true
            animWaveform = true
        } else { // normal
            premiumDock = true
            premiumDockGlass = true
            premiumDockGlow = true
            premiumWaveform = true

            animEnabled = true
            animMarquee = true
            animRevealTransitions = true
            animWaveform = true
        }
    }

    Component.onCompleted: {
        applyQualityPreset()
        initDockSettingsPersistence()
    }
    onQualityPresetChanged: applyQualityPreset()
    onManualOverridesChanged: applyQualityPreset()

    // =========================================================================
    // 1) PREMIUM SWITCHES + anim switches
    // =========================================================================
    property bool premiumDock: true
    property bool premiumDockGlass: true
    property bool premiumDockGlow: true
    property bool premiumWaveform: true

    property bool animEnabled: true
    property bool animMarquee: true
    property bool animRevealTransitions: true
    property bool animWaveform: true

    // =========================================================================
    // 2) ⚙️ CONFIGURACIÓN Y PERSISTENCIA (Settings diferido)
    // =========================================================================
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false

    Loader {
        id: dockSettingsLoader
        active: false
        sourceComponent: dockSettingsComponent
    }

    Component {
        id: dockSettingsComponent
        Settings {
            id: dockSettings
            category: "dock"
            property bool pinned: Config.options?.dock.pinnedOnStartup ?? false
            Component.onCompleted: root.pinned = pinned
            onPinnedChanged: root.pinned = pinned
        }
    }

    function initDockSettingsPersistence() {
        try {
            if (!Qt.application.organizationName || Qt.application.organizationName.length === 0)
                Qt.application.organizationName = "quickshell"
            if (!Qt.application.organizationDomain || Qt.application.organizationDomain.length === 0)
                Qt.application.organizationDomain = "local"
        } catch (e) { /* silent */ }

        const hasOrg = (Qt.application.organizationName && Qt.application.organizationName.length > 0)
        const hasDomain = (Qt.application.organizationDomain && Qt.application.organizationDomain.length > 0)
        dockSettingsLoader.active = hasOrg && hasDomain
    }

    onPinnedChanged: {
        if (dockSettingsLoader.item) dockSettingsLoader.item.pinned = pinned
    }

    // =========================================================================
    // 3) 📏 CONSTANTES DE DISEÑO
    // =========================================================================
    readonly property int kDockPadding: 5
    readonly property int kDockSpacing: 3
    readonly property int kPinButtonSize: 35

    readonly property int kMediaTopMargin: 20
    readonly property int kMediaLeftMargin: 5
    readonly property int kMediaExtraWidth: 28

    readonly property int kAlbumSize: 40
    readonly property int kAlbumRadius: 8

    readonly property int kInfoWidth: 260
    readonly property int kArtistLineHeight: 14
    readonly property int kTitleLineHeight: 16
    readonly property int kFadeWidth: 25

    readonly property real kVolumeStep: 0.04

    // =========================================================================
    // 4) 🎵 MediaPlayerWidget
    // =========================================================================
    component MediaPlayerWidget: Item {
        id: media

        Layout.fillHeight: true
        Layout.topMargin: root.kMediaTopMargin
        Layout.leftMargin: root.kMediaLeftMargin
        Layout.bottomMargin: Appearance.sizes.hyprlandGapsOut + (dockRow?.padding ?? 0)

        property var activePlayer: MprisController.activePlayer

        property string trackTitle: activePlayer?.trackTitle ?? ""
        property string trackArtist: activePlayer?.trackArtist ?? "Unknown Artist"
        property string artUrl: activePlayer?.trackArtUrl ?? ""
        property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

        readonly property bool canSeek: (activePlayer?.canSeek ?? false) && (activePlayer?.length ?? 0) > 0
        readonly property bool canGoNext: activePlayer?.canGoNext ?? true
        readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? true

        readonly property real trackLen: Math.max(0, activePlayer?.length ?? 0)
        readonly property real trackPos: Math.max(0, activePlayer?.position ?? 0)
        readonly property real ratio: (trackLen > 0) ? Math.max(0, Math.min(1, trackPos / trackLen)) : 0

        function friendlyTime(sec) {
            sec = Math.max(0, Math.floor(sec || 0))
            const m = Math.floor(sec / 60)
            const s = sec % 60
            return m + ":" + (s < 10 ? "0" + s : s)
        }
        function clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }

        function setVolumeDelta(dir) {
            if (!media.activePlayer) return
            // Algunos players NO exponen volume por MPRIS: en ese caso no hay manera aquí.
            if (media.activePlayer.volume === undefined) return

            let v = media.activePlayer.volume + dir * root.kVolumeStep
            v = Math.max(0.0, Math.min(1.0, v))
            media.activePlayer.volume = v
        }

        visible: activePlayer !== null && trackTitle !== ""
        implicitWidth: visible ? (mediaRow.implicitWidth + root.kMediaExtraWidth) : 0
        implicitHeight: parent?.height ?? 0

        Timer {
            interval: Config.options.resources.updateInterval
            repeat: true
            running: root.animEnabled && media.visible && media.isPlaying
            onTriggered: if (media.activePlayer) media.activePlayer.positionChanged()
        }

        Connections {
            target: media.activePlayer
            enabled: media.activePlayer !== null
            function onTrackArtUrlChanged() {
                albumArtImage.source = ""
                albumArtImage.source = media.artUrl !== ""
                    ? media.artUrl
                    : Qt.resolvedUrl("../../assets/icons/cover.png")
            }
            function onTrackTitleChanged() { titleMarquee.resetMarquee() }
        }

        Rectangle {
            id: mediaBg
            anchors.fill: parent
            radius: Appearance.rounding.normal

            // ✅ sin overlay/círculo al hover
            HoverHandler { id: hoverH }
            color: "transparent"

            // ✅ sin tooltip
            ToolTip.visible: false

            // ✅ Volumen con rueda (MUY compatible): MouseArea.onWheel
            // Importante: acceptedButtons = Qt.NoButton para no romper clicks.
            MouseArea {
                id: wheelArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                propagateComposedEvents: true

                onWheel: (wheel) => {
                    if (!media.visible) return
                    const dir = wheel.angleDelta.y > 0 ? 1 : -1
                    media.setVolumeDelta(dir)
                    wheel.accepted = true
                }
            }

            RowLayout {
                id: mediaRow
                // ✅ SUBE un poquito TODO el bloque del reproductor (controles incluidos)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3

                spacing: 10
                z: 2

                // Album
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    width: root.kAlbumSize
                    height: root.kAlbumSize

                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        source: media.artUrl !== ""
                                ? media.artUrl
                                : Qt.resolvedUrl("../../assets/icons/cover.png")
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        smooth: true

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: root.kAlbumSize
                                height: root.kAlbumSize
                                radius: root.kAlbumRadius
                            }
                        }

                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { enabled: root.animEnabled; NumberAnimation { duration: 250 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.colLayer1
                        radius: root.kAlbumRadius
                        visible: albumArtImage.status !== Image.Ready

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "music_note"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                            opacity: 0.5
                        }
                    }
                }

                // Text + controls
                Column {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.kInfoWidth
                    spacing: 2

                    Item {
                        width: parent.width
                        height: root.kArtistLineHeight
                        clip: true

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            color: Appearance.colors.colSubtext
                            text: media.trackArtist
                            font.pixelSize: 11
                        }
                    }

                    Item {
                        id: titleMarquee
                        width: parent.width
                        height: root.kTitleLineHeight
                        clip: true

                        property bool shouldScroll: titleText.contentWidth > width - 10
                        function resetMarquee() { titleText.x = 0 }

                        onWidthChanged: resetMarquee()
                        onShouldScrollChanged: if (!shouldScroll) resetMarquee()

                        StyledText {
                            id: titleText
                            anchors.verticalCenter: parent.verticalCenter

                            // ✅ más visible
                            color: "white"
                            opacity: 1.0

                            text: media.trackTitle !== "" ? media.trackTitle : "No Title"
                            font.weight: Font.Medium
                            font.pixelSize: 14

                            SequentialAnimation on x {
                                running: root.animEnabled && root.animMarquee && titleMarquee.shouldScroll && media.visible
                                loops: Animation.Infinite
                                onRunningChanged: titleMarquee.resetMarquee()

                                PauseAnimation { duration: 1500 }
                                NumberAnimation {
                                    to: titleMarquee.width - titleText.contentWidth - 5
                                    duration: Math.max(3000, titleText.contentWidth * 50)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation { duration: 800 }
                                NumberAnimation { to: 0; duration: 600; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: root.kFadeWidth
                            visible: titleMarquee.shouldScroll
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Appearance.colors.colLayer0 }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: root.kFadeWidth
                            visible: titleMarquee.shouldScroll
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Appearance.colors.colLayer0 }
                            }
                        }
                    }

                    // Controls row
                    Item {
                        width: parent.width
                        height: 26

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: 13
                                color: Qt.rgba(1, 1, 1, 0.90)
                                opacity: 1.0
                                text: media.friendlyTime(media.trackPos) + " / " + media.friendlyTime(media.trackLen)
                            }

                            // Prev
                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 28; height: 28
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_previous"
                                    iconSize: 24
                                    color: Appearance.colors.colOnLayer1
                                    opacity: (media.activePlayer && media.canGoPrevious) ? 1.0 : 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!media.activePlayer && media.canGoPrevious
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: media.activePlayer.previous()
                                }
                            }

                            // Play/Pause
                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 28; height: 28
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: media.isPlaying ? "pause" : "play_arrow"
                                    iconSize: 24
                                    color: Appearance.colors.colOnLayer1
                                    opacity: media.activePlayer ? 1.0 : 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!media.activePlayer
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: media.activePlayer.togglePlaying()
                                }
                            }

                            // miniBar: onda + “sonido” (más visible)
                            Item {
                                id: miniBar
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 16

                                // Ajustes del efecto (más fuerte/visible)
                                property real phase: 0.0
                                property real waveAmpMin: 0.35
                                property real waveAmpMax: 5.2
                                property real waveRampPow: 1.8
                                property real wavePxPerCycle: 20.0
                                property real waveSpeed: 1.35
                                property real playheadHeightPad: 4

                                // “sonido” tipo barras (más visible)
                                property bool audioBarsEnabled: true
                                property real barsStepPx: 2
                                property real barsMaxHalfHeight: 4

                                function seekToRatio(r) {
                                    if (!media.activePlayer || !media.canSeek || media.trackLen <= 0) return
                                    r = media.clamp(r, 0, 1)
                                    media.activePlayer.position = r * media.trackLen
                                }

                                NumberAnimation on phase {
                                    from: 0
                                    to: Math.PI * 2
                                    duration: Math.max(160, 1050 / Math.max(0.01, miniBar.waveSpeed))
                                    loops: Animation.Infinite
                                    running: root.animEnabled && media.visible && media.isPlaying
                                }

                                onPhaseChanged: barCanvas.requestPaint()

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
                                    id: barCanvas
                                    anchors.fill: parent
                                    antialiasing: true

                                    Connections {
                                        target: media.activePlayer
                                        enabled: media.activePlayer !== null
                                        function onPositionChanged() { barCanvas.requestPaint() }
                                        function onLengthChanged() { barCanvas.requestPaint() }
                                    }

                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset?.()
                                        ctx.clearRect(0, 0, width, height)
                                        if (media.trackLen <= 0) return

                                        const xPlay = media.clamp(track.width * media.ratio, 0, track.width)
                                        const yMid = track.y + track.height / 2

                                        // 0) “Audio bars” dentro del progreso (0..xPlay)
                                        if (miniBar.audioBarsEnabled && media.isPlaying && xPlay > 2) {
                                            ctx.save()
                                            ctx.fillStyle = Qt.rgba(
                                                Appearance.m3colors.m3primary.r,
                                                Appearance.m3colors.m3primary.g,
                                                Appearance.m3colors.m3primary.b,
                                                0.38
                                            )

                                            const step = Math.max(4, miniBar.barsStepPx)
                                            for (let x = 0; x <= xPlay; x += step) {
                                                const t = xPlay > 0 ? (x / xPlay) : 0
                                                const ramp = Math.pow(t, 1.55)

                                                // pseudo-amplitud agradable (más “musical”)
                                                const e =
                                                    0.55
                                                    + 0.45 * Math.sin((x / 10.0) + miniBar.phase * 2.6)
                                                const hh = miniBar.barsMaxHalfHeight * ramp * Math.max(0.18, e)

                                                ctx.fillRect(x, yMid - hh, 2.2, hh * 2.0)
                                            }
                                            ctx.restore()
                                        }

                                        // 1) Onda integrada dentro del progreso (de 0 a xPlay)
                                        if (xPlay > 1) {
                                            ctx.save()

                                            ctx.strokeStyle = Qt.rgba(
                                                Appearance.m3colors.m3primary.r,
                                                Appearance.m3colors.m3primary.g,
                                                Appearance.m3colors.m3primary.b,
                                                0.98
                                            )
                                            ctx.lineWidth = 3.4
                                            ctx.lineCap = "round"
                                            ctx.lineJoin = "round"

                                            ctx.shadowColor = "rgba(0,0,0,0.22)"
                                            ctx.shadowBlur = 5
                                            ctx.shadowOffsetX = 0
                                            ctx.shadowOffsetY = 0

                                            ctx.beginPath()

                                            const step = 1.0
                                            for (let x = 0; x <= xPlay; x += step) {
                                                const t = xPlay > 0 ? (x / xPlay) : 0
                                                const ramp = Math.pow(t, miniBar.waveRampPow)
                                                const amp = miniBar.waveAmpMin + (miniBar.waveAmpMax - miniBar.waveAmpMin) * ramp

                                                const ang = (x / miniBar.wavePxPerCycle) * (Math.PI * 2) + miniBar.phase
                                                const y = yMid + Math.sin(ang) * amp

                                                if (x === 0) ctx.moveTo(x, y)
                                                else ctx.lineTo(x, y)
                                            }

                                            ctx.stroke()
                                            ctx.restore()
                                        }

                                        // 2) Playhead fino
                                        ctx.save()
                                        ctx.strokeStyle = "rgba(245,245,245,0.95)"
                                        ctx.lineWidth = 2.0
                                        ctx.shadowColor = "rgba(0,0,0,0.40)"
                                        ctx.shadowBlur = 6
                                        ctx.beginPath()
                                        ctx.moveTo(xPlay + 0.5, track.y - miniBar.playheadHeightPad)
                                        ctx.lineTo(xPlay + 0.5, track.y + track.height + miniBar.playheadHeightPad)
                                        ctx.stroke()
                                        ctx.restore()
                                    }
                                }

                                // Seek arrastrando con mouse
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: media.canSeek
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true

                                    function _seekAt(x) { miniBar.seekToRatio(x / miniBar.width) }
                                    onPressed: (mouse) => _seekAt(mouse.x)
                                    onPositionChanged: (mouse) => { if (pressed) _seekAt(mouse.x) }
                                }

                                TapHandler {
                                    enabled: media.canSeek
                                    onTapped: (ev) => miniBar.seekToRatio(ev.position.x / miniBar.width)
                                }

                                DragHandler {
                                    enabled: media.canSeek
                                    onTranslationChanged: {
                                        const p = centroid.position
                                        miniBar.seekToRatio(p.x / miniBar.width)
                                    }
                                }
                            }

                            // Next
                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 28; height: 28
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    iconSize: 24
                                    color: Appearance.colors.colOnLayer1
                                    opacity: (media.activePlayer && media.canGoNext) ? 1.0 : 0.35
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!media.activePlayer && media.canGoNext
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: media.activePlayer.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 5) 🖥️ PANEL PRINCIPAL
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            required property var modelData
            screen: modelData

            visible: !GlobalStates.screenLocked
            color: "transparent"
            WlrLayershell.namespace: "quickshell:dock"

            property bool reveal: root.pinned
                                  || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse)
                                  || dockApps.requestDockShow
                                  || (!ToplevelManager.activeToplevel?.activated)

            anchors { bottom: true; left: true; right: true }

            exclusiveZone: root.pinned
                ? implicitHeight - Appearance.sizes.hyprlandGapsOut
                  - (Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut)
                : 0

            implicitHeight: (Config.options?.dock.height ?? 70)
                            + Appearance.sizes.elevationMargin
                            + Appearance.sizes.hyprlandGapsOut

            implicitWidth: dockBackground.implicitWidth
            mask: Region { item: dockMouseArea }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                hoverEnabled: true
                implicitWidth: dockHoverRegion.implicitWidth + Appearance.sizes.elevationMargin * 2

                // ✅ FIX: no robar clicks a los widgets internos
                acceptedButtons: Qt.NoButton

                anchors {
                    top: parent.top
                    topMargin: topMarginForState()
                    horizontalCenter: parent.horizontalCenter
                }

                function topMarginForState() {
                    if (dockRoot.reveal) return 0
                    if (Config.options?.dock.hoverToReveal) {
                        return dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight
                    }
                    return dockRoot.implicitHeight + 1
                }

                Behavior on anchors.topMargin {
                    enabled: root.animEnabled && root.animRevealTransitions
                    NumberAnimation { duration: root.revealAnimMs; easing.type: Easing.OutCubic }
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth

                    Item {
                        id: dockBackground
                        anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        implicitWidth: dockRow.implicitWidth + root.kDockPadding * 2
                        height: parent.height - Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

                        StyledRectangularShadow { target: dockVisualBackground }

                        Rectangle {
                            id: dockVisualBackground
                            anchors {
                                fill: parent
                                topMargin: Appearance.sizes.elevationMargin
                                bottomMargin: Appearance.sizes.hyprlandGapsOut
                            }

                            color: Appearance.colors.colLayer0
                            radius: Appearance.rounding.large
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border

                            layer.enabled: root.premiumDock && root.premiumDockGlow
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 0.7
                                shadowOpacity: dockRoot.reveal ? 0.22 : 0.12
                                shadowColor: Appearance.colors.colPrimary
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                visible: root.premiumDock && root.premiumDockGlass
                                opacity: dockRoot.reveal ? 0.22 : 0.14
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.18) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }

                        RowLayout {
                            id: dockRow
                            anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            spacing: root.kDockSpacing
                            property real padding: root.kDockPadding

                            VerticalButtonGroup {
                                Layout.topMargin: Appearance.sizes.hyprlandGapsOut

                                GroupButton {
                                    baseWidth: root.kPinButtonSize
                                    baseHeight: root.kPinButtonSize
                                    clickedWidth: baseWidth
                                    clickedHeight: baseHeight + 20
                                    buttonRadius: Appearance.rounding.normal
                                    toggled: root.pinned
                                    onClicked: root.pinned = !root.pinned

                                    contentItem: MaterialSymbol {
                                        text: "keep"
                                        horizontalAlignment: Text.AlignHCenter
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                                    }
                                }
                            }

                            DockSeparator {}

                            DockApps {
                                id: dockApps
                                buttonPadding: dockRow.padding
                            }

                            DockSeparator {}

                            MediaPlayerWidget { id: mediaPlayerItem }

                            DockSeparator { visible: mediaPlayerItem.visible }

                            DockButton {
                                Layout.fillHeight: true
                                topInset: Appearance.sizes.hyprlandGapsOut + dockRow.padding
                                bottomInset: Appearance.sizes.hyprlandGapsOut + dockRow.padding

                                onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen

                                ToolTip.visible: hovered ?? false
                                ToolTip.delay: 450
                                ToolTip.text: GlobalStates.overviewOpen ? "Cerrar overview" : "Abrir overview"

                                contentItem: MaterialSymbol {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: parent.width / 2
                                    text: "apps"
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

