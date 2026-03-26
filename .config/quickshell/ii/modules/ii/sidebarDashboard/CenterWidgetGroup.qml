import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarDashboard.notifications
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: notifList; property: "rotation"; from: 0; to: 8; duration: 60 }
        NumberAnimation { target: notifList; property: "rotation"; from: 8; to: -8; duration: 60 }
        NumberAnimation { target: notifList; property: "rotation"; from: -8; to: 8; duration: 60 }
        NumberAnimation { target: notifList; property: "rotation"; from: 8; to: 0; duration: 60 }
    }

    NotificationList {
        id: notifList
        anchors.fill: parent
        anchors.margins: 5
        transformOrigin: Item.Center
        
        Connections {
            target: notifList
            function onCountChanged() {
                if (notifList.count === 0) {
                    shakeAnimation.start()
                }
            }
        }
    }
}
