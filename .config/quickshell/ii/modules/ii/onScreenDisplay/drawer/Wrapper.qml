pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

Item {
    id: root

    /* external control */
    property bool shown: false

    readonly property int enterDuration: Config.options.appearance.panelAnimation.enterDuration
    readonly property int exitDuration: Config.options.appearance.panelAnimation.exitDuration
    readonly property list<real> enterCurve: Appearance.animationCurves.standard
    readonly property list<real> exitCurve: Appearance.animationCurves.standard
    property string currentIndicator: "volume"
    property var indicators: [
        {
            id: "volume",
            sourceUrl: "../indicators/VolumeIndicator.qml"
        },
        {
            id: "brightness",
            sourceUrl: "../indicators/BrightnessIndicator.qml"
        },
        {
            id: "playerVolume",
            sourceUrl: "../indicators/PlayerVolumeIndicator.qml"
        },
    ]

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: [
        State {
            name: "open"
            when: root.shown
            PropertyChanges {
                root.implicitHeight: content.implicitHeight
            }
        },
        State {
            name: "closed"
            when: !root.shown
            PropertyChanges {
                root.implicitHeight: 0
            }
        }
    ]

    transitions: [
        Transition {
            from: "closed"
            to: "open"
            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: root.enterDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.enterCurve
            }
        },
        Transition {
            from: "open"
            to: "closed"
            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: root.exitDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.exitCurve
            }
        }
    ]

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            root.currentIndicator = "brightness";
        }
    }

    Connections {
        // Listen to volume changes
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
        }
        function onMutedChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
        }
    }

    Connections {
        // Listen to protection triggers
        target: Audio
        function onSinkProtectionTriggered(reason) {
            root.currentIndicator = "volume";
        }
    }

    Connections {
        // Listen to MPRIS/MPD media player volume changes
        target: MprisController.activePlayer ?? null
        function onVolumeChanged() {
            if (MprisController.canChangeVolume) {
                root.currentIndicator = "playerVolume";
            }
        }
    }

    Loader {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl
    }
}
