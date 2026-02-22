import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    
    // --- NUEVO: Orientación ---
    property bool vertical: false
    
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    // Ajustamos las dimensiones implícitas según la orientación
    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : batteryProgress.implicitWidth
    implicitHeight: vertical ? batteryProgress.implicitWidth : Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        
        // Si estamos en vertical, rotamos la barra 90 grados para que vaya de abajo hacia arriba
        rotation: root.vertical ? -90 : 0
        
        value: percentage
        highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            // Como la barra está rotada -90 grados, el contenido interior se vería de lado.
            // Lo rotamos 90 grados de vuelta para que el texto/icono se vean derechos.
            RowLayout {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: (parent.height - height) / 2
                }
                spacing: 0
                rotation: root.vertical ? 90 : 0 // Contrarresta la rotación del padre

                MaterialSymbol {
                    id: boltIcon
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "bolt"
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: isCharging && percentage < 1 // TODO: animation
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    // Si prefieres que en vertical no salga el porcentaje, puedes poner:
                    // visible: !root.vertical
                    text: batteryProgress.text
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
