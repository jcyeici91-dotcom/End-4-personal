import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import qs.modules.common            // Appearance.*
import qs.modules.common.widgets
import qs.services                  // Translation.*

import ".." as SidebarLeft
import "../models" as Models
import "../ui" as UI

Item {
    id: page

    required property var theme
    Models.DashboardModel { id: dashboard }
    Models.MusicModel { id: music }

    readonly property int pad: 16
    readonly property int colGap: 12
    readonly property int rowGap: 12

    // --- COLORES DE FONDO
    readonly property color surface0: Appearance.colors.colLayer0
    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border

    // --- LÓGICA DE COLOR 
    function getLuminance(c) { return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b }
    readonly property bool isDark: getLuminance(surface1) < 0.5

    readonly property color smartAccent: isDark ? "#40c4ff" : "#0091ea"
    readonly property color smartText: isDark ? "#ffffff" : "#1d1d1d"
    readonly property color smartTextMuted: isDark ? "#b0bec5" : "#546e7a"

    readonly property color themeAccent: page.theme.colAccent

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

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: mainCol.implicitHeight + page.pad * 2

        ColumnLayout {
            id: mainCol
            x: page.pad
            y: page.pad
            width: flick.width - page.pad * 2
            spacing: page.rowGap

            // 1. CABECERA
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                contentWidth: headerRow.implicitWidth
                contentHeight: 160
                clip: false
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                RowLayout {
                    id: headerRow
                    height: 160
                    spacing: 12

                    // ─── RELOJ ───
                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        radius: 32
                        color: page.surface1
                        border.width: 1
                        border.color: page.border0
                        clip: true

                        SequentialAnimation on border.color {
                            loops: Animation.Infinite
                            ColorAnimation {
                                to: Qt.rgba(page.smartAccent.r, page.smartAccent.g, page.smartAccent.b, 0.5)
                                duration: 3000
                                easing.type: Easing.InOutSine
                            }
                            ColorAnimation {
                                to: page.border0
                                duration: 3000
                                easing.type: Easing.InOutSine
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            spacing: 0

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4

                                Text {
                                    id: hourText
                                    text: dashboard.timeHour
                                    font.pixelSize: 68
                                    font.family: page.theme.fontMain
                                    font.weight: Font.Black
                                    color: page.smartText

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                        shadowBlur: 0.8
                                        shadowVerticalOffset: 2
                                    }
                                }

                                Text {
                                    text: ":"
                                    font.pixelSize: 64
                                    font.family: page.theme.fontMain
                                    color: page.smartTextMuted
                                    Layout.bottomMargin: 6
                                    OpacityAnimator on opacity {
                                        from: 1.0
                                        to: 0.5
                                        duration: 1000
                                        loops: Animation.Infinite
                                        easing.type: Easing.InOutQuad
                                    }
                                }

                                Text {
                                    id: minText
                                    text: dashboard.timeMin
                                    font.pixelSize: 68
                                    font.family: page.theme.fontMain
                                    font.weight: Font.Black
                                    color: page.smartAccent

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(0, 0, 0, 0.4)
                                        shadowBlur: 0.8
                                        shadowVerticalOffset: 2
                                    }
                                }

                                Text {
                                    text: dashboard.timeSec
                                    font.pixelSize: 32
                                    font.family: page.theme.fontMain
                                    font.weight: Font.Bold
                                    color: page.smartTextMuted
                                    Layout.alignment: Qt.AlignBaseline
                                    Layout.bottomMargin: 9
                                }
                            }

                            // FECHA
                            MarqueeText {
                                Layout.topMargin: 4
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                text: dashboard.dateString
                                font.pixelSize: 14
                                font.bold: true
                                font.capitalization: Font.AllUppercase
                                color: page.smartText
                                centered: true
                            }
                        }
                    }

                    // ─── CLIMA ───
                    Rectangle {
                        Layout.preferredWidth: 160
                        Layout.fillHeight: true
                        radius: 32
                        color: page.surface1
                        border.width: 1
                        border.color: page.border0
                        clip: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            spacing: 4

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: dashboard.weatherIconFromCode(dashboard.weatherCode)
                                font.pixelSize: 42
                                color: page.smartAccent

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                                    shadowBlur: 0.5
                                }

                                SequentialAnimation on anchors.verticalCenterOffset {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0; to: -3; duration: 2500; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: -3; to: 0; duration: 2500; easing.type: Easing.InOutSine }
                                }
                            }

                            Text {
                                text: dashboard.weatherTemp
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                font.family: page.theme.fontMain
                                color: page.smartText
                                Layout.alignment: Qt.AlignHCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                MarqueeText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    text: dashboard.weatherCity
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: page.smartText
                                    centered: true
                                }

                                MarqueeText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 18
                                    text: dashboard.weatherCondition
                                    font.pixelSize: 12
                                    color: page.smartTextMuted
                                    centered: true
                                }
                            }
                        }
                    }
                }
            }

            // 2. GRID PRINCIPAL
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: page.colGap
                rowSpacing: page.rowGap

                UI.MusicPlayerCard {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight > 0 ? implicitHeight : 180
                    theme: page.theme
                    musicModel: music
                }

                // 2.1 MONITOR DE SISTEMA
                Rectangle {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360

                    radius: 28
                    color: page.surface1
                    border.width: 1
                    border.color: page.border0
                    clip: true

                    RowLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 20
                        anchors.topMargin: 18
                        z: 2
                        spacing: 8

                        Rectangle { width: 4; height: 16; radius: 2; color: page.smartAccent }

                        Text {
                            text: Translation.tr("System Vitality")
                            font.pixelSize: 13
                            font.family: page.theme.fontMain
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            color: page.smartText
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
                                ctx.strokeStyle = page.smartAccent
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

                            onWidthChanged: requestPaint()

                            Connections {
                                target: page
                                function onSmartAccentChanged() { ekgCanvas.requestPaint() }
                            }
                        }

                        MaterialSymbol {
                            id: vitalHeart
                            text: "ecg_heart"
                            font.pixelSize: 20
                            color: page.smartAccent
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
                                color: page.smartAccent
                                opacity: 0.45
                            }
                        }

                        ColumnLayout {
                            id: statsCol
                            width: parent.width
                            spacing: 8

                            // CPU / RAM / TEMPS / DISK
                            ResourcePill {
                                icon: "memory"
                                title: Translation.tr("Processor")
                                val: dashboard.cpuVal
                                sub: Translation.tr("Total usage")
                                prog: parseFloat(dashboard.cpuVal) / 100
                                tint: "#ff6b6b"
                            }
                            ResourcePill {
                                icon: "sd_card"
                                title: Translation.tr("RAM")
                                val: dashboard.ramVal
                                sub: dashboard.ramDetail
                                prog: parseFloat(dashboard.ramVal) / 100
                                tint: "#feca57"
                            }
                            ResourcePill {
                                icon: "thermostat"
                                title: Translation.tr("CPU Temperature")
                                val: dashboard.cpuTemp
                                sub: Translation.tr("Core Temp")
                                prog: parseFloat(dashboard.cpuTemp) / 100.0
                                isGauge: true
                                tint: "#ff7675"
                            }
                            ResourcePill {
                                icon: "device_thermostat"
                                title: Translation.tr("GPU Temperature")
                                val: dashboard.gpuTemp
                                sub: Translation.tr("AMD Radeon")
                                prog: parseFloat(dashboard.gpuTemp) / 100.0
                                isGauge: true
                                tint: "#ff9f43"
                            }
                            ResourcePill {
                                icon: "hard_drive"
                                title: Translation.tr("Storage")
                                val: dashboard.diskUsePct
                                sub: dashboard.diskVal + " " + Translation.tr("Free")
                                prog: parseFloat(dashboard.diskUsePct) / 100
                                tint: "#48dbfb"
                            }

                            // NETWORK (velocidad)
                            ResourcePill {
                                icon: "network_check"
                                title: "Network"
                                val: page.safeStr(dashboard.netDown, "0 KB/s") + " ↓"
                                sub: page.safeStr(dashboard.netUp, "0 KB/s") + " ↑" +
                                     " | " + page.safeStr(dashboard.netIface, "-")
                                isGauge: false
                                tint: "#38bdf8"
                            }

                            // UPDATES
                            ResourcePill {
                                icon: "system_update"
                                title: "System Updates"
                                val: page.safeStr(dashboard.totalUpdates, "0")
                                sub: "Repo: " + page.safeStr(dashboard.repoUpdates, "0") +
                                     " | AUR: " + page.safeStr(dashboard.aurUpdates, "0") +
                                     " | Rev: " + page.safeStr(dashboard.lastUpdateCheck, "--:--")
                                isGauge: true
                                prog: Math.min(page.safeInt(dashboard.totalUpdates, 0) / 50.0, 1.0)
                                tint: page.safeInt(dashboard.totalUpdates, 0) > 0 ? "#ef4444" : "#22c55e"
                            }

                            // SISTEMA (OS/HOST/KERNEL)
                            ResourcePill {
                                icon: "computer"
                                title: page.safeStr(dashboard.osName, "Linux")
                                val: page.safeStr(dashboard.hostName, "Host")
                                sub: page.safeStr(dashboard.kernelVal, "...") + " (" + page.safeStr(dashboard.archVal, "...") + ")"
                                isGauge: false
                                tint: "#3b82f6"
                            }

                            // DISPLAYS (SIN SUB)
                            ResourcePill {
                                icon: "monitor"
                                title: "Displays"
                                val: page.safeStr(dashboard.monitorSummary, "...")
                                sub: ""                 // <- quitado
                                isGauge: false
                                tint: "#a78bfa"
                            }

                            // PACMAN / YAY / PAQUETES
                            ResourcePill {
                                icon: "inventory_2"
                                title: "Pacman Packages"
                                val: page.safeStr(dashboard.pkgTotal, "...")
                                sub: "pacman v" + page.safeStr(dashboard.pacmanVer, "…") +
                                     " | Explicit: " + page.safeStr(dashboard.pkgExplicit, "...") +
                                     " | Deps: " + page.safeStr(dashboard.pkgDeps, "...")
                                isGauge: false
                                tint: "#fbbf24"
                            }

                            ResourcePill {
                                icon: "deployed_code"
                                title: "AUR / Foreign Packages"
                                val: page.safeStr(dashboard.pkgForeign, "0")
                                sub: "yay v" + page.safeStr(dashboard.yayVer, "not-installed") +
                                     " | AUR updates: " + page.safeStr(dashboard.aurUpdates, "0")
                                isGauge: false
                                tint: "#8b5cf6"
                            }

                            ResourcePill {
                                icon: "delete_sweep"
                                title: "Orphan Packages"
                                val: page.safeStr(dashboard.pkgOrphans, "0")
                                sub: (page.safeInt(dashboard.pkgOrphans, 0) > 0)
                                        ? "Tip: pacman -Qtdq | sudo pacman -Rns -"
                                        : "No orphans detected"
                                isGauge: false
                                tint: page.safeInt(dashboard.pkgOrphans, 0) > 0 ? "#f97316" : "#22c55e"
                            }

                            ResourcePill {
                                icon: "folder"
                                title: "Pacman Cache"
                                val: page.safeStr(dashboard.pacmanCacheSize, "...")
                                sub: "/var/cache/pacman/pkg"
                                isGauge: false
                                tint: "#06b6d4"
                            }

                            // SNAP / FLATPAK
                            ResourcePill {
                                icon: "package_2"
                                title: "Snap"
                                val: page.safeStr(dashboard.snapCount, "0")
                                sub: "snapd: " + page.safeStr(dashboard.snapdEnabled, "no") +
                                     " | snapd v" + page.safeStr(dashboard.snapVer, "not-installed")
                                isGauge: false
                                tint: "#f59e0b"
                            }

                            ResourcePill {
                                icon: "apps"
                                title: "Flatpak"
                                val: page.safeStr(dashboard.flatpakCount, "0")
                                sub: "flatpak v" + page.safeStr(dashboard.flatpakVer, "not-installed")
                                isGauge: false
                                tint: "#60a5fa"
                            }

                            // DISPLAY MANAGER
                            ResourcePill {
                                icon: "desktop_windows"
                                title: "Display Manager"
                                val: page.safeStr(dashboard.dmName, "none")
                                sub: "enabled: " + page.safeStr(dashboard.dmEnabled, "no")
                                isGauge: false
                                tint: page.safeStr(dashboard.dmEnabled, "no") === "yes" ? "#22c55e" : "#94a3b8"
                            }

                            // RESTO
                            ResourcePill {
                                icon: "apps"
                                title: Translation.tr("Active Processes")
                                val: dashboard.processesVal
                                sub: Translation.tr("Total tasks")
                                prog: Math.min(parseFloat(dashboard.processesVal) / 500.0, 1.0)
                                isGauge: true
                                tint: "#a29bfe"
                            }
                            ResourcePill {
                                icon: "schedule"
                                title: Translation.tr("Uptime")
                                val: dashboard.upTimeVal
                                sub: Translation.tr("Since start")
                                isGauge: false
                                tint: page.smartAccent
                            }
                            ResourcePill {
                                icon: "code_blocks"
                                title: Translation.tr("Quickshell")
                                val: dashboard.qsVer
                                sub: Translation.tr("Installed version")
                                isGauge: false
                                tint: "#00d2d3"
                            }
                            ResourcePill {
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

                // 2.2 BLOQUE CRIPTO                    
                UI.CryptoCard {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 380
                    theme: page.theme
                }

                // 2.3 BLOQUE NOTESCARD          PRUEBAS AGREGAS AL PULIR      
            //    UI.QuickNotesCard {
              //      Layout.columnSpan: 2
                //    Layout.fillWidth: true
                 //   Layout.preferredHeight: 420
                //    theme: page.theme
              //  }
                         // 2.3 BLOQUE GOOGLE DISCOVER (NOTICIAS)
                GoogleDiscoverPage {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    
                    // IMPORTANTE: Como tiene una lista infinita dentro, 
                    // debes darle altura o no se verá dentro de un ScrollView.
                 //   Layout.preferredHeight: 500 
                    
                    // Opcional: Un fondo o borde para que parezca tarjeta unificada
                    // Si tu GoogleDiscoverPage ya tiene fondo, esto no es necesario.
                  //  clip: true
                }
   
                Item { Layout.preferredHeight: 20; Layout.columnSpan: 2 }
            }
        }
    }

    // COMPONENTE: TEXTO CON MARQUEE
    component MarqueeText : Item {
        property alias text: txt.text
        property alias font: txt.font
        property alias color: txt.color
        property bool centered: false
        clip: true

        Text {
            id: txt
            anchors.verticalCenter: parent.verticalCenter
            x: {
                if (txt.implicitWidth <= parent.width) {
                    return centered ? (parent.width - txt.implicitWidth) / 2 : 0
                } else {
                    return 0
                }
            }

            SequentialAnimation on x {
                running: txt.implicitWidth > parent.width
                loops: Animation.Infinite
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    to: -(txt.implicitWidth - parent.width)
                    duration: (txt.implicitWidth - parent.width) * 20 + 1000
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation { duration: 1000 }
                NumberAnimation {
                    to: 0
                    duration: (txt.implicitWidth - parent.width) * 20 + 1000
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // COMPONENTE
    component ResourcePill : Rectangle {
        property string icon
        property string title
        property string val
        property string sub
        property real prog: 0.0
        property bool isGauge: true
        property color tint

        Layout.fillWidth: true
        Layout.preferredHeight: 68
        radius: 22
        color: page.surface1
        border.width: 1
        border.color: page.border0
        clip: true

        readonly property int badgeMaxW: 170

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 20
            spacing: 14

            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: Qt.rgba(tint.r, tint.g, tint.b, 0.20)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: icon
                    font.pixelSize: 22
                    color: tint
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: (String(sub || "").trim().length > 0) ? 4 : 2

                Text {
                    text: title
                    color: page.smartText
                    font.bold: true
                    font.pixelSize: 13
                    font.family: page.theme.fontMain
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // SUB: si está vacío, no ocupa altura (para Displays)
                MarqueeText {
                    Layout.fillWidth: true
                    visible: String(sub || "").trim().length > 0
                    Layout.preferredHeight: visible ? 16 : 0
                    text: sub
                    color: page.smartTextMuted
                    font.pixelSize: 11
                    font.family: page.theme.fontMain
                }

                Rectangle {
                    visible: isGauge
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.rgba(page.smartText.r, page.smartText.g, page.smartText.b, 0.10)

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.min(Math.max(prog, 0), 1)
                        radius: 3
                        color: tint
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                    }
                }

                Item { visible: !isGauge; Layout.preferredHeight: 6 }
            }

            // Slot derecho
            Item {
                id: rightSlot
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.minimumWidth: 40
                Layout.preferredHeight: 30

                Text {
                    visible: isGauge
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(90, parent.width > 0 ? parent.width : 90)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: val
                    color: page.smartText
                    font.pixelSize: 15
                    font.bold: true
                    font.family: page.theme.fontMain
                }

                Rectangle {
                    id: badge
                    visible: !isGauge
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(badgeText.implicitWidth + 24, badgeMaxW)
                    height: 28
                    radius: 14
                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.20)
                    border.width: 1
                    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.55)
                    clip: true

                    SequentialAnimation on border.color {
                        loops: Animation.Infinite
                        ColorAnimation { to: Qt.rgba(tint.r, tint.g, tint.b, 1.0); duration: 2000; easing.type: Easing.InOutSine }
                        ColorAnimation { to: Qt.rgba(tint.r, tint.g, tint.b, 0.40); duration: 2000; easing.type: Easing.InOutSine }
                    }

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        width: parent.width - 18
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: val
                        color: page.smartText
                        font.pixelSize: 13
                        font.bold: true
                        font.family: page.theme.fontMain
                    }
                }
            }
        }
    }
}

