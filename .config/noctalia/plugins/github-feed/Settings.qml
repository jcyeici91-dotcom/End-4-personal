import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root

    property var pluginApi: null

    property string editUsername: ""
    property string editToken: ""
    property int editRefreshInterval: 1800
    property int editMaxEvents: 50
    property bool editShowStars: true
    property bool editShowForks: true
    property bool editShowPRs: true
    property bool editShowRepoCreations: true
    property bool editShowMyRepoStars: true
    property bool editShowMyRepoForks: true
    property bool editOpenInBrowser: true

    spacing: Style.marginM

    NLabel {
        label: "Account"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "GitHub Username"
        description: "Your GitHub username to fetch activity feed"
        placeholderText: "e.g., linuxmobile"
        text: root.editUsername
        onTextChanged: root.editUsername = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Personal Access Token (Required)"
        description: "Required for GraphQL API. Create at github.com/settings/tokens with 'read:user' scope"
        placeholderText: "ghp_xxxxxxxxxxxx"
        text: root.editToken
        onTextChanged: root.editToken = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    NLabel {
        label: "Refresh Settings"
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: "Refresh Interval"
            description: {
                var minutes = Math.floor(root.editRefreshInterval / 60)
                if (minutes < 60) {
                    return "Check for new events every " + minutes + " minutes"
                } else {
                    var hours = Math.floor(minutes / 60)
                    var remainingMins = minutes % 60
                    if (remainingMins === 0) {
                        return "Check for new events every " + hours + " hour" + (hours > 1 ? "s" : "")
                    }
                    return "Check for new events every " + hours + "h " + remainingMins + "m"
                }
            }
        }

        NSlider {
            Layout.fillWidth: true
            from: 300
            to: 7200
            stepSize: 300
            value: root.editRefreshInterval
            onValueChanged: root.editRefreshInterval = value
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: "Maximum Events"
            description: "Show up to " + root.editMaxEvents + " events in the feed"
        }

        NSlider {
            Layout.fillWidth: true
            from: 10
            to: 100
            stepSize: 10
            value: root.editMaxEvents
            onValueChanged: root.editMaxEvents = value
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    NLabel {
        label: "Activity from Followed Users"
        description: "Events from people you follow"
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginS

        NToggle {
            Layout.fillWidth: true
            label: "Stars"
            description: "Repos they starred"
            checked: root.editShowStars
            onToggled: (checked) => { root.editShowStars = checked }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Forks"
            description: "Repos they forked"
            checked: root.editShowForks
            onToggled: (checked) => { root.editShowForks = checked }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Pull Requests"
            description: "PRs they opened"
            checked: root.editShowPRs
            onToggled: (checked) => { root.editShowPRs = checked }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Repo Creations"
            description: "Repos they created"
            checked: root.editShowRepoCreations
            onToggled: (checked) => { root.editShowRepoCreations = checked }
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    NLabel {
        label: "Activity on Your Repos"
        description: "Events on repositories you own"
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginS

        NToggle {
            Layout.fillWidth: true
            label: "Stars on Your Repos"
            description: "When someone stars your repo"
            checked: root.editShowMyRepoStars
            onToggled: (checked) => { root.editShowMyRepoStars = checked }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Forks of Your Repos"
            description: "When someone forks your repo"
            checked: root.editShowMyRepoForks
            onToggled: (checked) => { root.editShowMyRepoForks = checked }
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    NLabel {
        label: "Behavior"
    }

    NToggle {
        Layout.fillWidth: true
        label: "Open in Browser"
        description: "Click on events to open them in your default browser"
        checked: root.editOpenInBrowser
        onToggled: (checked) => { root.editOpenInBrowser = checked }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: infoCol.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        ColumnLayout {
            id: infoCol
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginS

            RowLayout {
                spacing: Style.marginS

                NIcon {
                    icon: "info-circle"
                    pointSize: Style.fontSizeS
                    color: Color.mPrimary
                }

                NText {
                    text: "IPC Commands"
                    pointSize: Style.fontSizeS
                    font.weight: Font.Medium
                    color: Color.mOnSurface
                }
            }

            NText {
                Layout.fillWidth: true
                text: "Refresh: qs -c noctalia-shell ipc call plugin:github-feed refresh"
                pointSize: Style.fontSizeXS
                font.family: Settings.data.ui.fontFixed
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WrapAnywhere
            }

            NText {
                Layout.fillWidth: true
                text: "Toggle panel: qs -c noctalia-shell ipc call plugin:github-feed toggle"
                pointSize: Style.fontSizeXS
                font.family: Settings.data.ui.fontFixed
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WrapAnywhere
            }
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("GitHubFeed", "Cannot save: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.username = root.editUsername.trim()
        pluginApi.pluginSettings.token = root.editToken.trim()
        pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
        pluginApi.pluginSettings.maxEvents = root.editMaxEvents
        pluginApi.pluginSettings.showStars = root.editShowStars
        pluginApi.pluginSettings.showForks = root.editShowForks
        pluginApi.pluginSettings.showPRs = root.editShowPRs
        pluginApi.pluginSettings.showRepoCreations = root.editShowRepoCreations
        pluginApi.pluginSettings.showMyRepoStars = root.editShowMyRepoStars
        pluginApi.pluginSettings.showMyRepoForks = root.editShowMyRepoForks
        pluginApi.pluginSettings.openInBrowser = root.editOpenInBrowser

        pluginApi.saveSettings()

        Logger.i("GitHubFeed", "Settings saved")
        ToastService.showNotice("GitHub Feed settings saved")
    }

    Component.onCompleted: {
        Logger.i("GitHubFeed", "Settings UI loaded")

        var settings = pluginApi?.pluginSettings
        var defaults = pluginApi?.manifest?.metadata?.defaultSettings

        root.editUsername = settings?.username || defaults?.username || ""
        root.editToken = settings?.token || defaults?.token || ""
        root.editRefreshInterval = settings?.refreshInterval || defaults?.refreshInterval || 1800
        root.editMaxEvents = settings?.maxEvents || defaults?.maxEvents || 50
        root.editShowStars = settings?.showStars ?? defaults?.showStars ?? true
        root.editShowForks = settings?.showForks ?? defaults?.showForks ?? true
        root.editShowPRs = settings?.showPRs ?? defaults?.showPRs ?? true
        root.editShowRepoCreations = settings?.showRepoCreations ?? defaults?.showRepoCreations ?? true
        root.editShowMyRepoStars = settings?.showMyRepoStars ?? defaults?.showMyRepoStars ?? true
        root.editShowMyRepoForks = settings?.showMyRepoForks ?? defaults?.showMyRepoForks ?? true
        root.editOpenInBrowser = settings?.openInBrowser ?? defaults?.openInBrowser ?? true
    }
}
