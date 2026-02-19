import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property int workDuration: pluginData.workDuration || 25
    property int shortBreakDuration: pluginData.shortBreakDuration || 5
    property int longBreakDuration: pluginData.longBreakDuration || 15
    property bool autoStartBreaks: pluginData.autoStartBreaks ?? false
    property bool autoStartPomodoros: pluginData.autoStartPomodoros ?? false
    property bool autoSetDND: pluginData.autoSetDND ?? false

    onWorkDurationChanged: {
        if (globalTimerState.value === "work" && globalTotalSeconds.value > 0) {
            const newTotal = workDuration * 60
            const elapsed = globalTotalSeconds.value - globalRemainingSeconds.value
            globalTotalSeconds.set(newTotal)
            globalRemainingSeconds.set(Math.max(1, newTotal - elapsed))
        }
    }

    onShortBreakDurationChanged: {
        if (globalTimerState.value === "shortBreak" && globalTotalSeconds.value > 0) {
            const newTotal = shortBreakDuration * 60
            const elapsed = globalTotalSeconds.value - globalRemainingSeconds.value
            globalTotalSeconds.set(newTotal)
            globalRemainingSeconds.set(Math.max(1, newTotal - elapsed))
        }
    }

    onLongBreakDurationChanged: {
        if (globalTimerState.value === "longBreak" && globalTotalSeconds.value > 0) {
            const newTotal = longBreakDuration * 60
            const elapsed = globalTotalSeconds.value - globalRemainingSeconds.value
            globalTotalSeconds.set(newTotal)
            globalRemainingSeconds.set(Math.max(1, newTotal - elapsed))
        }
    }

    PluginGlobalVar {
        id: globalRemainingSeconds
        varName: "remainingSeconds"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalTotalSeconds
        varName: "totalSeconds"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalIsRunning
        varName: "isRunning"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalTimerState
        varName: "timerState"
        defaultValue: "work"
    }

    PluginGlobalVar {
        id: globalCompletedPomodoros
        varName: "completedPomodoros"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalTimerOwnerId
        varName: "timerOwnerId"
        defaultValue: ""
    }

    property string instanceId: Math.random().toString(36).substring(2)

    Timer {
        id: pomodoroTimer
        interval: 1000
        repeat: true
        running: globalIsRunning.value && globalTimerOwnerId.value === root.instanceId
        onTriggered: {
            if (globalRemainingSeconds.value > 0) {
                globalRemainingSeconds.set(globalRemainingSeconds.value - 1)
            } else {
                root.timerComplete()
            }
        }
    }

    function timerComplete() {
        globalIsRunning.set(false)

        if (globalTimerState.value === "work") {
            globalCompletedPomodoros.set(globalCompletedPomodoros.value + 1)
            const isLongBreak = globalCompletedPomodoros.value % 4 === 0

            Quickshell.execDetached(["sh", "-c", "notify-send 'Pomodoro Complete' 'Time for a " + (isLongBreak ? "long" : "short") + " break!' -u normal"])

            if (root.autoSetDND) {
              SessionData.setDoNotDisturb(false)
            }
            if (isLongBreak) {
                root.startLongBreak(root.autoStartBreaks)
            } else {
                root.startShortBreak(root.autoStartBreaks)
            }
        } else {
            Quickshell.execDetached(["sh", "-c", "notify-send 'Break Complete' 'Ready for another pomodoro?' -u normal"])
            root.startWork(root.autoStartPomodoros)
        }
    }

    function startWork(autoStart) {
        globalTimerState.set("work")
        globalTotalSeconds.set(root.workDuration * 60)
        globalRemainingSeconds.set(globalTotalSeconds.value)
        if (autoStart) {
            globalTimerOwnerId.set(root.instanceId)

            if (root.autoSetDND) {
                SessionData.setDoNotDisturb(true)
            }
        }
        globalIsRunning.set(autoStart ?? false)
    }

    function startShortBreak(autoStart) {
        if(globalTimerState.value === "work" && root.autoSetDND) {
          SessionData.setDoNotDisturb(false)
        }
        globalTimerState.set("shortBreak")
        globalTotalSeconds.set(root.shortBreakDuration * 60)
        globalRemainingSeconds.set(globalTotalSeconds.value)
        if (autoStart) {
            globalTimerOwnerId.set(root.instanceId)
        }
        globalIsRunning.set(autoStart ?? false)
    }

    function startLongBreak(autoStart) {
        if(globalTimerState.value === "work" && root.autoSetDND) {
          SessionData.setDoNotDisturb(false)
        }
        globalTimerState.set("longBreak")
        globalTotalSeconds.set(root.longBreakDuration * 60)
        globalRemainingSeconds.set(globalTotalSeconds.value)
        if (autoStart) {
            globalTimerOwnerId.set(root.instanceId)
        }
        globalIsRunning.set(autoStart ?? false)
    }

    function toggleTimer() {
        if (!globalIsRunning.value) {
            globalTimerOwnerId.set(root.instanceId)
        }
        globalIsRunning.set(!globalIsRunning.value)
        if (root.autoSetDND && globalTimerState.value === "work") {
          SessionData.setDoNotDisturb(globalIsRunning.value)
        }
    }

    function resetTimer() {
        globalIsRunning.set(false)
        if (root.autoSetDND && globalTimerState.value === "work") {
          SessionData.setDoNotDisturb(false)
        }
        globalRemainingSeconds.set(globalTotalSeconds.value)
    }

    function formatTime(seconds, isVertical = false) {
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return isVertical ? mins + "\n" + (secs < 10 ? "0" : "") + secs : mins + " " + (secs < 10 ? "0" : "") + secs
    }

    function getStateColor() {
        if (globalTimerState.value === "work") return Theme.primary
        if (globalTimerState.value === "shortBreak") return Theme.success
        return Theme.warning
    }

    function getStateIcon() {
        if (globalTimerState.value === "work") return "work"
        return "coffee"
    }

    IpcHandler {
      function resetTimer(): string {
        root.resetTimer()
        return "POMDORO_TIME_RESET_SUCCESS"
      }

      function toggleTimer(): string {
        root.toggleTimer()
        return globalIsRunning.value ? "Timer is running" : "Timer is paused"
      }

      function startWork(): string {
        root.startWork(true)
        return "POMODORO_WORK_STARTED"
      }

      function startShortBreak(): string {
        root.startShortBreak(true)
        return "POMODORO_SHORT_BREAK_STARTED"
      }

      function startLongBreak(): string {
        root.startLongBreak(true)
        return "POMODORO_LONG_BREAK_STARTED"
      }

      target: "pomodoroTimer"
    }

    Timer {
        id: initTimer
        interval: 100
        repeat: false
        running: true
        onTriggered: {
            if (globalRemainingSeconds.value === 0 && globalTotalSeconds.value === 0) {
                root.startWork(false)
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.getStateIcon()
                size: Theme.iconSize - 6
                color: root.getStateColor()
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.formatTime(globalRemainingSeconds.value)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.getStateIcon()
                size: Theme.iconSize - 6
                color: root.getStateColor()
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.formatTime(globalRemainingSeconds.value, true)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Pomodoro Timer"
            detailsText: {
                if (globalTimerState.value === "work") return "Focus session • " + globalCompletedPomodoros.value + " completed"
                if (globalTimerState.value === "shortBreak") return "Short break"
                return "Long break"
            }
            showCloseButton: true

            Column {
                id: popoutContentColumn
                width: parent.width
                spacing: Theme.spacingM

                Item {
                    width: parent.width
                    height: 180

                    Rectangle {
                        width: 180
                        height: 180
                        radius: 90
                        anchors.centerIn: parent
                        color: "transparent"
                        border.width: 8
                        border.color: Qt.rgba(root.getStateColor().r, root.getStateColor().g, root.getStateColor().b, 0.2)

                        Canvas {
                            id: progressCanvas
                            width: parent.width - 16
                            height: parent.height - 16
                            anchors.centerIn: parent

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = root.getStateColor()
                                ctx.beginPath()
                                const centerX = width / 2
                                const centerY = height / 2
                                const radius = (width - 8) / 2
                                const progress = globalRemainingSeconds.value / globalTotalSeconds.value
                                const startAngle = -Math.PI / 2
                                const endAngle = startAngle + (2 * Math.PI * progress)
                                ctx.arc(centerX, centerY, radius, startAngle, endAngle, false)
                                ctx.stroke()
                            }

                            Connections {
                                target: globalRemainingSeconds
                                function onValueChanged() {
                                    progressCanvas.requestPaint()
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            StyledText {
                                text: root.formatTime(globalRemainingSeconds.value)
                                font.pixelSize: 36
                                font.weight: Font.Bold
                                color: root.getStateColor()
                                anchors.horizontalCenter: parent.horizontalCenter
                                horizontalAlignment: Text.AlignHCenter
                                width: 120
                            }

                            StyledText {
                                text: {
                                    if (globalTimerState.value === "work") return "Work"
                                    if (globalTimerState.value === "shortBreak") return "Short Break"
                                    return "Long Break"
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: playArea.containsMouse ? Qt.rgba(root.getStateColor().r, root.getStateColor().g, root.getStateColor().b, 0.2) : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: globalIsRunning.value ? "pause" : "play_arrow"
                            size: 32
                            color: root.getStateColor()
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleTimer()
                        }
                    }

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: resetArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "refresh"
                            size: 24
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetTimer()
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Quick Actions"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    Row {
                        id: quickActionsRow
                        width: parent.width
                        spacing: Theme.spacingS

                        property real buttonWidth: (width - spacing * 2) / 3

                        DankButton {
                            text: "Work"
                            iconName: "work"
                            width: quickActionsRow.buttonWidth
                            onClicked: root.startWork(false)
                        }

                        DankButton {
                            text: "Short Break"
                            iconName: "coffee"
                            width: quickActionsRow.buttonWidth
                            onClicked: root.startShortBreak(false)
                        }

                        DankButton {
                            text: "Long Break"
                            iconName: "weekend"
                            width: quickActionsRow.buttonWidth
                            onClicked: root.startLongBreak(false)
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: statsColumn.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: statsColumn
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        Row {
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "check_circle"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: globalCompletedPomodoros.value + " pomodoros completed"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: "Next long break after " + (4 - (globalCompletedPomodoros.value % 4)) + " more"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            leftPadding: Theme.iconSize + Theme.spacingM
                        }
                    }
                }
            }
        }
    }
}
