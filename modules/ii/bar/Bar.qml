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
import qs.modules.common.functions as CF // NUEVO: para transparentize en corners (no rompe)

Scope {
    id: bar

    // =========================================================
    // 1) Variants: una instancia de Bar por monitor (filtrable)
    // =========================================================
    Variants {
        id: barVariant

        // 1.1) Modelo de pantallas: usa screenList si está configurado
        readonly property var variantModel: {
            const screens = Quickshell.screens;
            const list = Config?.options?.bar?.screenList;
            if (!list || list.length === 0) return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        model: variantModel

        // =========================================================
        // 2) LazyLoader: solo crea la ventana si la barra está abierta
        // =========================================================
        LazyLoader {
            id: barLoader

            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData

            // Nota: esto NO es el id de Hyprland; es el índice del modelo de screens.
            property int monitorIndex: barVariant.variantModel.indexOf(modelData)

            // =========================================================
            // 3) PanelWindow: ventana real de la barra por monitor
            // =========================================================
            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                // ---------------------------------------------------------
                // 3.1) Flags/Helpers
                // ---------------------------------------------------------
                property int monitorIndex: barLoader.monitorIndex

                readonly property bool isBottom: !!Config?.options?.bar?.bottom
                readonly property bool autoHideEnabled: !!Config?.options?.bar?.autoHide?.enable
                readonly property bool pushWindows: !!Config?.options?.bar?.autoHide?.pushWindows
                readonly property bool deadPixelFix: !!Config?.options?.interactions?.deadPixelWorkaround?.enable

                // ---------------------------------------------------------
                // 3.2) Background style (Visible / Adaptive / Transparent)
                // ---------------------------------------------------------
                // Convención:
                // 0 = Transparent (glass)
                // 1 = Visible (siempre)
                // 2 = Adaptive (solo con ventanas)
                readonly property int barBackgroundStyle: (Config?.options?.bar?.barBackgroundStyle ?? 1)

                property bool hasActiveWindows: false

                // showBarBackground gobierna:
                // - decorators (cornerStyle hug)
                // - y sirve de estado general
                readonly property bool showBarBackground: (
                    (barBackgroundStyle === 1) ||
                    (barBackgroundStyle === 0) ||
                    (barBackgroundStyle === 2 && barRoot.hasActiveWindows)
                )

                // Color para corners (debe “parecer” el mismo fondo que pinta BarContent)
                readonly property color _glassTint: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.35) // NUEVO
                readonly property color barBackgroundColorForCorners: (barBackgroundStyle === 0)
                    ? _glassTint
                    : Appearance.colors.colLayer0

                // ---------------------------------------------------------
                // 3.3) Hyprland: detectar ventanas en el workspace activo
                //      (NUEVO: mapping robusto por screen.name -> monitor.name)
                // ---------------------------------------------------------
                function recomputeHasActiveWindows() {
                    const screenName = barRoot.screen?.name;

                    let monitor = null;
                    if (screenName) {
                        monitor = HyprlandData.monitors.find(m => m && m.name === screenName) ?? null;
                    }
                    // Fallback: compatibilidad (tu lógica previa)
                    if (!monitor) {
                        monitor = HyprlandData.monitors.find(m => m && m.id === barRoot.monitorIndex) ?? null;
                    }

                    const wsId = monitor?.activeWorkspace?.id;
                    const hasWindow = wsId
                        ? HyprlandData.windowList.some(w => w.workspace?.id === wsId && !w.floating)
                        : false;

                    barRoot.hasActiveWindows = hasWindow;
                }

                Connections {
                    // Solo necesario cuando el estilo depende de ventanas (Adaptive)
                    enabled: barRoot.barBackgroundStyle === 2
                    target: HyprlandData

                    function onWindowListChanged() { barRoot.recomputeHasActiveWindows(); }
                    function onMonitorsChanged() { barRoot.recomputeHasActiveWindows(); }
                }

                // ---------------------------------------------------------
                // 3.4) Auto-hide: mostrar por hover o por tecla Super
                // ---------------------------------------------------------
                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow

                Timer {
                    id: showBarTimer
                    interval: (Config?.options?.bar?.autoHide?.showWhenPressingSuper?.delay ?? 100)
                    repeat: false
                    onTriggered: barRoot.superShow = true
                }

                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!(Config?.options?.bar?.autoHide?.showWhenPressingSuper?.enable === true)) return;

                        if (GlobalStates.superDown) {
                            showBarTimer.restart();
                        } else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }

                // ---------------------------------------------------------
                // 3.5) Layershell / tamaño / exclusión / máscara
                // ---------------------------------------------------------
                exclusionMode: ExclusionMode.Ignore

                exclusiveZone: (barRoot.autoHideEnabled && (!barRoot.mustShow || !barRoot.pushWindows))
                    ? 0
                    : (Appearance.sizes.baseBarHeight
                       + (Config?.options?.bar?.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0))

                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: Appearance.sizes.barHeight + Appearance.rounding.screenRounding
                color: "transparent"

                mask: Region { item: hoverMaskRegion }

                // ---------------------------------------------------------
                // 3.6) Posición (top/bottom) y workaround dead-pixel
                // ---------------------------------------------------------
                anchors { top: !barRoot.isBottom; bottom: barRoot.isBottom; left: true; right: true }

                margins {
                    right: (barRoot.deadPixelFix && barRoot.anchors.right) * -1
                    bottom: (barRoot.deadPixelFix && barRoot.anchors.bottom) * -1
                }

                // ---------------------------------------------------------
                // 3.7) Lifecycle
                // ---------------------------------------------------------
                Component.onCompleted: {
                    barRoot.recomputeHasActiveWindows();
                    GlobalFocusGrab.addPersistent(barRoot);
                }

                Component.onDestruction: GlobalFocusGrab.removePersistent(barRoot)

                // =========================================================
                // 4) Hover region + BarContent (animación de ocultar/mostrar)
                // =========================================================
                MouseArea {
                    id: hoverRegion
                    hoverEnabled: true

                    anchors {
                        fill: parent
                        rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) * 1
                        bottomMargin: (barRoot.deadPixelFix && barRoot.anchors.bottom) * 1
                    }

                    // 4.1) Región usada por la máscara (hover/hide)
                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            topMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                            bottomMargin: -(Config?.options?.bar?.autoHide?.hoverRegionWidth ?? 0)
                        }
                    }

                    // 4.2) Contenido real de la barra
                    BarContent {
                        id: barContent
                        implicitHeight: Appearance.sizes.barHeight

                        // CORRECCIÓN: BarContent tiene `monitorIndex` pero aquí no se lo estabas pasando.
                        // Esto afecta el cálculo de hasActiveWindows en BarContent.
                        monitorIndex: barRoot.monitorIndex
                        screen: barRoot.screen

                        anchors {
                            left: parent.left
                            right: parent.right

                            top: barRoot.isBottom ? undefined : parent.top
                            bottom: barRoot.isBottom ? parent.bottom : undefined

                            topMargin: (!barRoot.isBottom && barRoot.autoHideEnabled && !barRoot.mustShow)
                                ? -Appearance.sizes.barHeight
                                : 0

                            bottomMargin: (barRoot.isBottom && barRoot.autoHideEnabled && !barRoot.mustShow)
                                ? -Appearance.sizes.barHeight
                                : ((barRoot.deadPixelFix && barRoot.anchors.bottom) * -1)

                            rightMargin: (barRoot.deadPixelFix && barRoot.anchors.right) * -1
                        }

                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    // =========================================================
                    // 5) Decoradores redondeados (cornerStyle Hug)
                    // =========================================================
                    Loader {
                        id: roundDecorators
                        active: barRoot.showBarBackground && (Config?.options?.bar?.cornerStyle === 0)
                        height: Appearance.rounding.screenRounding

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: barRoot.isBottom ? undefined : barContent.bottom
                            bottom: barRoot.isBottom ? barContent.top : undefined
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding

                            RoundCorner {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? barRoot.barBackgroundColorForCorners : "transparent"
                                corner: barRoot.isBottom
                                    ? RoundCorner.CornerEnum.BottomLeft
                                    : RoundCorner.CornerEnum.TopLeft
                            }

                            RoundCorner {
                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                implicitSize: Appearance.rounding.screenRounding
                                color: barRoot.showBarBackground ? barRoot.barBackgroundColorForCorners : "transparent"
                                corner: barRoot.isBottom
                                    ? RoundCorner.CornerEnum.BottomRight
                                    : RoundCorner.CornerEnum.TopRight
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // 6) IPC: control externo de la barra
    // =========================================================
    IpcHandler {
        target: "bar"
        function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close(): void { GlobalStates.barOpen = false }
        function open(): void { GlobalStates.barOpen = true }
    }

    // =========================================================
    // 7) Global shortcuts
    // =========================================================
    GlobalShortcut { name: "barToggle"; description: "Toggles bar on press"; onPressed: GlobalStates.barOpen = !GlobalStates.barOpen }
    GlobalShortcut { name: "barOpen"; description: "Opens bar on press"; onPressed: GlobalStates.barOpen = true }
    GlobalShortcut { name: "barClose"; description: "Closes bar on press"; onPressed: GlobalStates.barOpen = false }
}

