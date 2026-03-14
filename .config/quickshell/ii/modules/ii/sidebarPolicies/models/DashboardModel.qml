import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: m
    visible: false

    // LOCALE PARA FECHA (elegible desde Settings)
    readonly property string dateLocaleId: (typeof Translation !== "undefined"
                                            && Translation
                                            && Translation.languageCode
                                            && String(Translation.languageCode).trim().length > 0)
        ? String(Translation.languageCode).trim()
        : Qt.locale().name
    readonly property var dateLocale: Qt.locale(dateLocaleId)

    property string timeHour: "00"
    property string timeMin: "00"
    property string timeSec: "00"
    property string dateString: ""
    property string greeting: Translation.tr("Greeting.Hello")

    function greetingFromHour(h) {
        if (h < 12) return Translation.tr("Greeting.GoodMorning")
        if (h < 18) return Translation.tr("Greeting.GoodAfternoon")
        return Translation.tr("Greeting.GoodEvening")
    }

    // --- INFO SISTEMA ---
    property string kernelVal: "..."
    property string kernelFull: "..."
    property string archVal: "..."
    property string osName: "..."
    property string hostName: "..."
    property string currentShell: "..."

    property string qsVer: "..."
    property string hyprVer: "..."

    property string pacmanVer: "..."
    property string yayVer: "..."          // si existe
    property string flatpakVer: "..."      // si existe
    property string snapVer: "..."         // si existe

    // --- Updates ---
    property string repoUpdates: "0"
    property string aurUpdates: "0"
    property string totalUpdates: "0"
    property string lastUpdateCheck: "--:--"

    // --- Paquetes / Salud del sistema ---
    property string pkgTotal: "0"
    property string pkgExplicit: "0"
    property string pkgDeps: "0"
    property string pkgForeign: "0"        // AUR/otros (pacman -Qm)
    property string pkgOrphans: "0"        // pacman -Qtdq

    property string snapCount: "0"
    property string flatpakCount: "0"

    property string pacmanCacheSize: "..."
    property string dmName: "none"         // sddm/gdm/lightdm/lxdm/none
    property string dmEnabled: "no"        // yes/no
    property string snapdEnabled: "no"     // yes/no

    // --- NUEVO: Boot / Display / Network ---
    property string bootloader: "..."
    property string bootMode: "..."
    property string bootEntry: "..."

    property string monitorSummary: "..."
    property string monitorDetail: "..."

    property string netIface: "..."
    property string netDown: "0 KB/s"
    property string netUp: "0 KB/s"
    property string wifiSsid: "-"
    property string wifiSignal: "-"
    property string wifiRate: "-"

    // DATOS DINÁMICOS (ResourceUsage)
    property real cpuProgress: (typeof ResourceUsage !== "undefined"
                                && ResourceUsage.cpuUsage !== undefined
                                && !isNaN(ResourceUsage.cpuUsage))
        ? ResourceUsage.cpuUsage : 0
    property string cpuVal: Math.round(cpuProgress * 100) + "%"

    property real ramProgress: (typeof ResourceUsage !== "undefined"
                                && ResourceUsage.memoryUsedPercentage !== undefined
                                && !isNaN(ResourceUsage.memoryUsedPercentage))
        ? ResourceUsage.memoryUsedPercentage : 0
    property string ramVal: Math.round(ramProgress * 100) + "%"

    property string upTimeVal: (typeof DateTime !== "undefined" && DateTime.uptime) ? DateTime.uptime : "..."

    // Discos y Procesos
    property string diskVal: "..."
    property string diskUsePct: "0%"
    property real diskProgress: 0.0
    property string ramDetail: "-- / --"
    property string processesVal: "0"

    // Temperaturas
    property string cpuTemp: "--°C"
    property string gpuTemp: "--°C"

    // CLIMA (i18n)
    function getW(prop, fallback) {
        if (typeof Weather === "undefined") return fallback
        const d = Weather.data
        if (!d) return fallback
        const v = d[prop]
        if (v === undefined || v === null) return fallback
        if (typeof v === "string" && v.trim().length === 0) return fallback
        return v
    }

    property string weatherTemp: String(getW("temp", "--"))
    property string weatherCode: String(getW("wCode", "113"))
    property string rawCity: String(getW("city", "Chalatenango"))
    property string weatherCity: rawCity === "Nueva San Salvador" ? "San Salvador" : rawCity
    property string wHum: String(getW("humidity", "0")) + "%"
    property string wVis: String(getW("visibility", "10")) + " km"

    readonly property bool weatherIsValid: {
        const t = parseFloat(m.weatherTemp)
        return (!isNaN(t) && isFinite(t)) || (m.weatherCode && m.weatherCode.length > 0)
    }

    function weatherKeyFromCode(code) {
        const c = code.toString()
        if (c === "113") return "Weather.Sunny"
        if (c === "116") return "Weather.PartlyCloudy"
        if (c === "119" || c === "122") return "Weather.Cloudy"
        if (["176", "263", "296", "302"].includes(c)) return "Weather.Rainy"
        if (["200", "389"].includes(c)) return "Weather.Storm"
        return "Weather.Unknown"
    }
    readonly property string weatherCondition: Translation.tr(weatherKeyFromCode(m.weatherCode))

    function weatherIconFromCode(code) {
        var c = code.toString()
        switch (c) {
            case "113": return "sunny"
            case "116": return "partly_cloudy_day"
            case "119":
            case "122": return "cloud"
            case "176":
            case "263":
            case "296":
            case "302": return "rainy"
            case "200":
            case "389": return "thunderstorm"
            default:    return "cloud"
        }
    }
    readonly property string weatherIconName: weatherIconFromCode(m.weatherCode)

    readonly property string weatherTone: {
        switch (m.weatherIconName) {
            case "sunny": return "primary"
            case "partly_cloudy_day": return "secondary"
            case "cloud": return "surface"
            case "rainy": return "tertiary"
            case "thunderstorm": return "error"
            default: return "surface"
        }
    }

    // Helper: parsea key=value
    function applyKeyValues(text) {
        const lines = String(text || "").trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line || line.indexOf("=") < 0) continue
            const k = line.slice(0, line.indexOf("=")).trim()
            const v = line.slice(line.indexOf("=") + 1).trim()

            switch (k) {
                case "kernel": m.kernelVal = v; break
                case "kernelFull": m.kernelFull = v; break
                case "arch": m.archVal = v; break
                case "qs": m.qsVer = v; break
                case "hypr": m.hyprVer = v; break
                case "shell": m.currentShell = v; break
                case "os": m.osName = v; break
                case "host": m.hostName = v; break
                case "pacman": m.pacmanVer = v; break
                case "yay": m.yayVer = v; break
                case "flatpakVer": m.flatpakVer = v; break
                case "snapVer": m.snapVer = v; break

                case "pkgTotal": m.pkgTotal = v; break
                case "pkgExplicit": m.pkgExplicit = v; break
                case "pkgDeps": m.pkgDeps = v; break
                case "pkgForeign": m.pkgForeign = v; break
                case "pkgOrphans": m.pkgOrphans = v; break
                case "snapCount": m.snapCount = v; break
                case "flatpakCount": m.flatpakCount = v; break
                case "pacmanCache": m.pacmanCacheSize = v; break
                case "dmName": m.dmName = v; break
                case "dmEnabled": m.dmEnabled = v; break
                case "snapdEnabled": m.snapdEnabled = v; break

                // Boot / Display / Network
                case "bootloader": m.bootloader = v; break
                case "bootMode": m.bootMode = v; break
                case "bootEntry": m.bootEntry = v; break
                case "monitorSummary": m.monitorSummary = v; break
                case "monitorDetail": m.monitorDetail = v; break

                case "netIface": m.netIface = v; break
                case "netDown": m.netDown = v; break
                case "netUp": m.netUp = v; break
                case "wifiSsid": m.wifiSsid = v; break
                case "wifiSignal": m.wifiSignal = v; break
                case "wifiRate": m.wifiRate = v; break

                default: break
            }
        }
    }

    // TIMER PRINCIPAL
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const d = new Date()
            m.timeHour = d.getHours().toString().padStart(2, "0")
            m.timeMin  = d.getMinutes().toString().padStart(2, "0")
            m.timeSec  = d.getSeconds().toString().padStart(2, "0")
            m.dateString = d.toLocaleDateString(m.dateLocale, "ddd, d MMM")
            m.greeting = m.greetingFromHour(d.getHours())
            if (d.getSeconds() % 3 === 0)
                procSystemStats.running = true
        }
    }

    // Updates (cada 15m)
    Timer {
        id: updateCheckTimer
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procUpdates.running = true
    }

    // Stats “lentos” (paquetes/cache/DM + boot/monitores) cada 30m
    Timer {
        id: slowStatsTimer
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procPkgStats.running = true
            procBootDisplay.running = true
        }
    }

    // Network (rápido) cada 1s
    Timer {
        id: netTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procNet.running = true
    }

    Component.onCompleted: {
        procStaticInfo.running = true
        procSystemStats.running = true
        procUpdates.running = true
        procPkgStats.running = true
        procBootDisplay.running = true
        procNet.running = true
    }

    // 1) INFO ESTÁTICA (tolerante: nunca falla por falta de comandos)
    Process {
        id: procStaticInfo
        command: ["bash", "-lc",
            "set +e; " +
            "printf 'kernel=%s\\n' \"$(uname -r 2>/dev/null)\"; " +
            "printf 'kernelFull=%s\\n' \"$(uname -srvmo 2>/dev/null || uname -a 2>/dev/null)\"; " +
            "printf 'arch=%s\\n' \"$(uname -m 2>/dev/null)\"; " +
            "if command -v qs >/dev/null 2>&1; then printf 'qs=%s\\n' \"$(qs --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'qs=not-installed\\n'; fi; " +
            "if command -v hyprctl >/dev/null 2>&1; then printf 'hypr=%s\\n' \"$(hyprctl version 2>/dev/null | awk '/Tag/ {print $2; exit}')\"; else printf 'hypr=not-available\\n'; fi; " +
            "printf 'shell=%s\\n' \"$(basename \"${SHELL:-sh}\")\"; " +
            "printf 'os=%s\\n' \"$(. /etc/os-release 2>/dev/null; echo ${PRETTY_NAME:-Unknown})\"; " +
            "printf 'host=%s\\n' \"$(hostname 2>/dev/null)\"; " +
            "if command -v pacman >/dev/null 2>&1; then printf 'pacman=%s\\n' \"$(pacman --version 2>/dev/null | awk 'NR==1{print $2}')\"; else printf 'pacman=not-installed\\n'; fi; " +
            "if command -v yay >/dev/null 2>&1; then printf 'yay=%s\\n' \"$(yay --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'yay=not-installed\\n'; fi; " +
            "if command -v flatpak >/dev/null 2>&1; then printf 'flatpakVer=%s\\n' \"$(flatpak --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'flatpakVer=not-installed\\n'; fi; " +
            "if command -v snap >/dev/null 2>&1; then printf 'snapVer=%s\\n' \"$(snap version 2>/dev/null | awk -F': ' '/snapd /{print $2; exit}')\"; else printf 'snapVer=not-installed\\n'; fi; "
        ]
        stdout: StdioCollector { onStreamFinished: m.applyKeyValues(text) }
    }

    // 2) STATS RÁPIDAS (RAM, DISCO, PROCESOS, TEMPS)
    Process {
        id: procSystemStats
        command: ["bash", "-lc",
            "set +e; " +
            "free -h 2>/dev/null | awk 'NR==2 {print $3 \" / \" $2}' && " +
            "df -h --output=avail / 2>/dev/null | tail -n 1 && " +
            "df -P / 2>/dev/null | awk 'NR==2 {print $5}' && " +
            "sh -c 'p=$(ps -ax 2>/dev/null | wc -l); if [ \"$p\" -gt 0 ]; then echo $((p-1)); else echo 0; fi' && " +
            "(sensors k10temp-* 2>/dev/null | grep -m1 'Tctl' | awk '{print $2}' | tr -d '+°C' || echo 0) && " +
            "(sensors amdgpu-* 2>/dev/null | grep -m1 'edge' | awk '{print $2}' | tr -d '+°C' || echo 0)"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text || "").trim().split("\n")
                if (lines.length >= 6) {
                    m.ramDetail = lines[0].trim()
                    m.diskVal = lines[1].trim()
                    m.diskUsePct = lines[2].trim()
                    const pct = parseFloat(m.diskUsePct)
                    m.diskProgress = (!isNaN(pct) && isFinite(pct)) ? (pct / 100.0) : 0.0
                    m.processesVal = lines[3].trim()

                    const cpuT = parseFloat(lines[4])
                    if (!isNaN(cpuT) && isFinite(cpuT)) m.cpuTemp = Math.round(cpuT) + "°C"

                    const gpuT = parseFloat(lines[5])
                    if (!isNaN(gpuT) && isFinite(gpuT)) m.gpuTemp = Math.round(gpuT) + "°C"
                }
            }
        }
    }

    // 3) UPDATES (lento)
    Process {
        id: procUpdates
        command: ["bash", "-lc",
            "set +e; " +
            "repo=0; aur=0; " +
            "if command -v checkupdates >/dev/null 2>&1; then repo=$(checkupdates 2>/dev/null | wc -l); fi; " +
            "if command -v yay >/dev/null 2>&1; then aur=$(yay -Qua 2>/dev/null | wc -l); fi; " +
            "printf '%s\\n' \"$repo\"; " +
            "printf '%s\\n' \"$aur\"; "
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text || "").trim().split("\n")
                if (lines.length >= 2) {
                    m.repoUpdates = lines[0].trim()
                    m.aurUpdates = lines[1].trim()

                    const repo = parseInt(m.repoUpdates) || 0
                    const aur = parseInt(m.aurUpdates) || 0
                    m.totalUpdates = String(repo + aur)

                    const d = new Date()
                    m.lastUpdateCheck =
                        d.getHours().toString().padStart(2,'0') + ":" +
                        d.getMinutes().toString().padStart(2,'0')
                }
            }
        }
    }

    // 4) PAQUETES / HUÉRFANOS / CACHE / SNAP/FLATPAK / DM (muy lento)
    Process {
        id: procPkgStats
        command: ["bash", "-lc",
            "set +e; " +
            // Paquetes pacman
            "printf 'pkgTotal=%s\\n' \"$(pacman -Q 2>/dev/null | wc -l)\"; " +
            "printf 'pkgExplicit=%s\\n' \"$(pacman -Qe 2>/dev/null | wc -l)\"; " +
            "printf 'pkgDeps=%s\\n' \"$(pacman -Qd 2>/dev/null | wc -l)\"; " +
            "printf 'pkgForeign=%s\\n' \"$(pacman -Qm 2>/dev/null | wc -l)\"; " +
            "o=$(pacman -Qtdq 2>/dev/null | wc -l); printf 'pkgOrphans=%s\\n' \"$o\"; " +

            // Cache pacman (tamaño)
            "if command -v du >/dev/null 2>&1; then " +
                "c=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}'); " +
                "[ -z \"$c\" ] && c='0B'; " +
                "printf 'pacmanCache=%s\\n' \"$c\"; " +
            "else printf 'pacmanCache=...\\n'; fi; " +

            // Snap / snapd
            "if command -v snap >/dev/null 2>&1; then " +
                "sc=$(snap list 2>/dev/null | awk 'NR>1{c++} END{print c+0}'); " +
                "printf 'snapCount=%s\\n' \"$sc\"; " +
            "else printf 'snapCount=0\\n'; fi; " +
            "if command -v systemctl >/dev/null 2>&1; then " +
                "systemctl is-enabled --quiet snapd.socket 2>/dev/null; " +
                "if [ $? -eq 0 ]; then printf 'snapdEnabled=yes\\n'; else printf 'snapdEnabled=no\\n'; fi; " +
            "else printf 'snapdEnabled=no\\n'; fi; " +

            // Flatpak
            "if command -v flatpak >/dev/null 2>&1; then " +
                "fc=$(flatpak list 2>/dev/null | wc -l); " +
                "printf 'flatpakCount=%s\\n' \"$fc\"; " +
            "else printf 'flatpakCount=0\\n'; fi; " +

            // Display manager (prioridad simple)
            "dm='none'; dmen='no'; " +
            "if command -v systemctl >/dev/null 2>&1; then " +
                "for s in sddm.service gdm.service lightdm.service lxdm.service; do " +
                    "systemctl is-enabled --quiet \"$s\" 2>/dev/null; " +
                    "if [ $? -eq 0 ]; then dm=\"${s%%.*}\"; dmen='yes'; break; fi; " +
                "done; " +
            "fi; " +
            "printf 'dmName=%s\\n' \"$dm\"; " +
            "printf 'dmEnabled=%s\\n' \"$dmen\"; "
        ]
        stdout: StdioCollector { onStreamFinished: m.applyKeyValues(text) }
    }

    // 5) Bootloader + monitores (muy lento)
    Process {
    id: procBootDisplay
    command: ["bash", "-lc",
        "set +e; " +

        // Boot Mode
        "if [ -d /sys/firmware/efi ]; then printf 'bootMode=UEFI\\n'; else printf 'bootMode=BIOS\\n'; fi; " +

        // Bootloader detection (heurístico pero más robusto)
        "bl='unknown'; " +
        "if command -v bootctl >/dev/null 2>&1; then " +
            "bootctl is-installed 2>/dev/null | grep -qi yes && bl='systemd-boot'; " +
        "fi; " +
        "if [ \"$bl\" = 'unknown' ]; then " +
            "if [ -f /boot/grub/grub.cfg ] || [ -f /boot/grub2/grub.cfg ] || [ -d /boot/grub ]; then bl='grub'; fi; " +
        "fi; " +
        "if [ \"$bl\" = 'unknown' ] && [ -d /boot/EFI ] && find /boot/EFI -maxdepth 3 -iname 'refind*.efi' 2>/dev/null | grep -q .; then bl='refind'; fi; " +
        "printf 'bootloader=%s\\n' \"$bl\"; " +

        // Boot Entry (solo útil si systemd-boot)
        "be='-'; " +
        "if [ \"$bl\" = 'systemd-boot' ] && command -v bootctl >/dev/null 2>&1; then " +
            "tmp=$(bootctl status 2>/dev/null | awk -F': ' '/^Default (Boot Loader )?Entry/ {print $2; exit}'); " +
            "tmp=$(printf '%s' \"$tmp\" | tr -cd '[:print:]'); " +   // limpia caracteres raros
            "[ -n \"$tmp\" ] && be=\"$tmp\"; " +
        "fi; " +
        "printf 'bootEntry=%s\\n' \"$be\"; " +

        // Monitores (Hyprland)
        "ms='not-available'; md='not-available'; " +
        "if command -v hyprctl >/dev/null 2>&1; then " +
            "count=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/ {c++} END{print c+0}'); " +
            "line=$(hyprctl monitors 2>/dev/null | awk '/@[0-9]/{print; exit}'); " +
            "res=$(echo \"$line\" | grep -oE '[0-9]{3,5}x[0-9]{3,5}' | head -n1); " +
            "hz=$(echo \"$line\" | grep -oE '@[0-9]+(\\.[0-9]+)?' | tr -d '@' | head -n1); " +
            "[ -z \"$res\" ] && res='?x?'; [ -z \"$hz\" ] && hz='?'; " +
            "ms=\"${res}@${hz}Hz x${count}\"; " +
            "md=$(hyprctl monitors 2>/dev/null | awk ' " +
                "/^Monitor/ {m=$2} " +
                "/@[0-9]/ && m!=\"\" && seen[m]==0 {res=$1; hz=$2; gsub(/@/,\"\",hz); printf \"%s: %s@%s \", m, res, hz; seen[m]=1} " +
                "/scale:/ && m!=\"\" {printf \"scale %s | \", $2} " +
                "END{print \"\"}' | sed 's/ | $//'); " +
            "[ -z \"$md\" ] && md='-'; " +
        "fi; " +
        "printf 'monitorSummary=%s\\n' \"$ms\"; " +
        "printf 'monitorDetail=%s\\n' \"$md\"; "
    ]
    stdout: StdioCollector { onStreamFinished: m.applyKeyValues(text) }
}


    // 6) Red: velocidad + Wi-Fi (rápido)
    Process {
        id: procNet
        command: ["bash", "-lc",
            "set +e; " +
            "iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}'); " +
            "[ -z \"$iface\" ] && iface='-'; " +
            "printf 'netIface=%s\\n' \"$iface\"; " +

            "if [ \"$iface\" = '-' ]; then " +
                "printf 'netDown=0 KB/s\\n'; printf 'netUp=0 KB/s\\n'; " +
                "printf 'wifiSsid=-\\n'; printf 'wifiSignal=-\\n'; printf 'wifiRate=-\\n'; " +
                "exit 0; " +
            "fi; " +

            // velocidad usando estado en /tmp
            "state=\"/tmp/qs_net_${iface}.state\"; " +
            "rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null); " +
            "tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null); " +
            "[ -z \"$rx\" ] && rx=0; [ -z \"$tx\" ] && tx=0; " +
            "now=$(date +%s); " +
            "if [ -f \"$state\" ]; then " +
                "read prx ptx pnow < \"$state\"; " +
                "dt=$((now - pnow)); [ $dt -le 0 ] && dt=1; " +
                "drx=$((rx - prx)); dtx=$((tx - ptx)); " +
                "[ $drx -lt 0 ] && drx=0; [ $dtx -lt 0 ] && dtx=0; " +
            "else " +
                "dt=1; drx=0; dtx=0; " +
            "fi; " +
            "echo \"$rx $tx $now\" > \"$state\"; " +

            "h(){ b=$1; " +
                "if [ $b -ge 1048576 ]; then awk -v x=$b 'BEGIN{printf \"%.1f MB/s\", x/1048576}'; " +
                "elif [ $b -ge 1024 ]; then awk -v x=$b 'BEGIN{printf \"%.0f KB/s\", x/1024}'; " +
                "else echo \"${b} B/s\"; fi; }; " +

            "down=$(h $((drx/dt))); up=$(h $((dtx/dt))); " +
            "printf 'netDown=%s\\n' \"$down\"; " +
            "printf 'netUp=%s\\n' \"$up\"; " +

            // Wi-Fi info (si existe iw)
            "ssid='-'; sig='-'; rate='-'; " +
            "if command -v iw >/dev/null 2>&1; then " +
                "ssid=$(iw dev \"$iface\" link 2>/dev/null | awk -F': ' '/SSID/ {print $2; exit}'); " +
                "[ -z \"$ssid\" ] && ssid='-'; " +
                "sig=$(iw dev \"$iface\" link 2>/dev/null | awk -F': ' '/signal/ {print $2; exit}'); " +
                "[ -z \"$sig\" ] && sig='-'; " +
                "rate=$(iw dev \"$iface\" link 2>/dev/null | awk -F': ' '/tx bitrate/ {print $2; exit}'); " +
                "[ -z \"$rate\" ] && rate='-'; " +
            "fi; " +
            "printf 'wifiSsid=%s\\n' \"$ssid\"; " +
            "printf 'wifiSignal=%s\\n' \"$sig\"; " +
            "printf 'wifiRate=%s\\n' \"$rate\"; "
        ]
        stdout: StdioCollector { onStreamFinished: m.applyKeyValues(text) }
    }
}

