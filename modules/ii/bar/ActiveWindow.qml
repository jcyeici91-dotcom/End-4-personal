import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property bool vertical: false

    // Configuración visual
    property int maxSize: 350
    property bool isFixedSize: Config.options.bar.activeWindow.fixedSize
    property int fixedSize: vertical ? 150 : 250

    property bool parallaxEnabled: true
    property bool prismaticBorder: true

    property bool liveTitleEnabled: true

    property int liveTitleMaxShrinkPx: 60
    property int liveTitleRightExpandPx: 12
    property int liveTitleMinWidthPx: 120
    property int liveTitleWidthAnimMs: 150

    property int titleScrollSpeedFactor: 18

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property real prismAngle: 0.0
    property point parallaxOffset: Qt.point(0, 0)

    QtObject {
        id: internal
        property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
        property var biggestWindow: HyprlandData.biggestWindowForWorkspace(
            HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id
        )

        property bool isDesktop: !root.activeWindow && !biggestWindow

        property string classText: {
            if (focusingThisMonitor && root.activeWindow?.activated)
                return root.activeWindow?.appId || root.activeWindow?.class || "System"
            if (biggestWindow) return biggestWindow.class
            return "Desktop"
        }

        property string titleText: {
            if (focusingThisMonitor && root.activeWindow?.activated)
                return root.activeWindow?.title || "Unknown"
            if (biggestWindow) return biggestWindow.title
            return `Workspace ${monitor?.activeWorkspace?.id ?? 1}`
        }

        property string iconSource: {
            return Quickshell.iconPath(AppSearch.guessIcon(classText), "computer")
        }
    }

    implicitWidth: vertical
        ? Appearance.sizes.barHeight
        : (isFixedSize ? fixedSize : Math.min(contentRow.implicitWidth + 30, maxSize))

    implicitHeight: vertical
        ? (isFixedSize ? fixedSize : Math.min(contentRow.implicitWidth + 30, maxSize))
        : Appearance.sizes.barHeight

    Behavior on implicitWidth { SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } }
    Behavior on implicitHeight { SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } }

    NumberAnimation on prismAngle {
        from: 0; to: 360; duration: 10000; loops: Animation.Infinite
        // aunque siga corriendo, ya no se ve porque apagamos bgCapsule
        running: root.prismaticBorder && root.visible
    }

        Rectangle {
        id: bgCapsule
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: Appearance.colors.colOnSurface
        opacity: 0.0
        visible: false          // <-  no se dibuja nunca
        enabled: false          // <- y no procesa nada

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1.5
            opacity: 0.0

            layer.enabled: false
            layer.effect: ConicalGradient {
                angle: root.prismAngle
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.25; color: Qt.rgba(1,1,1,0.3) }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 0.75; color: Qt.rgba(1,1,1,0.3) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        border.width: 0
        border.color: "transparent"
    }

    Item {
        anchors.fill: parent
        x: root.parallaxOffset.x
        y: root.parallaxOffset.y

        Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            rotation: vertical ? 90 : 0
            spacing: 12

            Item {
                id: iconContainer
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                    Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    visible: false
                }

                Image {
                    id: appIcon
                    anchors.fill: parent
                    source: internal.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true

                    scale: 1.0
                    onSourceChanged: popAnim.restart()

                    SequentialAnimation {
                        id: popAnim
                        NumberAnimation { target: appIcon; property: "scale"; from: 0.5; to: 1.25; duration: 200; easing.type: Easing.OutBack }
                        NumberAnimation { target: appIcon; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutQuad }
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.8
                    shadowOpacity: 0.3
                    shadowVerticalOffset: 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    visible: !root.vertical
                    Layout.fillWidth: true
                    text: internal.classText.toUpperCase()
                    font.pixelSize: 9
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Appearance.colors.colSubtext
                    opacity: 0.65
                    elide: Text.ElideRight
                }

                Item {
                    id: titleViewport
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleTextMetrics.height
                    clip: true

                    property int baseWidth: Math.min(titleTextMetrics.width, root.maxSize - 60)
                    property int delta: Math.max(0, titleTextMetrics.width - baseWidth)

                    // Scroll SOLO cuando el mouse está encima
                    readonly property bool hoverScrollEnabled: mouseArea.containsMouse

                    property real progress: {
                        if (!mainTitle.shouldScroll || delta <= 0) return 0.0
                        return Math.max(0.0, Math.min(1.0, (-mainTitle.x) / delta))
                    }

                    property int shrinkNow: {
                        if (!(root.liveTitleEnabled && mainTitle.shouldScroll && hoverScrollEnabled)) return 0
                        return Math.round(root.liveTitleMaxShrinkPx * progress)
                    }

                    property int expandNow: {
                        if (!(root.liveTitleEnabled && mainTitle.shouldScroll && hoverScrollEnabled)) return 0
                        return Math.round(root.liveTitleRightExpandPx * (1.0 - progress))
                    }

                    property int liveWidth: {
                        var w = baseWidth + expandNow - shrinkNow
                        return Math.max(root.liveTitleMinWidthPx, w)
                    }

                    Layout.preferredWidth: liveWidth

                    Behavior on liveWidth {
                        NumberAnimation {
                            duration: root.liveTitleWidthAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    TextMetrics {
                        id: titleTextMetrics
                        text: internal.titleText
                        font.pixelSize: Appearance.font.pixelSize.medium
                        font.bold: true
                    }

                    StyledText {
                        id: mainTitle
                        text: internal.titleText
                        font.pixelSize: Appearance.font.pixelSize.medium
                        font.bold: true
                        color: Appearance.colors.colOnLayer0

                        property bool shouldScroll: titleTextMetrics.width > titleViewport.baseWidth

                        anchors.verticalCenter: parent.verticalCenter
                        x: 0

                        scale: 1.0 - (root.liveTitleEnabled && shouldScroll && titleViewport.hoverScrollEnabled
                                     ? (0.015 * titleViewport.progress)
                                     : 0.0)
                        transformOrigin: Item.Left

                        SequentialAnimation on x {
                            running: mainTitle.shouldScroll && root.visible && titleViewport.hoverScrollEnabled
                            loops: Animation.Infinite

                            PauseAnimation { duration: 500 }

                            NumberAnimation {
                                to: -(titleTextMetrics.width - titleViewport.baseWidth)
                                duration: (titleTextMetrics.width) * root.titleScrollSpeedFactor
                                easing.type: Easing.InOutSine
                            }

                            PauseAnimation { duration: 700 }

                            NumberAnimation {
                                to: 0
                                duration: (titleTextMetrics.width) * root.titleScrollSpeedFactor
                                easing.type: Easing.InOutSine
                            }
                        }

                        onShouldScrollChanged: {
                            if (!shouldScroll) x = 0
                        }
                    }

                    Connections {
                        target: mouseArea
                        function onContainsMouseChanged() {
                            if (!mouseArea.containsMouse) mainTitle.x = 0
                        }
                    }
                }
            }
        }
    }

    property real contentScale: 1.0
    transform: Scale {
        origin.x: width / 2
        origin.y: height / 2
        xScale: root.contentScale
        yScale: root.contentScale
    }

    SequentialAnimation {
        id: clickSquish
        NumberAnimation { target: root; property: "contentScale"; to: 0.94; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "contentScale"; to: 1.03; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "contentScale"; to: 1.0; duration: 250; easing.type: Easing.OutElastic }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

         onEntered: {
            // nada
        }
        onExited: {
            root.parallaxOffset = Qt.point(0, 0)
            mainTitle.x = 0
        }

        onMouseXChanged: {
            if (root.parallaxEnabled) {
                var centerX = width / 2
                var centerY = height / 2
                root.parallaxOffset = Qt.point(
                    (centerX - mouseX) * 0.05,
                    (centerY - mouseY) * 0.05
                )
            }
        }

        onClicked: clickSquish.restart()
    }
}

