import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.settings 1.1
import Quickshell

Item {
    id: root

    // =====================================================================
    // Layout Selector "Mango-like" (PRO)
    // ---------------------------------------------------------------------
    // Esto SOLO selecciona el layout y (opcional) aplica hyprctl.
    // Los efectos de movimiento de ventanas + gaps + bordes = Hyprland.
    //
    // TOCA DESPUÉS:
    // - Ajustar Hyprland (animaciones/gaps/rounding) -> ver bloque abajo.
    // - Ajustar el tamaño del panel contenedor (donde colocas este Item)
    //   si quieres que ocupe idéntico al widget de MangoWC.
    // =====================================================================

    // -------------------------
    // Orientación
    // -------------------------
    required property string orientation            // "horizontal" | "vertical"
    readonly property bool isVertical: orientation === "vertical"

    // -------------------------
    // Layouts Hyprland
    // -------------------------
    property var availableLayouts: ["dwindle", "master", "scrolling"]
    property string activeLayout: ""

    property bool applyToHyprland: true
    property bool applyOnStartup: true
    property bool rememberSelection: true

    // -------------------------
    // Densidad / Tamaño (Mango-like: un poco más grande y aireado)
    // -------------------------
    property bool useDensityPreset: true
    property string densityPreset: "normal"         // "compact" | "normal" | "large"

    // Manual (si useDensityPreset=false)
    property int buttonSizeManual: 38
    property int spacingManual: 6
    property int paddingManual: 6
    property int labelFontSizeManual: 12

    // -------------------------
    // Visual / Mango-like
    // -------------------------
    property bool showMiniPreview: true
    property bool showShortLetter: true
    property bool showTooltips: true
    property int tooltipDelayMs: 150

    // Frame (pill container)
    property int frameRadius: 14
    property color frameColor: Qt.rgba(0, 0, 0, 0.00)
    property color frameBorderColor: Qt.rgba(1, 1, 1, 0.14)

    // Botones (glass)
    property int btnRadius: 12
    property color btnBg: Qt.rgba(1, 1, 1, 0.07)
    property color btnBgHover: Qt.rgba(1, 1, 1, 0.12)
    property color btnBorder: Qt.rgba(1, 1, 1, 0.10)
    property color btnBorderActive: Qt.rgba(1, 1, 1, 0.24)

    // Tints activos
    property color activeTintMaster: Qt.rgba(0.20, 0.85, 0.45, 0.22)
    property color activeTintScrolling: Qt.rgba(0.66, 0.33, 1.00, 0.20)
    property color activeTintDwindle: Qt.rgba(0.25, 0.60, 1.00, 0.18)

    // Preview styling
    property color previewFill: Qt.rgba(1, 1, 1, 0.50)
    property color previewFill2: Qt.rgba(1, 1, 1, 0.26)
    property color previewStroke: Qt.rgba(0, 0, 0, 0.18)

    // Animaciones del widget (no ventanas)
    property bool enableEffects: true
    property bool enableHoverGrow: true
    property real hoverScale: 1.06
    property real pressedScale: 0.97

    // Master: main más grande (Mango feel)
    property real masterMainRatio: 0.78

    // Señal externa
    signal layoutSelected(string layout)

    // -------------------------
    // Persistencia
    // -------------------------
    Settings {
        id: selSettings
        category: "layoutSelector"
        property string savedLayout: ""
    }

    // =====================================================================
    // PRESETS
    // =====================================================================
    readonly property var densityPresets: ({
        compact: { buttonSize: 34, spacing: 5, padding: 5, labelFontSize: 12 },
        normal:  { buttonSize: 38, spacing: 6, padding: 6, labelFontSize: 12 },
        large:   { buttonSize: 44, spacing: 8, padding: 7, labelFontSize: 13 }
    })

    function _preset() {
        const p = root.densityPresets?.[root.densityPreset]
        return p ? p : root.densityPresets.normal
    }

    readonly property int buttonSize: root.useDensityPreset ? root._preset().buttonSize : root.buttonSizeManual
    readonly property int spacing: root.useDensityPreset ? root._preset().spacing : root.spacingManual
    readonly property int padding: root.useDensityPreset ? root._preset().padding : root.paddingManual
    readonly property int labelFontSize: root.useDensityPreset ? root._preset().labelFontSize : root.labelFontSizeManual

    // =====================================================================
    // Tamaño calculado (no forzamos width/height)
    // =====================================================================
    readonly property int calcW: root.isVertical
        ? (root.buttonSize + root.padding * 2)
        : (root.availableLayouts.length * root.buttonSize
           + Math.max(0, (root.availableLayouts.length - 1)) * root.spacing
           + root.padding * 2)

    readonly property int calcH: root.isVertical
        ? (root.availableLayouts.length * root.buttonSize
           + Math.max(0, (root.availableLayouts.length - 1)) * root.spacing
           + root.padding * 2)
        : (root.buttonSize + root.padding * 2)

    Layout.preferredWidth: root.calcW
    Layout.preferredHeight: root.calcH
    implicitWidth: root.calcW
    implicitHeight: root.calcH

    // =====================================================================
    // Helpers
    // =====================================================================
    function displayName(layout) {
        if (layout === "dwindle") return "Dwindle"
        if (layout === "master") return "Master"
        if (layout === "scrolling") return "Scrolling"
        return String(layout)
    }

    function shortLabel(layout) {
        if (layout === "dwindle") return "D"
        if (layout === "master") return "M"
        if (layout === "scrolling") return "S"
        return "?"
    }

    function activeTint(layout) {
        if (layout === "master") return root.activeTintMaster
        if (layout === "scrolling") return root.activeTintScrolling
        return root.activeTintDwindle
    }

    // =====================================================================
    // Apply + persist
    // =====================================================================
    function applyLayout(layout) {
        if (!layout || root.availableLayouts.indexOf(layout) === -1) return

        root.activeLayout = layout
        root.layoutSelected(layout)

        if (root.rememberSelection) selSettings.savedLayout = layout

        if (root.applyToHyprland) {
            Quickshell.execDetached(["hyprctl", "keyword", "general:layout", layout])
        }
    }

    Component.onCompleted: {
        if (root.rememberSelection
            && selSettings.savedLayout
            && root.availableLayouts.indexOf(selSettings.savedLayout) !== -1) {

            root.activeLayout = selSettings.savedLayout

            if (root.applyOnStartup && root.applyToHyprland) {
                Quickshell.execDetached(["hyprctl", "keyword", "general:layout", root.activeLayout])
            }
        } else if (!root.activeLayout && root.availableLayouts.length > 0) {
            root.activeLayout = root.availableLayouts[0]
        }
    }

    // =====================================================================
    // UI
    // =====================================================================
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: root.frameRadius
        color: root.frameColor
        border.width: 1
        border.color: root.frameBorderColor

        GridLayout {
            anchors.fill: parent
            anchors.margins: root.padding

            rows: root.isVertical ? root.availableLayouts.length : 1
            columns: root.isVertical ? 1 : root.availableLayouts.length

            rowSpacing: root.isVertical ? root.spacing : 0
            columnSpacing: root.isVertical ? 0 : root.spacing

            Repeater {
                model: root.availableLayouts

                delegate: Button {
                    id: btn
                    required property string modelData
                    readonly property bool isActive: root.activeLayout === modelData

                    Layout.preferredWidth: root.buttonSize
                    Layout.preferredHeight: root.buttonSize
                    Layout.minimumWidth: root.buttonSize
                    Layout.minimumHeight: root.buttonSize

                    hoverEnabled: true
                    focusPolicy: Qt.NoFocus

                    // Micro-interacciones (solo del widget)
                    scale: {
                        if (!root.enableEffects) return 1.0
                        if (down) return root.pressedScale
                        if (root.enableHoverGrow && hovered) return root.hoverScale
                        return 1.0
                    }
                    Behavior on scale {
                        enabled: root.enableEffects
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    background: Rectangle {
                        radius: root.btnRadius

                        // Fondo con “tint” activo
                        color: btn.isActive
                            ? Qt.rgba(
                                  root.activeTint(btn.modelData).r,
                                  root.activeTint(btn.modelData).g,
                                  root.activeTint(btn.modelData).b,
                                  root.activeTint(btn.modelData).a
                              )
                            : (btn.hovered ? root.btnBgHover : root.btnBg)

                        border.width: 1
                        border.color: btn.isActive ? root.btnBorderActive : root.btnBorder

                        // Glow sutil “Mango feel” (sin shaders)
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            visible: btn.isActive
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.width: 0
                        }

                        Behavior on color {
                            enabled: root.enableEffects
                            ColorAnimation { duration: 140 }
                        }
                        Behavior on border.color {
                            enabled: root.enableEffects
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        // Preview (centrado, consistente)
                        Item {
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.78)
                            height: Math.round(parent.height * 0.56)
                            visible: root.showMiniPreview
                            opacity: btn.isActive ? 1.0 : 0.95

                            Behavior on opacity {
                                enabled: root.enableEffects
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }

                            // DWINDLE
                            Item {
                                anchors.fill: parent
                                visible: btn.modelData === "dwindle"

                                Rectangle {
                                    x: 0; y: 0
                                    width: Math.round(parent.width * 0.62)
                                    height: Math.round(parent.height * 0.64)
                                    radius: 4
                                    color: root.previewFill
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: Math.round(parent.width * 0.66); y: 0
                                    width: Math.round(parent.width * 0.34)
                                    height: Math.round(parent.height * 0.40)
                                    radius: 4
                                    color: root.previewFill2
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: Math.round(parent.width * 0.66); y: Math.round(parent.height * 0.44)
                                    width: Math.round(parent.width * 0.34)
                                    height: Math.round(parent.height * 0.56)
                                    radius: 4
                                    color: root.previewFill
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                            }

                            // MASTER (main más grande)
                            Item {
                                anchors.fill: parent
                                visible: btn.modelData === "master"

                                readonly property int gutter: 2
                                readonly property real mainRatio: Math.max(0.60, Math.min(0.86, root.masterMainRatio))
                                readonly property int mainW: Math.round(parent.width * mainRatio)
                                readonly property int stackX: mainW + gutter
                                readonly property int stackW: Math.max(0, parent.width - stackX)

                                Rectangle {
                                    x: 0; y: 0
                                    width: mainW
                                    height: parent.height
                                    radius: 4
                                    color: root.previewFill
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: stackX; y: 0
                                    width: stackW
                                    height: Math.round(parent.height * 0.48)
                                    radius: 4
                                    color: root.previewFill2
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: stackX; y: Math.round(parent.height * 0.52)
                                    width: stackW
                                    height: Math.round(parent.height * 0.48)
                                    radius: 4
                                    color: root.previewFill2
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                            }

                            // SCROLLING
                            Item {
                                anchors.fill: parent
                                visible: btn.modelData === "scrolling"

                                Rectangle {
                                    x: 0; y: 0
                                    width: Math.round(parent.width * 0.30)
                                    height: parent.height
                                    radius: 4
                                    color: root.previewFill2
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: Math.round(parent.width * 0.35); y: 0
                                    width: Math.round(parent.width * 0.30)
                                    height: parent.height
                                    radius: 4
                                    color: root.previewFill
                                    border.width: 1
                                    border.color: root.previewStroke
                                }
                                Rectangle {
                                    x: Math.round(parent.width * 0.70); y: 0
                                    width: Math.round(parent.width * 0.30)
                                    height: parent.height
                                    radius: 4
                                    color: root.previewFill2
                                    border.width: 1
                                    border.color: root.previewStroke
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: -2
                                    text: "↔"
                                    color: Qt.rgba(1, 1, 1, 0.52)
                                    font.pixelSize: Math.max(10, Math.round(root.labelFontSize * 0.9))
                                    renderType: Text.NativeRendering
                                }
                            }
                        }

                        // Letra (sutil, tipo badge)
                        Text {
                            visible: root.showShortLetter
                            anchors.centerIn: parent
                            text: root.shortLabel(btn.modelData)
                            color: Qt.rgba(1, 1, 1, btn.isActive ? 0.92 : 0.82)
                            font.pixelSize: root.labelFontSize
                            font.bold: true
                            renderType: Text.NativeRendering
                        }
                    }

                    ToolTip.visible: root.showTooltips && hovered
                    ToolTip.delay: root.tooltipDelayMs
                    ToolTip.text: root.displayName(modelData)

                    onClicked: root.applyLayout(modelData)
                }
            }
        }
    }
}

