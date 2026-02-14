import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Io

Item {
    id: root

    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1

    property var brightnessMonitor: null
    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    property bool hasActiveWindows: false
    readonly property int barBackgroundStyle: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    readonly property bool bgIsGlass: barBackgroundStyle === 0
    readonly property bool bgIsSolid: barBackgroundStyle === 1
    readonly property bool bgIsAdaptive: barBackgroundStyle === 2

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || (bgIsAdaptive && !hasActiveWindows)

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    function _on(bg) { return _isDark(bg) ? "#FFFFFF" : "#000000" }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    readonly property color glassTint: themeIsDark
        ? Qt.rgba(0.02, 0.02, 0.03, 0.42)
        : Qt.rgba(0.98, 0.98, 1.00, 0.58)

    readonly property color glassRim: themeIsDark
        ? Qt.rgba(1, 1, 1, 0.18)
        : Qt.rgba(1, 1, 1, 0.55)

    readonly property color glassRimInner: themeIsDark
        ? Qt.rgba(0, 0, 0, 0.26)
        : Qt.rgba(0, 0, 0, 0.12)

    readonly property color barBgColor: showSolidBackground ? Appearance.colors.colLayer0 : glassTint

    readonly property color onBarStrong: _on(barBgColor)
    readonly property color onBar: _on(barBgColor)
    readonly property color onBarMuted: themeIsDark ? "#AAAAAA" : "#444444"
    readonly property color onBarIcon: _on(barBgColor)

    readonly property color chipBg: themeIsDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color chipBorder: themeIsDark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.20)

    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width)
        ? 2
        : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width)
            ? 1
            : 0

    readonly property int centerSideModuleWidth: (useShortenedForm == 2)
        ? Appearance.sizes.barCenterSideModuleWidthHellaShortened
        : (useShortenedForm == 1)
            ? Appearance.sizes.barCenterSideModuleWidthShortened
            : Appearance.sizes.barCenterSideModuleWidth

    function resolveMonitorForThisBar() {
        if (!HyprlandData) return null
        if (root.monitorIndex >= 0) {
            const byId = HyprlandData.monitors.find(m => m.id === root.monitorIndex)
            if (byId) return byId
        }
        const scrName = root.screen?.name
        if (scrName) {
            const byName = HyprlandData.monitors.find(m => m.name === scrName)
            if (byName) return byName
        }
        return null
    }

    function recomputeHasWindows() {
        if (!HyprlandData) {
            root.hasActiveWindows = false
            return
        }
        const monitor = resolveMonitorForThisBar()
        const wsId = monitor?.activeWorkspace?.id ?? null
        if (!wsId) {
            root.hasActiveWindows = false
            return
        }
        root.hasActiveWindows = HyprlandData.windowList.some(w =>
            (w.workspace?.id === wsId) && !w.floating
        )
    }

    Timer {
        id: hyprRecomputeTimer
        interval: 60
        repeat: false
        onTriggered: root.recomputeHasWindows()
    }

    Connections {
        enabled: root.bgIsAdaptive
        target: HyprlandData
        function schedule() { hyprRecomputeTimer.restart() }
        function onWindowListChanged() { schedule() }
        function onMonitorsChanged() { schedule() }
    }

    onMonitorIndexChanged: if (root.bgIsAdaptive) hyprRecomputeTimer.restart()

    onScreenChanged: {
        recomputeBrightnessMonitor()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }

    property var fullModel: (Config?.options?.bar?.layouts?.center ?? [])
    property var leftList: []
    property var centerList: []
    property var rightList: []

    function recomputeCenterSplit() {
        const model = root.fullModel
        if (!model || model.length === undefined) {
            root.leftList = []
            root.centerList = []
            root.rightList = []
            return
        }
        const idx = model.findIndex(item => item && item.centered === true)
        if (idx === -1) {
            root.leftList = []
            root.centerList = model
            root.rightList = []
            return
        }
        root.leftList = model.slice(0, idx)
        root.centerList = [model[idx]]
        root.rightList = model.slice(idx + 1)
    }
    onFullModelChanged: recomputeCenterSplit()

    Loader {
        active: (Config?.options?.bar?.cornerStyle === 1)
                && !!(Config?.options?.bar?.floatStyleShadow)
                && (root.showSolidBackground || root.useGlassMode)

        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
            color: root.useGlassMode
                ? (root.themeIsDark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.22))
                : Qt.rgba(0, 0, 0, 0.20)
            blur: root.useGlassMode ? 46 : 14
            spread: -2
        }
    }

    Rectangle {
        id: barBackground
        z: -10

        anchors.fill: parent
        anchors.margins: (Config?.options?.bar?.cornerStyle === 1)
            ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
            : 0

        radius: (Config?.options?.bar?.cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
        antialiasing: true

        color: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint

        border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
        border.color: root.showSolidBackground
            ? Appearance.colors.colLayer0Border
            : (root.themeIsDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.28))

        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }
        Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }

        Item {
            anchors.fill: parent
            visible: root.useGlassMode
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                antialiasing: true
                color: root.themeIsDark ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.10)
            }

            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.65) }
                    GradientStop { position: 0.40; color: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.22) }
                    GradientStop { position: 1.0; color: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.40) }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.themeIsDark ? 0.06 : 0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                }
                transform: Rotation { origin.x: barBackground.width / 2; origin.y: barBackground.height / 2; angle: -18 }
                opacity: 0.85
            }

            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: root.glassRim
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, barBackground.radius - 1)
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: root.glassRimInner
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: barBackground.radius
            color: "transparent"
            border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
            border.color: Appearance.colors.colLayer0Border
            opacity: root.showSolidBackground ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }
    }

    FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: middleSection.left
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: leftStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        width: 1
    }

    RowLayout {
        id: leftSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftStopper.right
        spacing: 4

        Repeater {
            model: Config.options.bar.layouts.left
            delegate: BarComponent {
                list: Config.options.bar.layouts.left
                barSection: 0
            }
        }
    }

    Item {
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        RowLayout {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: centerCenter.left
            anchors.rightMargin: 4

            Repeater {
                model: root.leftList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                }
            }
        }

        RowLayout {
            id: centerCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: root.centerList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                }
            }
        }

        RowLayout {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: centerCenter.right
            anchors.leftMargin: 4

            Repeater {
                model: root.rightList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                }
            }
        }
    }

    Item {
        id: rightStopper
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
    }

    RowLayout {
        id: rightSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: rightStopper.left
        anchors.rightMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        spacing: 4

        Repeater {
            id: rightRepeater
            model: Config.options.bar.layouts.right
            delegate: BarComponent {
                list: Config.options.bar.layouts.right
                barSection: 2
            }
        }
    }

    FocusedScrollMouseArea {
        id: barRightSideMouseArea
        z: -1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: middleSection.right
        anchors.right: parent.right
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }
}

