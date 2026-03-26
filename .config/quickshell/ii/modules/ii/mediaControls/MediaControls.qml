pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtQml.Models 
import QtCore
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
    
    readonly property real panelWidth: 950
    readonly property real panelHeight: 600 
    property real popupRounding: Appearance.rounding.large || 20

    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(players) {
        let filtered = []
        let used = new Set()
        for (let i = 0; i < players.length; ++i) {
            if (used.has(i)) continue
            let p1 = players[i]
            let group = [i]
            for (let j = i + 1; j < players.length; ++j) {
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
        onRunningChanged: { if (!cavaProc.running) root.visualizerPoints = [] }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p))
                root.visualizerPoints = points
            }
        }
    }

    readonly property var bgStyleRaw: Config.options?.statusBar?.backgroundStyle ?? 0
    property bool hasActiveWindows: false

    Connections {
        enabled: root.bgStyleRaw === 2 || root.bgStyleRaw === "adaptive"
        target: HyprlandData
        function onWindowListChanged() { root.updateActiveWindows() }
        function onActiveWorkspaceChanged() { root.updateActiveWindows() }
    }
    
    function updateActiveWindows() {
        if (!HyprlandData) return;
        const activeWsId = HyprlandData.activeWorkspace?.id;
        root.hasActiveWindows = activeWsId ? HyprlandData.windowList.some(w => w.workspace.id === activeWsId && !w.floating) : false;
    }

    Component.onCompleted: updateActiveWindows()

    Loader {
        id: mediaControlsLoader
        active: true
        sourceComponent: PanelWindow {
            id: panelWindow
            visible: GlobalStates.mediaControlsOpen || content.panelOpacity > 0
            exclusiveZone: 0
            exclusionMode: (content.isHybridNotchMode || content.isDetachedTransparentMode) ? ExclusionMode.Ignore : ExclusionMode.Normal
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"
            WlrLayershell.layer: GlobalStates.mediaControlsOpen ? WlrLayer.Overlay : WlrLayer.Background
            WlrLayershell.keyboardFocus: GlobalStates.mediaControlsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.mediaControlsOpen = false
            }

            HyprlandFocusGrab {
                id: focusGrab
                active: GlobalStates.mediaControlsOpen && !root.pinned
                windows: [panelWindow]
                onCleared: { if (!root.pinned) GlobalStates.mediaControlsOpen = false }
            }

            Item {
                id: masterClip
                anchors.fill: parent
                clip: true

                Item {
                    id: content
                    anchors.fill: parent
                    property real panelOpacity: panelBg.opacity
                    
                    property int activeViewId: 0
                    property int currentVisualIndex: 0
                    property bool editMode: false
                    
                    readonly property int tabCount: 7
                    readonly property int tabButtonSize: 44
                    readonly property int tabStripWidth: tabButtonSize + 16

                    readonly property var cornerConf: Config.options?.bar?.cornerStyle ?? 0
                    readonly property bool isHug: cornerConf === 0 || cornerConf === "hug"
                    readonly property bool isFloat: cornerConf === 1 || cornerConf === "float"
                    
                    readonly property var bgConf: Config.options?.bar?.barBackgroundStyle ?? 1
                    readonly property bool isGlass: bgConf === 0 || bgConf === "glass" || bgConf === "transparent"
                    readonly property bool isAdaptive: bgConf === 2 || bgConf === "adaptive"
                    
                    readonly property bool isTransparentBar: isGlass || (isAdaptive && !root.hasActiveWindows)
                    
                    readonly property string groupConf: Config.options?.bar?.groupBackgroundStyle ?? ""
                    readonly property bool isHybrid: groupConf === "hybrid"

                    readonly property bool isHybridNotchMode: isHybrid
                    readonly property bool isDetachedTransparentMode: !isHybrid && isTransparentBar && (isHug || isFloat)

                    readonly property int gapsOut: isFloat ? (Appearance.sizes.hyprlandGapsOut || 10) : 0
                    readonly property int baseBarBottom: gapsOut + (Appearance.sizes.baseBarHeight || 40)

                    readonly property int hybridNotchY: baseBarBottom - (isFloat ? 6 : 0) - (isHug ? 1 : 0)
                    readonly property int detachedGapY: baseBarBottom + 8

                    property int topOvershoot: (isHybridNotchMode || isDetachedTransparentMode) ? 0 : 20

                    readonly property bool isVisibleHug: !isTransparentBar && isHug

                    readonly property int shoulderRadiusVal: Config.options?.statusBar?.backgroundCornerRadius ?? 20

                    Settings {
                        id: dashSettings
                        category: "MediaControlsTabs"
                        property string tabOrder: ""
                    }

                    function getInitialModel() {
                        let defaults = [
                            { icon: "cloud", viewId: 0 },
                            { icon: "calendar_today", viewId: 1 },
                            { icon: "event_note", viewId: 2 },
                            { icon: "music_note", viewId: 3 },
                            { icon: "memory", viewId: 4 },
                            { icon: "edit_note", viewId: 5 },
                            { icon: "translate", viewId: 6 }
                        ];
                        if (dashSettings.tabOrder) {
                            try {
                                let saved = JSON.parse(dashSettings.tabOrder);
                                if (Array.isArray(saved) && saved.length === 7) {
                                    let newModel = [];
                                    for (let i = 0; i < saved.length; i++) {
                                        let item = defaults.find(x => x.viewId === saved[i]);
                                        if (item) newModel.push(item);
                                    }
                                    if (newModel.length === 7) return newModel;
                                }
                            } catch(e) {}
                        }
                        return defaults;
                    }

                    function saveTabOrder() {
                        let order = [];
                        for (let i = 0; i < content.tabCount; i++) {
                            let m = visualModel.items.get(i).model;
                            let vId = m.viewId !== undefined ? m.viewId : m.modelData.viewId;
                            order.push(vId);
                        }
                        dashSettings.tabOrder = JSON.stringify(order);
                    }

                    onCurrentVisualIndexChanged: {
                        tabHighlight.idx1 = currentVisualIndex
                        Qt.callLater(() => { tabHighlight.idx2 = currentVisualIndex })
                    }

                    states: [
                        State {
                            name: "visible"
                            when: GlobalStates.mediaControlsOpen
                            PropertyChanges { target: visualContainer; opacity: 1 }
                            PropertyChanges { target: panelBg; y: -content.topOvershoot; opacity: 1 } 
                            PropertyChanges { target: rightShoulder; opacity: 1 }
                            PropertyChanges { target: leftShoulder; opacity: 1 }
                        }
                    ]

                    transitions: [
                        Transition {
                            from: ""; to: "visible"
                            SequentialAnimation {
                                PropertyAction { targets: [panelBg, visualContainer]; property: "opacity"; value: 1 }
                                ParallelAnimation {
                                    NumberAnimation { target: panelBg; property: "y"; from: -root.panelHeight - content.topOvershoot; to: -content.topOvershoot; duration: 350; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel || [0.38, 1.21, 0.22, 1] }
                                    NumberAnimation { targets: [rightShoulder, leftShoulder]; property: "opacity"; from: 0; to: 1; duration: 300 }
                                }
                            }
                        },
                        Transition {
                            from: "visible"; to: ""
                            SequentialAnimation {
                                ParallelAnimation {
                                    NumberAnimation { target: panelBg; property: "y"; to: -root.panelHeight - content.topOvershoot; duration: 350; easing.bezierCurve: Appearance.animationCurves.emphasized || [0.2, 0.0, 0.0, 1.0] }
                                    NumberAnimation { targets: [rightShoulder, leftShoulder]; property: "opacity"; to: 0; duration: 150 }
                                }
                                PropertyAction { targets: [panelBg, visualContainer]; property: "opacity"; value: 0 }
                            }
                        }
                    ]

                    Item {
                        id: visualContainer
                        anchors.fill: parent
                        opacity: 0 
                        
                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: 0; verticalOffset: 4; radius: 28; samples: 32
                            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.20)
                            transparentBorder: true
                        }

                        Rectangle {
                            id: clipRect
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: content.isHybridNotchMode ? content.hybridNotchY : (content.isDetachedTransparentMode ? content.detachedGapY : 0)
                            width: root.panelWidth
                            height: root.panelHeight
                            clip: true
                            color: "transparent"

                            Rectangle {
                                id: panelBg
                                width: root.panelWidth
                                height: root.panelHeight + content.topOvershoot 
                                y: -root.panelHeight - content.topOvershoot
                                opacity: 0
                                color: content.isVisibleHug ? Appearance.colors.colLayer0 : (Appearance.m3colors.m3surfaceContainerLow || "#1e1e2e")
                                
                                topLeftRadius: content.isDetachedTransparentMode ? root.popupRounding : 0
                                topRightRadius: content.isDetachedTransparentMode ? root.popupRounding : 0
                                bottomLeftRadius: root.popupRounding
                                bottomRightRadius: root.popupRounding

                                border.width: 0
                                border.color: "transparent"

                                MouseArea { anchors.fill: parent; hoverEnabled: true }

                                Row {
                                    anchors.fill: parent
                                    leftPadding: 16; rightPadding: 16; topPadding: 16 + content.topOvershoot; bottomPadding: 16
                                    spacing: 16

                                    Item {
                                        id: tabStrip
                                        width: content.tabStripWidth
                                        height: root.panelHeight - 32 

                                        MouseArea {
                                            anchors.fill: parent
                                            onWheel: (wheel) => {
                                                if (content.editMode) return;
                                                if (wheel.angleDelta.y > 0) content.currentVisualIndex = (content.currentVisualIndex - 1 + content.tabCount) % content.tabCount
                                                else if (wheel.angleDelta.y < 0) content.currentVisualIndex = (content.currentVisualIndex + 1) % content.tabCount
                                                
                                                let currentItem = visualModel.items.get(content.currentVisualIndex).model;
                                                content.activeViewId = currentItem.viewId !== undefined ? currentItem.viewId : currentItem.modelData.viewId;
                                            }
                                        }

                                        Rectangle {
                                            anchors.centerIn: tabColumn
                                            width: content.tabButtonSize + 16
                                            height: tabColumn.implicitHeight + 16
                                            radius: Appearance.rounding.large
                                            color: Appearance.colors.colLayer2 || "#181825"
                                            opacity: 0.8
                                        }

                                        Rectangle {
                                            id: tabHighlight
                                            x: Math.round((tabStrip.width - content.tabButtonSize) / 2)
                                            width: content.tabButtonSize
                                            radius: 16
                                            color: Appearance.colors.colPrimaryContainer || "#89b4fa"
                                            
                                            opacity: content.editMode ? 0 : 1
                                            Behavior on opacity { NumberAnimation { duration: 150 } }

                                            property int idx1: 0
                                            property int idx2: 0
                                            function getYForIndex(i) { return tabColumn.y + i * (content.tabButtonSize + 6) }

                                            property real targetY1: getYForIndex(idx1)
                                            property real targetY2: getYForIndex(idx2)
                                            property real animY1: targetY1
                                            property real animY2: targetY2

                                            y: Math.min(animY1, animY2)
                                            height: Math.abs(animY2 - animY1) + content.tabButtonSize

                                            Behavior on animY1 { NumberAnimation { duration: 120; easing.type: Easing.OutSine } }
                                            Behavior on animY2 { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                                            onTargetY1Changed: animY1 = targetY1
                                            onTargetY2Changed: animY2 = targetY2
                                            onIdx1Changed: { targetY1 = getYForIndex(idx1) }
                                            onIdx2Changed: { targetY2 = getYForIndex(idx2) }
                                        }

                                        Column {
                                            id: tabColumn
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6

                                            ListView {
                                                id: tabList
                                                width: content.tabButtonSize
                                                height: (content.tabButtonSize * content.tabCount) + (6 * (content.tabCount - 1))
                                                interactive: false 
                                                spacing: 6
                                                
                                                model: DelegateModel {
                                                    id: visualModel
                                                    model: content.getInitialModel()
                                                    
                                                    delegate: DropArea {
                                                        id: delegateRoot
                                                        required property var modelData
                                                        
                                                        width: content.tabButtonSize
                                                        height: content.tabButtonSize
                                                        keys: ["tabItem"]
                                                        
                                                        property int visualIndex: DelegateModel.itemsIndex
                                                        property int viewId: modelData.viewId

                                                        onEntered: (drag) => {
                                                            let from = drag.source.visualIndex
                                                            let to = delegateRoot.visualIndex
                                                            if (from !== to) {
                                                                visualModel.items.move(from, to)
                                                                if (content.activeViewId === drag.source.viewId) {
                                                                    content.currentVisualIndex = to
                                                                } else if (content.activeViewId === delegateRoot.viewId) {
                                                                    content.currentVisualIndex = from
                                                                }
                                                            }
                                                        }

                                                        Item {
                                                            id: itemContainer
                                                            width: content.tabButtonSize
                                                            height: content.tabButtonSize
                                                            
                                                            property int visualIndex: delegateRoot.visualIndex
                                                            property int viewId: delegateRoot.viewId

                                                            Drag.active: dragArea.drag.active
                                                            Drag.source: itemContainer
                                                            Drag.keys: ["tabItem"]
                                                            Drag.hotSpot.x: width / 2
                                                            Drag.hotSpot.y: height / 2

                                                            states: [
                                                                State {
                                                                    when: dragArea.drag.active
                                                                    ParentChange { target: itemContainer; parent: tabList }
                                                                    PropertyChanges { target: itemContainer; opacity: 0.9; scale: 1.15; z: 100 }
                                                                }
                                                            ]
                                                            Behavior on scale { NumberAnimation { duration: 150 } }

                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: Appearance.rounding.small
                                                                color: content.editMode ? Appearance.colors.colLayer1 : "transparent"
                                                                opacity: dragArea.containsMouse && content.activeViewId !== delegateRoot.viewId ? 0.7 : (content.editMode ? 0.5 : 0)
                                                                border.width: content.editMode ? 1 : 0
                                                                border.color: Appearance.colors.colPrimaryContainer
                                                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                                            }

                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: modelData.icon 
                                                                iconSize: 22
                                                                color: content.activeViewId === delegateRoot.viewId ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                                                Behavior on color { ColorAnimation { duration: 200 } }

                                                                SequentialAnimation on rotation {
                                                                    loops: Animation.Infinite
                                                                    running: content.editMode && !dragArea.drag.active
                                                                    NumberAnimation { from: 0; to: 3; duration: 120 }
                                                                    NumberAnimation { from: 3; to: -3; duration: 240 }
                                                                    NumberAnimation { from: -3; to: 0; duration: 120 }
                                                                }
                                                            }

                                                            MouseArea {
                                                                id: dragArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: content.editMode ? Qt.OpenHandCursor : Qt.PointingHandCursor
                                                                
                                                                drag.target: content.editMode ? itemContainer : null
                                                                drag.axis: Drag.YAxis

                                                                onPressed: {
                                                                    if (content.editMode) cursorShape = Qt.ClosedHandCursor
                                                                }
                                                                onReleased: {
                                                                    if (content.editMode) {
                                                                        cursorShape = Qt.OpenHandCursor
                                                                        content.saveTabOrder()
                                                                    } else {
                                                                        content.activeViewId = delegateRoot.viewId
                                                                        content.currentVisualIndex = delegateRoot.visualIndex
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: content.tabButtonSize * 0.6
                                                height: 2
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                color: Appearance.colors.colSubtext
                                                opacity: 0.2
                                                radius: 1
                                            }

                                            Item {
                                                width: content.tabButtonSize
                                                height: content.tabButtonSize

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: Appearance.rounding.small
                                                    color: content.editMode ? Appearance.colors.colPrimaryContainer : "transparent"
                                                    opacity: editBtnMouse.containsMouse ? 0.8 : (content.editMode ? 1 : 0)
                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: content.editMode ? "done" : "tune" 
                                                    iconSize: 22
                                                    color: content.editMode ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }

                                                MouseArea {
                                                    id: editBtnMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        content.editMode = !content.editMode
                                                        if (!content.editMode) content.saveTabOrder()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        id: contentArea
                                        width: root.panelWidth - 48 - content.tabStripWidth
                                        height: root.panelHeight - 32

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 0; visible: content.activeViewId === 0
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 0 ? 0 : (content.activeViewId > 0 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("DashWeather.qml")
                                        }

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 1; visible: content.activeViewId === 1
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 1 ? 0 : (content.activeViewId > 1 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("HorizontalMiniCalendar.qml")
                                        }

                                        Loader {
                                            id: scheduleLoader
                                            anchors.fill: parent; active: true; visible: content.activeViewId === 2
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 2 ? 0 : (content.activeViewId > 2 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("DashSchedule.qml")
                                        }

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 3; visible: content.activeViewId === 3
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 3 ? 0 : (content.activeViewId > 3 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            
                                            sourceComponent: Item {
                                                ColumnLayout {
                                                    anchors.fill: parent; spacing: 10
                                                    Repeater {
                                                        model: ScriptModel { values: root.meaningfulPlayers }
                                                        delegate: PlayerControl {
                                                            required property MprisPlayer modelData
                                                            player: modelData; visualizerPoints: root.visualizerPoints
                                                            implicitWidth: parent.width; Layout.fillHeight: true 
                                                            radius: Appearance.rounding.normal || 16
                                                            pinned: root.pinned; settingsQmlPath: root.settingsQmlPath
                                                            onTogglePinned: root.pinned = !root.pinned
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    anchors.centerIn: parent; spacing: 16; visible: root.meaningfulPlayers.length === 0
                                                    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "music_off"; iconSize: 64; color: Appearance.colors.colSubtext; opacity: 0.3 }
                                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: Translation.tr("No active player"); font.pixelSize: 22; color: Appearance.colors.colSubtext; font.italic: true; opacity: 0.5 }
                                                }
                                            }
                                        }

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 4; visible: content.activeViewId === 4
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 4 ? 0 : (content.activeViewId > 4 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("ResourcesPopup.qml")
                                        }

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 5; visible: content.activeViewId === 5
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 5 ? 0 : (content.activeViewId > 5 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("DashNotepad.qml")
                                        }

                                        Loader {
                                            anchors.fill: parent; active: content.activeViewId === 6; visible: content.activeViewId === 6
                                            opacity: visible ? 1 : 0
                                            transform: Translate { y: content.activeViewId === 6 ? 0 : (content.activeViewId > 6 ? -12 : 12); Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } }
                                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                            source: Qt.resolvedUrl("DashTranslation.qml")
                                        }
                                    }
                                }
                            }
                        }

                        RoundCorner {
                            id: rightShoulder
                            anchors.right: clipRect.left
                            anchors.rightMargin: -1
                            y: clipRect.y + panelBg.y + content.topOvershoot
                            implicitSize: content.shoulderRadiusVal > 0 ? content.shoulderRadiusVal : 20
                            corner: RoundCorner.CornerEnum.TopRight 
                            color: panelBg.color
                            opacity: 0
                            visible: !content.isDetachedTransparentMode
                        }
                        
                        RoundCorner {
                            id: leftShoulder
                            anchors.left: clipRect.right
                            anchors.leftMargin: -1
                            y: clipRect.y + panelBg.y + content.topOvershoot
                            implicitSize: content.shoulderRadiusVal > 0 ? content.shoulderRadiusVal : 20
                            corner: RoundCorner.CornerEnum.TopLeft 
                            color: panelBg.color
                            opacity: 0
                            visible: !content.isDetachedTransparentMode
                        }
                    }
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
    }
}
