import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets

import ".." as Bar

Item {
    id: right

    required property bool useHybridGroups
    required property int hybridResizeMs

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Item {
        id: rightStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
    }

    Loader {
        id: rightContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: rightStopper.left
        anchors.rightMargin: right.useHybridGroups ? 0 : Math.ceil(Appearance.rounding.screenRounding / 2)
        active: true
        sourceComponent: right.useHybridGroups ? rightHybridComponent : rightClassicComponent
    }

    Component {
        id: rightClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.right
                delegate: Bar.BarComponent {
                    list: Config.options.bar.layouts.right
                    barSection: 2
                }
            }
        }
    }

    Component {
        id: rightHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenRight: true

            width: implicitWidth
            Behavior on width {
                NumberAnimation {
                    duration: right.hybridResizeMs
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: Config.options.bar.layouts.right
                delegate: Bar.BarComponent {
                    list: Config.options.bar.layouts.right
                    barSection: 2
                }
            }
        }
    }
}

