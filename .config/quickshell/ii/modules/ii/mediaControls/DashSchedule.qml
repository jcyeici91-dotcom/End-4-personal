pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var events: []
    property string selectedId: ""
    property string formTitle: ""
    property string formDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string formTime: "09:00"
    property string formEndTime: "10:00"
    property string formRecurrence: "once" 
    property string formDescription: ""
    property bool formFocus: false

    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    FileView {
        id: scheduleFile
        path: root.storagePath
        watchChanges: true
        onLoaded: {
            try {
                let parsed = JSON.parse(scheduleFile.text)
                if (Array.isArray(parsed)) {
                    root.events = []
                    root.events = parsed
                }
            } catch(e) {
                console.log("DashSchedule: Error al cargar schedule.json")
            }
        }
    }

    Component.onCompleted: scheduleFile.reload()

    function save() {
        scheduleFile.setText(JSON.stringify(root.events, null, 2))
    }

    function clearForm() {
        formTitle = ""; formDate = Qt.formatDate(new Date(), "yyyy-MM-dd")
        formTime = "09:00"; formEndTime = "10:00"; formRecurrence = "once"; formDescription = ""; formFocus = false
    }

    function deleteEvent(id) {
        let updatedEvents = root.events.filter(e => String(e.id) !== String(id))
        root.events = updatedEvents
        save()
        if (String(root.selectedId) === String(id)) { 
            root.selectedId = ""
            clearForm() 
        }
    }

    Timer {
        id: autoSaveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.selectedId || !root.formTitle.trim()) return
            const descVal = root.formDescription.trim() ? root.formDescription.trim() : undefined
            
            let updatedEvents = root.events.map(e => {
                if(String(e.id) === String(root.selectedId)) {
                    return {
                        id: root.selectedId, title: root.formTitle, date: root.formDate, 
                        time: root.formTime, endTime: root.formEndTime, recurrence: root.formRecurrence, 
                        description: descVal, focus: root.formFocus,
                        notified: e.notified || false
                    }
                }
                return e
            })
            root.events = updatedEvents
            save()
        }
    }

    function saveEvent() {
        if (!formTitle.trim()) return
        const descVal = formDescription.trim() ? formDescription.trim() : undefined
        let updatedEvents = root.events.slice()

        if (selectedId) {
            updatedEvents = updatedEvents.map(e => {
                if(String(e.id) === String(selectedId)) {
                    return { 
                        id: selectedId, title: formTitle, date: formDate, time: formTime, 
                        endTime: formEndTime, recurrence: formRecurrence, description: descVal, focus: formFocus,
                        notified: e.notified || false
                    }
                }
                return e
            })
        } else {
            const newEv = { 
                id: Date.now().toString(36), title: formTitle, date: formDate, time: formTime, 
                endTime: formEndTime, recurrence: formRecurrence, description: descVal, focus: formFocus,
                notified: false
            }
            updatedEvents.push(newEv)
        }
        
        root.events = updatedEvents
        save()
        selectedId = ""
        clearForm()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

           Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 20
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RippleButton {
                    Layout.fillWidth: true; implicitHeight: 44; buttonRadius: 22
                    colBackground: Appearance.colors.colPrimary || "#cba6f7"
                    onClicked: { root.selectedId = ""; root.clearForm() }
                    contentItem: RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        MaterialSymbol { text: "add"; iconSize: 20; color: Appearance.colors.colSurface || "#11111b" }
                        StyledText { text: "Nuevo Evento"; font.pixelSize: 14; font.weight: Font.Bold; color: Appearance.colors.colSurface || "#11111b" }
                    }
                }

                StyledText {
                    Layout.topMargin: 8
                    text: "Próximos Eventos"
                    font.pixelSize: 12; font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext || "#a6adc8"
                }

                ListView {
                    id: eventList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 8; clip: true
                    model: root.events.slice().sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time))

                       delegate: SwipeDelegate {
                        id: delegateItem
                        required property var modelData
                        width: eventList.width; height: 68
                        padding: 0
                        
                        background: Rectangle {
                            radius: 12
                            color: root.selectedId === modelData.id 
                                ? (Appearance.colors.colSurfaceVariant || "#313244") 
                                : (delegateItem.hovered ? (Appearance.colors.colLayer2 || "#181825") : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        swipe.right: Rectangle {
                            width: 80; height: 68; radius: 12
                            anchors.left: parent.left
                            color: Appearance.colors.colError || "#f38ba8"
                            MaterialSymbol { anchors.centerIn: parent; text: "delete_forever"; iconSize: 28; color: "#11111b" }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { 
                                    let evId = modelData.id
                                    delegateItem.swipe.close()
                                    Qt.callLater(() => root.deleteEvent(evId)) 
                                }
                            }
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 16
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    spacing: 6
                                    MaterialSymbol {
                                        visible: modelData.focus || false
                                        text: "notifications_active"; iconSize: 15
                                        color: Appearance.colors.colError || "#f38ba8"
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Sin título"
                                        font.pixelSize: 14; font.weight: Font.Bold
                                        color: root.selectedId === modelData.id ? (Appearance.colors.colPrimary || "#cba6f7") : (Appearance.colors.colOnLayer1 || "white")
                                        elide: Text.ElideRight
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        let d = modelData.date + " " + modelData.time
                                        if (modelData.endTime) d += " - " + modelData.endTime
                                        if (modelData.recurrence !== "once") d += " · " + modelData.recurrence
                                        return d
                                    }
                                    font.pixelSize: 11; color: Appearance.colors.colSubtext || "#a6adc8"; opacity: 0.8
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        onClicked: {
                            root.selectedId = ""
                            root.formTitle = modelData.title
                            root.formDate = modelData.date
                            root.formTime = modelData.time
                            root.formEndTime = modelData.endTime || ""
                            root.formRecurrence = modelData.recurrence
                            root.formDescription = modelData.description || ""
                            root.formFocus = modelData.focus || false
                            root.selectedId = modelData.id
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true; Layout.fillWidth: true
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: root.selectedId ? "Editar Evento" : "Crear Evento"
                        font.pixelSize: 22; font.weight: Font.Black
                        color: Appearance.colors.colOnLayer1 || "white"
                    }

                    RowLayout {
                        spacing: 8
                        StyledText { text: "Modo Focus"; font.pixelSize: 13; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext || "#a6adc8" }
                        
                        RippleButton {
                            implicitWidth: 44; implicitHeight: 24; buttonRadius: 12
                            colBackground: root.formFocus ? (Appearance.colors.colError || "#f38ba8") : (Appearance.colors.colSurfaceVariant || "#45475a")
                            onClicked: { root.formFocus = !root.formFocus; if (root.selectedId) autoSaveTimer.restart(); }
                            Rectangle {
                                x: root.formFocus ? parent.width - width - 3 : 3
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: 9
                                color: root.formFocus ? (Appearance.colors.colSurface || "#11111b") : (Appearance.colors.colSubtext || "#a6adc8")
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 50; radius: 12
                    color: Appearance.colors.colLayer2 || "#181825"
                    border.color: titleField.activeFocus ? (Appearance.colors.colPrimary || "#cba6f7") : "transparent"; border.width: 2
                    TextInput {
                        id: titleField; anchors.fill: parent; anchors.margins: 14
                        text: root.formTitle; font.pixelSize: 18; font.weight: Font.Bold; color: "white"
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: { root.formTitle = text; if(root.selectedId && titleField.activeFocus) autoSaveTimer.restart() }
                        StyledText {
                            anchors.fill: parent; text: "Título del evento..."; color: Appearance.colors.colSubtext; opacity: 0.5
                            visible: !parent.text && !parent.activeFocus; font.pixelSize: 18; font.weight: Font.Bold; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    
                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: Appearance.colors.colLayer2 || "#181825"
                        border.color: dateField.activeFocus ? (Appearance.colors.colPrimary || "#cba6f7") : "transparent"; border.width: 2
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            MaterialSymbol { text: "calendar_today"; iconSize: 18; color: Appearance.colors.colSubtext }
                            TextInput {
                                id: dateField; Layout.fillWidth: true; text: root.formDate; color: "white"; font.pixelSize: 14
                                inputMask: "9999-99-99"; verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: { root.formDate = text; if(root.selectedId && dateField.activeFocus) autoSaveTimer.restart() }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: Appearance.colors.colLayer2 || "#181825"
                        border.color: timeField.activeFocus ? (Appearance.colors.colPrimary || "#cba6f7") : "transparent"; border.width: 2
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            MaterialSymbol { text: "schedule"; iconSize: 18; color: Appearance.colors.colSubtext }
                            TextInput {
                                id: timeField; Layout.fillWidth: true; text: root.formTime; color: "white"; font.pixelSize: 14
                                inputMask: "99:99"; verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: { root.formTime = text; if(root.selectedId && timeField.activeFocus) autoSaveTimer.restart() }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: Appearance.colors.colLayer2 || "#181825"
                        border.color: endTimeField.activeFocus ? (Appearance.colors.colPrimary || "#cba6f7") : "transparent"; border.width: 2
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            MaterialSymbol { text: "event_busy"; iconSize: 18; color: Appearance.colors.colSubtext }
                            TextInput {
                                id: endTimeField; Layout.fillWidth: true; text: root.formEndTime; color: "white"; font.pixelSize: 14
                                inputMask: "99:99"; verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: { root.formEndTime = text; if(root.selectedId && endTimeField.activeFocus) autoSaveTimer.restart() }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    StyledText { text: "Repetir:"; font.pixelSize: 13; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext || "#a6adc8" }
                    Repeater {
                        model: ["once", "daily", "weekly", "monthly"]
                        delegate: RippleButton {
                            required property string modelData
                            implicitHeight: 32; implicitWidth: 80; buttonRadius: 16
                            colBackground: root.formRecurrence === modelData ? (Appearance.colors.colSurfaceVariant || "#313244") : "transparent"
                            onClicked: { root.formRecurrence = modelData; if (root.selectedId) autoSaveTimer.restart(); }
                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: {
                                    if(modelData === "once") return "Única"
                                    if(modelData === "daily") return "Diario"
                                    if(modelData === "weekly") return "Semanal"
                                    return "Mensual"
                                }
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: root.formRecurrence === modelData ? (Appearance.colors.colPrimary || "#cba6f7") : (Appearance.colors.colSubtext || "#a6adc8")
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                    color: Appearance.colors.colLayer2 || "#181825"
                    border.color: descArea.activeFocus ? (Appearance.colors.colPrimary || "#cba6f7") : "transparent"; border.width: 2
                    clip: true
                    
                    Flickable {
                        id: descFlickable; anchors.fill: parent; anchors.margins: 14; contentHeight: descArea.implicitHeight; clip: true
                        TextEdit {
                            id: descArea; width: descFlickable.width; height: Math.max(implicitHeight, descFlickable.height)
                            text: root.formDescription; font.pixelSize: 14; color: "white"; wrapMode: TextEdit.Wrap
                            onTextChanged: { root.formDescription = text; if(root.selectedId && descArea.activeFocus) autoSaveTimer.restart() }
                            StyledText {
                                anchors.top: parent.top; anchors.left: parent.left; text: "Añade notas o detalles aquí..."
                                color: Appearance.colors.colSubtext; opacity: 0.5; visible: !descArea.text && !descArea.activeFocus; font.pixelSize: 14
                            }
                        }
                    }
                }

                RippleButton {
                    Layout.fillWidth: true; implicitHeight: 48; buttonRadius: 24
                    colBackground: Appearance.colors.colPrimary || "#cba6f7"
                    enabled: root.formTitle.trim().length > 0; opacity: enabled ? 1 : 0.5
                    onClicked: root.saveEvent()
                    contentItem: RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        MaterialSymbol { text: "save"; iconSize: 22; color: Appearance.colors.colSurface || "#11111b" }
                        StyledText { text: root.selectedId ? "Guardar Cambios" : "Añadir a la Agenda"; font.pixelSize: 16; font.weight: Font.ExtraBold; color: Appearance.colors.colSurface || "#11111b" }
                    }
                }
            }
        }
    }

       property var activeAlarmEvent: null

      Process {
        id: sysNotify
        property string evTitle: ""
        command: ["notify-send", "-u", "critical", "-t", "0", "🔔 ALARMA FOCUS", evTitle]
    }

    Process {
        id: sysAudio
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    Timer {
        id: soundLoop
        interval: 3000
        repeat: true
        onTriggered: {
            sysAudio.running = false
            sysAudio.running = true
        }
    }

      Timer {
        id: timeChecker
        interval: 5000 
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            let yyyy = now.getFullYear();
            let mm = String(now.getMonth() + 1).padStart(2, '0');
            let dd = String(now.getDate()).padStart(2, '0');
            let hh = String(now.getHours()).padStart(2, '0');
            let mins = String(now.getMinutes()).padStart(2, '0');
            
            let currentDate = `${yyyy}-${mm}-${dd}`;
            let currentTime = `${hh}:${mins}`;

            for(let i = 0; i < root.events.length; i++) {
                let ev = root.events[i]
                
                if(ev.focus && !ev.notified && ev.date === currentDate && ev.time === currentTime) {
                    activeAlarmEvent = ev;
                    
                    try { GlobalStates.mediaControlsOpen = true } catch(e) {}
                    
                    sysNotify.evTitle = ev.title;
                    sysNotify.running = true;
                    
                    sysAudio.running = true;
                    soundLoop.start();
                    
                   alarmPopup.open();
                    break;
                }
            }
        }
    }

       Popup {
        id: alarmPopup
        anchors.centerIn: parent
        width: 360; height: 300
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose 
        
        background: Rectangle {
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 28
            border.color: Appearance.colors.colError || "#f38ba8"
            border.width: 4
            
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colError || "#f38ba8", 0.4)
                radius: 40
                samples: 75
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "notifications_active"
                iconSize: 68
                color: Appearance.colors.colError || "#f38ba8"

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: alarmPopup.opened
                    NumberAnimation { to: 1.25; duration: 350; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 350; easing.type: Easing.InOutQuad }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.activeAlarmEvent ? root.activeAlarmEvent.title : "¡ALERTA!"
                font.pixelSize: 26; font.weight: Font.Black
                color: Appearance.colors.colOnLayer1 || "white"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            RippleButton {
                Layout.fillWidth: true; implicitHeight: 60; buttonRadius: 30
                colBackground: Appearance.colors.colError || "#f38ba8"
                contentItem: StyledText { 
                    anchors.centerIn: parent
                    text: "DETENER ALARMA"
                    font.pixelSize: 18; font.weight: Font.Black
                    color: Appearance.colors.colSurface || "#11111b"
                }
                onClicked: {
                    soundLoop.stop();
                    sysAudio.running = false;
                    alarmPopup.close();
                    
                    if(root.activeAlarmEvent) {
                        let updatedEvents = root.events.map(e => {
                            if(String(e.id) === String(root.activeAlarmEvent.id)) e.notified = true
                            return e
                        })
                        root.events = updatedEvents
                        root.save() 
                    }
                }
            }
        }
    }
}
