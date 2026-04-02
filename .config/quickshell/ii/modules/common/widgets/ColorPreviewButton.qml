import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
    id: root

    readonly property string builtInThemeDirectory: Directories.defaultThemes
    readonly property string customThemeDirectory: Directories.customThemes

    property string colorScheme: "scheme-auto"
    property string colorSchemeDisplayName: ""

    property bool builtInTheme: false
    property bool customTheme: false
    property bool shouldLoad: false

    readonly property string builtInThemeFilePath: builtInThemeDirectory + "/" + colorScheme + ".json"
    readonly property string customThemeFilePath: customThemeDirectory + "/" + colorScheme + ".json"

    readonly property bool toggled: Config.options.appearance.palette.type === root.colorScheme
    readonly property bool sharpMode: Config.options.appearance.sharpMode

    readonly property string wallpaperPath: Config.options.background.wallpaperPath
    readonly property string scriptPath: FileUtils.trimFileProtocol(Directories.scriptPath + "/colors/generate_colors_material.py")
    readonly property string grepCommand: "grep -oE '#[0-9A-Fa-f]{6}' | head -n 3"
    readonly property string accentColorCommand: "python3 \"" + root.scriptPath + "\" --path \"" + root.wallpaperPath + "\" --debug | grep \"Accent color\" | awk '{print $NF}'"

    readonly property string builtInThemeCommand:
        "jq -r '.primary, .primary_container, .secondary' \"" + root.builtInThemeFilePath + "\""

    readonly property string customThemeCommand:
        "jq -r '.primary, .primary_container, .secondary' \"" + root.customThemeFilePath + "\""

    readonly property string dynamicThemeCommand:
        "python3 \"" + root.scriptPath + "\" --color \"$(" + root.accentColorCommand + ")\" --scheme \"" + root.colorScheme + "\" --debug | " + root.grepCommand

    readonly property string effectiveCommand:
        root.customTheme ? root.customThemeCommand
                         : root.builtInTheme ? root.builtInThemeCommand
                                             : root.dynamicThemeCommand

    property color primaryColor: "#9E9E9E"
    property color secondaryColor: "#757575"
    property color tertiaryColor: "#BDBDBD"

    property bool loaded: false
    property bool loading: false

    colBackground: toggled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
    colBackgroundHover: toggled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer2Hover
    colRipple: toggled ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer2Active

    buttonRadius: Appearance.rounding.small

    Layout.fillWidth: true
    implicitWidth: 64
    implicitHeight: 64

    function resetPreview() {
        loaded = false
        loading = false
        primaryColor = "#9E9E9E"
        secondaryColor = "#757575"
        tertiaryColor = "#BDBDBD"
        myCanvas.requestPaint()
    }

    function startLoading() {
        if (!shouldLoad)
            return

        if (loading)
            return

        loading = true
        loaded = false
        colorFetchProcess.running = false
        colorFetchProcess.running = true
    }

    function applyFallbackColors() {
        // fallback visual para que nunca se vea "vacío" o todos iguales
        if (root.colorScheme.indexOf("scheme-") === 0) {
            primaryColor = "#B39DDB"
            secondaryColor = "#9575CD"
            tertiaryColor = "#D1C4E9"
        } else if (root.builtInTheme) {
            primaryColor = "#CE93D8"
            secondaryColor = "#BA68C8"
            tertiaryColor = "#E1BEE7"
        } else if (root.customTheme) {
            primaryColor = "#80CBC4"
            secondaryColor = "#4DB6AC"
            tertiaryColor = "#B2DFDB"
        } else {
            primaryColor = "#90CAF9"
            secondaryColor = "#64B5F6"
            tertiaryColor = "#BBDEFB"
        }

        loaded = true
        loading = false
        myCanvas.requestPaint()
    }

    function parseAndApplyColors(rawText) {
        let lines = (rawText || "").split("\n")
        let found = []

        for (let i = 0; i < lines.length; i++) {
            let c = lines[i].trim()
            if (/^#[0-9A-Fa-f]{6}$/.test(c))
                found.push(c)
        }

        if (found.length >= 3) {
            primaryColor = found[0]
            secondaryColor = found[1]
            tertiaryColor = found[2]
            loaded = true
            loading = false
            myCanvas.requestPaint()
        } else {
            applyFallbackColors()
        }
    }

    onClicked: {
        Config.options.appearance.palette.type = root.colorScheme

        if (customTheme) {
            Quickshell.execDetached([
                "bash",
                "-c",
                "cp \"" + root.customThemeFilePath + "\" \"" + Directories.generatedMaterialThemePath + "\""
            ])
        } else if (builtInTheme) {
            Quickshell.execDetached([
                "bash",
                "-c",
                "cp \"" + root.builtInThemeFilePath + "\" \"" + Directories.generatedMaterialThemePath + "\""
            ])
        } else {
            Quickshell.execDetached([
                "bash",
                "-c",
                "\"" + Directories.wallpaperSwitchScriptPath + "\" --noswitch"
            ])
        }
    }

    onShouldLoadChanged: {
        if (shouldLoad)
            startLoading()
    }

    onColorSchemeChanged: {
        resetPreview()
        if (shouldLoad)
            Qt.callLater(startLoading)
    }

    onBuiltInThemeChanged: {
        resetPreview()
        if (shouldLoad)
            Qt.callLater(startLoading)
    }

    onCustomThemeChanged: {
        resetPreview()
        if (shouldLoad)
            Qt.callLater(startLoading)
    }

    Component.onCompleted: {
        if (shouldLoad)
            Qt.callLater(startLoading)
        else
            myCanvas.requestPaint()
    }

    Process {
        id: colorFetchProcess
        running: false
        command: [ "bash", "-c", root.effectiveCommand ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseAndApplyColors(this.text)
            }
        }

        onRunningChanged: {
            if (!running && root.loading && !root.loaded) {
                // Si terminó pero no hubo stdout usable, usamos fallback
                Qt.callLater(root.applyFallbackColors)
            }
        }
    }

    StyledToolTip {
        text: root.colorSchemeDisplayName
    }

    Item {
        id: contentRoot
        anchors.fill: parent

        Rectangle {
            id: selectionRing
            anchors.centerIn: parent
            width: 42
            height: 42
            radius: width / 2
            color: "transparent"
            border.width: root.toggled ? 2 : 1
            border.color: root.toggled
                ? Appearance.colors.colPrimary
                : Qt.rgba(1, 1, 1, 0.08)
            opacity: root.toggled ? 1.0 : 0.9

            Behavior on border.color {
                ColorAnimation { duration: 180 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 180 }
            }
        }

        Canvas {
            id: myCanvas
            anchors.centerIn: parent
            width: 30
            height: 30
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                var centerX = width / 2
                var centerY = height / 2
                var radius = width / 2

                ctx.reset()

                if (root.sharpMode) {
                    ctx.beginPath()
                    ctx.fillStyle = root.primaryColor
                    ctx.rect(0, 0, width, centerY)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.fillStyle = root.secondaryColor
                    ctx.rect(centerX, centerY, centerX, centerY)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.fillStyle = root.tertiaryColor
                    ctx.rect(0, centerY, centerX, centerY)
                    ctx.fill()
                } else {
                    ctx.beginPath()
                    ctx.fillStyle = root.primaryColor
                    ctx.moveTo(centerX, centerY)
                    ctx.arc(centerX, centerY, radius, Math.PI, 0, false)
                    ctx.closePath()
                    ctx.fill()

                    ctx.beginPath()
                    ctx.fillStyle = root.secondaryColor
                    ctx.moveTo(centerX, centerY)
                    ctx.arc(centerX, centerY, radius, 0, Math.PI / 2, false)
                    ctx.closePath()
                    ctx.fill()

                    ctx.beginPath()
                    ctx.fillStyle = root.tertiaryColor
                    ctx.moveTo(centerX, centerY)
                    ctx.arc(centerX, centerY, radius, Math.PI / 2, Math.PI, false)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }

        Rectangle {
            anchors.centerIn: myCanvas
            width: myCanvas.width
            height: myCanvas.height
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 4
            width: 4
            height: 4
            radius: 2
            visible: root.toggled
            color: Appearance.colors.colPrimary
        }
    }
}
