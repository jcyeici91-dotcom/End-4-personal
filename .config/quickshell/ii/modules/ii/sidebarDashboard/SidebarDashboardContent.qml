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

import qs.modules.ii.sidebarDashboard.quickToggles
import qs.modules.ii.sidebarDashboard.quickToggles.classicStyle

import qs.modules.ii.sidebarDashboard.bluetoothDevices
import qs.modules.ii.sidebarDashboard.nightLight
import qs.modules.ii.sidebarDashboard.volumeMixer
import qs.modules.ii.sidebarDashboard.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    // 2x2 “pills” sizing
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
                // root.showNightLightDialog = false; // opcional
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
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            SystemButtonRow {
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.bottomMargin: 0
            }

            /* =========================
               PÍLDORAS EN 2x2
               Arriba: Brillo | Luz Noche
               Abajo : Volumen | Mic
               ========================= */

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.pillSpacing

                // ---- Row 1: Brightness + Night Light ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.pillSpacing

                    Loader {
                        id: brightnessLoader
                        visible: active
                        active: {
                            const s = Config.options.sidebar.quickSliders
                            return !!(Config.ready && s.enable && s.showBrightness)
                        }

                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160

                        sourceComponent: QuickSliders {
                            showBrightness: true
                            showVolume: false
                            showMic: false
                        }
                    }

                    Loader {
                        id: nightLightPillLoader
                        visible: active
                        active: true

                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160

                        sourceComponent: NightLightPill {}
                    }
                }

                // ---- Row 2: Volume + Mic ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.pillSpacing

                    Loader {
                        id: volumeLoader
                        visible: active
                        active: {
                            const s = Config.options.sidebar.quickSliders
                            return !!(Config.ready && s.enable && s.showVolume)
                        }

                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160

                        sourceComponent: QuickSliders {
                            showBrightness: false
                            showVolume: true
                            showMic: false
                        }
                    }

                    Loader {
                        id: micLoader
                        visible: active
                        active: {
                            const s = Config.options.sidebar.quickSliders
                            return !!(Config.ready && s.enable && s.showMic)
                        }

                        Layout.fillWidth: false
                        Layout.preferredWidth: root.twoUpPillWidth
                        Layout.minimumWidth: 160

                        sourceComponent: QuickSliders {
                            showBrightness: false
                            showVolume: false
                            showMic: true
                        }
                    }
                }
            }

            /* =========================
               QUICK TOGGLES (centro)
               ========================= */

            LoaderedQuickPanelImplementation {
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode
                }
            }

            /* =========================
               Widgets (resto)
               ========================= */

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

    /* ===== Dialogs ===== */

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog { isSink: true }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog { isSink: false }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    /* ===== Components ===== */

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent

        onShownChanged: if (shown) toggleDialogLoader.active = true;
        active: shown
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                toggleDialogLoader.item.show = false
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.item.visible && !root[toggleDialogLoader.shownPropertyString])
                    toggleDialogLoader.active = false;
            }
        }
    }

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() { root.showAudioOutputDialog = true; }
            function onOpenAudioInputDialog() { root.showAudioInputDialog = true; }
            function onOpenBluetoothDialog() { root.showBluetoothDialog = true; }
            function onOpenNightLightDialog() { root.showNightLightDialog = true; }
            function onOpenWifiDialog() { root.showWifiDialog = true; }
        }
    }

    component NightLightQuickSlider: StyledSlider {
        id: s
        required property string materialSymbol
        property string tooltipText: ""

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
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        StyledToolTip { text: s.tooltipText }
    }

    component NightLightPill: Rectangle {
        id: nl
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1
        clip: true

        // compacta
        property real verticalPadding: 3
        property real horizontalPadding: 8

        implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
        implicitHeight: contentItem.implicitHeight + verticalPadding * 2

        readonly property real kMin: 1200
        readonly property real kMax: 6500

        function clamp(x, a, b) { return Math.max(a, Math.min(b, x)) }
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

            // (QUITADO) Botón con icono de foco/círculo a la izquierda

            NightLightQuickSlider {
                Layout.fillWidth: true
                materialSymbol: "nightlight"
                value: nl.kelvinTo01(Config.options.light.night.colorTemperature)
                tooltipText: `${Math.round(Config.options.light.night.colorTemperature)}K`
                onMoved: {
                    Config.options.light.night.colorTemperature = nl.v01ToKelvin(value)
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
                visible: Config.options.sidebar.quickToggles.style === "android"
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
                        Quickshell.execDetached(["bash", "-c", Config.options.update.scriptPath + " " + Config.options.update.scriptFlags ]);
                    } else {
                        confirm = true
                        confirmTimer.start()
                    }
                }
                StyledToolTip {
                    text: Translation.tr("Update the ii-vynx, make sure to set script path in settings")
                }
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

