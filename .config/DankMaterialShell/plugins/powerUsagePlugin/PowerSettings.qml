import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "powerUsagePlugin"

    StyledText {
        width: parent.width
        text: "Power Usage Monitor Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure how often the power usage is refreshed and displayed."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "How often to update power usage (in seconds)"
        defaultValue: 5
        minimum: 1
        maximum: 30
        unit: "s"
        leftIcon: "schedule"
    }

    SelectionSetting {
        settingKey: "selectedPopout"
        label: "Popup to Open when Clicked"
        options: [
            {
                label: "Battery Info",
                value: "battery"
            },
            {
                label: "Task Manager/Process List",
                value: "processList"
            }
        ]
        defaultValue: "battery"
    }
}
