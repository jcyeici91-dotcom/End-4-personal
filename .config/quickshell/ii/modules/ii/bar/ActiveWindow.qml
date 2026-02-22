import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.ui 1.0  

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
    // Detectamos si la barra está a la derecha o a la izquierda
    readonly property bool isRightSide: Config.options.bar.bottom || Config.runtime.bar.position === "right"

    property int maxSize: 165
    property bool isFixedSize: Config.options.bar.activeWindow.fixedSize
    // Le damos un tamaño un poco más largo en vertical para que el texto fluya bien
    property int fixedSize: vertical ? 180 : 250
    readonly property int capsuleSize: isFixedSize ? fixedSize : maxSize

    // --- LÓGICA DE ESTILOS BASADA EN BARCONTENT ---
    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)
    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = UIState.surfaceStyle
            if (s !== "") return s
        }
        switch (barBackgroundStyleFromConfig) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        case 4: return "line"
        default: return "solid"
        }
    }

    property bool hideBackground: resolvedStyle === "crystal" || resolvedStyle === "line"

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

    // Texto
    readonly property color titleColor: Appearance.colors.colOnLayer1
    readonly property color labelColor: Appearance.colors.colOnLayer2
    readonly property real labelOpacity: 1.0

    readonly property bool titleShadowEnabled: true
    readonly property color titleShadowColor: themeIsDark
        ? Qt.rgba(0, 0, 0, 0.55)
        : Qt.rgba(0, 0, 0, 0.18)

    readonly property color labelShadowColor: themeIsDark
        ? Qt.rgba(0, 0, 0, 0.45)
        : Qt.rgba(0, 0, 0, 0.12)

    // Fondo “capsule”
    readonly property color capsuleFill: Appearance.colors.colLayer1
    readonly property color capsuleBorder: Appearance.colors.colLayer3
    readonly property color capsuleInner: Appearance.colors.colLayer2

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

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : capsuleSize
    implicitHeight: vertical ? capsuleSize : Appearance.sizes.barHeight

    Behavior on implicitWidth { SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } }
    Behavior on implicitHeight { SpringAnimation { spring: 3.2; damping: 0.35; epsilon: 0.5 } }

    NumberAnimation on prismAngle {
        from: 0
        to: 360
        duration: 10000
        loops: Animation.Infinite
        running: root.prismaticBorder && root.visible
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
        x: root.parallaxOffset.x
        y: root.parallaxOffset.y

        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        GridLayout {
            id: contentGrid
            anchors.fill: parent
            anchors.margins: root.vertical ? 6 : 10

            // Layout adaptativo: Columna en vertical, Fila en horizontal
            columns: root.vertical ? 1 : 2
            rows: root.vertical ? 2 : 1
            rowSpacing: 10
            columnSpacing: 12

            Item {
                id: iconContainer
                Layout.alignment: root.vertical ? Qt.AlignTop | Qt.AlignHCenter : Qt.AlignVCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.topMargin: root.vertical ? 4 : 0

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    source: internal.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true

                    scale: 1.0
                    onSourceChanged: popAnim.restart()

                    SequentialAnimation {
                        id: popAnim
                        NumberAnimation {
                            target: appIcon; property: "scale"
                            from: 0.5; to: 1.25
                            duration: 200; easing.type: Easing.OutBack
                        }
                        NumberAnimation {
                            target: appIcon; property: "scale"
                            to: 1.0
                            duration: 150; easing.type: Easing.OutQuad
                        }
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.8
                    shadowOpacity: root.themeIsDark ? 0.34 : 0.22
                    shadowVerticalOffset: 1
                }
            }

            // CONTENEDOR MÁGICO DEL TEXTO ROTADO
            Item {
                id: textWrapper
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Item {
                    id: rotatedTextContainer
                    // Invertimos las dimensiones internamente para rotarlo sin que se corte
                    width: root.vertical ? textWrapper.height : textWrapper.width
                    height: root.vertical ? textWrapper.width : textWrapper.height
                    anchors.centerIn: parent

                    // AQUÍ ESTÁ EL SECRETO:
                    // Si la barra está a la derecha, gira 90°. Si está a la izquierda, gira -90° para que sea legible.
                    rotation: root.vertical ? (root.isRightSide ? 90 : -90) : 0

                    ColumnLayout {
                        id: textCol
                        anchors.fill: parent
                        spacing: 0

                        StyledText {
                            id: appClassText
                            // CAMBIO ÚNICO: ocultar “nombre de la app” en vertical, mantenerlo en horizontal
                            visible: !root.vertical

                            Layout.fillWidth: true
                            text: internal.classText.toUpperCase()
                            font.pixelSize: 9
                            font.bold: true
                            font.capitalization: Font.AllUppercase
                            color: root.labelColor
                            opacity: root.labelOpacity
                            elide: Text.ElideRight

                            layer.enabled: root.titleShadowEnabled
                            layer.effect: DropShadow {
                                // Mantenemos la sombra yendo visualmente hacia abajo ajustando la matemática
                                horizontalOffset: root.vertical ? (root.isRightSide ? (root.themeIsDark ? 1 : 0) : (root.themeIsDark ? -1 : 0)) : 0
                                verticalOffset: root.vertical ? 0 : (root.themeIsDark ? 1 : 0)
                                radius: root.themeIsDark ? 6 : 3
                                samples: root.themeIsDark ? 14 : 8
                                color: root.labelShadowColor
                            }
                        }

                        Item {
                            id: titleViewport
                            Layout.fillWidth: true
                            Layout.preferredHeight: titleTextMetrics.height
                            clip: true

                            readonly property int baseWidth: width
                            readonly property int delta: Math.max(0, titleTextMetrics.width - baseWidth)
                            readonly property bool hoverScrollEnabled: mouseArea.containsMouse

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
                                color: root.titleColor

                                anchors.verticalCenter: parent.verticalCenter
                                x: 0

                                property bool shouldScroll: titleTextMetrics.width > titleViewport.baseWidth

                                layer.enabled: root.titleShadowEnabled
                                layer.effect: DropShadow {
                                    horizontalOffset: root.vertical ? (root.isRightSide ? (root.themeIsDark ? 1 : 0) : (root.themeIsDark ? -1 : 0)) : 0
                                    verticalOffset: root.vertical ? 0 : (root.themeIsDark ? 1 : 0)
                                    radius: root.themeIsDark ? 8 : 4
                                    samples: root.themeIsDark ? 16 : 10
                                    color: root.titleShadowColor
                                }

                                SequentialAnimation on x {
                                    id: hoverScrollAnim
                                    running: mainTitle.shouldScroll && root.visible && titleViewport.hoverScrollEnabled
                                    loops: Animation.Infinite

                                    PauseAnimation { duration: root.titleScrollPauseStartMs }

                                    NumberAnimation {
                                        to: -titleViewport.delta
                                        duration: Math.max(250, Math.round(1000 * (titleViewport.delta / root.titleScrollPxPerSecond)))
                                        easing.type: Easing.InOutSine
                                    }

                                    PauseAnimation { duration: root.titleScrollPauseEndMs }

                                    NumberAnimation {
                                        to: 0
                                        duration: Math.max(250, Math.round(1000 * (titleViewport.delta / root.titleScrollPxPerSecond)))
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
            root.parallaxOffset = Qt.point(0, 0)
            mainTitle.x = 0
        }

        onPositionChanged: {
            if (!root.parallaxEnabled) return
            var centerX = width / 2
            var centerY = height / 2
            root.parallaxOffset = Qt.point(
                (centerX - mouseX) * 0.05,
                (centerY - mouseY) * 0.05
            )
        }

        onClicked: clickSquish.restart()
    }
}

