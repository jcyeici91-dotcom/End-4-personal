// SidebarPoliciesContent.qml (Qt6)
// UI vieja (header + pills + frame) + sistema nuevo (policies + tabs dinámicos)
// + Sistema (Overview) + Fondos (WallpapersPage viejo) + Wallpapers (WallpaperBrowserUI nuevo)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import qs.services
import qs.modules.common
import qs.modules.common.widgets

import "./ui" as UI
import "./pages" as Pages

Item {
    id: root
    required property var scopeRoot
    anchors.fill: parent

    property int sidebarPadding: 16

    UI.SidebarTheme { id: theme }

    // Policies (nuevo)
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.policies.translator !== 0
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool wallpapersEnabled: Config.options.policies.wallpapers !== 0

    // Tabs: Sistema + Fondos (viejo) + lo nuevo (incluyendo Wallpapers original)
    // OJO: el orden DEBE coincidir con contentChildren.
    readonly property var tabButtonList: [
        { "key": "system", "icon": "dashboard", "name": Translation.tr("Sistema") },

        // Fondos = tus fondos (viejo)
        { "key": "fundos", "icon": "palette", "name": Translation.tr("Fondos") },

        ...(root.aiChatEnabled ? [{ "key": "ai", "icon": "neurology", "name": Translation.tr("Intelligence") }] : []),
        ...(root.translatorEnabled ? [{ "key": "tr", "icon": "translate", "name": Translation.tr("Translator") }] : []),

        // Wallpapers = buscador/manager nuevo (solo si policy lo permite)
        ...(root.wallpapersEnabled ? [{ "key": "walls", "icon": "wallpaper", "name": Translation.tr("Wallpapers") }] : []),

        ...((root.animeEnabled && !root.animeCloset) ? [{ "key": "anime", "icon": "bookmark_heart", "name": Translation.tr("Anime") }] : [])
    ]

    readonly property bool hasTabs: tabButtonList.length > 0

    function focusActiveItem() {
        if (swipeView.currentItem && swipeView.currentItem.forceActiveFocus)
            swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) { swipeView.incrementCurrentIndex(); event.accepted = true }
            else if (event.key === Qt.Key_PageUp) { swipeView.decrementCurrentIndex(); event.accepted = true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.sidebarPadding
        spacing: 16

        // Header (viejo)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 25
            color: Qt.rgba(0, 0, 0, 0.20)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol {
                    text: "auto_awesome"
                    font.pixelSize: 18
                    color: theme.colAccent
                }

                Text {
                    text: "Hakadosh Baruj Hu"
                    color: theme.colText
                    font.pixelSize: 14
                    font.bold: true
                    font.family: theme.fontMain
                }
            }
        }

        // Nav pills (viejo)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.hasTabs ? 85 : 0
            visible: root.hasTabs
            radius: 24
            color: Qt.rgba(0, 0, 0, 0.15)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                Repeater {
                    model: root.tabButtonList

                    delegate: Item {
                        id: navItem
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isActive: swipeView.currentIndex === index

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Rectangle {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 32
                                radius: 16
                                color: navItem.isActive ? theme.colAccent : "transparent"
                                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutQuad } }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: navItem.modelData.icon
                                    font.pixelSize: 20
                                    color: navItem.isActive ? theme.colBase : theme.colText
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: navItem.modelData.name
                                font.family: theme.fontMain
                                font.pixelSize: 12
                                font.bold: navItem.isActive
                                color: navItem.isActive ? theme.colText : theme.colSubText
                                opacity: navItem.isActive ? 1.0 : 0.8
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: swipeView.currentIndex = navItem.index
                        }
                    }
                }
            }
        }

        // Content frame + SwipeView
        Rectangle {
            id: contentFrame
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 28

            color: Qt.rgba(theme.colBase.r, theme.colBase.g, theme.colBase.b, 0.55)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            clip: false

            SwipeView {
                id: swipeView
                anchors.fill: parent
                anchors.margins: 8

                interactive: true
                orientation: Qt.Horizontal
                currentIndex: 0

                clip: false
                layer.enabled: true
                layer.samples: 8
                layer.smooth: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: swipeMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 0.7
                }

                // MISMO ORDEN que tabButtonList
                contentChildren: [
                    // Sistema
                    systemPage.createObject(root),

                    // Fondos (viejo: tus fondos)
                    fondosPage.createObject(root),

                    ...(root.aiChatEnabled ? [aiChat.createObject(root)] : []),
                    ...(root.translatorEnabled ? [translator.createObject(root)] : []),

                    // Wallpapers (nuevo) solo si policy lo permite
                    ...(root.wallpapersEnabled ? [wallpaperBrowser.createObject(root)] : []),

                    ...(root.animeEnabled ? [anime.createObject(root)] : [])
                ]
            }

            Item {
                id: swipeMask
                visible: false
                width: swipeView.width
                height: swipeView.height

                layer.enabled: true
                layer.samples: 8
                layer.smooth: true

                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(0, contentFrame.radius - 8)
                    color: "white"
                    antialiasing: true
                }
            }
        }

        // Pages
        Component { id: systemPage; Pages.OverviewPage { theme: theme } }

        // Fondos = viejo (tus fondos)
        Component { id: fondosPage; Pages.WallpapersPage { theme: theme } }

        // Wallpapers = nuevo (buscar/descubrir)
        Component { id: wallpaperBrowser; WallpaperBrowserUI { } }

        // Nuevo
        Component { id: aiChat; AiChat { } }
        Component { id: translator; Translator { } }
        Component { id: anime; Anime { } }
    }
}

