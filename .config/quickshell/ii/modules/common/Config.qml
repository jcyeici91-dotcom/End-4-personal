pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common.functions

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 75
    property bool blockWrites: false

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

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

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.writeAdapter()
        }
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            property string panelFamily: "ii"

            property JsonObject policies: JsonObject {
                property int ai: 1
                property int weeb: 0
                property int wallpapers: 1
                property int translator: 0
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal! Make sure you answer precisely without hallucination and prefer bullet points over walls of text. You can have a friendly greeting at the beginning of the conversation, but don't repeat the user's question\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n"
                property string tool: "functions"
                property list<var> extraModels: [
                    {"openrouter": [
                        {title: "Gemini 2.5 Flash", value: "gemini-2.5-flash", modelProvider: "google"},
                    ]},
                    {"google": [
                    ]},
                    {"mistral": [
                    ]},
                ]
            }

            property JsonObject appearance: JsonObject {
                property bool enableAnimations: false
                
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2
                property int wrappedFrameThickness: 10
                property bool sharpMode: false
                property bool toggleWindowRounding: true
                property JsonObject fonts: JsonObject {
                    property bool enableCustom: false
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
                    property string accentColor: ""
                }
                property list<string> customColorSchemes: []
            }

            property JsonObject audio: JsonObject {
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1"
                property string update: "kitty -1 --hold=yes fish -i -c 'pkexec pacman -Syu'"
                property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
            }

            property JsonObject background: JsonObject {
                property bool enable: true
                property JsonObject widgets: JsonObject {
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy"
                        property real x: 100
                        property real y: 100
                        property string style: "cookie"
                        property string styleLocked: "cookie"
                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property string aiStylingModel: "gemini"
                            property int sides: 14
                            property string backgroundStyle: "cookie"
                            property string backgroundShape: "Arch"
                            property string dialNumberStyle: "full"
                            property string hourHandStyle: "fill"
                            property string minuteHandStyle: "medium"
                            property string secondHandStyle: "dot"
                            property string dateStyle: "bubble"
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
                            property bool colorful: false
                            property bool showColon: true
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
                    property JsonObject media: JsonObject {
                        property bool enable: true
                        property string placementStrategy: "free"
                        property real x: 800
                        property real y: 100
                        property bool useAlbumColors: true
                        property bool hideAllButtons: false
                        property bool showPreviousToggle: true
                        property bool tintArtCover: false
                        property string backgroundShape: "Circle"
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
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
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
                    property real workspaceZoom: 1.07
                    property bool enableSidebar: true
                    property real widgetsFactor: 1.2
                }
                property JsonObject mediaMode: JsonObject {
                    property bool enable: false
                    property bool togglePerMonitor: false
                    property string backgroundShape: "Square"
                    property bool enableBackgroundAnimation: true
                    property bool changeShellColor: true
                    
                    property bool showVisualizer: true
                    
                    property JsonObject backgroundAnimation: JsonObject {
                        property bool enable: true
                        property int speedScale: 10
                    }
                    property JsonObject syllable: JsonObject {
                        property int textHighlightStyle: 0
                    }
                    
                }
            }

            property JsonObject hyprland: JsonObject {
                property bool enableCustomConfig: true 
            }

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
                
                property bool bottom: false
                
                property int cornerStyle: 0

                property bool floatStyleShadow: true
                property bool borderless: false
                property string topLeftIcon: "spark"

                property int barBackgroundStyle: 1
                property bool crystalEffect: false

                property bool verbose: true
                property bool vertical: false

                property string groupBackgroundStyle: "rounded"
                
                
                property JsonObject mediaPlayer: JsonObject {
                    property bool useFixedSize: false
                    property int customSize: 250
                    property JsonObject lyrics: JsonObject {
                        property bool enable: false
                        property int customSize: 400
                        property string style: "scroller"
                        property bool useGradientMask: true
                    }
                }

                property JsonObject resources: JsonObject {
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                    
                    property bool showCpu: true
                    property bool showRam: true
                    property bool showTemperature: true
                    property bool showCat: true
                }
                property list<string> screenList: []
                
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
                    property int maxWindowCount: 20
                    property bool interactiveFocus: false
                    property int shown: 10
                    property bool showAppIcons: true
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useWorkspaceMap: true
                    property list<var> workspaceMap: [0, 10] 
                    property bool useNerdFont: false
                    property int activeIndicatorOpacity: 100
                    property bool dynamicWorkspaces: false
                }
                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true
                    property string city: ""
                    property bool useUSCS: false
                    property int fetchInterval: 10
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }
                property JsonObject layouts: JsonObject {
                    property list<var> left: [
                        { id: "policies_panel_button" },
                        { id: "active_window" }
                    ]
                    property list<var> center: [
                        { id: "music_player" },
                        { id: "workspaces", centered: true },
                        { id: "system_monitor" }
                    ]
                    property list<var> right: [
                        { id: "clock" },
                        { id: "system_tray" },
                        { id: "dashboard_panel_button" }
                    ]
                }
                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }
                property JsonObject sizes: JsonObject {
                    property int height: 40
                    property int width: 46
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            property JsonObject cheatsheet: JsonObject {
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

            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            property JsonObject crosshair: JsonObject {
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            property JsonObject dock: JsonObject {
                property bool enable: false
                property bool monochromeIcons: true
                property real height: 60
                property real hoverRegionHeight: 2
                property bool pinnedOnStartup: false
                property bool hoverToReveal: true
                property list<string> pinnedApps: [
                    "org.kde.dolphin", "kitty",]
                property list<string> ignoredAppRegexes: []
            }

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

            property JsonObject language: JsonObject {
                property string ui: "en_US"
                property JsonObject translator: JsonObject {
                    property string engine: "auto"
                    property string targetLanguage: "auto"
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: [ "org.kde.dolphin", "kitty", "cmake-gui"]
            }

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

            property JsonObject media: JsonObject {
                property bool filterDuplicatePlayers: true
                property string priorityPlayer: ""
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
            }

            property JsonObject osd: JsonObject {
                property int timeout: 2500
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

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
                property list<var> workspaceMap: [0,10]
                property bool showOpeningAnimation: true

                property JsonObject scrollingStyle: JsonObject {
                    
                    property int dimPercentage: 50
                    property string backgroundStyle: "blur"
                    property string zoomStyle: "in"
                }
            }

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

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            property JsonObject lyricsService: JsonObject {
                property bool enable: true
                property bool enableGenius: true
                property bool enableLrclib: true
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true
                property list<var> pinnedItems: [ "Fcitx" ]
                property bool filterPassive: true
            }

            property JsonObject update: JsonObject {
                property string scriptPath: ""
                property string scriptFlags: "--no-backup --no-confirm"
            }

            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

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

            property JsonObject sidebar: JsonObject {
                property string position: "default"
                property bool keepRightSidebarLoaded: true
                
                property bool floatStyle: false
                property int floatingGap: 12
                
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
                    property string style: "android"
                    property JsonObject android: JsonObject {
                        property int columns: 5
                        property list<var> toggles: [
                            { "size": 2, "type": "network" },
                            { "size": 1, "type": "idleInhibitor"  },
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

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://","")
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: ""
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string longDateFormat: "dd/MM/yyyy"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property int firstDayOfWeek: 0

                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
                property bool secondPrecision: false
            }

            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120
                property int adviseUpdateThreshold: 75
                property int stronglyAdviseUpdateThreshold: 200
            }
            
            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
                property list<var> directories: [
                    {"icon": "wallpaper", "name": "Wallpapers", "path": `${Directories.pictures}/Wallpapers`}
                ]
            }
            
            property JsonObject windows: JsonObject {
                property bool showTitlebar: true
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }

            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }
                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
                    property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
                    property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
                }
            }

            property JsonObject wallpapers: JsonObject {  
                property string service: "wallhaven"
                property string sort: "favourites"
                property bool showAnimeResults: false
                property JsonObject paths: JsonObject {
                    property string download: FileUtils.trimFileProtocol(`${Directories.home}/Pictures/Wallpapers`)
                    property string nsfw: FileUtils.trimFileProtocol(`${Directories.home}/Pictures/Wallpapers/NSFW`)
                }
            }

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
                    property list<string> toggles: [ "network", "bluetooth", "easyEffects", "powerProfile", "idleInhibitor", "nightLight", "darkMode", "antiFlashbang", "cloudflareWarp", "mic", "musicRecognition", "notifications", "onScreenKeyboard", "gameMode", "screenSnip", "colorPicker" ]
                }
                property JsonObject calendar: JsonObject {
                    property bool force2CharDayOfWeek: true
                }
            }
        }
    }
}
