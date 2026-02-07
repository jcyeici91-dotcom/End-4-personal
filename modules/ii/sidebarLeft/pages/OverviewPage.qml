import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.common            // Appearance.*
import qs.modules.common.widgets
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

    readonly property color surface0: Appearance.colors.colLayer0
    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border
    readonly property color onSurface: Appearance.colors.colOnLayer0
    readonly property color onSurfaceMuted: Qt.rgba(onSurface.r, onSurface.g, onSurface.b, 0.75)
  
    readonly property color accent: page.theme.colAccent
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

            // 1. CABECERA (RELOJ Y CLIMA)
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
                                to: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.55)
                                duration: 2000
                                easing.type: Easing.InOutSine
                            }
                            ColorAnimation {
                                to: page.border0
                                duration: 2000
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
                                    color: page.onSurface
                                    // Reemplazo de DropShadow -> MultiEffect
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(0, 0, 0, 0.30)
                                        shadowBlur: 0.8
                                        shadowVerticalOffset: 2
                                        shadowHorizontalOffset: 0
                                    }
                                }
                                Text {
                                    text: ":"
                                    font.pixelSize: 64
                                    font.family: page.theme.fontMain
                                    color: page.onSurfaceMuted
                                    Layout.bottomMargin: 6
                                    OpacityAnimator on opacity {
                                        from: 1.0
                                        to: 0.4
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
                                    color: page.accent
                                    // Reemplazo de DropShadow -> MultiEffect
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(0, 0, 0, 0.30)
                                        shadowBlur: 0.8
                                        shadowVerticalOffset: 2
                                        shadowHorizontalOffset: 0
                                    }
                                }
                                Text {
                                    text: dashboard.timeSec
                                    font.pixelSize: 32
                                    font.family: page.theme.fontMain
                                    font.weight: Font.Bold
                                    color: page.onSurface
                                    opacity: 0.7
                                    Layout.alignment: Qt.AlignBaseline
                                    Layout.bottomMargin: 9
                                }
                            }
                            MarqueeText {
                                Layout.topMargin: 4
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                text: dashboard.dateString
                                font.pixelSize: 14
                                font.bold: true
                                font.capitalization: Font.AllUppercase
                                color: page.onSurfaceMuted
                                centered: true
                            }
                        }
                    }
                    // ───  CLIMA ───
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
                                color: page.accent
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
                                color: page.onSurface
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
                                    color: page.onSurface
                                    centered: true
                                }
                                MarqueeText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 18
                                    text: dashboard.weatherCondition
                                    font.pixelSize: 11
                                    color: page.onSurfaceMuted
                                    centered: true
                                    opacity: 0.85
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
                    Layout.preferredHeight: 300
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
                        Rectangle { width: 4; height: 16; radius: 2; color: page.accent }
                        Text {
                            text: "SYSTEM VITALITY"
                            font.pixelSize: 13
                            font.family: page.theme.fontMain
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            color: page.onSurface
                            opacity: 0.85
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
                                var ctx = getContext("2d");
                                var w = width; var h = height; var midY = h / 2;
                                var pulseWidth = 50; var cycleWidth = 180; var pulseHeight = 12;
                                ctx.reset();
                                ctx.lineWidth = 2;
                                ctx.strokeStyle = page.accent;
                                ctx.lineCap = "round"; ctx.lineJoin = "round";
                                var xOffset = animationProgress * cycleWidth;
                                ctx.beginPath();
                                for (var cx = -cycleWidth + xOffset; cx < w; cx += cycleWidth) {
                                    if (cx === -cycleWidth + xOffset) ctx.moveTo(cx, midY); else ctx.lineTo(cx, midY);
                                    var pulseStart = cx + (cycleWidth - pulseWidth) / 2;
                                    ctx.lineTo(pulseStart, midY);
                                    ctx.lineTo(pulseStart + pulseWidth * 0.1, midY - pulseHeight * 0.2);
                                    ctx.lineTo(pulseStart + pulseWidth * 0.4, midY + pulseHeight);
                                    ctx.lineTo(pulseStart + pulseWidth * 0.6, midY - pulseHeight * 0.5);
                                    ctx.lineTo(pulseStart + pulseWidth * 0.8, midY - pulseHeight * 0.1);
                                    ctx.lineTo(pulseStart + pulseWidth * 1.0, midY);
                                    ctx.lineTo(cx + cycleWidth, midY);
                                }
                                ctx.stroke();
                            }
                            onWidthChanged: requestPaint()
                            Connections {
                                target: page.theme
                                function onColAccentChanged() { ekgCanvas.requestPaint() }
                            }
                        }
                        MaterialSymbol {
                            id: vitalHeart
                            text: "ecg_heart"
                            font.pixelSize: 20
                            color: page.accent
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
                                color: page.accent
                                opacity: 0.45
                            }
                        }
                        ColumnLayout {
                            id: statsCol
                            width: parent.width
                            spacing: 8
                            ResourcePill { icon: "memory"; title: "Procesador"; val: dashboard.cpuVal; sub: "Uso total"; prog: parseFloat(dashboard.cpuVal) / 100; tint: "#ff6b6b" }
                            ResourcePill { icon: "sd_card"; title: "Memoria RAM"; val: dashboard.ramVal; sub: dashboard.ramDetail; prog: parseFloat(dashboard.ramVal) / 100; tint: "#feca57" }
                            ResourcePill { icon: "thermostat"; title: "Temperatura CPU"; val: dashboard.cpuTemp; sub: "Core Temp"; prog: parseFloat(dashboard.cpuTemp) / 100.0; isGauge: true; tint: "#ff7675" }
                            ResourcePill { icon: "device_thermostat"; title: "Temperatura GPU"; val: dashboard.gpuTemp; sub: "AMD Radeon"; prog: parseFloat(dashboard.gpuTemp) / 100.0; isGauge: true; tint: "#ff9f43" }
                            ResourcePill { icon: "hard_drive"; title: "Almacenamiento"; val: dashboard.diskUsePct; sub: dashboard.diskVal + " Libre"; prog: parseFloat(dashboard.diskUsePct) / 100; tint: "#48dbfb" }
                            ResourcePill { icon: "apps"; title: "Procesos Activos"; val: dashboard.processesVal; sub: "Total tareas"; prog: Math.min(parseFloat(dashboard.processesVal) / 500.0, 1.0); isGauge: true; tint: "#a29bfe" }
                            ResourcePill { icon: "schedule"; title: "Tiempo Activo"; val: dashboard.upTimeVal; sub: "Desde inicio"; isGauge: false; tint: page.accent }
                            ResourcePill { icon: "code_blocks"; title: "Quickshell"; val: dashboard.qsVer; sub: "Versión Instalada"; isGauge: false; tint: "#00d2d3" }
                            ResourcePill { icon: "grid_view"; title: "Hyprland"; val: dashboard.hyprVer; sub: "Compositor"; isGauge: false; tint: "#5f27cd" }
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
                // 2.4 BLOQUE NOTICIAS
                UI.NewsCard {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 580
                    theme: page.theme
                }
                // 2.X CHAT AI
                Rectangle {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 520
                    radius: 28
                    color: page.surface1
                    border.width: 1
                    border.color: page.border0
                    clip: true
                    SidebarLeft.AiChat {
                        anchors.fill: parent
                        anchors.margins: 12
                    }
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
    // COMPONENTE: PÍLDORA MEJORADA
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
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 20
            spacing: 14
            Rectangle {
                width: 42; height: 42; radius: 21
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
                spacing: 4
                Text {
                    text: title
                    color: page.onSurface
                    font.bold: true
                    font.pixelSize: 13
                    font.family: page.theme.fontMain
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                MarqueeText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    text: sub
                    color: page.onSurfaceMuted
                    font.pixelSize: 11
                    font.family: page.theme.fontMain
                    opacity: 0.85
                }
                Rectangle {
                    visible: isGauge
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.rgba(page.onSurface.r, page.onSurface.g, page.onSurface.b, 0.10)
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
            Item {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.minimumWidth: 40
                Layout.preferredHeight: 30
                Text {
                    visible: isGauge
                    anchors.centerIn: parent
                    text: val
                    color: page.onSurface
                    font.pixelSize: 15
                    font.bold: true
                    font.family: page.theme.fontMain
                }
                Rectangle {
                    visible: !isGauge
                    anchors.centerIn: parent
                    width: badgeText.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.20)
                    border.width: 1
                    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.55)
                    SequentialAnimation on border.color {
                        loops: Animation.Infinite
                        ColorAnimation { to: Qt.rgba(tint.r, tint.g, tint.b, 1.0); duration: 2000; easing.type: Easing.InOutSine }
                        ColorAnimation { to: Qt.rgba(tint.r, tint.g, tint.b, 0.40); duration: 2000; easing.type: Easing.InOutSine }
                    }
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: val
                        color: page.onSurface
                        font.pixelSize: 13
                        font.bold: true
                        font.family: page.theme.fontMain
                    }
                }
            }
        }
    }
}
