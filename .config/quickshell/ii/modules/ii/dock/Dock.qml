import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtCore

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.ui 1.0
import qs.services

import "../bar" as Bar

Scope {
    id: root

    property int dockHeightNudge: 4

    property string qualityPreset: "auto"
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

    readonly property bool barIsBottom: (Config.options?.bar?.bottom ?? false)
    readonly property bool dockAtTop: barIsBottom
    readonly property string dockEdge: dockAtTop ? "top" : "bottom"

    // Estética / cristal (dock)
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode !== undefined)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    readonly property color dockMarqueeFadeBg: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        themeIsDark ? 0.22 : 0.14
    )

    readonly property color dockDividerCol: themeIsDark
        ? Qt.rgba(1, 1, 1, 0.14)
        : Qt.rgba(0, 0, 0, 0.14)

    readonly property int dockInnerPadX: 10

    readonly property bool dockUseScreenCaptureBlur: true
    readonly property int dockCaptureIntervalMs: 120
    readonly property string dockCapturePath: "/tmp/quickshell_dock_backdrop.png"

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
        } else {
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

    property bool premiumDock: true
    property bool premiumDockGlass: true
    property bool premiumDockGlow: true
    property bool premiumWaveform: true

    property bool animEnabled: true
    property bool animMarquee: true
    property bool animRevealTransitions: true
    property bool animWaveform: true

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _styleFromUIState() {
        const s = typeof UIState !== "undefined" && UIState ? UIState.surfaceStyle : ""
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

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
        } catch (e) {}

        const hasOrg = (Qt.application.organizationName && Qt.application.organizationName.length > 0)
        const hasDomain = (Qt.application.organizationDomain && Qt.application.organizationDomain.length > 0)
        dockSettingsLoader.active = hasOrg && hasDomain
    }

    onPinnedChanged: {
        if (dockSettingsLoader.item) dockSettingsLoader.item.pinned = pinned
    }

    readonly property int kDockPadding: 5
    readonly property int kDockSpacing: 3
    readonly property int kPinButtonSize: 35

    // Más compacto
    readonly property int kMediaTopMargin: 5
    readonly property int kMediaLeftMargin: 6
    readonly property int kMediaExtraWidth: 6

    readonly property int kAlbumSize: 40
    readonly property int kAlbumRadius: 8

    // base de info menor
    readonly property int kInfoWidth: 210
    readonly property int kArtistLineHeight: 14
    readonly property int kTitleLineHeight: 16
    readonly property int kFadeWidth: 18

    readonly property real kVolumeStep: 0.04

    component DockConditionalSeparator: Rectangle {
        property bool show: false
        visible: show
        width: 1
        Layout.fillHeight: true
        Layout.topMargin: dockRow.padding + 6
        Layout.bottomMargin: dockRow.padding + 6
        radius: 1
        color: root.dockDividerCol
        opacity: 0.9
        antialiasing: true
    }

    component MediaPlayerWidget: Item {
        id: media

        Layout.fillHeight: true
        Layout.topMargin: root.kMediaTopMargin
        Layout.leftMargin: root.kMediaLeftMargin
        Layout.bottomMargin: 0

        readonly property int kBtn: 28
        readonly property int kGap: 6
        readonly property int kTimeW: 110

        readonly property int minControlsW: kTimeW + (kBtn * 3) + (kGap * 4)

        readonly property int maxColumnW: 200
        readonly property int minColumnW: 190

        property var activePlayer: MprisController.activePlayer

        property string trackTitle: activePlayer?.trackTitle ?? ""
        property string trackArtist: activePlayer?.trackArtist ?? ""
        property string artUrl: activePlayer?.trackArtUrl ?? ""
        property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

        readonly property bool canGoNext: activePlayer?.canGoNext ?? true
        readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? true

        readonly property bool compactHeight: height < 58

        readonly property string safeTitle: (trackTitle && trackTitle.length > 0) ? trackTitle : "No Title"
        readonly property string safeArtist: (trackArtist && trackArtist.length > 0) ? trackArtist : "Unknown Artist"

        function friendlyTime(sec) {
            sec = Math.max(0, Math.floor(sec || 0))
            const m = Math.floor(sec / 60)
            const s = sec % 60
            return m + ":" + (s < 10 ? "0" + s : s)
        }

        function setVolumeDelta(dir) {
            if (!media.activePlayer) return
            if (media.activePlayer.volume === undefined) return
            let v = media.activePlayer.volume + dir * root.kVolumeStep
            v = Math.max(0.0, Math.min(1.0, v))
            media.activePlayer.volume = v
        }

        visible: activePlayer !== null

        TextMetrics { id: titleMetrics; text: media.safeTitle; font: titleText.font }
        TextMetrics { id: artistMetrics; text: media.safeArtist; font: artistText.font }

        readonly property int computedTitleW: Math.ceil(Math.min(maxColumnW, Math.max(minColumnW, titleMetrics.width + 6)))
        readonly property int computedArtistW: Math.ceil(Math.min(maxColumnW, Math.max(minColumnW, artistMetrics.width + 6)))

        readonly property int columnW: Math.min(
            maxColumnW,
            Math.max(minControlsW, Math.max(root.kInfoWidth, computedTitleW, computedArtistW))
        )

        readonly property int desiredW: root.kAlbumSize + 10 + columnW + root.kMediaExtraWidth

        width: visible ? desiredW : 0
        height: parent ? parent.height : 0
        clip: true

        Layout.preferredWidth: visible ? desiredW : 0
        Layout.minimumWidth: visible ? desiredW : 0
        Layout.maximumWidth: visible ? desiredW : 0

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
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: "transparent"
            clip: true

            MouseArea {
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
                anchors.fill: parent
                spacing: 10

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

                Column {
                    Layout.alignment: Qt.AlignVCenter
                    width: media.columnW
                    spacing: 2

                    Item {
                        id: titleMarquee
                        width: parent.width
                        height: root.kTitleLineHeight
                        clip: true

                        HoverHandler { id: titleHover }
                        readonly property bool hovered: titleHover.hovered
                        readonly property bool shouldScroll: titleMetrics.width > width - 10

                        function resetMarquee() { titleText.x = 0 }
                        onWidthChanged: resetMarquee()
                        onHoveredChanged: resetMarquee()
                        onShouldScrollChanged: if (!shouldScroll) resetMarquee()

                        StyledText {
                            id: titleText
                            anchors.verticalCenter: parent.verticalCenter
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.98
                            text: media.safeTitle
                            font.weight: Font.Medium
                            font.pixelSize: 14

                            elide: (!root.animEnabled || !root.animMarquee || !titleMarquee.hovered)
                                   ? Text.ElideRight
                                   : Text.ElideNone

                            SequentialAnimation on x {
                                running: root.animEnabled
                                         && root.animMarquee
                                         && media.visible
                                         && titleMarquee.hovered
                                         && titleMarquee.shouldScroll
                                loops: Animation.Infinite
                                onRunningChanged: titleMarquee.resetMarquee()

                                PauseAnimation { duration: 450 }
                                NumberAnimation {
                                    to: titleMarquee.width - titleMetrics.width - 6
                                    duration: Math.max(2100, titleMetrics.width * 32)
                                    easing.type: Easing.Linear
                                }
                                PauseAnimation { duration: 420 }
                                NumberAnimation { to: 0; duration: 420; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: root.kArtistLineHeight
                        visible: !media.compactHeight
                        clip: true

                        StyledText {
                            id: artistText
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            color: Appearance.colors.colSubtext
                            text: media.safeArtist
                            font.pixelSize: 11
                        }
                    }

                    Item {
                        width: parent.width
                        height: 26

                        RowLayout {
                            anchors.fill: parent
                            spacing: media.kGap

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: 12
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.92
                                text: media.friendlyTime(media.activePlayer?.position ?? 0)
                                      + " / "
                                      + media.friendlyTime(media.activePlayer?.length ?? 0)
                                elide: Text.ElideRight
                                Layout.preferredWidth: media.kTimeW
                            }

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: media.kBtn
                                height: media.kBtn

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_previous"
                                    iconSize: 23
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

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: media.kBtn
                                height: media.kBtn

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: media.isPlaying ? "pause" : "play_arrow"
                                    iconSize: 23
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

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: media.kBtn
                                height: media.kBtn

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    iconSize: 23
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            required property var modelData
            screen: modelData

            visible: !GlobalStates.screenLocked
            color: "transparent"
            WlrLayershell.namespace: "quickshell:dock"

           property bool hasActiveWindows: false

            function resolveMonitorForThisDock() {
                if (!HyprlandData) return null
                const scrName = dockRoot.screen?.name
                if (scrName) {
                    const byName = HyprlandData.monitors.find(m => m.name === scrName)
                    if (byName) return byName
                }
                return null
            }

            function recomputeHasWindows() {
                if (!HyprlandData) {
                    dockRoot.hasActiveWindows = false
                    return
                }
                const monitor = resolveMonitorForThisDock()
                const wsId = monitor?.activeWorkspace?.id ?? null
                if (!wsId) {
                    dockRoot.hasActiveWindows = false
                    return
                }
                dockRoot.hasActiveWindows = HyprlandData.windowList.some(w =>
                    (w.workspace?.id === wsId) && !w.floating
                )
            }

            Timer {
                id: hyprRecomputeTimerDock
                interval: 60
                repeat: false
                onTriggered: dockRoot.recomputeHasWindows()
            }

            Connections {
                target: HyprlandData
                enabled: root.resolvedStyle === "adaptive"
                function schedule() { hyprRecomputeTimerDock.restart() }
                function onWindowListChanged() { schedule() }
                function onMonitorsChanged() { schedule() }
            }

            onScreenChanged: if (root.resolvedStyle === "adaptive") hyprRecomputeTimerDock.restart()

            // Resuelve adaptive (solid/glass) por monitor
            readonly property string styleAfterAdaptive: {
                if (root.resolvedStyle === "adaptive")
                    return dockRoot.hasActiveWindows ? "solid" : "glass"
                return root.resolvedStyle
            }

            //  Regla final para el dock:
            //    - crystal => crystal
            readonly property string effectiveStyle: (styleAfterAdaptive === "crystal") ? "crystal" : "solid"

            readonly property bool effIsSolid: effectiveStyle === "solid"
            readonly property bool effIsCrystal: effectiveStyle === "crystal"

            property bool reveal: root.pinned
                                  || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse)
                                  || dockApps.requestDockShow
                                  || (!ToplevelManager.activeToplevel?.activated)

                    anchors {
                top: root.dockAtTop
                bottom: !root.dockAtTop
                left: true
                right: true
            }

            exclusiveZone: root.pinned
                ? implicitHeight - Appearance.sizes.hyprlandGapsOut
                  - (Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut)
                : 0

            implicitHeight: (Config.options?.dock.height ?? 70)
                            + root.dockHeightNudge
                            + Appearance.sizes.elevationMargin
                            + Appearance.sizes.hyprlandGapsOut

            mask: Region { item: dockMouseArea }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                anchors {
                    top: parent.top
                    topMargin: topMarginForState()
                    horizontalCenter: parent.horizontalCenter
                }

                width: dockHoverRegion.width + Appearance.sizes.elevationMargin * 2

                function topMarginForState() {
                 if (dockRoot.reveal) return 0

                      if (Config.options?.dock.hoverToReveal) {
                        if (!root.dockAtTop)
                            return dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight
                        return -(dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight)
                    }

                    if (!root.dockAtTop)
                        return dockRoot.implicitHeight + 1
                    return -(dockRoot.implicitHeight + 1)
                }

                Behavior on anchors.topMargin {
                    enabled: root.animEnabled && root.animRevealTransitions
                    NumberAnimation { duration: root.revealAnimMs; easing.type: Easing.OutCubic }
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    width: dockBackground.width

                    Item {
                        id: dockBackground
                        anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }

                        width: dockRow.implicitWidth + root.kDockPadding * 2 + root.dockInnerPadX * 2
                        height: parent.height - Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut

                        Item {
                            id: dockVisualBackground
                            anchors {
                                fill: parent
                                topMargin: Appearance.sizes.elevationMargin
                                bottomMargin: Appearance.sizes.hyprlandGapsOut
                            }

                            property int cornerStyle: 1
                            property int radiusPx: Appearance.rounding.large
                            readonly property int cancelOuterMargin: Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))

                            Rectangle {
                                id: dockShadowShape
                                anchors.fill: parent
                                radius: dockVisualBackground.radiusPx
                                color: "transparent"
                                antialiasing: true
                            }

                            StyledRectangularShadow { target: dockShadowShape }

                            Loader {
                                id: bgLoader
                                anchors.fill: parent
                                sourceComponent: dockRoot.effIsCrystal ? crystalBgComponent : solidBgComponent
                            }

                            Component {
                                id: solidBgComponent
                                Item {
                                    anchors.fill: parent

                                    Rectangle {
                                        id: solidBase
                                        anchors.fill: parent
                                        anchors.margins: 0
                                        radius: dockVisualBackground.radiusPx
                                        antialiasing: true
                                        color: Appearance.colors.colLayer0
                                        border.width: 1
                                        border.color: Appearance.colors.colLayer0Border
                                    }

                                    Rectangle {
                                        anchors.fill: solidBase
                                        radius: solidBase.radius
                                        visible: root.premiumDock && root.premiumDockGlass
                                        opacity: dockRoot.reveal ? 0.22 : 0.14
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.18) }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }

                                    layer.enabled: root.premiumDock && root.premiumDockGlow
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowBlur: 0.7
                                        shadowOpacity: dockRoot.reveal ? 0.22 : 0.12
                                        shadowColor: Appearance.colors.colPrimary
                                        shadowHorizontalOffset: 0
                                        shadowVerticalOffset: 0
                                    }
                                }
                            }

                            Component {
                                id: crystalBgComponent
                                Item {
                                    anchors.fill: parent

                                    Bar.BarBgOverlayGlassBlur {
                                        anchors.fill: parent
                                        anchors.margins: -dockVisualBackground.cancelOuterMargin

                                      position: root.dockEdge
                                        cornerStyle: dockVisualBackground.cornerStyle

                                        useGlassMode: root.premiumDock && root.premiumDockGlass
                                        showSolidBackground: false
                                        backgroundColor: Appearance.colors.colLayer0

                                        enableRealBlur: true
                                        useScreenCaptureBlur: root.dockUseScreenCaptureBlur
                                        captureIntervalMs: root.dockCaptureIntervalMs
                                        captureOutputPath: root.dockCapturePath

                                        tintOpacity: root.themeIsDark ? 0.18 : 0.14
                                        blurRadius: 56
                                        blurSaturation: root.themeIsDark ? 1.55 : 1.65
                                        blurContrast: 1.08
                                        blurBrightness: root.themeIsDark ? 1.12 : 1.10

                                        basePadding: 0
                                        enableMask: true
                                        content: [ Item { } ]
                                    }

                                    Bar.BarBgCrystalOverlay {
                                        anchors.fill: parent
                                        anchors.margins: -dockVisualBackground.cancelOuterMargin

                                        // === AJUSTE: idem para el cristal ===
                                        position: root.dockEdge
                                        cornerStyle: dockVisualBackground.cornerStyle
                                        useGlassMode: true
                                        showSolidBackground: false
                                        backgroundColor: "transparent"
                                        overlayStrength: Appearance.colors.isDark ? 1.0 : 0.95
                                        visible: true
                                    }

                                    layer.enabled: root.premiumDock && root.premiumDockGlow
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowBlur: 0.7
                                        shadowOpacity: dockRoot.reveal ? 0.22 : 0.12
                                        shadowColor: Appearance.colors.colPrimary
                                        shadowHorizontalOffset: 0
                                        shadowVerticalOffset: 0
                                    }
                                }
                            }
                        }

                        RowLayout {
                            id: dockRow
                            anchors.fill: dockVisualBackground
                            spacing: root.kDockSpacing
                            property real padding: root.kDockPadding

                            Item { width: root.dockInnerPadX; height: 1 }

                            VerticalButtonGroup {
                                Layout.topMargin: 0

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

                            DockConditionalSeparator { show: true }

                            DockApps {
                                id: dockApps
                                buttonPadding: dockRow.padding
                            }

                            DockConditionalSeparator { show: mediaPlayerItem.visible }

                            MediaPlayerWidget { id: mediaPlayerItem }

                            DockConditionalSeparator { show: mediaPlayerItem.visible }

                            DockButton {
                                Layout.fillHeight: true
                                topInset: dockRow.padding
                                bottomInset: dockRow.padding

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

                            Item { width: root.dockInnerPadX; height: 1 }
                        }
                    }
                }
            }

            Component.onCompleted: {
                if (root.resolvedStyle === "adaptive") hyprRecomputeTimerDock.restart()
                else dockRoot.recomputeHasWindows()
            }
        }
    }
}

