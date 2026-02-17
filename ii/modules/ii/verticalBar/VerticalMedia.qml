pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell.Services.Mpris
import "../../common/utils" // Audio.incrementVolume()/decrementVolume()

MouseArea {
    id: root

    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    // Mostrar SI hay reproductor y está Playing o Paused.
    // Ocultar cuando no hay nada (sin player o Stopped).
    readonly property bool showWidget: !!activePlayer
        && (activePlayer.playbackState === MprisPlaybackState.Playing
            || activePlayer.playbackState === MprisPlaybackState.Paused)

    // --- portada: solo aparece cuando está lista (sin placeholder) ---
    readonly property bool hasCoverArt: coverImg.status === Image.Ready

    Layout.fillHeight: true
    implicitWidth: showWidget ? Appearance.sizes.verticalBarWidth : 0
    visible: showWidget
    enabled: showWidget

    // tamaños (manteniendo el botón/progreso original pequeño)
    readonly property int kPad: 5
    readonly property int kCoverSize: Math.max(26, Math.min(40, Math.floor(implicitWidth - 2 * kPad)))
    readonly property int kCoverGap: 8

    // altura: suma portada SOLO si existe (así no deja hueco arriba)
    implicitHeight: showWidget
        ? ((root.hasCoverArt ? (kCoverSize + kCoverGap) : 0) + mediaCircProg.implicitHeight + 10)
        : 0

    // calidad portada
    property int coverRequestPx: 512

    Timer {
        running: showWidget && activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    // INPUTS
    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
    hoverEnabled: false // para que NO aparezcan popups/tooltips por hover

    onPressed: (event) => {
        if (!showWidget) return

        // Click izquierdo: SOLO abre/cierra el popup “bonito” (media controls)
        if (event.button === Qt.LeftButton) {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            return
        }

        if (!activePlayer) return

        // Click medio: play/pause
        if (event.button === Qt.MiddleButton) {
            activePlayer.togglePlaying()
        }
        // Back: anterior
        else if (event.button === Qt.BackButton) {
            activePlayer.previous()
        }
        // Forward o Click derecho: siguiente
        else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
            activePlayer.next()
        }
    }

    // Rueda: volumen
    onWheel: (wheel) => {
        if (!showWidget) return
        wheel.accepted = true
        if (wheel.angleDelta.y > 0) Audio.incrementVolume()
        else Audio.decrementVolume()
    }

    // =========================================================
    // CENTRADO: el botón SIEMPRE al centro
    // =========================================================
    Item {
        id: centerStack
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight

        // PORTADA + EFECTO (ARRIBA) — ambos juntos
        Item {
            id: coverArea
            width: root.kCoverSize
            height: root.kCoverSize
            anchors.horizontalCenter: centerStack.horizontalCenter
            anchors.bottom: mediaCircProg.top
            anchors.bottomMargin: root.hasCoverArt ? root.kCoverGap : 0
            visible: root.hasCoverArt

            // Efecto circular (ring) solo cuando hay portada lista
            Item {
                id: ringBox
                anchors.centerIn: parent
                width: Math.round(parent.width * 1.55)
                height: width
                visible: root.hasCoverArt

                property real phase: 0
                NumberAnimation on phase {
                    running: ringBox.visible && (activePlayer?.playbackState === MprisPlaybackState.Playing)
                    from: 0
                    to: Math.PI * 2
                    duration: 1150
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                Canvas {
                    id: ringCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var c = Appearance.m3colors.m3primary
                        var cx = width / 2
                        var cy = height / 2

                        var minSide = Math.min(width, height)
                        var maxR = (minSide / 2) - 1.5
                        var r0 = minSide * 0.30

                        var amp = (activePlayer?.playbackState === MprisPlaybackState.Playing) ? 0.85 : 0.0
                        var breathe = Math.sin(ringBox.phase * 2.0) * 0.035

                        for (var i = 0; i < 4; i++) {
                            var k = i / 4.0
                            var r = r0
                                  + (k * 2.4)
                                  + (Math.sin(ringBox.phase * 1.7 + i) * amp)
                                  + (r0 * breathe)

                            if (r > maxR) r = maxR

                            var a = 0.30 - k * 0.07
                            ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, Math.max(0, a))
                            ctx.lineWidth = 1.35

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
                            ctx.stroke()
                        }
                    }

                    Connections { target: ringBox; function onPhaseChanged() { ringCanvas.requestPaint() } }
                    Component.onCompleted: requestPaint()
                }
            }

            // Portada circular
            Item {
                id: coverClip
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.88)
                height: width
                visible: root.hasCoverArt

                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                    antialiasing: true
                    visible: false
                }

                Item {
                    id: coverContent
                    anchors.fill: parent
                    visible: false

                    Image {
                        id: coverImg
                        anchors.fill: parent
                        source: (activePlayer?.trackArtUrl && activePlayer.trackArtUrl.length > 0)
                            ? activePlayer.trackArtUrl
                            : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: root.coverRequestPx
                        sourceSize.height: root.coverRequestPx
                        mipmap: true
                        smooth: true
                        asynchronous: true
                        cache: true
                        autoTransform: true
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: coverContent
                    maskSource: coverMask
                }

                // borde sutil SOLO con portada
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    antialiasing: true
                    border.width: 1
                    border.color: Qt.rgba(
                        Appearance.m3colors.m3primary.r,
                        Appearance.m3colors.m3primary.g,
                        Appearance.m3colors.m3primary.b,
                        0.65
                    )
                }
            }
        }

        // BOTÓN/PROGRESO (CENTRO) — tamaño original
        ClippedFilledCircularProgress {
            id: mediaCircProg
            anchors.horizontalCenter: centerStack.horizontalCenter
            anchors.verticalCenter: centerStack.verticalCenter

            implicitSize: 20
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"

                    // >>> AQUÍ se agranda el ícono de pausa/música:
                    // iconSize: Appearance.font.pixelSize.normal
                    iconSize: Appearance.font.pixelSize.normal

                    color: Appearance.m3colors.m3onSecondaryContainer
                    opacity: activePlayer ? 1.0 : 0.55
                }
            }
        }
    }

    // Nota: NO hay Bar.StyledPopup aquí (para evitar el popup gris).
    // El “bonito” es el panel de mediaControls que se abre con GlobalStates.mediaControlsOpen.
}

