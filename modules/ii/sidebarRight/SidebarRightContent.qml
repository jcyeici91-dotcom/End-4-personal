import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

// Imports de módulos específicos
import qs.modules.ii.sidebarRight.quickToggles
import qs.modules.ii.sidebarRight.quickToggles.classicStyle
import qs.modules.ii.sidebarRight.bluetoothDevices
import qs.modules.ii.sidebarRight.nightLight
import qs.modules.ii.sidebarRight.volumeMixer
import qs.modules.ii.sidebarRight.wifiNetworks

Item {
    id: root
    
    // --- Configuración y Propiedades ---
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    
    // Estados de Diálogos
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    // Lógica de visualización de Sliders (Extraída para limpieza)
    readonly property bool showSliders: {
        const conf = Config.options.sidebar.quickSliders
        if (!conf.enable) return false
        return (conf.showMic || conf.showVolume || conf.showBrightness)
    }

    // --- Control de Eventos ---
    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            // Cerrar todos los diálogos al cerrar la sidebar
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false
                root.showBluetoothDialog = false
                root.showAudioOutputDialog = false
                root.showAudioInputDialog = false
                root.showNightLightDialog = false
            }
        }
    }

    // --- Layout Principal ---
    implicitHeight: sidebarRightBackground.implicitHeight
    implicitWidth: sidebarRightBackground.implicitWidth

    StyledRectangularShadow {
        target: sidebarRightBackground
    }

    Rectangle {
        id: sidebarRightBackground
        anchors.fill: parent
        
        // Cálculos de tamaño
        implicitHeight: parent.height - (Appearance.sizes.hyprlandGapsOut * 2)
        implicitWidth: sidebarWidth - (Appearance.sizes.hyprlandGapsOut * 2)
        
        // Estilo
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
        clip: true // Asegura que el contenido no se salga de las esquinas redondeadas

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            // 1. Fila de Botones de Sistema (Uptime, Settings, Power)
            SystemButtonRow {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.topMargin: 5
            }

            // 2. Sliders (Volumen/Brillo)
            Loader {
                id: slidersLoader
                Layout.fillWidth: true
                visible: active
                active: root.showSliders
                sourceComponent: QuickSliders {}
            }

            // 3. Panel de Toggles (Classic vs Android)
            // Optimizado: Un solo Loader que elige el componente
            Loader {
                id: quickPanelLoader
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                
                sourceComponent: {
                    if (Config.options.sidebar.quickToggles.style === "android") return androidPanelComp
                    return classicPanelComp
                }

                // Componentes definidos internamente para el Loader
                Component {
                    id: classicPanelComp
                    ClassicQuickPanel {} 
                }
                
                Component { 
                    id: androidPanelComp
                    AndroidQuickPanel { editMode: root.editMode }
                }

                // Conexiones para los eventos de los paneles
                Connections {
                    target: quickPanelLoader.item
                    ignoreUnknownSignals: true
                    function onOpenAudioOutputDialog() { root.showAudioOutputDialog = true }
                    function onOpenAudioInputDialog() { root.showAudioInputDialog = true }
                    function onOpenBluetoothDialog() { root.showBluetoothDialog = true }
                    function onOpenNightLightDialog() { root.showNightLightDialog = true }
                    function onOpenWifiDialog() { root.showWifiDialog = true }
                }
            }

            // 4. Widgets Centrales (Media Player, etc)
            CenterWidgetGroup {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
            }

            // 5. Widgets Inferiores
            BottomWidgetGroup {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: implicitHeight
            }
        }
    }

    // --- Definición de Diálogos ---
    
    // Componente base para evitar repetición de código
    component ToggleDialogLoader: Loader {
        id: dlgLoader
        required property string propName
        property alias dialogComponent: dlgLoader.sourceComponent
        
        anchors.fill: parent
        active: root[propName]
        
        onActiveChanged: {
            if (active && item) {
                item.show = true
                item.forceActiveFocus()
            }
        }

        Connections {
            target: dlgLoader.item
            ignoreUnknownSignals: true
            function onDismiss() {
                if (dlgLoader.item) dlgLoader.item.show = false
                root[dlgLoader.propName] = false
            }
            function onVisibleChanged() {
                if (dlgLoader.item && !dlgLoader.item.visible && !root[dlgLoader.propName]) {
                    dlgLoader.active = false
                }
            }
        }
    }

    // Instancias de Diálogos
    ToggleDialogLoader {
        propName: "showAudioOutputDialog"
        dialogComponent: VolumeDialog { isSink: true }
    }

    ToggleDialogLoader {
        propName: "showAudioInputDialog"
        dialogComponent: VolumeDialog { isSink: false }
    }

    ToggleDialogLoader {
        propName: "showBluetoothDialog"
        dialogComponent: BluetoothDialog {}
        // Lógica específica de Bluetooth al mostrarse/ocultarse
        onActiveChanged: {
            if (active) {
                Bluetooth.defaultAdapter.enabled = true
                Bluetooth.defaultAdapter.discovering = true
            } else {
                Bluetooth.defaultAdapter.discovering = false
            }
        }
    }

    ToggleDialogLoader {
        propName: "showNightLightDialog"
        dialogComponent: NightLightDialog {}
    }

    ToggleDialogLoader {
        propName: "showWifiDialog"
        dialogComponent: WifiDialog {}
        onActiveChanged: {
            if (active) {
                Network.enableWifi()
                Network.rescanWifi()
            }
        }
    }

    // --- Componente de Fila de Botones de Sistema ---
    component SystemButtonRow: Item {
        implicitHeight: Math.max(uptimePill.implicitHeight, actionButtons.implicitHeight)

        // Píldora de Uptime (Izquierda)
        Rectangle {
            id: uptimePill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            
            color: Appearance.colors.colLayer1
            radius: height / 2
            implicitHeight: 36 // Altura fija para consistencia
            implicitWidth: uptimeRow.implicitWidth + 24
            
            Row {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 8
                
                CustomIcon {
                    width: 20
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnLayer0
                }
                
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                }
            }
        }

        // Botones de Acción (Derecha)
        ButtonGroup {
            id: actionButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            
            color: Appearance.colors.colLayer1
            padding: 4
            spacing: 2

            QuickToggleButton {
                visible: Config.options.sidebar.quickToggles.style === "android"
                toggled: root.editMode
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip { text: Translation.tr("Edit Toggles") }
            }
            
            QuickToggleButton {
                buttonIcon: "restart_alt"
                onClicked: {
                    Hyprland.dispatch("reload")
                    Quickshell.reload(true)
                }
                StyledToolTip { text: Translation.tr("Reload System") }
            }
            
            QuickToggleButton {
                buttonIcon: "settings"
                onClicked: {
                    GlobalStates.sidebarRightOpen = false
                    Quickshell.execDetached(["qs", "-p", root.settingsQmlPath])
                }
                StyledToolTip { text: Translation.tr("Settings") }
            }
            
            QuickToggleButton {
                buttonIcon: "power_settings_new"
                onClicked: GlobalStates.sessionOpen = true
                StyledToolTip { text: Translation.tr("Power Menu") }
            }
        }
    }
}
