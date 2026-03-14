// BongoCat.qml
import QtQuick
import QtQuick.Layouts

Item {
    id: bongoCat

    // Recibido desde Media.qml (para rotar si la barra está vertical)
    property bool isVertical: false

    // Controla si debe animar (true solo en PLAY)
    property bool animate: true

property url gifSource: Qt.resolvedUrl("../../assets/gifs/bongo-cat.gif")

    implicitWidth: 56
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    AnimatedImage {
        anchors.fill: parent
        source: bongoCat.gifSource
        smooth: true
        cache: true
        fillMode: Image.PreserveAspectFit
        rotation: bongoCat.isVertical ? 270 : 0

        // En pausa: se queda visible pero congelado
        paused: !bongoCat.animate
    }
}

