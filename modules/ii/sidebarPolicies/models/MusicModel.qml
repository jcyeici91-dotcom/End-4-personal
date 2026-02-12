import QtQuick
import qs.services

Item {
    id: m
    width: 0
    height: 0
    visible: false

    property var track: MprisController.activeTrack
    property var activePlayer: MprisController.activePlayer

    property bool available: !!activePlayer || !!track

    property string player: (activePlayer && activePlayer.identity && ("" + activePlayer.identity).length)
                            ? ("" + activePlayer.identity)
                            : ((activePlayer && activePlayer.name) ? ("" + activePlayer.name) : "")

    property string status: MprisController.isPlaying
                            ? "Playing"
                            : (available ? "Paused" : "Stopped")

    // ─────────────────────────────────────────────
    function _meta(key, fallback) {
        if (activePlayer && activePlayer.metadata && activePlayer.metadata[key] !== undefined && activePlayer.metadata[key] !== null)
            return activePlayer.metadata[key]
        return fallback
    }

    function _toStr(v) {
        if (v === undefined || v === null) return ""
        if (Array.isArray(v)) return v.join(", ")
        // QUrl / QVariant suele exponer toString()
        try {
            if (v && v.toString) return v.toString()
        } catch (e) {}
        return ("" + v)
    }

    function _normalizeArtUrl(u) {
        u = (u || "").trim()
        if (!u.length) return ""

        if (u.indexOf("QUrl(") === 0) {
            // QUrl("file:///x") o QUrl('file:///x')
            var m = u.match(/^QUrl\(["'](.+)["']\)$/)
            if (m && m[1]) u = m[1]
            u = u.trim()
        }

        if (u.indexOf("file://localhost/") === 0) {
            u = "file:///" + u.slice("file://localhost/".length)
        }

        // /home/user/cover.jpg -> file:///home/user/cover.jpg
        if (u[0] === "/") {
            u = "file://" + u
        }

        if (u.indexOf("file:/") === 0 && u.indexOf("file://") !== 0) {
            u = u.replace("file:/", "file:///")
        }

        return u
    }

    // Metadata textual
    property string title:  (track && track.title)  ? _toStr(track.title)  : _toStr(_meta("xesam:title", ""))
    property string artist: (track && track.artist) ? _toStr(track.artist) : _toStr(_meta("xesam:artist", ""))
    property string album:  (track && track.album)  ? _toStr(track.album)  : _toStr(_meta("xesam:album", ""))

    property string artUrlRaw: {
        // 1) lo que da el track
        var u = (track && track.artUrl) ? _toStr(track.artUrl) : ""
        if (u && u.length) return u

        // 2) key estándar MPRIS
        u = _toStr(_meta("mpris:artUrl", ""))
        if (u && u.length) return u

        // 3) algunos publican "artUrl" sin namespace
        u = _toStr(_meta("artUrl", ""))
        if (u && u.length) return u

        // 4) algunos publican "xesam:artUrl" (no tan común)
        u = _toStr(_meta("xesam:artUrl", ""))
        if (u && u.length) return u

        return ""
    }

    property string artUrl: _normalizeArtUrl(artUrlRaw)

    property real _lengthUs: 0
    property real _positionUs: 0
    property real lengthSec: _lengthUs / 1000000.0
    property real positionSec: _positionUs / 1000000.0

    function _normalizeToUs(v) {
        if (v === undefined || v === null) return 0
        var n = Number(v)
        if (isNaN(n) || n <= 0) return 0

        if (n >= 10000000) return Math.floor(n)          // us
        if (n >= 1000)     return Math.floor(n * 1000)   // ms -> us
        return Math.floor(n * 1000000)                   // s -> us
    }

    function _secToTime(s) {
        s = Math.max(0, Math.floor(s || 0))
        var mm = Math.floor(s / 60)
        var ss = s % 60
        return mm.toString() + ":" + ss.toString().padStart(2, "0")
    }

    property string positionStr: _secToTime(positionSec)
    property string lengthStr: _secToTime(lengthSec)

    property int pollMs: 400

    function refreshTimes() {
        var len = _meta("mpris:length", 0)
        if ((!len || Number(len) <= 0) && track) {
            if (track.length !== undefined) len = track.length
            else if (track.duration !== undefined) len = track.duration
        }
        m._lengthUs = _normalizeToUs(len)

        var pos = 0
        if (activePlayer && activePlayer.position !== undefined && activePlayer.position !== null) {
            pos = activePlayer.position
        } else {
            pos = _meta("mpris:position", 0)
        }
        m._positionUs = _normalizeToUs(pos)
    }

    Timer {
        interval: m.pollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: m.refreshTimes()
    }

    // Controles
    function playPause() { MprisController.togglePlaying() }
    function next() { MprisController.next() }
    function previous() { MprisController.previous() }

    function seekTo(sec) {
        if (!activePlayer) return
        sec = Math.max(0, Math.min(lengthSec || 0, sec || 0))
        activePlayer.position = Math.floor(sec * 1000000.0)
        refreshTimes()
    }
}

