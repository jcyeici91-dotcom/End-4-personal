pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

Item {
    id: root

    /* external control */
    property bool shown: false
    required property ShellScreen screen

    readonly property int enterDuration: Config.options.appearance.panelAnimation.enterDuration
    readonly property int exitDuration: Config.options.appearance.panelAnimation.exitDuration
    readonly property list<real> enterCurve: Appearance.animationCurves.standard
    readonly property list<real> exitCurve: Appearance.animationCurves.standard

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    onVisibleChanged: {
        if(!root.visible) {
            content.item?.clearResults();
            content.item?.disableExpandAnimation();
            return;
        }        
        if (!content.item?.dontAutoCancelSearch) {
            content.item?.cancelSearch();
        }
    }

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

    Loader {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        sourceComponent: Content {
            screen: root.screen
        }
    }
}
