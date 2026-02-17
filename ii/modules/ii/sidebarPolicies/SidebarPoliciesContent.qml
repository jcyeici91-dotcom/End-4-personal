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

    // STICKER 
     readonly property url welcomeStickerSourcePortable: Qt.resolvedUrl("./assets/gifs/1.png")
    readonly property url welcomeStickerSourceFallback: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/1.png"
    property bool allowStickerFallback: true

    // Header tuning
    property int headerInnerPadding: 14

    // PNG flotante 
    property int floatingBadgeSize: 90         // tamaño del “mini/png”
    property int floatingBadgeLift: -5        // cuanto sube por encima del header (más = más arriba)
    property int floatingBadgeRightPadding: 10  // separación del borde derecho

    // Policies
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.policies.translator !== 0
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool wallpapersEnabled: Config.options.policies.wallpapers !== 0

    readonly property var tabButtonList: [
        { "key": "system", "icon": "dashboard", "name": Translation.tr("Sistema") },
        { "key": "fundos", "icon": "palette", "name": Translation.tr("Fondos") },

        ...(root.aiChatEnabled ? [{ "key": "ai", "icon": "neurology", "name": Translation.tr("IA") }] : []),
        ...(root.translatorEnabled ? [{ "key": "tr", "icon": "translate", "name": Translation.tr("Traductor") }] : []),

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

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 25
            color: Qt.rgba(0, 0, 0, 0.20)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)

            // clave para que el PNG pueda “salirse” hacia arriba
            clip: false

            // Contenedor general
            Item {
                anchors.fill: parent

                // Grupo centrado (ícono + texto)
                Row {
                    id: centeredWelcome
                    anchors.centerIn: parent
                    spacing: 10

                    MaterialSymbol {
                        text: "auto_awesome"
                        font.pixelSize: 18
                        color: theme.colAccent
                    }

                    Text {
                        id: welcomeText
                        text: "Welcome to my fortress"
                        color: theme.colText
                        font.pixelSize: 14
                        font.bold: true
                        font.family: theme.fontMain
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                }

                // “Badge” a la derecha (pero el PNG va flotando encima)
                Item {
                    id: floatingBadge
                    width: root.floatingBadgeSize
                    height: root.floatingBadgeSize
                    anchors.right: parent.right
                    anchors.rightMargin: root.floatingBadgeRightPadding
                    anchors.verticalCenter: parent.verticalCenter

                    // El PNG flotante (encima del header)
                    Image {
                        id: welcomeStickerPortable
                        width: root.floatingBadgeSize
                        height: root.floatingBadgeSize
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -root.floatingBadgeLift

                        source: root.welcomeStickerSourcePortable
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        antialiasing: true
                        visible: status === Image.Ready
                    }

                    Image {
                        id: welcomeStickerFallback
                        width: root.floatingBadgeSize
                        height: root.floatingBadgeSize
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -root.floatingBadgeLift

                        source: root.welcomeStickerSourceFallback
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        antialiasing: true
                        visible: root.allowStickerFallback
                                 && !welcomeStickerPortable.visible
                                 && status === Image.Ready
                    }

                    // Placeholder si ninguna carga
                    Rectangle {
                        width: root.floatingBadgeSize
                        height: root.floatingBadgeSize
                        radius: root.floatingBadgeSize / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -root.floatingBadgeLift
                        color: Qt.rgba(1, 1, 1, 0.10)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        visible: !welcomeStickerPortable.visible && !welcomeStickerFallback.visible

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "rocket_launch"
                            font.pixelSize: Math.round(root.floatingBadgeSize * 0.55)
                            color: theme.colAccent
                        }
                    }
                }

                // padding interno visual (opcional, por si luego añades cosas)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.headerInnerPadding
                    color: "transparent"
                    visible: false
                }
            }
        }

        // Nav pills
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
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
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

                contentChildren: [
                    systemPage.createObject(root),
                    fondosPage.createObject(root),

                    ...(root.aiChatEnabled ? [aiChat.createObject(root)] : []),
                    ...(root.translatorEnabled ? [translator.createObject(root)] : []),

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
        Component { id: fondosPage; Pages.WallpapersPage { theme: theme } }
        Component { id: wallpaperBrowser; WallpaperBrowserUI { } }
        Component { id: aiChat; AiChat { } }
        Component { id: translator; Translator { } }
        Component { id: anime; Anime { } }
    }
}

