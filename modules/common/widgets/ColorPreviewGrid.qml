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

/*
    ✅ Rediseño (SIN cambiar la funcionalidad):
    - Antes: GridLayout con 3 columnas => se veía como 3 filas/varias filas.
    - Ahora: UNA SOLA FILA (horizontal), con scroll horizontal (wheel incluido).
    - Paletas un poco más pequeñas (controlado por itemWidth/itemHeight).
    - El nombre de cada tema se sigue pasando por colorSchemeDisplayName
      (si ColorPreviewButton lo muestra, aparecerá; no se elimina ninguno).

    NOTA:
    - La selección/aplicación de temas NO se toca: sigue siendo ColorPreviewButton
      quien aplica el scheme (igual que antes).
*/

Item {
    id: root

    // Ancho/alto: se adapta al contenedor, y da un alto estable para 1 fila.
    // Puedes ajustar itemHeight si quieres más compacto.
    implicitWidth: parent ? parent.width : 600
    implicitHeight: itemHeight

    // Tamaño visual (más pequeño que antes)
    // Ajusta aquí si quieres más chico/grande.
    property int itemWidth: 160
    property int itemHeight: 86

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

    // Mantiene tu API actual (para NO romper nada)
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

    // Decide which set to show (igual que antes)
    property list<string> colorSchemes: customTheme
        ? effectiveCustomSchemes
        : (builtInTheme ? builtInColorSchemes : root.wallpaperColorSchemes)

    function formatText(text) {
        if (customTheme || builtInTheme) {
            // "rose_pine" -> "Rose_pine" (mantengo tu lógica original)
            return text.charAt(0).toUpperCase() + text.slice(1)
        }
        // "scheme-tonal-spot" -> "Tonal spot"
        const sliced = text.split("-").slice(1).join(" ")
        return sliced.charAt(0).toUpperCase() + sliced.slice(1)
    }

    // Lazy-load (igual idea que antes, pero adaptado a ListView)
    property int loadedCount: 0

    function maxContentX() {
        return Math.max(0, themeList.contentWidth - themeList.width)
    }

    function clampContentX(x) {
        var maxX = root.maxContentX()
        if (x < 0) return 0
        if (x > maxX) return maxX
        return x
    }

    ListView {
        id: themeList
        anchors.fill: parent
        clip: true

        orientation: ListView.Horizontal
        spacing: 10

        model: root.colorSchemes

        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        // Scroll con la rueda (vertical wheel -> horizontal scroll)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: function(w) {
                var delta = w.angleDelta.y
                if (delta === 0) return
                themeList.contentX = root.clampContentX(themeList.contentX - delta)
                w.accepted = true
            }
        }

        delegate: Item {
            width: root.itemWidth
            height: root.itemHeight

            // Si tu ColorPreviewButton ya pinta nombre internamente usando
            // colorSchemeDisplayName, lo seguirá haciendo.
            // Aquí le damos un tamaño fijo más compacto.
            ColorPreviewButton {
                anchors.fill: parent

                colorScheme: modelData
                colorSchemeDisplayName: root.formatText(modelData)
                customTheme: root.customTheme
                builtInTheme: root.builtInTheme

                // Lazy-load: igual comportamiento que antes (no carga todo de golpe)
                shouldLoad: index < root.loadedCount
            }
        }
    }

    Timer {
        id: loadTimer
        interval: 16
        repeat: true
        running: false

        onTriggered: {
            root.loadedCount += 1
            if (root.loadedCount >= root.colorSchemes.length)
                loadTimer.stop()
        }
    }

    function restartLazyLoad() {
        root.loadedCount = 0
        loadTimer.stop()
        Qt.callLater(function() { loadTimer.start() })
    }

    Component.onCompleted: restartLazyLoad()

    // Si cambias entre schemes/built-in/custom o cambia el array, reinicia el lazy-load
    onColorSchemesChanged: restartLazyLoad()
    onCustomThemeChanged: restartLazyLoad()
    onBuiltInThemeChanged: restartLazyLoad()
    onCustomColorSchemesChanged: restartLazyLoad()
}

