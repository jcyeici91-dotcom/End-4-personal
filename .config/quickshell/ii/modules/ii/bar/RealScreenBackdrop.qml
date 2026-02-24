import QtQuick
import QtQuick.Window
import Quickshell.Io

Item {
    id: root

    property bool enabled: true
    property int intervalMs: 140
    property string outputPath: "/tmp/quickshell_sidebar_backdrop.png"

    // Cache bust
    property int _rev: 0
    readonly property url sourceUrl: ("file://" + outputPath + "?rev=" + _rev)

    // Sólo capturamos cuando el item ya está asociado a una ventana real
    readonly property bool _hasWindow: (root.Window.window !== null)

    readonly property point globalPos: root.mapToGlobal(0, 0)
    readonly property int captureX: Math.round(globalPos.x)
    readonly property int captureY: Math.round(globalPos.y)
    readonly property int captureW: Math.max(1, Math.round(root.width))
    readonly property int captureH: Math.max(1, Math.round(root.height))

    Image {
        id: img
        anchors.fill: parent
        source: root.sourceUrl
        asynchronous: true
        cache: false
        smooth: true
        fillMode: Image.Stretch
        visible: false
    }

    Process {
        id: grabProc
        running: false
        stdout: StdioCollector { }
        stderr: StdioCollector { }

        onRunningChanged: {
            if (!running) root._rev++
        }
    }

    Timer {
        id: t
        interval: root.intervalMs
        repeat: true
        running: root.enabled && root.visible && root._hasWindow

        onTriggered: {
            if (grabProc.running) return
            if (root.captureW < 4 || root.captureH < 4) return

            // grim geometry: "X,Y WxH"
            const geom = `${root.captureX},${root.captureY} ${root.captureW}x${root.captureH}`

            // Importante: escapamos todo con bash -lc y comillas simples
            grabProc.command = ["bash", "-lc", `grim -g '${geom}' '${root.outputPath}'`]
            grabProc.running = true
        }
    }

    // Exponemos el Image como “fuente” para el blur
    property alias imageItem: img
}

