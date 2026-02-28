import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property real animationSpeedScale
    required property string artFilePath
    required property color overlayColor
    required property bool animationEnabled

    onAnimationSpeedScaleChanged: {

    }

    Image {
        id: img
        anchors.fill: parent
        source: root.artFilePath
        fillMode: Image.PreserveAspectCrop
        cache: false; antialiasing: true; asynchronous: true

        layer.enabled: true
        layer.effect: StyledBlurEffect { source: img }

        Rectangle { anchors.fill: parent; color: root.overlayColor }

        transform: [
            Scale {
                origin.x: img.width / 2; origin.y: img.height / 2
                xScale: 1.15; yScale: 1.15
            },
            Translate { id: floatTranslate }
        ]

        AxisAnimation {
            speed: root.animationSpeedScale
            axis: "x"
            frames: [-50,  30, -20,  50, -50]
            times:  [16500, 11500, 19500, 14500]
        }

        AxisAnimation {
            speed: root.animationSpeedScale
            axis: "y"
            frames: [20, -50,  30, -30,  20]
            times:  [20000, 14000, 19000, 14500]
        }
    }


    component AxisAnimation: SequentialAnimation {
        required property string axis
        required property var frames 
        required property var times 
        required property var speed

        loops: Animation.Infinite
        running: root.animationEnabled

        onSpeedChanged: { // to instantly update the speed, it waits for the full animation to end to take effect otherwise
            running = false
            Qt.callLater (() => {
                running = root.animationEnabled
            })
        }

        NumberAnimation { target: floatTranslate; property: axis; from: frames[0]; to: frames[1]; duration: times[0] / speed; easing.type: Easing.InOutSine }
        NumberAnimation { target: floatTranslate; property: axis; from: frames[1]; to: frames[2]; duration: times[1] / speed; easing.type: Easing.InOutSine }
        NumberAnimation { target: floatTranslate; property: axis; from: frames[2]; to: frames[3]; duration: times[2] / speed; easing.type: Easing.InOutSine }
        NumberAnimation { target: floatTranslate; property: axis; from: frames[3]; to: frames[4]; duration: times[3] / speed; easing.type: Easing.InOutSine }
    }
}