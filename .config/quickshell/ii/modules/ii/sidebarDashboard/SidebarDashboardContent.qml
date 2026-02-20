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

import qs.modules.ii.ui 1.0

import "../bar" as Bar

import qs.modules.ii.sidebarDashboard.quickToggles
import qs.modules.ii.sidebarDashboard.quickToggles.classicStyle

import qs.modules.ii.sidebarDashboard.bluetoothDevices
import qs.modules.ii.sidebarDashboard.nightLight
import qs.modules.ii.sidebarDashboard.volumeMixer
import qs.modules.ii.sidebarDashboard.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes ? (Appearance.sizes.sidebarWidth || 350) : 350
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    readonly property bool safeNoEffects: false
    readonly property bool _configReady: (typeof Config !== "undefined") && Config && (Config.ready === true)
    readonly property var _opts: ((typeof Config !== "undefined") && Config) ? Config.options : null

    readonly property bool followGlobalSidebarStyle: (_opts?.sidebar?.followGlobalSidebarStyle ?? false)

    readonly property int styleIntFromConfig: {
        const o = _opts
        if (o?.sidebar?.dashboardRightBackgroundStyle !== undefined) return o.sidebar.dashboardRightBackgroundStyle
        if (o?.sidebar?.rightBackgroundStyle !== undefined) return o.sidebar.rightBackgroundStyle
        if (o?.sidebar?.sidebarBackgroundStyle !== undefined) return o.sidebar.sidebarBackgroundStyle
        if (o?.sidebar?.backgroundStyle !== undefined) return o.sidebar.backgroundStyle
        if (o?.bar?.barBackgroundStyle !== undefined) return o.bar.barBackgroundStyle
        return 1
    }

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _normalizeStyle(v) {
        if (typeof v === "number") return _styleFromConfig(v)
        if (typeof v !== "string") return "solid"
        const s = v.toLowerCase().trim()
        if (s === "visible") return "solid"
        if (s === "transparent") return "glass"
        return s
    }

    function _effectiveSidebarStyle(requested) {
        const s = _normalizeStyle(requested)
        if (s === "solid" || s === "glass") return "visible"
        if (s === "crystal") return "crystal"

        if (s === "adaptive") {
            const hw = (typeof UIState !== "undefined" && UIState && UIState.hasWindows !== undefined) ? UIState.hasWindows : false
            return hw ? "visible" : "crystal"
        }
        return "visible"
    }

    readonly property var requestedStyle: followGlobalSidebarStyle
        ? ((typeof UIState !== "undefined" && UIState) ? UIState.surfaceStyle : "solid")
        : _styleFromConfig(styleIntFromConfig)

    readonly property string sidebarStyle: _effectiveSidebarStyle(requestedStyle)
    readonly property bool bgIsVisible: sidebarStyle === "visible"
    readonly property bool bgIsCrystal: sidebarStyle === "crystal"

    property real pillSpacing: sidebarPadding
    readonly property real pillsRowWidth: sidebarRightBackground.width - sidebarPadding * 2
    readonly property real twoUpPillWidth: Math.floor((pillsRowWidth - pillSpacing) / 2)

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false;
                root.showBluetoothDialog = false;
                root.showAudioOutputDialog = false;
                root.showAudioInputDialog = false;
                root.showNightLightDialog = false;
            }
        }
    }

    implicitHeight: sidebarRightBackground.implicitHeight
    implicitWidth: sidebarRightBackground.implicitWidth

    StyledRectangularShadow {
        target: sidebarRightBackground
    }

    Rectangle {
        id: sidebarRightBackground
        anchors.fill: parent
        implicitHeight: parent.height - (Appearance.sizes ? (Appearance.sizes.hyprlandGapsOut || 0) : 0) * 2
        implicitWidth: sidebarWidth - (Appearance.sizes ? (Appearance.sizes.hyprlandGapsOut || 0) : 0) * 2

        radius: (Appearance.rounding ? (Appearance.rounding.screenRounding || 18) : 18) - (Appearance.sizes ? (Appearance.sizes.hyprlandGapsOut || 0) : 0) + 1
        antialiasing: true
        clip: true

        color: root.bgIsVisible 
            ? Appearance.colors.colLayer0 
            : (root.safeNoEffects ? Appearance.colors.colLayer0 : "transparent")

        border.width: root.bgIsVisible ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        Bar.BarBgOverlayGlassBlur {
            anchors.fill: parent
            visible: root.bgIsCrystal && !root.safeNoEffects
            
            useGlassMode: root.bgIsCrystal
            showSolidBackground: root.bgIsVisible
            backgroundColor: Appearance.colors.colLayer0 || Qt.rgba(0,0,0,0.5)
            cornerStyle: 0
            
            // Protección anti-crash para el Sidebar
            enableRealBlur: false 
            enableMask: false
        }

        Bar.BarBgCrystalOverlay {
            anchors.fill: parent
            visible: root.bgIsCrystal && !root.safeNoEffects
            
            useGlassMode: root.bgIsCrystal
            showSolidBackground: root.bgIsVisible
            backgroundColor: Appearance.colors.colLayer0 || Qt.rgba(0,0,0,0.5)
            cornerStyle: 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            SystemButtonRow {
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.bottomMargin: 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.pillSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.pillSpacing

                    Loader {
                        id: brightnessLoader
                        visible: active
                        active: !!(root._configReady && root._opts?.sidebar?.quickSliders?.enable && root._opts?.sidebar?.quickSliders?.showBrightness)
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160
                        
                        sourceComponent: Component {
                            QuickSliders { 
                                showBrightness: true
                                showVolume: false
                                showMic: false 
                            }
                        }
                    }

                    Loader {
                        id: nightLightPillLoader
                        visible: active
                        active: true
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160
                        
                        sourceComponent: Component { 
                            NightLightPill {} 
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.pillSpacing

                    Loader {
                        id: volumeLoader
                        visible: active
                        active: !!(root._configReady && root._opts?.sidebar?.quickSliders?.enable && root._opts?.sidebar?.quickSliders?.showVolume)
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160
                        
                        sourceComponent: Component {
                            QuickSliders { 
                                showBrightness: false
                                showVolume: true
                                showMic: false 
                            }
                        }
                    }

                    Loader {
                        id: micLoader
                        visible: active
                        active: !!(root._configReady && root._opts?.sidebar?.quickSliders?.enable && root._opts?.sidebar?.quickSliders?.showMic)
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160
                        
                        sourceComponent: Component {
                            QuickSliders { 
                                showBrightness: false
                                showVolume: false
                                showMic: true 
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                visible: active
                active: (root._opts?.sidebar?.quickToggles?.style === "classic")
                sourceComponent: Component {
                    ClassicQuickPanel {
                        onOpenAudioOutputDialog: root.showAudioOutputDialog = true
                        onOpenAudioInputDialog: root.showAudioInputDialog = true
                        onOpenBluetoothDialog: root.showBluetoothDialog = true
                        onOpenNightLightDialog: root.showNightLightDialog = true
                        onOpenWifiDialog: root.showWifiDialog = true
                    }
                }
            }

            Loader {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                visible: active
                active: (root._opts?.sidebar?.quickToggles?.style === "android")
                sourceComponent: Component {
                    AndroidQuickPanel {
                        editMode: root.editMode
                        onOpenAudioOutputDialog: root.showAudioOutputDialog = true
                        onOpenAudioInputDialog: root.showAudioInputDialog = true
                        onOpenBluetoothDialog: root.showBluetoothDialog = true
                        onOpenNightLightDialog: root.showNightLightDialog = true
                        onOpenWifiDialog: root.showWifiDialog = true
                    }
                }
            }

            CenterWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            BottomWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showAudioOutputDialog
        sourceComponent: Component {
            VolumeDialog {
                isSink: true
                show: true
                Component.onCompleted: forceActiveFocus()
                onDismiss: root.showAudioOutputDialog = false
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showAudioInputDialog
        sourceComponent: Component {
            VolumeDialog {
                isSink: false
                show: true
                Component.onCompleted: forceActiveFocus()
                onDismiss: root.showAudioInputDialog = false
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showBluetoothDialog
        sourceComponent: Component {
            BluetoothDialog {
                show: true
                Component.onCompleted: {
                    forceActiveFocus()
                    Bluetooth.defaultAdapter.enabled = true
                    Bluetooth.defaultAdapter.discovering = true
                }
                Component.onDestruction: Bluetooth.defaultAdapter.discovering = false
                onDismiss: root.showBluetoothDialog = false
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showNightLightDialog
        sourceComponent: Component {
            NightLightDialog {
                show: true
                Component.onCompleted: forceActiveFocus()
                onDismiss: root.showNightLightDialog = false
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showWifiDialog
        sourceComponent: Component {
            WifiDialog {
                show: true
                Component.onCompleted: {
                    forceActiveFocus()
                    Network.enableWifi()
                    Network.rescanWifi()
                }
                onDismiss: root.showWifiDialog = false
            }
        }
    }

    component NightLightQuickSlider: StyledSlider {
        id: s
        required property string materialSymbol
        property string tooltipText: ""
        implicitWidth: 100 

        configuration: StyledSlider.Configuration.M
        stopIndicatorValues: []

        MaterialSymbol {
            id: icon
            property bool nearFull: s.value >= 0.82
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: nearFull ? s.handle.right : parent.right
            anchors.rightMargin: nearFull ? 14 : 8
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: s.materialSymbol

            Behavior on color { 
                ColorAnimation { duration: 150 } 
            }
            Behavior on anchors.rightMargin { 
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic } 
            }
        }
        
        StyledToolTip { text: s.tooltipText }
    }

    component NightLightPill: Rectangle {
        id: nl
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1
        clip: true

        property real verticalPadding: 3
        property real horizontalPadding: 8

        implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
        implicitHeight: contentItem.implicitHeight + verticalPadding * 2

        readonly property real kMin: 1200
        readonly property real kMax: 6500

        function clamp(x, a, b) { 
            return Math.max(a, Math.min(b, x)) 
        }
        function kelvinTo01(k) {
            const kk = clamp(k, kMin, kMax)
            return (kMax - kk) / (kMax - kMin)
        }
        function v01ToKelvin(v) {
            const vv = clamp(v, 0.0, 1.0)
            return kMax - vv * (kMax - kMin)
        }

        RowLayout {
            id: contentItem
            anchors.fill: parent
            anchors.leftMargin: nl.horizontalPadding
            anchors.rightMargin: nl.horizontalPadding
            anchors.topMargin: nl.verticalPadding
            anchors.bottomMargin: nl.verticalPadding
            spacing: 6

            NightLightQuickSlider {
                Layout.fillWidth: true
                materialSymbol: "nightlight"
                value: nl.kelvinTo01(root._opts?.light?.night?.colorTemperature ?? 6500)
                tooltipText: `${Math.round(root._opts?.light?.night?.colorTemperature ?? 6500)}K`
                
                onMoved: {
                    if (!root._opts?.light?.night) return
                    root._opts.light.night.colorTemperature = nl.v01ToKelvin(value)
                }
            }

            QuickToggleButton {
                Layout.alignment: Qt.AlignVCenter
                toggled: false
                buttonIcon: "settings"
                onClicked: root.showNightLightDialog = true
                StyledToolTip { text: Translation.tr("Night Light settings") }
            }
        }
    }

    component SystemButtonRow: Item {
        implicitHeight: Math.max(uptimeContainer.implicitHeight, systemButtonsRow.implicitHeight)

        Rectangle {
            id: uptimeContainer
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            color: Appearance.colors.colLayer1
            radius: height / 2
            implicitWidth: uptimeRow.implicitWidth + 24
            implicitHeight: uptimeRow.implicitHeight + 8

            Row {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 8
                
                CustomIcon {
                    id: distroIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 25
                    height: 25
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnLayer0
                }
                
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    textFormat: Text.MarkdownText
                }
            }
        }

        ButtonGroup {
            id: systemButtonsRow
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            color: Appearance.colors.colLayer1
            padding: 4

            QuickToggleButton {
                toggled: root.editMode
                visible: (root._opts?.sidebar?.quickToggles?.style === "android")
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip {
                    text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
                }
            }
            
            QuickToggleButton {
                toggled: false
                buttonIcon: "restart_alt"
                onClicked: { Hyprland.dispatch("reload"); Quickshell.reload(true); }
                StyledToolTip { text: Translation.tr("Reload Hyprland & Quickshell") }
            }
            
            QuickToggleButton {
                toggled: false
                buttonIcon: "settings"
                onClicked: {
                    GlobalStates.sidebarRightOpen = false;
                    Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                }
                StyledToolTip { text: Translation.tr("Settings") }
            }
            
            QuickToggleButton {
                id: updateButton
                toggled: confirm
                property bool confirm: false
                buttonIcon: confirm ? "check" : "download"
                
                Timer {
                    id: confirmTimer
                    interval: 2000
                    onTriggered: { confirmTimer.stop(); updateButton.confirm = false }
                }
                
                onClicked: {
                    if (confirm) {
                        GlobalStates.sidebarRightOpen = false;
                        const sp = root._opts?.update?.scriptPath ?? ""
                        const sf = root._opts?.update?.scriptFlags ?? ""
                        if (sp.length > 0) Quickshell.execDetached(["bash", "-c", sp + " " + sf ]);
                    } else {
                        confirm = true
                        confirmTimer.start()
                    }
                }
                StyledToolTip { text: Translation.tr("Update the ii-vynx") }
            }
            
            QuickToggleButton {
                toggled: false
                buttonIcon: "power_settings_new"
                onClicked: { GlobalStates.sessionOpen = true; }
                StyledToolTip { text: Translation.tr("Session") }
            }
        }
    }
}
