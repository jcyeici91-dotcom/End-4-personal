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

import qs.modules.ii.ui 1.0

import "." as Bar

Item {
    id: root

    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1

    property var brightnessMonitor: null
    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    property bool hasActiveWindows: false

    // ----------------------------------------------------------
    // Style resolution
    // ----------------------------------------------------------
    readonly property bool followGlobalBarStyle: (Config?.options?.bar?.followGlobalBarStyle ?? false)

    readonly property int barBackgroundStyleFromConfig: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    function _styleFromConfig(v) {
        switch (v) {
        case 0: return "glass"
        case 1: return "solid"
        case 2: return "adaptive"
        case 3: return "crystal"
        default: return "solid"
        }
    }

    function _styleFromUIState() {
        const s = UIState.surfaceStyle
        return (s === "solid" || s === "glass" || s === "crystal" || s === "adaptive") ? s : ""
    }

    readonly property string resolvedStyle: {
        if (followGlobalBarStyle) {
            const s = _styleFromUIState()
            if (s !== "") return s
        }
        return _styleFromConfig(barBackgroundStyleFromConfig)
    }

    readonly property bool bgIsGlass: resolvedStyle === "glass"
    readonly property bool bgIsSolid: resolvedStyle === "solid"
    readonly property bool bgIsAdaptive: resolvedStyle === "adaptive"
    readonly property bool bgIsCrystal: resolvedStyle === "crystal"

    // Adaptive behavior:
    // - With windows => solid
    // - No windows => glass
    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)

    // Overlay for glass, crystal and adaptive(no-windows)
    readonly property bool useOverlayBg: bgIsGlass || bgIsCrystal || (bgIsAdaptive && !hasActiveWindows)

    readonly property bool useHybridGroups: ((Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid")
    readonly property int cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0) // 0 Hug | 1 Float | 2 Rect
    readonly property bool isBottom: (Config?.options?.bar?.bottom ?? false)

    readonly property bool allowFullBarBackgroundInHybrid: (useHybridGroups && showSolidBackground)
    readonly property bool shouldDrawBackground: (!useHybridGroups) || allowFullBarBackgroundInHybrid

    // ----------------------------------------------------------
    // Hybrid resize
    // ----------------------------------------------------------
    readonly property int hybridResizeMs: 85

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
        id: bgLoader
        z: -10
        anchors.fill: parent
        sourceComponent: root.shouldDrawBackground
            ? (root.useOverlayBg ? overlayBgComponent : classicBgComponent)
            : null
    }

    Component {
        id: classicBgComponent

        Item {
            anchors.fill: parent

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
        }
    }

    Component {
        id: overlayBgComponent

        Item {
            anchors.fill: parent

            Item {
                id: overlayBg
                anchors.fill: parent
            }

            Bar.BarBgShadowOverlay {
                targetItem: overlayBg
                cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)
                visibleWhen: (Config?.options?.bar?.cornerStyle === 1)
                    && !!(Config?.options?.bar?.floatStyleShadow)
                    && (root.showSolidBackground || root.useGlassMode)
            }

            Loader {
                id: overlayBase
                anchors.fill: overlayBg
                active: true
                sourceComponent: root.bgIsCrystal ? crystalBaseComponent : normalBaseComponent
            }

            Component {
                id: normalBaseComponent
                Bar.BarBgOverlay {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint
                }
            }

            Component {
                id: crystalBaseComponent
                Bar.BarBgOverlayGlassBlur {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.glassTint
                }
            }

            Loader {
                id: crystalTop
                anchors.fill: overlayBg
                active: root.bgIsCrystal
                visible: root.bgIsCrystal
                sourceComponent: crystalTopComponent
            }

            Component {
                id: crystalTopComponent
                Bar.BarBgCrystalOverlay {
                    anchors.fill: parent

                    position: (Config?.options?.bar?.bottom ?? false) ? "bottom" : "top"
                    cornerStyle: (Config?.options?.bar?.cornerStyle ?? 0)

                    useGlassMode: root.useGlassMode
                    showSolidBackground: root.showSolidBackground
                    backgroundColor: root.glassTint
                }
            }
        }
    }

    // ==========================================================
    // Bridges (Hybrid + Hug/Float)
    // ==========================================================
    readonly property bool bridgeEnabled: (useHybridGroups
        && (cornerStyle === 0 || cornerStyle === 1)
        && !allowFullBarBackgroundInHybrid)

    readonly property int seamOverlapPx: 3

    readonly property int bridgeOuterMargin: (cornerStyle === 1)
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    readonly property int bridgeExtraBleed: (cornerStyle === 0) ? seamOverlapPx : 0

    // =================================================================================
    // FIX MAESTRO PARA EL GROSOR DE LA LÍNEA:
    // He aumentado el multiplicador para que la línea quede "un pelín más grande" (de 4 a 8px aprox),
    // haciéndola más visible sin llegar a ser gruesa o tosca.
    // =================================================================================
    readonly property int bridgeBandPx: bridgeEnabled
        ? Math.max(4, Math.min(8, Math.round((Appearance.rounding.normal ?? 12) * 0.40)))
        : 0

    // =================================================================================
    // FIX DE COLOR DE LA LÍNEA:
    // Sigue siendo Cristal en modo Cristal, y tu color de tema en los otros modos.
    // =================================================================================
    readonly property color bridgeColor: root.bgIsCrystal 
        ? root.glassTint 
        : Appearance.m3colors.m3surfaceContainerLow

    Item {
        id: topBridge
        z: -9
        visible: (!root.isBottom) && root.bridgeEnabled
        clip: true

        layer.enabled: true
        layer.smooth: false

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: root.bridgeOuterMargin - root.bridgeExtraBleed
            rightMargin: root.bridgeOuterMargin - root.bridgeExtraBleed
        }

        height: Math.round(root.bridgeBandPx + root.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(root.bridgeBandPx + root.seamOverlapPx)
            antialiasing: false
            color: root.bridgeColor
            radius: 0
        }
    }

    Item {
        id: bottomBridge
        z: -9
        visible: (root.isBottom) && root.bridgeEnabled
        clip: true

        layer.enabled: true
        layer.smooth: false

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: root.bridgeOuterMargin - root.bridgeExtraBleed
            rightMargin: root.bridgeOuterMargin - root.bridgeExtraBleed
        }

        height: Math.round(root.bridgeBandPx + root.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(root.bridgeBandPx + root.seamOverlapPx)
            antialiasing: false
            color: root.bridgeColor
            radius: 0
        }
    }

    // =========================================================
    // Mouse areas / content
    // =========================================================
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
        anchors.leftMargin: root.useHybridGroups ? 0 : Math.ceil(Appearance.rounding.screenRounding / 2)
        width: 1
    }

    Loader {
        id: leftContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftStopper.right
        active: true
        sourceComponent: root.useHybridGroups ? leftHybridComponent : leftClassicComponent
    }

    Component {
        id: leftClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.left
                delegate: BarComponent { list: Config.options.bar.layouts.left; barSection: 0 }
            }
        }
    }

    Component {
        id: leftHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenLeft: true

            width: implicitWidth
            Behavior on width {
                NumberAnimation {
                    duration: root.hybridResizeMs
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: Config.options.bar.layouts.left
                delegate: BarComponent { list: Config.options.bar.layouts.left; barSection: 0 }
            }
        }
    }

    Item {
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: root.useHybridGroups ? middleHybridComponent : middleClassicComponent
        }

        Component {
            id: middleClassicComponent
            Item {
                anchors.fill: parent

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
        }

        Component {
            id: middleHybridComponent
            Item {
                anchors.fill: parent

                Loader {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: centerCenterGroup.left
                    anchors.rightMargin: 4
                    active: (root.leftList && root.leftList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: 4
                        isContainer: true
                        autoHide: true
                        padding: 6
                        edgeInset: 2

                        width: implicitWidth
                        Behavior on width {
                            NumberAnimation {
                                duration: root.hybridResizeMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            model: root.leftList
                            delegate: BarComponent {
                                list: Config.options.bar.layouts.center
                                barSection: 1
                                originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                            }
                        }
                    }
                }

                Bar.BarGroup {
                    id: centerCenterGroup
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    vertical: false
                    spacing: 4
                    isContainer: true
                    autoHide: true
                    padding: 6
                    edgeInset: 2

                    width: implicitWidth
                    Behavior on width {
                        NumberAnimation {
                            duration: root.hybridResizeMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: root.centerList
                        delegate: BarComponent {
                            list: Config.options.bar.layouts.center
                            barSection: 1
                            originalIndex: Config.options.bar.layouts.center.findIndex(e => e && modelData && e.id === modelData.id)
                        }
                    }
                }

                Loader {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: centerCenterGroup.right
                    anchors.leftMargin: 4
                    active: (root.rightList && root.rightList.length > 0)
                    visible: active
                    sourceComponent: Bar.BarGroup {
                        vertical: false
                        spacing: 4
                        isContainer: true
                        autoHide: true
                        padding: 6
                        edgeInset: 2

                        width: implicitWidth
                        Behavior on width {
                            NumberAnimation {
                                duration: root.hybridResizeMs
                                easing.type: Easing.OutCubic
                            }
                        }

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

    Loader {
        id: rightContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: rightStopper.left
        anchors.rightMargin: root.useHybridGroups ? 0 : Math.ceil(Appearance.rounding.screenRounding / 2)
        active: true
        sourceComponent: root.useHybridGroups ? rightHybridComponent : rightClassicComponent
    }

    Component {
        id: rightClassicComponent
        RowLayout {
            spacing: 4
            Repeater {
                model: Config.options.bar.layouts.right
                delegate: BarComponent { list: Config.options.bar.layouts.right; barSection: 2 }
            }
        }
    }

    Component {
        id: rightHybridComponent
        Bar.BarGroup {
            vertical: false
            spacing: 4
            isContainer: true
            autoHide: false
            padding: 6
            edgeInset: 2
            attachScreenRight: true

            width: implicitWidth
            Behavior on width {
                NumberAnimation {
                    duration: root.hybridResizeMs
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: Config.options.bar.layouts.right
                delegate: BarComponent { list: Config.options.bar.layouts.right; barSection: 2 }
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
