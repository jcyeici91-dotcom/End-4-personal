import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Qt.labs.settings 1.1
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root

    // ORIENTACIÓN / ESTADO
     property bool vertical: false
    property bool borderless: Config.options.bar.borderless

  
    property bool useDensityPreset: true
    property string densityPreset: "compact" // "compact" | "normal" | "large"

        // EFECTOS (master + sub)
     property bool enableEffectsMaster: true
    property bool enableSprings: true
    property bool enableHoverGrow: true
    property bool enableHoverRotate: true
    property bool enableHoverRecolor: true


    // Espacio entre botones
    property int manualGridRowSpacingBase: 8
    property int manualGridColumnSpacingBase: 8

    // Padding externo (extra al implicitWidth/Height)
    property int manualOuterPaddingH: 4
    property int manualOuterPaddingV: 4

    // Tamaño iconos
    property real manualBaseIconScale: 1.00
    property real manualHoverScale: 1.20

    property bool tooltipsEnabled: true
    property bool tooltipsFollowEnabled: true
    property int tooltipFollowIntervalMs: 30
    property int tooltipGapBelow: 10
    property int tooltipGapSide: 10

    // Visual tooltip
    property int tooltipRadius: 10
    property int tooltipMaxWidth: 360
    property real tooltipBgOpacity: 0.82
    property real tooltipShadowOpacity: 0.22

    readonly property var densityPresets: ({
        compact: {
            gridRowSpacingBase: 4,
            gridColumnSpacingBase: 4,
            outerPaddingH: 0,
            outerPaddingV: 0,
            baseIconScale: 0.95,
            hoverScale: 1.12
        },
        normal: {
            gridRowSpacingBase: 8,
            gridColumnSpacingBase: 8,
            outerPaddingH: 4,
            outerPaddingV: 4,
            baseIconScale: 1.00,
            hoverScale: 1.20
        },
        large: {
            gridRowSpacingBase: 12,
            gridColumnSpacingBase: 12,
            outerPaddingH: 8,
            outerPaddingV: 8,
            baseIconScale: 1.08,
            hoverScale: 1.24
        }
    })

    function _presetObj() {
        const p = root.densityPresets?.[root.densityPreset]
        return p ? p : root.densityPresets.normal
    }

       readonly property int gridRowSpacingBase: root.useDensityPreset
        ? root._presetObj().gridRowSpacingBase
        : root.manualGridRowSpacingBase

    readonly property int gridColumnSpacingBase: root.useDensityPreset
        ? root._presetObj().gridColumnSpacingBase
        : root.manualGridColumnSpacingBase

    readonly property int outerPaddingH: root.useDensityPreset
        ? root._presetObj().outerPaddingH
        : root.manualOuterPaddingH

    readonly property int outerPaddingV: root.useDensityPreset
        ? root._presetObj().outerPaddingV
        : root.manualOuterPaddingV

    readonly property real baseIconScale: root.useDensityPreset
        ? root._presetObj().baseIconScale
        : root.manualBaseIconScale

    readonly property real hoverScale: root.useDensityPreset
        ? root._presetObj().hoverScale
        : root.manualHoverScale

    // Espaciados “finales”
    readonly property int gridRowSpacing: Math.max(0, Math.round(root.gridRowSpacingBase))
    readonly property int gridColumnSpacing: Math.max(0, Math.round(root.gridColumnSpacingBase))

       readonly property int baseIconSize: Math.max(
        1,
        Math.round(Appearance.font.pixelSize.large * root.baseIconScale)
    )

    function hoverIconSize(mult) {
        // mult: factor específico por botón (pequeño ajuste por ícono)
        const canGrow = root.enableEffectsMaster && root.enableHoverGrow
        const m = canGrow ? (root.hoverScale * mult) : 1.0
        return Math.max(1, Math.round(root.baseIconSize * m))
    }

    property Item tooltipTarget: null
    property string tooltipText: ""

    readonly property bool tooltipsEnabledEffective: root.tooltipsEnabled && !root.vertical

    // refs de botones (evita Connections dentro de CircleUtilButton)
    property Item _layoutBtnRef: null
    property Item _kbdBtnRef: null
    property Item _modeBtnRef: null
    property Item _perfBtnRef: null

    Settings {
        id: utilSettings
        category: "utilbuttons"
        property int layoutIndex: 0
    }

    function _setTip(target, text) {
        if (!root.tooltipsEnabledEffective) return
        root.tooltipTarget = target
        root.tooltipText = text || ""
    }

    function _clearTipIf(target) {
        if (root.tooltipTarget === target) {
            root.tooltipTarget = null
            root.tooltipText = ""
        }
    }

    function _refreshTipIfTarget(target, newText) {
        if (!root.tooltipsEnabledEffective) return
        if (root.tooltipTarget === target) root.tooltipText = newText || ""
    }

    onVerticalChanged: {
        if (root.vertical) {
            root.tooltipTarget = null
            root.tooltipText = ""
        }
    }

      Item {
        id: tipLayer

        parent: (root.Window.window && root.Window.window.contentItem) ? root.Window.window.contentItem : root
        z: 999999
        anchors.fill: parent
        clip: false

        visible: root.tooltipsEnabledEffective

        Timer {
            id: tipFollow
            interval: root.tooltipFollowIntervalMs
            repeat: true
            running: root.tooltipsFollowEnabled && tipBubble.visible
            onTriggered: tipBubble.reposition()
        }

        Item {
            id: tipBubble
            visible: tipLayer.visible
                     && root.tooltipTarget !== null
                     && root.tooltipText.length > 0
            opacity: visible ? 1 : 0
            clip: false
            enabled: false

            Behavior on opacity {
                NumberAnimation {
                    duration: root.enableEffectsMaster ? 130 : 0
                    easing.type: Easing.OutCubic
                }
            }

            readonly property int pad: 6

            width: bubble.implicitWidth
            height: bubble.implicitHeight

            function reposition() {
                if (!visible || !root.tooltipTarget) return

                const p = root.tooltipTarget.mapToItem(tipLayer, 0, 0)
                const tw = root.tooltipTarget.width
                const th = root.tooltipTarget.height

                const w = tipBubble.width
                const h = tipBubble.height

                let rawX = p.x + tw / 2 - w / 2
                let rawY = p.y + th + root.tooltipGapBelow

                tipBubble.x = Math.round(Math.max(pad, Math.min(rawX, tipLayer.width - pad - w)))
                tipBubble.y = Math.round(Math.max(pad, Math.min(rawY, tipLayer.height - pad - h)))
            }

            onVisibleChanged: {
                if (visible) {
                    reposition()
                    if (root.tooltipsFollowEnabled) tipFollow.start()
                } else {
                    tipFollow.stop()
                }
            }

            Connections {
                target: root
                function onTooltipTargetChanged() { tipBubble.reposition() }
                function onTooltipTextChanged() { tipBubble.reposition() }
            }

            Rectangle {
                anchors.centerIn: bubble
                width: bubble.width + 2
                height: bubble.height + 2
                radius: bubble.radius + 1
                color: Qt.rgba(0, 0, 0, root.tooltipShadowOpacity)
                visible: tipBubble.visible
            }

            Rectangle {
                id: bubble
                radius: root.tooltipRadius
                color: Qt.rgba(0, 0, 0, root.tooltipBgOpacity)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                implicitHeight: label.implicitHeight + 10
                implicitWidth: Math.min(root.tooltipMaxWidth, label.implicitWidth + 14)

                onImplicitWidthChanged: tipBubble.reposition()
                onImplicitHeightChanged: tipBubble.reposition()

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.tooltipText
                    color: "white"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    renderType: Text.NativeRendering
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }
        }
    }

    property int _layoutIndex: 0
    readonly property var _layouts: ["dwindle", "master", "scrolling"]

    function _currentLayout() {
        const i = Math.max(0, Math.min(root._layoutIndex, root._layouts.length - 1))
        return root._layouts[i]
    }

    function _prettyLayoutName(layout) {
        if (layout === "dwindle") return "Dwindle"
        if (layout === "master") return "Master"
        if (layout === "scrolling") return "Scrolling"
        return layout
    }

    function _applyLayout(layout) {
        Quickshell.execDetached(["hyprctl", "keyword", "general:layout", layout])
    }

    function _saveLayoutIndex() {
        utilSettings.layoutIndex = root._layoutIndex
    }

    function _advanceLayout() {
        root._layoutIndex = (root._layoutIndex + 1) % root._layouts.length
        root._saveLayoutIndex()
        root._applyLayout(root._currentLayout())
        root._refreshTipIfTarget(root._layoutBtnRef, root._prettyLayoutName(root._currentLayout()))
    }

    readonly property bool _layoutToggleEnabled: {
        const ub = Config.options.bar.utilButtons
        if (!ub) return true
        const v = ub.showLayoutToggle
        return (v === undefined || v === null) ? true : v
    }

    Component.onCompleted: {
        const idx = Number(utilSettings.layoutIndex)
        root._layoutIndex = isNaN(idx) ? 0 : Math.max(0, Math.min(idx, root._layouts.length - 1))
        root._applyLayout(root._currentLayout())
    }

    Connections {
        target: GlobalStates
        function onOskOpenChanged() {
            if (!root._kbdBtnRef) return
            root._refreshTipIfTarget(root._kbdBtnRef, GlobalStates.oskOpen ? "Hide Keyboard" : "Show Keyboard")
        }
    }

    Connections {
        target: Appearance.m3colors
        function onDarkmodeChanged() {
            if (!root._modeBtnRef) return
            root._refreshTipIfTarget(root._modeBtnRef, Appearance.m3colors.darkmode ? "Light Mode" : "Dark Mode")
        }
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            if (!root._perfBtnRef) return
            let t = "Power"
            if (PowerProfiles) {
                switch (PowerProfiles.profile) {
                case PowerProfile.PowerSaver: t = "Power Saver"; break
                case PowerProfile.Balanced: t = "Balanced"; break
                case PowerProfile.Performance: t = "Performance"; break
                default: t = "Power"; break
                }
            }
            root._refreshTipIfTarget(root._perfBtnRef, t)
        }
    }

    implicitWidth: gridLayout.implicitWidth + (vertical ? 0 : root.outerPaddingH)
    implicitHeight: gridLayout.implicitHeight + (vertical ? root.outerPaddingV : 0)

    Behavior on implicitWidth {
        enabled: root.enableEffectsMaster && root.enableSprings
        SpringAnimation { spring: 3; damping: 0.2; epsilon: 0.5 }
    }
    Behavior on implicitHeight {
        enabled: root.enableEffectsMaster && root.enableSprings
        SpringAnimation { spring: 3; damping: 0.2; epsilon: 0.5 }
    }

    GridLayout {
        id: gridLayout
        anchors.centerIn: parent

        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1

        rowSpacing: root.gridRowSpacing
        columnSpacing: root.gridColumnSpacing

        // Screenshot (Region)
        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: active
            sourceComponent: CircleUtilButton {
                id: snipBtn
                Layout.alignment: Qt.AlignVCenter

                onHoveredChanged: {
                    if (hovered) root._setTip(snipBtn, "Screenshot (Region)")
                    else root._clearTipIf(snipBtn)
                }

                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"])

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: Appearance.colors.colOnLayer2

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // Screen Recording
        Loader {
            active: Config.options.bar.utilButtons.showScreenRecord
            visible: active
            sourceComponent: CircleUtilButton {
                id: recBtn
                Layout.alignment: Qt.AlignVCenter

                onHoveredChanged: {
                    if (hovered) root._setTip(recBtn, "Screen Recording")
                    else root._clearTipIf(recBtn)
                }

                onClicked: Quickshell.execDetached([Directories.recordScriptPath])

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "videocam"
                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: (root.enableEffectsMaster && root.enableHoverRecolor && parent.hovered)
                           ? Appearance.colors.colPrimary
                           : Appearance.colors.colOnLayer2

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        // Color Picker
        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: active
            sourceComponent: CircleUtilButton {
                id: pickerBtn
                Layout.alignment: Qt.AlignVCenter

                onHoveredChanged: {
                    if (hovered) root._setTip(pickerBtn, "Color Picker")
                    else root._clearTipIf(pickerBtn)
                }

                onClicked: Quickshell.execDetached(["hyprpicker", "-a"])

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: (root.enableEffectsMaster && root.enableHoverRecolor && parent.hovered)
                           ? "#E91E63"
                           : Appearance.colors.colOnLayer2

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        // Layout Toggle
        Loader {
            id: layoutToggleLoader
            active: root._layoutToggleEnabled
            visible: active

            Layout.preferredWidth: active ? implicitWidth : 0
            Layout.preferredHeight: active ? implicitHeight : 0
            Layout.minimumWidth: active ? implicitWidth : 0
            Layout.minimumHeight: active ? implicitHeight : 0
            Layout.maximumWidth: active ? -1 : 0
            Layout.maximumHeight: active ? -1 : 0

            sourceComponent: CircleUtilButton {
                id: layoutBtn
                Layout.alignment: Qt.AlignVCenter

                Component.onCompleted: root._layoutBtnRef = layoutBtn
                Component.onDestruction: if (root._layoutBtnRef === layoutBtn) root._layoutBtnRef = null

                onHoveredChanged: {
                    if (hovered) root._setTip(layoutBtn, root._prettyLayoutName(root._currentLayout()))
                    else root._clearTipIf(layoutBtn)
                }

                onClicked: root._advanceLayout()

                readonly property string layout: root._currentLayout()
                readonly property string layoutIcon: {
                    if (layout === "dwindle") return "bubble_chart"
                    if (layout === "master") return "account_tree"
                    if (layout === "scrolling") return "swap_horiz"
                    return "auto_awesome"
                }
                readonly property color layoutColor: {
                    if (layout === "dwindle") return Appearance.colors.colPrimary
                    if (layout === "master") return "#22C55E"
                    if (layout === "scrolling") return "#A855F7"
                    return Appearance.colors.colOnLayer2
                }

                readonly property real baseRotation: (layout === "master") ? -8 : (layout === "scrolling" ? 8 : 0)
                readonly property real hoverRotation: (layout === "master") ? -16 : (layout === "scrolling" ? 18 : 14)

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: parent.layoutIcon

                    iconSize: parent.hovered
                              ? root.hoverIconSize(parent.layout === "scrolling" ? 1.05 : (parent.layout === "master" ? 0.98 : 1.02))
                              : root.baseIconSize

                    color: (root.enableEffectsMaster && root.enableHoverRecolor && parent.hovered)
                           ? parent.layoutColor
                           : Appearance.colors.colOnLayer2

                    rotation: (root.enableEffectsMaster && root.enableHoverRotate && parent.hovered)
                              ? parent.hoverRotation
                              : parent.baseRotation

                    Behavior on rotation {
                        enabled: root.enableEffectsMaster && root.enableSprings && root.enableHoverRotate
                        SpringAnimation { spring: 3.2; damping: 0.24 }
                    }
                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 170 }
                    }
                }
            }
        }

        // Keyboard Toggle
        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: active
            sourceComponent: CircleUtilButton {
                id: kbdBtn
                Layout.alignment: Qt.AlignVCenter

                Component.onCompleted: root._kbdBtnRef = kbdBtn
                Component.onDestruction: if (root._kbdBtnRef === kbdBtn) root._kbdBtnRef = null

                function _kbdTip() { return GlobalStates.oskOpen ? "Hide Keyboard" : "Show Keyboard" }

                onHoveredChanged: {
                    if (hovered) root._setTip(kbdBtn, _kbdTip())
                    else root._clearTipIf(kbdBtn)
                }

                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: GlobalStates.oskOpen ? 1 : 0
                    text: "keyboard"

                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: GlobalStates.oskOpen ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2

                    rotation: (root.enableEffectsMaster && root.enableHoverRotate)
                              ? (GlobalStates.oskOpen ? 0 : -10)
                              : 0

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on rotation {
                        enabled: root.enableEffectsMaster && root.enableSprings && root.enableHoverRotate
                        SpringAnimation { spring: 2; damping: 0.2 }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        // Mic Toggle
        Loader {
            active: Config.options.bar.utilButtons.showMicToggle
            visible: active
            sourceComponent: CircleUtilButton {
                id: micBtn
                Layout.alignment: Qt.AlignVCenter

                readonly property bool isMuted: Pipewire && Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
                                               ? Pipewire.defaultAudioSource.audio.muted
                                               : false

                function _micTip() { return isMuted ? "Unmute Microphone" : "Mute Microphone" }

                onHoveredChanged: {
                    if (hovered) root._setTip(micBtn, _micTip())
                    else root._clearTipIf(micBtn)
                }

                onIsMutedChanged: root._refreshTipIfTarget(micBtn, _micTip())
                onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: parent.isMuted ? 1 : 0
                    text: parent.isMuted ? "mic_off" : "mic"

                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: parent.isMuted ? "#FF5252" : Appearance.colors.colOnLayer2

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        // Dark Mode Toggle
        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: active
            sourceComponent: CircleUtilButton {
                id: modeBtn
                Layout.alignment: Qt.AlignVCenter

                Component.onCompleted: root._modeBtnRef = modeBtn
                Component.onDestruction: if (root._modeBtnRef === modeBtn) root._modeBtnRef = null

                function _modeTip() { return Appearance.m3colors.darkmode ? "Light Mode" : "Dark Mode" }

                onHoveredChanged: {
                    if (hovered) root._setTip(modeBtn, _modeTip())
                    else root._clearTipIf(modeBtn)
                }

                onClicked: {
                    const mode = Appearance.m3colors.darkmode ? "light" : "dark"
                    Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", mode, "--noswitch"])
                }

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: Appearance.m3colors.darkmode ? "dark_mode" : "light_mode"

                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize
                    color: Appearance.colors.colOnLayer2

                    rotation: (root.enableEffectsMaster && root.enableHoverRotate)
                              ? (Appearance.m3colors.darkmode ? 0 : 180)
                              : 0

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on rotation {
                        enabled: root.enableEffectsMaster && root.enableHoverRotate
                        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
                    }
                }
            }
        }

        // Performance Profile Toggle
        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: active
            sourceComponent: CircleUtilButton {
                id: perfBtn
                Layout.alignment: Qt.AlignVCenter

                Component.onCompleted: root._perfBtnRef = perfBtn
                Component.onDestruction: if (root._perfBtnRef === perfBtn) root._perfBtnRef = null

                function getProfileText() {
                    if (!PowerProfiles) return "Power"
                    switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "Power Saver"
                    case PowerProfile.Balanced: return "Balanced"
                    case PowerProfile.Performance: return "Performance"
                    default: return "Power"
                    }
                }

                onHoveredChanged: {
                    if (hovered) root._setTip(perfBtn, getProfileText())
                    else root._clearTipIf(perfBtn)
                }

                onClicked: {
                    if (PowerProfiles && PowerProfiles.hasPerformanceProfile) {
                        switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break
                        case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break
                        case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break
                        }
                    } else if (PowerProfiles) {
                        PowerProfiles.profile = (PowerProfiles.profile === PowerProfile.Balanced)
                                                ? PowerProfile.PowerSaver
                                                : PowerProfile.Balanced
                    }
                }

                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: (PowerProfiles && PowerProfiles.profile === PowerProfile.Performance) ? 1 : 0

                    text: {
                        if (!PowerProfiles) return "battery_unknown"
                        switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "airwave"
                        case PowerProfile.Performance: return "local_fire_department"
                        default: return "battery_unknown"
                        }
                    }

                    iconSize: parent.hovered ? root.hoverIconSize(1.00) : root.baseIconSize

                    color: {
                        if (!PowerProfiles) return Appearance.colors.colOnLayer2
                        switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "#4CAF50"
                        case PowerProfile.Balanced: return "#2196F3"
                        case PowerProfile.Performance: return "#FF5252"
                        default: return Appearance.colors.colOnLayer2
                        }
                    }

                    Behavior on iconSize {
                        enabled: root.enableEffectsMaster && root.enableHoverGrow
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        enabled: root.enableEffectsMaster && root.enableHoverRecolor
                        ColorAnimation { duration: 300 }
                    }
                }
            }
        }
    }
}

