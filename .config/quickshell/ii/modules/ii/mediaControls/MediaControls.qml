pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    property bool pinned: false
    readonly property string settingsQmlPath: Quickshell.shellPath("settings.qml")

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    
    // 🔥 MEDIDAS CORREGIDAS (Más espacio interno, menos espacio muerto) 🔥
    readonly property real widgetWidth: 700
    readonly property real widgetHeight: 150 
    
    property real popupRounding: 45
    property list<real> visualizerPoints: []

    readonly property bool isFloatOrHybrid: (Config.options.bar.cornerStyle === 1) || (Config.options.bar.barBackgroundStyle === 0) || (Config.options.bar.barBackgroundStyle === 3)
    readonly property int floatingGap: 12

    function filterDuplicatePlayers(players) {
        let filtered = []
        let used = new Set()
        for (let i = 0; i < players.length; ++i) {
            if (used.has(i)) continue
            let p1 = players[i]
            let group = [i]
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j]
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) ||
                    (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j)
                }
            }
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0)
            if (chosenIdx === undefined) chosenIdx = group[0]
            filtered.push(players[chosenIdx])
            group.forEach(idx => used.add(idx))
        }
        return filtered
    }

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = []
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p))
                root.visualizerPoints = points
            }
        }
    }

    property real openAnim: GlobalStates.mediaControlsOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuart }
    }

    Loader {
        id: mediaControlsLoader
        active: true
        sourceComponent: PanelWindow {
            id: panelWindow
            visible: GlobalStates.mediaControlsOpen || root.openAnim > 0.0
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            readonly property real baseRadius: root.popupRounding
            readonly property int contentW: root.widgetWidth + (baseRadius * 2)
            // 🔥 Elimina el espacio vacío gigante, ajusta al alto real 🔥
            readonly property int contentH: root.widgetHeight + 30 

            implicitWidth: contentW
            implicitHeight: contentH

            readonly property var rect: Persistent.states.media.popupRect
            readonly property real barThickness: Config.options.bar.vertical ? (Config.options.bar.sizes.width || 40) : (Config.options.bar.sizes.height || 40)
            readonly property bool isVertical: Config.options.bar.vertical
            readonly property bool isBottomRight: Config.options.bar.bottom
            readonly property string barEdge: isVertical ? (isBottomRight ? "right" : "left") : (isBottomRight ? "bottom" : "top")

            anchors {
                top: isVertical || !isBottomRight
                bottom: !isVertical && isBottomRight
                left: !isVertical || !isBottomRight
                right: isVertical && isBottomRight
            }

            margins {
                top: {
                    if (rect.width === 0) return 0
                    if (isVertical) {
                        let targetY = rect.y + (rect.height / 2) - (panelWindow.contentH / 2)
                        return Math.max(0, Math.min(targetY, screen.height - panelWindow.contentH))
                    } else {
                        return !isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                    }
                }
                bottom: !isVertical && isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                left: {
                    if (rect.width === 0) return 0
                    if (!isVertical) {
                        let targetX = rect.x + (rect.width / 2) - (panelWindow.contentW / 2)
                        return Math.max(0, Math.min(targetX, screen.width - panelWindow.contentW))
                    } else {
                        return !isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                    }
                }
                right: isVertical && isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
            }

            mask: Region { item: clipBox }

            Item {
                id: clipBox
                anchors.fill: parent
                clip: true

                Item {
                    id: slideContent
                    width: parent.width
                    height: parent.height
                    property real off: 1.0 - root.openAnim

                    x: panelWindow.barEdge === "left" ? -off * width : (panelWindow.barEdge === "right" ? off * width : 0)
                    y: panelWindow.barEdge === "top" ? -off * height : (panelWindow.barEdge === "bottom" ? off * height : 0)

                    Item {
                        id: background
                        anchors.fill: parent

                        Loader {
                            anchors.fill: parent
                            sourceComponent: root.isFloatOrHybrid ? floatingBgComponent : unitedBgComponent
                        }

                        Component {
                            id: floatingBgComponent
                            Rectangle {
                                anchors.centerIn: parent
                                width: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.height : parent.width
                                height: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.width : parent.height
                                color: Appearance.colors.colLayer0
                                radius: panelWindow.baseRadius
                                border.width: 1
                                border.color: Appearance.colors.colLayer0Border
                                rotation: {
                                    if (panelWindow.barEdge === "top") return 0
                                    if (panelWindow.barEdge === "bottom") return 180
                                    if (panelWindow.barEdge === "left") return -90
                                    if (panelWindow.barEdge === "right") return 90
                                }
                            }
                        }

                        Component {
                            id: unitedBgComponent
                            Shape {
                                anchors.centerIn: parent
                                width: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.height : parent.width
                                height: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.width : parent.height

                                rotation: {
                                    if (panelWindow.barEdge === "top") return 0
                                    if (panelWindow.barEdge === "bottom") return 180
                                    if (panelWindow.barEdge === "left") return -90
                                    if (panelWindow.barEdge === "right") return 90
                                }

                                preferredRendererType: Shape.CurveRenderer
                                property real w: width
                                property real h: height
                                property real rad: panelWindow.baseRadius

                                ShapePath {
                                    fillColor: Appearance.colors.colLayer0
                                    strokeColor: "transparent"
                                    strokeWidth: 0
                                    startX: 0
                                    startY: 0
                                    PathQuad { x: rad; y: rad; controlX: rad; controlY: 0 }
                                    PathLine { x: rad; y: h - rad }
                                    PathQuad { x: rad * 2; y: h; controlX: rad; controlY: h }
                                    PathLine { x: w - rad * 2; y: h }
                                    PathQuad { x: w - rad; y: h - rad; controlX: w - rad; controlY: h }
                                    PathLine { x: w - rad; y: rad }
                                    PathQuad { x: w; y: 0; controlX: w - rad; controlY: 0 }
                                    PathLine { x: 0; y: 0 }
                                }

                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Appearance.colors.colLayer0Border
                                    strokeWidth: 1
                                    capStyle: ShapePath.FlatCap
                                    startX: 0
                                    startY: 0
                                    PathQuad { x: rad; y: rad; controlX: rad; controlY: 0 }
                                    PathLine { x: rad; y: h - rad }
                                    PathQuad { x: rad * 2; y: h; controlX: rad; controlY: h }
                                    PathLine { x: w - rad * 2; y: h }
                                    PathQuad { x: w - rad; y: h - rad; controlX: w - rad; controlY: h }
                                    PathLine { x: w - rad; y: rad }
                                    PathQuad { x: w; y: 0; controlX: w - rad; controlY: 0 }
                                }
                            }
                        }
                    }

                    Item {
                        id: paddedContainer
                        anchors.fill: parent
                        // 🔥 MÁRGENES ESTRICTOS PARA ELIMINAR EL VACÍO 🔥
                        anchors.topMargin: 15
                        anchors.bottomMargin: 15 
                        anchors.leftMargin: panelWindow.barEdge === "left" ? panelWindow.baseRadius : (panelWindow.barEdge === "right" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)
                        anchors.rightMargin: panelWindow.barEdge === "right" ? panelWindow.baseRadius : (panelWindow.barEdge === "left" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)

                        ColumnLayout {
                            id: playerColumnLayout
                            anchors.fill: parent // 🔥 LLENA TODO EL CONTENEDOR 🔥
                            spacing: 10

                            Repeater {
                                model: ScriptModel { values: root.meaningfulPlayers }
                                delegate: PlayerControl {
                                    required property MprisPlayer modelData
                                    player: modelData
                                    visualizerPoints: root.visualizerPoints
                                    implicitWidth: root.widgetWidth
                                    Layout.fillHeight: true // 🔥 SE ESTIRA HASTA TOCAR EL FONDO 🔥
                                    radius: root.popupRounding
                                    pinned: root.pinned
                                    settingsQmlPath: root.settingsQmlPath
                                    onTogglePinned: root.pinned = !root.pinned
                                }
                            }

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                visible: root.meaningfulPlayers.length === 0
                                implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                                implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                                StyledRectangularShadow { target: placeholderBackground }

                                Rectangle {
                                    id: placeholderBackground
                                    anchors.centerIn: parent
                                    color: Appearance.colors.colLayer1
                                    radius: root.popupRounding
                                    property real padding: 20
                                    implicitWidth: placeholderLayout.implicitWidth + padding * 2
                                    implicitHeight: placeholderLayout.implicitHeight + padding * 2

                                    ColumnLayout {
                                        id: placeholderLayout
                                        anchors.centerIn: parent
                                        StyledText {
                                            text: Translation.tr("No active player")
                                            font.pixelSize: Appearance.font.pixelSize.large
                                        }
                                        StyledText {
                                            color: Appearance.colors.colSubtext
                                            text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            function updateDismissable() {
                if (GlobalStates.mediaControlsOpen && !root.pinned) {
                    GlobalFocusGrab.addDismissable(panelWindow)
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow)
                }
            }

            Component.onCompleted: updateDismissable()
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
        }
    }

    Connections {
        target: root
        function onPinnedChanged() {
            if (mediaControlsLoader.item) mediaControlsLoader.item.updateDismissable()
        }
    }

    Connections {
        target: GlobalStates
        function onMediaControlsOpenChanged() {
            if (mediaControlsLoader.item) mediaControlsLoader.item.updateDismissable()
        }
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            if (!root.pinned) GlobalStates.mediaControlsOpen = false
        }
    }

    IpcHandler {
        target: "mediaControls"
        function toggle(): void {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            if (GlobalStates.mediaControlsOpen) Notifications.timeoutAll()
        }
        function close(): void { GlobalStates.mediaControlsOpen = false }
        function open(): void {
            GlobalStates.mediaControlsOpen = true
            Notifications.timeoutAll()
        }
    }
}
