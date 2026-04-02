pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

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

    function toggleDetach() { root.detach = !root.detach; }

    Process {
        id: pinWithFunnyHyprlandWorkaroundProc
        property var hook: null
        property int cursorX
        property int cursorY

        function doIt() {
            command = ["hyprctl", "cursorpos"]
            hook = (output) => {
                cursorX = parseInt(output.split(",")[0])
                cursorY = parseInt(output.split(",")[1])
                doIt2()
            }
            running = true
        }

        function doIt2() {
            command = ["bash", "-c", "hyprctl dispatch movecursor 9999 9999"]
            hook = () => { doIt3() }
            running = true
        }

        function doIt3() {
            root.pin = !root.pin
            command = ["bash", "-c", `sleep 0.01; hyprctl dispatch movecursor ${cursorX} ${cursorY}`]
            hook = null
            running = true
        }

        stdout: StdioCollector {
            onStreamFinished: { pinWithFunnyHyprlandWorkaroundProc.hook(text) }
        }
    }

    function togglePin() {
        if (!root.pin) pinWithFunnyHyprlandWorkaroundProc.doIt()
        else root.pin = false
    }

    Component.onCompleted: {
        root.sidebarContent = contentComponent.createObject(null, { "scopeRoot": root })
        sidebarLoader.item.contentParent.children = [root.sidebarContent]
    }

    onDetachChanged: {
        if (root.detach) {
            sidebarContent.parent = null
            sidebarLoader.active = false
            detachedSidebarLoader.active = true
            detachedSidebarLoader.item.contentParent.children = [sidebarContent]
        } else {
            sidebarContent.parent = null
            detachedSidebarLoader.active = false
            sidebarLoader.active = true
            sidebarLoader.item.contentParent.children = [sidebarContent]
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
                const p = Config.options.policies
                const allFeatures = (p?.ai !== 0) && (p?.weeb === 1) && (p?.wallpapers !== 0) && (p?.translator !== 0)
                if (panelWindow.extend) return Appearance.sizes.sidebarWidthExtended
                return allFeatures ? Appearance.sizes.sidebarWidthExpanded : Appearance.sizes.sidebarWidth
            }

            property var contentParent: sidebarLeftContentContainer
            function hide() { GlobalStates.sidebarLeftOpen = false }

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.pin ? sidebarWidth : 0
            implicitWidth: sidebarWidth
            
            height: parent ? parent.height : 1080

            WlrLayershell.namespace: root.isOnLeft ? "quickshell:sidebarLeft" : "quickshell:sidebarRight"
            WlrLayershell.keyboardFocus: GlobalStates.sidebarLeftOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                left: root.isOnLeft
                right: !root.isOnLeft
                bottom: true
            }

            onVisibleChanged: {
                if (visible) GlobalFocusGrab.addDismissable(panelWindow)
                else         GlobalFocusGrab.removeDismissable(panelWindow)
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() { panelWindow.hide() }
            }

            Item {
                id: sidebarLeftBackground
                anchors.fill: parent

                Item {
                    id: sidebarLeftContentContainer
                    anchors.fill: parent
                }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) panelWindow.hide()
                if (event.modifiers === Qt.ControlModifier) {
                    if      (event.key === Qt.Key_O) panelWindow.extend = !panelWindow.extend
                    else if (event.key === Qt.Key_D) root.toggleDetach()
                    else if (event.key === Qt.Key_P) root.togglePin()
                    event.accepted = true
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
                if (!visible) GlobalStates.sidebarLeftOpen = false
            }

            Rectangle {
                id: detachedSidebarBackground
                anchors.fill: parent
                radius: Appearance.rounding.screenRounding
                antialiasing: true
                clip: true
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                Item {
                    id: detachedSidebarContentContainer
                    anchors.fill: parent
                    z: 10
                }

                Keys.onPressed: (event) => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_D) root.toggleDetach()
                        event.accepted = true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
        function close():  void { GlobalStates.sidebarLeftOpen = false }
        function open():   void { GlobalStates.sidebarLeftOpen = true  }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: "Opens left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = true }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: "Closes left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = false }
    }

    GlobalShortcut {
        name: "sidebarLeftToggleDetach"
        description: "Detach left sidebar into a window/Attach it back"
        onPressed: { root.detach = !root.detach }
    }
}
