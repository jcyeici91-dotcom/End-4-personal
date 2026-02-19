import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.bar as Bar

Item { // Bar content region
    id: root

    // FIX: esto se usaba antes pero NO existía; ahora se requiere desde VerticalBar.qml
    required property int monitorIndex

    // Recibido desde VerticalBar.qml (por si lo necesitas en widgets internos)
    property bool rightSide: false

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    // --- Estado base ---
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

    Connections {
        enabled: Config.options.bar.barBackgroundStyle === 2
        target: HyprlandData
        function onWindowListChanged() {
            const monitor = HyprlandData.monitors.find(m => m.id === root.monitorIndex);
            const wsId = monitor?.activeWorkspace?.id;

            const hasWindow = wsId
                ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating)
                : false;

            root.hasActiveWindows = hasWindow
        }
    }

    component HorizontalBarSeparator: Rectangle {
        Layout.leftMargin: Appearance.sizes.baseBarHeight / 3
        Layout.rightMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillWidth: true
        implicitHeight: 1
        color: Appearance.colors.colOutlineVariant
    }

    ////// Definning places of center modules //////
    property var fullModel: Config.options?.bar?.layouts?.center
    property int centerIdx: (fullModel || []).findIndex(item => item.centered)

    property var leftList: centerIdx === -1 ? [] : fullModel.slice(0, centerIdx)
    property var centerList: centerIdx === -1 ? fullModel : [fullModel[centerIdx]]
    property var rightList: centerIdx === -1 ? [] : fullModel.slice(centerIdx + 1)

    // =========================================================
    // Fondo: sombra + background (SOLID/ADAPTIVE) + GLASS (style 0)
    // (Pulido+) Sin línea + más “vidrio” SIN blur real.
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

        // ----- Ajustes finos “vidrio” -----
        readonly property real glassOpacity: 0.15
        readonly property real borderLight: 0.18
        readonly property real borderDark: 0.10
        readonly property real vignetteStrength: 0.10
        readonly property real diagonalSheen: 0.05

        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0
        }

        antialiasing: true

        // GLASS base
        opacity: isGlass ? glassOpacity : (bgEnabled ? 1.0 : 0.0)

        color: isGlass
            ? Qt.rgba(0, 0, 0, 1)
            : (bgEnabled ? Appearance.colors.colLayer0 : "transparent")

        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0

        // En glass controlamos borde con overlays (para más “vidrio”)
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

        // ---- Highlight “externo” (SIN línea) ----
        // Barra vertical: el highlight se pega al borde exterior.
        // rightSide=true  -> borde exterior RIGHT
        // rightSide=false -> borde exterior LEFT
        Rectangle {
            visible: parent.isGlass
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: root.rightSide ? undefined : parent.left
                right: root.rightSide ? parent.right : undefined
            }

            width: Math.max(2, Math.round(parent.width * 0.26))
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
            opacity: 0.6

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, parent.vignetteStrength) }
                GradientStop { position: 0.30; color: "transparent" }
                GradientStop { position: 0.70; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, parent.vignetteStrength) }
            }
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

        // ---- Sheen central ----
        Rectangle {
            visible: parent.isGlass
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            antialiasing: true

            gradient: Gradient {
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 0.65; color: "transparent" }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }
    }

    FocusedScrollMouseArea { // Top section | scroll to change brightness
        id: barTopSectionMouseArea
        anchors {
            top: parent.top
            bottom: middleSection.top
            left: parent.left
            right: parent.right
        }
        implicitWidth: Appearance.sizes.baseVerticalBarWidth
        height: (root.height - middleSection.height) / 2
        width: Appearance.sizes.verticalBarWidth

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }
    }

    Item {
        id: topStopper
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Math.ceil(Appearance.rounding.screenRounding / 2.5)
        }
        height: 1
    }

    ColumnLayout { // Top section
        id: topSection
        anchors {
            top: topStopper.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        Repeater {
            id: leftRepeater
            model: Config.options.bar.layouts.left
            delegate: Bar.BarComponent {
                vertical: true
                list: leftRepeater.model
                barSection: 0
            }
        }
    }

    Item {
        id: middleSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: centerCenter.top
                bottomMargin: 4
            }
            Repeater {
                id: middleLeftRepeater
                model: root.leftList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        ColumnLayout { // center
            id: centerCenter
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: root.centerList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: centerCenter.bottom
                topMargin: 4
            }
            Repeater {
                id: middleRightRepeater
                model: root.rightList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }
    }

    ColumnLayout { // Bottom section
        id: bottomSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: bottomStopper.top
        }
        spacing: 4

        Repeater {
            id: rightRepeater
            model: Config.options.bar.layouts.right
            delegate: Bar.BarComponent {
                vertical: true
                list: rightRepeater.model
                barSection: 2
            }
        }
    }

    Item {
        id: bottomStopper
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: Math.ceil(Appearance.rounding.screenRounding / 2.5)
        }
        height: 1
    }

    FocusedScrollMouseArea { // Bottom section | scroll to change volume
        id: barBottomSectionMouseArea
        z: -1
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: middleSection.bottom
        }
        implicitWidth: Appearance.sizes.baseVerticalBarWidth

        onScrollDown: Audio.decrementVolume()
        onScrollUp: Audio.incrementVolume()
        onMovedAway: GlobalStates.osdVolumeOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }
}

