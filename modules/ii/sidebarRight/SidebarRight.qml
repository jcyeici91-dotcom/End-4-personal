import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.sidebarRightOpen

        function hide() {
            GlobalStates.sidebarRightOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:sidebarRight"
        // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
        // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        
        // La ventana base debe ser transparente
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        // [NUEVO CONTENEDOR DE FONDO]
        // Este rectángulo proveerá el color base y la transparencia necesaria para el blur.
        Rectangle {
            id: sidebarBackgroundContainer
            
            // Aplicamos aquí los márgenes que antes tenía el Loader
            anchors {
                fill: parent
                margins: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }

            // [COLOR MÁGICO] Usamos el color del tema pero con 65% de opacidad (0.65)
            // Esto permite que Hyprland desenfoque lo que hay detrás.
            color: Qt.rgba(
                Appearance.colors.colLayer0.r, 
                Appearance.colors.colLayer0.g, 
                Appearance.colors.colLayer0.b, 
                0.65
            )

            // Bordes y redondeo consistentes con el tema
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

            // El cargador de contenido ahora vive DENTRO del fondo transparente
            Loader {
                id: sidebarContentLoader
                active: GlobalStates.sidebarRightOpen || Config?.options.sidebar.keepRightSidebarLoaded
                
                // Ahora simplemente llena el contenedor
                anchors.fill: parent

                focus: GlobalStates.sidebarRightOpen
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        panelWindow.hide();
                    }
                }

                sourceComponent: SidebarRightContent {}
            }
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = true;
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = false;
        }
    }
}
