import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // --- NUEVO: Orientación ---
    property bool vertical: false

    readonly property bool pRunning: TimerService.pomodoroRunning ?? false
    readonly property bool sRunning: TimerService.stopwatchRunning ?? false
    readonly property bool hasStop: TimerService.stopwatchTime > 0
    readonly property bool hasPomo: TimerService.pomodoroSecondsLeft > 0 && (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration || pRunning)

    property bool showPomodoro: Config.options.bar.timers.showPomodoro
    property bool showStopwatch: Config.options.bar.timers.showStopwatch

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : gridLayout.implicitWidth + gridLayout.columnSpacing * 5
    implicitHeight: root.vertical ? gridLayout.implicitHeight + gridLayout.rowSpacing * 5 : Appearance.sizes.barHeight

    property bool compVisible: ((hasStop || sRunning) && root.showStopwatch) || ((pRunning || hasPomo) && root.showPomodoro)

    onCompVisibleChanged: rootItem.toggleVisible(compVisible)
    Component.onCompleted: rootItem.toggleVisible(compVisible)

    Behavior on implicitWidth {
        enabled: !root.vertical
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        enabled: root.vertical
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function formatTime(time) {
        const sec = Math.floor(time/100)
        return Math.floor(sec/60).toString().padStart(2,'0') + ":" +
        (sec%60).toString().padStart(2,'0') + "." +
        (time%100).toString().padStart(2,'0')
    }

    GridLayout {
        id: gridLayout
        anchors.centerIn: parent
        
        // FIX: GridLayout usa columnSpacing y rowSpacing
        columnSpacing: 4
        rowSpacing: 4
        
        columns: root.vertical ? 1 : 3
        rows: root.vertical ? 3 : 1

        Loader {
            active: hasStop && showStopwatch
            visible: active
            Layout.preferredWidth: root.vertical ? -1 : 90 // fixed solo en horizontal
            Layout.alignment: Qt.AlignCenter
            sourceComponent: RowLayout {
                MaterialSymbol {
                    text: root.sRunning ? "timer" : "timer_pause"
                    color: Appearance.colors.colOnPrimary
                    iconSize: Appearance.font.pixelSize.large
                }

                StyledText {
                    Layout.topMargin: 3
                    text: formatTime(TimerService.stopwatchTime)
                    color: Appearance.colors.colOnPrimary
                }
            }  
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TimerService.toggleStopwatch()
                }
            } 
        }

        Item {
            visible: hasStop && hasPomo
            Layout.preferredWidth: root.vertical ? 0 : (hasStop && hasPomo ? 2 : 0)
            Layout.preferredHeight: root.vertical ? (hasStop && hasPomo ? 2 : 0) : 0
        }

        Loader {
            active: hasPomo && showPomodoro
            visible: active
            Layout.preferredWidth: root.vertical ? -1 : 60
            Layout.rightMargin: root.vertical ? 0 : 5
            Layout.alignment: Qt.AlignCenter
            sourceComponent: RowLayout {
                MaterialSymbol {
                    text: root.pRunning ? "search_activity" : "pause_circle"
                    color: Appearance.colors.colOnPrimary
                    iconSize: Appearance.font.pixelSize.large
                }

                StyledText {
                    Layout.topMargin: 3
                    text: {
                        const t = TimerService.pomodoroSecondsLeft
                        return Math.floor(t/60).toString().padStart(2,'0') + ":" + (t%60).toString().padStart(2,'0')
                    }
                    color: Appearance.colors.colOnPrimary
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TimerService.togglePomodoro()
                }
            } 
        }
    }
}
