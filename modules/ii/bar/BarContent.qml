// =========================================================
// 0) Imports
//    - Nota: solo reordenado visualmente con comentarios.
//    - NO se cambió funcionalidad.
// =========================================================
import qs.modules.ii.bar.weather

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    // =========================================================
    // 1) Contexto / Screen / Monitor
    // =========================================================
    property var screen: root.QsWindow.window?.screen
    property int monitorIndex

    // Monitor para brillo (según pantalla actual)
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    // =========================================================
    // 2) Responsive: “shortened / hella-shortened”
    //    (esto afecta anchos/tamaños de módulos del centro)
    // =========================================================
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

    // --- 3.1 Estado base ---
property bool hasActiveWindows: false

// barBackgroundStyle:
// 1 = Visible     -> fondo siempre ON
// 2 = Adaptive    -> fondo ON solo si hay ventanas activas
// 0 = Transparent -> fondo tipo “cristal” (glass) siempre ON
property int barBackgroundStyle: Config.options.bar.barBackgroundStyle

// showBarBackground controla si “existe fondo” (sólido o glass)
property bool showBarBackground: (barBackgroundStyle === 1)
                                || (barBackgroundStyle === 2 && root.hasActiveWindows)
                                || (barBackgroundStyle === 0)

    // =========================================================
    // 4) Hyprland: detectar si hay ventanas en el workspace activo
    //    (solo se habilita cuando el estilo es Adaptive === 2)
    // =========================================================
    Connections {
        enabled: Config.options.bar.barBackgroundStyle === 2
        target: HyprlandData

        function onWindowListChanged() {
            const monitor = HyprlandData.monitors.find(m => m.id === monitorIndex);
            const wsId = monitor?.activeWorkspace?.id;

            const hasWindow = wsId
                ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating)
                : false;

            root.hasActiveWindows = hasWindow
        }
    }

    // =========================================================
    // 5) Centro: dividir el layout del centro en (left / centered / right)
    //    - fullModel = Config.options.bar.layouts.center
    //    - “centered: true” marca el elemento que va centrado real.
    // =========================================================
    property var fullModel: Config.options.bar.layouts.center

    property var leftList: []
    property var centerList: []
    property var rightList: []

    onFullModelChanged: {
        const idx = fullModel.findIndex(item => item.centered)

        if (idx === -1) {
            leftList = []
            centerList = fullModel
            rightList = []
            return
        }

        leftList = fullModel.slice(0, idx)
        centerList = [fullModel[idx]]
        rightList = fullModel.slice(idx + 1)
    }

// =========================================================
// 6) Fondo: sombra + background (SOLID/ADAPTIVE) + GLASS (TRANSPARENT=0)
//    (Pulido+) Sin línea arriba + más “vidrio” SIN blur real.
// =========================================================

// Background shadow
Loader {
    readonly property bool isGlass: Config.options.bar.barBackgroundStyle === 0

    active: (root.showBarBackground || isGlass)
            && Config.options.bar.cornerStyle === 1
            && Config.options.bar.floatStyleShadow

    anchors.fill: barBackground
    sourceComponent: StyledRectangularShadow {
        anchors.fill: undefined
        target: barBackground
    }
}

// Background
Rectangle {
    id: barBackground
    z: -10

    readonly property bool isGlass: Config.options.bar.barBackgroundStyle === 0
    readonly property bool bgEnabled: root.showBarBackground || isGlass

    // ----- Ajustes finos “vidrio” (tócalos a gusto) -----
    readonly property real glassOpacity: 0.15          // antes 0.22
    readonly property real borderLight: 0.18           // borde claro
    readonly property real borderDark: 0.10            // borde oscuro
    readonly property real vignetteStrength: 0.10      // 0.06–0.14
    readonly property real diagonalSheen: 0.05         // 0.03–0.08

    anchors {
        fill: parent
        margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
    }

    antialiasing: true

    // GLASS base: mantenemos tu enfoque estable
    opacity: isGlass ? glassOpacity : (bgEnabled ? 1.0 : 0.0)

    color: isGlass
        ? Qt.rgba(0, 0, 0, 1)
        : (bgEnabled ? Appearance.colors.colLayer0 : "transparent")

    radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0

    // Quitamos el “borde único” en glass para controlar mejor con overlays
    border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
    border.color: isGlass ? "transparent" : Appearance.colors.colLayer0Border

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // ---- Borde claro (espesor vidrio) ----
    Rectangle {
        visible: parent.isGlass && Config.options.bar.cornerStyle === 1
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, parent.borderLight)
        antialiasing: true
    }

    // ---- Borde oscuro (separación del fondo) ----
    Rectangle {
        visible: parent.isGlass && Config.options.bar.cornerStyle === 1
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, parent.borderDark)
        antialiasing: true
        opacity: 0.75
    }

    // ---- Highlight superior (SIN línea) ----
    Rectangle {
        visible: parent.isGlass
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            // sin margins: 1
        }

        height: Math.max(2, Math.round(parent.height * 0.26))
        radius: parent.radius
        color: "transparent"
        antialiasing: true

        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" } // clave anti-línea
            GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.13) }
            GradientStop { position: 1.0;  color: "transparent" }
        }
    }

    // ---- Vignette interior (profundidad, muy leve) ----
    Rectangle {
        visible: parent.isGlass
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        antialiasing: true

        gradient: Gradient {
            // borde superior/inferior/izq/der “un poco” más oscuros
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, parent.vignetteStrength) }
            GradientStop { position: 0.30; color: "transparent" }
            GradientStop { position: 0.70; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, parent.vignetteStrength) }
        }
        opacity: 0.6
    }

    // ---- Sheen diagonal (reflexión tipo vidrio) ----
    Rectangle {
        visible: parent.isGlass
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        antialiasing: true
        rotation: -12
        transformOrigin: Item.Center

        gradient: Gradient {
            GradientStop { position: 0.00; color: "transparent" }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 0.52; color: Qt.rgba(1, 1, 1, parent.diagonalSheen) }
            GradientStop { position: 0.58; color: "transparent" }
            GradientStop { position: 1.00; color: "transparent" }
        }
    }

    // ---- Tu sheen central original (lo dejamos, pero un toque más presente) ----
    Rectangle {
        visible: parent.isGlass
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        antialiasing: true

        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.05) } // antes 0.04
            GradientStop { position: 0.65; color: "transparent" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
    }
}


    // =========================================================
    // 7) MouseArea izquierda: brillo + sidebar izquierda
    // =========================================================
    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
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

    // =========================================================
    // 8) Stoppers (márgenes para respetar rounding del borde)
    // =========================================================
    Item {
        id: leftStopper
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        }
        width: 1
    }

    Item {
        id: rightStopper
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: 1
    }

    // =========================================================
    // 9) Sección izquierda: módulos Config.options.bar.layouts.left
    // =========================================================
    RowLayout { // Left section
        id: leftSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: leftStopper.right
        }
        spacing: 4

        Repeater {
            id: leftRepeater
            model: Config.options.bar.layouts.left
            delegate: BarComponent {
                list: Config.options.bar.layouts.left
                barSection: 0
            }
        }
    }

    // =========================================================
    // 10) Sección central: módulos Config.options.bar.layouts.center
    //     (se divide en izquierda-del-centro / centro / derecha-del-centro)
    // =========================================================
    Item {
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        // 10.1) Izquierda del centro
        RowLayout {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: centerCenter.left
                rightMargin: 4
            }
            Repeater {
                id: middleLeftRepeater
                model: root.leftList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    // Recalcular índice porque el modelo del repeater cambió
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        // 10.2) Centro real
        RowLayout { //center
            id: centerCenter
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            Repeater {
                model: root.centerList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        // 10.3) Derecha del centro
        RowLayout {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: centerCenter.right
                leftMargin: 4
            }
            Repeater {
                id: middleRightRepeater
                model: root.rightList
                delegate: BarComponent {
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }
    }

    // =========================================================
    // 11) Sección derecha: módulos Config.options.bar.layouts.right
    // =========================================================
    RowLayout { // Right section
        id: rightSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: rightStopper.left
            rightMargin: Math.ceil(Appearance.rounding.screenRounding / 2)
        }
        spacing: 4

        Repeater {
            id: rightRepeater
            model: Config.options.bar.layouts.right
            delegate: BarComponent {
                list: rightRepeater.model
                barSection: 2
            }
        }
    }

    // =========================================================
    // 12) MouseArea derecha: volumen + sidebar derecha
    // =========================================================
    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        z: -1
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;

        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
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
}

