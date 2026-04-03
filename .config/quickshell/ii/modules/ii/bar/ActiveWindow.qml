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

    property bool enableAnimations: Config.options.appearance.enableAnimations

    property bool vertical: false
    
    readonly property bool isRightSide: Config.options.bar.bottom || Config.runtime.bar.position === "right"

    property int maxSize: 165
    
    readonly property int dynamicMargin: root.vertical ? 6 : Math.max(2, Math.round(root.height * 0.05))
    readonly property int dynamicTitleSize: Math.max(10, Math.min(13, Math.round(root.height * 0.30)))
    readonly property int dynamicLabelSize: Math.max(7, Math.min(9, Math.round(root.height * 0.18)))

    property bool hideBackground: true
    property bool parallaxEnabled: true
    property bool prismaticBorder: true

    property int titleScrollPxPerSecond: 25
    property int titleScrollPauseStartMs: 450
    property int titleScrollPauseEndMs: 650

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property real prismAngle: 0.0
    property point parallaxOffset: Qt.point(0, 0)

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode) ? Appearance.m3colors.darkmode : false

    readonly property color titleColor: Appearance.colors.colOnLayer1
    readonly property color labelColor: Appearance.colors.colOnLayer2
    readonly property real labelOpacity: 1.0

    readonly property bool titleShadowEnabled: true
    readonly property color titleShadowColor: themeIsDark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.18)
    readonly property color labelShadowColor: themeIsDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.12)

    readonly property color capsuleFill: Appearance.colors.colLayer1
    readonly property color capsuleBorder: Appearance.colors.colLayer3
    readonly property color capsuleInner: Appearance.colors.colLayer2

    QtObject {
        id: internal

        property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
        property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

        property bool isDesktop: !root.activeWindow && !biggestWindow

        property string classText: {
            if (focusingThisMonitor && root.activeWindow?.activated) return root.activeWindow?.appId || root.activeWindow?.class || "System"
            if (biggestWindow) return biggestWindow.class
            return "Desktop"
        }

        property string titleText: {
            if (focusingThisMonitor && root.activeWindow?.activated) return root.activeWindow?.title || "Unknown"
            if (biggestWindow) return biggestWindow.title
            return `Workspace ${monitor?.activeWorkspace?.id ?? 1}`
        }
    }

    TextMetrics {
        id: classTextMetrics
        text: internal.classText.toUpperCase()
        font.pixelSize: root.dynamicLabelSize
        font.bold: true
    }

    TextMetrics {
        id: titleTextMetrics
        text: internal.titleText
        font.pixelSize: root.dynamicTitleSize
        font.bold: true
    }

    readonly property real calculatedWidth: Math.max(classTextMetrics.width, titleTextMetrics.width) + 24

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : Math.min(root.maxSize, calculatedWidth)
    implicitHeight: vertical ? Math.min(root.maxSize, calculatedWidth) : Appearance.sizes.barHeight

    Behavior on implicitWidth { 
        enabled: enableAnimations
        SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } 
    }
    Behavior on implicitHeight { 
        enabled: enableAnimations
        SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } 
    }

    NumberAnimation on prismAngle {
        from: 0
        to: 360
        duration: 10000
        loops: Animation.Infinite
        running: root.prismaticBorder && root.visible && root.enableAnimations
    }

    Rectangle {
        id: bgCapsule
        visible: !root.hideBackground
        anchors.fill: parent
        anchors.margins: 2
        radius: root.vertical ? (width / 2) : 10
        antialiasing: true
        clip: true
        color: root.capsuleFill
        border.width: 1
        border.color: ColorUtils.transparentize(root.capsuleBorder, root.themeIsDark ? 0.35 : 0.50)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: ColorUtils.transparentize(root.capsuleInner, root.themeIsDark ? 0.45 : 0.60)
            opacity: 0.55
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1.5
            opacity: root.prismaticBorder ? 0.85 : 0.0
            layer.enabled: root.prismaticBorder
            layer.effect: ConicalGradient {
                angle: root.prismAngle
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(root.capsuleBorder.r, root.capsuleBorder.g, root.capsuleBorder.b, 0.00) }
                    GradientStop { position: 0.25; color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.18) }
                    GradientStop { position: 0.5; color: Qt.rgba(root.capsuleBorder.r, root.capsuleBorder.g, root.capsuleBorder.b, 0.00) }
                    GradientStop { position: 0.75; color: Qt.rgba(Appearance.colors.colSecondary.r, Appearance.colors.colSecondary.g, Appearance.colors.colSecondary.b, 0.16) }
                    GradientStop { position: 1.0; color: Qt.rgba(root.capsuleBorder.r, root.capsuleBorder.g, root.capsuleBorder.b, 0.00) }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: root.dynamicMargin
        anchors.bottomMargin: root.dynamicMargin
        x: root.parallaxOffset.x
        y: root.parallaxOffset.y

        Behavior on x { 
            enabled: enableAnimations
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad } 
        }
        Behavior on y { 
            enabled: enableAnimations
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad } 
        }

        Column {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.vertical
            spacing: -1

            StyledText {
                width: parent.width
                visible: root.height >= 33
                text: internal.classText.toUpperCase()
                font.pixelSize: root.dynamicLabelSize
                font.bold: true
                color: root.labelColor
                opacity: root.labelOpacity
                elide: Text.ElideRight

                layer.enabled: root.titleShadowEnabled
                layer.effect: DropShadow {
                    verticalOffset: root.themeIsDark ? 1 : 0
                    radius: root.themeIsDark ? 6 : 3
                    samples: root.themeIsDark ? 14 : 8
                    color: root.labelShadowColor
                }
            }

            Item {
                width: parent.width
                height: titleTextMetrics.height
                clip: true

                StyledText {
                    id: mainTitle
                    text: internal.titleText
                    font.pixelSize: root.dynamicTitleSize
                    font.bold: true
                    color: root.titleColor
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    
                    property bool shouldScroll: titleTextMetrics.width > parent.width

                    layer.enabled: root.titleShadowEnabled
                    layer.effect: DropShadow {
                        verticalOffset: root.themeIsDark ? 1 : 0
                        radius: root.themeIsDark ? 8 : 4
                        samples: root.themeIsDark ? 16 : 10
                        color: root.titleShadowColor
                    }

                    SequentialAnimation on x {
                        running: mainTitle.shouldScroll && root.visible && mouseArea.containsMouse && root.enableAnimations
                        loops: Animation.Infinite
                        PauseAnimation { duration: root.titleScrollPauseStartMs }
                        NumberAnimation {
                            to: -(titleTextMetrics.width - mainTitle.parent.width)
                            duration: Math.max(250, Math.round(1000 * ((titleTextMetrics.width - mainTitle.parent.width) / root.titleScrollPxPerSecond)))
                            easing.type: Easing.InOutSine
                        }
                        PauseAnimation { duration: root.titleScrollPauseEndMs }
                        NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.vertical
            clip: true

            Item {
                width: parent.height
                height: parent.width
                anchors.centerIn: parent
                rotation: root.isRightSide ? 90 : -90
                
                StyledText {
                    anchors.centerIn: parent
                    text: internal.titleText
                    font.pixelSize: root.dynamicTitleSize
                    font.bold: true
                    color: root.titleColor
                    width: parent.width
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
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
        onExited: {
            if(enableAnimations) {
                root.parallaxOffset = Qt.point(0, 0)
                mainTitle.x = 0
            }
        }
        onPositionChanged: {
            if (!root.parallaxEnabled || !enableAnimations) return 
            root.parallaxOffset = Qt.point((width/2 - mouseX) * 0.05, (height/2 - mouseY) * 0.05)
        }
        onClicked: if(enableAnimations) clickSquish.restart()
    }
}
