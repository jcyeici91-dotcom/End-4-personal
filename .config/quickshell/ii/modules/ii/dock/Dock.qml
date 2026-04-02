pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
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
import qs.services

import "../bar" as Bar

Scope {
    id: root

    property int dockHeightNudge: 4

    // Limpiamos lo de auto/high refresh como pediste
    property bool manualOverrides: false

    readonly property int revealAnimMs: 240
    readonly property int waveformIntervalMs: 33

    readonly property bool barIsBottom: (Config.options?.bar?.bottom ?? false)
    readonly property bool dockAtTop: barIsBottom
    readonly property string dockEdge: dockAtTop ? "top" : "bottom"

    // --- LÓGICA DE UNIÓN / FLOTACIÓN ESTANDARIZADA CORREGIDA ---
    readonly property bool isFloatOrHybrid: {
        // 1. Si el estilo de fondo es "Crystal" (3), siempre flota y se separa.
        if (Config.options?.bar?.barBackgroundStyle === 3) return true;
        
        // 2. CORRECCIÓN PRINCIPAL: Si estás usando "Float" (1) pero con fondo "Transparente" (0)
        // o en un modo "Hybrid", forzamos a que el dock SE UNA al borde (false)
        // para que dibuje las curvas hacia afuera como en la imagen.
        if (Config.options?.bar?.cornerStyle === 1 && Config.options?.bar?.barBackgroundStyle === 0) return false;
        
        // 3. Si está explícitamente en "Hug" (0) o "Hybrid" (2), siempre se une al borde.
        if (Config.options?.bar?.cornerStyle === 0 || Config.options?.bar?.cornerStyle === 2) return false;
        
        // 4. Solo permitimos que flote si es estrictamente "Float" (1) y "Sólido" (1).
        if (Config.options?.bar?.cornerStyle === 1 && Config.options?.bar?.barBackgroundStyle === 1) return true;
        
        // Por defecto, se une a los bordes para garantizar las curvas (Hug)
        return false;
    }
    
    readonly property int floatingGap: 12

    // Estética básica
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

    property bool premiumDock: true
    property bool premiumDockGlow: true
    property bool premiumWaveform: true

    // 👇 CONECTADO AL INTERRUPTOR MAESTRO 👇
    property bool animEnabled: Config.options.appearance.enableAnimations
    property bool animMarquee: true
    property bool animRevealTransitions: true
    property bool animWaveform: true

    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        return "solid" 
    }

    property bool pinned: Config.options?.dock?.pinnedOnStartup ?? false

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
            property bool pinned: Config.options?.dock?.pinnedOnStartup ?? false
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

    Component.onCompleted: {
        initDockSettingsPersistence()
    }

    onPinnedChanged: {
        if (dockSettingsLoader.item) dockSettingsLoader.item.pinned = pinned
    }

    readonly property int kDockPadding: 5
    readonly property int kDockSpacing: 3
    readonly property int kPinButtonSize: 35

    readonly property int kMediaTopMargin: 5
    readonly property int kMediaLeftMargin: 6
    readonly property int kMediaExtraWidth: 6

    readonly property int kAlbumSize: 40
    readonly property int kAlbumRadius: 8

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
            interval: Config.options?.resources?.updateInterval ?? 1000
            repeat: true
            running: root.animEnabled && media.visible && media.isPlaying // Detiene las actualizaciones de progreso si no hay animaciones
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
            WlrLayershell.layer: WlrLayer.Overlay // Asegura que se vea por encima de las ventanas

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

            property bool reveal: root.pinned
                                  || (Config.options?.dock?.hoverToReveal && dockMouseArea.containsMouse)
                                  || dockApps.requestDockShow
                                  || (!ToplevelManager.activeToplevel?.activated)

            property bool isBarBottom: root.barIsBottom
            property bool isDockBottom: !isBarBottom

            anchors {
                bottom: isDockBottom
                top: !isDockBottom
                left: true
                right: true
            }

            // Exclusión de zona
            exclusiveZone: root.pinned 
                ? (implicitHeight - (root.isFloatOrHybrid ? Appearance.sizes.elevationMargin : 0)) 
                : 0

            // Base radius para redondear bordes si está flotando o unido
            readonly property int baseRadius: Appearance.rounding.large

            // Medidas implícitas de la ventana
            implicitWidth: dockBackground.implicitWidth
            implicitHeight: (Config.options?.dock?.height ?? 70) 
                            + root.dockHeightNudge 
                            + (root.isFloatOrHybrid ? Appearance.sizes.elevationMargin : 0)

            mask: Region { item: dockMouseArea }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                // Ajuste inteligente para no cortar en ningún modo
                anchors {
                    topMargin: isDockBottom ? (dockRoot.reveal ? 0 : Config.options?.dock?.hoverToReveal ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight) : (dockRoot.implicitHeight + 1)) : 0
                    bottomMargin: isDockBottom ? 0 : (dockRoot.reveal ? 0 : Config.options?.dock?.hoverToReveal ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight) : (dockRoot.implicitHeight + 1))
                    horizontalCenter: parent.horizontalCenter
                }
                
                // El ancho abarca el flare o el padding sin cortes
                width: dockBackground.width

                state: isDockBottom ? "topAnchored" : "bottomAnchored"
                states: [
                    State {
                        name: "topAnchored"
                        AnchorChanges {
                            target: dockMouseArea
                            anchors.top: parent.top
                            anchors.bottom: undefined
                        }
                    },
                    State {
                        name: "bottomAnchored"
                        AnchorChanges {
                            target: dockMouseArea
                            anchors.top: undefined
                            anchors.bottom: parent.bottom
                        }
                    }
                ]

                Behavior on anchors.topMargin {
                    enabled: root.animEnabled && root.animRevealTransitions
                    NumberAnimation { duration: root.revealAnimMs; easing.type: Easing.OutCubic }
                }

                Behavior on anchors.bottomMargin {
                    enabled: root.animEnabled && root.animRevealTransitions
                    NumberAnimation { duration: root.revealAnimMs; easing.type: Easing.OutCubic }
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    
                    // Contenedor principal que se moverá y dibujará el fondo
                    Item {
                        id: dockBackground
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: isDockBottom ? parent.bottom : undefined
                        anchors.top: isDockBottom ? undefined : parent.top
                        
                        // Calculamos el ancho sumando las curvas (flareSpace)
                        property real r: dockRoot.baseRadius
                        property real flareSpace: root.isFloatOrHybrid ? 0 : (r * 2)

                        // El ancho visible total es el ancho del contenido interno más los bordes necesarios.
                        width: dockRow.implicitWidth + (root.isFloatOrHybrid ? root.kDockPadding * 2 : flareSpace * 2)
                        height: parent.height - (root.isFloatOrHybrid ? Appearance.sizes.elevationMargin : 0)

                        // Componente Inteligente para el Fondo
                        Loader {
                            id: bgLoader
                            anchors.fill: parent
                            sourceComponent: root.isFloatOrHybrid ? floatingBgComponent : unitedBgComponent
                        }

                        // --- COMPONENTE MODO FLOTANTE ---
                        Component {
                            id: floatingBgComponent
                            Item {
                                anchors.fill: parent
                                
                                Rectangle {
                                    id: floatShadowShape
                                    anchors.fill: parent
                                    radius: dockRoot.baseRadius
                                    color: "transparent"
                                    antialiasing: true
                                }

                                StyledRectangularShadow { target: floatShadowShape }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: dockRoot.baseRadius
                                    color: Appearance.colors.colLayer0
                                    border.width: 1
                                    border.color: Appearance.colors.colLayer0Border
                                    antialiasing: true
                                }
                            }
                        }

                        // --- COMPONENTE MODO UNIDO (Shape curvo abrazando los bordes) ---
                        Component {
                            id: unitedBgComponent
                            Shape {
                                id: dockVisualBackground
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer

                                property real w: width
                                property real h: height
                                property real r: dockBackground.r

                                property real startY: isDockBottom ? h : 0

                                // Puntos para el Shape
                                property real p1X: r
                                property real p1Y: isDockBottom ? h - r : r
                                property real c1X: r
                                property real c1Y: isDockBottom ? h : 0

                                property real p2X: r
                                property real p2Y: isDockBottom ? r : h - r

                                property real p3X: 2 * r
                                property real p3Y: isDockBottom ? 0 : h
                                property real c2X: r
                                property real c2Y: isDockBottom ? 0 : h

                                property real p4X: w - 2 * r
                                property real p4Y: isDockBottom ? 0 : h

                                property real p5X: w - r
                                property real p5Y: isDockBottom ? r : h - r
                                property real c3X: w - r
                                property real c3Y: isDockBottom ? 0 : h

                                property real p6X: w - r
                                property real p6Y: isDockBottom ? h - r : r

                                property real p7X: w
                                property real p7Y: isDockBottom ? h : 0
                                property real c4X: w - r
                                property real c4Y: isDockBottom ? h : 0

                                ShapePath {
                                    fillColor: Appearance.colors.colLayer0
                                    strokeColor: "transparent"
                                    strokeWidth: 0
                                    startX: 0
                                    startY: dockVisualBackground.startY

                                    PathQuad { x: dockVisualBackground.p1X; y: dockVisualBackground.p1Y; controlX: dockVisualBackground.c1X; controlY: dockVisualBackground.c1Y }
                                    PathLine { x: dockVisualBackground.p2X; y: dockVisualBackground.p2Y }
                                    PathQuad { x: dockVisualBackground.p3X; y: dockVisualBackground.p3Y; controlX: dockVisualBackground.c2X; controlY: dockVisualBackground.c2Y }
                                    PathLine { x: dockVisualBackground.p4X; y: dockVisualBackground.p4Y }
                                    PathQuad { x: dockVisualBackground.p5X; y: dockVisualBackground.p5Y; controlX: dockVisualBackground.c3X; controlY: dockVisualBackground.c3Y }
                                    PathLine { x: dockVisualBackground.p6X; y: dockVisualBackground.p6Y }
                                    PathQuad { x: dockVisualBackground.p7X; y: dockVisualBackground.p7Y; controlX: dockVisualBackground.c4X; controlY: dockVisualBackground.c4Y }
                                    PathLine { x: 0; y: dockVisualBackground.startY }
                                }

                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Appearance.colors.colLayer0Border
                                    strokeWidth: 1
                                    capStyle: ShapePath.FlatCap
                                    startX: 0
                                    startY: dockVisualBackground.startY

                                    PathQuad { x: dockVisualBackground.p1X; y: dockVisualBackground.p1Y; controlX: dockVisualBackground.c1X; controlY: dockVisualBackground.c1Y }
                                    PathLine { x: dockVisualBackground.p2X; y: dockVisualBackground.p2Y }
                                    PathQuad { x: dockVisualBackground.p3X; y: dockVisualBackground.p3Y; controlX: dockVisualBackground.c2X; controlY: dockVisualBackground.c2Y }
                                    PathLine { x: dockVisualBackground.p4X; y: dockVisualBackground.p4Y }
                                    PathQuad { x: dockVisualBackground.p5X; y: dockVisualBackground.p5Y; controlX: dockVisualBackground.c3X; controlY: dockVisualBackground.c3Y }
                                    PathLine { x: dockVisualBackground.p6X; y: dockVisualBackground.p6Y }
                                    PathQuad { x: dockVisualBackground.p7X; y: dockVisualBackground.p7Y; controlX: dockVisualBackground.c4X; controlY: dockVisualBackground.c4Y }
                                }
                            }
                        }

                        // --- CONTENIDO DEL DOCK ---
                        RowLayout {
                            id: dockRow
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: root.kDockSpacing
                            property real padding: root.kDockPadding

                            Item { width: root.dockInnerPadX; height: 1 }

                            VerticalButtonGroup {
                                Layout.topMargin: dockRow.padding
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
