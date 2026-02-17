import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.modules.common            // Appearance.*
import qs.modules.common.widgets

Rectangle {
    id: root
    required property var theme

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 580
    Layout.minimumHeight: 420

    radius: 32
    clip: true


    readonly property color surface0: Appearance.colors.colLayer0
    readonly property color surface1: Appearance.colors.colLayer1
    readonly property color border0: Appearance.colors.colLayer0Border
    readonly property color onSurface: Appearance.colors.colOnLayer0
    readonly property color onSurfaceMuted: Qt.rgba(onSurface.r, onSurface.g, onSurface.b, 0.75)


    readonly property color accent: (root.theme && root.theme.colAccent) ? root.theme.colAccent : Qt.rgba(0.45, 0.65, 1.0, 1.0)
    readonly property string fontMain: (root.theme && root.theme.fontMain) ? root.theme.fontMain : ""

    color: root.surface1
    border.width: 1
    border.color: root.border0

    // WEBZ.IO CONFIG (News API Lite)

    readonly property string webzToken: "18a4d11a-7092-40e6-8a50-1935c69dc127"
    readonly property string baseUrl: "https://api.webz.io/newsApiLite"

    
    ListModel { id: newsModel }

    property bool isLoading: false
    property string errorText: ""
    property string lastUpdated: ""

    readonly property int maxAgeHours: 6
    property bool onlyRecent: true

    property int maxItems: 45
    property bool dedupeByLink: true
    property var _buffer: ([])

    property string activeTab: "TOP"   // TOP | SV | WORLD | SPORTS
    property string activeSort: "NEW"  // NEW | SOURCE

    // Reintentos para evitar 500 por query compleja
    property int _attemptIndex: 0
    property var _attemptQueries: ([])


    function baseQ() { return "language:spanish " }

    function primaryQueryForTab(tab) {
        switch (tab) {
        case "SV":     return baseQ() + "El Salvador"
        case "WORLD":  return baseQ() + "noticias internacionales"
        case "SPORTS": return baseQ() + "deportes"
        default:       return baseQ() + "noticias destacadas"
        }
    }

    function fallbackQueriesForTab(tab) {
        var q1 = primaryQueryForTab(tab)
        var q2 = baseQ() + (tab === "SPORTS" ? "futbol" :
                           tab === "WORLD" ? "mundo" :
                           tab === "SV" ? "San Salvador" :
                           "noticias")
        var q3 = "language:spanish"
        var q4 = (tab === "SPORTS" ? "deportes" :
                 tab === "WORLD" ? "internacional" :
                 tab === "SV" ? "El Salvador" :
                 "noticias")
        return [q1, q2, q3, q4]
    }

    // --------------------------
    function refresh() {
        if (root.isLoading) return
        root.isLoading = true
        root.errorText = ""
        root.lastUpdated = ""

        newsModel.clear()
        root._buffer = []

        if (!root.webzToken || root.webzToken.trim() === "") {
            root.isLoading = false
            root.errorText = "Falta configurar el token de Webz.io."
            return
        }

        root._attemptQueries = fallbackQueriesForTab(root.activeTab)
        root._attemptIndex = 0
        fetchAttempt()
    }

    function fetchAttempt() {
        if (root._attemptIndex >= root._attemptQueries.length) {
            root.isLoading = false
            if (root.errorText === "") root.errorText = "No se pudo obtener noticias (todas las consultas fallaron)."
            return
        }

        var q = root._attemptQueries[root._attemptIndex]
        var url = root.baseUrl +
                  "?token=" + encodeURIComponent(root.webzToken) +
                  "&q=" + encodeURIComponent(q)

        console.log("[WebzLite] attempt", root._attemptIndex + 1, "q=", q)

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)

        try {
            xhr.setRequestHeader("Cache-Control", "no-cache")
            xhr.setRequestHeader("Pragma", "no-cache")
            xhr.setRequestHeader("Accept", "application/json")
        } catch (e) {}

        xhr.timeout = 12000

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status === 200 && xhr.responseText) {
                try {
                    var response = JSON.parse(xhr.responseText)
                    parseWebzLiteJson(response)
                    finalize()

                    root.isLoading = false
                    root.lastUpdated = nowHHMM()

                    if (newsModel.count === 0) {
                        if (root.onlyRecent) {
                            root.errorText = "Sin resultados recientes. Probando sin filtro de tiempo..."
                            root.onlyRecent = false
                            root._attemptIndex = 0
                            fetchAttempt()
                            return
                        }
                        root.errorText = "Sin resultados."
                    }
                    return
                } catch (e) {
                    console.log("[WebzLite] JSON error:", e)
                }
            } else {
                var msg = ("Error Webz.io (" + xhr.status + ").")
                console.log("[WebzLite] HTTP error:", xhr.status, xhr.responseText)
                root.errorText = msg
            }

            root._attemptIndex = root._attemptIndex + 1
            fetchAttempt()
        }

        xhr.ontimeout = function() {
            console.log("[WebzLite] timeout")
            root.errorText = "Tiempo de espera agotado."
            root._attemptIndex = root._attemptIndex + 1
            fetchAttempt()
        }

        xhr.send()
    }

    function parseWebzLiteJson(response) {
        var posts = response && response.posts ? response.posts : []
        if (!posts || posts.length === 0) return

        var limit = Math.min(posts.length, 200)

        for (var i = 0; i < limit; i++) {
            var post = posts[i]
            if (!post) continue

            var title = cleanText(post.title || "")
            var url = (post.url || "").trim()
            if (!title || !url) continue

            var source = "Noticias"
            if (post.thread) source = cleanText(post.thread.site_full || post.thread.site || source)

            var published = post.published || post.published_at || post.created || ""
            var ts = parseDateToMs(published)

            if (root.onlyRecent) {
                if (ts <= 0) continue
                var ageHours = (Date.now() - ts) / 3600000
                if (ageHours > root.maxAgeHours) continue
                if (ageHours < -2) continue
            }

            var img = ""
            if (post.thread) img = (post.thread.main_image || "").trim()
            if (!img) img = "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&q=80"

            var rgb = sourceColor01(source)

            root._buffer.push({
                title: title,
                source: source,
                tagR: rgb.r, tagG: rgb.g, tagB: rgb.b,
                time: timeSinceMs(ts),
                image: img,
                url: url,
                ts: ts
            })
        }
    }

    function finalize() {
        if (root.activeSort === "SOURCE") {
            root._buffer.sort(function(a, b) {
                var sa = (a.source || "")
                var sb = (b.source || "")
                if (sa < sb) return -1
                if (sa > sb) return 1
                return (b.ts || 0) - (a.ts || 0)
            })
        } else {
            root._buffer.sort(function(a, b) { return (b.ts || 0) - (a.ts || 0) })
        }

        var out = []
        var seen = {}
        for (var i = 0; i < root._buffer.length; i++) {
            var it = root._buffer[i]
            if (!it || !it.url) continue

            if (root.dedupeByLink) {
                if (seen[it.url]) continue
                seen[it.url] = true
            }

            out.push(it)
            if (out.length >= root.maxItems) break
        }

        newsModel.clear()
        for (var j = 0; j < out.length; j++) newsModel.append(out[j])
    }


    function cleanText(text) {
        if (!text) return ""
        text = ("" + text)
        text = text.replace(/&amp;/g, "&")
                   .replace(/&lt;/g, "<")
                   .replace(/&gt;/g, ">")
                   .replace(/&quot;/g, "\"")
                   .replace(/&#39;/g, "'")
                   .replace(/&nbsp;/g, " ")
        text = text.replace(/<[^>]*>?/gm, "")
        return text.trim()
    }

    function parseDateToMs(dateStr) {
        if (!dateStr) return 0
        var d = new Date(dateStr)
        if (!isNaN(d.getTime())) return d.getTime()
        var iso = ("" + dateStr).trim()
        var d2 = new Date(iso)
        if (!isNaN(d2.getTime())) return d2.getTime()
        return 0
    }

    function timeSinceMs(ts) {
        if (!ts || ts <= 0) return ""
        var seconds = Math.floor((Date.now() - ts) / 1000)
        if (seconds < 45) return "Ahora"
        var minutes = Math.floor(seconds / 60)
        if (minutes < 60) return minutes + "m"
        var hours = Math.floor(minutes / 60)
        if (hours < 24) return hours + "h"
        return Math.floor(hours / 24) + "d"
    }

    function nowHHMM() {
        var d = new Date()
        return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
    }

    function openLink(url) { Qt.openUrlExternally(url) }

    function hashStr(s) {
        s = s || ""
        var h = 2166136261
        for (var i = 0; i < s.length; i++) {
            h ^= s.charCodeAt(i)
            h += (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24)
        }
        return h >>> 0
    }

    function sourceColor01(source) {
        var h = hashStr(source)
        var r = ((h >> 16) & 255) / 255.0
        var g = ((h >> 8) & 255) / 255.0
        var b = (h & 255) / 255.0
        return {
            r: (r * 0.55 + root.accent.r * 0.45),
            g: (g * 0.55 + root.accent.g * 0.45),
            b: (b * 0.55 + root.accent.b * 0.45)
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // HEADER
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + 28
            radius: 22


            color: root.surface0
            border.width: 1
            border.color: root.border0
            clip: true

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 44; height: 44; radius: 16
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "breaking_news"
                            font.pixelSize: 22
                            color: root.accent
                            opacity: 0.95
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "Noticias (Webz.io · ES)"
                            font.family: root.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Black
                            color: root.onSurface
                        }

                        RowLayout {
                            spacing: 10
                            Text {
                                text: root.isLoading ? "Conectando..." :
                                      (root.lastUpdated !== "" ? ("Actualizado " + root.lastUpdated) : "Listo")
                                font.family: root.fontMain
                                font.pixelSize: 11
                                color: root.onSurfaceMuted
                                opacity: 0.90
                            }

                            Rectangle {
                                height: 18
                                radius: 9
                                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                                width: badge.implicitWidth + 14

                                Text {
                                    id: badge
                                    anchors.centerIn: parent
                                    text: newsModel.count + " items"
                                    font.family: root.fontMain
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: root.onSurface
                                    opacity: 0.9
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Toggle sort
                    Rectangle {
                        width: 44; height: 44; radius: 16
                        color: root.surface0
                        border.width: 1
                        border.color: root.border0

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.activeSort === "NEW" ? "schedule" : "sort_by_alpha"
                            font.pixelSize: 20
                            color: root.onSurface
                            opacity: 0.88
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeSort = (root.activeSort === "NEW") ? "SOURCE" : "NEW"
                                var tmp = []
                                for (var i = 0; i < newsModel.count; i++) tmp.push(newsModel.get(i))
                                root._buffer = tmp
                                finalize()
                            }
                        }
                    }

                    // Refresh
                    Rectangle {
                        width: 44; height: 44; radius: 16
                        color: root.surface0
                        border.width: 1
                        border.color: root.border0

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.isLoading ? "progress_activity" : "refresh"
                            font.pixelSize: 20
                            color: root.onSurface
                            opacity: 0.92
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.isLoading
                            onClicked: root.refresh()
                        }
                    }
                }

                // Tabs
                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 21
                    color: root.surface0
                    border.width: 1
                    border.color: root.border0
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        SegButton { text: "Top"; key: "TOP" }
                        SegButton { text: "El Salvador"; key: "SV" }
                        SegButton { text: "Mundo"; key: "WORLD" }
                        SegButton { text: "Deportes"; key: "SPORTS" }
                    }
                }
            }
        }

        // CONTENT
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: newsList
                anchors.fill: parent
                model: newsModel
                spacing: 12
                clip: true
                visible: !root.isLoading && newsModel.count > 0
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 2; color: root.accent; opacity: 0.22 }
                }

                delegate: SwipeDelegate {
                    id: del
                    width: newsList.width - 8
                    height: 112
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 22

                         color: del.hovered
                            ? Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.07)
                            : root.surface0

                        border.width: 1
                        border.color: root.border0
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            radius: 20
                            color: Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.06)
                            border.width: 1
                            border.color: root.border0
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: model.image
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                opacity: 0.95
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 6

                            Text {
                                text: model.title
                                font.family: root.fontMain
                                font.weight: Font.Bold
                                font.pixelSize: 13
                                color: root.onSurface
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 3
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    height: 22
                                    radius: 10
                                    width: srcText.implicitWidth + 16
                                    color: Qt.rgba(model.tagR, model.tagG, model.tagB, 0.16)
                                    border.width: 1
                                    border.color: Qt.rgba(model.tagR, model.tagG, model.tagB, 0.22)

                                    Text {
                                        id: srcText
                                        anchors.centerIn: parent
                                        text: model.source
                                        font.family: root.fontMain
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: root.onSurface
                                        opacity: 0.92
                                    }
                                }

                                RowLayout {
                                    spacing: 4
                                    MaterialSymbol { text: "schedule"; font.pixelSize: 12; color: root.onSurfaceMuted; opacity: 0.75 }
                                    Text {
                                        text: model.time
                                        font.family: root.fontMain
                                        font.pixelSize: 11
                                        color: root.onSurfaceMuted
                                        opacity: 0.82
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                MaterialSymbol {
                                    text: "chevron_right"
                                    font.pixelSize: 20
                                    color: root.onSurfaceMuted
                                    opacity: del.hovered ? 0.9 : 0.55
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }
                            }
                        }
                    }

                    onClicked: root.openLink(model.url)
                }
            }

            // Loading / empty overlays
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                visible: root.isLoading || (!root.isLoading && newsModel.count === 0)

                MaterialSymbol {
                    text: root.isLoading ? "progress_activity" : "rss_feed"
                    font.pixelSize: 34
                    color: root.onSurfaceMuted
                    opacity: 0.75
                }

                Text {
                    text: root.isLoading ? "Cargando..." :
                          (root.errorText !== "" ? root.errorText : "Sin noticias")
                    font.family: root.fontMain
                    font.pixelSize: 13
                    color: root.onSurfaceMuted
                    opacity: 0.90
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: !root.isLoading && root.errorText.indexOf("500") >= 0
                    text: "Sugerencia: la API Lite suele dar 500 si la consulta tiene OR, comillas o paréntesis. Esta versión reintenta con consultas simples."
                    font.family: root.fontMain
                    font.pixelSize: 11
                    color: root.onSurfaceMuted
                    opacity: 0.70
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: Math.min(parent.width, 420)
                }
            }
        }
    }

    component SegButton: Rectangle {
        property string text: ""
        property string key: ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16

        property bool active: root.activeTab === key

        color: active ? root.accent : "transparent"
        border.width: 1
        border.color: active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35) : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.family: root.fontMain
            font.pixelSize: 12
            font.bold: true
            color: active ? "#000000" : root.onSurface
            opacity: active ? 1.0 : 0.78
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.activeTab === parent.key) return
                root.activeTab = parent.key
                root.refresh()
            }
        }
    }
}

