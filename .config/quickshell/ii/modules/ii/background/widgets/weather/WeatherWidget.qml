import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"

    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    StyledDropShadow {
        target: backgroundShape
    }

    MaterialShape {
        id: backgroundShape
        anchors.fill: parent
        shape: MaterialShape.Shape.Pill
        color: Appearance.colors.colPrimaryContainer
        
         implicitSize: 240 

        StyledText {
            font {
                pixelSize: 80
                family: Appearance.font.family.expressive
                weight: Font.Medium
            }
            color: Appearance.colors.colPrimary
            
              text: Weather.data?.temp ? Weather.data.temp.replace(/[a-zA-Z]/g, "") : "--°"
            
            anchors {
                right: parent.right
                top: parent.top
               rightMargin: 40
                topMargin: 40
            }
        }

        MaterialSymbol {
            iconSize: 80
            color: Appearance.colors.colOnPrimaryContainer
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            
            anchors {
                left: parent.left
                bottom: parent.bottom
               leftMargin: 40
                bottomMargin: 40
            }
        }
    }
}
