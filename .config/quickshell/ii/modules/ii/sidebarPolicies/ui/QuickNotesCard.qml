import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Qt.labs.settings 1.1

import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: card

    // --- Props y Tema ---
    required property var theme
    property color accent: Appearance.m3colors?.m3primary ?? "#40c4ff"
    property color bgInput: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.06)

    radius: 24
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    clip: true

    // --- Reloj interno ---
    property int _nowMs: Date.now()
    Timer {
        interval: 1000
        running: card.visible
        repeat: true
        onTriggered: card._nowMs = Date.now()
    }

    // --- Señales visuales de alarma ---
    property int lastAlarmMs: 0
    property int lastFiredIndex: -1
    property bool alarmFlash: false

    Timer {
        id: alarmFlashTimer
        interval: 1600
        repeat: false
        onTriggered: card.alarmFlash = false
    }

    function _triggerAlarmSignal(idx) {
        lastFiredIndex = idx
        lastAlarmMs = Date.now()
        alarmFlash = true
        alarmFlashTimer.restart()
    }

    // --- Funciones ---
    function _pad2(n) { return (n < 10 ? "0" : "") + n }

    function _isoDate(d) {
        return d.getFullYear() + "-" + _pad2(d.getMonth() + 1) + "-" + _pad2(d.getDate())
    }

    function _fmtNiceDate(ms) {
        if (!ms || ms <= 0) return "Sin fecha"
        var d = new Date(ms)

        var today = new Date(); today.setHours(0,0,0,0)
        var itemDate = new Date(ms); itemDate.setHours(0,0,0,0)

        var diff = (itemDate - today) / (1000 * 60 * 60 * 24)
        var timeStr = _pad2(d.getHours()) + ":" + _pad2(d.getMinutes())

        if (diff === 0) return "Hoy, " + timeStr
        if (diff === 1) return "Mañana, " + timeStr
        if (diff === -1) return "Ayer, " + timeStr
        return _pad2(d.getDate()) + "/" + _pad2(d.getMonth()+1) + " " + timeStr
    }

    function _parseIsoDate(s) {
        // estricta: YYYY-MM-DD
        if (!s) return null
        s = ("" + s).trim()
        if (s.length !== 10) return null
        if (s[4] !== "-" || s[7] !== "-") return null

        var y = parseInt(s.slice(0, 4))
        var m = parseInt(s.slice(5, 7))
        var d = parseInt(s.slice(8, 10))
        if (isNaN(y) || isNaN(m) || isNaN(d)) return null
        if (m < 1 || m > 12) return null
        if (d < 1 || d > 31) return null

        var dt = new Date(y, m - 1, d)
        if (dt.getFullYear() !== y || (dt.getMonth() + 1) !== m || dt.getDate() !== d) return null
        return dt
    }

    function _dueMsFromInputs() {
        var dt = _parseIsoDate(inputDateText)
        if (!dt) return 0
        dt.setHours(inputHour, inputMinute, 0, 0)
        return dt.getTime()
    }

    // --- Persistencia ---
    function _serialize() {
        var arr = []
        for (var i = 0; i < tasks.count; i++) arr.push(tasks.get(i))
        store.payload = JSON.stringify(arr)
    }

    function _load() {
        tasks.clear()
        try {
            var arr = JSON.parse(store.payload)
            for (var i = 0; i < arr.length; i++) tasks.append(arr[i])
        } catch (e) {}
    }

    function _addTask() {
        var t = titleField.text.trim()
        if (t === "") return

        var due = _dueMsFromInputs()
        // si la fecha es inválida, no agregues; así evitas tareas con due=0 sin querer
        if (due <= 0) {
            dtPopup.openForFix()
            return
        }

        tasks.insert(0, {
            title: t,
            notes: notesField.text.trim(),
            dueMs: due,
            alarm: alarmActive,
            done: false,
            fired: false
        })

        titleField.text = ""
        notesField.text = ""
        _serialize()
    }

    function _snoozeIndex(idx, minutes) {
        if (idx < 0 || idx >= tasks.count) return
        var ms = Math.max(Date.now(), tasks.get(idx).dueMs) + minutes * 60000
        tasks.setProperty(idx, "dueMs", ms)
        tasks.setProperty(idx, "fired", false)
        tasks.setProperty(idx, "done", false)
        _serialize()
    }

    // --- Inputs (ahora editables) ---
    property string inputDateText: _isoDate(new Date())
    property int inputHour: new Date().getHours()
    property int inputMinute: new Date().getMinutes()
    property bool alarmActive: true

    Settings { id: store; category: "SidebarPolicies.QuickNotes"; property string payload: "" }
    ListModel { id: tasks }

    Component.onCompleted: {
        inputDateText = _isoDate(new Date())
        _load()
    }

    // --- Alarma Poll (más rápido para que se note el momento) ---
    Timer {
        interval: 1000
        running: card.visible
        repeat: true
        onTriggered: {
            var now = card._nowMs
            for (var i = 0; i < tasks.count; i++) {
                var it = tasks.get(i)
                if (it.done || !it.alarm || it.fired || it.dueMs <= 0) continue
                if (now >= it.dueMs) {
                    tasks.setProperty(i, "fired", true)
                    alarmPopup.taskIndex = i
                    alarmPopup.open()
                    card._triggerAlarmSignal(i)
                    _serialize()
                    break
                }
            }
        }
    }

    // =========================
    // Popup editor Fecha/Hora
    // =========================
    Popup {
        id: dtPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        width: Math.min(360, parent ? parent.width - 40 : 360)
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        function openForFix() {
            // abre el popup y marca visualmente que hubo error
            open()
            dateEdit.forceActiveFocus()
            dateEdit.selectAll()
        }

        background: Rectangle {
            radius: 18
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 24
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "Fecha y hora"
                color: Appearance.colors.colOnLayer1
                font.pixelSize: 14
                font.bold: true
                font.family: card.theme.fontMain
            }

            TextField {
                id: dateEdit
                Layout.fillWidth: true
                text: card.inputDateText
                placeholderText: "YYYY-MM-DD"
                onTextChanged: card.inputDateText = text

                // hint visual si inválida
                property bool ok: card._parseIsoDate(text) !== null
                color: Appearance.colors.colOnLayer0
                background: Rectangle {
                    radius: 10
                    color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.06)
                    border.width: 1
                    border.color: dateEdit.ok
                        ? Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.12)
                        : Qt.rgba(1, 0.35, 0.35, 0.75)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Hora"
                        color: Appearance.colors.colOnLayer0
                        opacity: 0.7
                        font.pixelSize: 11
                        font.family: card.theme.fontMain
                    }

                    SpinBox {
                        id: hourEdit
                        from: 0
                        to: 23
                        editable: true
                        value: card.inputHour
                        onValueChanged: card.inputHour = value
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Minuto"
                        color: Appearance.colors.colOnLayer0
                        opacity: 0.7
                        font.pixelSize: 11
                        font.family: card.theme.fontMain
                    }

                    SpinBox {
                        id: minEdit
                        from: 0
                        to: 59
                        editable: true
                        value: card.inputMinute
                        onValueChanged: card.inputMinute = value
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Ahora"
                    onClicked: {
                        var d = new Date()
                        card.inputDateText = card._isoDate(d)
                        card.inputHour = d.getHours()
                        card.inputMinute = d.getMinutes()
                        dateEdit.text = card.inputDateText
                        hourEdit.value = card.inputHour
                        minEdit.value = card.inputMinute
                    }
                }

                Button {
                    text: "Hoy"
                    onClicked: {
                        var d = new Date()
                        card.inputDateText = card._isoDate(d)
                        dateEdit.text = card.inputDateText
                    }
                }

                Button {
                    text: "Mañana"
                    onClicked: {
                        var d = new Date()
                        d.setDate(d.getDate() + 1)
                        card.inputDateText = card._isoDate(d)
                        dateEdit.text = card.inputDateText
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "OK"
                    enabled: card._parseIsoDate(card.inputDateText) !== null
                    highlighted: true
                    onClicked: dtPopup.close()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Formato: YYYY-MM-DD (ejemplo: 2026-02-13)"
                color: Appearance.colors.colOnLayer0
                opacity: 0.55
                font.pixelSize: 10
                font.family: card.theme.fontMain
            }
        }
    }

    // =========================
    //  UI PRINCIPAL
    // =========================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Header + indicador visual cuando suena una alarma
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headRow.implicitHeight + 14
            radius: 16
            color: card.alarmFlash
                   ? Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.16)
                   : "transparent"
            border.width: card.alarmFlash ? 1 : 0
            border.color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.35)

            Behavior on color { ColorAnimation { duration: 180 } }

            RowLayout {
                id: headRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 12

                Rectangle {
                    width: 42; height: 42; radius: 14
                    color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.15)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "task_alt"
                        font.pixelSize: 24
                        color: card.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "QuickTasks"
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: 16
                        font.bold: true
                        font.family: card.theme.fontMain
                    }

                    Text {
                        text: "Organiza tu día"
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: 12
                        opacity: 0.6
                        font.family: card.theme.fontMain
                    }
                }

                Rectangle {
                    height: 28
                    radius: 10
                    color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.10)
                    implicitWidth: badgeText.implicitWidth + 14

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: tasks.count + " tareas"
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.75
                        font.pixelSize: 11
                        font.bold: true
                        font.family: card.theme.fontMain
                    }
                }
            }
        }

        // Área de Entrada
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: inputCol.implicitHeight + 24
            color: Appearance.colors.colLayer0
            radius: 16
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: inputCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // Título
                TextField {
                    id: titleField
                    Layout.fillWidth: true
                    placeholderText: "Nueva tarea..."
                    background: Rectangle { color: "transparent" }
                    font.pixelSize: 14
                    color: Appearance.colors.colOnLayer0
                    leftPadding: 0
                    bottomPadding: 8

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: parent.activeFocus ? card.accent : Qt.rgba(0.5,0.5,0.5,0.2)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    onAccepted: card._addTask()
                }

                // Notas
                TextField {
                    id: notesField
                    Layout.fillWidth: true
                    visible: titleField.text.length > 0 || activeFocus
                    placeholderText: "Detalles adicionales..."
                    background: Rectangle { color: "transparent" }
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer0
                    opacity: 0.85
                    leftPadding: 0
                }

                // Selector Fecha y Hora (chips) -> ahora abre editor para poner lo que quieras
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Fecha chip (editable via popup)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: card.bgInput

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            MaterialSymbol {
                                text: "calendar_month"
                                font.pixelSize: 16
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.7
                            }

                            Text {
                                id: dateDisplay
                                Layout.fillWidth: true
                                text: card.inputDateText
                                color: Appearance.colors.colOnLayer0
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            MaterialSymbol {
                                text: "edit"
                                font.pixelSize: 14
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.5
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dtPopup.open()
                        }
                    }

                    // Hora chip (editable via popup)
                    Rectangle {
                        width: 110
                        height: 32
                        radius: 8
                        color: card.bgInput

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "schedule"
                                font.pixelSize: 16
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.7
                            }

                            Text {
                                text: card._pad2(card.inputHour) + ":" + card._pad2(card.inputMinute)
                                font.bold: true
                                color: Appearance.colors.colOnLayer0
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dtPopup.open()
                        }
                    }

                    // Botón Add
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: titleField.text.length > 0 ? card.accent : card.bgInput

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_upward"
                            font.pixelSize: 18
                            color: titleField.text.length > 0 ? "white" : Appearance.colors.colOnLayer0
                            opacity: titleField.text.length > 0 ? 1 : 0.3
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: titleField.text.length > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: card._addTask()
                        }

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Toggles rápidos + alarma
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Button {
                        text: "Hoy"
                        onClicked: {
                            var d = new Date()
                            card.inputDateText = card._isoDate(d)
                        }
                    }

                    Button {
                        text: "Mañana"
                        onClicked: {
                            var d = new Date()
                            d.setDate(d.getDate() + 1)
                            card.inputDateText = card._isoDate(d)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 26
                        radius: 13
                        color: alarmActive ? Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.2) : "transparent"
                        border.width: 1
                        border.color: card.bgInput
                        implicitWidth: 26

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "alarm"
                            font.pixelSize: 14
                            color: alarmActive ? card.accent : Appearance.colors.colOnLayer0
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: alarmActive = !alarmActive
                        }
                    }

                    Button {
                        text: "Editar fecha/hora"
                        onClicked: dtPopup.open()
                    }
                }

                // Hint si fecha inválida
                Text {
                    Layout.fillWidth: true
                    visible: card._parseIsoDate(card.inputDateText) === null
                    text: "Fecha inválida. Usa formato YYYY-MM-DD."
                    color: Qt.rgba(1, 0.35, 0.35, 0.95)
                    font.pixelSize: 11
                    font.bold: true
                    font.family: card.theme.fontMain
                }
            }
        }

        // Banner “Llegó la alarma” (además del popup)
        Rectangle {
            Layout.fillWidth: true
            visible: card.alarmFlash && card.lastFiredIndex >= 0 && card.lastFiredIndex < tasks.count
            radius: 14
            color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.14)
            border.width: 1
            border.color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.30)
            implicitHeight: bannerRow.implicitHeight + 14

            RowLayout {
                id: bannerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 10

                MaterialSymbol {
                    text: "notifications_active"
                    font.pixelSize: 18
                    color: card.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: "Alarma: " + tasks.get(card.lastFiredIndex).title
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 12
                    font.bold: true
                    font.family: card.theme.fontMain
                    elide: Text.ElideRight
                }

                Button {
                    text: "+10 min"
                    onClicked: card._snoozeIndex(card.lastFiredIndex, 10)
                }

                Button {
                    text: "Ok"
                    highlighted: true
                    onClicked: card.alarmFlash = false
                }
            }
        }

        // Lista de Tareas
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: tasks

            ScrollBar.vertical: ScrollBar {
                width: 4
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    radius: 2
                    color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.60)
                    opacity: 0.28
                }
            }

            // Placeholder vacío
            Text {
                anchors.centerIn: parent
                visible: tasks.count === 0
                text: "No hay tareas pendientes"
                color: Appearance.colors.colOnLayer0
                opacity: 0.4
                font.italic: true
                font.family: card.theme.fontMain
            }

            delegate: Rectangle {
                id: taskItem
                width: list.width
                height: 54
                radius: 12
                color: Appearance.colors.colLayer0
                border.width: 1

                readonly property bool overdue: (!done && dueMs > 0 && dueMs < card._nowMs)
                readonly property bool ringing: (index === card.lastFiredIndex) && card.alarmFlash

                // Borde rojo si vencido, acento si está “sonando”
                border.color: ringing
                    ? Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.75)
                    : (overdue ? "#ff5252" : Appearance.colors.colLayer0Border)

                // Pulso cuando suena (para que SE NOTE)
                SequentialAnimation on scale {
                    running: ringing
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.01; duration: 140; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.00; duration: 220; easing.type: Easing.OutQuad }
                }

                // Animación de entrada
                ListView.onAdd: SequentialAnimation {
                    PropertyAction { target: taskItem; property: "height"; value: 0 }
                    NumberAnimation { target: taskItem; property: "height"; to: 54; duration: 200; easing.type: Easing.OutBack }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    // Checkbox Circular
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        border.width: 2
                        border.color: done ? card.accent : Qt.rgba(0.5,0.5,0.5,0.3)
                        color: done ? card.accent : "transparent"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: 14
                            color: "white"
                            visible: done
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tasks.setProperty(index, "done", !done)
                                card._serialize()
                            }
                        }
                    }

                    // Textos
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: title
                            font.pixelSize: 13
                            font.strikeout: done
                            color: Appearance.colors.colOnLayer0
                            opacity: done ? 0.5 : 1.0
                            elide: Text.ElideRight
                            font.family: card.theme.fontMain
                        }

                        Text {
                            text: _fmtNiceDate(dueMs)
                            font.pixelSize: 10
                            color: overdue ? "#ff5252" : Appearance.colors.colOnLayer0
                            opacity: overdue ? 0.95 : 0.6
                            font.family: card.theme.fontMain
                        }
                    }

                    // Icono alarma (si está activa en esa tarea)
                    MaterialSymbol {
                        visible: alarm
                        text: ringing ? "notifications_active" : "notifications"
                        font.pixelSize: 18
                        color: ringing ? card.accent : Appearance.colors.colOnLayer0
                        opacity: ringing ? 1.0 : 0.35
                    }

                    // Borrar
                    MaterialSymbol {
                        text: "close"
                        font.pixelSize: 16
                        color: Appearance.colors.colOnLayer0
                        opacity: 0.25

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.opacity = 0.9
                            onExited: parent.opacity = 0.25
                            onClicked: {
                                tasks.remove(index)
                                card._serialize()
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Popup de Alarma (ya lo tenías, lo dejo pero con más info + resaltar) ---
    Popup {
        id: alarmPopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 320
        height: 180
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        property int taskIndex: -1

        background: Rectangle {
            radius: 20
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 24
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "notifications_active"
                font.pixelSize: 32
                color: card.accent
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: (alarmPopup.taskIndex >= 0 && tasks.count > alarmPopup.taskIndex)
                        ? tasks.get(alarmPopup.taskIndex).title
                        : "Alarma"
                color: Appearance.colors.colOnLayer1
                font.bold: true
                font.pixelSize: 16
                elide: Text.ElideRight
                font.family: card.theme.fontMain
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: (alarmPopup.taskIndex >= 0 && tasks.count > alarmPopup.taskIndex)
                        ? _fmtNiceDate(tasks.get(alarmPopup.taskIndex).dueMs)
                        : ""
                color: Appearance.colors.colOnLayer1
                opacity: 0.65
                font.pixelSize: 11
                font.family: card.theme.fontMain
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    text: "+10 min"
                    onClicked: {
                        card._snoozeIndex(alarmPopup.taskIndex, 10)
                        alarmPopup.close()
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Listo"
                    highlighted: true
                    onClicked: {
                        tasks.setProperty(alarmPopup.taskIndex, "done", true)
                        card._serialize()
                        alarmPopup.close()
                    }
                }
            }
        }
    }
}

