import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.settings 1.1
import Quickshell

Item {
    id: root

    // Orientación
    property string orientation: "horizontal"
    readonly property bool isVertical: orientation === "vertical"

    // Layouts Hyprland
    property var availableLayouts: ["dwindle", "master", "scrolling"]
    property string activeLayout: ""

    property bool applyToHyprland: false // Controlado desde HyprlandConfig
    property bool rememberSelection: true

    // Densidad y Tamaño
    property int buttonSize: 50 // Tamaño jugoso para los clics
    property int spacing: 12
    property int padding: 10
    property int labelFontSize: 16

    // Visual
    property bool showShortLetter: true
    property bool showTooltips: true

    // Colores (Estilo Glass/Mango)
    property color frameColor: Qt.rgba(0, 0, 0, 0.25)
    property color frameBorderColor: Qt.rgba(1, 1, 1, 0.08)
    property color btnBg: Qt.rgba(1, 1, 1, 0.05)
    property color btnBgHover: Qt.rgba(1, 1, 1, 0.15)
    property color btnBorder: Qt.rgba(1, 1, 1, 0.1)
    property color btnBorderActive: Qt.rgba(1, 1, 1, 0.4)

    // Tints de color para cada layout
    property color activeTintMaster: Qt.rgba(0.20, 0.85, 0.45, 0.35)
    property color activeTintScrolling: Qt.rgba(0.66, 0.33, 1.00, 0.35)
    property color activeTintDwindle: Qt.rgba(0.25, 0.60, 1.00, 0.35)

    signal layoutSelected(string layout)

    // FIX 1: Dimensiones estrictas para que NUNCA se peguen
    implicitWidth: isVertical ? (buttonSize + padding * 2) : ((buttonSize * availableLayouts.length) + (spacing * (availableLayouts.length - 1)) + padding * 2)
    implicitHeight: isVertical ? ((buttonSize * availableLayouts.length) + (spacing * (availableLayouts.length - 1)) + padding * 2) : (buttonSize + padding * 2)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    function activeTint(layout) {
        if (layout === "master") return root.activeTintMaster
        if (layout === "scrolling") return root.activeTintScrolling
        return root.activeTintDwindle
    }

    Component.onCompleted: {
        if (root.activeLayout === "" && root.availableLayouts.length > 0) {
            root.activeLayout = root.availableLayouts[0]
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 18
        color: root.frameColor
        border.width: 1
        border.color: root.frameBorderColor

        // Usamos Row/Column en lugar de GridLayout para forzar el espaciado
        Row {
            anchors.centerIn: parent
            spacing: root.spacing
            visible: !root.isVertical

            Repeater {
                model: root.availableLayouts
                delegate: layoutButtonComponent
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: root.spacing
            visible: root.isVertical

            Repeater {
                model: root.availableLayouts
                delegate: layoutButtonComponent
            }
        }
    }

    // Componente delegado
    Component {
        id: layoutButtonComponent
        Rectangle {
            id: btn
            
            // FIX 2: Capturamos la variable de forma segura para no perder el scope
            readonly property string layoutId: modelData 
            readonly property bool isActive: root.activeLayout === layoutId

            width: root.buttonSize
            height: root.buttonSize
            radius: 12

            color: isActive ? root.activeTint(layoutId) : (mouseArea.containsMouse ? root.btnBgHover : root.btnBg)
            border.width: 1
            border.color: isActive ? root.btnBorderActive : root.btnBorder

            // EFECTO: Animación de rebote jugosa
            scale: mouseArea.pressed ? 0.88 : (mouseArea.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 200 } }

            // EFECTO: Anillo de resplandor (Glow) interior al estar activo
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: isActive ? 2 : 0
                border.color: Qt.rgba(1, 1, 1, 0.5)
                opacity: isActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            // CONTENIDO VISUAL (Previsualizaciones de Hyprland)
            Item {
                anchors.fill: parent
                anchors.margins: 10
                opacity: btn.isActive ? 1.0 : 0.5

                // DWINDLE
                Item {
                    anchors.fill: parent
                    visible: btn.layoutId === "dwindle"
                    Rectangle { x: 0; y: 0; width: parent.width * 0.55; height: parent.height; color: "white"; radius: 3 }
                    Rectangle { x: parent.width * 0.65; y: 0; width: parent.width * 0.35; height: parent.height * 0.45; color: "white"; radius: 3; opacity: 0.6 }
                    Rectangle { x: parent.width * 0.65; y: parent.height * 0.55; width: parent.width * 0.35; height: parent.height * 0.45; color: "white"; radius: 3; opacity: 0.6 }
                }

                // MASTER
                Item {
                    anchors.fill: parent
                    visible: btn.layoutId === "master"
                    Rectangle { x: 0; y: 0; width: parent.width * 0.65; height: parent.height; color: "white"; radius: 3 }
                    Rectangle { x: parent.width * 0.75; y: 0; width: parent.width * 0.25; height: parent.height * 0.45; color: "white"; radius: 3; opacity: 0.6 }
                    Rectangle { x: parent.width * 0.75; y: parent.height * 0.55; width: parent.width * 0.25; height: parent.height * 0.45; color: "white"; radius: 3; opacity: 0.6 }
                }

                // SCROLLING
                Item {
                    anchors.fill: parent
                    visible: btn.layoutId === "scrolling"
                    Rectangle { x: 0; y: 0; width: parent.width * 0.20; height: parent.height; color: "white"; radius: 3; opacity: 0.4 }
                    Rectangle { x: parent.width * 0.30; y: 0; width: parent.width * 0.40; height: parent.height; color: "white"; radius: 3 }
                    Rectangle { x: parent.width * 0.80; y: 0; width: parent.width * 0.20; height: parent.height; color: "white"; radius: 3; opacity: 0.4 }
                }

                // Letra Inicial sobrepuesta (D, M, S)
                Text {
                    anchors.centerIn: parent
                    text: btn.layoutId.charAt(0).toUpperCase()
                    color: "white"
                    font.pixelSize: root.labelFontSize
                    font.bold: true
                    style: Text.Outline
                    styleColor: Qt.rgba(0,0,0,0.5)
                    visible: root.showShortLetter
                    opacity: mouseArea.containsMouse ? 1.0 : 0.0 // Solo aparece al pasar el ratón
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            ToolTip.visible: mouseArea.containsMouse
            ToolTip.text: btn.layoutId.charAt(0).toUpperCase() + btn.layoutId.slice(1)

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.activeLayout = btn.layoutId
                    root.layoutSelected(btn.layoutId)
                }
            }
        }
    }
}
