import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root
    implicitHeight: mainLayout.implicitHeight

    // --- ESTILO ---
    readonly property color bgPill: "#303134"
    readonly property color bgWidget: "#303134"
    readonly property color textMain: "#e8eaed"
    readonly property color textSub: "#9aa0a6"
    readonly property color accent: "#8ab4f8"

    // El Salvador: UTC-6 (sin DST)
    readonly property int esOffsetMinutes: -6 * 60

    property string searchQuery: ""
    property bool inSearchMode: false

    // MODELOS
    ListModel { id: newsModel }
    ListModel { id: scoresModel }

    // ---------------------------------------------------------
    // LAYOUT PRINCIPAL
    // ---------------------------------------------------------
    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 16

        // ---------------------------------------------------------
        // 1) BARRA DE BÚSQUEDA
        // ---------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 26
            color: root.bgPill

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.8
                shadowVerticalOffset: 2
                shadowColor: "#60000000"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                spacing: 12

                Text {
                    visible: !root.inSearchMode
                    textFormat: Text.RichText
                    text:
                        "<span style='color:#4285F4'>G</span>" +
                        "<span style='color:#EA4335'>o</span>" +
                        "<span style='color:#FBBC05'>o</span>" +
                        "<span style='color:#4285F4'>g</span>" +
                        "<span style='color:#34A853'>l</span>" +
                        "<span style='color:#EA4335'>e</span>"
                    font.family: "Roboto"
                    font.pixelSize: 18
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialSymbol {
                    visible: root.inSearchMode
                    text: "arrow_back"
                    color: root.textMain
                    font.pixelSize: 24
                    TapHandler { onTapped: resetSearch() }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    text: ""
                    color: root.textMain
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true

                    Text {
                        text: "Buscar noticias, equipos..."
                        color: root.textSub
                        font.pixelSize: 18
                        visible: !parent.text && !parent.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onAccepted: {
                        if (text.trim() !== "") {
                            root.inSearchMode = true
                            root.searchQuery = text.trim()
                            procNews.loadNews()
                            focus = false
                        }
                    }
                }

                MaterialSymbol {
                    text: "mic"
                    color: root.accent
                    font.pixelSize: 24
                    TapHandler {
                        onTapped: procBrowser.openUrl("https://www.google.com/search?q=" + encodeURIComponent(searchInput.text))
                    }
                }

                MaterialSymbol { text: "lens_camera"; color: "#fbbc04"; font.pixelSize: 24 }
            }
        }

        // ---------------------------------------------------------
        // 2) CARRUSEL (PARTIDOS)
        //   - FIX rueda: clamp correcto usando originX (evita “espacios vacíos”)
        //   - FIX “se queda en 3”: no bloqueamos el flick; wheel solo ajusta contentX con límites reales
        //   - Flechas: ahora avanzan “poco a poco” (por página) y con repetición al mantener presionado
        // ---------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            visible: !root.inSearchMode

            ListView {
                id: scoresList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 12
                clip: true

                interactive: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 1200

                // Animación suave cuando ajustamos contentX (rueda/flechas)
                Behavior on contentX {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                // ---- Límites robustos (IMPORTANTÍSIMO) ----
                // En QtQuick, el “inicio” real es originX (no siempre 0).
                function minX() { return originX }
                function maxX() { return Math.max(originX, originX + contentWidth - width) }

                function setX(x) {
                    contentX = clamp(x, minX(), maxX())
                }

                function clampNow() {
                    setX(contentX)
                }

                // “Página” (avanzar poco a poco con flechas)
                function pageStepPx() {
                    // 85% del ancho visible se siente como “pasar tarjetas”
                    return Math.max(160, Math.floor(width * 0.85))
                }

                function scrollPage(side) {
                    var step = pageStepPx()
                    if (side === "left") setX(contentX - step)
                    else setX(contentX + step)
                }

                // Repara cambios de layout/modelo (evita quedarse en blanco)
                onContentWidthChanged: Qt.callLater(clampNow)
                onWidthChanged: Qt.callLater(clampNow)
                onCountChanged: Qt.callLater(clampNow)
                onMovementEnded: clampNow

                // Wheel: usa pixelDelta si existe; si no, angleDelta.
                // Y siempre “clamp” con minX/maxX reales (originX).
                WheelHandler {
                    target: scoresList
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                    // Nota: Si aceptamos el wheel, el ListView no hace scroll “solo”.
                    // Aquí lo hacemos nosotros de forma correcta.
                    onWheel: (wheel) => {
                        // Preferir scroll horizontal si existe
                        var dx = 0
                        var dy = 0

                        if (wheel.pixelDelta) {
                            dx = wheel.pixelDelta.x
                            dy = wheel.pixelDelta.y
                        }
                        if ((dx === 0 && dy === 0) && wheel.angleDelta) {
                            dx = wheel.angleDelta.x
                            dy = wheel.angleDelta.y
                        }

                        // En muchos mouse, el scroll viene por dy.
                        // Elegimos el eje dominante y lo aplicamos horizontal.
                        var dominant = (Math.abs(dx) > Math.abs(dy)) ? dx : dy

                        // Sensibilidad (ajústala si quieres)
                        var factor = wheel.pixelDelta && (wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0) ? 1.0 : 0.35
                        var delta = dominant * factor

                        // Importante: el signo usualmente viene invertido respecto a contentX,
                        // esta fórmula se siente natural: wheel arriba => mover hacia la izquierda.
                        scoresList.setX(scoresList.contentX - delta)

                        wheel.accepted = true
                    }
                }

                model: scoresModel

                delegate: Rectangle {
                    width: 305
                    height: 118
                    radius: 16
                    color: root.bgWidget
                    border.width: 1
                    border.color: "#3c4043"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: model.league
                                color: root.textSub
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: model.dayLabel !== ""
                                radius: 9
                                color: "#202124"
                                border.width: 1
                                border.color: "#3c4043"
                                height: 20
                                width: dayText.implicitWidth + 14

                                Text {
                                    id: dayText
                                    anchors.centerIn: parent
                                    text: model.dayLabel
                                    color: root.textSub
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                visible: model.status === "in"
                                width: 7; height: 7; radius: 3.5
                                color: "#ff4d4d"
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0.2; duration: 800 }
                                    NumberAnimation { from: 0.2; to: 1; duration: 800 }
                                }
                            }

                            Text {
                                text: (model.status === "pre" && model.kickoffLocal !== "") ? model.kickoffLocal : model.statusText
                                color: model.status === "in" ? "#ff4d4d" : root.textSub
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 14

                            ColumnLayout {
                                Layout.preferredWidth: 92
                                spacing: 4
                                Image {
                                    source: model.homeLogo
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: model.homeTeam
                                    color: root.textMain
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                color: "#202124"
                                radius: 10
                                width: 72
                                height: 30
                                Text {
                                    anchors.centerIn: parent
                                    text: model.fullScore
                                    color: "#fff"
                                    font.bold: true
                                    font.pixelSize: 15
                                }
                            }

                            ColumnLayout {
                                Layout.preferredWidth: 92
                                spacing: 4
                                Image {
                                    source: model.awayLogo
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: model.awayTeam
                                    color: root.textMain
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        Text {
                            visible: model.status === "pre" && model.kickoffDetail !== ""
                            text: model.kickoffDetail
                            color: root.textSub
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    TapHandler { onTapped: procBrowser.openUrl(model.link) }
                }
            }

            // Flechas “por página” (paso a paso).
            CarouselEdgeArrow {
                side: "left"
                list: scoresList
                visibleWhenCount: scoresModel.count
                onTriggered: scoresList.scrollPage("left")
            }
            CarouselEdgeArrow {
                side: "right"
                list: scoresList
                visibleWhenCount: scoresModel.count
                onTriggered: scoresList.scrollPage("right")
            }
        }

        // ---------------------------------------------------------
        // 3) NOTICIAS
        // ---------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 520
            clip: true

            ListView {
                id: newsList
                anchors.fill: parent
                spacing: 16
                model: newsModel
                clip: true

                header: Item {
                    width: newsList.width
                    height: root.inSearchMode ? 28 : 0
                    visible: root.inSearchMode

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Resultados para: " + root.searchQuery
                        color: root.textSub
                        font.pixelSize: 11
                    }
                }

                delegate: Rectangle {
                    width: newsList.width
                    height: 280
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            radius: 16
                            color: "#000"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: model.image
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready && model.image !== ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: parent.children[0].status !== Image.Ready
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#3c4043" }
                                    GradientStop { position: 1.0; color: "#202124" }
                                }
                                MaterialSymbol { anchors.centerIn: parent; text: "newspaper"; color: "#5f6368"; font.pixelSize: 40 }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Rectangle { width: 7; height: 7; radius: 3.5; color: model.isSV ? "#34A853" : root.textSub }
                                Text { text: model.source; color: root.textMain; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text { text: model.time; color: root.textSub; font.pixelSize: 11 }
                            }

                            Text {
                                text: model.title
                                color: root.textMain
                                font.family: "Roboto"
                                font.pixelSize: 16
                                font.bold: true
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    TapHandler { onTapped: procBrowser.openUrl(model.link) }
                }
            }
        }
    }

    // ---------------------------------------------------------
    // COMPONENTES / UTILS
    // ---------------------------------------------------------
    component MaterialSymbol : Text { font.family: "Material Symbols Rounded" }

    component CarouselEdgeArrow : Rectangle {
        id: arrow
        property string side: "left"
        property Flickable list: null
        property int visibleWhenCount: 0
        signal triggered()

        width: 30; height: 60; radius: 15
        color: pressed ? "#2a2b2e" : "#202124"
        border.width: (activeFocus || hovered || pressed) ? 1.5 : 1
        border.color: (activeFocus || hovered || pressed) ? root.accent : "#3c4043"
        visible: visibleWhenCount > 0

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: (side === "left") ? parent.left : undefined
        anchors.right: (side === "right") ? parent.right : undefined
        anchors.leftMargin: (side === "left") ? 6 : 0
        anchors.rightMargin: (side === "right") ? 6 : 0

        readonly property bool atBeginning: list ? list.atXBeginning : true
        readonly property bool atEnd: list ? list.atXEnd : true
        readonly property bool disabled: (side === "left") ? atBeginning : atEnd

        opacity: disabled ? 0.25 : 0.88
        enabled: !disabled

        property bool pressed: false
        property bool hovered: false

        scale: pressed ? 0.96 : (hovered || activeFocus ? 1.04 : 1.0)

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: (arrow.hovered || arrow.activeFocus) ? 0.9 : 0.7
            shadowVerticalOffset: 1
            shadowColor: "#50000000"
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: (side === "left") ? "chevron_left" : "chevron_right"
            color: root.textMain
            font.pixelSize: 22
            opacity: 0.95
        }

        // Mantener presionado: avanza por páginas repetidamente
        Timer {
            id: repeatTimer
            interval: 90
            repeat: true
            running: false
            onTriggered: arrow.triggered()
        }

        TapHandler {
            onPressedChanged: {
                arrow.pressed = pressed
                if (pressed) {
                    arrow.forceActiveFocus()
                    arrow.triggered()     // primer paso inmediato
                    repeatTimer.start()   // luego repite mientras sostienes
                } else {
                    repeatTimer.stop()
                }
            }
            onCanceled: {
                arrow.pressed = false
                repeatTimer.stop()
            }
            onTapped: { /* no-op: ya lo manejamos en pressedChanged */ }
        }

        HoverHandler { onHoveredChanged: arrow.hovered = hovered }

        Keys.onReturnPressed: triggered()
        Keys.onEnterPressed: triggered()
        focusPolicy: Qt.StrongFocus
    }

    function resetSearch() {
        root.inSearchMode = false
        root.searchQuery = ""
        searchInput.text = ""
        procNews.loadNews()
    }

    function clamp(v, lo, hi) {
        if (v < lo) return lo
        if (v > hi) return hi
        return v
    }

    // --- Hora ES ---
    function two(n) { return (n < 10 ? "0" : "") + n }
    function epochFromIso(iso) {
        try {
            var d = new Date(iso)
            var t = d.getTime()
            if (isNaN(t)) return NaN
            return t
        } catch (e) { return NaN }
    }
    function esDateFromIso(iso) {
        var t = epochFromIso(iso)
        if (isNaN(t)) return null
        return new Date(t + root.esOffsetMinutes * 60000)
    }
    function fmtTimeES(iso) {
        var d = esDateFromIso(iso)
        if (!d) return ""
        return two(d.getUTCHours()) + ":" + two(d.getUTCMinutes())
    }
    function fmtDetailES(iso) {
        var d = esDateFromIso(iso)
        if (!d) return ""
        return two(d.getUTCDate()) + "/" + two(d.getUTCMonth() + 1) + " " +
               two(d.getUTCHours()) + ":" + two(d.getUTCMinutes()) + " (ES)"
    }
    function msFromIso(iso) {
        try {
            var t = (new Date(iso)).getTime()
            return isNaN(t) ? NaN : t
        } catch (e) {
            return NaN
        }
    }

    // ---------------------------------------------------------
    // NAVEGADOR
    // ---------------------------------------------------------
    Process {
        id: procBrowser
        function openUrl(link) {
            command = ["bash", "-c", "firefox \"" + link + "\""]
            running = true
        }
    }

    // ---------------------------------------------------------
    // NOTIFICACIÓN -> notify-send
    // ---------------------------------------------------------
    Process {
        id: procNotify
        property string appName: "Fútbol"
        property string iconName: "dialog-information"
        property int timeoutMs: 7000

        function send(title, body) {
            command = ["bash", "-lc",
                       "notify-send -a \"" + escapeSh(appName) + "\" -u normal -t " + timeoutMs +
                       " -i \"" + escapeSh(iconName) + "\" \"" + escapeSh(title) + "\" \"" + escapeSh(body) + "\""]
            running = true
        }
    }

    function escapeSh(s) {
        return ("" + s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
    }

    // ---------------------------------------------------------
    // DETALLES DEL GOL (anotador)
    // ---------------------------------------------------------
    Process {
        id: procGoalDetails

        property var queue: []
        property bool busy: false
        property var lastGoalKeyByEvent: ({})

        function request(leagueKey, eventId, leagueName, homeName, awayName, hs, as, detail) {
            if (!eventId || !leagueKey) return
            queue.push({
                leagueKey: leagueKey,
                eventId: eventId,
                leagueName: leagueName,
                homeName: homeName,
                awayName: awayName,
                hs: hs,
                as: as,
                detail: detail
            })
            pump()
        }

        function pump() {
            if (busy) return
            if (queue.length === 0) return
            busy = true

            var j = queue.shift()
            _job = j

            var url = "https://site.api.espn.com/apis/site/v2/sports/soccer/" + j.leagueKey + "/summary?event=" + j.eventId
            command = ["curl", "-s", "-L", url]
            running = true
        }

        property var _job: null

        function safe(obj, path, fallback) {
            try {
                var parts = path.split(".")
                var cur = obj
                for (var i = 0; i < parts.length; i++) {
                    var p = parts[i]
                    if (p.match(/^\d+$/)) p = parseInt(p, 10)
                    cur = cur[p]
                    if (cur === undefined || cur === null) return fallback
                }
                return cur
            } catch (e) { return fallback }
        }

        function pickLastGoal(json) {
            var keyEvents = safe(json, "keyEvents", [])
            if (Array.isArray(keyEvents) && keyEvents.length > 0) {
                for (var i = keyEvents.length - 1; i >= 0; i--) {
                    var ev = keyEvents[i]
                    var typeText = (safe(ev, "type.text", "") + "").toLowerCase()
                    var text = (safe(ev, "text", "") + "").toLowerCase()
                    if (typeText.indexOf("goal") !== -1 || text.indexOf("goal") !== -1 || text.indexOf("gol") !== -1)
                        return ev
                }
            }

            var scoringPlays = safe(json, "scoringPlays", [])
            if (Array.isArray(scoringPlays) && scoringPlays.length > 0)
                return scoringPlays[scoringPlays.length - 1]

            return null
        }

        function extractScorer(ev) {
            return safe(ev, "participants.0.athlete.displayName", "") ||
                   safe(ev, "participants.0.athlete.shortName", "") ||
                   safe(ev, "athletes.0.displayName", "") ||
                   safe(ev, "player.displayName", "") ||
                   ""
        }

        function extractTeam(ev) {
            return safe(ev, "team.displayName", "") ||
                   safe(ev, "team.shortDisplayName", "") ||
                   safe(ev, "competitor.displayName", "") ||
                   ""
        }

        function extractClock(ev) {
            return safe(ev, "clock.displayValue", "") || safe(ev, "time", "") || ""
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var j = procGoalDetails._job
                procGoalDetails._job = null

                try {
                    var json = JSON.parse(text)
                    var lastGoal = procGoalDetails.pickLastGoal(json)

                    var scorer = ""
                    var team = ""
                    var clock = ""
                    var rawText = ""

                    if (lastGoal) {
                        scorer = procGoalDetails.extractScorer(lastGoal)
                        team = procGoalDetails.extractTeam(lastGoal)
                        clock = procGoalDetails.extractClock(lastGoal)
                        rawText = procGoalDetails.safe(lastGoal, "text", "")
                    }

                    var goalKey = (scorer + "|" + team + "|" + clock + "|" + j.hs + "-" + j.as + "|" + rawText).trim()
                    var prevKey = procGoalDetails.lastGoalKeyByEvent[j.eventId] || ""
                    if (!(goalKey !== "" && goalKey === prevKey)) {
                        if (goalKey !== "") procGoalDetails.lastGoalKeyByEvent[j.eventId] = goalKey

                        var title = "GOOOL"
                        if (scorer !== "") title = "GOOOL: " + scorer
                        else if (team !== "") title = "GOOOL: " + team

                        var body = j.homeName + " " + j.hs + " - " + j.as + " " + j.awayName + "\n" + j.leagueName
                        if (clock !== "") body += "\nMinuto: " + clock
                        if (scorer !== "" && team !== "") body += "\n" + scorer + " (" + team + ")"
                        else if (rawText !== "") body += "\n" + rawText
                        else if (j.detail && j.detail !== "") body += "\n" + j.detail

                        procNotify.send(title, body)
                    }
                } catch (e) {
                    if (j) {
                        var title2 = "GOOOL"
                        var body2 = j.homeName + " " + j.hs + " - " + j.as + " " + j.awayName + "\n" + j.leagueName
                        if (j.detail && j.detail !== "") body2 += "\n" + j.detail
                        procNotify.send(title2, body2)
                    }
                }

                procGoalDetails.busy = false
                procGoalDetails.pump()
            }
        }
    }

    // ---------------------------------------------------------
    // PARTIDOS: goles + aviso 10 min antes + final
    // ---------------------------------------------------------
    Process {
        id: procScores

        property var leagues: [
            { key: "eng.1", name: "Premier League" },
            { key: "esp.1", name: "La Liga" },
            { key: "ita.1", name: "Serie A" },
            { key: "ger.1", name: "Bundesliga" },
            { key: "fra.1", name: "Ligue 1" },
            { key: "uefa.champions", name: "UEFA Champions League" },
            { key: "uefa.europa", name: "UEFA Europa League" }
        ]

        property var dayOffsets: [-1, 0, 1, 2, 3]
        property int leagueIndex: 0
        property int dayIndex: 0
        property int maxMatches: 80
        property bool loading: false
        property var pendingScores: []
        property var seenIds: ({})

        // Detector de goles
        property bool initializedOnce: false
        property var lastScoreByEvent: ({})
        property var lastNotifyAtByEvent: ({})

        // Avisos inicio/final
        property var notifiedPreByEvent: ({})
        property var notifiedFinalByEvent: ({})
        property var lastStateByEvent: ({})

        // Config
        property int preNotifyMinutes: 10
        property int preWindowMs: 90000
        property int goalCooldownMs: 5000

        function startLoadScores() {
            if (loading) return
            loading = true
            pendingScores = []
            seenIds = ({})
            leagueIndex = 0
            dayIndex = 0
            loadNext()
        }

        function addDays(d, offset) {
            var x = new Date(d)
            x.setDate(x.getDate() + offset)
            return x
        }

        function pad2(n) { return (n < 10 ? "0" : "") + n }
        function yyyymmdd(d) { return "" + d.getFullYear() + pad2(d.getMonth() + 1) + pad2(d.getDate()) }

        function loadNext() {
            if (leagueIndex >= leagues.length) { finalizeScores(); return }
            if (dayIndex >= dayOffsets.length) { leagueIndex++; dayIndex = 0; loadNext(); return }

            var lg = leagues[leagueIndex]
            var off = dayOffsets[dayIndex]
            var dateStr = yyyymmdd(addDays(new Date(), off))
            var url = "https://site.api.espn.com/apis/site/v2/sports/soccer/" + lg.key + "/scoreboard?dates=" + dateStr

            command = ["curl", "-s", "-L", url]
            running = true
        }

        function safe(obj, path, fallback) {
            try {
                var parts = path.split(".")
                var cur = obj
                for (var i = 0; i < parts.length; i++) {
                    var p = parts[i]
                    if (p.match(/^\d+$/)) p = parseInt(p, 10)
                    cur = cur[p]
                    if (cur === undefined || cur === null) return fallback
                }
                return cur
            } catch (e) { return fallback }
        }

        function pickTeams(competitors) {
            var home = null, away = null
            for (var i = 0; i < competitors.length; i++) {
                if (competitors[i].homeAway === "home") home = competitors[i]
                if (competitors[i].homeAway === "away") away = competitors[i]
            }
            if (!home && competitors.length > 0) home = competitors[0]
            if (!away && competitors.length > 1) away = competitors[1]
            return { home: home, away: away }
        }

        function dayLabelFromOffset(off) {
            if (off === 0) return "HOY"
            if (off === -1) return "AYER"
            return "D+" + off
        }

        function statusRank(state) {
            if (state === "in") return 0
            if (state === "pre") return 1
            if (state === "post") return 3
            return 2
        }

        function timeRank(eventDateIso) {
            try { return new Date(eventDateIso).getTime() } catch (e) { return 0 }
        }

        function maybeNotifyPreKickoff(eventId, leagueName, homeName, awayName, eventDateIso, kickoffLocal) {
            if (!eventId || !eventDateIso) return
            if (notifiedPreByEvent[eventId] === true) return
            if (!initializedOnce) return

            var t = msFromIso(eventDateIso)
            if (isNaN(t)) return

            var now = Date.now()
            var target = t - preNotifyMinutes * 60000
            var delta = now - target

            if (delta >= 0 && delta <= preWindowMs) {
                notifiedPreByEvent[eventId] = true
                var title = "Partido en " + preNotifyMinutes + " min"
                var body = homeName + " vs " + awayName + "\nHora (ES): " + (kickoffLocal || fmtTimeES(eventDateIso)) + "\n" + leagueName
                procNotify.send(title, body)
            }
        }

        function maybeNotifyFinal(eventId, leagueName, homeName, awayName, hs, as) {
            if (!eventId) return
            if (notifiedFinalByEvent[eventId] === true) return
            if (!initializedOnce) return

            notifiedFinalByEvent[eventId] = true
            var title = "Final: " + homeName + " " + hs + " - " + as + " " + awayName
            procNotify.send(title, leagueName)
        }

        function maybeNotifyGoal(eventId, leagueKey, leagueName, homeName, awayName, hs, as, detail) {
            if (!eventId || eventId === "") return

            var prev = lastScoreByEvent[eventId]
            lastScoreByEvent[eventId] = ({ home: hs, away: as })

            if (!initializedOnce) return
            if (!prev) return

            var changed = (hs !== prev.home) || (as !== prev.away)
            if (!changed) return

            var now = Date.now()
            var lastAt = lastNotifyAtByEvent[eventId] || 0
            if (now - lastAt < goalCooldownMs) return
            lastNotifyAtByEvent[eventId] = now

            procGoalDetails.request(leagueKey, eventId, leagueName, homeName, awayName, hs, as, detail)
        }

        function finalizeScores() {
            if (!pendingScores || pendingScores.length === 0) {
                loading = false
                initializedOnce = true
                return
            }

            pendingScores.sort(function(a, b) {
                var ra = statusRank(a.status)
                var rb = statusRank(b.status)
                if (ra !== rb) return ra - rb

                var da = a.dayOffset, db = b.dayOffset
                var pa = (da === 0 ? 0 : (da > 0 ? 1 : 2))
                var pb = (db === 0 ? 0 : (db > 0 ? 1 : 2))
                if (pa !== pb) return pa - pb

                var ta = timeRank(a.eventDate)
                var tb = timeRank(b.eventDate)
                if (ta !== tb) return ta - tb

                return (a.statusText || "").localeCompare(b.statusText || "")
            })

            if (pendingScores.length > maxMatches)
                pendingScores = pendingScores.slice(0, maxMatches)

            scoresModel.clear()
            for (var i = 0; i < pendingScores.length; i++)
                scoresModel.append(pendingScores[i])

            loading = false
            initializedOnce = true
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var lg = procScores.leagues[procScores.leagueIndex]
                var off = procScores.dayOffsets[procScores.dayIndex]

                try {
                    var json = JSON.parse(text)
                    var events = json.events || []

                    for (var i = 0; i < events.length; i++) {
                        var e = events[i]

                        var eid = procScores.safe(e, "id", "")
                        if (eid !== "") {
                            if (procScores.seenIds[eid] === true) continue
                            procScores.seenIds[eid] = true
                        }

                        var comp = procScores.safe(e, "competitions.0", null)
                        if (!comp) continue

                        var competitors = comp.competitors || []
                        if (competitors.length < 2) continue

                        var picked = procScores.pickTeams(competitors)
                        var home = picked.home
                        var away = picked.away
                        if (!home || !away) continue

                        var state = procScores.safe(e, "status.type.state", "pre")
                        var shortDetail = procScores.safe(e, "status.type.shortDetail", "")

                        var homeName = procScores.safe(home, "team.shortDisplayName", "Local")
                        var awayName = procScores.safe(away, "team.shortDisplayName", "Visitante")
                        var homeLogo = procScores.safe(home, "team.logo", "")
                        var awayLogo = procScores.safe(away, "team.logo", "")
                        var homeScoreStr = procScores.safe(home, "score", "0")
                        var awayScoreStr = procScores.safe(away, "score", "0")

                        var hs = parseInt(homeScoreStr, 10); if (isNaN(hs)) hs = 0
                        var as = parseInt(awayScoreStr, 10); if (isNaN(as)) as = 0

                        var eventDate = procScores.safe(e, "date", "")

                        var kickoffLocal = ""
                        var kickoffDetail = ""
                        if (state === "pre" && eventDate !== "") {
                            kickoffLocal = fmtTimeES(eventDate)
                            kickoffDetail = fmtDetailES(eventDate)
                        }

                        var prevState = procScores.lastStateByEvent[eid] || ""
                        procScores.lastStateByEvent[eid] = state

                        if (state === "pre" && eventDate !== "") {
                            procScores.maybeNotifyPreKickoff(eid, lg.name, homeName, awayName, eventDate, kickoffLocal)
                        }

                        if (state === "in") {
                            procScores.maybeNotifyGoal(eid, lg.key, lg.name, homeName, awayName, hs, as, shortDetail)
                        }

                        if (state === "post" && prevState !== "post") {
                            procScores.maybeNotifyFinal(eid, lg.name, homeName, awayName, hs, as)
                        }

                        var scoreStr = (state === "pre") ? "vs" : (hs + " - " + as)

                        var linkUrl = procScores.safe(
                            e, "links.0.href",
                            "https://www.google.com/search?q=" + encodeURIComponent(homeName + " vs " + awayName)
                        )

                        procScores.pendingScores.push({
                            "id": eid,
                            "league": lg.name,
                            "dayLabel": procScores.dayLabelFromOffset(off),
                            "dayOffset": off,
                            "eventDate": eventDate,

                            "homeTeam": homeName,
                            "homeLogo": homeLogo,
                            "awayTeam": awayName,
                            "awayLogo": awayLogo,

                            "fullScore": scoreStr,
                            "status": state,
                            "statusText": shortDetail,

                            "kickoffLocal": kickoffLocal,
                            "kickoffDetail": kickoffDetail,

                            "link": linkUrl
                        })
                    }
                } catch (e) {
                    console.log("Error parsing scores (" + lg.name + "): " + e)
                }

                procScores.dayIndex++
                procScores.loadNext()
            }
        }
    }

    // ---------------------------------------------------------
    // NOTICIAS RSS
    // ---------------------------------------------------------
    Process {
        id: procNews

        property var queue: []
        property var collected: []
        property bool loading: false
        property int maxItems: 30
        property bool _currentIsSV: false

        function loadNews() {
            newsModel.clear()
            collected = []
            queue = []
            loading = true

            if (root.inSearchMode) {
                queue.push({ url: "https://news.google.com/rss/search?q=" + encodeURIComponent(root.searchQuery) + "&hl=es-419&gl=US&ceid=US:es-419", isSV: false })
            } else {
                queue.push({ url: "https://news.google.com/rss?hl=es-419&gl=US&ceid=US:es-419", isSV: false })
                queue.push({ url: "https://news.google.com/rss?hl=es-419&gl=SV&ceid=SV:es-419", isSV: true })
                queue.push({ url: "https://news.google.com/rss/search?q=" + encodeURIComponent("El Salvador") + "&hl=es-419&gl=SV&ceid=SV:es-419", isSV: true })
            }

            loadNext()
        }

        function loadNext() {
            if (queue.length === 0) { finalize(); return }
            var next = queue.shift()
            _currentIsSV = next.isSV
            command = ["curl", "-s", "-L", next.url]
            running = true
        }

        function finalize() {
            var seen = ({})
            var out = []
            for (var i = 0; i < collected.length; i++) {
                var it = collected[i]
                if (!it.link) continue
                if (seen[it.link] === true) continue
                seen[it.link] = true
                out.push(it)
            }

            out.sort(function(a, b) { return (b.ts || 0) - (a.ts || 0) })

            newsModel.clear()
            var take = Math.min(maxItems, out.length)
            for (var k = 0; k < take; k++) newsModel.append(out[k])
            loading = false
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.length > 80) {
                    var items = parseXMLToItems(text, procNews._currentIsSV)
                    for (var i = 0; i < items.length; i++)
                        procNews.collected.push(items[i])
                }
                procNews.loadNext()
            }
        }
    }

    function parseXMLToItems(xml, isSV) {
        var results = []
        var itemRegex = /<item>([\s\S]*?)<\/item>/g
        var match
        var count = 0

        while ((match = itemRegex.exec(xml)) !== null && count < 40) {
            var c = match[1]
            var t = (c.match(/<title>(.*?)<\/title>/) || ["",""])[1].replace("<![CDATA[","").replace("]]>","")
            var l = (c.match(/<link>(.*?)<\/link>/) || ["",""])[1]
            var d = (c.match(/<pubDate>(.*?)<\/pubDate>/) || ["",""])[1]
            var s = (c.match(/<source[^>]*>(.*?)<\/source>/) || ["","Noticias"])[1]

            var img = ""
            var descM = c.match(/<description>([\s\S]*?)<\/description>/)
            if (descM) {
                var src = descM[1].match(/src="([^"]+)"/)
                if (src) img = src[1]
            }
            if (img === "" || img.includes("tracker")) {
                var seed = root.inSearchMode ? root.searchQuery : (isSV ? "elsalvador" : "world")
                img = "https://loremflickr.com/500/300/" + encodeURIComponent(seed) + "?lock=" + count
            }

            var ts = 0
            var time = "Ahora"
            if (d) {
                var dd = new Date(d)
                ts = dd.getTime()
                if (!isNaN(ts)) {
                    var diff = Date.now() - ts
                    var mins = Math.max(0, Math.floor(diff / 60000))
                    var hrs = Math.floor(mins / 60)
                    if (mins < 60) time = mins + " min"
                    else if (hrs < 24) time = hrs + " h"
                    else time = Math.floor(hrs / 24) + " d"
                }
            }

            var dash = t.lastIndexOf(" - ")
            if (dash > 0) t = t.substring(0, dash)

            results.push({
                "title": decodeHtml(t),
                "link": l,
                "source": s,
                "time": time,
                "image": img,
                "ts": ts,
                "isSV": !!isSV
            })
            count++
        }
        return results
    }

    function decodeHtml(s) {
        return ("" + s)
            .replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&#39;/g, "'")
    }

    // ---------------------------------------------------------
    // TIMERS / INICIO
    // ---------------------------------------------------------
    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: procScores.startLoadScores()
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: procNews.loadNews()
    }

    Component.onCompleted: {
        procNews.loadNews()
        procScores.startLoadScores()
    }
}

