pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var notes: []
    property string selectedId: ""
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/notes.json"

    function makeId() { return Date.now().toString(36) + Math.random().toString(36).substring(2, 7) }

    function stripHtml(html) {
        if (!html) return "";
        return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    function save() {
        notesFile.setText(JSON.stringify(root.notes, null, 2))
    }

    function selectNote(id) {
        selectedId = id
        const n = root.notes.find(n => n.id === id)
        if (n) {
            titleInput.text = n.title
            bodyArea.text = n.body
        }
    }

        function newNote() {
        const n = { id: makeId(), title: "Nueva Nota", body: "", updatedAt: new Date().toISOString() }
        root.notes = [n].concat(root.notes)
        save()
        selectNote(n.id)
    }

     function deleteSelected() {
        if (!selectedId) return
        root.notes = root.notes.filter(n => n.id !== selectedId)
        save()
        selectedId = ""
        titleInput.text = ""
        bodyArea.text = ""
    }

     FileView {
        id: notesFile
        path: root.storagePath
        watchChanges: false // No observamos cambios para evitar bucles de lectura/escritura al autoguardar
        onLoaded: {
            try {
                let parsed = JSON.parse(notesFile.text) // Usar .text como propiedad (típico en Quickshell FileView)
                if (Array.isArray(parsed)) root.notes = parsed
            } catch(e) {
                console.log("DashNotepad: No se pudo cargar notes.json o el archivo está vacío.")
            }
        }
    }

    Component.onCompleted: notesFile.reload()

       Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.selectedId) return
            
            let updatedNotes = []
            for (let i = 0; i < root.notes.length; i++) {
                let n = root.notes[i]
                if (n.id === root.selectedId) {
                    updatedNotes.push({
                        id: n.id,
                        title: titleInput.text,
                        body: bodyArea.text,
                        updatedAt: new Date().toISOString()
                    })
                } else {
                    updatedNotes.push(n)
                }
            }
            root.notes = updatedNotes
            root.save()
        }
    }

   RowLayout {
        anchors.fill: parent
        anchors.margins: 16 // Margen general para separarlo de los bordes del Dashboard
        spacing: 16

            Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 260
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 20
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                  RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    buttonRadius: 22
                    colBackground: Appearance.colors.colPrimary || "#cba6f7"
                    onClicked: root.newNote()

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol { text: "add"; iconSize: 20; color: Appearance.colors.colSurface || "#11111b" }
                        StyledText { 
                            text: "Nueva Nota"
                            font.pixelSize: 14; font.weight: Font.Bold
                            color: Appearance.colors.colSurface || "#11111b" 
                        }
                    }
                }

                   StyledText {
                    Layout.topMargin: 8
                    text: "Mis Notas"
                    font.pixelSize: 12; font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext || "#a6adc8"
                }

                    ListView {
                    id: noteList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    clip: true

                    model: root.notes.slice().sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))

                    delegate: Rectangle {
                        required property var modelData
                        width: noteList.width
                        height: 64
                        radius: 12
                        
                        color: root.selectedId === modelData.id 
                            ? (Appearance.colors.colSurfaceVariant || "#313244")
                            : (nMouse.containsMouse ? (Appearance.colors.colLayer2 || "#181825") : "transparent")
                        
                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 16
                            spacing: 4

                                StyledText {
                                Layout.fillWidth: true
                                text: modelData.title || "Sin título"
                                font.pixelSize: 14; font.weight: Font.Bold
                                color: root.selectedId === modelData.id 
                                    ? (Appearance.colors.colPrimary || "#cba6f7") 
                                    : (Appearance.colors.colOnLayer1 || "#cdd6f4")
                                elide: Text.ElideRight
                            }
                            
                               StyledText {
                                Layout.fillWidth: true
                                property string plainBody: root.stripHtml(modelData.body)
                                text: plainBody.split("\n")[0] || (modelData.body.trim() !== "" ? "Contenido..." : "Nota vacía")
                                font.pixelSize: 12
                                color: Appearance.colors.colSubtext || "#a6adc8"
                                opacity: 0.7
                                elide: Text.ElideRight
                            }
                        }

                            MouseArea {
                            id: nMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectNote(modelData.id)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 20

         ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                visible: root.selectedId === ""

                MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "edit_note"; iconSize: 64; color: Appearance.colors.colSubtext || "#a6adc8"; opacity: 0.3 }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Selecciona o crea una nota"
                    color: Appearance.colors.colSubtext || "#a6adc8"
                    font.pixelSize: 18; font.weight: Font.Medium
                    opacity: 0.6
                }
            }

                ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16
                visible: root.selectedId !== ""

                   RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                        Item {
                        Layout.fillWidth: true
                        height: 40

                        TextInput {
                            id: titleInput
                            anchors.fill: parent
                            font.family: Appearance.font.family.main
                            font.pixelSize: 28
                            font.weight: Font.Black
                            color: Appearance.colors.colOnLayer1 || "white"
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            
                            onTextChanged: saveTimer.restart()

                                StyledText {
                                anchors.fill: parent
                                text: "Título de la nota..."
                                color: Appearance.colors.colSubtext || "#a6adc8"
                                visible: !titleInput.text && !titleInput.activeFocus
                                font.pixelSize: 28; font.weight: Font.Black
                                verticalAlignment: Text.AlignVCenter
                                opacity: 0.5
                            }
                        }
                    }

                        RippleButton {
                        implicitWidth: 44; implicitHeight: 44; buttonRadius: 22
                        colBackground: Appearance.colors.colSurfaceVariant || "#313244"
                        onClicked: root.deleteSelected()
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20; color: Appearance.colors.colError || "#f38ba8" }
                        StyledToolTip { text: "Eliminar nota" }
                    }
                }

                     Rectangle {
                    Layout.fillWidth: true; height: 1
                    color: Appearance.colors.colSubtext || "#a6adc8"; opacity: 0.1
                }

                    Flickable {
                    id: bodyFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: bodyArea.implicitHeight
                    clip: true
                    
                   ScrollBar.vertical: StyledScrollBar {}

                    TextEdit {
                        id: bodyArea
                        width: bodyFlickable.width
                       height: Math.max(implicitHeight, bodyFlickable.height)
                        
                        font.family: Appearance.font.family.main
                        font.pixelSize: 16
                        color: Appearance.colors.colOnLayer1 || "#cdd6f4"
                        wrapMode: TextEdit.Wrap
                        
                        selectionColor: Appearance.colors.colPrimaryContainer || "#f5c2e7"
                        selectedTextColor: Appearance.colors.colOnPrimaryContainer || "#11111b"
                        
                        onTextChanged: saveTimer.restart()

                            onCursorRectangleChanged: {
                            const margin = 30
                            if (cursorRectangle.y < bodyFlickable.contentY) {
                                bodyFlickable.contentY = cursorRectangle.y
                            } else if (cursorRectangle.y + cursorRectangle.height + margin > bodyFlickable.contentY + bodyFlickable.height) {
                                bodyFlickable.contentY = cursorRectangle.y + cursorRectangle.height - bodyFlickable.height + margin
                            }
                        }

                          StyledText {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            text: "Empieza a escribir aquí..."
                            color: Appearance.colors.colSubtext || "#a6adc8"
                            visible: !bodyArea.text && !bodyArea.activeFocus
                            font.pixelSize: 16
                            wrapMode: Text.Wrap
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }
}
