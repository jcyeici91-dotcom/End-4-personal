import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: rightSidebarButton

    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    Layout.rightMargin: Appearance.rounding.screenRounding
    Layout.fillWidth: false

    property int iconTargetSize: 28
    property int buttonPadding: 4

    Layout.preferredWidth: iconTargetSize + buttonPadding * 2
    Layout.preferredHeight: iconTargetSize + buttonPadding * 2
    width: Layout.preferredWidth
    height: Layout.preferredHeight

    toggled: GlobalStates.sidebarRightOpen

    onClicked: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        clickFx.restart()
    }

    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    // FX (press + pop + glow + heartbeat)
     property real pressScale: 1.0
    property real popScale: 1.0
    property real glowOpacity: 0.0
    property real glowScale: 0.90

    // Heartbeat
    property bool hoveredFx: false
    property real pulse: 0.0
    property bool heartbeatActive: (toggled || hoveredFx)
    property real pulseAmp: toggled ? 0.075 : 0.040  // más fuerte si está activo

    // Press “squish”
    onPressed: {
        pressAnim.stop()
        pressAnim.to = 0.86
        pressAnim.restart()
    }
    onReleased: {
        pressAnim.stop()
        pressAnim.to = 1.0
        pressAnim.restart()
    }
    onCanceled: {
        pressAnim.stop()
        pressAnim.to = 1.0
        pressAnim.restart()
    }

    NumberAnimation {
        id: pressAnim
        target: rightSidebarButton
        property: "pressScale"
        duration: 95
        easing.type: Easing.OutCubic
        property real to: 1.0
        onRunningChanged: if (!running) rightSidebarButton.pressScale = to
    }

    // “Pop” al click + glow sutil
    SequentialAnimation {
        id: clickFx
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: rightSidebarButton
                property: "popScale"
                to: 0.92
                duration: 65
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: rightSidebarButton
                property: "glowOpacity"
                from: 0.0
                to: 0.55
                duration: 90
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: rightSidebarButton
                property: "glowScale"
                from: 0.85
                to: 1.18
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        NumberAnimation {
            target: rightSidebarButton
            property: "popScale"
            to: 1.0
            duration: 180
            easing.type: Easing.OutBack
            easing.overshoot: 1.30
        }

        NumberAnimation {
            target: rightSidebarButton
            property: "glowOpacity"
            to: 0.0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    // Latido “corazón” (loop) cuando está toggled o hover
    SequentialAnimation on pulse {
        running: rightSidebarButton.heartbeatActive
        loops: Animation.Infinite

        NumberAnimation { from: 0.00; to: 1.00; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { from: 1.00; to: 0.15; duration: 120; easing.type: Easing.InOutCubic }
        NumberAnimation { from: 0.15; to: 0.85; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { from: 0.85; to: 0.00; duration: 180; easing.type: Easing.InOutCubic }
        PauseAnimation { duration: 700 }
    }

    onHeartbeatActiveChanged: if (!heartbeatActive) pulse = 0.0

    // Captura hover sin interferir con el click del RippleButton
    MouseArea {
        anchors.fill: parent
        z: 999
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: rightSidebarButton.hoveredFx = true
        onExited: rightSidebarButton.hoveredFx = false
    }

    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: rightSidebarButton.iconTargetSize
        height: rightSidebarButton.iconTargetSize
        transformOrigin: Item.Center

        // escala final (press * pop * latido)
        scale: (rightSidebarButton.pressScale * rightSidebarButton.popScale)
               * (1.0 + rightSidebarButton.pulse * rightSidebarButton.pulseAmp)

        // Glow “soft ring” (aparece al click)
        Rectangle {
            id: glowRing
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: rightSidebarButton.toggled
                ? Qt.rgba(
                      Appearance.colors.colOnSecondaryContainer.r,
                      Appearance.colors.colOnSecondaryContainer.g,
                      Appearance.colors.colOnSecondaryContainer.b,
                      0.95
                  )
                : Qt.rgba(
                      Appearance.colors.colOnLayer1.r,
                      Appearance.colors.colOnLayer1.g,
                      Appearance.colors.colOnLayer1.b,
                      0.70
                  )
            opacity: rightSidebarButton.glowOpacity
            scale: rightSidebarButton.glowScale
            antialiasing: true

            layer.enabled: opacity > 0.01
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 10
                samples: 24
                color: Qt.rgba(
                    Appearance.m3colors.m3primary.r,
                    Appearance.m3colors.m3primary.g,
                    Appearance.m3colors.m3primary.b,
                    0.30
                )
            }
        }

        // SVG base
        Image {
            id: svgSource
            anchors.fill: parent
        source: Qt.resolvedUrl("../../../assets/icons/nixos-symbolic.svg")
            sourceSize.width: rightSidebarButton.iconTargetSize * 2
            sourceSize.height: rightSidebarButton.iconTargetSize * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: false
        }

        // Color según toggled
        ColorOverlay {
            anchors.fill: svgSource
            source: svgSource
            color: rightSidebarButton.toggled
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer1
        }
    }
}

