import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.ui 1.0
import "../bar" as Bar

Scope {
    id: root
    property bool detach: false
    property bool pin: false
    property Component contentComponent: SidebarPoliciesContent {}
    property Item sidebarContent

    readonly property bool isOnLeft: {
        const pos = Config.options.sidebar.position;
        return pos === "default" || pos === "left";
    }

    // ==========================
    // LÓGICA DE ESTILO (igual que derecha)
    // ==========================
    readonly property bool safeNoEffects: false
    readonly property bool _configReady: (typeof Config !== "undefined") && Config && (Config.ready === true)
    readonly property var _opts: ((typeof Config !== "undefined") && Config) ? Config.options : null
    readonly property bool followGlobalSidebarStyle: (_opts?.sidebar?.followGlobalSidebarStyle ?? false)

    readonly property int styleIntFromConfig: {
        const o = _opts
        if (o?.sidebar?.dashboardRightBackgroundStyle !== undefined) return o.sidebar.dashboardRightBackgroundStyle
        if (o?.sidebar?.rightBackgroundStyle !== undefined) return o.sidebar.rightBackgroundStyle
        if (o?.sidebar?.sidebarBackgroundStyle !== undefined) return o.sidebar.sidebarBackgroundStyle
        if (o?.sidebar?.backgroundStyle !== undefined) return o.sidebar.backgroundStyle
        if (o?.bar?.barBackgroundStyle !== undefined) return o.bar.barBackgroundStyle
        return 1
    }

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _normalizeStyle(v) {
        if (typeof v === "number") return _styleFromConfig(v)
        if (typeof v !== "string") return "solid"
        const s = v.toLowerCase().trim()
        if (s === "visible") return "solid"
        if (s === "transparent") return "glass"
        return s
    }

    function _effectiveSidebarStyle(requested) {
        const s = _normalizeStyle(requested)
        if (s === "solid" || s === "glass") return "visible"
        if (s === "crystal") return "crystal"
        if (s === "adaptive") {
            const hw = (typeof UIState !== "undefined" && UIState && UIState.hasWindows !== undefined)
                ? UIState.hasWindows
                : false
            return hw ? "visible" : "crystal"
        }
        return "visible"
    }

    readonly property var requestedStyle: followGlobalSidebarStyle
        ? ((typeof UIState !== "undefined" && UIState) ? UIState.surfaceStyle : "solid")
        : _styleFromConfig(styleIntFromConfig)

    readonly property string sidebarStyle: _effectiveSidebarStyle(requestedStyle)
    readonly property bool bgIsVisible: sidebarStyle === "visible"
    readonly property bool bgIsCrystal: sidebarStyle === "crystal"

    function toggleDetach() { root.detach = !root.detach; }

    Process {
        id: pinWithFunnyHyprlandWorkaroundProc
        property var hook: null
        property int cursorX
        property int cursorY

        function doIt() {
            command = ["hyprctl", "cursorpos"]
            hook = (output) => {
                cursorX = parseInt(output.split(",")[0]);
                cursorY = parseInt(output.split(",")[1]);
                doIt2();
            }
            running = true;
        }
        function doIt2(output) {
            command = ["bash", "-c", "hyprctl dispatch movecursor 9999 9999"];
            hook = () => { doIt3(); }
            running = true;
        }
        function doIt3(output) {
            root.pin = !root.pin;
            command = ["bash", "-c", `sleep 0.01; hyprctl dispatch movecursor ${cursorX} ${cursorY}`];
            hook = null
            running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: { pinWithFunnyHyprlandWorkaroundProc.hook(text); }
        }
    }

    function togglePin() {
        if (!root.pin) pinWithFunnyHyprlandWorkaroundProc.doIt()
        else root.pin = !root.pin;
    }

    Component.onCompleted: {
        root.sidebarContent = contentComponent.createObject(null, { "scopeRoot": root });
        sidebarLoader.item.contentParent.children = [root.sidebarContent];
    }

    onDetachChanged: {
        if (root.detach) {
            sidebarContent.parent = null;
            sidebarLoader.active = false;
            detachedSidebarLoader.active = true;
            detachedSidebarLoader.item.contentParent.children = [sidebarContent];
        } else {
            sidebarContent.parent = null;
            detachedSidebarLoader.active = false;
            sidebarLoader.active = true;
            sidebarLoader.item.contentParent.children = [sidebarContent];
        }
    }

    Loader {
        id: sidebarLoader
        active: true

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: GlobalStates.sidebarLeftOpen

            property bool extend: false
            readonly property real sidebarWidth: {
                const p = Config.options.policies;
                const allFeatures = p.ai !== 0 && p.weeb == 1 && p.wallpapers !== 0 && p.translator !== 0;

                if (panelWindow.extend) return Appearance.sizes.sidebarWidthExtended;
                return allFeatures ? Appearance.sizes.sidebarWidthExpanded : Appearance.sizes.sidebarWidth;
            }

            // Contenedor interno
            property var contentParent: sidebarLeftContentContainer

            function hide() { GlobalStates.sidebarLeftOpen = false }

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.pin ? sidebarWidth : 0
            implicitWidth: Appearance.sizes.sidebarWidthExtended + Appearance.sizes.elevationMargin

            // Namespace correcto para tus layerrules
            WlrLayershell.namespace: root.isOnLeft ? "quickshell:sidebarLeft" : "quickshell:sidebarRight"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                left: root.isOnLeft
                right: !root.isOnLeft
                bottom: true
            }

            // Recorte por máscara
            mask: Region { item: sidebarLeftBackground }

            onVisibleChanged: {
                if (visible) GlobalFocusGrab.addDismissable(panelWindow);
                else GlobalFocusGrab.removeDismissable(panelWindow);
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() { panelWindow.hide(); }
            }

            StyledRectangularShadow {
                target: sidebarLeftBackground
                radius: sidebarLeftBackground.radius
            }

            Rectangle {
                id: sidebarLeftBackground

                radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
                antialiasing: true
                clip: true

                // EXACTO como tu sidebar derecho:
                // - Visible: sólido normal
                // - Crystal: 100% transparente (sin neblina)
                color: root.bgIsVisible ? Appearance.colors.colLayer0 : "transparent"

                border.width: root.bgIsVisible ? 1 : 0
                border.color: Appearance.colors.colLayer0Border

                height: parent.height - (Appearance.sizes.hyprlandGapsOut * 2)
                y: Appearance.sizes.hyprlandGapsOut
                width: panelWindow.sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin

                Behavior on width {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                // ==============================================================
                // CRISTAL INVISIBLE 100% PURO (igual que el derecho)
                // ==============================================================
                Item {
                    anchors.fill: parent
                    visible: root.bgIsCrystal && !root.safeNoEffects

                    // 1) Borde exterior
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Appearance.colors.isDark
                            ? Qt.rgba(0, 0, 0, 0.45)
                            : Qt.rgba(0, 0, 0, 0.15)
                    }

                    // 2) Bisel interno
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, parent.radius - 1)
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? 0.15 : 0.40)
                    }

                    // 3) Highlight superior
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: parent.radius > 0 ? parent.radius / 1.2 : 1
                        anchors.rightMargin: parent.radius > 0 ? parent.radius / 1.2 : 1
                        anchors.topMargin: 1
                        height: 1
                        color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? 0.35 : 0.70)
                    }
                }

                // CONTENEDOR INTERNO PARA EL CONTENIDO
                Item {
                    id: sidebarLeftContentContainer
                    anchors.fill: parent
                }

                state: root.isOnLeft ? "left" : "right"
                states: [
                    State {
                        name: "left"
                        AnchorChanges {
                            target: sidebarLeftBackground
                            anchors.left: parent.left
                            anchors.right: undefined
                        }
                        PropertyChanges {
                            target: sidebarLeftBackground
                            anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
                            anchors.rightMargin: 0
                        }
                    },
                    State {
                        name: "right"
                        AnchorChanges {
                            target: sidebarLeftBackground
                            anchors.left: undefined
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: sidebarLeftBackground
                            anchors.rightMargin: Appearance.sizes.hyprlandGapsOut
                            anchors.leftMargin: 0
                        }
                    }
                ]

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) panelWindow.hide();

                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_O) panelWindow.extend = !panelWindow.extend;
                        else if (event.key === Qt.Key_D) root.toggleDetach();
                        else if (event.key === Qt.Key_P) root.togglePin();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    Loader {
        id: detachedSidebarLoader
        active: false

        sourceComponent: FloatingWindow {
            id: detachedSidebarRoot
            property var contentParent: detachedSidebarContentContainer
            color: "transparent"

            visible: GlobalStates.sidebarLeftOpen
            onVisibleChanged: {
                if (!visible) GlobalStates.sidebarLeftOpen = false;
            }

            Rectangle {
                id: detachedSidebarBackground
                anchors.fill: parent

                radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
                antialiasing: true
                clip: true

                color: root.bgIsVisible ? Appearance.colors.colLayer0 : "transparent"
                border.width: root.bgIsVisible ? 1 : 0
                border.color: Appearance.colors.colLayer0Border

                // Cristal puro también en modo detach
                Item {
                    anchors.fill: parent
                    visible: root.bgIsCrystal && !root.safeNoEffects

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Appearance.colors.isDark
                            ? Qt.rgba(0, 0, 0, 0.45)
                            : Qt.rgba(0, 0, 0, 0.15)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, parent.radius - 1)
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? 0.15 : 0.40)
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: parent.radius > 0 ? parent.radius / 1.2 : 1
                        anchors.rightMargin: parent.radius > 0 ? parent.radius / 1.2 : 1
                        anchors.topMargin: 1
                        height: 1
                        color: Qt.rgba(1, 1, 1, Appearance.colors.isDark ? 0.35 : 0.70)
                    }
                }

                Item {
                    id: detachedSidebarContentContainer
                    anchors.fill: parent
                }

                Keys.onPressed: (event) => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_D) root.toggleDetach();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
        function close(): void { GlobalStates.sidebarLeftOpen = false }
        function open(): void { GlobalStates.sidebarLeftOpen = true }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen; }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: "Opens left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = true; }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: "Closes left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = false; }
    }

    GlobalShortcut {
        name: "sidebarLeftToggleDetach"
        description: "Detach left sidebar into a window/Attach it back"
        onPressed: { root.detach = !root.detach; }
    }
}

