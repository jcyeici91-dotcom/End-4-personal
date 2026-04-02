import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common.widgets

Rectangle {
    id: cardRoot

    // =========================================================
    // 1. CONFIGURACIÓN
    // =========================================================
    required property var theme
    
    // Datos
    property string icon: "info"
    property string val: ""
    property string label: ""
    property string detail: ""
    
    // Opcional: Color de acento manual (si no se define, usa el del tema)
    property color accentColor: theme.colAccent

    // Opcional: Acción al hacer click
    signal clicked()

    // =========================================================
    // 2. LÓGICA DE PROGRESO
    // =========================================================
    function parsePercentage(valueString) {
        if (!valueString) return 0
        // Extrae solo números y puntos
        var num = parseFloat(("" + valueString).replace(/[^0-9.]/g, ""))
        if (isNaN(num)) return 0
        // Si el valor es > 1 (ej: 45), lo dividimos por 100. Si es 0.45, se queda igual.
        return (num > 1) ? (num / 100.0) : num
    }

    readonly property bool hasProgress: 
        (val && (val.indexOf("%") !== -1 || val.indexOf("°") !== -1)) || 
        (detail && detail.indexOf("%") !== -1)

    readonly property real progressValue: 
        hasProgress ? parsePercentage((val.indexOf("%") !== -1 || val.indexOf("°") !== -1) ? val : detail) : 0

    // Color dinámico de la barra (Verde -> Naranja -> Rojo)
    readonly property color progressColor: {
        if (progressValue >= 0.85) return "#ef4444" // Rojo crítico
        if (progressValue >= 0.60) return "#f59e0b" // Naranja advertencia
        return accentColor // Color normal
    }

    // =========================================================
    // 3. DISEÑO VISUAL
    // =========================================================
    Layout.fillWidth: true
    Layout.minimumWidth: 140
    Layout.preferredHeight: (detail && detail.length > 0) ? 100 : 85

    radius: 22
    
    // Fondo reactivo al mouse
    color: mouseArea.pressed 
           ? Qt.darker(theme.colSurface, 1.05) 
           : (mouseArea.containsMouse ? theme.colSurfaceHighlight : theme.colSurface)
           
    border.width: 1
    border.color: mouseArea.containsMouse 
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) 
                  : theme.colBorderSoft

    // Animaciones suaves
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    scale: mouseArea.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cardRoot.clicked()
    }

    // =========================================================
    // 4. CONTENIDO INTERNO
    // =========================================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // --- ICONO EN BURBUJA ---
        Rectangle {
            width: 48
            height: 48
            radius: 16
            // Fondo del icono con transparencia del color de acento
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.20)

            MaterialSymbol {
                anchors.centerIn: parent
                text: cardRoot.icon
                color: accentColor
                font.pixelSize: 26
            }
        }

        // --- TEXTOS ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            // Título (Label)
            Text {
                text: cardRoot.label
                color: theme.colSubText
                font.pixelSize: 12
                font.bold: true
                font.family: theme.fontMain
                opacity: 0.8
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Valor Principal (Grande)
            Text {
                text: cardRoot.val
                color: theme.colText
                font.pixelSize: 20
                font.bold: true
                font.family: theme.fontMain
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Detalle (Subtítulo pequeño)
            Text {
                visible: cardRoot.detail !== ""
                text: cardRoot.detail
                color: theme.colSubText
                font.pixelSize: 11
                font.family: theme.fontMain
                opacity: 0.6
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // --- BARRA DE PROGRESO ---
            Item {
                visible: cardRoot.hasProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.topMargin: 4

                // Fondo de la barra
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(theme.colText.r, theme.colText.g, theme.colText.b, 0.1)
                }

                // Relleno de la barra
                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, cardRoot.progressValue))
                    radius: 2
                    color: cardRoot.progressColor
                    
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
