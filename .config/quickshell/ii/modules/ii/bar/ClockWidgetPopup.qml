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

    // Corregido: En JS los meses van de 0 (Enero) a 11 (Diciembre).
    // Fechas ajustadas a los días exactos de El Salvador.
    property var salvadorHolidays: [
        { month: 4, day: 1,  label: "Día del Trabajo" },
        { month: 4, day: 10, label: "Día de la Madre" },
        { month: 5, day: 17, label: "Día del Padre" },
        { month: 5, day: 29, label: "Día del Servidor Judicial" }, // Asumiendo 29 de Junio
        { month: 7, day: 6,  label: "Fiestas Agostinas" },
        { month: 8, day: 15, label: "Día de la Independencia" },
        { month: 10, day: 2, label: "Día de los Difuntos" },
        { month: 11, day: 25, label: "Navidad" }
    ]

    // Ahora devuelve un arreglo de objetos para armar la UI dinámicamente
    function getUpcomingHolidays() {
        // Normalizamos "hoy" a medianoche para evitar bugs de horas
        let today = new Date(calYear, calMonth, calToday); 
        
        return salvadorHolidays.filter(h => {
            let hDate = new Date(calYear, h.month, h.day)
            return hDate >= today
        }).slice(0, 5)
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 16 // Aumentamos un poco el espaciado general para que respire

        // --- CALENDARIO ---
        Item {
            Layout.fillWidth: true
            implicitHeight: calendarColumn.implicitHeight

            Column {
                id: calendarColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 12

                Rectangle {
                    width: monthLabel.implicitWidth + 32
                    height: monthLabel.implicitHeight + 12
                    radius: height / 2
                    color: Appearance.colors.colPrimary
                    opacity: 0.15 // Un fondo un poco más sutil
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        id: monthLabel
                        anchors.centerIn: parent
                        text: root.calMonthLabel.toUpperCase()
                        font.pixelSize: Appearance.font.pixelSize.medium
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Appearance.colors.colPrimary
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    readonly property var dayNames: ["Lu","Ma","Mi","Ju","Vi","Sá","Do"] // Español por defecto

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
                                opacity: 0.6 // Reduce el peso visual de los encabezados
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Appearance.colors.colOnSurface
                    opacity: 0.10 // Divisor más elegante
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
                                opacity: dayCell.isToday ? 0.9 : 0
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
                                opacity: dayCell.isToday ? 1.0 : (dayCell.isWeekend ? 0.8 : 0.7)
                            }
                        }
                    }
                }
            }
        }

        // --- SEPARADOR Y UPTIME ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOnSurface
            opacity: 0.10
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        StyledPopupValueRow {
            icon: "timelapse"
            label: Translation.tr("Tiempo de actividad")
            value: root.formattedUptime
            Layout.fillWidth: true
        }

        // --- PRÓXIMOS FERIADOS ---
        ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            StyledPopupValueRow {
                icon: "celebration"
                label: Translation.tr("Próximos feriados")
                value: "" // Funciona como título
                Layout.fillWidth: true
            }

            // Nueva lista de feriados más estructurada y elegante
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 32 // Alineado con el texto del row anterior (asumiendo el espacio del ícono)
                spacing: 6

                property var upcomingList: root.getUpcomingHolidays()

                StyledText {
                    visible: parent.upcomingList.length === 0
                    text: "No hay feriados próximos"
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.small
                    opacity: 0.7
                }

                Repeater {
                    model: parent.upcomingList
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledText {
                            // Fecha
                            text: {
                                let d = new Date(root.calYear, modelData.month, modelData.day)
                                return d.toLocaleDateString(Qt.locale(), "dd MMM")
                            }
                            color: Appearance.colors.colPrimary
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            Layout.alignment: Qt.AlignTop
                        }

                        StyledText {
                            // Nombre del feriado
                            text: modelData.label
                            color: Appearance.colors.colOnSurface
                            font.pixelSize: Appearance.font.pixelSize.small
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.85
                        }
                    }
                }
            }
        }
    }
}
