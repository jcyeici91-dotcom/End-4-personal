import QtQuick
import QtQuick.Layouts

import ".." as Bar

Item {
    id: center

    required property bool useHybridGroups
    required property int hybridResizeMs

    required property var leftList
    required property var centerList
    required property var rightList

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter

    Loader {
        anchors.fill: parent
        active: true
        sourceComponent: center.useHybridGroups ? middleHybridComponent : middleClassicComponent
    }

    Component {
        id: middleClassicComponent
        Item {
            anchors.fill: parent

            RowLayout {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: centerCenter.left
                anchors.rightMargin: 4
                Repeater {
                    model: center.leftList
                    delegate: Bar.BarComponent {
                        list: Config.options.bar.layouts.center
                        barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                    }
                }
            }

            RowLayout {
                id: centerCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: center.centerList
                    delegate: Bar.BarComponent {
                        list: Config.options.bar.layouts.center
                        barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                    }
                }
            }

            RowLayout {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: centerCenter.right
                anchors.leftMargin: 4
                Repeater {
                    model: center.rightList
                    delegate: Bar.BarComponent {
                        list: Config.options.bar.layouts.center
                        barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                    }
                }
            }
        }
    }

    Component {
        id: middleHybridComponent
        Item {
            anchors.fill: parent

            Loader {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: centerCenterGroup.left
                anchors.rightMargin: 4
                active: (center.leftList && center.leftList.length > 0)
                visible: active
                sourceComponent: Bar.BarGroup {
                    vertical: false
                    spacing: 4
                    isContainer: true
                    autoHide: true
                    padding: 6
                    edgeInset: 2

                    width: implicitWidth
                    Behavior on width {
                        NumberAnimation {
                            duration: center.hybridResizeMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: center.leftList
                        delegate: Bar.BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
            }

            Bar.BarGroup {
                id: centerCenterGroup
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                vertical: false
                spacing: 4
                isContainer: true
                autoHide: true
                padding: 6
                edgeInset: 2

                width: implicitWidth
                Behavior on width {
                    NumberAnimation {
                        duration: center.hybridResizeMs
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: center.centerList
                    delegate: Bar.BarComponent {
                        list: Config.options.bar.layouts.center
                        barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                    }
                }
            }

            Loader {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: centerCenterGroup.right
                anchors.leftMargin: 4
                active: (center.rightList && center.rightList.length > 0)
                visible: active
                sourceComponent: Bar.BarGroup {
                    vertical: false
                    spacing: 4
                    isContainer: true
                    autoHide: true
                    padding: 6
                    edgeInset: 2

                    width: implicitWidth
                    Behavior on width {
                        NumberAnimation {
                            duration: center.hybridResizeMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: center.rightList
                        delegate: Bar.BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }
            }
        }
    }
}

