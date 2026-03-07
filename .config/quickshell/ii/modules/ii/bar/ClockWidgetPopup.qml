import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    property var currentDate: DateTime.clock.date
    property string formattedUptime: DateTime.uptime

    property int calYear: currentDate.getFullYear()
    property int calMonth: currentDate.getMonth()
    property int calToday: currentDate.getDate()

    property int daysInMonth: new Date(calYear, calMonth + 1, 0).getDate()

    property int firstDayOffset: {
        const d = new Date(calYear, calMonth, 1).getDay()
        return (d === 0) ? 6 : d - 1
    }

    property string calMonthLabel: {
        return Qt.locale().standaloneMonthName(calMonth, Locale.LongFormat) + " " + calYear
    }

    property var salvadorHolidays: [
        { month: 4, day: 30, label: "Día del Trabajo" },
        { month: 5, day: 9,  label: "Día de la Madre" },
        { month: 6, day: 16, label: "Día del Padre" },
        { month: 5, day: 29, label: "Día del Servidor Judicial" },
        { month: 7, day: 5,  label: "Fiestas Agostinas / Divino Salvador" },
        { month: 8, day: 14, label: "Día de la Independencia" },
        { month: 10, day: 1, label: "Día de los Difuntos" },
        { month: 11, day: 24, label: "Navidad" }
    ]

    function getUpcomingHolidays() {
        let today = currentDate
        let upcoming = salvadorHolidays.filter(h => {
            let hDate = new Date(calYear, h.month, h.day)
            return hDate >= today
        }).slice(0, 5)

        if (upcoming.length === 0) return "No hay feriados próximos"

        return upcoming.map(h => {
            let d = new Date(calYear, h.month, h.day)
            let dayStr = d.toLocaleDateString(Qt.locale(), "dd MMM")
            return dayStr + " – " + h.label
        }).join("\n")
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 12

        Item {
            Layout.fillWidth: true
            implicitHeight: calendarColumn.implicitHeight

            Column {
                id: calendarColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: monthLabel.implicitWidth + 32
                    height: monthLabel.implicitHeight + 12
                    radius: height / 2
                    color: Appearance.colors.colPrimary
                    opacity: 0.20
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        id: monthLabel
                        anchors.centerIn: parent
                        text: root.calMonthLabel.toUpperCase()
                        font.pixelSize: Appearance.font.pixelSize.medium
                        font.weight: Font.Bold
                        font.letterSpacing: 1.8
                        color: Appearance.colors.colPrimary
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    readonly property var dayNames: ["Mo","Tu","We","Th","Fr","Sa","Su"]

                    Repeater {
                        model: 7
                        delegate: Item {
                            width: calendarColumn.width / 7
                            height: 24
                            StyledText {
                                anchors.centerIn: parent
                                text: parent.parent.dayNames[index]
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: (index >= 5) ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                opacity: 0.75
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Appearance.colors.colOnSurface
                    opacity: 0.15
                }

                Grid {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: 42
                        delegate: Item {
                            id: dayCell
                            width: calendarColumn.width / 7
                            height: width

                            readonly property int dayNumber: index - root.firstDayOffset + 1
                            readonly property bool isValid: dayNumber >= 1 && dayNumber <= root.daysInMonth
                            readonly property bool isToday: isValid && dayNumber === root.calToday
                            readonly property bool isWeekend: (index % 7) >= 5

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.82
                                height: width
                                radius: width / 2
                                color: Appearance.colors.colPrimary
                                opacity: dayCell.isToday ? 0.85 : 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: dayCell.isValid
                                text: dayCell.dayNumber
                                font.pixelSize: Appearance.font.pixelSize.small + 1
                                font.weight: dayCell.isToday ? Font.Bold : Font.Medium
                                color: {
                                    if (dayCell.isToday) return Appearance.colors.colOnPrimary
                                    if (dayCell.isWeekend) return Appearance.colors.colPrimary
                                    return Appearance.colors.colOnSurface
                                }
                                opacity: dayCell.isToday ? 1.0 : (dayCell.isWeekend ? 0.9 : 0.8)
                            }
                        }
                    }
                }
            }
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("System uptime")
            value: root.formattedUptime
            Layout.topMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOnSurface
            opacity: 0.12
        }

        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "celebration"
                label: Translation.tr("Próximos asuetos / feriados")
                value: ""
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small + 1
                lineHeight: 1.3
                text: getUpcomingHolidays()
            }
        }
    }
}

