import QtQuick
import Quickshell
import "nepali-date.js" as NepCal
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property color customColor: Theme.primary

    SystemClock {
        id: systemClock

        precision: SystemClock.Hours
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            StyledText {
                text: NepCal.formatBSDate(NepCal.ADToBS(Qt.formatDate(systemClock.date, "yyyy-MM-dd")), pluginData.dateFormat ?? "YYYY Month dd", pluginData.showDevanagari)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

        }

    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            StyledText {
                text: NepCal.formatBSDateVertical(NepCal.ADToBS(Qt.formatDate(systemClock.date, "yyyy-MM-dd")), pluginData.dateFormat ?? "YYYY Month dd", pluginData.showDevanagari)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

}
