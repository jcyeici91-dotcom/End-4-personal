pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

MouseArea {
    id: wallpaperSelectorContent

    property bool useDarkMode: Appearance.m3colors.darkmode
    property string defaultWallpaperDir: Directories.pictures + "/Wallpapers"
    property string animatedWallpaperDir: Directories.pictures + "/Wallpapers/animados"
    property string currentWallpaperDir: defaultWallpaperDir
    
    property int currentViewMode: 0 

    property int sliceWidth: 120
    property int expandedWidth: Math.min(width * 0.55, 750)
    property int skewOffset: 35
    property int sliceSpacing: -18

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            Wallpapers.select(filePath, wallpaperSelectorContent.useDarkMode)
        }
    }

    function getActiveView() {
        if (currentViewMode === 0) return sliceListView
        if (currentViewMode === 1) return gridListView
        if (currentViewMode === 2) return carouselListView
        if (currentViewMode === 3) return arcListView
        return null
    }

    function currentItemData() {
        let view = getActiveView()
        if (!view || !view.model || view.count <= 0) return null
        if (typeof view.model.get === "function") return view.model.get(view.currentIndex)
        return null
    }

    function activateCurrent() {
        const item = currentItemData()
        if (!item) return
        wallpaperSelectorContent.selectWallpaperPath(item.actualPath || item.filePath)
    }

    function moveSelection(delta) {
        let view = getActiveView()
        if (!view || view.count <= 0) return
        let next = view.currentIndex + delta
        if (next < 0) next = view.count - 1
        if (next >= view.count) next = 0
        view.currentIndex = next
    }

    acceptedButtons: Qt.BackButton | Qt.ForwardButton | Qt.LeftButton
    hoverEnabled: true
    focus: true

    onClicked: mouse => { forceActiveFocus() }

    onPressed: event => {
        if (event.button === Qt.BackButton) {
            moveSelection(-1); event.accepted = true
        } else if (event.button === Qt.ForwardButton) {
            moveSelection(1); event.accepted = true
        }
    }

    onWheel: wheel => {
        if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
            moveSelection(-1)
        } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
            moveSelection(1)
        }
        wheel.accepted = true
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            moveSelection(-1); event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            moveSelection(1); event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            activateCurrent(); event.accepted = true
        }
    }

    implicitWidth: 1200
    implicitHeight: 620

    Component.onCompleted: {
        Wallpapers.setDirectory(currentWallpaperDir)
        Qt.callLater(() => forceActiveFocus())
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                Wallpapers.setDirectory(currentWallpaperDir)
                Qt.callLater(() => wallpaperSelectorContent.forceActiveFocus())
            }
        }
    }

    Component {
        id: mediaPreviewFactory
        Item {
            id: mediaRoot
            anchors.fill: parent
            property var mData: parent.itemModelData
            property bool mActive: parent.itemActive
            
            property string fileExt: mData && mData.fileName ? mData.fileName.split('.').pop().toLowerCase() : ""
            property bool isVid: ["mp4", "webm", "mkv", "mov"].includes(fileExt)
            property bool isGif: fileExt === "gif"
            
            function getUrl(path) {
                if (!path) return ""
                return path.startsWith("file://") ? path : "file://" + path
            }

            Image {
                anchors.fill: parent
                visible: (!mediaRoot.isVid && !mediaRoot.isGif) || (mediaRoot.isVid && !mediaRoot.mActive)
                source: mediaRoot.mData ? getUrl(mediaRoot.mData.thumbnail || mediaRoot.mData.previewPath || mediaRoot.mData.filePath) : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: true
            }
            
            AnimatedImage {
                anchors.fill: parent
                visible: mediaRoot.isGif
                source: mediaRoot.isGif && mediaRoot.mData ? getUrl(mediaRoot.mData.filePath) : ""
                fillMode: Image.PreserveAspectCrop
                playing: mediaRoot.mActive
            }
            
            Loader {
                anchors.fill: parent
                active: mediaRoot.isVid
                sourceComponent: Item {
                    MediaPlayer {
                        id: mplayer
                        source: mediaRoot.mData ? mediaRoot.getUrl(mediaRoot.mData.filePath) : ""
                        audioOutput: AudioOutput { muted: true }
                        videoOutput: voutput
                        loops: MediaPlayer.Infinite
                    }
                    VideoOutput {
                        id: voutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                    }
                    Connections {
                        target: mediaRoot
                        function onMActiveChanged() {
                            if (mediaRoot.mActive) mplayer.play()
                            else mplayer.pause()
                        }
                    }
                    Component.onCompleted: {
                        if (mediaRoot.mActive) mplayer.play()
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            id: premiumFilterBar
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.preferredHeight: 48
            Layout.preferredWidth: filterRow.implicitWidth + 32
            radius: height / 2
            color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.7)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Row {
                id: filterRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 120; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentWallpaperDir === wallpaperSelectorContent.defaultWallpaperDir
                    property bool isHovered: staticMouseArea.containsMouse

                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰋩"
                            font.pixelSize: 14
                            color: parent.parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                        Text {
                            text: "Estáticos"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: parent.parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                    }

                    MouseArea {
                        id: staticMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallpaperSelectorContent.currentWallpaperDir = wallpaperSelectorContent.defaultWallpaperDir
                            Wallpapers.setDirectory(wallpaperSelectorContent.currentWallpaperDir)
                        }
                    }
                }

                Rectangle {
                    width: 120; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentWallpaperDir === wallpaperSelectorContent.animatedWallpaperDir
                    property bool isHovered: animMouseArea.containsMouse

                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰕧"
                            font.pixelSize: 14
                            color: parent.parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                        Text {
                            text: "Animados"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: parent.parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                    }

                    MouseArea {
                        id: animMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallpaperSelectorContent.currentWallpaperDir = wallpaperSelectorContent.animatedWallpaperDir
                            Wallpapers.setDirectory(wallpaperSelectorContent.currentWallpaperDir)
                        }
                    }
                }

                Rectangle {
                    width: 1; height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, 0.2)
                    anchors.margins: 4
                }

                Rectangle {
                    width: 40; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentViewMode === 0
                    property bool isHovered: view0MouseArea.containsMouse
                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰕰"; font.pixelSize: 18; color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0 }
                    MouseArea { id: view0MouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaperSelectorContent.currentViewMode = 0 }
                }

                Rectangle {
                    width: 40; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentViewMode === 1
                    property bool isHovered: view1MouseArea.containsMouse
                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰾍"; font.pixelSize: 18; color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0 }
                    MouseArea { id: view1MouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaperSelectorContent.currentViewMode = 1 }
                }

                Rectangle {
                    width: 40; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentViewMode === 2
                    property bool isHovered: view2MouseArea.containsMouse
                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰞉"; font.pixelSize: 18; color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0 }
                    MouseArea { id: view2MouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaperSelectorContent.currentViewMode = 2 }
                }

                Rectangle {
                    width: 40; height: 36; radius: 18
                    property bool isSelected: wallpaperSelectorContent.currentViewMode === 3
                    property bool isHovered: view3MouseArea.containsMouse
                    color: isSelected ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
                    border.width: isSelected ? 0 : 1
                    border.color: isHovered && !isSelected ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰋫"; font.pixelSize: 18; color: parent.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0 }
                    MouseArea { id: view3MouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaperSelectorContent.currentViewMode = 3 }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: wallpaperSelectorContent.currentViewMode

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: sliceListView
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: Wallpapers.folderModel
                    clip: true
                    spacing: wallpaperSelectorContent.sliceSpacing

                    flickDeceleration: 1500
                    maximumFlickVelocity: 3000
                    boundsBehavior: Flickable.StopAtBounds
                    preferredHighlightBegin: (width - wallpaperSelectorContent.expandedWidth) / 2
                    preferredHighlightEnd: (width + wallpaperSelectorContent.expandedWidth) / 2
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: 350
                    
                    header: Item { width: (sliceListView.width - wallpaperSelectorContent.expandedWidth) / 2; height: 1 }
                    footer: Item { width: (sliceListView.width - wallpaperSelectorContent.expandedWidth) / 2; height: 1 }

                    delegate: Item {
                        id: sliceDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property bool isHovered: itemMouseArea.containsMouse
                        readonly property bool isHiddenDir: modelData.fileName === "animados" || modelData.fileName === "gifs" || modelData.fileIsDir === true

                        width: isHiddenDir ? 0 : (isCurrent ? wallpaperSelectorContent.expandedWidth : wallpaperSelectorContent.sliceWidth)
                        height: sliceListView.height
                        visible: !isHiddenDir
                        z: isCurrent ? 100 : (isHovered ? 90 : 50 - Math.abs(index - sliceListView.currentIndex))

                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!isCurrent) sliceListView.currentIndex = index
                                else wallpaperSelectorContent.selectWallpaperPath(modelData.actualPath || modelData.filePath)
                            }
                        }

                        Item {
                            id: sliceImageContainer
                            anchors.fill: parent
                            
                            Loader {
                                anchors.fill: parent
                                sourceComponent: mediaPreviewFactory
                                property var itemModelData: modelData
                                property bool itemActive: sliceDelegate.isCurrent || sliceDelegate.isHovered
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, sliceDelegate.isCurrent ? 0 : (sliceDelegate.isHovered ? 0.2 : 0.55))
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }

                            layer.enabled: true
                            layer.smooth: true
                            layer.samples: 4
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: ShaderEffectSource {
                                    sourceItem: Item {
                                        width: sliceImageContainer.width
                                        height: sliceImageContainer.height
                                        Shape {
                                            anchors.fill: parent
                                            antialiasing: true
                                            preferredRendererType: Shape.CurveRenderer
                                            ShapePath {
                                                fillColor: "white"
                                                strokeColor: "transparent"
                                                startX: wallpaperSelectorContent.skewOffset; startY: 0
                                                PathLine { x: sliceDelegate.width; y: 0 }
                                                PathLine { x: sliceDelegate.width - wallpaperSelectorContent.skewOffset; y: sliceDelegate.height }
                                                PathLine { x: 0; y: sliceDelegate.height }
                                                PathLine { x: wallpaperSelectorContent.skewOffset; y: 0 }
                                            }
                                        }
                                    }
                                }
                                maskThresholdMin: 0.3
                                maskSpreadAtMin: 0.3
                            }
                        }

                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: sliceDelegate.isCurrent ? Appearance.colors.colPrimary : (sliceDelegate.isHovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.1))
                                strokeWidth: sliceDelegate.isCurrent ? 3 : 1
                                Behavior on strokeColor { ColorAnimation { duration: 200 } }
                                startX: wallpaperSelectorContent.skewOffset; startY: 0
                                PathLine { x: sliceDelegate.width; y: 0 }
                                PathLine { x: sliceDelegate.width - wallpaperSelectorContent.skewOffset; y: sliceDelegate.height }
                                PathLine { x: 0; y: sliceDelegate.height }
                                PathLine { x: wallpaperSelectorContent.skewOffset; y: 0 }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.leftMargin: wallpaperSelectorContent.skewOffset
                            anchors.right: parent.right; anchors.rightMargin: wallpaperSelectorContent.skewOffset
                            height: 60
                            color: Qt.rgba(0, 0, 0, 0.7)
                            opacity: sliceDelegate.isCurrent ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                            visible: opacity > 0
                            StyledText {
                                anchors.centerIn: parent
                                text: (modelData.fileName || "").replace(/\.[^/.]+$/, "")
                                color: "white"
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                GridView {
                    id: gridListView
                    anchors.fill: parent
                    anchors.margins: 20
                    model: Wallpapers.folderModel
                    clip: true
                    cellWidth: 260
                    cellHeight: 180
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: gridDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: GridView.isCurrentItem
                        readonly property bool isHovered: gridMouseArea.containsMouse
                        readonly property bool isHiddenDir: modelData.fileName === "animados" || modelData.fileName === "gifs" || modelData.fileIsDir === true

                        width: isHiddenDir ? 0 : gridListView.cellWidth
                        height: isHiddenDir ? 0 : gridListView.cellHeight
                        visible: !isHiddenDir

                        Item {
                            anchors.fill: parent
                            anchors.margins: 12
                            scale: isHovered || isCurrent ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                            Rectangle {
                                id: gridCard
                                anchors.fill: parent
                                radius: 16
                                color: Qt.rgba(0.1, 0.1, 0.1, 1)
                                border.width: isCurrent ? 3 : (isHovered ? 2 : 1)
                                border.color: isCurrent ? Appearance.colors.colPrimary : (isHovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.1))
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.5)
                                    shadowBlur: isHovered ? 0.8 : 0.4
                                    shadowVerticalOffset: isHovered ? 6 : 2
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: gridCard.border.width
                                    
                                    Loader {
                                        anchors.fill: parent
                                        sourceComponent: mediaPreviewFactory
                                        property var itemModelData: modelData
                                        property bool itemActive: gridDelegate.isCurrent || gridDelegate.isHovered
                                    }

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: ShaderEffectSource {
                                            sourceItem: Rectangle {
                                                width: gridCard.width - (gridCard.border.width * 2)
                                                height: gridCard.height - (gridCard.border.width * 2)
                                                radius: 16 - gridCard.border.width
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: gridCard.border.width
                                    radius: 16 - gridCard.border.width
                                    color: Qt.rgba(0, 0, 0, isCurrent ? 0 : (isHovered ? 0.1 : 0.4))
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.margins: gridCard.border.width; height: 40; radius: 16 - gridCard.border.width
                                    color: Qt.rgba(0, 0, 0, 0.8)
                                    opacity: isCurrent || isHovered ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }

                                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 16; color: Qt.rgba(0, 0, 0, 0.8) }
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: (modelData.fileName || "").replace(/\.[^/.]+$/, "")
                                        color: "white"
                                        font.pixelSize: Appearance.font.pixelSize.medium
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                        width: parent.width - 20
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            MouseArea {
                                id: gridMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!isCurrent) gridListView.currentIndex = index
                                    else wallpaperSelectorContent.selectWallpaperPath(modelData.actualPath || modelData.filePath)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: carouselListView
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: Wallpapers.folderModel
                    spacing: -240
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    preferredHighlightBegin: width / 2 - 200
                    preferredHighlightEnd: width / 2 + 200
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: 400

                    header: Item { width: carouselListView.width / 2 - 200; height: 1 }
                    footer: Item { width: carouselListView.width / 2 - 200; height: 1 }

                    delegate: Item {
                        id: carouselDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property bool isHovered: carouselMouseArea.containsMouse
                        readonly property bool isHiddenDir: modelData.fileName === "animados" || modelData.fileName === "gifs" || modelData.fileIsDir === true

                        width: isHiddenDir ? 0 : 400
                        height: carouselListView.height
                        visible: !isHiddenDir

                        property real itemCenter: x + width / 2
                        property real viewCenter: carouselListView.contentX + carouselListView.width / 2
                        property real dist: Math.abs(itemCenter - viewCenter)
                        property real scaleRatio: Math.max(0.65, 1.0 - dist / 800)
                        
                        z: isCurrent ? 100 : Math.floor(scaleRatio * 100)

                        Item {
                            anchors.centerIn: parent
                            width: parent.width * carouselDelegate.scaleRatio
                            height: parent.height * 0.85 * carouselDelegate.scaleRatio

                            Rectangle {
                                id: carouselCard
                                anchors.fill: parent
                                radius: 24
                                color: Qt.rgba(0.1, 0.1, 0.1, 1)
                                border.width: carouselDelegate.isCurrent ? 4 : 2
                                border.color: carouselDelegate.isCurrent ? Appearance.colors.colPrimary : Qt.rgba(1, 1, 1, 0.2)
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.6)
                                    shadowBlur: carouselDelegate.isCurrent ? 1.0 : 0.5
                                    shadowVerticalOffset: carouselDelegate.isCurrent ? 8 : 4
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: carouselCard.border.width
                                    
                                    Loader {
                                        anchors.fill: parent
                                        sourceComponent: mediaPreviewFactory
                                        property var itemModelData: modelData
                                        property bool itemActive: carouselDelegate.isCurrent
                                    }

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: ShaderEffectSource {
                                            sourceItem: Rectangle {
                                                width: carouselCard.width - (carouselCard.border.width * 2)
                                                height: carouselCard.height - (carouselCard.border.width * 2)
                                                radius: 24 - carouselCard.border.width
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: carouselCard.border.width
                                    radius: 24 - carouselCard.border.width
                                    color: Qt.rgba(0, 0, 0, carouselDelegate.isCurrent ? 0 : 0.5)
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.margins: carouselCard.border.width; height: 60; radius: 24 - carouselCard.border.width
                                    color: Qt.rgba(0, 0, 0, 0.8)
                                    opacity: carouselDelegate.isCurrent ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }

                                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 20; color: Qt.rgba(0, 0, 0, 0.8) }
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: (modelData.fileName || "").replace(/\.[^/.]+$/, "")
                                        color: "white"
                                        font.pixelSize: Appearance.font.pixelSize.large
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: carouselMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!carouselDelegate.isCurrent) carouselListView.currentIndex = index
                                    else wallpaperSelectorContent.selectWallpaperPath(modelData.actualPath || modelData.filePath)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: arcListView
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: Wallpapers.folderModel
                    spacing: 20
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    preferredHighlightBegin: width / 2 - 150
                    preferredHighlightEnd: width / 2 + 150
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: 400

                    header: Item { width: arcListView.width / 2 - 150; height: 1 }
                    footer: Item { width: arcListView.width / 2 - 150; height: 1 }

                    delegate: Item {
                        id: arcDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property bool isHovered: arcMouseArea.containsMouse
                        readonly property bool isHiddenDir: modelData.fileName === "animados" || modelData.fileName === "gifs" || modelData.fileIsDir === true

                        width: isHiddenDir ? 0 : 300
                        height: arcListView.height
                        visible: !isHiddenDir

                        property real itemCenter: x + width / 2
                        property real viewCenter: arcListView.contentX + arcListView.width / 2
                        property real dist: itemCenter - viewCenter
                        property real absDist: Math.abs(dist)
                        property real ratio: Math.max(0, 1 - absDist / (arcListView.width / 1.5))
                        
                        y: (1 - ratio) * 80 + (arcListView.height - 400) / 2
                        rotation: dist / 25
                        scale: 0.7 + 0.3 * ratio
                        z: Math.floor(ratio * 100)

                        Rectangle {
                            id: arcCard
                            width: 300
                            height: 400
                            anchors.centerIn: parent
                            radius: 12
                            color: Qt.rgba(0.1, 0.1, 0.1, 1)
                            border.width: arcDelegate.isCurrent ? 4 : 2
                            border.color: arcDelegate.isCurrent ? Appearance.colors.colPrimary : Qt.rgba(1, 1, 1, 0.2)

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.6)
                                shadowBlur: 1.0
                                shadowVerticalOffset: 8
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: arcCard.border.width
                                
                                Loader {
                                    anchors.fill: parent
                                    sourceComponent: mediaPreviewFactory
                                    property var itemModelData: modelData
                                    property bool itemActive: arcDelegate.isCurrent
                                }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: ShaderEffectSource {
                                        sourceItem: Rectangle {
                                            width: arcCard.width - (arcCard.border.width * 2)
                                            height: arcCard.height - (arcCard.border.width * 2)
                                            radius: 12 - arcCard.border.width
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: arcCard.border.width
                                radius: 12 - arcCard.border.width
                                color: Qt.rgba(0, 0, 0, arcDelegate.isCurrent ? 0 : 0.4)
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                anchors.margins: arcCard.border.width; height: 50; radius: 12 - arcCard.border.width
                                color: Qt.rgba(0, 0, 0, 0.8)
                                opacity: arcDelegate.isCurrent ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 16; color: Qt.rgba(0, 0, 0, 0.8) }
                                StyledText {
                                    anchors.centerIn: parent
                                    text: (modelData.fileName || "").replace(/\.[^/.]+$/, "")
                                    color: "white"
                                    font.pixelSize: Appearance.font.pixelSize.medium
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: arcMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!arcDelegate.isCurrent) arcListView.currentIndex = index
                                else wallpaperSelectorContent.selectWallpaperPath(modelData.actualPath || modelData.filePath)
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            visible: {
                if (wallpaperSelectorContent.currentViewMode === 0) return sliceListView.count === 0
                if (wallpaperSelectorContent.currentViewMode === 1) return gridListView.count === 0
                if (wallpaperSelectorContent.currentViewMode === 2) return carouselListView.count === 0
                if (wallpaperSelectorContent.currentViewMode === 3) return arcListView.count === 0
                return false
            }
            anchors.centerIn: parent
            text: Translation.tr("No wallpapers found in ") + wallpaperSelectorContent.currentWallpaperDir
            font.family: Appearance.font.family.reading
            color: Appearance.colors.colOnLayer0
        }
    }
}
