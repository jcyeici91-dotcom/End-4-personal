import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Hyprland

PluginComponent {
    id: root
    property string displayText: ""
    property bool isNotDefault: false
    visible: isNotDefault
    Connections {
            target: Hyprland

            function onRawEvent(event) {
            // Captura eventos de submapa de Hyprland
              if (event.name === "submap") {
                // El data contiene el nombre del submapa
                const submapName = event.data.trim()

                if (submapName && submapName !== "") {
                    root.displayText = submapName
		    root.isNotDefault = true
                } else {
                    root.displayText = ""
		    root.isNotDefault = false
                }
              }
            }
	  }
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS
            Loader {
	      active: isNotDefault
	      sourceComponent: StyledText {
                visible: isNotDefault
                text: root.displayText

                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
              }
	    }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            Loader {
	      active: isNotDefault
	      sourceComponent: StyledText {
                text: root.displayText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
	        visible: isNotDefault
                anchors.horizontalCenter: parent.horizontalCenter
            }
	    }
        }
    }
}
