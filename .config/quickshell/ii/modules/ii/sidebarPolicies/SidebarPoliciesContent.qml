pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes

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

    readonly property url welcomeStickerSourcePortable: Qt.resolvedUrl("./assets/gifs/1.png")
    readonly property url welcomeStickerSourceFallback: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/1.png"
    property bool allowStickerFallback: true

    property int headerInnerPadding: 14
    property int floatingBadgeSize: 90
    property int floatingBadgeLift: -5
    property int floatingBadgeRightPadding: 10

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

    readonly property bool isOnLeft: {
        const pos = Config.options.sidebar.position
        return pos === "default" || pos === "left"
    }
    
    readonly property real shapeRadius: Appearance.rounding ? (Appearance.rounding.screenRounding || 18) : 18
    
    // --- LÓGICA DE FLOTACIÓN INTELIGENTE ---
    // Determinamos si la barra principal está "flotando" (separada del borde superior)
    readonly property bool isMainBarFloating: (Config.options.bar.cornerStyle === 1) || (Config.options.bar.barBackgroundStyle === 0) || (Config.options.bar.barBackgroundStyle === 3)
    
    // El sidebar flota si el usuario lo forzó en config O si la barra principal está flotando.
    readonly property bool isFloating: Config.options.sidebar.floatStyle || isMainBarFloating
    readonly property int floatingGap: Config.options.sidebar.floatingGap
    // ---------------------------------------

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

    Item {
        anchors.fill: parent

        anchors.topMargin: root.isFloating ? root.floatingGap : 0
        anchors.bottomMargin: root.isFloating ? root.floatingGap : 0
        anchors.leftMargin: root.isFloating && root.isOnLeft ? root.floatingGap : 0
        anchors.rightMargin: root.isFloating && !root.isOnLeft ? root.floatingGap : 0

        Loader {
            anchors.fill: parent
            sourceComponent: root.isFloating ? floatingBgComponent : unitedBgComponent
        }

        Component {
            id: floatingBgComponent
            Rectangle {
                color: Appearance.colors.colLayer0
                radius: root.shapeRadius
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
            }
        }

        Component {
            id: unitedBgComponent
            Shape {
                id: bgShape
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                property real w: width
                property real h: height
                property real rad: root.shapeRadius

                ShapePath {
                    fillColor: Appearance.colors.colLayer0
                    strokeColor: "transparent"
                    strokeWidth: 0
                    startX: root.isOnLeft ? bgShape.w : 0
                    startY: 0

                    PathQuad {
                        x: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        y: bgShape.rad
                        controlX: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        controlY: 0
                    }
                    PathLine {
                        x: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        y: bgShape.h - bgShape.rad
                    }
                    PathQuad {
                        x: root.isOnLeft ? bgShape.w : 0
                        y: bgShape.h
                        controlX: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        controlY: bgShape.h
                    }
                    PathLine {
                        x: root.isOnLeft ? 0 : bgShape.w
                        y: bgShape.h
                    }
                    PathLine {
                        x: root.isOnLeft ? 0 : bgShape.w
                        y: 0
                    }
                    PathLine {
                        x: root.isOnLeft ? bgShape.w : 0
                        y: 0
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Appearance.colors.colLayer0Border
                    strokeWidth: 1
                    capStyle: ShapePath.FlatCap
                    startX: root.isOnLeft ? bgShape.w : 0
                    startY: 0

                    PathQuad {
                        x: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        y: bgShape.rad
                        controlX: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        controlY: 0
                    }
                    PathLine {
                        x: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        y: bgShape.h - bgShape.rad
                    }
                    PathQuad {
                        x: root.isOnLeft ? bgShape.w : 0
                        y: bgShape.h
                        controlX: root.isOnLeft ? bgShape.w - bgShape.rad : bgShape.rad
                        controlY: bgShape.h
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: root.sidebarPadding
            anchors.bottomMargin: root.sidebarPadding
            anchors.leftMargin: root.sidebarPadding + (root.isFloating ? root.shapeRadius : (root.isOnLeft ? 0 : root.shapeRadius))
            anchors.rightMargin: root.sidebarPadding + (root.isFloating ? root.shapeRadius : (root.isOnLeft ? root.shapeRadius : 0))
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 25
                color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)
                clip: false

                Item {
                    anchors.fill: parent

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

                    Item {
                        id: floatingBadge
                        width: root.floatingBadgeSize
                        height: root.floatingBadgeSize
                        anchors.right: parent.right
                        anchors.rightMargin: root.floatingBadgeRightPadding
                        anchors.verticalCenter: parent.verticalCenter

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
                            visible: root.allowStickerFallback && !welcomeStickerPortable.visible && status === Image.Ready
                        }

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
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.hasTabs ? 85 : 0
                visible: root.hasTabs
                radius: 24
                color: Qt.rgba(0, 0, 0, 0.15)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)
                clip: true

                ListView {
                    id: tabsListView
                    anchors.fill: parent
                    anchors.margins: 4
                    orientation: ListView.Horizontal
                    spacing: 4

                    model: root.tabButtonList

                    interactive: true
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    function clampTabsContentX() {
                        const maxX = Math.max(0, tabsListView.contentWidth - tabsListView.width)
                        if (tabsListView.contentX < 0) tabsListView.contentX = 0
                        else if (tabsListView.contentX > maxX) tabsListView.contentX = maxX
                    }

                    onWidthChanged: clampTabsContentX()
                    onContentWidthChanged: clampTabsContentX()

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true

                        property real wheelScale: 1.2

                        onWheel: (wheel) => {
                            const dy = wheel.angleDelta ? wheel.angleDelta.y : 0
                            const dx = wheel.angleDelta ? wheel.angleDelta.x : 0
                            const delta = (dy !== 0) ? dy : dx
                            if (delta === 0) return

                            tabsListView.contentX = tabsListView.contentX - (delta * wheelScale)
                            tabsListView.clampTabsContentX()

                            wheel.accepted = true
                        }
                    }

                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        height: 3
                        anchors.bottom: parent.bottom
                    }

                    delegate: Item {
                        id: navItem
                        required property var modelData
                        required property int index

                        width: Math.max(100, (tabsListView.width / Math.min(root.tabButtonList.length, 4)) - 4)
                        height: tabsListView.height - 8

                        readonly property bool isActive: swipeView.currentIndex === index

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignHCenter
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
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
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

            Rectangle {
                id: contentFrame
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 28

                color: Qt.rgba(theme.colBase.r, theme.colBase.g, theme.colBase.b, 0.20)
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

                    clip: true

                    contentChildren: [
                        systemPage.createObject(root),
                        fondosPage.createObject(root),
                        ...(root.aiChatEnabled ? [aiChat.createObject(root)] : []),
                        ...(root.translatorEnabled ? [translator.createObject(root)] : []),
                        ...(root.wallpapersEnabled ? [wallpaperBrowser.createObject(root)] : []),
                        ...(root.animeEnabled ? [anime.createObject(root)] : [])
                    ]
                }
            }

            Component { id: systemPage; Pages.OverviewPage { theme: theme } }
            Component { id: fondosPage; Pages.WallpapersPage { theme: theme } }
            Component { id: wallpaperBrowser; WallpaperBrowserUI { } }
            Component { id: aiChat; AiChat { } }
            Component { id: translator; Translator { } }
            Component { id: anime; Anime { } }
        }
    }
}
