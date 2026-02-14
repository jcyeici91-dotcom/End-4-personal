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
    readonly property color cardBg: "#202124"
    readonly property color textMain: "#e8eaed"
    readonly property color textSub: "#9aa0a6"
    readonly property color accent: "#8ab4f8"

    property string activeTopic: "HEADLINES"
    property string searchQuery: ""
    property bool inSearchMode: false

    // MODELOS DE DATOS
    ListModel { id: newsModel }   // Noticias RSS
    ListModel { id: scoresModel } // Partidos (multi-liga + multi-días)

    // Variables Clima
    property string weatherTemp: "--"
    property string weatherCond: "Cargando..."

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 16

        // ---------------------------------------------------------
        // 1. BARRA DE BÚSQUEDA
        // ---------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.alignment: Qt.AlignHCenter
            radius: 26
            color: root.bgPill

            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowVerticalOffset: 2; shadowColor: "#60000000" }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 15
                spacing: 12

                Text {
                    visible: !root.inSearchMode
                    text: "G"
                    font.family: "Roboto"
                    font.bold: true
                    font.pixelSize: 24
                    color: "#fff"
                }

                MaterialSymbol {
                    visible: root.inSearchMode
                    text: "arrow_back"
                    color: "#e8eaed"
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
                    color: "#8ab4f8"
                    font.pixelSize: 24
                    TapHandler { onTapped: procBrowser.openUrl("https://www.google.com/search?q=&kponly&kgmid=/m/02mjmr") }
                }
                MaterialSymbol { text: "lens_camera"; color: "#fbbc04"; font.pixelSize: 24 }
            }
        }

        // ---------------------------------------------------------
        // 2. WIDGETS (CLIMA + PARTIDOS HOY/RECIENTES/PRÓXIMOS)
        // ---------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            visible: !root.inSearchMode

            ListView {
                id: scoresList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 12
                clip: true

                interactive: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.DragOverBounds

                // CABECERA: CLIMA
                header: Rectangle {
                    width: 140
                    height: 90
                    radius: 16
                    color: root.bgWidget
                    border.width: 1
                    border.color: "#3c4043"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "El Salvador"; color: root.textMain; font.bold: true; font.pixelSize: 12 }
                        RowLayout {
                            Text { text: root.weatherTemp; color: root.textMain; font.pixelSize: 28; font.bold: true }
                            MaterialSymbol { text: "partly_cloudy_day"; color: "#fbbc04"; font.pixelSize: 24 }
                        }
                        Text {
                            text: root.weatherCond
                            color: root.textSub
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.maximumWidth: 120
                        }
                    }

                    TapHandler { onTapped: procBrowser.openUrl("https://www.google.com/search?q=clima+el+salvador") }
                }

                model: scoresModel

                delegate: Rectangle {
                    width: 240
                    height: 90
                    radius: 16
                    color: root.bgWidget
                    border.width: 1
                    border.color: "#3c4043"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        // LIGA + DÍA + ESTADO
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: model.league
                                color: root.textSub
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: model.dayLabel !== ""
                                radius: 8
                                color: "#202124"
                                border.width: 1
                                border.color: "#3c4043"
                                height: 18
                                width: dayText.implicitWidth + 12

                                Text {
                                    id: dayText
                                    anchors.centerIn: parent
                                    text: model.dayLabel
                                    color: root.textSub
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                visible: model.status === "in"
                                width: 6; height: 6; radius: 3; color: "#ff4d4d"
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0.2; duration: 800 }
                                    NumberAnimation { from: 0.2; to: 1; duration: 800 }
                                }
                            }

                            Text {
                                text: model.statusText
                                color: model.status === "in" ? "#ff4d4d" : root.textSub
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // EQUIPOS + SCORE
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 10

                            ColumnLayout {
                                Layout.preferredWidth: 70
                                Image {
                                    source: model.homeLogo
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: model.homeTeam
                                    color: root.textMain
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                color: "#202124"
                                radius: 8
                                width: 56
                                height: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: model.fullScore
                                    color: "#fff"
                                    font.bold: true
                                    font.pixelSize: 14
                                }
                            }

                            ColumnLayout {
                                Layout.preferredWidth: 70
                                Image {
                                    source: model.awayLogo
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: model.awayTeam
                                    color: root.textMain
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    TapHandler { onTapped: procBrowser.openUrl(model.link) }
                }

                // Cargando (solo si no hay nada aún)
                footer: Item {
                    width: 240
                    height: 90
                    visible: procScores.loading && scoresModel.count === 0

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: root.bgWidget
                        border.width: 1
                        border.color: "#3c4043"
                        opacity: 0.75

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "Cargando más partidos..."; color: root.textSub; font.pixelSize: 12 }
                            Rectangle {
                                width: 140; height: 4; radius: 2; color: "#3c4043"
                                Rectangle {
                                    width: parent.width * 0.45
                                    height: parent.height
                                    radius: 2
                                    color: root.accent
                                    SequentialAnimation on x {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: -width; to: parent.width; duration: 900; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: 90
                radius: 16
                color: root.bgWidget
                border.width: 1
                border.color: "#3c4043"
                opacity: 0.5
                visible: !procScores.loading && scoresModel.count === 0

                Text {
                    anchors.centerIn: parent
                    text: "No hay partidos"
                    color: root.textSub
                    font.pixelSize: 12
                }
            }
        }

        // ---------------------------------------------------------
        // 3. FEED DE NOTICIAS
        // ---------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 500
            clip: true

            ListView {
                id: newsList
                anchors.fill: parent
                spacing: 16
                model: newsModel
                clip: true

                header: ColumnLayout {
                    width: parent.width
                    visible: root.inSearchMode
                    spacing: 10
                    Text { text: "Resultados para: " + root.searchQuery; color: root.accent; font.bold: true; font.pixelSize: 14; Layout.leftMargin: 8 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10; Layout.leftMargin: 8
                        ActionChip { label: "Tabla Liga"; icon: "table_chart"; url: "https://www.google.com/search?q=tabla+liga+española" }
                        ActionChip { label: "Resultados"; icon: "sports_score"; url: "https://www.google.com/search?q=resultados+futbol+hoy" }
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
                                Rectangle { width: 16; height: 16; radius: 8; color: root.textSub }
                                Text { text: model.source; color: root.textMain; font.pixelSize: 11; font.bold: true }
                                Text { text: "• " + model.time; color: root.textSub; font.pixelSize: 11 }
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

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                Item { Layout.fillWidth: true }
                                MaterialSymbol { text: "favorite"; color: root.textSub; font.pixelSize: 18 }
                                Item { width: 15 }
                                MaterialSymbol { text: "share"; color: root.textSub; font.pixelSize: 18 }
                            }
                        }
                    }

                    TapHandler { onTapped: procBrowser.openUrl(model.link) }
                }
            }
        }
    }

    // --- COMPONENTES AUXILIARES ---
    component MaterialSymbol : Text { font.family: "Material Symbols Rounded" }

    component ActionChip : Rectangle {
        property string label
        property string icon
        property string url
        width: rA.implicitWidth + 24; height: 32; radius: 16
        color: root.bgWidget; border.width: 1; border.color: "#5f6368"

        RowLayout {
            id: rA; anchors.centerIn: parent; spacing: 6
            MaterialSymbol { text: icon; color: "#8ab4f8"; font.pixelSize: 16 }
            Text { text: label; color: root.textMain; font.bold: true; font.pixelSize: 12 }
        }

        TapHandler { onTapped: procBrowser.openUrl(url) }
    }

    function resetSearch() {
        root.inSearchMode = false
        root.searchQuery = ""
        searchInput.text = ""
        procNews.loadNews()
    }

    // ---------------------------------------------------------
    // BACKEND: NAVEGADOR
    // ---------------------------------------------------------
    Process {
        id: procBrowser
        function openUrl(link) {
            command = ["bash", "-c", "firefox \"" + link + "\""]
            running = true
        }
    }

    // ---------------------------------------------------------
    // BACKEND: CLIMA
    // ---------------------------------------------------------
    Process {
        id: procWeather
        command: ["curl", "-s", "wttr.in/El+Salvador?format=%t|%C"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")
                if (parts.length >= 2) {
                    root.weatherTemp = parts[0].trim()
                    root.weatherCond = parts[1].trim()
                }
            }
        }
    }

    // ---------------------------------------------------------
    // BACKEND: PARTIDOS (LO MEJOR)
    // - Trae: ayer + hoy + próximos días
    // - Multi-liga
    // - Buffer para no vaciar al recargar
    // - Deduplicación por event id
    // - Orden: EN VIVO -> HOY -> PRÓXIMOS -> RECIENTES
    // ---------------------------------------------------------
    Process {
        id: procScores

        // Grandes ligas europeas
        property var leagues: [
            { key: "eng.1", name: "Premier League" },
            { key: "esp.1", name: "La Liga" },
            { key: "ita.1", name: "Serie A" },
            { key: "ger.1", name: "Bundesliga" },
            { key: "fra.1", name: "Ligue 1" },
            { key: "uefa.champions", name: "UEFA Champions League" }
        ]

        // Ventana de días:
        // -1 = ayer, 0 = hoy, +1 +2 +3 = próximos
        property var dayOffsets: [-1, 0, 1, 2, 3]

        property int leagueIndex: 0
        property int dayIndex: 0

        property int maxMatches: 60
        property bool loading: false

        // buffer
        property var pendingScores: []
        property var seenIds: ({}) // mapa id->true para no duplicar

        function startLoadScores() {
            if (loading) return

            loading = true
            pendingScores = []
            seenIds = ({})
            leagueIndex = 0
            dayIndex = 0
            loadNext()
        }

        function loadNext() {
            if (leagueIndex >= leagues.length) {
                finalizeScores()
                return
            }
            if (dayIndex >= dayOffsets.length) {
                leagueIndex++
                dayIndex = 0
                loadNext()
                return
            }

            var lg = leagues[leagueIndex]
            var off = dayOffsets[dayIndex]

            var dateStr = yyyymmdd(addDays(new Date(), off))
            var url = "https://site.api.espn.com/apis/site/v2/sports/soccer/" + lg.key + "/scoreboard?dates=" + dateStr

            command = ["curl", "-s", "-L", url]
            running = true
        }

        function addDays(d, offset) {
            var x = new Date(d)
            x.setDate(x.getDate() + offset)
            return x
        }

        function pad2(n) { return (n < 10 ? "0" : "") + n }

        function yyyymmdd(d) {
            return "" + d.getFullYear() + pad2(d.getMonth() + 1) + pad2(d.getDate())
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
            } catch (e) {
                return fallback
            }
        }

        function pickTeams(competitors) {
            var home = null
            var away = null
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
            // Para ordenar por fecha/hora cuando se pueda
            try { return new Date(eventDateIso).getTime() } catch (e) { return 0 }
        }

        function finalizeScores() {
            if (!pendingScores || pendingScores.length === 0) {
                loading = false
                return
            }

            // Orden pro:
            // 1) en vivo
            // 2) hoy (pre/in/post)
            // 3) próximos (pre)
            // 4) recientes (post/ayer)
            pendingScores.sort(function(a, b) {
                // primero rank de estado
                var ra = statusRank(a.status)
                var rb = statusRank(b.status)
                if (ra !== rb) return ra - rb

                // luego día: HOY primero, luego D+1.., luego AYER
                var da = a.dayOffset
                var db = b.dayOffset
                var pa = (da === 0 ? 0 : (da > 0 ? 1 : 2))
                var pb = (db === 0 ? 0 : (db > 0 ? 1 : 2))
                if (pa !== pb) return pa - pb

                // dentro de cada grupo, ordenar por hora (si existe)
                var ta = timeRank(a.eventDate)
                var tb = timeRank(b.eventDate)
                if (ta !== tb) return ta - tb

                // fallback por texto
                return (a.statusText || "").localeCompare(b.statusText || "")
            })

            if (pendingScores.length > maxMatches)
                pendingScores = pendingScores.slice(0, maxMatches)

            // Reemplazo atómico
            scoresModel.clear()
            for (var i = 0; i < pendingScores.length; i++)
                scoresModel.append(pendingScores[i])

            loading = false
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

                        // id para deduplicar
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

                        var state = procScores.safe(e, "status.type.state", "pre") // pre, in, post
                        var shortDetail = procScores.safe(e, "status.type.shortDetail", "")

                        var homeName = procScores.safe(home, "team.shortDisplayName", "Local")
                        var awayName = procScores.safe(away, "team.shortDisplayName", "Visitante")
                        var homeLogo = procScores.safe(home, "team.logo", "")
                        var awayLogo = procScores.safe(away, "team.logo", "")
                        var homeScore = procScores.safe(home, "score", "")
                        var awayScore = procScores.safe(away, "score", "")

                        var scoreStr = (state === "pre") ? "vs" : (homeScore + " - " + awayScore)

                        var eventDate = procScores.safe(e, "date", "") // ISO
                        var linkUrl = procScores.safe(
                            e, "links.0.href",
                            "https://www.google.com/search?q=" + encodeURIComponent(homeName + " vs " + awayName)
                        )

                        procScores.pendingScores.push({
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
                            "link": linkUrl
                        })
                    }
                } catch (e) {
                    console.log("Error parsing scores (" + lg.name + "): " + e)
                }

                // siguiente fecha
                procScores.dayIndex++
                procScores.loadNext()
            }
        }
    }

    // ---------------------------------------------------------
    // BACKEND: NOTICIAS RSS
    // ---------------------------------------------------------
    Process {
        id: procNews
        function loadNews() {
            newsModel.clear()
            var url = "https://news.google.com/rss?hl=es-419&gl=SV&ceid=SV:es-419"
            if (root.inSearchMode)
                url = "https://news.google.com/rss/search?q=" + encodeURIComponent(root.searchQuery) + "&hl=es-419&gl=SV&ceid=SV:es-419"
            command = ["curl", "-s", "-L", url]
            running = true
        }
        stdout: StdioCollector { onStreamFinished: { if (text.length > 100) parseXML(text) } }
    }

    // TIMERS Y INICIO
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: {
            procScores.startLoadScores()
            procWeather.running = true
        }
    }

    Component.onCompleted: {
        procNews.loadNews()
        procScores.startLoadScores()
        procWeather.running = true
    }

    function parseXML(xml) {
        var itemRegex = /<item>([\s\S]*?)<\/item>/g
        var match
        var count = 0

        while ((match = itemRegex.exec(xml)) !== null && count < 20) {
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
                var seed = root.inSearchMode ? root.searchQuery : "news"
                img = "https://loremflickr.com/500/300/" + encodeURIComponent(seed) + "?lock=" + count
            }

            var time = "Hoy"
            if (d) {
                var diff = new Date() - new Date(d)
                var h = Math.floor(diff / 3600000)
                time = h < 1 ? Math.floor(diff / 60000) + " min" : h + " h"
            }

            var dash = t.lastIndexOf(" - ")
            if (dash > 0) t = t.substring(0, dash)

            newsModel.append({
                "title": decodeHtml(t),
                "link": l,
                "source": s,
                "time": time,
                "image": img
            })
            count++
        }
    }

    function decodeHtml(s) {
        return s
            .replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&#39;/g, "'")
    }
}

