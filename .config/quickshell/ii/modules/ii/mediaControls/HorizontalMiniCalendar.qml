pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.modules.common.widgets
import qs.modules.common
import qs.services // Para acceder a DateTime.uptime
import "calendario"

Item {
    id: root
    implicitWidth: 940
    implicitHeight: 480   

    property int currentMode: 0 // 0 Focus, 1 Short, 2 Long, 3 Stopwatch

    property int focusTime: 25
    property int shortBreakTime: 5
    property int longBreakTime: 15

    property int totalTime: focusTime * 60
    property int timeLeft: focusTime * 60
    property int stopwatchElapsed: 0

    property bool timerRunning: false
    property int cycleCount: 0
    property bool autoContinue: false

    property int todaySessions: 0
    property int todayFocusMinutes: 0
    property int currentStreak: 0

    property var laps: []

    property bool editingTime: false
    property string manualMinutesText: ""

    readonly property bool isStopwatch: currentMode === 3
    readonly property bool isPomodoro: currentMode !== 3

    readonly property color panelColor: Appearance.colors.colLayer1 || "#1e1e2e"
    readonly property color subPanelColor: Appearance.colors.colSurfaceVariant || "#313244"
    readonly property color primaryColor: Appearance.colors.colPrimary || "#cba6f7"
    readonly property color textColor: Appearance.colors.colOnSurface || "#cdd6f4"
    readonly property color mutedText: Appearance.colors.colSubtext || "#a6adc8"
    readonly property color softBorder: Qt.rgba(1, 1, 1, 0.05)

    readonly property bool nextIsLongBreak: isPomodoro && currentMode === 0 && ((cycleCount + 1) % 4 === 0)

    function modeLabel(mode) {
        if (mode === 0) return "Focus";
        if (mode === 1) return "Short Break";
        if (mode === 2) return "Long Break";
        return "Stopwatch";
    }

    function modeShortLabel(mode) {
        if (mode === 0) return "Focus";
        if (mode === 1) return "Short";
        if (mode === 2) return "Long";
        return "Watch";
    }

    function getModeMinutes(mode) {
        if (mode === 0) return focusTime;
        if (mode === 1) return shortBreakTime;
        if (mode === 2) return longBreakTime;
        return 0;
    }

    function setModeMinutes(mode, minutes) {
        const safe = Math.max(1, Math.min(180, minutes));
        if (mode === 0) focusTime = safe;
        else if (mode === 1) shortBreakTime = safe;
        else if (mode === 2) longBreakTime = safe;
    }

    function applyMode(mode, preserveRunning) {
        currentMode = mode

        if (!preserveRunning)
            timerRunning = false

        editingTime = false
        manualMinutesText = ""
        stopwatchElapsed = 0

        if (mode === 0) totalTime = focusTime * 60
        else if (mode === 1) totalTime = shortBreakTime * 60
        else if (mode === 2) totalTime = longBreakTime * 60
        else totalTime = 1

        if (mode !== 3)
            timeLeft = totalTime

        ringBg.requestPaint()
        ringFg.requestPaint()
    }

    function setTimerMode(mode) {
        modePulse.restart()
        applyMode(mode, false)
    }

    function adjustTime(minutesToAdd) {
        if (timerRunning || isStopwatch)
            return

        let next = getModeMinutes(currentMode) + minutesToAdd
        setModeMinutes(currentMode, next)

        totalTime = getModeMinutes(currentMode) * 60
        timeLeft = totalTime
        ringFg.requestPaint()
    }

    function applyManualMinutes() {
        if (timerRunning || isStopwatch)
            return

        let n = parseInt(manualMinutesText)
        if (isNaN(n))
            n = getModeMinutes(currentMode)

        setModeMinutes(currentMode, n)
        totalTime = getModeMinutes(currentMode) * 60
        timeLeft = totalTime
        editingTime = false
        manualMinutesText = ""
        ringFg.requestPaint()
    }

    function formatTime(seconds) {
        let t = Math.max(0, seconds)
        let h = Math.floor(t / 3600)
        let m = Math.floor((t % 3600) / 60)
        let s = t % 60

        if (h > 0)
            return h.toString().padStart(2, "0") + ":" +
                   m.toString().padStart(2, "0") + ":" +
                   s.toString().padStart(2, "0")

        return m.toString().padStart(2, "0") + ":" +
               s.toString().padStart(2, "0")
    }

    function resetCurrentMode() {
        timerRunning = false
        editingTime = false
        manualMinutesText = ""
        stopwatchElapsed = 0

        if (currentMode === 0) {
            totalTime = focusTime * 60
            timeLeft = totalTime
        } else if (currentMode === 1) {
            totalTime = shortBreakTime * 60
            timeLeft = totalTime
        } else if (currentMode === 2) {
            totalTime = longBreakTime * 60
            timeLeft = totalTime
        } else {
            laps = []
        }

        ringFg.requestPaint()
    }

    function resetAll() {
        timerRunning = false
        cycleCount = 0
        stopwatchElapsed = 0
        laps = []
        resetCurrentMode()
    }

    function addLap() {
        if (!isStopwatch || !timerRunning)
            return
        laps = [formatTime(stopwatchElapsed)].concat(laps).slice(0, 4)
    }

    function onCycleFinished() {
          }

    Timer {
        id: mainTimer
        interval: 1000
        repeat: true
        running: root.timerRunning

        onTriggered: {
            if (root.isStopwatch) {
                root.stopwatchElapsed++
                ringFg.requestPaint()
                return
            }

            if (root.timeLeft > 0) {
                root.timeLeft--
                ringFg.requestPaint()
                return
            }

            root.timerRunning = false
            root.onCycleFinished()

            if (root.currentMode === 0) {
                root.cycleCount++
                root.todaySessions++
                root.todayFocusMinutes += root.focusTime
                root.currentStreak++
            }

            if (root.autoContinue) {
                if (root.currentMode === 0) {
                    if (root.cycleCount > 0 && root.cycleCount % 4 === 0)
                        root.applyMode(2, true)
                    else
                        root.applyMode(1, true)
                } else {
                    root.applyMode(0, true)
                }
                root.timerRunning = true
            }
        }
    }

    property var scheduledEvents: []
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    FileView {
        id: scheduleFile
        path: root.storagePath

        onLoaded: {
            try {
                let parsed = JSON.parse(scheduleFile.text)
                if (Array.isArray(parsed))
                    root.scheduledEvents = parsed
            } catch (e) {
                root.scheduledEvents = []
            }
        }
    }

    Component.onCompleted: {
        scheduleFile.reload()
        applyMode(0, false)
    }

    SequentialAnimation {
        id: modePulse
        NumberAnimation { target: centerZone; property: "scale"; to: 0.985; duration: 70 }
        NumberAnimation { target: centerZone; property: "scale"; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 360
            radius: Appearance.rounding.large || 24
            color: root.panelColor
            border.width: 1
            border.color: root.softBorder
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.025)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                   RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 56; height: 56; radius: 23
                        color: Appearance.colors.colLayer2 || "#1e1e2e"
                        border.width: 2; border.color: root.primaryColor
                        clip: true
                        
                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            source: "file:///home/" + (Quickshell.env("USER") || "") + "/.face"
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "person"
                            font.pixelSize: 28
                            color: root.primaryColor
                            visible: !userAvatar.visible
                        }
                    }

                       ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        StyledText {
                            text: Translation.tr("Hola, %1").arg(Quickshell.env("USER") || "Usuario")
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: root.textColor
                        }

                        RowLayout {
                            spacing: 4
                            MaterialSymbol {
                                text: "timelapse"
                                iconSize: 15
                                color: root.mutedText
                            }
                            StyledText {
                                text: "Uptime: " + (DateTime.uptime || "0m")
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: root.mutedText
                            }
                        }
                    }
                }

                   Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.textColor
                    opacity: 0.05
                }

                CalendarWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

            Rectangle {
            id: timerPanel
            Layout.fillHeight: true
            Layout.fillWidth: true
            radius: Appearance.rounding.large || 24
            color: root.panelColor
            border.width: 1
            border.color: root.softBorder
            clip: true

               Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 80
                radius: parent.radius
                color: "transparent"

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06) }
                    GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.018) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                   RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 10

                    StyledText {
                        text: "Focus Timer"
                        font.pixelSize: 17
                        font.weight: Font.ExtraBold
                        color: root.textColor
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: root.isPomodoro
                        implicitWidth: root.nextIsLongBreak ? 108 : 76
                        implicitHeight: 28
                        radius: 14
                        color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.22)

                        Behavior on implicitWidth {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: root.nextIsLongBreak ? "Long break next" : (root.cycleCount + " cycle")
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.primaryColor
                        }
                    }
                }

                   Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        Repeater {
                            model: 4

                            delegate: Rectangle {
                                required property int index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 16
                                color: root.currentMode === index
                                        ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.16)
                                        : "transparent"
                                border.width: root.currentMode === index ? 1 : 0
                                border.color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.20)

                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                                scale: root.currentMode === index ? 1.0 : 0.985

                                StyledText {
                                    anchors.centerIn: parent
                                    text: root.modeShortLabel(index)
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: root.currentMode === index ? root.primaryColor : root.mutedText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setTimerMode(index)
                                }
                            }
                        }
                    }
                }

                   Item {
                    id: centerZone
                    Layout.fillWidth: true
                    Layout.fillHeight: true 
                    Layout.minimumHeight: 120 
                    Layout.alignment: Qt.AlignHCenter
                    scale: 1.0

                    readonly property real ringSize: Math.min(width, height, 220)

                    Item {
                        anchors.centerIn: parent
                        width: parent.ringSize
                        height: parent.ringSize

                        Canvas {
                            id: ringBg
                            anchors.fill: parent

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                const cx = width / 2
                                const cy = height / 2
                                const r = Math.min(cx, cy) - 14

                                ctx.beginPath()
                                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.04)
                                ctx.lineWidth = 24
                                ctx.lineCap = "round"
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                                ctx.lineWidth = 14
                                ctx.lineCap = "round"
                                ctx.stroke()
                            }
                        }

                        Canvas {
                            id: ringFg
                            anchors.fill: parent

                            readonly property real progress: root.isStopwatch
                                ? ((root.stopwatchElapsed % 60) / 60.0)
                                : Math.max(0, Math.min(1, 1.0 - (root.timeLeft / Math.max(1, root.totalTime))))

                            onProgressChanged: requestPaint()

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                if (progress <= 0 && root.isPomodoro)
                                    return

                                const cx = width / 2
                                const cy = height / 2
                                const r = Math.min(cx, cy) - 14
                                const start = -Math.PI / 2
                                const end = start + (progress * Math.PI * 2)

                                ctx.beginPath()
                                ctx.arc(cx, cy, r, start, end)
                                ctx.strokeStyle = Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.14)
                                ctx.lineWidth = 24
                                ctx.lineCap = "round"
                                ctx.stroke()

                                const grad = ctx.createLinearGradient(0, 0, width, height)
                                grad.addColorStop(0.0, Qt.rgba(1.0, 0.55, 0.72, 1.0))
                                grad.addColorStop(0.45, root.primaryColor)
                                grad.addColorStop(1.0, Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.82))

                                ctx.beginPath()
                                ctx.arc(cx, cy, r, start, end)
                                ctx.strokeStyle = grad
                                ctx.lineWidth = 14
                                ctx.lineCap = "round"
                                ctx.stroke()

                                const tipX = cx + Math.cos(end) * r
                                const tipY = cy + Math.sin(end) * r
                                ctx.beginPath()
                                ctx.arc(tipX, tipY, 4.5, 0, Math.PI * 2)
                                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.9)
                                ctx.fill()
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.modeLabel(root.currentMode)
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: root.primaryColor
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Rectangle {
                                    visible: !root.timerRunning && root.isPomodoro && !root.editingTime
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: minusArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.04)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "remove"
                                        iconSize: 18
                                        color: root.mutedText
                                    }

                                    Timer {
                                        id: minusHold
                                        interval: 140
                                        repeat: true
                                        triggeredOnStart: true
                                        onTriggered: root.adjustTime(-1)
                                    }

                                    MouseArea {
                                        id: minusArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: minusHold.start()
                                        onReleased: minusHold.stop()
                                        onCanceled: minusHold.stop()
                                    }
                                }

                                Item {
                                    implicitWidth: centerZone.ringSize * 0.7 
                                    implicitHeight: 64

                                    StyledText {
                                        id: timeText
                                        anchors.centerIn: parent
                                        visible: !root.editingTime
                                        text: root.formatTime(root.isStopwatch ? root.stopwatchElapsed : root.timeLeft)
                                        font.pixelSize: root.isStopwatch ? 42 : 46 
                                        font.weight: Font.ExtraBold
                                        color: root.textColor
                                    }

                                    TextField {
                                        anchors.centerIn: parent
                                        visible: root.editingTime && root.isPomodoro
                                        width: 110
                                        height: 42
                                        text: root.manualMinutesText
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 22
                                        color: root.textColor
                                        selectByMouse: true
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        placeholderText: "25"
                                        background: Rectangle {
                                            radius: 14
                                            color: Qt.rgba(1, 1, 1, 0.04)
                                            border.width: 1
                                            border.color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.25)
                                        }
                                        onAccepted: root.applyManualMinutes()
                                        onEditingFinished: {
                                            if (visible)
                                                root.applyManualMinutes()
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        visible: !root.timerRunning && root.isPomodoro && !root.editingTime
                                        acceptedButtons: Qt.LeftButton
                                        onDoubleClicked: {
                                            root.manualMinutesText = root.getModeMinutes(root.currentMode).toString()
                                            root.editingTime = true
                                        }
                                        onWheel: function(wheel) {
                                            root.adjustTime(wheel.angleDelta.y > 0 ? 1 : -1)
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: !root.timerRunning && root.isPomodoro && !root.editingTime
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: plusArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.04)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "add"
                                        iconSize: 18
                                        color: root.mutedText
                                    }

                                    Timer {
                                        id: plusHold
                                        interval: 140
                                        repeat: true
                                        triggeredOnStart: true
                                        onTriggered: root.adjustTime(1)
                                    }

                                    MouseArea {
                                        id: plusArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: plusHold.start()
                                        onReleased: plusHold.stop()
                                        onCanceled: plusHold.stop()
                                    }
                                }
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                visible: !root.timerRunning && root.isPomodoro && !root.editingTime
                                text: "Scroll, mantén ± o doble click"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: Qt.rgba(root.mutedText.r, root.mutedText.g, root.mutedText.b, 0.85)
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            visible: root.cycleCount > 0 && root.isPomodoro
                            width: 34
                            height: 34
                            radius: 17
                            color: root.primaryColor

                            StyledText {
                                anchors.centerIn: parent
                                text: root.cycleCount
                                font.pixelSize: 13
                                font.weight: Font.ExtraBold
                                color: Appearance.colors.colSurface || "#11111b"
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 56 
                    spacing: 12

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: stopArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.isStopwatch ? "flag" : "stop"
                            iconSize: 22
                            color: root.textColor
                        }

                        MouseArea {
                            id: stopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isStopwatch)
                                    root.addLap()
                                else
                                    root.resetCurrentMode()
                            }
                        }
                    }

                    Rectangle {
                        id: playButton
                        width: 176
                        height: 56 
                        radius: 28
                        color: root.primaryColor
                        scale: playArea.containsMouse ? 1.02 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            radius: (parent.height + 8) / 2
                            color: "transparent"
                            border.width: playArea.containsMouse ? 1 : 0
                            border.color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.28)
                            opacity: playArea.containsMouse ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            MaterialSymbol {
                                text: root.timerRunning ? "pause" : "play_arrow"
                                iconSize: 28
                                color: Appearance.colors.colSurface || "#11111b"
                            }

                            StyledText {
                                text: root.timerRunning ? "Pause" : "Start"
                                font.pixelSize: 16
                                font.weight: Font.ExtraBold
                                color: Appearance.colors.colSurface || "#11111b"
                            }
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.timerRunning = !root.timerRunning
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: resetArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 22
                            color: root.textColor
                        }

                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetAll()
                        }
                    }
                }

                   RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Today sessions", value: root.todaySessions },
                            { label: "Focus mins", value: root.todayFocusMinutes },
                            { label: "Current streak", value: root.currentStreak }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 16
                            color: Qt.rgba(1, 1, 1, 0.028)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.04)

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.value
                                    font.pixelSize: 14
                                    font.weight: Font.ExtraBold
                                    color: root.textColor
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                    color: root.mutedText
                                }
                            }
                        }
                    }
                }

                   RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 10

                    Rectangle {
                        visible: root.isPomodoro
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 20
                        color: Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 10

                            StyledText {
                                text: "Auto-continue"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: root.mutedText
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 46
                                height: 24
                                radius: 12
                                color: root.autoContinue
                                        ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.95)
                                        : Qt.rgba(1, 1, 1, 0.08)

                                Rectangle {
                                    x: root.autoContinue ? parent.width - width - 3 : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: root.autoContinue
                                            ? (Appearance.colors.colSurface || "#11111b")
                                            : root.mutedText

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.autoContinue = !root.autoContinue
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.isPomodoro ? 160 : 200
                        Layout.fillHeight: true
                        radius: 20
                        color: Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)

                        StyledText {
                            anchors.centerIn: parent
                            text: root.isStopwatch
                                  ? (root.laps.length > 0 ? ("Lap " + root.laps[0]) : "Running live")
                                  : (root.getModeMinutes(root.currentMode) + " min")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: root.primaryColor
                        }
                    }
                }
            }
        }
    }
}
