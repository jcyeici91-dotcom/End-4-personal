import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: layout.implicitHeight + 30

    SessionBackground {
        anchors.fill: parent
        attachEdge: "right"
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 20

        SessionButton { 
            iconName: "lock"
            command: "loginctl lock-session"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
        }

        SessionButton { 
            iconName: "logout"
            command: "hyprctl dispatch exit"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
        }

        SessionButton { 
            iconName: "power_settings_new"
            command: "systemctl poweroff"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
        }
        
        AnimatedImage {
            source: Qt.resolvedUrl("../../../assets/gifs/kurukuru.gif")
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            fillMode: Image.PreserveAspectFit
            playing: GlobalStates.sessionVisible
        }

        SessionButton { 
            iconName: "bedtime"
            command: "systemctl suspend"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
        }

        SessionButton { 
            iconName: "restart_alt"
            command: "systemctl reboot"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
        }
    }
}
