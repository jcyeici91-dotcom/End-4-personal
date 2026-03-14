import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./overview/blocks" as Blocks
import "../models" as Models
import "../ui" as UI

Item {
    id: page
    required property var theme

    Models.DashboardModel { id: dashboard }
    Models.MusicModel { id: music }

    readonly property int pad: 16
    readonly property int colGap: 12
    readonly property int rowGap: 12

    Flickable {
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: mainCol.implicitHeight + page.pad * 2

        ColumnLayout {
            id: mainCol
            x: page.pad
            y: page.pad
            width: parent.width - page.pad * 2
            spacing: page.rowGap

            Blocks.HeaderBlock {
                Layout.fillWidth: true
                Layout.preferredHeight: 160   
                theme: page.theme
                dashboard: dashboard
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: page.colGap
                rowSpacing: page.rowGap

                UI.MusicPlayerCard {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    theme: page.theme
                    musicModel: music
                }

                Blocks.SystemVitalityBlock {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    theme: page.theme
                    dashboard: dashboard
                }

                UI.CryptoCard {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 380   
                    theme: page.theme
                }

                GoogleDiscoverPage {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }
    }
}

