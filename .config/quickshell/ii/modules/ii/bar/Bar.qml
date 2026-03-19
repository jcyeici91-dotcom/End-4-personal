pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar.drawers
import qs.modules.common.functions as CF

Scope {
    id: bar

    Variants {
        id: barVariant

        readonly property var variantModel: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        model: variantModel
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            property int monitorIndex: barVariant.variantModel.indexOf(modelData)

            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
            property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
            property bool fullscreen: activeWorkspaceWithFullscreen != undefined

            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                property int monitorIndex: barLoader.monitorIndex
                
                //  INTERRUPTOR MAESTRO 
                property bool enableAnimations: Config.options.appearance.enableAnimations
                
                QtObject {
                    id: styleEnum
                    readonly property int visible: 1
                    readonly property int adaptive: 2
                }

                readonly property var _barBackgroundStyleRaw: (Config?.options?.bar?.barBackgroundStyle ?? styleEnum.visible)

                function _normalizeBarStyle(v) {
                    if (typeof v === "number") {
                        switch (v) {
                            case styleEnum.visible: return "visible"
                            case styleEnum.adaptive: return "adaptive"
                            default: return "visible"
                        }
                    }

                    if (typeof v !== "string") return "visible"
                    const s = v.toLowerCase().trim()

                    if (s === "solid" || s === "alwaysvisible" || s === "always_visible") return "visible"
                    if (s === "visible" || s === "adaptive") return s

                    return "visible"
                }

                readonly property string barStyleName: _normalizeBarStyle(_barBackgroundStyleRaw)

                readonly property int barBackgroundStyle: (typeof _barBackgroundStyleRaw === "number")
                    ? _barBackgroundStyleRaw
                    : ((barStyleName === "adaptive") ? styleEnum.adaptive : styleEnum.visible)

                property bool hasActiveWindows: false
                readonly property bool isAdaptiveStyle: (barRoot.barStyleName === "adaptive")

                readonly property bool showBarBackground: (
                    (barRoot.barStyleName === "visible") ||
                    (barRoot.barStyleName === "adaptive" && barRoot.hasActiveWindows)
                )

                readonly property color _solidBase: Appearance.colors.colLayer0
                readonly property color barBackgroundColorForCorners: !barRoot.showBarBackground ? "transparent" : _solidBase

                property var currentMonitor: {
                    const screenName = barRoot.screen?.name
                    return HyprlandData.monitors.find(m => m && m.name === screenName)
                        ?? HyprlandData.monitors.find(m => m && m.id === barRoot.monitorIndex)
                        ?? null
                }

                property var activeWsId: currentMonitor?.activeWorkspace?.id

                function recomputeHasActiveWindows() {
                    if (!activeWsId) {
                        barRoot.hasActiveWindows = false
                        return
                    }
                    barRoot.hasActiveWindows = HyprlandData.windowList.some(w =>
                        (w.workspace?.id === activeWsId) && !w.floating
                    )
                }

                onActiveWsIdChanged: barRoot.recomputeHasActiveWindows()

                Connections {
                    enabled: barRoot.isAdaptiveStyle
                    target: HyprlandData
                    function onWindowListChanged() { barRoot.recomputeHasActiveWindows() }
                    function onMonitorsChanged() { barRoot.recomputeHasActiveWindows() }
                }

                HyprlandFocusGrab {
                    id: focusGrab
                    active: Config.options.appearance.panelAnimation.enableBackgroundAnimation && (GlobalStates.overviewOpen)
                    windows: [barRoot]
                    onCleared: {
                        GlobalStates.overviewOpen = false
                    }
                }

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }
                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow
                exclusionMode: ExclusionMode.Ignore
                
                // --- AJUSTE DE ALTURA EXCLUSIVA PARA VENTANAS ---
                exclusiveZone: (Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 :
                    ((Config.options.bar.groupBackgroundStyle === "hybrid") ? Appearance.sizes.baseBarHeight + 6 : Appearance.sizes.baseBarHeight) + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)

                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: modelData.height 
                mask: Region {
                    item: hoverMaskRegion
                }
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    right: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                    bottom: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                }

                Component.onCompleted: {
                    barRoot.recomputeHasActiveWindows()
                    GlobalFocusGrab.addPersistent(barRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                }

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors {
                        fill: parent
                        rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * 1
                        bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * 1
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            topMargin: -Config.options.bar.autoHide.hoverRegionWidth
                            bottomMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        }
                    }

                    BarContent {
                        id: barContent
                        
                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            right: parent.right
                            left: parent.left
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : 0
                            bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                            rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                        }
                        Behavior on anchors.topMargin {
                            enabled: barRoot.enableAnimations
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            enabled: barRoot.enableAnimations
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: parent.bottom
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : 0
                            }
                        }
                    }

                    Loader {
                        id: roundDecorators
                        
                        // --- 1. DETECTAMOS LAS COMBINACIONES EXACTAS ---
                        readonly property bool isGlass: Config?.options?.bar?.barBackgroundStyle === 0
                        readonly property bool isHug: Config?.options?.bar?.cornerStyle === 0
                        readonly property bool isHybrid: Config?.options?.bar?.groupBackgroundStyle === "hybrid"
                        
                        readonly property bool isHugTranspRect: isHug && isGlass && !isHybrid

                        readonly property bool isVisibleMode: Config?.options?.bar?.barBackgroundStyle === 1
                        readonly property bool isFloat: Config?.options?.bar?.cornerStyle === 1
                        readonly property bool isVisibleFloat: isVisibleMode && isFloat

                        readonly property bool isAdaptiveMode: Config?.options?.bar?.barBackgroundStyle === 2
                        readonly property bool isAdaptiveEmpty: isAdaptiveMode && !barRoot.hasActiveWindows && (isHug || isFloat)
                        
                        // --- EL NUEVO AJUSTE ---
                        // Combinación: Float (1) + Adaptive (2) + CON ventanas
                        readonly property bool isAdaptiveFloatWithWindows: isAdaptiveMode && isFloat && barRoot.hasActiveWindows

                        // --- 2. ACTIVAMOS LA MAGIA (Subir esquinas) ---
                        // Añadimos isAdaptiveFloatWithWindows a la lista de condiciones
                        readonly property bool pinCornersToScreenEdge: isHybrid || isHugTranspRect || isVisibleFloat || isAdaptiveEmpty || isAdaptiveFloatWithWindows

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: pinCornersToScreenEdge ? parent.top : barContent.bottom
                            bottom: undefined
                        }
                        height: Appearance.rounding.screenRounding
                        
                        // --- 3. ASEGURAMOS QUE EL LOADER ESTÉ ACTIVO ---
                        active: (showBarBackground && isHug) || pinCornersToScreenEdge

                        // --- 4. COLOR SÓLIDO PARA EL "MARCO" ---
                        readonly property color dynamicCornerColor: (!showBarBackground && pinCornersToScreenEdge) || isVisibleFloat || isAdaptiveEmpty || isAdaptiveFloatWithWindows ? barRoot._solidBase : barRoot.barBackgroundColorForCorners

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: roundDecorators
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: pinCornersToScreenEdge ? parent.bottom : barContent.top
                                }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding
                            
                            RoundCorner {
                                id: leftCorner
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                }
                                implicitSize: Appearance.rounding.screenRounding
                                color: roundDecorators.dynamicCornerColor 

                                corner: RoundCorner.CornerEnum.TopLeft
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                                    }
                                }
                            }
                            
                            RoundCorner {
                                id: rightCorner
                                anchors {
                                    right: parent.right
                                    top: !Config.options.bar.bottom ? parent.top : undefined
                                    bottom: Config.options.bar.bottom ? parent.bottom : undefined
                                }
                                implicitSize: Appearance.rounding.screenRounding
                                color: roundDecorators.dynamicCornerColor 

                                corner: RoundCorner.CornerEnum.TopRight
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: (DrawerVisibilityConfig.barOsdVisible || DrawerVisibilityConfig.barSearchOverviewVisible) && !barLoader.fullscreen
                    sourceComponent: Item {
                        clip: true
                        anchors { 
                            fill: parent
                            topMargin: Appearance.sizes.barHeight - (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 1)
                        }

                        Backgrounds {
                            id: backgrounds
                            panels: panels
                        }

                        Panels {
                            id: panels

                            screen: barLoader.modelData
                            visibilities: Visibilities.getForScreen(barLoader.modelData)
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
