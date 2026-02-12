import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets

Rectangle {
    id: cardRoot
    required property var theme

    property string icon: "info"
    property string val: ""
    property string label: ""
    property string detail: ""

    function parsePercentage(valueString) {
        if (!valueString) return 0
        var num = parseFloat(("" + valueString).replace(/[^0-9.]/g, ""))
        if (isNaN(num)) return 0
        return Math.max(0, Math.min(1, num / 100))
    }

    readonly property bool hasProgress:
        (val && val.indexOf("%") !== -1) ||
        (val && val.indexOf("°") !== -1) ||
        (detail && detail.indexOf("%") !== -1)

    readonly property real progressValue:
        (detail && detail.indexOf("%") !== -1) ? parsePercentage(detail) : parsePercentage(val)

    Layout.fillWidth: true
    Layout.minimumWidth: 0

     Layout.preferredHeight: (detail && detail.length > 0) ? 98 : 85

    radius: 20
    color: mouseArea.containsMouse ? theme.colSurfaceHighlight : theme.colSurface
    border.width: 1
    border.color: mouseArea.containsMouse ? theme.colBorderHover : theme.colBorderSoft

    Behavior on color { ColorAnimation { duration: 140 } }

    scale: mouseArea.pressed ? 0.985 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Rectangle {
            width: 50
            height: 50
            radius: 25
            color: theme.colAccentDim
            border.width: 1
            border.color: Qt.rgba(theme.colAccent.r, theme.colAccent.g, theme.colAccent.b, 0.35)

            MaterialSymbol {
                anchors.centerIn: parent
                text: cardRoot.icon
                color: theme.colText
                font.pixelSize: 35
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 2

                Text {
                    text: cardRoot.label
                    color: theme.colSubText
                    font.pixelSize: 13
                    font.bold: true
                    font.family: theme.fontMain
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: (typeof cardRoot.detail === "string" && cardRoot.detail.length > 0)
                    text: (typeof cardRoot.detail === "string") ? cardRoot.detail : ""
                    color: theme.colSubText
                    font.pixelSize: 11
                    font.bold: true
                    font.family: theme.fontMain
                    opacity: 0.78
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            Text {
                text: cardRoot.val
                color: theme.colText
                font.pixelSize: 21
                font.bold: true
                font.family: theme.fontMain
                elide: Text.ElideRight
            }

            Rectangle {
                visible: cardRoot.hasProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.topMargin: 6
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    width: parent.width * Math.min(cardRoot.progressValue, 1.0)
                    height: parent.height
                    radius: 2
                    color: {
                        if (cardRoot.progressValue > 0.80) return "#ef4444"
                        if (cardRoot.progressValue > 0.60) return "#f59e0b"
                        return theme.colAccent
                    }
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }
        }
    }
}

