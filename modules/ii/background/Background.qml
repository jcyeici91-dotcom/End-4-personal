pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot
        required property var modelData

        // =========================================================
        // 1) Bindings base / capa (layershell)
        // =========================================================
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:background"
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running)
            ? WlrLayer.Top
            : WlrLayer.Bottom

        anchors { top: true; bottom: true; left: true; right: true }

        // =========================================================
        // 2) Accesos a Config (NUEVO: helpers para robustez y menos repetición)
        // =========================================================
        readonly property var bgOpt: Config?.options?.background
        readonly property var barOpt: Config?.options?.bar
        readonly property var lockOpt: Config?.options?.lock
        readonly property var overviewOpt: Config?.options?.overview
        readonly property var workSafetyOpt: Config?.options?.workSafety

        // =========================================================
        // 3) Monitor/Workspaces + visible when fullscreen
        // =========================================================
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

        // Workspaces del monitor
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(ws =>
            ws.monitor && ws.monitor.name === monitor.name
        )

        // Workspace activo que tiene alguna ventana fullscreen
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(ws =>
            ws.active && (ws.toplevels.values.filter(w => w.wayland?.fullscreen)[0] !== undefined)
        )[0]

        // Visible si:
        // - pantalla bloqueada
        // - o no hay fullscreen en el workspace activo
        // - o la opción de ocultar al fullscreen está desactivada
        visible: GlobalStates.screenLocked
            || (activeWorkspaceWithFullscreen === undefined)
            || !(bgOpt?.hideWhenFullscreen === true) // NUEVO: optional chaining seguro

        // =========================================================
        // 4) Ventanas relevantes por monitor (para parallax por workspace)
        // =========================================================
        property list<var> relevantWindows: HyprlandData.windowList
            .filter(win => win.monitor === monitor?.id && win.workspace?.id >= 0)
            .sort((a, b) => (a.workspace?.id ?? 0) - (b.workspace?.id ?? 0))

        property int firstWorkspaceId: relevantWindows[0]?.workspace?.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace?.id || 10

        // =========================================================
        // 5) Wallpaper: path + seguridad + tamaño
        // =========================================================
        // CORRECCIÓN/ROBUSTEZ: evita crash si wallpaperPath es undefined
        readonly property string _wallpaperPathRaw: bgOpt?.wallpaperPath ?? ""
        readonly property string _thumbnailPathRaw: bgOpt?.thumbnailPath ?? ""

        property bool wallpaperIsVideo: (
            _wallpaperPathRaw.endsWith(".mp4")
            || _wallpaperPathRaw.endsWith(".webm")
            || _wallpaperPathRaw.endsWith(".mkv")
            || _wallpaperPathRaw.endsWith(".avi")
            || _wallpaperPathRaw.endsWith(".mov")
        )

        property string wallpaperPath: wallpaperIsVideo ? _thumbnailPathRaw : _wallpaperPathRaw

        property bool wallpaperSafetyTriggered: {
            const enabled = workSafetyOpt?.enable?.wallpaper === true;
            const wp = (bgRoot.wallpaperPath ?? "").toLowerCase();
            const nn = (Network.networkName ?? "").toLowerCase();

            const sensitiveWallpaper =
                CF.StringUtils.stringListContainsSubstring(wp, workSafetyOpt?.triggerCondition?.fileKeywords ?? []);
            const sensitiveNetwork =
                CF.StringUtils.stringListContainsSubstring(nn, workSafetyOpt?.triggerCondition?.networkNameKeywords ?? []);

            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }

        // Tamaños (init razonable)
        property int wallpaperWidth: modelData.width
        property int wallpaperHeight: modelData.height

        // Evitar divisiones raras si width/height son 0
        property real wallpaperToScreenRatio: Math.min(
            (wallpaperWidth > 0 ? wallpaperWidth / screen.width : 1),
            (wallpaperHeight > 0 ? wallpaperHeight / screen.height : 1)
        )

        property real preferredWallpaperScale: bgOpt?.parallax?.workspaceZoom ?? 1.0
        property real effectiveWallpaperScale: 1

        property real movableXSpace: ((wallpaperWidth / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.width) / 2
        property real movableYSpace: ((wallpaperHeight / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.height) / 2

        readonly property bool verticalParallax: (
            ((bgOpt?.parallax?.autoVertical === true) && wallpaperHeight > wallpaperWidth)
            || (bgOpt?.parallax?.vertical === true)
        )

        // =========================================================
        // 6) Colores / legibilidad (aquí es donde “adaptive” suele fallar)
        // =========================================================
        property bool shouldBlur: (GlobalStates.screenLocked && (lockOpt?.blur?.enable === true))
        property color dominantColor: Appearance.colors.colPrimary // default

        // NUEVO: detecta si dominante es oscura
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5

        // NUEVO (mejora adaptive sin romper): forzamos un mínimo de contraste
        // Idea: mantenemos tu lógica, pero si el color resultante queda demasiado cercano
        // a la luminosidad del wallpaper dominante, lo empujamos hacia colOnLayer0.
        property color colText: {
            if (wallpaperSafetyTriggered) {
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            }

            if (GlobalStates.screenLocked && shouldBlur) {
                return Appearance.colors.colOnLayer0;
            }

            // Tu cálculo original
            const base = CF.ColorUtils.colorWithLightness(
                Appearance.colors.colPrimary,
                (dominantColorIsDark ? 0.80 : 0.12)
            );

            // Ajuste suave: si el wallpaper es muy claro/oscuro, empuja un poco hacia colOnLayer0
            // (evita texto “lavado” en modo adaptive).
            const mixAmount = dominantColorIsDark ? 0.10 : 0.18; // NUEVO: valores conservadores
            return CF.ColorUtils.mix(base, Appearance.colors.colOnLayer0, mixAmount);
        }

        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // =========================================================
        // 7) Zoom/Overview animation
        // =========================================================
        property var zoomLevels: ({
            "in":  { default: 1.04, zoomed: 1 },
            "out": { default: 1,    zoomed: 1.04 }
        })

        readonly property bool zoomInStyle: (overviewOpt?.scrollingStyle?.zoomStyle === "in")
        readonly property bool showOpeningAnimation: (overviewOpt?.showOpeningAnimation === true)

        property real defaultRatio: zoomInStyle ? zoomLevels.in.default : zoomLevels.out.default
        property real zoomedRatio:  zoomInStyle ? zoomLevels.in.zoomed  : zoomLevels.out.zoomed

        property bool overviewOpen: GlobalStates.overviewOpen
        property real scaleAnimated: (overviewOpen && showOpeningAnimation) ? zoomedRatio : defaultRatio

        Behavior on scaleAnimated {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        // =========================================================
        // 8) Color de fondo del PanelWindow (cuando workSafetyTriggered)
        // =========================================================
        color: {
            if (!wallpaperSafetyTriggered || wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // =========================================================
        // 9) Wallpaper size probe (magick identify)
        // =========================================================
        onWallpaperPathChanged: bgRoot.updateZoomScale()

        function updateZoomScale() {
            // NUEVO: no correr identify si no hay path
            if (!bgRoot.wallpaperPath || bgRoot.wallpaperPath.length === 0) return;
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }

        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", path]

            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = (wallpaperSizeOutputCollector.text ?? "").trim();
                    const parts = output.split(" ").map(Number);
                    const width = parts[0];
                    const height = parts[1];

                    // NUEVO: validación para evitar NaN
                    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
                        return;
                    }

                    const screenWidth = bgRoot.screen.width;
                    const screenHeight = bgRoot.screen.height;

                    bgRoot.wallpaperWidth = width;
                    bgRoot.wallpaperHeight = height;

                    if (width <= screenWidth || height <= screenHeight) {
                        bgRoot.effectiveWallpaperScale = Math.max(screenWidth / width, screenHeight / height);
                    } else {
                        bgRoot.effectiveWallpaperScale = Math.min(
                            bgRoot.preferredWallpaperScale,
                            width / screenWidth,
                            height / screenHeight
                        );
                    }
                }
            }
        }

        // =========================================================
        // 10) Render wallpaper + blur + widgets
        // =========================================================
        Item {
            id: wallpaperItem
            anchors.fill: parent
            clip: true

            scale: (showOpeningAnimation && overviewOpen && (overviewOpt?.style === "scrolling"))
                ? zoomedRatio
                : defaultRatio

            Behavior on scale {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            // -------------------------
            // 10.1 Wallpaper image
            // -------------------------
            StyledImage {
                id: wallpaper

                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0

                cache: false
                smooth: false

                // Range = groups that workspaces span on
                property int chunkSize: (barOpt?.workspaces?.shown ?? 10)
                property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize
                property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize
                property int range: upper - lower

                property real valueX: {
                    let result = 0.5;

                    if ((bgOpt?.parallax?.enableWorkspace === true) && !bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    if (bgOpt?.parallax?.enableSidebar === true) {
                        result += (0.15 * GlobalStates.sidebarRightOpen - 0.15 * GlobalStates.sidebarLeftOpen);
                    }
                    return result;
                }

                property real valueY: {
                    let result = 0.5;
                    if ((bgOpt?.parallax?.enableWorkspace === true) && bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    return result;
                }

                property real effectiveValueX: Math.max(0, Math.min(1, valueX))
                property real effectiveValueY: Math.max(0, Math.min(1, valueY))

                x: -(bgRoot.movableXSpace) - (effectiveValueX - 0.5) * 2 * bgRoot.movableXSpace
                y: -(bgRoot.movableYSpace) - (effectiveValueY - 0.5) * 2 * bgRoot.movableYSpace

                source: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop

                Behavior on x {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                sourceSize {
                    width: bgRoot.screen.width * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
                    height: bgRoot.screen.height * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
                }

                width: bgRoot.wallpaperWidth / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
                height: bgRoot.wallpaperHeight / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
            }

            // -------------------------
            // 10.2 Blur when locked
            // -------------------------
            Loader {
                id: blurLoader
                active: (lockOpt?.blur?.enable === true) && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaper

                scale: GlobalStates.screenLocked ? (lockOpt?.blur?.extraZoom ?? 1) : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }

                sourceComponent: GaussianBlur {
                    source: wallpaper
                    radius: GlobalStates.screenLocked ? (lockOpt?.blur?.radius ?? 0) : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            // -------------------------
            // 10.3 Widgets canvas (parallax)
            // -------------------------
            WidgetCanvas {
                id: widgetCanvas

                scale: 1 - (defaultRatio - 1)
                Behavior on scale {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                anchors {
                    left: wallpaper.left
                    right: wallpaper.right
                    top: wallpaper.top
                    bottom: wallpaper.bottom
                    horizontalCenter: undefined
                    verticalCenter: undefined

                    readonly property real parallaxFactor: bgOpt?.parallax?.widgetsFactor ?? 1

                    leftMargin: {
                        const xOnWallpaper = bgRoot.movableXSpace;
                        const extraMove = (wallpaper.effectiveValueX * 2 * bgRoot.movableXSpace) * (parallaxFactor - 1);
                        return xOnWallpaper - extraMove;
                    }

                    topMargin: {
                        const yOnWallpaper = bgRoot.movableYSpace;
                        const extraMove = (wallpaper.effectiveValueY * 2 * bgRoot.movableYSpace) * (parallaxFactor - 1);
                        return yOnWallpaper - extraMove;
                    }

                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }

                width: wallpaper.width
                height: wallpaper.height

                states: State {
                    name: "centered"
                    when: GlobalStates.screenLocked || bgRoot.wallpaperSafetyTriggered

                    PropertyChanges { target: widgetCanvas; width: parent.width; height: parent.height }
                    AnchorChanges {
                        target: widgetCanvas
                        anchors {
                            left: undefined; right: undefined; top: undefined; bottom: undefined
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                // Weather
                FadeLoader {
                    shown: bgOpt?.widgets?.weather?.enable === true
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                    }
                }

                // Clock
                FadeLoader {
                    shown: bgOpt?.widgets?.clock?.enable === true
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }

                // Media (delayed load + hard reset)
                Timer {
                    id: mediaTimer
                    interval: 200
                    onTriggered: mediaLoader.enableLoading = true
                }

                FadeLoader {
                    id: mediaLoader
                    property bool enableLoading: true

                    shown: (bgOpt?.widgets?.media?.enable === true) && enableLoading

                    sourceComponent: MediaWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                    }

                    onLoaded: {
                        if (item && item.requestReset) {
                            item.requestReset.connect(() => { // hard reset
                                mediaLoader.enableLoading = false
                                mediaTimer.running = true
                            })
                        }
                    }
                }
            }
        }
      }
}

