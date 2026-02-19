import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var events: mainInstance?.events || []
    readonly property bool isLoading: mainInstance?.isLoading || false
    readonly property bool hasError: mainInstance?.hasError || false
    readonly property bool hasUsername: (pluginApi?.pluginSettings?.username || "") !== ""

    icon: "brand-github"
    tooltipText: buildTooltip()
    tooltipDirection: BarService.getTooltipDirection()
    baseSize: Style.capsuleHeight
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: {
        if (hasError) return Color.mError
        if (!hasUsername) return Color.mOnSurfaceVariant
        return Color.mOnSurface
    }
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: "transparent"
    colorBorderHover: "transparent"

    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: {
        if (!hasUsername) {
            ToastService.showNotice("Please configure your GitHub username in settings")
            return
        }

        for (var slot = 1; slot <= 2; slot++) {
            var panel = PanelService.getPanel("pluginPanel" + slot, screen)
            if (panel && panel.currentPluginId === "github-feed") {
                panel.toggle(root)
                return
            }
        }

        for (var slot = 1; slot <= 2; slot++) {
            var panel = PanelService.getPanel("pluginPanel" + slot, screen)
            if (panel && panel.currentPluginId === "") {
                panel.currentPluginId = "github-feed"
                panel.loadPluginPanel("github-feed")
                panel.open(root)
                return
            }
        }

        var panel1 = PanelService.getPanel("pluginPanel1", screen)
        if (panel1) {
            panel1.unloadPluginPanel()
            panel1.currentPluginId = "github-feed"
            panel1.loadPluginPanel("github-feed")
            panel1.open(root)
        }
    }

    onRightClicked: {
        if (mainInstance && hasUsername) {
            mainInstance.fetchFromGitHub()
            ToastService.showNotice("Refreshing GitHub feed...")
        }
    }

    function buildTooltip() {
        if (!hasUsername) {
            return "GitHub Feed\nClick to configure"
        }

        if (hasError) {
            return "GitHub Feed\nError: " + (mainInstance?.errorMessage || "Unknown error")
        }

        if (isLoading) {
            return "GitHub Feed\nLoading..."
        }

        var username = pluginApi?.pluginSettings?.username || ""
        var tooltip = "GitHub Feed - @" + username + "\n"
        tooltip += events.length + " events"

        if (mainInstance?.lastFetchTimestamp) {
            var age = Math.floor(Date.now() / 1000) - mainInstance.lastFetchTimestamp
            var minutes = Math.floor(age / 60)
            if (minutes < 1) {
                tooltip += "\nUpdated just now"
            } else if (minutes < 60) {
                tooltip += "\nUpdated " + minutes + "m ago"
            } else {
                tooltip += "\nUpdated " + Math.floor(minutes / 60) + "h ago"
            }
        }

        tooltip += "\n\nRight-click to refresh"

        return tooltip
    }

    Component.onCompleted: {
        Logger.i("GitHubFeed", "BarWidget initialized")
    }
}
