import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import qs.modules.common           
import qs.modules.common.widgets    
import qs.services                 

import "../widgets" as W

Item {
    id: block

    required property var theme
    required property var dashboard

    // --- Config propia del bloque
    readonly property int heightBlock: 160
    readonly property int spacingCards: 12

    //  el root es el que participa en ColumnLayout
    implicitHeight: heightBlock
    implicitWidth: 460

    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border

    function getLuminance(c) { return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b }
    readonly property bool isDark: getLuminance(surface1) < 0.5

readonly property color smartAccent: Appearance.colors.colPrimary
readonly property color smartText: Appearance.colors.colOnLayer1
readonly property color smartTextMuted: Appearance.colors.colSubtext

    // Header 
    Flickable {
        id: headerFlick
        anchors.fill: parent

        // CLAVE: 
        clip: true

        boundsBehavior: Flickable.StopAtBounds

        contentWidth: headerRow.implicitWidth
        contentHeight: height

        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        RowLayout {
            id: headerRow
            height: block.heightBlock
            spacing: block.spacingCards

            // ─── RELOJ ───
            Rectangle {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                radius: 32
                color: block.surface1
                border.width: 1
                border.color: block.border0
                clip: true

                SequentialAnimation on border.color {
                    loops: Animation.Infinite
                    ColorAnimation {
                        to: Qt.rgba(block.smartAccent.r, block.smartAccent.g, block.smartAccent.b, 0.5)
                        duration: 3000
                        easing.type: Easing.InOutSine
                    }
                    ColorAnimation {
                        to: block.border0
                        duration: 3000
                        easing.type: Easing.InOutSine
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 0

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: dashboard.timeHour
                            font.pixelSize: 68
                            font.family: block.theme.fontMain
                            font.weight: Font.Black
                            color: block.smartText

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                shadowBlur: 0.8
                                shadowVerticalOffset: 2
                            }
                        }

                        Text {
                            text: ":"
                            font.pixelSize: 64
                            font.family: block.theme.fontMain
                            color: block.smartTextMuted
                            Layout.bottomMargin: 6

                            OpacityAnimator on opacity {
                                from: 1.0
                                to: 0.5
                                duration: 1000
                                loops: Animation.Infinite
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Text {
                            text: dashboard.timeMin
                            font.pixelSize: 68
                            font.family: block.theme.fontMain
                            font.weight: Font.Black
                            color: block.smartAccent

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                shadowBlur: 0.8
                                shadowVerticalOffset: 2
                            }
                        }

                        Text {
                            text: dashboard.timeSec
                            font.pixelSize: 32
                            font.family: block.theme.fontMain
                            font.weight: Font.Bold
                            color: block.smartTextMuted
                            Layout.alignment: Qt.AlignBaseline
                            Layout.bottomMargin: 9
                        }
                    }

                    // FECHA
                    W.MarqueeText {
                        Layout.topMargin: 4
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        text: dashboard.dateString
                        font.pixelSize: 14
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        color: block.smartText
                        centered: true
                    }
                }
            }

            // ─── CLIMA ───
            Rectangle {
                Layout.preferredWidth: 160
                Layout.fillHeight: true
                radius: 32
                color: block.surface1
                border.width: 1
                border.color: block.border0
                clip: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: dashboard.weatherIconFromCode(dashboard.weatherCode)
                        font.pixelSize: 42
                        color: block.smartAccent

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.3)
                            shadowBlur: 0.5
                        }

                        SequentialAnimation on anchors.verticalCenterOffset {
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: -3; duration: 2500; easing.type: Easing.InOutSine }
                            NumberAnimation { from: -3; to: 0; duration: 2500; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: dashboard.weatherTemp
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        font.family: block.theme.fontMain
                        color: block.smartText
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        W.MarqueeText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            text: dashboard.weatherCity
                            font.bold: true
                            font.pixelSize: 13
                            color: block.smartText
                            centered: true
                        }

                        W.MarqueeText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            text: dashboard.weatherCondition
                            font.pixelSize: 12
                            color: block.smartTextMuted
                            centered: true
                        }
                    }
                }
            }
        }
    }
}

