import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    Item {
        id: contentContainer
        // Ajustamos el padding horizontal a 24px (12 por lado) en vez de 32
        implicitWidth: mainLayout.implicitWidth + 24
        implicitHeight: mainLayout.implicitHeight + 32

        ColumnLayout {
            id: mainLayout
            anchors.centerIn: parent
            spacing: 12 // Reducido ligeramente para compactar verticalmente

            // =========================
            // 1. Cabecera (Big Weather)
            // =========================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter // Centra todo el bloque de cabecera
                spacing: 4

                // BLOQUE CIUDAD (Centrado forzoso)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30 // Altura suficiente para el texto e icono
                    
                    RowLayout {
                        anchors.centerIn: parent // Esto garantiza el centrado absoluto
                        spacing: 6
                        
                        MaterialSymbol {
                            text: "location_on"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Weather.data.city
                            font.weight: Font.DemiBold
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnSurface
                        }
                    }
                }

                // Temperatura y Estado
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    MaterialSymbol {
                        text: "wb_sunny"
                        iconSize: 56 // Reducido un pelín (de 64) para balancear
                        color: Appearance.colors.colOnSurface
                    }
                    ColumnLayout {
                        spacing: -4 // Juntamos un poco número y texto
                        StyledText {
                            text: Weather.data.temp
                            font.weight: Font.Bold
                            font.pixelSize: 42 // Reducido un pelín (de 48)
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            text: Weather.data.condition ? Weather.data.condition : "Current"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.8
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Appearance.colors.colOutline
                opacity: 0.15
                Layout.topMargin: 2
                Layout.bottomMargin: 2
            }

            // =========================
            // 2. Rejilla de Detalles
            // =========================
            GridLayout {
                id: detailsGrid
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                uniformCellWidths: true
                // Quitamos Layout.fillWidth para que el grid dicte el ancho mínimo (compacto)
                Layout.alignment: Qt.AlignHCenter 

                component DetailCard: Rectangle {
                    id: dCard
                    
                    // ANCHO AJUSTADO: Bajamos de 150 a 130 para hacerlo más estrecho
                    Layout.preferredWidth: 110
                    Layout.minimumWidth: 100 
                    
                    Layout.preferredHeight: 60 // Reducido de 64
                    color: Qt.rgba(1, 1, 1, 0.03)
                    radius: 14
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    
                    property string title: ""
                    property string value: ""
                    property string icon: ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10 // Margen interno reducido
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.1)
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: dCard.icon
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            StyledText {
                                text: dCard.title
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                                opacity: 0.8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: dCard.value
                                font.weight: Font.DemiBold
                                font.pixelSize: Appearance.font.pixelSize.normal 
                                color: Appearance.colors.colOnSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true 
                            }
                        }
                    }
                }

                DetailCard { title: Translation.tr("Wind"); icon: "air"; value: Weather.data.wind } // Quitamos dirección para ahorrar espacio si quieres, o déjala: Weather.data.wind + " (" + Weather.data.windDir + ")"
                DetailCard { title: Translation.tr("Humidity"); icon: "humidity_percentage"; value: Weather.data.humidity }
                DetailCard { title: Translation.tr("UV Index"); icon: "wb_sunny"; value: Weather.data.uv }
                DetailCard { title: Translation.tr("Pressure"); icon: "compress"; value: Weather.data.press }
                DetailCard { title: Translation.tr("Visibility"); icon: "visibility"; value: Weather.data.visib }
                DetailCard { title: Translation.tr("Precipitation"); icon: "rainy"; value: Weather.data.precip }
            }

            // =========================
            // 3. Footer
            // =========================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48 // Reducido de 56
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.08)
                radius: 14
                Layout.topMargin: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    
                    RowLayout {
                        spacing: 6
                        MaterialSymbol { text: "wb_twilight"; color: "#FFA726"; iconSize: 20 } 
                        StyledText { text: Weather.data.sunrise; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.normal }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 6
                        StyledText { text: Weather.data.sunset; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.normal }
                        MaterialSymbol { text: "bedtime"; color: "#7E57C2"; iconSize: 20 } 
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                text: Translation.tr("Updated: %1").arg(Weather.data.lastRefresh)
                font.pixelSize: 10 // Fuente muy pequeña para info técnica
                color: Appearance.colors.colOnSurfaceVariant
                opacity: 0.5
            }
        }
    }
}
