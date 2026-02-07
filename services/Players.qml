pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.length > 0 ? players[0] : null

    property var trackLyrics: 1        // 1 = loading, 404 = not found, object = ok
    property int currentTry: 1
    readonly property int maxTries: 5

    signal lyricsChanged()

    Connections {
        target: player
        function onPostTrackChanged() {
            reloadLyrics()
        }
    }

    function reloadLyrics() {
        trackLyrics = 1
        currentTry = 1
        lyricsChanged()
        lyricsTimer.restart()
    }

    Timer {
        id: lyricsTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: lyricsProc.running = true
    }

    Process {
        id: lyricsProc
        running: false

        command: [
            "curl",
            "https://lrclib.net/api/get?artist_name=" +
            encodeURI(player.trackArtist) +
            "&track_name=" +
            encodeURI(player.trackTitle) +
            "&duration=" +
            player.length
        ]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var data = JSON.parse(text)

                if (data.statusCode) {
                    if (currentTry < maxTries) {
                        currentTry++
                        lyricsTimer.restart()
                    } else {
                        trackLyrics = 404
                        lyricsChanged()
                    }
                } else {
                    trackLyrics = data
                    lyricsChanged()
                }
            }
        }
    }
}
