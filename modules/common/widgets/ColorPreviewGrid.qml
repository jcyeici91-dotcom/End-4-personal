import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common

/*
    Almost all of the custom color schemes (latte.json, samurai.json etc.) are gotten from:
    https://github.com/snowarch/quickshell-ii-niri/blob/main/modules/common/ThemePresets.qml

    To add a new custom color scheme:

    1. Put a proper color scheme json into ~/.config/illogical_impulse/themes
    2. Add the exact name of the json file (without .json) to config.json:
       appearance -> customColorSchemes

    This file additionally provides a fallback list (extraCustomSchemes) so your
    10 custom themes show up even if config.json has an empty array.
*/

GridLayout {
    id: root
    implicitWidth: parent.width
    columns: 3

    readonly property list<string> builtInColorSchemes: [
        "angel_light", "angel", "ayu", "cobalt2", "cursor", "dracula", "flexoki",
        "frappe", "github", "gruvbox", "kanagawa", "latte", "macchiato",
        "material_ocean", "matrix", "mercury", "mocha", "nord", "open_code",
        "orng", "osaka_jade", "rose_pine", "sakura", "samurai", "synthwave84",
        "vercel", "vesper", "zen_burn", "zen_garden"
    ]

    // This comes from your config.json: appearance.customColorSchemes
    property list<string> customColorSchemes: (Config.options.appearance.customColorSchemes ?? [])

    // Fallback: your 10 new themes (must exist as json files in ~/.config/illogical_impulse/themes/)
    readonly property list<string> extraCustomSchemes: [
        "espresso",
        "mocha_cream",
        "ink_olive",
        "carbon_amber",
        "midnight_plum",
        "obsidian_teal",
        "cocoa_rose",
        "night_sand",
        "smoke_blue",
        "noir_copper"
    ]

    readonly property list<string> wallpaperColorSchemes: [
        "scheme-auto",
        "scheme-content",
        "scheme-tonal-spot",
        "scheme-fidelity",
        "scheme-fruit-salad",
        "scheme-expressive",
        "scheme-rainbow",
        "scheme-neutral",
        "scheme-monochrome"
    ]

    property bool customTheme: false
    property bool builtInTheme: false

    function uniq(list) {
        const out = []
        const seen = {}
        for (let i = 0; i < (list ? list.length : 0); i++) {
            const v = "" + list[i]
            if (!v || seen[v]) continue
            seen[v] = true
            out.push(v)
        }
        return out
    }

    // Merge config custom schemes + fallback list, remove duplicates.
    // If you DO add them to config.json later, it will still show only once.
    readonly property list<string> effectiveCustomSchemes: uniq(customColorSchemes.concat(extraCustomSchemes))

    // Decide which set to show
    property list<string> colorSchemes: customTheme
        ? effectiveCustomSchemes
        : (builtInTheme ? builtInColorSchemes : root.wallpaperColorSchemes)

    function formatText(text) {
        if (customTheme || builtInTheme)
            return text.charAt(0).toUpperCase() + text.slice(1)
        const sliced = text.split("-").slice(1).join(" ")
        return sliced.charAt(0).toUpperCase() + sliced.slice(1)
    }

    property int loadedCount: 0

    Repeater {
        model: root.colorSchemes

        delegate: ColorPreviewButton {
            Layout.fillWidth: true

            colorScheme: modelData
            colorSchemeDisplayName: formatText(modelData)
            customTheme: root.customTheme
            builtInTheme: root.builtInTheme

            shouldLoad: index < root.loadedCount
        }
    }

    Timer {
        id: loadTimer
        interval: 20
        repeat: true
        running: false

        onTriggered: {
            root.loadedCount += 1
            if (root.loadedCount >= root.colorSchemes.length)
                loadTimer.stop()
        }
    }

    Component.onCompleted: {
        root.loadedCount = 0
        Qt.callLater(() => loadTimer.start())
    }
}

