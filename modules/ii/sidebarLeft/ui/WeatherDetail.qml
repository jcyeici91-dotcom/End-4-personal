import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common.widgets

Item {
    id: root

    required property var theme      
    required property var model      

    implicitWidth: 210
    implicitHeight: 120

    readonly property color _surface: Qt.rgba(theme.colSurface.r, theme.colSurface.g, theme.colSurface.b, 0.60)
    readonly property color _border: Qt.rgba(255, 255, 255, 0.08)
    readonly property color _accent: theme.colAccent


    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 28  // Radio grande como las otras tarjetas
        color: root._surface
        border.width: 1
        border.color: root._border
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 24
            color: Qt.rgba(0, 0, 0, 0.25)
        }
    }

    // CONTENIDO
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // Icono + Temperatura
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            // Contenedor del Icono (Píldora Tonal)
            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                radius: 20
                // Color de acento muy suave (Tonal)
                color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.15)
                border.width: 1
                border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.25)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.model.weatherIconFromCode(root.model.weatherCode)
                    font.pixelSize: 28
                    color: root._accent
                }
            }

            // Textos Grandes
            ColumnLayout {
                spacing: -2
                Layout.fillWidth: true

                Text {
                    text: root.model.weatherTemp + "°C"
                    color: theme.colText
                    font.family: theme.fontMain
                    font.pixelSize: 26
                    font.weight: Font.Black
                }

                Text {
                    text: root.model.weatherCity
                    color: theme.colSubText
                    font.family: theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true } // Espaciador

        // Estado del clima (Texto inferior)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.05) // Fondo muy sutil
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                
                MaterialSymbol { 
                    text: "device_thermostat"
                    font.pixelSize: 14
                    color: theme.colSubText
                    opacity: 0.7
                }

                Text {
                    text: root.model.weatherCondition
                    color: theme.colSubText
                    font.family: theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }
    }
}
