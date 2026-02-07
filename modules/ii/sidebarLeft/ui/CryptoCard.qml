import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

import Quickshell
import Quickshell.Io

import qs.modules.common            // Appearance.*
import qs.modules.common.widgets

Rectangle {
    id: root
    required property var theme

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 380
    Layout.minimumHeight: 380

    radius: 28
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

    // ---- Data ----
    ListModel { id: cryptoModel }
    ListModel { id: filteredModel }

    property bool isOffline: true
    property bool isLoading: false
    property bool searchMode: false
    property string searchQuery: ""
    property string sortMode: "VOL"       // VOL | GAIN | LOSS | FAV
    property int limitCoins: 150
    property string lastUpdated: ""
    property string apiUrl: "https://api.binance.com/api/v3/ticker/24hr"

    // ---- Favoritos 
    property var favoritesMap: ({})
    property int favoritesRevision: 0

    function isFavorite(sym) {
        var _rev = root.favoritesRevision // fuerza binding reactivo
        if (!sym) return false
        return !!root.favoritesMap[sym]
    }

    function toggleFavorite(sym) {
        if (!sym) return

        var next = {}
        var cur = root.favoritesMap
        for (var k in cur) next[k] = cur[k]

        if (next[sym]) delete next[sym]
        else next[sym] = true

        root.favoritesMap = next
        root.favoritesRevision = root.favoritesRevision + 1

        if (root.sortMode === "FAV") filterList(root.searchQuery)
    }

      function nowHHMM() {
        var d = new Date()
        return (d.getHours().toString().padStart(2, "0")) + ":" + (d.getMinutes().toString().padStart(2, "0"))
    }

    function formatPrice(price) {
        var p = Number(price)
        if (!isFinite(p)) return "$--"
        if (p < 0.0001) return "$" + p.toFixed(8)
        if (p < 1) return "$" + p.toFixed(5)
        if (p > 1000) return "$" + p.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return "$" + p.toFixed(2)
    }

    function normalizeRows(binanceArray) {
        var temp = []
        for (var i = 0; i < binanceArray.length; i++) {
            var it = binanceArray[i]
            if (!it.symbol || !it.symbol.endsWith("USDT")) continue

            var raw = it.symbol.replace("USDT", "")
            if (raw.indexOf("UP") !== -1 || raw.indexOf("DOWN") !== -1) continue
            if (raw.indexOf("BULL") !== -1 || raw.indexOf("BEAR") !== -1) continue

            var vol = parseFloat(it.quoteVolume)
            var chg = parseFloat(it.priceChangePercent)
            var last = parseFloat(it.lastPrice)

            temp.push({
                name: raw,
                pair: "USDT",
                priceNum: last,
                price: formatPrice(last),
                changeNum: chg,
                change: (chg > 0 ? "+" : "") + (isFinite(chg) ? chg.toFixed(2) : "0.00") + "%",
                isUp: isFinite(chg) ? (chg >= 0) : true,
                vol: isFinite(vol) ? vol : 0
            })

            if (temp.length >= root.limitCoins) break
        }
        return temp
    }

    function sortRows(rows) {
        if (root.sortMode === "GAIN") rows.sort(function(a, b) { return b.changeNum - a.changeNum })
        else if (root.sortMode === "LOSS") rows.sort(function(a, b) { return a.changeNum - b.changeNum })
        else rows.sort(function(a, b) { return b.vol - a.vol })
    }

    function applyModel(rows) {
        cryptoModel.clear()
        for (var i = 0; i < rows.length; i++) cryptoModel.append(rows[i])
        filterList(root.searchQuery)
    }

    function filterList(query) {
        root.searchQuery = query || ""
        filteredModel.clear()

        var q = root.searchQuery.toUpperCase().trim()
        for (var i = 0; i < cryptoModel.count; i++) {
            var item = cryptoModel.get(i)

            if (root.sortMode === "FAV" && !root.isFavorite(item.name))
                continue

            if (q === "" || (item.name && item.name.indexOf(q) !== -1))
                filteredModel.append(item)
        }
    }

    function refreshData() {
        if (root.isLoading) return
        root.isLoading = true
        apiProcess.running = true
    }

    Process {
        id: apiProcess
        command: ["bash", "-c", "curl -s -k '" + root.apiUrl + "'"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false
                if (text.trim() === "") { root.isOffline = true; return }

                try {
                    var data = JSON.parse(text)
                    if (!Array.isArray(data)) { root.isOffline = true; return }

                    root.isOffline = false
                    var rows = normalizeRows(data)
                    sortRows(rows)
                    applyModel(rows)
                    root.lastUpdated = nowHHMM()
                } catch (e) {
                    console.error("Crypto JSON Error:", e)
                    root.isOffline = true
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: refreshData()
    }

    function loadMockData() {
        if (cryptoModel.count > 0 || filteredModel.count > 0) return
        applyModel([
            { name: "BTC", pair: "USDT", priceNum: 0, price: "$--,--", changeNum: 1.2, change: "+1.20%", isUp: true, vol: 0 },
            { name: "ETH", pair: "USDT", priceNum: 0, price: "$--,--", changeNum: -0.8, change: "-0.80%", isUp: false, vol: 0 },
            { name: "SOL", pair: "USDT", priceNum: 0, price: "$--,--", changeNum: 0.3, change: "+0.30%", isUp: true, vol: 0 }
        ])
    }

    Component.onCompleted: {
        loadMockData()
        refreshData()
    }

    // UI CONTENT
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ---- Top bar ----
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            StackLayout {
                anchors.fill: parent
                currentIndex: root.searchMode ? 1 : 0

                // Normal header
                Item {
                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            width: 42; height: 42; radius: 16
                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                            border.width: 1
                            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "currency_bitcoin"
                                font.pixelSize: 22
                                color: root.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Crypto Market"
                                font.family: root.fontMain
                                font.weight: Font.Black
                                font.pixelSize: 16
                                color: root.onSurface
                            }
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 7; height: 7; radius: 4; color: root.isOffline ? "#ff7675" : "#00d084"; opacity: 0.95 }
                                Text {
                                    text: root.isOffline ? "Offline" : "Live"
                                    font.family: root.fontMain
                                    font.pixelSize: 11
                                    color: root.isOffline ? root.onSurfaceMuted : "#00d084"
                                    opacity: root.isOffline ? 0.75 : 0.95
                                }
                                Text {
                                    visible: !root.isOffline && root.lastUpdated !== ""
                                    text: "· " + root.lastUpdated
                                    font.family: root.fontMain
                                    font.pixelSize: 11
                                    color: root.onSurfaceMuted
                                    opacity: 0.6
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        IconPillButton {
                            symbol: "search"
                            onClicked: { root.searchMode = true; searchInput.forceActiveFocus() }
                        }

                        IconPillButton {
                            symbol: root.isLoading ? "progress_activity" : "refresh"
                            enabled: !root.isLoading
                            onClicked: refreshData()
                        }
                    }
                }

                // Search header
                Item {
                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 16

                            // Igual filosofía Vitality: superficie + borde del sistema
                            color: root.surface0
                            border.width: 1
                            border.color: searchInput.activeFocus
                                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.40)
                                : root.border0

                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 8

                                MaterialSymbol {
                                    text: "search"
                                    font.pixelSize: 18
                                    color: root.onSurfaceMuted
                                    opacity: 0.8
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: root.fontMain
                                        font.pixelSize: 14
                                        color: root.onSurface
                                        selectByMouse: true
                                        selectionColor: root.accent
                                        onTextChanged: filterList(text)
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Buscar (BTC, ETH...)"
                                        font.family: root.fontMain
                                        font.pixelSize: 14
                                        color: root.onSurfaceMuted
                                        opacity: 0.55
                                        elide: Text.ElideRight
                                        visible: searchInput.text === "" && !searchInput.activeFocus
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 10
                                    color: Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.06)
                                    border.width: 1
                                    border.color: root.border0

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        font.pixelSize: 16
                                        color: root.onSurfaceMuted
                                        opacity: 0.9
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { searchInput.text = ""; filterList("") }
                                    }
                                }
                            }
                        }

                        IconPillButton {
                            symbol: "done"
                            onClicked: { root.searchMode = false; searchInput.focus = false }
                        }
                    }
                }
            }
        }

        // ---- Chips ----
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: chipRow.implicitWidth
            contentHeight: height
            interactive: contentWidth > width

            Row {
                id: chipRow
                height: parent.height
                spacing: 10

                FilterChip { text: "Volumen";    active: root.sortMode === "VOL";  onClicked: { root.sortMode = "VOL";  refreshData() } }
                FilterChip { text: "Ganadoras";  active: root.sortMode === "GAIN"; onClicked: { root.sortMode = "GAIN"; refreshData() } }
                FilterChip { text: "Perdedoras"; active: root.sortMode === "LOSS"; onClicked: { root.sortMode = "LOSS"; refreshData() } }

                FilterChip {
                    text: "Favoritos"
                    active: root.sortMode === "FAV"
                    onClicked: {
                        root.sortMode = "FAV"
                        filterList(root.searchQuery)
                    }
                }

                Rectangle {
                    height: 32
                    radius: 16
                    color: root.surface0
                    border.width: 1
                    border.color: root.border0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialSymbol { text: "numbers"; font.pixelSize: 16; color: root.onSurfaceMuted; opacity: 0.7 }
                        Text {
                            text: filteredModel.count + " coins"
                            font.family: root.fontMain
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: root.onSurfaceMuted
                            opacity: 0.9
                        }
                    }
                }
            }
        }

        // ---- List container ----
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 22
            color: root.surface0
            border.width: 1
            border.color: root.border0
            clip: true

            Text {
                anchors.centerIn: parent
                visible: !root.isLoading && filteredModel.count === 0
                text: "Sin resultados"
                font.family: root.fontMain
                font.pixelSize: 13
                color: root.onSurfaceMuted
                opacity: 0.85
            }

            ListView {
                id: coinList
                anchors.fill: parent
                anchors.margins: 12
                model: filteredModel
                spacing: 10
                clip: true

                ScrollBar.vertical: ScrollBar {
                    width: 5
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 2; color: root.accent; opacity: 0.18 }
                }

                delegate: CoinRow { }
            }
        }
    }

    // Components
     component IconPillButton: Rectangle {
        property string symbol: ""
        signal clicked()

        implicitWidth: 40
        implicitHeight: 40
        radius: 16

        // Vitality style: surface + border del sistema
        color: root.surface0
        border.width: 1
        border.color: root.border0

        property bool pressed: false
        scale: pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        MaterialSymbol {
            anchors.centerIn: parent
            text: parent.symbol
            font.pixelSize: 20
            color: root.onSurface
            opacity: parent.enabled ? 0.88 : 0.35
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.enabled
            cursorShape: Qt.PointingHandCursor
            onPressed: parent.pressed = true
            onReleased: parent.pressed = false
            onCanceled: parent.pressed = false
            onClicked: parent.clicked()
        }
    }

    component FilterChip: Rectangle {
        property string text: ""
        property bool active: false
        signal clicked()

        height: 32
        radius: 16

        color: active
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.92)
            : root.surface0

        // Importante: NO borde blanco; usamos border0
        border.width: 1
        border.color: active
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
            : root.border0

        implicitWidth: label.implicitWidth + 22

        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            font.family: root.fontMain
            font.pixelSize: 12
            font.weight: Font.Bold
            color: active ? "black" : root.onSurfaceMuted
        }

        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    component Sparkline: Canvas {
        property string symbol: ""
        property real changeNum: 0
        property bool isUp: true
        property color lineColor: isUp ? "#00d084" : "#ff7675"

        antialiasing: true

        function hashStr(s) {
            var h = 2166136261
            for (var i = 0; i < s.length; i++) {
                h ^= s.charCodeAt(i)
                h += (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24)
            }
            return h >>> 0
        }

        function rnd(seed) {
            seed ^= seed << 13; seed >>>= 0
            seed ^= seed >> 17; seed >>>= 0
            seed ^= seed << 5;  seed >>>= 0
            return seed >>> 0
        }

        onSymbolChanged: requestPaint()
        onChangeNumChanged: requestPaint()
        onIsUpChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var w = width, h = height
            if (w <= 2 || h <= 2) return

            var seed = hashStr(symbol + ":" + Math.round(changeNum * 100).toString())
            var n = 18
            var pts = []

            var amp = Math.min(1.0, Math.max(0.25, Math.abs(changeNum) / 8.0))
            var trend = (isUp ? 1 : -1) * (0.18 + 0.20 * amp)

            var v = 0.5
            for (var i = 0; i < n; i++) {
                seed = rnd(seed)
                var noise = ((seed % 1000) / 1000.0 - 0.5) * 0.22 * amp
                v = v + noise + trend / (n - 1)
                v = Math.max(0.08, Math.min(0.92, v))
                pts.push(v)
            }

            ctx.beginPath()
            for (var x = 0; x < n; x++) {
                var px = (x / (n - 1)) * (w - 1)
                var py = (1.0 - pts[x]) * (h - 1)
                if (x === 0) ctx.moveTo(px, py)
                else ctx.lineTo(px, py)
            }
            ctx.lineTo(w - 1, h - 1)
            ctx.lineTo(0, h - 1)
            ctx.closePath()

            var grad = ctx.createLinearGradient(0, 0, 0, h)
            grad.addColorStop(0.0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.16))
            grad.addColorStop(1.0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.00))
            ctx.fillStyle = grad
            ctx.fill()

            ctx.beginPath()
            for (var j = 0; j < n; j++) {
                var lx = (j / (n - 1)) * (w - 1)
                var ly = (1.0 - pts[j]) * (h - 1)
                if (j === 0) ctx.moveTo(lx, ly)
                else ctx.lineTo(lx, ly)
            }
            ctx.lineWidth = 2
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.strokeStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.92)
            ctx.stroke()
        }
    }

    component CoinRow: Rectangle {
        width: coinList.width
        height: 68
        radius: 18

        property int _favRev: root.favoritesRevision
        property bool fav: root.isFavorite(model.name)

        property bool hovered: ma.containsMouse
        property bool pressed: false

             color: pressed
            ? Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.10)
            : (hovered ? Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.07)
                       : Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, 0.05))

        border.width: 1
        border.color: root.border0

        Behavior on color { ColorAnimation { duration: 120 } }
        scale: pressed ? 0.992 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: pressed = true
            onReleased: pressed = false
            onCanceled: pressed = false
            onDoubleClicked: root.toggleFavorite(model.name)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 40; height: 40; radius: 16
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)

                Image {
                    id: coinImg
                    anchors.centerIn: parent
                    width: 26; height: 26
                    source: "https://assets.coincap.io/assets/icons/" + (model.name ? model.name.toLowerCase() : "") + "@2x.png"
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                    opacity: 0.95
                }

                Text {
                    anchors.centerIn: parent
                    visible: coinImg.status !== Image.Ready
                    text: model.name ? model.name.slice(0, 1) : "?"
                    font.family: root.fontMain
                    font.pixelSize: 14
                    font.weight: Font.Black
                    color: root.accent
                    opacity: 0.95
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.preferredWidth: 82
                Layout.maximumWidth: 96

                Text {
                    text: model.name
                    font.family: root.fontMain
                    font.weight: Font.Bold
                    font.pixelSize: 14
                    color: root.onSurface
                    elide: Text.ElideRight
                }
                Text {
                    text: model.pair
                    font.family: root.fontMain
                    font.pixelSize: 11
                    color: root.onSurfaceMuted
                    opacity: 0.75
                }
            }

            Sparkline {
                Layout.fillWidth: true
                Layout.preferredWidth: 160
                Layout.minimumWidth: 120
                Layout.preferredHeight: 38
                symbol: model.name
                changeNum: model.changeNum
                isUp: model.isUp
                lineColor: model.isUp ? "#00d084" : "#ff7675"
                opacity: hovered ? 1.0 : 0.9
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Rectangle {
                id: starBtn
                width: 30
                height: 30
                radius: 10

                color: fav
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    : Qt.rgba(root.onSurface.r, root.onSurface.g, root.onSurface.b, hovered ? 0.08 : 0.06)

                border.width: 1
                border.color: fav
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                    : root.border0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: fav ? "star" : "star_outline"
                    font.pixelSize: 18
                    color: fav ? root.accent : root.onSurfaceMuted
                    opacity: fav ? 0.98 : 0.85
                    scale: starMa.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }

                MouseArea {
                    id: starMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleFavorite(model.name)
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6
                Layout.preferredWidth: 92
                Layout.maximumWidth: 110

                Text {
                    text: model.price
                    font.family: root.fontMain
                    font.weight: Font.ExtraBold
                    font.pixelSize: 14
                    color: root.onSurface
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignRight
                    elide: Text.ElideLeft
                }

                Rectangle {
                    Layout.alignment: Qt.AlignRight
                    height: 22
                    radius: 8
                    color: model.isUp ? Qt.rgba(0/255, 208/255, 132/255, 0.12)
                                     : Qt.rgba(255/255, 118/255, 117/255, 0.12)
                    border.width: 1
                    border.color: model.isUp ? Qt.rgba(0/255, 208/255, 132/255, 0.16)
                                            : Qt.rgba(255/255, 118/255, 117/255, 0.16)
                    width: changeText.implicitWidth + 26

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: model.isUp ? "trending_up" : "trending_down"
                            font.pixelSize: 14
                            color: model.isUp ? "#00d084" : "#ff7675"
                        }
                        Text {
                            id: changeText
                            text: model.change
                            font.family: root.fontMain
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: model.isUp ? "#00d084" : "#ff7675"
                        }
                    }
                }
            }
        }
    }
}

