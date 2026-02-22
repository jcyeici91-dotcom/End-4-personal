import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

import ".." as Bar

Item {
    id: left

    required property bool useHybridGroups
    required property int hybridResizeMs

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Item {
        id: leftStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: left.useHybridGroups ? 0 : Math.ceil(Appearance.rounding.screenRounding / 2)
        width: 1
    }

    Loader {
        id: leftContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftStopper.right
        active: true
        sourceComponent: left.useHybridGroups ? leftHybridComponent : leftClassicComponent
    }

    Component {
        id: leftClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.left
                delegate: Bar.BarComponent {
                    list: Config.options.bar.layouts.left
                    barSection: 0
                }
            }
        }
    }

    Component {
        id: leftHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenLeft: true

            width: implicitWidth
            Behavior on width {
                NumberAnimation {
                    duration: left.hybridResizeMs
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: Config.options.bar.layouts.left
                delegate: Bar.BarComponent {
                    list: Config.options.bar.layouts.left
                    barSection: 0
                }
            }
        }
    }
}

