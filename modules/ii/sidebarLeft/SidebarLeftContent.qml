// SidebarLeftContent.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

import qs.modules.common.widgets
import qs.modules.common

import "./ui" as UI
import "./pages" as Pages

Item {
    id: root
    required property var scopeRoot
    anchors.fill: parent

    property int sidebarPadding: 16

    UI.SidebarTheme { id: theme }

    property var tabButtonList: [
        { icon: "dashboard", name: "Sistema" },
        { icon: "translate", name: "Traductor" },
        { icon: "palette",   name: "Fondos" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.sidebarPadding
        spacing: 16

         Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 25
            
            color: Qt.rgba(0, 0, 0, 0.2)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol {
                    text: "auto_awesome"
                    font.pixelSize: 18
                    color: theme.colAccent
                }

                Text {
                    text: "Hakadosh Baruj Hu"
                    color: theme.colText
                    font.pixelSize: 14
                    font.bold: true
                    font.family: theme.fontMain
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 85
            radius: 24
            
            color: Qt.rgba(0, 0, 0, 0.15)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                Repeater {
                    model: root.tabButtonList
                    
                    delegate: Item {
                        id: navItem
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isActive: swipeView.currentIndex === index
                        readonly property bool isHovered: navMouse.containsMouse

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            // PÍLDORA (Icono)
                            Rectangle {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 32
                                radius: 16
                                
                                color: isActive ? theme.colAccent : "transparent"
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 20
                                    color: isActive ? theme.colBase : theme.colText
                                }
                            }

                            // TEXTO
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                font.family: theme.fontMain
                                font.pixelSize: 12
                                font.bold: isActive
                                color: isActive ? theme.colText : theme.colSubText
                                opacity: isActive ? 1.0 : 0.8
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: swipeView.currentIndex = index
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 28
            
          color: Qt.rgba(theme.colBase.r, theme.colBase.g, theme.colBase.b, 0.55)
            
            clip: true
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.08)

            SwipeView {
                id: swipeView
                anchors.fill: parent
                anchors.margins: 8
                
                interactive: true 
                orientation: Qt.Horizontal
                currentIndex: 0
                clip: true

                Pages.OverviewPage { theme: theme }
                Translator { }
                Pages.WallpapersPage { theme: theme }
            }
        }
     }
}
