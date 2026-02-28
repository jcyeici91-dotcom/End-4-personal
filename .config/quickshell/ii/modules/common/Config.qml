pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common.functions

Singleton {
    id: root

    /* ------------------------------------------------------------------------
     * [0] CORE / ESTADO GENERAL
     * --------------------------------------------------------------------- */
    property string filePath: Directories.shellConfigPath  // Ruta del archivo de config (JSON)
    property alias options: configOptionsJsonAdapter        // Acceso a todas las opciones (JsonAdapter)
    property bool ready: false                              // True cuando ya cargó el archivo
    property int readWriteDelay: 75                         // ms (debounce) para leer/escribir
    property bool blockWrites: false                        // True = no escribe al archivo (modo seguro)

    /* ------------------------------------------------------------------------
     * [1] API UTIL: setNestedValue("a.b.c", value)
     * - Permite setear valores por ruta (dot-path) dentro de options
     * - Convierte "true"/"false"/"123" cuando sea seguro
     * --------------------------------------------------------------------- */
    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;

        // Crear/recorrer objetos intermedios si no existen
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
        }

        // Convertir strings simples a bool/number cuando sea razonable
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    /* ------------------------------------------------------------------------
     * [2] TIMERS: debounce de lectura/escritura
     * --------------------------------------------------------------------- */
    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.writeAdapter()
    }

    /* ------------------------------------------------------------------------
     * [3] IO: FileView + JsonAdapter (carga/guarda el JSON)
     * --------------------------------------------------------------------- */
    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites

        // Si el archivo cambia, recarga (con debounce)
        onFileChanged: fileReloadTimer.restart()

        // Si el adapter cambia (opciones), escribe (con debounce)
        onAdapterUpdated: fileWriteTimer.restart()

        // Señal de “config lista”
        onLoaded: root.ready = true

        // Si no existe, crea uno escribiendo defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        /* ====================================================================
         * [4] OPCIONES (JsonAdapter)
         * - TODO lo que cambias de UI/funciones vive aquí
         * - Está ordenado por “secciones” numeradas
         * ================================================================= */
        JsonAdapter {
            id: configOptionsJsonAdapter

            /* =================================================================
             * [4.1] “FAMILIA” / VARIANTE DE PANEL
             * - Cambia el set de componentes o estilo general (“ii” vs “waffle”)
             * =============================================================== */
            property string panelFamily: "ii" // "ii", "waffle"

            /* =================================================================
             * [4.2] POLÍTICAS / FLAGS GENERALES
             * - Interruptores “macro” para habilitar/deshabilitar features
             * =============================================================== */
            property JsonObject policies: JsonObject {
                property int ai: 1          // 0: No | 1: Yes | 2: Local
                property int weeb: 0        // 0: No | 1: Open | 2: Closet
                property int wallpapers: 1  // 0: No | 1: Yes
                property int translator: 0  // 0: No | 1: Yes
            }

            /* =================================================================
             * [4.3] IA (sidebar assistant / modelos / prompt)
             * - systemPrompt: define estilo y reglas del asistente
             * - tool: “search”, “functions”, o “none”
             * - extraModels: modelos adicionales (providers)
             * =============================================================== */
            property JsonObject ai: JsonObject {
                property string systemPrompt:
                    "## Style\n" +
                    "- Use casual tone, don't be formal! Make sure you answer precisely without hallucination and prefer bullet points over walls of text. You can have a friendly greeting at the beginning of the conversation, but don't repeat the user's question\n\n" +
                    "## Context (ignore when irrelevant)\n" +
                    "- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n" +
                    "- Desktop environment: {DE}\n" +
                    "- Current date & time: {DATETIME}\n" +
                    "- Focused app: {WINDOWCLASS}\n\n" +
                    "## Presentation\n" +
                    "- Use Markdown features in your response: \n" +
                    "  - **Bold** text to **highlight keywords** in your response\n" +
                    "  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n" +
                    "- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n" +
                    "- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n"

                property string tool: "functions" // search, functions, or none

                // Needed entries in the object: title, value, modelProvider (only for openrouter)
                property list<var> extraModels: [
                    {
                        "openrouter": [
                            { title: "Gemini 2.5 Flash", value: "gemini-2.5-flash", modelProvider: "google" }
                        ]
                    },
                    { "google": [] },
                    { "mistral": [] }
                ]
            }

            /* =================================================================
             * [4.4] APARIENCIA GLOBAL
             * - Tipografías, transparencia, theming por wallpaper, palette
             * =============================================================== */
            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2       // 0: None | 1: Always | 2: When not fullscreen | 3: Wrapped
                property int wrappedFrameThickness: 10

                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }

                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }

                property JsonObject wallpaperTheming: JsonObject {
                    property bool enableAppsAndShell: true
                    property bool enableQtApps: true
                    property bool enableTerminal: true

                    property JsonObject terminalGenerationProps: JsonObject {
                        property real harmony: 0.6
                        property real harmonizeThreshold: 100
                        property real termFgBoost: 0.35
                        property bool forceDarkMode: false
                    }
                }

                property JsonObject palette: JsonObject {
                    property string type: "auto"
                    // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity,
                    // scheme-fruit-salad, scheme-monochrome, scheme-neutral,
                    // scheme-rainbow, scheme-tonal-spot
                    property string accentColor: ""
                }

                property list<string> customColorSchemes: []
            }

            /* =================================================================
             * [4.5] AUDIO
             * - Protección contra subidas bruscas de volumen
             * =============================================================== */
            property JsonObject audio: JsonObject {
                // Values in %
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            /* =================================================================
             * [4.6] APPS / COMANDOS DEL SISTEMA
             * - Rutas/command strings para abrir módulos/herramientas
             * =============================================================== */
            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1" // Only for shell actions
                property string update: "kitty -1 --hold=yes fish -i -c 'pkexec pacman -Syu'"
                property string volumeMixer:
                    "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"pavucontrol-qt\" \"pavucontrol\""
            }

            /* =================================================================
             * [4.7] FONDO (WALLPAPER) + WIDGETS EN FONDO
             * - Clock/media/weather widgets sobre el wallpaper
             * - Parallax y “media mode”
             * =============================================================== */
            property JsonObject background: JsonObject {
                property JsonObject widgets: JsonObject {
                    /* -------------------- [4.7.1] CLOCK -------------------- */
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy" // "free", "leastBusy", "mostBusy"
                        property real x: 100
                        property real y: 100

                        property string style: "cookie"       // "cookie", "digital"
                        property string styleLocked: "cookie" // "cookie", "digital"

                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property string aiStylingModel: "gemini" // "gemini", "openrouter"
                            property int sides: 14
                            property string backgroundStyle: "cookie" // "cookie", "sine", "shape"
                            property string backgroundShape: "Arch"   // MaterialShape.Shape enum as string

                            property string dialNumberStyle: "full" // "dots", "numbers", "full", "none"
                            property string hourHandStyle: "fill"   // "classic", "fill", "hollow", "hide"
                            property string minuteHandStyle: "medium" // "classic", "thin", "medium", "bold", "hide"
                            property string secondHandStyle: "dot"  // "dot", "line", "classic", "hide"
                            property string dateStyle: "bubble"     // "border", "rect", "bubble", "hide"

                            property bool timeIndicators: true
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                        }

                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false

                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }

                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                        }
                    }

                    /* -------------------- [4.7.2] MEDIA -------------------- */
                    property JsonObject media: JsonObject {
                        property bool enable: true
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 800
                        property real y: 100

                        property bool useAlbumColors: true
                        property bool hideAllButtons: false
                        property bool showPreviousToggle: true
                        property bool tintArtCover: false

                        property string backgroundShape: "Circle" // MaterialShape.Shape enum as string

                        property JsonObject glow: JsonObject {
                            property bool enable: true
                            property real brightness: 10
                        }

                        property JsonObject visualizer: JsonObject {
                            property bool enable: false
                            property real opacity: 0.15
                            property int smoothing: 2
                            property int blur: 1
                        }
                    }

                    /* ------------------- [4.7.3] WEATHER ------------------- */
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                    }
                }

                property string wallpaperPath: ""
                property string thumbnailPath: ""
                property bool hideWhenFullscreen: true

                property JsonObject parallax: JsonObject {
                    property bool vertical: true
                    property bool autoVertical: false
                    property bool enableWorkspace: true
                    property real workspaceZoom: 1.07 // Relative to screen, not wallpaper size
                    property bool enableSidebar: true
                    property real widgetsFactor: 1.2
                }

                property JsonObject mediaMode: JsonObject {
                    property bool enable: false
                    property string backgroundShape: "Square"
                    property bool enableBackgroundAnimation: true // may cause nausea
                    property bool changeShellColor: true          // album color -> shell color

                    property JsonObject backgroundAnimation: JsonObject {
                        property bool enable: true
                        property int speedScale: 10 // 1 slow, 10 default, 20 2x
                    }

                    property JsonObject syllable: JsonObject {
                        property int textHighlightStyle: 0 // 0 vertical, 1 horizontal
                    }
                }
            }

            /* =================================================================
             * [4.8] BAR (barra superior/lateral) + layout + widgets
             * =============================================================== */
        property JsonObject bar: JsonObject {
                property JsonObject activeWindow: JsonObject {
                    property bool fixedSize: false
                }

                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property bool pushWindows: false
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }

                property bool bottom: false // Instead of top

                // 0: Hug | 1: Float | 2: Rect | 3: Hybrid (Notch)
                property int cornerStyle: 0

                property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
                property bool borderless: false // true for no grouping of items
                property string topLeftIcon: "spark" // Options: "distro" or any icon name in ~/.config/quickshell/ii/assets/icons

               // 0: Transparent | 1: Visible | 2: Adaptive | 3: Crystal
                property int barBackgroundStyle: 1

                property bool verbose: true
                property bool vertical: false

                // "rounded" (Pills/Line) | "rect" (Canvas) | "hybrid" (Notch)
                property string groupBackgroundStyle: "rounded"

                property JsonObject mediaPlayer: JsonObject {
                    property int customSize: 250
                    property JsonObject lyrics: JsonObject {
                        property bool enable: true
                        property int customSize: 400
                        property string style: "scroller" // scroller, static
                        property bool useGradientMask: true
                    }
                }

                property JsonObject resources: JsonObject {
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                }

                property list<string> screenList: [] // e.g. "eDP-1" (hyprctl monitors)

                property JsonObject timers: JsonObject {
                    property bool showPomodoro: true
                    property bool showStopwatch: true
                }

                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: false
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: true
                    property bool showDarkModeToggle: true
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false
                }

                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: true
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useWorkspaceMap: true
                    property list<var> workspaceMap: [0, 10]
                    property int maxWindowCount: 5
                    property bool useNerdFont: false
                    property int activeIndicatorOpacity: 100 // 0-100
                }

                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true
                    property string city: "" // When enableGPS is false
                    property bool useUSCS: false
                    property int fetchInterval: 10 // minutes
                }

                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }

                property JsonObject layouts: JsonObject {
                    // availableComps = componentes “opcionales”
                    // left/center/right = layout principal de la barra
                    property list<var> availableComps: [
                        { id: "record_indicator", icon: "screen_record", title: "Record indicator", visible: false },
                        { id: "screen_share_indicator", icon: "screen_share", title: "Screen share indicator", visible: false },
                        { id: "date", icon: "date_range", title: "Date" },
                        { id: "battery", icon: "battery_android_6", title: "Battery" },
                        { id: "timer", icon: "timer", title: "Timer & Pomodoro" },
                        { id: "weather", icon: "weather_mix", title: "Weather" },
                        { id: "utility_buttons", icon: "build", title: "Utility buttons" }
                    ]

                    property list<var> left: [
                        { id: "policies_panel_button", icon: "star", title: "Policies panel button" },
                        { id: "active_window", icon: "label", title: "Active window" }
                    ]

                    property list<var> center: [
                        { id: "music_player", icon: "music_note", title: "Music player" },
                        { id: "workspaces", icon: "workspaces", title: "Workspaces", centered: true },
                        { id: "system_monitor", icon: "monitor_heart", title: "System monitor" }
                    ]

                    property list<var> right: [
                        { id: "clock", icon: "nest_clock_farsight_analog", title: "Clock" },
                        { id: "system_tray", icon: "system_update_alt", title: "System tray" },
                        { id: "dashboard_panel_button", icon: "notifications", title: "Dashboard panel button" }
                    ]
                }

                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }

                property JsonObject sizes: JsonObject {
                    property int height: 40 // horizontal mode
                    property int width: 46  // vertical mode
                }
            }

            /* =================================================================
             * [4.9] BATERÍA (alertas + autosuspend)
             * =============================================================== */
            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            /* =================================================================
             * [4.10] CALENDARIO (locale)
             * =============================================================== */
            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            /* =================================================================
             * [4.11] CHEATSHEET (teclas/íconos)
             * =============================================================== */
            property JsonObject cheatsheet: JsonObject {
                // Use a nerdfont to see the icons
                property string superKey: ""
                property bool useMacSymbol: false
                property bool splitButtons: false
                property bool useMouseSymbol: false
                property bool useFnSymbol: false

                property JsonObject fontSize: JsonObject {
                    property int key: Appearance.font.pixelSize.smaller
                    property int comment: Appearance.font.pixelSize.smaller
                }
            }

            /* =================================================================
             * [4.12] CONFLICT KILLER (evitar daemons duplicados)
             * =============================================================== */
            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            /* =================================================================
             * [4.13] CROSSHAIR (formato Valorant)
             * =============================================================== */
            property JsonObject crosshair: JsonObject {
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            /* =================================================================
             * [4.14] DOCK (dock/pinned apps)
             * =============================================================== */
            property JsonObject dock: JsonObject {
                property bool enable: false
                property bool monochromeIcons: true
                property real height: 60
                property real hoverRegionHeight: 2
                property bool pinnedOnStartup: false
                property bool hoverToReveal: true
                property list<string> pinnedApps: ["org.kde.dolphin", "kitty"]
                property list<string> ignoredAppRegexes: []
            }

            /* =================================================================
             * [4.15] INTERACCIONES (scroll + workaround)
             * =============================================================== */
            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false
                    property int mouseScrollDeltaThreshold: 120
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject {
                    property bool enable: false
                }
            }

            /* =================================================================
             * [4.16] IDIOMA + TRADUCTOR
             * =============================================================== */
            property JsonObject language: JsonObject {
                property string ui: "en_US" // "auto" o locale específico

                property JsonObject translator: JsonObject {
                    property string engine: "auto"
                    property string targetLanguage: "auto"
                    property string sourceLanguage: "auto"
                }
            }

            /* =================================================================
             * [4.17] LAUNCHER (apps fijadas)
             * =============================================================== */
            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: ["org.kde.dolphin", "kitty", "cmake-gui"]
            }

            /* =================================================================
             * [4.18] LUZ (night light + anti flashbang)
             * =============================================================== */
            property JsonObject light: JsonObject {
                property JsonObject night: JsonObject {
                    property bool automatic: true
                    property string from: "19:00"
                    property string to: "06:30"
                    property int colorTemperature: 5000
                }
                property JsonObject antiFlashbang: JsonObject {
                    property bool enable: false
                }
            }

            /* =================================================================
             * [4.19] LOCK (hyprlock + blur + seguridad)
             * =============================================================== */
            property JsonObject lock: JsonObject {
                property bool useHyprlock: false
                property bool launchOnStartup: false

                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                }

                property bool centerClock: true
                property bool showLockedText: true

                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }

                property bool materialShapeChars: true
            }

            /* =================================================================
             * [4.20] MEDIA (MPRIS / playerctl)
             * =============================================================== */
            property JsonObject media: JsonObject {
                property bool filterDuplicatePlayers: true
                property string priorityPlayer: ""
            }

            /* =================================================================
             * [4.21] NETWORKING (user agent)
             * =============================================================== */
            property JsonObject networking: JsonObject {
                property string userAgent:
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            /* =================================================================
             * [4.22] NOTIFICACIONES / OSD
             * =============================================================== */
            property JsonObject notifications: JsonObject {
                property int timeout: 7000
            }

            property JsonObject osd: JsonObject {
                property int timeout: 2500
            }

            /* =================================================================
             * [4.23] OSK (teclado en pantalla)
             * =============================================================== */
            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

            /* =================================================================
             * [4.24] OVERLAY (animaciones + notas + media overlay)
             * =============================================================== */
            property JsonObject overlay: JsonObject {
                property bool openingZoomAnimation: true
                property bool darkenScreen: true
                property real clickthroughOpacity: 0.8

                property JsonObject floatingImage: JsonObject {
                    property string imageSource: "https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"
                    property real scale: 0.5
                }

                property JsonObject notes: JsonObject {
                    property bool showTabs: true
                    property bool allowEditingIcon: true
                }

                property JsonObject media: JsonObject {
                    property int backgroundOpacityPercentage: 100
                    property bool useGradientMask: true
                    property bool showSlider: true
                    property int lyricSize: Appearance.font.pixelSize.larger
                }
            }

            /* =================================================================
             * [4.25] OVERVIEW (exposé/workspaces overview)
             * =============================================================== */
            property JsonObject overview: JsonObject {
                property bool enable: true
                property real scale: 0.18
                property real rows: 3
                property real columns: 1
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool showIcons: true
                property bool centerIcons: true
                property bool useWorkspaceMap: true
                property list<var> workspaceMap: [0, 10]
                property bool showOpeningAnimation: true

                property string style: "classic" // classic, scrolling

                property JsonObject hyprscrollingImplementation: JsonObject {
                    property int maxWorkspaceWidth: 1200 // TODO: remove this too
                }

                property JsonObject scrollingStyle: JsonObject {
                    property int dimPercentage: 50 // 0-75
                    property string backgroundStyle: "blur" // transparent, blur, dim
                    property string zoomStyle: "in"         // in, out
                }

                property string position: "center" // top, center, bottom
                property int centerTopPaddingRatio: 3
            }

            /* =================================================================
             * [4.26] REGION SELECTOR (selección de región para snip/acciones)
             * =============================================================== */
            property JsonObject regionSelector: JsonObject {
                property bool showOnlyOnFocusedMonitor: false

                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }

                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }

                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }

                property JsonObject annotation: JsonObject {
                    property bool useSatty: false
                }
            }

            /* =================================================================
             * [4.27] RESOURCES (refresh + historial)
             * =============================================================== */
            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            /* =================================================================
             * [4.28] LYRICS SERVICE (proveedores)
             * =============================================================== */
            property JsonObject lyricsService: JsonObject {
                property bool enable: true
                property bool enableGenius: true
                property bool enableLrclib: true
            }

            /* =================================================================
             * [4.29] TRAY (íconos/filtrado/pineados)
             * =============================================================== */
            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true
                property list<var> pinnedItems: ["Fcitx"]
                property bool filterPassive: true
            }

            /* =================================================================
             * [4.30] UPDATE (script de actualización)
             * =============================================================== */
            property JsonObject update: JsonObject {
                property string scriptPath: ""
                property string scriptFlags: "--no-backup --no-confirm"
            }

            /* =================================================================
             * [4.31] MUSIC RECOGNITION (timeout/interval)
             * =============================================================== */
            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

            /* =================================================================
             * [4.32] SEARCH (web + archivos + prefijos)
             * =============================================================== */
            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com", "facebook.com"]
                property string fileSearchDirectory: "/home"
                property bool blurFileSearchResultPreviews: false
                property bool sloppy: false

                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string fileSearch: ","
                    property string emojis: ":"
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                }

                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                    property bool useCircleSelection: false
                }
            }

            /* =================================================================
             * [4.33] SIDEBAR (posiciones + módulos + toggles/sliders)
             * =============================================================== */
            property JsonObject sidebar: JsonObject {
                property string position: "default"
                property bool keepRightSidebarLoaded: true

                property JsonObject translator: JsonObject {
                    property bool enable: false
                    property int delay: 300
                }

                property JsonObject ai: JsonObject {
                    property bool textFadeIn: false
                    property bool showProviderAndModelButtons: true
                    property list<string> showProviders: ["google", "openrouter", "mistral"]
                }

                property JsonObject booru: JsonObject {
                    property bool allowNsfw: false
                    property string defaultProvider: "yandere"
                    property int limit: 20
                    property JsonObject zerochan: JsonObject {
                        property string username: "[unset]"
                    }
                }

                property JsonObject cornerOpen: JsonObject {
                    property bool enable: false
                    property bool bottom: false
                    property bool valueScroll: true
                    property bool clickless: false
                    property int cornerRegionWidth: 250
                    property int cornerRegionHeight: 5
                    property bool visualize: false
                    property bool clicklessCornerEnd: true
                    property int clicklessCornerVerticalOffset: 1
                }

                property JsonObject quickToggles: JsonObject {
                    property string style: "android" // classic, android
                    property JsonObject android: JsonObject {
                        property int columns: 5
                        property list<var> toggles: [
                            { "size": 2, "type": "network" },
                            { "size": 1, "type": "idleInhibitor" },
                            { "size": 2, "type": "darkMode" },
                            { "size": 1, "type": "mic" },
                            { "size": 2, "type": "audio" },
                            { "size": 2, "type": "nightLight" }
                        ]
                    }
                }

                property JsonObject quickSliders: JsonObject {
                    property bool enable: true
                    property bool showMic: true
                    property bool showVolume: true
                    property bool showBrightness: true
                }
            }

            /* =================================================================
             * [4.34] SCREEN RECORD / SCREEN SNIP (paths)
             * =============================================================== */
            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://", "")
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // empty => copy to clipboard only
            }

            /* =================================================================
             * [4.35] SONIDOS (eventos)
             * =============================================================== */
            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property string theme: "freedesktop"
            }

            /* =================================================================
             * [4.36] TIEMPO (formatos + pomodoro)
             * =============================================================== */
            property JsonObject time: JsonObject {
                // https://doc.qt.io/qt-6/qtime.html#toString
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string longDateFormat: "dd/MM/yyyy"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"

                // 0 Monday ... 6 Sunday
                property int firstDayOfWeek: 0

                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }

                property bool secondPrecision: false
            }

            /* =================================================================
             * [4.37] UPDATES (chequeo + umbrales)
             * =============================================================== */
            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120 // minutes
                property int adviseUpdateThreshold: 75
                property int stronglyAdviseUpdateThreshold: 200
            }

            /* =================================================================
             * [4.38] WALLPAPER SELECTOR (file dialog)
             * =============================================================== */
            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
            }

            /* =================================================================
             * [4.39] WINDOWS (decoraciones en apps del shell)
             * =============================================================== */
            property JsonObject windows: JsonObject {
                property bool showTitlebar: true
                property bool centerTitle: true
            }

            /* =================================================================
             * [4.40] HACKS (delays/workarounds)
             * =============================================================== */
            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }

            /* =================================================================
             * [4.41] WORK SAFETY (seguridad “NSFW” por red/archivos/links)
             * =============================================================== */
            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }

                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: [
                        "airport", "cafe", "college", "company", "eduroam",
                        "free", "guest", "public", "school", "university"
                    ]
                    property list<string> fileKeywords: [
                        "anime", "booru", "ecchi", "hentai", "yande.re", "konachan",
                        "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"
                    ]
                    property list<string> linkKeywords: [
                        "hentai", "porn", "sukebei", "hitomi.la", "rule34",
                        "gelbooru", "fanbox", "dlsite"
                    ]
                }
            }

            /* =================================================================
             * [4.42] WALLPAPERS (servicio + paths)
             * =============================================================== */
            property JsonObject wallpapers: JsonObject {
                property string service: "wallhaven" // "unsplash" or "wallhaven"
                property string sort: "favourites"
                property bool showAnimeResults: false // only for wallhaven

                property JsonObject paths: JsonObject {
                    property string download: FileUtils.trimFileProtocol(Directories.home + "/Pictures/Wallpapers")
                    property string nsfw: FileUtils.trimFileProtocol(Directories.home + "/Pictures/Wallpapers/NSFW")
                }
            }

            /* =================================================================
             * [4.43] WAFFLES (modo/tema tipo Windows-like)
             * - tweaks + bar + action center + calendar
             * =============================================================== */
            property JsonObject waffles: JsonObject {
                property JsonObject tweaks: JsonObject {
                    property bool switchHandlePositionFix: true
                    property bool smootherMenuAnimations: true
                    property bool smootherSearchBar: true
                }

                property JsonObject bar: JsonObject {
                    property bool bottom: true
                    property bool leftAlignApps: false
                }

                property JsonObject actionCenter: JsonObject {
                    property list<string> toggles: [
                        "network", "bluetooth", "easyEffects", "powerProfile",
                        "idleInhibitor", "nightLight", "darkMode", "antiFlashbang",
                        "cloudflareWarp", "mic", "musicRecognition", "notifications",
                        "onScreenKeyboard", "gameMode", "screenSnip", "colorPicker"
                    ]
                }

                property JsonObject calendar: JsonObject {
                    property bool force2CharDayOfWeek: true
                }
            }
        }
    }
}

