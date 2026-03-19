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
    
    // INTERRUPTOR MAESTRO 
    property bool enableAnimations: Config.options.appearance.enableAnimations

    property real r: Appearance.rounding.windowRounding ?? 24
    property int viewState: 1 // 1 = Volumen/Brillo, 2 = Sesión
    
    implicitWidth: 90
    implicitHeight: Math.max(slidersLayout.implicitHeight, sessionLayout.implicitHeight) + (r * 2) + 30

     // FONDO PEGADO AL BORDE
        SessionBackground {
        anchors.fill: parent
        attachEdge: "right"
        rounding: root.r
    }
    
      // DETECTOR DE GESTOS (ARRASTRE Y SCROLL)
      MouseArea {
        anchors.fill: parent
        property int startX: 0
        
        onPressed: (mouse) => { startX = mouse.x; }
        
        onPositionChanged: (mouse) => {
            if (pressed) {
                if (startX - mouse.x > 30) root.viewState = 2; 
                else if (mouse.x - startX > 30) root.viewState = 1; 
            }
        }
        
        onWheel: (wheel) => {
            if (wheel.angleDelta.y < 0) root.viewState = 2; 
            else root.viewState = 1; 
        }
    }

  
    // PÍLDORAS VERTICALES
      Item {
        id: slidersView
        width: parent.width
        height: parent.height
        opacity: root.viewState === 1 ? 1 : 0
        visible: opacity > 0
        x: root.viewState === 1 ? 0 : -20 
        
        Behavior on opacity { 
            enabled: root.enableAnimations
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
        }
        Behavior on x { 
            enabled: root.enableAnimations
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
        }

        ColumnLayout {
            id: slidersLayout
            anchors.centerIn: parent
            spacing: 24 

            // PÍLDORA DE VOLUMEN 
            ControlPill {
                Layout.alignment: Qt.AlignHCenter
                value: Audio.value
                iconName: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                
                onRequestChange: (newValue) => {
                    if (Audio.sink) Audio.sink.audio.volume = newValue;
                }
                
                onIconClicked: () => {
                    Audio.toggleMute();
                }
            }

            // PÍLDORA DE BRILLO + LUZ NOCTURNA
            ControlPill {
                Layout.alignment: Qt.AlignHCenter
                value: Brightness.monitors.length > 0 ? Brightness.monitors[0].brightness : 0
                iconName: Hyprsunset.active ? "nightlight" : "light_mode"
                
                onRequestChange: (newValue) => {
                    //Ajusta el brillo
                    if (Brightness.monitors.length > 0) {
                        Brightness.monitors[0].setBrightness(newValue);
                    }
                    
                    // luz nocturna está activa, ajusta la temperatura al MISMO porcentaje
                    if (Hyprsunset.active) {
                        // 100% de slider (1.0) = 100% de calidez (2500K)
                        // 0% de slider (0.0) = 0% de calidez (6500K)
                        let newTemp = 6500 - Math.round(4000 * newValue);
                        Config.options.light.night.colorTemperature = newTemp;
                    }
                }
                
                // clic sobre la burbuja del icono
                onIconClicked: () => {
                    if (!Hyprsunset.active) {
                        //  la temperatura al nivel actual del brillo ANTES de encenderla
                        let currentBright = Brightness.monitors.length > 0 ? Brightness.monitors[0].brightness : 0;
                        let newTemp = 6500 - Math.round(4000 * currentBright);
                        Config.options.light.night.colorTemperature = newTemp;
                    }
                    // Encendemos o apagamos el servicio
                    Hyprsunset.toggle();
                }
            }
        }
    }

    // BOTONES DE SESIÓN 
      Item {
        id: sessionView
        width: parent.width
        height: parent.height
        opacity: root.viewState === 2 ? 1 : 0
        visible: opacity > 0
        x: root.viewState === 2 ? 0 : 20 
        
        Behavior on opacity { 
            enabled: root.enableAnimations
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
        }
        Behavior on x { 
            enabled: root.enableAnimations
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
        }

        ColumnLayout {
            id: sessionLayout
            anchors.centerIn: parent
            spacing: 16

            SessionButton { iconName: "lock"; command: "loginctl lock-session" }
            SessionButton { iconName: "logout"; command: "hyprctl dispatch exit" }
            SessionButton { iconName: "power_settings_new"; command: "systemctl poweroff" }
            
            AnimatedImage {
                source: Qt.resolvedUrl("../../../assets/gifs/kurukuru.gif")
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
                playing: root.viewState === 2 && root.enableAnimations // Detiene el GIF cuando se desactivan las animaciones
                visible: root.enableAnimations // Lo oculta para que no quede estático de forma fea
            }

            SessionButton { iconName: "bedtime"; command: "systemctl suspend" }
            SessionButton { iconName: "restart_alt"; command: "systemctl reboot" }
        }
    }

    // PÍLDORA DESLIZABLE
    component ControlPill: Item {
        id: pill
        property real value: 0
        property string iconName: ""
        
        signal requestChange(real newValue)
        signal iconClicked() 

        implicitWidth: 44
        implicitHeight: 200

        // Fondo de la píldora
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.05) 
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            // Relleno coloreado
            Rectangle {
                id: pillFill
                width: parent.width
                height: Math.max(width, parent.height * pill.value) 
                anchors.bottom: parent.bottom
                radius: parent.width / 2
                color: Appearance.colors.colPrimary 
            }
        }

        // Círculo interactivo que resalta
        Rectangle {
            id: thumbCircle
            width: pill.width - 4
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(2, pill.height - pillFill.height + 2)
            
            color: Appearance.colors.colOnSurface 
            Behavior on y { enabled: false } 

            MaterialSymbol {
                anchors.centerIn: parent
                text: pill.iconName
                font.pixelSize: 20
                color: Appearance.colors.colLayer0 
            }
        }

        // Lógica de Interacción Táctil y Ratón
        MouseArea {
            anchors.fill: parent
            preventStealing: true 
            
            property bool isDragging: false
            property bool isThumbPress: false
            
            function updateValue(mouseY) {
                let newValue = 1 - (mouseY / pill.height);
                newValue = Math.max(0, Math.min(1, newValue)); 
                pill.requestChange(newValue);
            }

            onPressed: (mouse) => {
                isDragging = false;
                
                let thumbY = thumbCircle.y;
                let thumbBottom = thumbY + thumbCircle.height;
                
                if (mouse.y >= thumbY && mouse.y <= thumbBottom) {
                    isThumbPress = true; // Tocó el icono
                } else {
                    isThumbPress = false; // Tocó el track
                    updateValue(mouse.y);
                }
            }
            
            onPositionChanged: (mouse) => { 
                if (pressed) {
                    isDragging = true;
                    updateValue(mouse.y);
                } 
            }
            
            onReleased: (mouse) => {
                if (isThumbPress && !isDragging) {
                    pill.iconClicked();
                }
            }
            
            onWheel: (wheel) => {
                wheel.accepted = true; 
                if (wheel.angleDelta.y > 0) pill.requestChange(Math.min(1, pill.value + 0.05))
                else pill.requestChange(Math.max(0, pill.value - 0.05))
            }
        }
    }
}
