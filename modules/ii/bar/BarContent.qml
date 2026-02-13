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
    // Brightness
    // -----------------------------
    property var brightnessMonitor: null
    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    // -----------------------------
    // Background style logic
    // -----------------------------
    property bool hasActiveWindows: false
    readonly property int barBackgroundStyle: (Config?.options?.bar?.barBackgroundStyle ?? 1)

    readonly property bool bgIsGlass: barBackgroundStyle === 0
    readonly property bool bgIsSolid: barBackgroundStyle === 1
    readonly property bool bgIsAdaptive: barBackgroundStyle === 2

    readonly property bool showSolidBackground: bgIsSolid || (bgIsAdaptive && hasActiveWindows)
    readonly property bool useGlassMode: bgIsGlass || (bgIsAdaptive && !hasActiveWindows)

    // -----------------------------
    // Theme helpers (CONTRASTE MEJORADO)
    // -----------------------------
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    
    // Umbral ajustado: Si el fondo es medianamente oscuro, lo tratamos como oscuro
    function _isDark(c) { return _lin(c) < 0.65 }

    // NUEVO HELPER DE TEXTO:
    // Si el fondo es oscuro -> Blanco Puro
    // Si el fondo es claro -> Negro Puro (Máximo contraste)
    function _on(bg, a) { 
        // Ignoramos el alpha 'a' para el color base para evitar que se vea "opaco"
        return _isDark(bg) ? "#FFFFFF" : "#000000" 
    }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    // -----------------------------
    // GLASS TUNING (CRISTAL LECHOSO)
    // -----------------------------
    readonly property color glassTint: themeIsDark
        ? Qt.rgba(0.05, 0.05, 0.05, 0.50) // Dark: Más sólido para que resalte el blanco
        : Qt.rgba(0.96, 0.96, 0.98, 0.75) // Light: BLANCO LECHOSO (75% opacidad) para que el texto negro se lea

    readonly property color glassHighlightTop: themeIsDark
        ? Qt.rgba(1.0, 1.0, 1.0, 0.15)
        : Qt.rgba(1.0, 1.0, 1.0, 0.90) // Brillo casi sólido arriba

    readonly property color glassHighlightMid: themeIsDark
        ? Qt.rgba(1.0, 1.0, 1.0, 0.02)
        : Qt.rgba(1.0, 1.0, 1.0, 0.40) // Centro iluminado

    readonly property color glassHighlightBot: themeIsDark
        ? Qt.rgba(1.0, 1.0, 1.0, 0.05)
        : Qt.rgba(1.0, 1.0, 1.0, 0.60) // Reflejo inferior fuerte

    readonly property color glassBorderOuter: themeIsDark
        ? Qt.rgba(1.0, 1.0, 1.0, 0.25)
        : Qt.rgba(1.0, 1.0, 1.0, 0.80) // Borde blanco muy visible en light mode

    readonly property color glassBorderInner: themeIsDark
        ? Qt.rgba(0.0, 0.0, 0.0, 0.30)
        : Qt.rgba(0.0, 0.0, 0.0, 0.10) // Borde interno sutil

    readonly property color glassScrim: themeIsDark
        ? Qt.rgba(0, 0, 0, 0.10)
        : Qt.rgba(1, 1, 1, 0.30) // Base blanca extra

    // -----------------------------
    // TOKENS DE CONTENIDO (COLORES FUERTES)
    // -----------------------------
    readonly property color barBgColor: showSolidBackground
        ? Appearance.colors.colLayer0
        : glassTint

    // Aquí forzamos colores sólidos sin opacidad para evitar el look "opaco/lavado"
    readonly property color onBarStrong: _on(barBgColor, 1.0) 
    readonly property color onBar:       _on(barBgColor, 1.0)
    
    // Los iconos secundarios (Muted) ahora son gris oscuro (#444) en vez de gris claro (#AAA) en light mode
    readonly property color onBarMuted:  themeIsDark ? "#AAAAAA" : "#444444" 
    
    readonly property color onBarIcon:   _on(barBgColor, 1.0)

    // Chips más visibles
    readonly property color chipBg: themeIsDark
        ? Qt.rgba(1, 1, 1, 0.15)
        : Qt.rgba(0, 0, 0, 0.10) // Negro al 10% en light mode

    readonly property color chipBorder: themeIsDark
        ? Qt.rgba(1, 1, 1, 0.20)
        : Qt.rgba(0, 0, 0, 0.20)

    // -----------------------------
    // Responsive sizing
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
    // Hyprland: detectar ventanas
    // ---------------------------------------------------------
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
    // Background shadow
    // ---------------------------------------------------------
    Loader {
        active: (Config?.options?.bar?.cornerStyle === 1)
                && !!(Config?.options?.bar?.floatStyleShadow)
                && (root.showSolidBackground || root.useGlassMode)

        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
            color: root.useGlassMode
                ? (root.themeIsDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.25)) // Sombra más fuerte
                : Qt.rgba(0, 0, 0, 0.22)
            blur: root.useGlassMode ? 40 : 14
            spread: -2
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

        color: root.showSolidBackground ? Appearance.colors.colLayer0 : root.glassTint

        border.width: (Config?.options?.bar?.cornerStyle === 1) ? 1 : 0
        // Borde blanco en modo claro para separar del fondo
        border.color: root.showSolidBackground
            ? Appearance.colors.colLayer0Border
            : (root.themeIsDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.40))

        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }
        Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.InOutQuad } }

        // --- CAPAS EFECTO CRISTAL ---
        Item {
            anchors.fill: parent
            visible: root.useGlassMode
            clip: true

            // 1. Tinte base
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                color: root.glassScrim
                antialiasing: true
            }

            // 2. Gradiente
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

            // 3. Borde exterior brillante
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                color: "transparent"
                border.width: 1
                antialiasing: true
                border.color: root.glassBorderOuter
            }
        }

        // Capa sólida para transición
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
    // Left scroll
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
            // Ya no asignamos 'color' aquí para evitar el error anterior
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

    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        if (root.bgIsAdaptive) hyprRecomputeTimer.restart()
    }
}
