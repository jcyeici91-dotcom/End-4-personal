import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import qs.modules.common            // Appearance.*
import qs.modules.common.widgets
import qs.services                  // Translation.*

import "../widgets" as Widgets

Rectangle {
    id: block

    required property var theme
    required property var dashboard

    // --- COLORES
    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border

    function getLuminance(c) { return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b }
    readonly property bool isDark: getLuminance(surface1) < 0.5

    readonly property color smartAccent: isDark ? "#40c4ff" : "#0091ea"
    readonly property color smartText: isDark ? "#ffffff" : "#1d1d1d"
    readonly property color smartTextMuted: isDark ? "#b0bec5" : "#546e7a"

    // Helpers 
    function safeStr(v, fallback) {
        const s = String(v === undefined || v === null ? "" : v).trim()
        if (s.length === 0 || s === "...") return fallback
        return s
    }
    function safeInt(v, fallback) {
        const n = parseInt(v, 10)
        if (isNaN(n) || !isFinite(n)) return fallback
        return n
    }

    Layout.columnSpan: 2
    Layout.fillWidth: true
    Layout.preferredHeight: 360

    radius: 28
    color: surface1
    border.width: 1
    border.color: border0
    clip: true

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        anchors.topMargin: 18
        z: 2
        spacing: 8

        Rectangle { width: 4; height: 16; radius: 2; color: smartAccent }

        Text {
            text: Translation.tr("System Vitality")
            font.pixelSize: 13
            font.family: theme.fontMain
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: smartText
            opacity: 0.9
        }

        Canvas {
            id: ekgCanvas
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            antialiasing: true

            property real animationProgress: 0.0

            SequentialAnimation on animationProgress {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 0.0; to: 1.0; duration: 2500; easing.type: Easing.Linear }
            }

            onAnimationProgressChanged: requestPaint()
            onWidthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                var midY = h / 2
                var pulseWidth = 50
                var cycleWidth = 180
                var pulseHeight = 12

                ctx.reset()
                ctx.lineWidth = 2
                ctx.strokeStyle = smartAccent
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                var xOffset = animationProgress * cycleWidth

                ctx.beginPath()
                for (var cx = -cycleWidth + xOffset; cx < w; cx += cycleWidth) {
                    if (cx === -cycleWidth + xOffset) ctx.moveTo(cx, midY)
                    else ctx.lineTo(cx, midY)

                    var pulseStart = cx + (cycleWidth - pulseWidth) / 2
                    ctx.lineTo(pulseStart, midY)
                    ctx.lineTo(pulseStart + pulseWidth * 0.1, midY - pulseHeight * 0.2)
                    ctx.lineTo(pulseStart + pulseWidth * 0.4, midY + pulseHeight)
                    ctx.lineTo(pulseStart + pulseWidth * 0.6, midY - pulseHeight * 0.5)
                    ctx.lineTo(pulseStart + pulseWidth * 0.8, midY - pulseHeight * 0.1)
                    ctx.lineTo(pulseStart + pulseWidth * 1.0, midY)
                    ctx.lineTo(cx + cycleWidth, midY)
                }
                ctx.stroke()
            }
        }

        MaterialSymbol {
            id: vitalHeart
            text: "ecg_heart"
            font.pixelSize: 20
            color: smartAccent
            opacity: 0.9
            transformOrigin: Item.Center

            SequentialAnimation {
                running: true
                loops: Animation.Infinite

                ParallelAnimation {
                    NumberAnimation { target: vitalHeart; property: "scale"; to: 1.2; duration: 100; easing.type: Easing.OutQuad }
                    NumberAnimation { target: vitalHeart; property: "opacity"; to: 1.0; duration: 100 }
                }
                NumberAnimation { target: vitalHeart; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.InQuad }
                ParallelAnimation {
                    NumberAnimation { target: vitalHeart; property: "scale"; to: 1.15; duration: 120; easing.type: Easing.OutQuad }
                    NumberAnimation { target: vitalHeart; property: "opacity"; to: 1.0; duration: 120 }
                }
                NumberAnimation { target: vitalHeart; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.InQuad }
                PauseAnimation { duration: 900 }
            }
        }
    }

    Flickable {
        id: statsFlick
        anchors.fill: parent
        anchors.topMargin: 50
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        contentHeight: statsCol.implicitHeight
        contentWidth: width
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            width: 4
            policy: ScrollBar.AsNeeded
            active: statsFlick.moving || statsFlick.flicking
            contentItem: Rectangle {
                radius: 2
                color: smartAccent
                opacity: 0.45
            }
        }

        ColumnLayout {
            id: statsCol
            width: parent.width
            spacing: 8

            // CPU / RAM / TEMPS / DISK
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "memory"
                title: Translation.tr("Processor")
                val: dashboard.cpuVal
                sub: Translation.tr("Total usage")
                prog: parseFloat(dashboard.cpuVal) / 100
                tint: "#ff6b6b"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "sd_card"
                title: Translation.tr("RAM")
                val: dashboard.ramVal
                sub: dashboard.ramDetail
                prog: parseFloat(dashboard.ramVal) / 100
                tint: "#feca57"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "thermostat"
                title: Translation.tr("CPU Temperature")
                val: dashboard.cpuTemp
                sub: Translation.tr("Core Temp")
                prog: parseFloat(dashboard.cpuTemp) / 100.0
                isGauge: true
                tint: "#ff7675"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "device_thermostat"
                title: Translation.tr("GPU Temperature")
                val: dashboard.gpuTemp
                sub: Translation.tr("AMD Radeon")
                prog: parseFloat(dashboard.gpuTemp) / 100.0
                isGauge: true
                tint: "#ff9f43"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "hard_drive"
                title: Translation.tr("Storage")
                val: dashboard.diskUsePct
                sub: dashboard.diskVal + " " + Translation.tr("Free")
                prog: parseFloat(dashboard.diskUsePct) / 100
                tint: "#48dbfb"
            }

            // NETWORK (velocidad)
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "network_check"
                title: "Network"
                val: block.safeStr(dashboard.netDown, "0 KB/s") + " ↓"
                sub: block.safeStr(dashboard.netUp, "0 KB/s") + " ↑" +
                     " | " + block.safeStr(dashboard.netIface, "-")
                isGauge: false
                tint: "#38bdf8"
            }

            // UPDATES
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "system_update"
                title: "System Updates"
                val: block.safeStr(dashboard.totalUpdates, "0")
                sub: "Repo: " + block.safeStr(dashboard.repoUpdates, "0") +
                     " | AUR: " + block.safeStr(dashboard.aurUpdates, "0") +
                     " | Rev: " + block.safeStr(dashboard.lastUpdateCheck, "--:--")
                isGauge: true
                prog: Math.min(block.safeInt(dashboard.totalUpdates, 0) / 50.0, 1.0)
                tint: block.safeInt(dashboard.totalUpdates, 0) > 0 ? "#ef4444" : "#22c55e"
            }

            // SISTEMA (OS/HOST/KERNEL)
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "computer"
                title: block.safeStr(dashboard.osName, "Linux")
                val: block.safeStr(dashboard.hostName, "Host")
                sub: block.safeStr(dashboard.kernelVal, "...") + " (" + block.safeStr(dashboard.archVal, "...") + ")"
                isGauge: false
                tint: "#3b82f6"
            }

            // DISPLAYS (SIN SUB)
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "monitor"
                title: "Displays"
                val: block.safeStr(dashboard.monitorSummary, "...")
                sub: ""
                isGauge: false
                tint: "#a78bfa"
            }

            // PACMAN / YAY / PAQUETES
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "inventory_2"
                title: "Pacman Packages"
                val: block.safeStr(dashboard.pkgTotal, "...")
                sub: "pacman v" + block.safeStr(dashboard.pacmanVer, "…") +
                     " | Explicit: " + block.safeStr(dashboard.pkgExplicit, "...") +
                     " | Deps: " + block.safeStr(dashboard.pkgDeps, "...")
                isGauge: false
                tint: "#fbbf24"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "deployed_code"
                title: "AUR / Foreign Packages"
                val: block.safeStr(dashboard.pkgForeign, "0")
                sub: "yay v" + block.safeStr(dashboard.yayVer, "not-installed") +
                     " | AUR updates: " + block.safeStr(dashboard.aurUpdates, "0")
                isGauge: false
                tint: "#8b5cf6"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "delete_sweep"
                title: "Orphan Packages"
                val: block.safeStr(dashboard.pkgOrphans, "0")
                sub: (block.safeInt(dashboard.pkgOrphans, 0) > 0)
                        ? "Tip: pacman -Qtdq | sudo pacman -Rns -"
                        : "No orphans detected"
                isGauge: false
                tint: block.safeInt(dashboard.pkgOrphans, 0) > 0 ? "#f97316" : "#22c55e"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "folder"
                title: "Pacman Cache"
                val: block.safeStr(dashboard.pacmanCacheSize, "...")
                sub: "/var/cache/pacman/pkg"
                isGauge: false
                tint: "#06b6d4"
            }

            // SNAP / FLATPAK
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "package_2"
                title: "Snap"
                val: block.safeStr(dashboard.snapCount, "0")
                sub: "snapd: " + block.safeStr(dashboard.snapdEnabled, "no") +
                     " | snapd v" + block.safeStr(dashboard.snapVer, "not-installed")
                isGauge: false
                tint: "#f59e0b"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "apps"
                title: "Flatpak"
                val: block.safeStr(dashboard.flatpakCount, "0")
                sub: "flatpak v" + block.safeStr(dashboard.flatpakVer, "not-installed")
                isGauge: false
                tint: "#60a5fa"
            }

            // DISPLAY MANAGER
            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "desktop_windows"
                title: "Display Manager"
                val: block.safeStr(dashboard.dmName, "none")
                sub: "enabled: " + block.safeStr(dashboard.dmEnabled, "no")
                isGauge: false
                tint: block.safeStr(dashboard.dmEnabled, "no") === "yes" ? "#22c55e" : "#94a3b8"
            }

              Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "apps"
                title: Translation.tr("Active Processes")
                val: dashboard.processesVal
                sub: Translation.tr("Total tasks")
                prog: Math.min(parseFloat(dashboard.processesVal) / 500.0, 1.0)
                isGauge: true
                tint: "#a29bfe"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "schedule"
                title: Translation.tr("Uptime")
                val: dashboard.upTimeVal
                sub: Translation.tr("Since start")
                isGauge: false
                tint: smartAccent
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "code_blocks"
                title: Translation.tr("Quickshell")
                val: dashboard.qsVer
                sub: Translation.tr("Installed version")
                isGauge: false
                tint: "#00d2d3"
            }

            Widgets.ResourcePill {
                theme: block.theme; smartText: block.smartText; smartTextMuted: block.smartTextMuted
                surface1: block.surface1; border0: block.border0
                icon: "grid_view"
                title: Translation.tr("Hyprland")
                val: dashboard.hyprVer
                sub: Translation.tr("Compositor")
                isGauge: false
                tint: "#5f27cd"
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}

