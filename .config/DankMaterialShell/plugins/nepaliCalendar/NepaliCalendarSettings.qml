import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "nepaliCalendar"

    ToggleSetting {
        settingKey: "showDevanagari"
        label: "देवनागरी"
        description: "देवनागरी लिपि लाई देखाउनुहोस्"
        defaultValue: false
    }

    SelectionSetting {
        settingKey: "dateFormat"
        label: "Format"
        description: "Choose how the date is displayed"
        options: [{
            "label": "2082 Jestha 12",
            "value": "YYYY Month dd"
        }, {
            "label": "2082/02/12",
            "value": "YYYY/MM/dd"
        }, {
            "label": "82-02-12",
            "value": "YY-MM-dd"
        }, {
            "label": "82/02/12",
            "value": "YY/MM/dd"
        }, {
            "label": "2082-02-12",
            "value": "YYYY-MM-dd"
        }, {
            "label": "Jestha 12",
            "value": "Month dd"
        }]
        defaultValue: "YYYY Month dd"
    }

}
