pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.waffle.looks

WButton {
    id: root
    
    // Dimensiones del botón
    implicitHeight: 40
    implicitWidth: contentItem.implicitWidth + 30
    color: "transparent"

    // Contenido del botón
    contentItem: Item {
        id: contentItem
        anchors.centerIn: parent
        implicitWidth: buttonText.implicitWidth

        WText {
            id: buttonText
            anchors.centerIn: parent
            text: root.text
            
            // Color del texto con transición suave
            color: root.pressed ? Looks.colors.fg : Looks.colors.fg1
            
            // Comportamiento de animación para el color del texto
            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Transición suave en el estado de presión
    Behavior on pressed {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // Efecto de sombra al pasar el mouse
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Acciones al hacer clic
        }
        onPressed: {
            root.pressed = true;
        }
        onReleased: {
            root.pressed = false;
        }
        onClicked: {
            // Acciones adicionales si se requiere
        }
    }
}

