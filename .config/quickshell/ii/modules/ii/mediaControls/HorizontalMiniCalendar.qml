pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.common

Item {
    id: root
    implicitHeight: 50 // Un poquito más alto para respirar
    implicitWidth: layout.implicitWidth

    property int weekShift: 0
    property color highlightColor: Appearance.colors.colPrimary
    property color normalColor: Appearance.colors.colSubtext

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.weekShift--;
            else if (wheel.angleDelta.y < 0) root.weekShift++;
        }
        onClicked: root.weekShift = 0 
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 24 // Más separación entre el mes y los días

        // 1. MES (Elegante y moderno)
        StyledText {
            text: {
                let d = new Date();
                d.setDate(d.getDate() + (root.weekShift * 7));
                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                return months[d.getMonth()];
            }
            font.pixelSize: 28 // Más grande
            font.weight: Font.ExtraBold // Extra grueso, muy moderno
            font.letterSpacing: -0.5 // Letras ligeramente juntas para títulos grandes
            color: Appearance.colors.colOnLayer0
            Layout.alignment: Qt.AlignVCenter
        }

        // 2. LOS 7 DÍAS EN HORIZONTAL
        RowLayout {
            spacing: 16
            Layout.alignment: Qt.AlignVCenter | Qt.AlignBottom

            Repeater {
                model: 7
                delegate: ColumnLayout {
                    required property int index
                    
                    property int offset: index - 3 + (root.weekShift * 7)
                    property bool isToday: offset === 0
                    
                    property var dateObj: {
                        let d = new Date();
                        let trigger = offset; 
                        d.setDate(d.getDate() + trigger);
                        return d;
                    }

                    spacing: 4 // Un poquito más de espacio entre letra y número
                    Layout.alignment: Qt.AlignBottom

                    // Nombre del día (S, M, T... o THU)
                    StyledText {
                        text: {
                            const daysFull = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
                            const daysShort = ["S", "M", "T", "W", "T", "F", "S"];
                            return isToday ? daysFull[dateObj.getDay()] : daysShort[dateObj.getDay()];
                        }
                        font.pixelSize: isToday ? 11 : 10
                        font.weight: isToday ? Font.ExtraBold : Font.DemiBold // DemiBold resalta mejor que Normal
                        font.letterSpacing: 1.0 // Espaciado premium para letras mayúsculas
                        color: isToday ? root.highlightColor : root.normalColor
                        opacity: isToday ? 1.0 : 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Número del día (01, 15...)
                    StyledText {
                        text: dateObj.getDate().toString().padStart(2, "0")
                        font.pixelSize: isToday ? 20 : 15 // Aumentado para mayor legibilidad
                        font.weight: isToday ? Font.ExtraBold : Font.DemiBold
                        color: isToday ? root.highlightColor : root.normalColor
                        opacity: isToday ? 1.0 : 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
