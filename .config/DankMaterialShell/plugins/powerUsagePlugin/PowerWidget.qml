import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string powerUsage: "..."
    property int refreshInterval: (pluginData.refreshInterval || 5) * 1000
    property string scriptPath: Qt.resolvedUrl("get-power-usage").toString().replace("file://", "")

    property var popoutService: null

    property string selectedPopout: pluginData.selectedPopout || "battery"

    property var popoutActions: ({
            "battery": (x, y, w, s, scr) => popoutService?.toggleBattery(x, y, w, s, scr),
            "processList": (x, y, w, s, scr) => popoutService?.toggleProcessList(x, y, w, s, scr)
        })

    property var popoutNames: ({
            "battery": "Battery Info",
            "processList": "Process List"
        })

    pillClickAction: (x, y, width, section, screen) => {
        if (popoutActions[selectedPopout]) {
            popoutActions[selectedPopout](x, y, width, section, screen);
        }
    }

    Process {
        id: powerProcess
        command: ["sh", root.scriptPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.powerUsage = data.trim();
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("Power usage updated: ", root.powerUsage);
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            powerProcess.running = true;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            rightPadding: Theme.spacingS

            StyledText {
                text: "󰠠 "
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.powerUsage
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
                text: "󰠠 "
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.powerUsage
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
