import QtQuick

Item {
    id: root

    property alias text: txt.text
    property alias font: txt.font
    property alias color: txt.color
    property bool centered: false

    clip: true

    // Para que Layouts sepan cuánto mide
    implicitHeight: txt.implicitHeight
    implicitWidth: txt.implicitWidth

    Text {
        id: txt
        anchors.verticalCenter: parent.verticalCenter

        x: {
            if (txt.implicitWidth <= parent.width) {
                return root.centered ? (parent.width - txt.implicitWidth) / 2 : 0
            }
            return 0
        }

        SequentialAnimation on x {
            running: txt.implicitWidth > parent.width
            loops: Animation.Infinite

            PauseAnimation { duration: 1500 }

            NumberAnimation {
                to: -(txt.implicitWidth - parent.width)
                duration: (txt.implicitWidth - parent.width) * 20 + 1000
                easing.type: Easing.InOutQuad
            }

            PauseAnimation { duration: 1000 }

            NumberAnimation {
                to: 0
                duration: (txt.implicitWidth - parent.width) * 20 + 1000
                easing.type: Easing.InOutQuad
            }
        }
    }
}

