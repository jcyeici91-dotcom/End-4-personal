pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    
    property real r: Appearance.rounding.windowRounding ?? 24
    property int viewState: 1 // 1 = Volumen/Brillo, 2 = Sesión
    
    // Ancho fijo y alto derivado de los layouts
    implicitWidth: 90
    implicitHeight: Math.max(slidersLayout.implicitHeight, sessionLayout.implicitHeight) + (r * 2) + 30

    // ==========================================
    // FONDO PEGADO AL BORDE (Tu diseño original)
    // ==========================================
    SessionBackground {
        anchors.fill: parent
        attachEdge: "right"
        rounding: root.r
    }
    
    // ==========================================
    // DETECTOR DE GESTOS (ARRASTRE Y SCROLL EN EL FONDO)
    // ==========================================
    // Esto te permite arrastrar o usar la rueda en el fondo vacío del panel para cambiar de menú.
    MouseArea {
        anchors.fill: parent
        property int startX: 0
        
        onPressed: (mouse) => { startX = mouse.x; }
        
        // Arrastrar de izquierda a derecha en el fondo vacío para cambiar de vista
        onPositionChanged: (mouse) => {
            if (pressed) {
                if (startX - mouse.x > 30) root.viewState = 2; // Arrastró hacia la izquierda -> Menú Sesión
                else if (mouse.x - startX > 30) root.viewState = 1; // Arrastró hacia la derecha -> Sliders
            }
        }
        
        // Rueda del ratón para cambiar de vista (cuando NO estás sobre las píldoras)
        onWheel: (wheel) => {
            if (wheel.angleDelta.y < 0) root.viewState = 2; // Scroll abajo -> Menú Sesión
            else root.viewState = 1; // Scroll arriba -> Sliders
        }
    }

    // ==========================================
    // VISTA 1: PÍLDORAS VERTICALES
    // ==========================================
    Item {
        id: slidersView
        anchors.fill: parent
        opacity: root.viewState === 1 ? 1 : 0
        visible: opacity > 0
        x: root.viewState === 1 ? 0 : -20 
        
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        ColumnLayout {
            id: slidersLayout
            anchors.centerIn: parent
            spacing: 24 

            // Píldora de Volumen (Arriba)
            ControlPill {
                Layout.alignment: Qt.AlignHCenter
                value: Audio.value
                iconName: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                onRequestChange: (newValue) => {
                    if (Audio.sink) Audio.sink.audio.volume = newValue;
                }
            }

            // Píldora de Brillo (Abajo)
            ControlPill {
                Layout.alignment: Qt.AlignHCenter
                value: Brightness.monitors.length > 0 ? Brightness.monitors[0].brightness : 0
                iconName: "light_mode"
                onRequestChange: (newValue) => {
                    if (Brightness.monitors.length > 0) Brightness.monitors[0].setBrightness(newValue);
                }
            }
        }
    }

    // ==========================================
    // VISTA 2: BOTONES DE SESIÓN (Visibles en cualquier tema)
    // ==========================================
    Item {
        id: sessionView
        anchors.fill: parent
        opacity: root.viewState === 2 ? 1 : 0
        visible: opacity > 0
        x: root.viewState === 2 ? 0 : 20 
        
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        ColumnLayout {
            id: sessionLayout
            anchors.centerIn: parent
            spacing: 16

            SessionButton { iconName: "lock"; command: "loginctl lock-session" }
            SessionButton { iconName: "logout"; command: "hyprctl dispatch exit" }
            SessionButton { iconName: "power_settings_new"; command: "systemctl poweroff" }
            
            // Un pequeño gif decorativo
            AnimatedImage {
                source: Qt.resolvedUrl("../../../assets/gifs/kurukuru.gif")
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
                playing: root.viewState === 2
            }

            SessionButton { iconName: "bedtime"; command: "systemctl suspend" }
            SessionButton { iconName: "restart_alt"; command: "systemctl reboot" }
        }
    }

    // ==========================================
    // COMPONENTE: PÍLDORA DESLIZABLE (Ajustada a la referencia y visible)
    // ==========================================
    component ControlPill: Item {
        id: pill
        property real value: 0
        property string iconName: ""
        
        signal requestChange(real newValue)

        implicitWidth: 44
        implicitHeight: 200 // Píldoras largas

        // Fondo de la píldora (Vacío, translúcido/gris claro)
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.05) // Gris muy translúcido
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            // Relleno coloreado (Barra que sube)
            Rectangle {
                id: pillFill
                width: parent.width
                height: Math.max(width, parent.height * pill.value) 
                anchors.bottom: parent.bottom
                radius: parent.width / 2
                color: Appearance.colors.colPrimary // Primary colored fill
            }
        }

        // Círculo interactivo que resalta (Como en tu foto de referencia)
        Rectangle {
            width: pill.width - 4
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(2, pill.height - pillFill.height + 2)
            
            color: Appearance.colors.colOnSurface // Circulo claro/blanco (Visible)
            Behavior on y { enabled: false } 

            MaterialSymbol {
                anchors.centerIn: parent
                text: pill.iconName
                font.pixelSize: 20
                color: Appearance.colors.colLayer0 // Icono oscuro
            }
        }

        // Control nativo de arrastre y scroll (Aislado)
        MouseArea {
            anchors.fill: parent
            preventStealing: true 
            
            function updateValue(mouseY) {
                let newValue = 1 - (mouseY / pill.height);
                newValue = Math.max(0, Math.min(1, newValue)); 
                pill.requestChange(newValue);
            }

            onPressed: (mouse) => updateValue(mouse.y)
            onPositionChanged: (mouse) => { if (pressed) updateValue(mouse.y) }
            
            // Atrapamos la rueda aquí para que cambie el valor y no cambie de vista
            onWheel: (wheel) => {
                wheel.accepted = true; // Evita que el fondo detecte este scroll
                if (wheel.angleDelta.y > 0) pill.requestChange(Math.min(1, pill.value + 0.05))
                else pill.requestChange(Math.max(0, pill.value - 0.05))
            }
        }
    }
}
