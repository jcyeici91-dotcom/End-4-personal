import Quickshell
import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "appShortcut"

    SelectionSetting {
        settingKey: "shortcutApp"
        label: I18n.tr("Shortcut Application")
        description: I18n.tr("Choose which app to show a shortcut for")
        options: DesktopEntries.applications.values.map(app => {
            return {
                label: app.name,
                value: app.id
            };
        })
        defaultValue: "none"
    }

    SliderSetting {
        settingKey: "backgroundOpacity"
        label: I18n.tr("Shortcut Background Opacity")
        defaultValue: 80
        minimum: 0
        maximum: 100
        unit: "%"
    }

    ToggleSetting {
        settingKey: "drawOutlines"
        label: I18n.tr("Draw Outlines")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "drawBorder"
        label: I18n.tr("Draw Border Around Shortcut")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "followTheme"
        label: I18n.tr("Adapt Icon To Theme")
        defaultValue: false
    }
}
