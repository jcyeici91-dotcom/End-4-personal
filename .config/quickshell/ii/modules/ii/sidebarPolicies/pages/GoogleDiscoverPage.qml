pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Item {
    id: root
    implicitHeight: mainLayout.implicitHeight

    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }
    function _rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    readonly property bool themeIsDark: (Appearance.m3colors && Appearance.m3colors.darkmode !== undefined)
        ? Appearance.m3colors.darkmode
        : _isDark(Appearance.colors.colLayer0)

    function _pickOn(bg) { return _isDark(bg) ? Qt.rgba(1, 1, 1, 1) : Qt.rgba(0, 0, 0, 1) }
    function _ensureReadable(fg, bg, minDelta) {
        var d = Math.abs(_lin(fg) - _lin(bg))
        return (d >= (minDelta || 0.25)) ? fg : _pickOn(bg)
    }

    function _hex2(n) {
        n = Math.max(0, Math.min(255, Math.round(n)))
        var s = n.toString(16)
        return (s.length === 1) ? ("0" + s) : s
    }
    function _toHex(c) { return "#" + _hex2(c.r * 255) + _hex2(c.g * 255) + _hex2(c.b * 255) }

    readonly property color bgPill: (Appearance.m3colors && Appearance.m3colors.m3surfaceContainerLow !== undefined)
        ? Appearance.m3colors.m3surfaceContainerLow
        : Appearance.colors.colLayer1

    readonly property color bgWidget: (Appearance.m3colors && Appearance.m3colors.m3surfaceContainerLow !== undefined)
        ? Appearance.m3colors.m3surfaceContainerLow
        : Appearance.colors.colLayer1

    readonly property color _textMainRaw: (Appearance.colors.colOnLayer1 !== undefined) ? Appearance.colors.colOnLayer1 : _pickOn(bgWidget)
    readonly property color _textSubRaw: (Appearance.colors.colOnLayer2 !== undefined) ? Appearance.colors.colOnLayer2 : _rgba(_pickOn(bgWidget), 0.72)

    readonly property color textMain: _ensureReadable(_textMainRaw, bgWidget, 0.30)
    readonly property color textSub: _ensureReadable(_textSubRaw, bgWidget, 0.22)

    readonly property color accent: (Appearance.colors.colPrimary !== undefined) ? Appearance.colors.colPrimary : "#4285F4"

    readonly property color outlineSoft: _rgba(_ensureReadable(textMain, bgWidget, 0.18), themeIsDark ? 0.14 : 0.18)
    readonly property color surfaceSubtle: (Appearance.m3colors && Appearance.m3colors.m3surfaceContainer !== undefined)
        ? Appearance.m3colors.m3surfaceContainer
        : ((Appearance.colors.colLayer2 !== undefined) ? Appearance.colors.colLayer2 : _rgba(bgWidget, themeIsDark ? 0.92 : 0.97))

    readonly property color shadowCol: Qt.rgba(0, 0, 0, themeIsDark ? 0.40 : 0.22)

    readonly property color danger: (Appearance.colors.colError !== undefined) ? Appearance.colors.colError : "#ff4d4d"
    readonly property color success: (Appearance.colors.colSuccess !== undefined) ? Appearance.colors.colSuccess : "#34A853"
    readonly property color warn: (Appearance.colors.colWarning !== undefined) ? Appearance.colors.colWarning : "#fbbc04"

    readonly property int esOffsetMinutes: -6 * 60

    // --- MODELOS DE LIGAS (8 Bloques) ---
    ListModel { id: mSpain }
    ListModel { id: mEngland }
    ListModel { id: mGermany }
    ListModel { id: mFrance }
    ListModel { id: mItaly }
    ListModel { id: mUEFA }
    ListModel { id: mAmericas }
    ListModel { id: mIntl }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 20

        // Buscador de Google
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
                shadowColor: root.shadowCol
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                spacing: 12

                Text {
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

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    text: ""
                    color: root.textMain
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true

                    Text {
                        text: "Buscar en Google..."
                        color: root.textSub
                        font.pixelSize: 18
                        visible: !parent.text && !parent.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onAccepted: {
                        if (text.trim() !== "") {
                            procBrowser.openUrl("https://www.google.com/search?q=" + encodeURIComponent(text.trim()))
                            text = ""
                            focus = false
                        }
                    }
                }

                MaterialSymbol {
                    text: "mic"
                    color: root.accent
                    font.pixelSize: 24
                    TapHandler {
                        onTapped: {
                            if (searchInput.text.trim() !== "") {
                                procBrowser.openUrl("https://www.google.com/search?q=" + encodeURIComponent(searchInput.text.trim()))
                                searchInput.text = ""
                            }
                        }
                    }
                }

                MaterialSymbol { text: "lens_camera"; color: root.warn; font.pixelSize: 24 }
            }
        }

        // --- BLOQUES DE PARTIDOS (Se ocultan solos si no hay partidos) ---
        ScoresCarousel { titleText: "🇪🇸 España (La Liga, Copa, Supercopa)"; sourceModel: mSpain }
        ScoresCarousel { titleText: "🏴󠁧󠁢󠁥󠁮󠁧󠁿 Inglaterra (Premier, FA, Carabao)"; sourceModel: mEngland }
        ScoresCarousel { titleText: "🇩🇪 Alemania (Bundesliga, Pokal)"; sourceModel: mGermany }
        ScoresCarousel { titleText: "🇫🇷 Francia (Ligue 1, Coupe)"; sourceModel: mFrance }
        ScoresCarousel { titleText: "🇮🇹 Italia (Serie A, Coppa)"; sourceModel: mItaly }
        ScoresCarousel { titleText: "⭐ UEFA (Champions, Europa, Conference)"; sourceModel: mUEFA }
        ScoresCarousel { titleText: "🌎 América (SV, MX, BR, AR, CO, USA)"; sourceModel: mAmericas }
        ScoresCarousel { titleText: "🏆 Internacional (Mundial, Copa América, Elim.)"; sourceModel: mIntl }

        Item { Layout.preferredHeight: 10; Layout.fillWidth: true }
    }

    // Componente Carrusel Reutilizable
    component ScoresCarousel : ColumnLayout {
        property string titleText: ""
        property var sourceModel: null
        
        spacing: 8
        visible: sourceModel.count > 0
        Layout.fillWidth: true

        Text {
            text: titleText
            color: root.textMain
            font.bold: true
            font.pixelSize: 14
            Layout.leftMargin: 8
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 128

            ListView {
                id: list
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 12
                clip: true

                interactive: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 1200
                model: sourceModel

                Behavior on contentX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                function minX() { return originX }
                function maxX() { return Math.max(originX, originX + contentWidth - width) }
                function setX(x) { contentX = root.clamp(x, minX(), maxX()) }
                function clampNow() { setX(contentX) }
                function pageStepPx() { return Math.max(160, Math.floor(width * 0.85)) }
                function scrollPage(side) {
                    var step = pageStepPx()
                    if (side === "left") setX(contentX - step)
                    else setX(contentX + step)
                }

                onContentWidthChanged: Qt.callLater(clampNow)
                onWidthChanged: Qt.callLater(clampNow)
                onCountChanged: Qt.callLater(clampNow)
                onMovementEnded: clampNow

                WheelHandler {
                    target: list
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (wheel) => {
                        var dx = 0; var dy = 0;
                        if (wheel.pixelDelta) { dx = wheel.pixelDelta.x; dy = wheel.pixelDelta.y }
                        if ((dx === 0 && dy === 0) && wheel.angleDelta) { dx = wheel.angleDelta.x; dy = wheel.angleDelta.y }

                        var dominant = (Math.abs(dx) > Math.abs(dy)) ? dx : dy
                        var factor = wheel.pixelDelta && (wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0) ? 1.0 : 0.35
                        var delta = dominant * factor

                        list.setX(list.contentX - delta)
                        wheel.accepted = true
                    }
                }

                delegate: Rectangle {
                    width: 305
                    height: 118
                    radius: 16
                    color: Appearance.colors.colLayer0
                    clip: true
                    border.width: 1
                    border.color: root.outlineSoft

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: 0.65
                        shadowVerticalOffset: 1
                        shadowColor: root.shadowCol
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        z: 10

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
                                color: root.surfaceSubtle
                                border.width: 1
                                border.color: root.outlineSoft
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
                                color: root.danger
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0.2; duration: 800 }
                                    NumberAnimation { from: 0.2; to: 1; duration: 800 }
                                }
                            }

                            Text {
                                text: (model.status === "pre" && model.kickoffLocal !== "") ? model.kickoffLocal : model.statusText
                                color: model.status === "in" ? root.danger : root.textSub
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
                                color: root.surfaceSubtle
                                radius: 10
                                width: 72
                                height: 30
                                border.width: 1
                                border.color: root.outlineSoft
                                Text {
                                    anchors.centerIn: parent
                                    text: model.fullScore
                                    color: root.textMain
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

            CarouselEdgeArrow { side: "left"; list: list; visibleWhenCount: sourceModel.count; onTriggered: list.scrollPage("left") }
            CarouselEdgeArrow { side: "right"; list: list; visibleWhenCount: sourceModel.count; onTriggered: list.scrollPage("right") }
        }
    }

    component MaterialSymbol : Text { font.family: "Material Symbols Rounded" }

    component CarouselEdgeArrow : Rectangle {
        id: arrow
        property string side: "left"
        property Flickable list: null
        property int visibleWhenCount: 0
        signal triggered()

        width: 30
        height: 60
        radius: 15

        readonly property color baseBg: root.bgWidget
        readonly property color hoverBg: root.surfaceSubtle
        readonly property color fg: root._ensureReadable(root.textMain, (pressed ? hoverBg : baseBg), 0.30)

        color: pressed ? hoverBg : baseBg
        border.width: (activeFocus || hovered || pressed) ? 1.5 : 1
        border.color: (activeFocus || hovered || pressed) ? root.accent : root.outlineSoft
        visible: visibleWhenCount > 0

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: (side === "left") ? parent.left : undefined
        anchors.right: (side === "right") ? parent.right : undefined
        anchors.leftMargin: (side === "left") ? 6 : 0
        anchors.rightMargin: (side === "right") ? 6 : 0

        readonly property bool atBeginning: list ? list.atXBeginning : true
        readonly property bool atEnd: list ? list.atXEnd : true
        readonly property bool disabled: (side === "left") ? atBeginning : atEnd

        opacity: disabled ? 0.20 : 0.92
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
            shadowColor: root.shadowCol
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: (side === "left") ? "chevron_left" : "chevron_right"
            color: arrow.fg
            font.pixelSize: 22
            opacity: 0.95
        }

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
                    arrow.triggered()
                    repeatTimer.start()
                } else {
                    repeatTimer.stop()
                }
            }
            onCanceled: { arrow.pressed = false; repeatTimer.stop() }
        }

        HoverHandler { onHoveredChanged: arrow.hovered = hovered }
    }

    function clamp(v, lo, hi) {
        if (v < lo) return lo
        if (v > hi) return hi
        return v
    }

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
        } catch (e) { return NaN }
    }

    function getDayLabel(isoDate) {
        if (!isoDate) return "";
        var d = esDateFromIso(isoDate);
        if (!d) return "";
        var now = esDateFromIso(new Date().toISOString());
        
        var dDate = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        var nowDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        
        var diffTime = dDate.getTime() - nowDate.getTime();
        var diffDays = Math.round(diffTime / (1000 * 3600 * 24));
        
        if (diffDays === 0) return "HOY";
        if (diffDays === -1) return "AYER";
        if (diffDays === 1) return "MAÑANA";
        return two(d.getDate()) + "/" + two(d.getMonth() + 1);
    }

    Process {
        id: procBrowser
        function openUrl(link) {
            command = ["bash", "-c", "firefox \"" + link + "\""]
            running = true
        }
    }

    Process {
        id: procNotify
        property string appName: "Fútbol"
        property string iconName: "dialog-information"
        property int timeoutMsNormal: 7000
        property int timeoutMsImportant: 9000

        property bool useColorHints: true
        property string hintBg: root._toHex(Appearance.colors.colLayer0)
        property string hintFg: root._toHex(root.textMain)

        function send(title, body, urgency) {
            var u = urgency || "normal"
            var t = (u === "critical") ? timeoutMsImportant : timeoutMsNormal
            var hints = ""
            if (useColorHints) {
                hints = " -h string:bgcolor:" + escapeSh(hintBg) + " -h string:fgcolor:" + escapeSh(hintFg)
            }
            command = ["bash", "-lc",
                       "notify-send -a \"" + escapeSh(appName) + "\" -u " + u +
                       " -t " + t +
                       " -i \"" + escapeSh(iconName) + "\" " +
                       hints +
                       " \"" + escapeSh(title) + "\" \"" + escapeSh(body) + "\""]
            running = true
        }
    }

    function escapeSh(s) {
        return ("" + s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
    }

    Process {
        id: procMatchSummary

        property var queue: []
        property bool busy: false
        property var _job: null

        property var seenEventKeysByEvent: ({})
        property var notifiedLineupByEvent: ({})
        property var lastFetchAtByEvent: ({})

        property int liveFetchCooldownMs: 20000
        property int preFetchCooldownMs: 60000
        property int lineupWindowMinutes: 120

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

        function shouldFetch(eventId, state, eventDateIso) {
            var now = Date.now()
            var lastAt = lastFetchAtByEvent[eventId] || 0

            if (state === "in") {
                if (now - lastAt < liveFetchCooldownMs) return false
                lastFetchAtByEvent[eventId] = now
                return true
            }

            if (state === "pre") {
                if (!eventDateIso) return false
                var t = msFromIso(eventDateIso)
                if (isNaN(t)) return false
                var minsToKick = Math.floor((t - now) / 60000)
                if (minsToKick > lineupWindowMinutes) return false
                if (now - lastAt < preFetchCooldownMs) return false
                lastFetchAtByEvent[eventId] = now
                return true
            }

            return false
        }

        function request(leagueKey, eventId, leagueName, homeName, awayName, hs, as, state, eventDateIso) {
            if (!leagueKey || !eventId) return
            if (!shouldFetch(eventId, state, eventDateIso)) return

            queue.push({
                leagueKey: leagueKey, eventId: eventId, leagueName: leagueName,
                homeName: homeName, awayName: awayName, hs: hs, as: as,
                state: state, eventDateIso: eventDateIso
            })
            pump()
        }

        function pump() {
            if (busy) return
            if (queue.length === 0) return
            busy = true

            _job = queue.shift()
            var url = "https://site.api.espn.com/apis/site/v2/sports/soccer/" + _job.leagueKey + "/summary?event=" + _job.eventId
            command = ["curl", "-s", "-L", url]
            running = true
        }

        function normalizeType(t) {
            t = (t || "").toString().toLowerCase()
            if (t.indexOf("yellow") !== -1) return "yellow"
            if (t.indexOf("red") !== -1) return "red"
            if (t.indexOf("sub") !== -1) return "sub"
            if (t.indexOf("goal") !== -1 || t.indexOf("gol") !== -1) return "goal"
            return "other"
        }

        function extractClock(ev) { return safe(ev, "clock.displayValue", "") || safe(ev, "time", "") || "" }
        function extractText(ev) { return safe(ev, "text", "") || safe(ev, "shortText", "") || safe(ev, "description", "") || "" }

        function eventKey(ev) {
            var t = safe(ev, "type.text", "") || safe(ev, "type", "")
            var clock = extractClock(ev)
            var txt = extractText(ev)
            return (t + "|" + clock + "|" + txt).trim()
        }

        function ensureSeenMap(eventId) {
            if (!seenEventKeysByEvent[eventId]) seenEventKeysByEvent[eventId] = ({})
            return seenEventKeysByEvent[eventId]
        }

        function notifyCard(job, cardKind, text, clock) {
            if (!job) return
            var title = (cardKind === "red") ? "Tarjeta roja" : "Tarjeta amarilla"
            var body = job.homeName + " " + job.hs + " - " + job.as + " " + job.awayName + "\n" + job.leagueName
            if (clock) body += "\nMinuto: " + clock
            if (text) body += "\n" + text
            procNotify.send(title, body, "critical")
        }

        function notifySub(job, text, clock) {
            if (!job) return
            var title = "Cambio"
            var body = job.homeName + " " + job.hs + " - " + job.as + " " + job.awayName + "\n" + job.leagueName
            if (clock) body += "\nMinuto: " + clock
            if (text) body += "\n" + text
            procNotify.send(title, body, "normal")
        }

        function stringifyLineupTeam(teamObj) {
            var name = safe(teamObj, "team.displayName", "") || safe(teamObj, "team.shortDisplayName", "") || ""
            var formation = safe(teamObj, "formation", "") || safe(teamObj, "team.formation", "") || ""

            var players = safe(teamObj, "players", [])
            var starters = []
            if (Array.isArray(players)) {
                for (var i = 0; i < players.length; i++) {
                    var group = players[i]
                    var gname = (safe(group, "displayName", "") + "").toLowerCase()
                    if (gname.indexOf("starter") === -1 && gname.indexOf("titular") === -1) continue
                    var ath = safe(group, "athletes", [])
                    if (Array.isArray(ath)) {
                        for (var k = 0; k < ath.length; k++) {
                            var pn = safe(ath[k], "athlete.shortName", "") || safe(ath[k], "athlete.displayName", "")
                            if (pn) starters.push(pn)
                        }
                    }
                }
            }

            var header = name
            if (formation) header += " (" + formation + ")"

            if (starters.length >= 7) return header + ":\n- " + starters.slice(0, 11).join("\n- ")
            return ""
        }

        function maybeNotifyLineups(job, json) {
            if (!job) return
            if (job.state !== "pre") return
            if (notifiedLineupByEvent[job.eventId] === true) return
            if (!procScores.initializedOnce) return

            var teams = safe(json, "boxscore.teams", [])
            if (!Array.isArray(teams) || teams.length < 2) return

            var a = stringifyLineupTeam(teams[0])
            var b = stringifyLineupTeam(teams[1])
            if (!a && !b) return

            notifiedLineupByEvent[job.eventId] = true

            var title = "Alineaciones Confirmadas"
            var body = job.homeName + " vs " + job.awayName + "\n" + job.leagueName
            if (a) body += "\n\n" + a
            if (b) body += "\n\n" + b

            procNotify.send(title, body, "normal")
        }

        function processKeyEvents(job, json) {
            if (!job) return
            if (!procScores.initializedOnce) return

            var keyEvents = safe(json, "keyEvents", [])
            if (!Array.isArray(keyEvents) || keyEvents.length === 0) return

            var seen = ensureSeenMap(job.eventId)

            for (var i = 0; i < keyEvents.length; i++) {
                var ev = keyEvents[i]
                var k = eventKey(ev)
                if (!k) continue
                if (seen[k] === true) continue
                seen[k] = true

                var typeText = safe(ev, "type.text", "") || ""
                var kind = normalizeType(typeText)
                var clock = extractClock(ev)
                var txt = extractText(ev)

                if (kind === "yellow") notifyCard(job, "yellow", txt || typeText, clock)
                else if (kind === "red") notifyCard(job, "red", txt || typeText, clock)
                else if (kind === "sub") notifySub(job, txt || typeText, clock)
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var job = procMatchSummary._job
                procMatchSummary._job = null

                try {
                    var json = JSON.parse(text)
                    procMatchSummary.maybeNotifyLineups(job, json)
                    procMatchSummary.processKeyEvents(job, json)
                } catch (e) { }

                procMatchSummary.busy = false
                procMatchSummary.pump()
            }
        }
    }

    Process {
        id: procGoalDetails

        property var queue: []
        property bool busy: false
        property var lastGoalKeyByEvent: ({})

        function request(leagueKey, eventId, leagueName, homeName, awayName, hs, as, detail) {
            if (!eventId || !leagueKey) return
            queue.push({
                leagueKey: leagueKey, eventId: eventId, leagueName: leagueName,
                homeName: homeName, awayName: awayName, hs: hs, as: as, detail: detail
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
                   safe(ev, "player.displayName", "") || ""
        }

        function extractTeam(ev) {
            return safe(ev, "team.displayName", "") ||
                   safe(ev, "team.shortDisplayName", "") ||
                   safe(ev, "competitor.displayName", "") || ""
        }

        function extractClock(ev) { return safe(ev, "clock.displayValue", "") || safe(ev, "time", "") || "" }

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

                        procNotify.send(title, body, "critical")
                    }
                } catch (e) {
                    if (j) {
                        var title2 = "GOOOL"
                        var body2 = j.homeName + " " + j.hs + " - " + j.as + " " + j.awayName + "\n" + j.leagueName
                        if (j.detail && j.detail !== "") body2 += "\n" + j.detail
                        procNotify.send(title2, body2, "critical")
                    }
                }

                procGoalDetails.busy = false
                procGoalDetails.pump()
            }
        }
    }

    Process {
        id: procScores

        // Lista completa y categorizada de torneos
        property var leagues: [
            // España
            { group: "spain", key: "esp.1", name: "La Liga" },
            { group: "spain", key: "esp.copa_del_rey", name: "Copa del Rey" },
            { group: "spain", key: "esp.super_cup", name: "Supercopa de España" },
            // Inglaterra
            { group: "england", key: "eng.1", name: "Premier League" },
            { group: "england", key: "eng.fa", name: "FA Cup" },
            { group: "england", key: "eng.league_cup", name: "EFL Cup" },
            // Alemania
            { group: "germany", key: "ger.1", name: "Bundesliga" },
            { group: "germany", key: "ger.dfb_pokal", name: "DFB Pokal" },
            // Francia
            { group: "france", key: "fra.1", name: "Ligue 1" },
            { group: "france", key: "fra.coupe_de_france", name: "Coupe de France" },
            // Italia
            { group: "italy", key: "ita.1", name: "Serie A" },
            { group: "italy", key: "ita.coppa_italia", name: "Coppa Italia" },
            // UEFA
            { group: "uefa", key: "uefa.champions", name: "Champions League" },
            { group: "uefa", key: "uefa.europa", name: "Europa League" },
            { group: "uefa", key: "uefa.europa.conf", name: "Conference League" },
            { group: "uefa", key: "uefa.super_cup", name: "Supercopa UEFA" },
            // América
            { group: "americas", key: "slv.1", name: "Primera División SV" },
            { group: "americas", key: "mex.1", name: "Liga MX" },
            { group: "americas", key: "bra.1", name: "Brasileirão" },
            { group: "americas", key: "col.1", name: "Liga BetPlay" },
            { group: "americas", key: "arg.1", name: "Liga Profesional AR" },
            { group: "americas", key: "usa.1", name: "MLS" },
            // Internacional
            { group: "intl", key: "fifa.world", name: "Copa Mundial" },
            { group: "intl", key: "conmebol.america", name: "Copa América" },
            { group: "intl", key: "fifa.worldq.conmebol", name: "Elim. CONMEBOL" },
            { group: "intl", key: "fifa.worldq.concacaf", name: "Elim. CONCACAF" },
            { group: "intl", key: "fifa.worldq.uefa", name: "Elim. UEFA" }
        ]

        property int leagueIndex: 0
        property bool loading: false
        property var pendingScores: []
        property var seenIds: ({})
        property bool initializedOnce: false

        property var lastScoreByEvent: ({})
        property var lastNotifyAtByEvent: ({})
        property var notifiedPreByEvent: ({})
        property var notifiedFinalByEvent: ({})
        property var lastStateByEvent: ({})

        property int preNotifyMinutes: 10
        property int preWindowMs: 90000
        property int goalCooldownMs: 5000

        function startLoadScores() {
            if (loading) return
            loading = true
            pendingScores = []
            seenIds = ({})
            leagueIndex = 0
            loadNext()
        }

        function loadNext() {
            if (leagueIndex >= leagues.length) { finalizeScores(); return }

            var lg = leagues[leagueIndex]
            // Usamos la URL sin fechas para que ESPN devuelva la jornada actual automáticamente. Ultra rápido.
            var url = "https://site.api.espn.com/apis/site/v2/sports/soccer/" + lg.key + "/scoreboard"

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
                procNotify.send(title, body, "normal")
            }
        }

        function maybeNotifyFinal(eventId, leagueName, homeName, awayName, hs, as) {
            if (!eventId) return
            if (notifiedFinalByEvent[eventId] === true) return
            if (!initializedOnce) return

            notifiedFinalByEvent[eventId] = true
            var title = "Final: " + homeName + " " + hs + " - " + as + " " + awayName
            procNotify.send(title, leagueName, "normal")
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

            // Ordenamos todos los partidos
            pendingScores.sort(function(a, b) {
                var ra = statusRank(a.status)
                var rb = statusRank(b.status)
                if (ra !== rb) return ra - rb

                var ta = timeRank(a.eventDate)
                var tb = timeRank(b.eventDate)
                if (ta !== tb) return ta - tb

                return (a.statusText || "").localeCompare(b.statusText || "")
            })

            // Limpiamos los 8 modelos
            mSpain.clear(); mEngland.clear(); mGermany.clear(); mFrance.clear();
            mItaly.clear(); mUEFA.clear(); mAmericas.clear(); mIntl.clear();

            // Repartimos los partidos a su bloque correspondiente
            for (var i = 0; i < pendingScores.length; i++) {
                var item = pendingScores[i]
                var grp = item.group

                if (grp === "spain") mSpain.append(item)
                else if (grp === "england") mEngland.append(item)
                else if (grp === "germany") mGermany.append(item)
                else if (grp === "france") mFrance.append(item)
                else if (grp === "italy") mItaly.append(item)
                else if (grp === "uefa") mUEFA.append(item)
                else if (grp === "americas") mAmericas.append(item)
                else if (grp === "intl") mIntl.append(item)
            }

            loading = false
            initializedOnce = true
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var lg = procScores.leagues[procScores.leagueIndex]

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
                        var dayLabelStr = ""
                        
                        if (eventDate !== "") {
                            kickoffLocal = fmtTimeES(eventDate)
                            kickoffDetail = fmtDetailES(eventDate)
                            dayLabelStr = getDayLabel(eventDate)
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

                        procMatchSummary.request(lg.key, eid, lg.name, homeName, awayName, hs, as, state, eventDate)

                        var scoreStr = (state === "pre") ? "vs" : (hs + " - " + as)
                        var linkUrl = procScores.safe(e, "links.0.href", "https://www.google.com/search?q=" + encodeURIComponent(homeName + " vs " + awayName))

                        procScores.pendingScores.push({
                            "id": eid,
                            "group": lg.group,
                            "leagueKey": lg.key,
                            "league": lg.name,
                            "dayLabel": dayLabelStr,
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
                } catch (err) {
                    console.log("Error parsing scores (" + lg.name + "): " + err)
                }

                procScores.leagueIndex++
                procScores.loadNext()
            }
        }
    }

    // Actualiza los resultados cada 2 minutos (óptimo para no colapsar peticiones y tener en vivo)
    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: procScores.startLoadScores()
    }

    Component.onCompleted: {
        procScores.startLoadScores()
    }
}
