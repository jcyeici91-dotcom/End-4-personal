import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings 1.0 // Para guardar las notas automáticamente

Item {
    id: root
    property int margin: 10

    // SISTEMA DE GUARDADO (Reemplaza al servicio Notepad de iNiR)
    Settings {
        id: noteSettings
        category: "SidebarNotepad"
        property string savedText: ""
    }

    onFocusChanged: (focus) => {
        if (focus) {
            Qt.callLater(() => textArea.forceActiveFocus())
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.margin
        spacing: 8

        // CABECERA (Título + Contador)
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Notepad")
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
                font.bold: true
            }

            StyledText {
                text: textArea.text.length > 0
                      ? Translation.tr("%1 chars").arg(textArea.text.length)
                      : Translation.tr("Empty")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        // ÁREA DE TEXTO
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            
            // Colores adaptados a tu tema
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 8
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: textArea
                    width: scrollView.availableWidth
                    wrapMode: TextArea.Wrap
                    
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    
                    placeholderText: Translation.tr("Write your notes here...")
                    placeholderTextColor: Appearance.colors.colSubtext
                    
                    // Cargar texto guardado
                    text: noteSettings.savedText
                    
                    selectByMouse: true
                    activeFocusOnTab: true
                    background: null

                    // Guardar automáticamente cuando escribes
                    onTextChanged: {
                        noteSettings.savedText = text
                    }

                    // Mover scroll al escribir
                    onCursorRectangleChanged: {
                        scrollView.ScrollBar.vertical.position = Math.max(0, Math.min(
                            (cursorRectangle.y - scrollView.height / 2) / contentHeight,
                            1 - scrollView.height / contentHeight
                        ))
                    }
                }
            }
        }
    }
}
