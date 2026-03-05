import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets    // MaterialSymbol

import "./" as W

Rectangle {
    id: pill

    required property var theme
    required property color smartText
    required property color smartTextMuted
    required property color surface1
    required property color border0

    property string icon: ""
    property string title: ""
    property string val: ""
    property string sub: ""
    property real prog: 0.0
    property bool isGauge: true
    property color tint: "#40c4ff"

    Layout.fillWidth: true
    Layout.preferredHeight: 68

    radius: 22
    color: surface1
    border.width: 1
    border.color: border0
    clip: true

    readonly property int badgeMaxW: 170

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 20
        spacing: 14

        Rectangle {
            width: 42
            height: 42
            radius: 21
            color: Qt.rgba(pill.tint.r, pill.tint.g, pill.tint.b, 0.20)

            MaterialSymbol {
                anchors.centerIn: parent
                text: pill.icon
                font.pixelSize: 22
                color: pill.tint
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: (String(pill.sub || "").trim().length > 0) ? 4 : 2

            Text {
                text: pill.title
                color: pill.smartText
                font.bold: true
                font.pixelSize: 13
                font.family: pill.theme.fontMain
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            W.MarqueeText {
                Layout.fillWidth: true
                visible: String(pill.sub || "").trim().length > 0
                Layout.preferredHeight: visible ? 16 : 0
                text: pill.sub
                color: pill.smartTextMuted
                font.pixelSize: 11
                font.family: pill.theme.fontMain
            }

            Rectangle {
                visible: pill.isGauge
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(pill.smartText.r, pill.smartText.g, pill.smartText.b, 0.10)

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(Math.max(pill.prog, 0), 1)
                    radius: 3
                    color: pill.tint
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                }
            }

            Item { visible: !pill.isGauge; Layout.preferredHeight: 6 }
        }

        Item {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.minimumWidth: 40
            Layout.preferredHeight: 30

            Text {
                visible: pill.isGauge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(90, parent.width > 0 ? parent.width : 90)
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: pill.val
                color: pill.smartText
                font.pixelSize: 15
                font.bold: true
                font.family: pill.theme.fontMain
            }

            Rectangle {
                id: badge
                visible: !pill.isGauge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(badgeText.implicitWidth + 24, pill.badgeMaxW)
                height: 28
                radius: 14
                color: Qt.rgba(pill.tint.r, pill.tint.g, pill.tint.b, 0.20)
                border.width: 1
                border.color: Qt.rgba(pill.tint.r, pill.tint.g, pill.tint.b, 0.55)
                clip: true

                SequentialAnimation on border.color {
                    loops: Animation.Infinite
                    ColorAnimation { to: Qt.rgba(pill.tint.r, pill.tint.g, pill.tint.b, 1.0); duration: 2000; easing.type: Easing.InOutSine }
                    ColorAnimation { to: Qt.rgba(pill.tint.r, pill.tint.g, pill.tint.b, 0.40); duration: 2000; easing.type: Easing.InOutSine }
                }

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    width: parent.width - 18
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: pill.val
                    color: pill.smartText
                    font.pixelSize: 13
                    font.bold: true
                    font.family: pill.theme.fontMain
                }
            }
        }
    }
}

