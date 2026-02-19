import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    // those are widget options
    minWidth: 100
    minHeight: 100
    property bool forceSquare: true

    // settings data here
    property string appId: pluginData.shortcutApp
    property real backgroundOpacity: (pluginData.backgroundOpacity ?? 80) / 100
    property bool followTheme: pluginData.followTheme ?? false
    property bool drawOutlines: pluginData.drawOutlines ?? false
    property bool drawBorder: pluginData.drawBorder ?? true

    property var app: DesktopEntries.applications.values.find(app => app.id == appId)
    property var iconSource: Quickshell.iconPath(app.icon)

    Rectangle {
        id: shortcutBg
        visible: root.appId !== "none"
        anchors.fill: parent

        // this gives space to the pop animation
        // TODO: idk what to do about this, but its hard coded for now.
        // it could be not enough if the widget size is big
        anchors.margins: 15

        // hover scale animation
        Behavior on scale {
            NumberAnimation {
                duration: 75
            }
        }

        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, root.backgroundOpacity)
        border.color: Theme.withAlpha(Theme.primary, 0.4)
        border.width: root.drawBorder ? 1 : 0

        Image {
            id: mainIcon
            source: root.iconSource
            anchors.fill: parent
            anchors.margins: 10
            fillMode: Image.PreserveAspectFit

            layer.enabled: root.drawOutlines || root.followTheme
            layer.effect: MultiEffect {
                shadowEnabled: root.drawOutlines
                shadowColor: Theme.primary
                shadowBlur: 0
                shadowScale: 1.1
                colorization: root.followTheme ? 1 : 0
                colorizationColor: Theme.primary
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                root.app.execute();
                // make the ghost icon visible
                ghostIcon.opacity = 1.0;
                ghostIcon.scale = 1.0;

                // restart is used here in case you spam-click
                // so the animation starts over
                popAnim.restart();
            }
            onEntered: shortcutBg.scale = 1.05
            onExited: shortcutBg.scale = 1.0
        }
    }

    Image {
        // this has identical props to the main icon
        // its the one that animates on click
        id: ghostIcon
        source: root.iconSource
        anchors.fill: shortcutBg
        anchors.margins: 10
        fillMode: Image.PreserveAspectFit

        opacity: 0
        visible: opacity > 0

        layer.enabled: root.drawOutlines || root.followTheme
        layer.effect: MultiEffect {
            shadowEnabled: root.drawOutlines
            shadowColor: Theme.primary
            shadowBlur: 0
            shadowScale: 1.05
            colorization: root.followTheme ? 1 : 0
            colorizationColor: Theme.primary
        }
    }

    ParallelAnimation {
        id: popAnim

        NumberAnimation {
            target: ghostIcon
            property: "scale"
            from: 1.0
            to: 1.8
            duration: 1000
            easing.type: Easing.OutQuart
        }

        NumberAnimation {
            target: ghostIcon
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 1000
            easing.type: Easing.OutQuad
        }
    }
}
