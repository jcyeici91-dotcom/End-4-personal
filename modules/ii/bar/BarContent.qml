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

Item { // Bar content region
    id: root

    // -----------------------------
    // Screen / monitor
    // -----------------------------
    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1

    // -----------------------------
    // Brightness (null-safe)
    // -----------------------------
    property var brightnessMonitor: null
    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    // -----------------------------
    // Background style logic
    // 0 = Glass/Transparent, 1 = Solid, 2 = Adaptive
    // Adaptive:
    //   - con ventanas en el workspace activo => SOLID
    //   - sin ventanas => GLASS
    // -----------------------------
    property bool hasActiveWindows: false
    readonly property int barBackgroundStyle: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    readonly property bool bgIsGlass: barBackgroundStyle === 0
    readonly property bool bgIsSolid: barBackgroundStyle === 1
    readonly property bool bgIsAdaptive: barBackgroundStyle === 2

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || (bgIsAdaptive && !hasActiveWindows)

    // -----------------------------
    // Glass tuning (MEJOR LEGIBILIDAD)
    // -----------------------------
    // Sube/baja estos valores si lo quieres más oscuro o más “cristal”.
    readonly property color glassTint: Qt.rgba(0.02, 0.03, 0.05, 0.40)     // fondo oscuro translúcido (mejora texto)
    readonly property color glassHighlightTop: Qt.rgba(1.0, 1.0, 1.0, 0.10) // brillo suave
    readonly property color glassHighlightMid: Qt.rgba(1.0, 1.0, 1.0, 0.03)
    readonly property color glassHighlightBot: Qt.rgba(0.9, 0.95, 1.0, 0.06)
    readonly property color glassBorderOuter: Qt.rgba(1.0, 1.0, 1.0, 0.22) // menos “blanco duro”
    readonly property color glassBorderInner: Qt.rgba(0.0, 0.0, 0.0, 0.22) // define borde y mejora contraste

    // -----------------------------
    // Responsive sizing (igual que tu lógica)
    // -----------------------------
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

    // ---------------------------------------------------------
    // Hyprland: detectar ventanas (robusto)
    // ---------------------------------------------------------
    function resolveMonitorForThisBar() {
        if (!HyprlandData) return null

        // prefer by id
        if (root.monitorIndex >= 0) {
            const byId = HyprlandData.monitors.find(m => m.id === root.monitorIndex)
            if (byId) return byId
        }

        // fallback by screen name
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

    // IMPORTANTÍSIMO: SOLO UN onScreenChanged (fusionado)
    onScreenChanged: {
        recomputeBrightnessMonitor()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }

    // ---------------------------------------------------------
    // Center split
    // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // Background shadow (un poco más fuerte en glass para legibilidad)
    // ---------------------------------------------------------
    Loader {
        active: (Config?.options?.bar?.cornerStyle === 1)
                && !!(Config?.options?.bar?.floatStyleShadow)
                && (root.showSolidBackground || root.useGlassMode)

        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
            color: root.useGlassMode ? Qt.rgba(0.0, 0.0, 0.0, 0.34) : Qt.rgba(0, 0, 0, 0.22)
            blur: root.useGlassMode ? 30 : 14
            spread: root.useGlassMode ? -2 : -2
        }
    }

    // ---------------------------------------------------------
    // Background (SOLID o GLASS)
    // ---------------------------------------------------------
    Rectangle {
        id: barBackground
        z: -10

        anchors.fill: parent
        anchors.margins: (Config?.options?.bar?.cornerStyle === 1)
            ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut))
            : 0

        radius: (Config?.options?.bar?.cornerStyle === 1) ? Appearance.rounding.windowRounding : 0
        antialiasing: true

        // CLAVE: en glass ya NO es totalmente transparente -> mejora muchísimo la legibilidad
        color: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint

        border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
        border.color: root.showSolidBackground ? Appearance.colors.colLayer0Border : Qt.rgba(1, 1, 1, 0.10)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Glass overlay (luces suaves, sin “lavar” el texto)
        Item {
            anchors.fill: parent
            visible: root.useGlassMode
            clip: true

            // Highlight gradient (suave)
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: root.glassHighlightTop }
                    GradientStop { position: 0.45; color: root.glassHighlightMid }
                    GradientStop { position: 1.0; color: root.glassHighlightBot }
                }
            }

            // Very subtle sheen
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                    GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.00) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                }
            }

            // Outer border (menos fuerte que antes)
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: root.glassBorderOuter
            }

            // Inner border (oscuro) para separar del wallpaper y mejorar lectura
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, barBackground.radius - 1)
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: root.glassBorderInner
            }
        }

        // Oculta el borde “del tema” cuando es glass
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

    // ---------------------------------------------------------
    // Left scroll (brightness)
    // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // Layout sections
    // ---------------------------------------------------------
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

    // -----------------------------
    // UN SOLO onCompleted
    // -----------------------------
    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }
}

