pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common

Item {
    id: root
    property bool vertical: false
    property bool showWeather: false
    property int wheelCooldownMs: 180
    property bool wheelLocked: false

    function togglePage() {
        showWeather = !showWeather
    }

    Timer {
        id: wheelCooldown
        interval: root.wheelCooldownMs
        repeat: false
        onTriggered: root.wheelLocked = false
    }

    function safeImplicitW(obj, fallback) {
        return (obj && obj.implicitWidth > 0) ? obj.implicitWidth : fallback
    }

    function safeImplicitH(obj, fallback) {
        return (obj && obj.implicitHeight > 0) ? obj.implicitHeight : fallback
    }

    readonly property real clockW: safeImplicitW(clockLoader.item, 100)
    readonly property real clockH: safeImplicitH(clockLoader.item, 45)
    readonly property real weatherW: safeImplicitW(weatherLoader.item, 100)
    readonly property real weatherH: safeImplicitH(weatherLoader.item, 45)

    readonly property real contentWidth: root.showWeather ? weatherW : clockW
    readonly property real contentHeight: root.showWeather ? weatherH : clockH

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : Math.max(1, contentWidth)
    implicitHeight: root.vertical ? Math.max(1, contentHeight) : (Appearance.sizes.barHeight > 0 ? Appearance.sizes.barHeight : 45)

    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Behavior on implicitHeight {
        enabled: root.vertical
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            if (wheel.angleDelta.y === 0) return
            if (root.wheelLocked) {
                wheel.accepted = true
                return
            }
            root.wheelLocked = true
            wheelCooldown.restart()
            root.togglePage()
            wheel.accepted = true
        }
    }

    component AnimatedPage: Loader {
        id: page
        property bool shown: false
        active: true
        visible: shown
        opacity: shown ? 1 : 0
        scale: shown ? 1.0 : 0.92

        anchors.left: root.vertical ? parent.left : undefined
        anchors.right: root.vertical ? parent.right : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter

        width: root.vertical ? parent.width : (item ? Math.max(1, item.implicitWidth) : 1)
        height: root.vertical ? (item ? Math.max(1, item.implicitHeight) : 1) : (item ? Math.max(1, item.implicitHeight) : 1)

        onItemChanged: {
            if (item && item.hasOwnProperty("vertical"))
                item.vertical = root.vertical
        }

        Connections {
            target: root
            function onVerticalChanged() {
                if (page.item && page.item.hasOwnProperty("vertical"))
                    page.item.vertical = root.vertical
            }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }

    AnimatedPage {
        id: clockLoader
        source: "ClockWidget.qml"
        shown: !root.showWeather
    }

    AnimatedPage {
        id: weatherLoader
        source: "weather/WeatherBar.qml"
        shown: root.showWeather
    }
}
