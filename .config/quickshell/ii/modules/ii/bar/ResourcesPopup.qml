pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property string terminalCmd: "kitty"

    property bool open: false
    property Item hoverTarget: null
    property var widgetRect: Qt.rect(0, 0, 0, 0)

    // INTERRUPTOR MAESTRO 
    property bool enableAnimations: Config.options.appearance.enableAnimations

    // --- Lógica extraída para detectar si debe unirse o flotar ---
    readonly property bool isFloatOrHybrid: (Config.options.bar.cornerStyle === 1) || (Config.options.bar.barBackgroundStyle === 0) || (Config.options.bar.barBackgroundStyle === 3)
    readonly property int floatingGap: 12

    onOpenChanged: {
        if (open && hoverTarget) {
            let pos = hoverTarget.mapToItem(null, 0, 0)
            widgetRect = Qt.rect(pos.x, pos.y, hoverTarget.width, hoverTarget.height)
            procSystemStats.running = true
            procNet.running = true
            procUpdates.running = true
        }
    }

    property real openAnim: root.open ? 1.0 : 0.0
    Behavior on openAnim {
        enabled: root.enableAnimations // Desactiva la animación si el interruptor está apagado
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutQuart
        }
    }

    property bool useSystemLanguage: true
    readonly property var _locale: Qt.locale()
    readonly property string _localeName: _locale ? String(_locale.name || "") : ""
    readonly property bool _isSpanish: root.useSystemLanguage && (_localeName.toLowerCase().startsWith("es") || _localeName.toLowerCase().includes("_es"))

    function tr(key) {
        const en = {
            system: "System", temp: "Temp", updates: "Updates", packages: "Packages", info: "Info",
            processor: "CPU", ram: "Memory", used: "USED", free: "FREE", total: "TOTAL",
            swap: "Swap", network: "Network", disk: "Storage", na: "N/A"
        }
        const es = {
            system: "Procesos", temp: "Temp", updates: "Updates", packages: "Paquetes", info: "Info",
            processor: "CPU", ram: "Memoria", used: "USADO", free: "LIBRE", total: "TOTAL",
            swap: "Swap", network: "Red", disk: "Almacenamiento", na: "N/A"
        }
        const dict = root._isSpanish ? es : en
        return dict[key] !== undefined ? dict[key] : (en[key] !== undefined ? en[key] : key)
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB", "TB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }

    function clamp01(x) { 
        return Math.max(0, Math.min(1, x)) 
    }

    function memRatio() {
        const total = ResourceUsage.memoryTotal
        if (!total || total <= 0) return 0
        const used = ResourceUsage.memoryUsed !== undefined ? ResourceUsage.memoryUsed : 0
        return clamp01(used / total)
    }

    function swapRatio() {
        const total = ResourceUsage.swapTotal
        if (!total || total <= 0) return 0
        const used = ResourceUsage.swapUsed !== undefined ? ResourceUsage.swapUsed : 0
        return clamp01(used / total)
    }

    property string kernelVal: "..."
    property string osName: "..."
    property string currentShell: "..."
    property string uptimeVal: "..."
    property string qsVer: "..."
    property string hyprVer: "..."
    property string pacmanVer: "..."
    property string yayVer: "..."
    property string flatpakVer: "..."
    property string snapVer: "..."
    property string repoUpdates: "0"
    property string aurUpdates: "0"
    property string totalUpdates: "0"
    property string lastUpdateCheck: "--:--"
    property string pkgTotal: "0"
    property string pkgExplicit: "0"
    property string pkgOrphans: "0"
    property string pkgAur: "0"
    property string snapCount: "0"
    property string flatpakCount: "0"
    property string pacmanCacheSize: "..."
    property string cpuTemp: "N/A"
    property string gpuTemp: "N/A"
    property real cpuTemp01: 0
    property real gpuTemp01: 0
    property string processesVal: "0"
    
    property string netDownStr: "0 B/s"
    property string netUpStr: "0 B/s"
    property string netTotalStr: "0 B"
    property var rxHistory: Array(30).fill(0)
    property var txHistory: Array(30).fill(0)
    
    property var disks: [{ device: "Cargando...", size: "0G", used: "0G", avail: "0G", pct: 0, pct01: 0.0, mount: "" }]
    property int currentDiskIndex: 0
    readonly property var currentDisk: root.disks[root.currentDiskIndex] !== undefined ? root.disks[root.currentDiskIndex] : { device: "N/A", size: "0", used: "0", avail: "0", pct: 0, pct01: 0.0, mount: "" }

    property int optWidth: 640 
    property int optSpacing: 16

    component WaveFill: Item {
        id: wroot
        anchors.fill: parent
        clip: true
        required property real value
        required property color color

        Rectangle {
            width: Math.max(wroot.width, wroot.height) * 2.8
            height: width
            x: (wroot.width - width) / 2
            y: wroot.height - (wroot.height * wroot.value)
            radius: width * 0.46
            color: wroot.color
            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 7000
                loops: Animation.Infinite
                running: root.open && root.enableAnimations // Detiene la ola de fondo si no hay animaciones
            }
        }
    }

    Item {
        id: logic
        visible: false

        function applyKeyValues(text) {
            const lines = String(text || "").trim().split("\n")
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (!line || line.indexOf("=") < 0) continue
                const k = line.slice(0, line.indexOf("=")).trim()
                const v = line.slice(line.indexOf("=") + 1).trim()
                switch (k) {
                    case "kernel": root.kernelVal = v; break
                    case "uptime": root.uptimeVal = v; break
                    case "qs": root.qsVer = v; break
                    case "hypr": root.hyprVer = v; break
                    case "shell": root.currentShell = v; break
                    case "os": root.osName = v; break
                    case "pacman": root.pacmanVer = v; break
                    case "yay": root.yayVer = v; break
                    case "flatpakVer": root.flatpakVer = v; break
                    case "snapVer": root.snapVer = v; break
                    case "pkgTotal": root.pkgTotal = v; break
                    case "pkgExplicit": root.pkgExplicit = v; break
                    case "pkgOrphans": root.pkgOrphans = v; break
                    case "pkgAur": root.pkgAur = v; break
                    case "snapCount": root.snapCount = v; break
                    case "flatpakCount": root.flatpakCount = v; break
                    case "pacmanCache": root.pacmanCacheSize = v; break
                    case "repoUpdates": root.repoUpdates = v; break
                    case "aurUpdates": root.aurUpdates = v; break
                    
                    case "netRaw":
                        let netParts = v.split("|")
                        let dRate = parseFloat(netParts[0])
                        let uRate = parseFloat(netParts[1])
                        
                        if (!isNaN(dRate) && !isNaN(uRate)) {
                            root.netDownStr = root.formatBytes(dRate) + "/s"
                            root.netUpStr = root.formatBytes(uRate) + "/s"
                            root.netTotalStr = root.formatBytes(dRate + uRate) + "/s"

                            let tempRx = root.rxHistory
                            let tempTx = root.txHistory
                            tempRx.push(dRate)
                            tempRx.shift()
                            tempTx.push(uRate)
                            tempTx.shift()
                            root.rxHistory = tempRx
                            root.txHistory = tempTx
                            
                            if (root.open) {
                                netGraphCanvas.requestPaint()
                            }
                        }
                        break
                        
                    case "disks":
                        let dList = v.split(";")
                        let parsedDisks = []
                        for(let d = 0; d < dList.length; d++) {
                            let discStr = dList[d]
                            if(!discStr) continue
                            let parts = discStr.split("|") 
                            if(parts.length >= 6) {
                                let pVal = parseFloat(parts[4].replace("%",""))
                                parsedDisks.push({
                                    device: parts[0],
                                    size: parts[1],
                                    used: parts[2],
                                    avail: parts[3],
                                    pct: isNaN(pVal) ? 0 : pVal,
                                    pct01: isNaN(pVal) ? 0 : (pVal / 100.0),
                                    mount: parts[5]
                                })
                            }
                        }
                        if (parsedDisks.length > 0) {
                            root.disks = parsedDisks
                            if (root.currentDiskIndex >= parsedDisks.length) {
                                root.currentDiskIndex = 0
                            }
                        }
                        break
                }
            }
        }

        Component.onCompleted: {
            procStaticInfo.running = true
            procPkgStats.running = true
        }

        Timer { 
            interval: 2000 
            running: root.open 
            repeat: true 
            triggeredOnStart: true 
            onTriggered: procSystemStats.running = true 
        }
        
        Timer { 
            interval: 1000 
            running: root.open 
            repeat: true 
            triggeredOnStart: true 
            onTriggered: procNet.running = true 
        }
        
        Timer { 
            interval: 1800000 
            running: true 
            repeat: true 
            triggeredOnStart: false 
            onTriggered: procPkgStats.running = true 
        }

        Process {
            id: procStaticInfo
            command: ["bash", "-lc",
                "set +e; " +
                "printf 'kernel=%s\\n' \"$(uname -r 2>/dev/null)\"; " +
                "printf 'uptime=%s\\n' \"$(uptime -p 2>/dev/null | sed 's/up //')\"; " +
                "if command -v qs >/dev/null 2>&1; then printf 'qs=%s\\n' \"$(qs --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'qs=N/A\\n'; fi; " +
                "if command -v hyprctl >/dev/null 2>&1; then printf 'hypr=%s\\n' \"$(hyprctl version 2>/dev/null | awk '/Tag/ {print $2; exit}')\"; else printf 'hypr=N/A\\n'; fi; " +
                "printf 'shell=%s\\n' \"$(basename \"${SHELL:-sh}\")\"; " +
                "printf 'os=%s\\n' \"$(. /etc/os-release 2>/dev/null; echo ${PRETTY_NAME:-Unknown})\"; " +
                "if command -v pacman >/dev/null 2>&1; then printf 'pacman=%s\\n' \"$(pacman --version 2>/dev/null | awk 'NR==1{print $2}')\"; else printf 'pacman=N/A\\n'; fi; " +
                "if command -v yay >/dev/null 2>&1; then printf 'yay=%s\\n' \"$(yay --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'yay=N/A\\n'; fi; " +
                "if command -v flatpak >/dev/null 2>&1; then printf 'flatpakVer=%s\\n' \"$(flatpak --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'flatpakVer=N/A\\n'; fi; " +
                "if command -v snap >/dev/null 2>&1; then printf 'snapVer=%s\\n' \"$(snap version 2>/dev/null | awk -F': ' '/snapd /{print $2; exit}')\"; else printf 'snapVer=N/A\\n'; fi; "
            ]
            stdout: StdioCollector { onStreamFinished: logic.applyKeyValues(text) }
        }

        Process {
            id: procPkgStats
            command: ["bash", "-lc",
                "set +e; " +
                "printf 'pkgTotal=%s\\n' \"$(pacman -Q 2>/dev/null | wc -l)\"; " +
                "printf 'pkgExplicit=%s\\n' \"$(pacman -Qe 2>/dev/null | wc -l)\"; " +
                "printf 'pkgAur=%s\\n' \"$(pacman -Qm 2>/dev/null | wc -l)\"; " +
                "o=$(pacman -Qtdq 2>/dev/null | wc -l); printf 'pkgOrphans=%s\\n' \"$o\"; " +
                "if command -v du >/dev/null 2>&1; then c=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}'); [ -z \"$c\" ] && c='0B'; printf 'pacmanCache=%s\\n' \"$c\"; else printf 'pacmanCache=...\\n'; fi; " +
                "if command -v snap >/dev/null 2>&1; then sc=$(snap list 2>/dev/null | awk 'NR>1{c++} END{print c+0}'); printf 'snapCount=%s\\n' \"$sc\"; else printf 'snapCount=0\\n'; fi; " +
                "if command -v flatpak >/dev/null 2>&1; then fc=$(flatpak list 2>/dev/null | wc -l); printf 'flatpakCount=%s\\n' \"$fc\"; else printf 'flatpakCount=0\\n'; fi; "
            ]
            stdout: StdioCollector { onStreamFinished: logic.applyKeyValues(text) }
        }

        Process {
            id: procUpdates
            command: ["bash", "-lc",
                "set +e; repo=0; aur=0; " +
                "if command -v checkupdates >/dev/null 2>&1; then repo=$(checkupdates 2>/dev/null | wc -l); fi; " +
                "if command -v yay >/dev/null 2>&1; then aur=$(yay -Qua 2>/dev/null | wc -l); fi; " +
                "printf 'repoUpdates=%s\\n' \"$repo\"; " +
                "printf 'aurUpdates=%s\\n' \"$aur\"; "
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    logic.applyKeyValues(text)
                    const repo = parseInt(root.repoUpdates) || 0
                    const aur = parseInt(root.aurUpdates) || 0
                    root.totalUpdates = String(repo + aur)
                    const d = new Date()
                    root.lastUpdateCheck = d.getHours().toString().padStart(2,'0') + ":" + d.getMinutes().toString().padStart(2,'0')
                }
            }
        }

        Process {
            id: procSystemStats
            command: ["bash", "-lc",
                "set +e; " +
                "d=$(df -h | awk '$1 ~ /^\\/dev\\// && $1 !~ /loop/ {name=$1; gsub(\"/dev/\",\"\",name); print name\"|\"$2\"|\"$3\"|\"$4\"|\"$5\"|\"$6}' | paste -sd \";\" -); printf 'disks=%s\\n' \"$d\" && " +
                "sh -c 'p=$(ps -ax 2>/dev/null | wc -l); if [ \"$p\" -gt 0 ]; then echo $((p-1)); else echo 0; fi' && " +
                "(sensors k10temp-* 2>/dev/null | grep -m1 'Tctl' | awk '{print $2}' | tr -d '+°C' || echo 0) && " +
                "(sensors amdgpu-* 2>/dev/null | grep -m1 'edge' | awk '{print $2}' | tr -d '+°C' || echo 0)"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = String(text || "").trim().split("\n")
                    if(lines.length > 0) logic.applyKeyValues(lines[0]) 
                    if (lines.length >= 4) {
                        root.processesVal = lines[1].trim()
                        const cpuT = parseFloat(lines[2])
                        if (!isNaN(cpuT) && isFinite(cpuT)) {
                            root.cpuTemp = Math.round(cpuT) + "°C"
                            root.cpuTemp01 = root.clamp01((cpuT - 35) / 50)
                        }
                        const gpuT = parseFloat(lines[3])
                        if (!isNaN(gpuT) && isFinite(gpuT)) {
                            root.gpuTemp = Math.round(gpuT) + "°C"
                            root.gpuTemp01 = root.clamp01((gpuT - 35) / 50)
                        }
                    }
                }
            }
        }

        Process {
            id: procNet
            command: ["bash", "-lc",
                "set +e; iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}'); [ -z \"$iface\" ] && iface='-'; if [ \"$iface\" = '-' ]; then printf 'netRaw=0|0\\n'; exit 0; fi; state=\"/tmp/qs_net_${iface}.state\"; rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null); tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null); [ -z \"$rx\" ] && rx=0; [ -z \"$tx\" ] && tx=0; now=$(date +%s); if [ -f \"$state\" ]; then read prx ptx pnow < \"$state\"; dt=$((now - pnow)); [ $dt -le 0 ] && dt=1; drx=$((rx - prx)); dtx=$((tx - ptx)); [ $drx -lt 0 ] && drx=0; [ $dtx -lt 0 ] && dtx=0; else dt=1; drx=0; dtx=0; fi; echo \"$rx $tx $now\" > \"$state\"; printf 'netRaw=%s|%s\\n' \"$((drx/dt))\" \"$((dtx/dt))\"; "
            ]
            stdout: StdioCollector { onStreamFinished: logic.applyKeyValues(text) }
        }

        Process {
            id: runSystemUpdate
            command: [root.terminalCmd, "-e", "fish", "-c", "actualizar"]
        }
    }

    readonly property var tabList: [
        { id: 0, icon: "memory", label: root.tr("system") },
        { id: 1, icon: "device_thermostat", label: root.tr("temp") },
        { id: 2, icon: "update", label: root.tr("updates") },
        { id: 3, icon: "inventory_2", label: root.tr("packages") },
        { id: 4, icon: "info", label: root.tr("info") }
    ]

    Loader {
        id: popupLoader
        active: true
        sourceComponent: PanelWindow {
            id: panelWindow

            visible: root.open || root.openAnim > 0.0
            color: "transparent"

            readonly property real baseRadius: Appearance.rounding.windowRounding
            readonly property int contentW: root.optWidth + (baseRadius * 2)
            readonly property int contentH: mainLayout.implicitHeight + (baseRadius * 2) + 20

            implicitWidth: contentW
            implicitHeight: contentH

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:resourcesPopup"
            WlrLayershell.layer: WlrLayer.Overlay

            readonly property real barThickness: Config.options.bar.vertical ? (Config.options.bar.sizes.width || 40) : (Config.options.bar.sizes.height || 40)
            readonly property bool isVertical: Config.options.bar.vertical
            readonly property bool isBottomRight: Config.options.bar.bottom
            readonly property string barEdge: isVertical ? (isBottomRight ? "right" : "left") : (isBottomRight ? "bottom" : "top")

            anchors {
                top: isVertical || !isBottomRight
                bottom: !isVertical && isBottomRight
                left: !isVertical || !isBottomRight
                right: isVertical && isBottomRight
            }

            // --- AQUI ESTA LA CORRECCIÓN DE LOS MÁRGENES Y BORDES ---
            margins {
                top: {
                    if (root.widgetRect.width === 0) return 0
                    if (isVertical) {
                        let targetY = root.widgetRect.y + (root.widgetRect.height / 2) - (panelWindow.contentH / 2)
                        let edgeGap = root.isFloatOrHybrid ? root.floatingGap : 0
                        return Math.max(edgeGap, Math.min(targetY, screen.height - panelWindow.contentH - edgeGap))
                    } else {
                        return !isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                    }
                }
                bottom: !isVertical && isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                left: {
                    if (root.widgetRect.width === 0) return 0
                    if (!isVertical) {
                        let targetX = root.widgetRect.x + (root.widgetRect.width / 2) - (panelWindow.contentW / 2)
                        let edgeGap = root.isFloatOrHybrid ? root.floatingGap : 0
                        return Math.max(edgeGap, Math.min(targetX, screen.width - panelWindow.contentW - edgeGap))
                    } else {
                        return !isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                    }
                }
                right: isVertical && isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
            }

            mask: Region { item: clipBox }

            Item {
                id: clipBox
                anchors.fill: parent
                clip: true

                Item {
                    id: slideContent
                    width: parent.width
                    height: parent.height
                    property real off: 1.0 - root.openAnim

                    x: panelWindow.barEdge === "left" ? -off * width : (panelWindow.barEdge === "right" ? off * width : 0)
                    y: panelWindow.barEdge === "top" ? -off * height : (panelWindow.barEdge === "bottom" ? off * height : 0)

                    Item {
                        id: background
                        anchors.fill: parent

                        Loader {
                            anchors.fill: parent
                            sourceComponent: root.isFloatOrHybrid ? floatingBgComponent : unitedBgComponent
                        }

                        Component {
                            id: floatingBgComponent
                            Rectangle {
                                anchors.centerIn: parent
                                width: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.height : parent.width
                                height: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.width : parent.height
                                color: Appearance.colors.colLayer0
                                radius: panelWindow.baseRadius
                                border.width: 1
                                border.color: Appearance.colors.colLayer0Border
                                rotation: {
                                    if (panelWindow.barEdge === "top") return 0
                                    if (panelWindow.barEdge === "bottom") return 180
                                    if (panelWindow.barEdge === "left") return -90
                                    if (panelWindow.barEdge === "right") return 90
                                }
                            }
                        }

                        Component {
                            id: unitedBgComponent
                            Shape {
                                id: bgShape
                                anchors.centerIn: parent
                                width: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.height : parent.width
                                height: (panelWindow.barEdge === "left" || panelWindow.barEdge === "right") ? parent.width : parent.height

                                rotation: {
                                    if (panelWindow.barEdge === "top") return 0
                                    if (panelWindow.barEdge === "bottom") return 180
                                    if (panelWindow.barEdge === "left") return -90
                                    if (panelWindow.barEdge === "right") return 90
                                }

                                preferredRendererType: Shape.CurveRenderer
                                property real w: width
                                property real h: height
                                property real rad: panelWindow.baseRadius

                                ShapePath {
                                    fillColor: Appearance.colors.colLayer0
                                    strokeColor: "transparent"
                                    strokeWidth: 0
                                    startX: 0
                                    startY: 0
                                    PathQuad { x: bgShape.rad; y: bgShape.rad; controlX: bgShape.rad; controlY: 0 }
                                    PathLine { x: bgShape.rad; y: bgShape.h - bgShape.rad }
                                    PathQuad { x: bgShape.rad * 2; y: bgShape.h; controlX: bgShape.rad; controlY: bgShape.h }
                                    PathLine { x: bgShape.w - bgShape.rad * 2; y: bgShape.h }
                                    PathQuad { x: bgShape.w - bgShape.rad; y: bgShape.h - bgShape.rad; controlX: bgShape.w - bgShape.rad; controlY: bgShape.h }
                                    PathLine { x: bgShape.w - bgShape.rad; y: bgShape.rad }
                                    PathQuad { x: bgShape.w; y: 0; controlX: bgShape.w - bgShape.rad; controlY: 0 }
                                    PathLine { x: 0; y: 0 }
                                }

                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Appearance.colors.colLayer0Border
                                    strokeWidth: 1
                                    capStyle: ShapePath.FlatCap
                                    startX: 0
                                    startY: 0
                                    PathQuad { x: bgShape.rad; y: bgShape.rad; controlX: bgShape.rad; controlY: 0 }
                                    PathLine { x: bgShape.rad; y: bgShape.h - bgShape.rad }
                                    PathQuad { x: bgShape.rad * 2; y: bgShape.h; controlX: bgShape.rad; controlY: bgShape.h }
                                    PathLine { x: bgShape.w - bgShape.rad * 2; y: bgShape.h }
                                    PathQuad { x: bgShape.w - bgShape.rad; y: bgShape.h - bgShape.rad; controlX: bgShape.w - bgShape.rad; controlY: bgShape.h }
                                    PathLine { x: bgShape.w - bgShape.rad; y: bgShape.rad }
                                    PathQuad { x: bgShape.w; y: 0; controlX: bgShape.w - bgShape.rad; controlY: 0 }
                                }
                            }
                        }
                    }

                    Item {
                        id: paddedContainer
                        anchors.fill: parent
                        anchors.topMargin: root.isFloatOrHybrid ? panelWindow.baseRadius : (panelWindow.barEdge === "top" ? panelWindow.baseRadius : (panelWindow.barEdge === "bottom" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius))
                        anchors.bottomMargin: root.isFloatOrHybrid ? panelWindow.baseRadius : (panelWindow.barEdge === "bottom" ? panelWindow.baseRadius : (panelWindow.barEdge === "top" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius))
                        anchors.leftMargin: root.isFloatOrHybrid ? panelWindow.baseRadius : (panelWindow.barEdge === "left" ? panelWindow.baseRadius : (panelWindow.barEdge === "right" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius))
                        anchors.rightMargin: root.isFloatOrHybrid ? panelWindow.baseRadius : (panelWindow.barEdge === "right" ? panelWindow.baseRadius : (panelWindow.barEdge === "left" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius))

                        ColumnLayout {
                            id: mainLayout
                            anchors.centerIn: parent
                            width: root.optWidth
                            spacing: root.optSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                spacing: 8 

                                Repeater {
                                    model: root.tabList
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 12
                                        color: flick.currentIndex === index ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                                        border.width: flick.currentIndex === index ? 1 : 0
                                        border.color: Appearance.colors.colLayer0Border
                                        
                                        Behavior on color { 
                                            enabled: root.enableAnimations
                                            ColorAnimation { 
                                                duration: 250
                                                easing.type: Easing.OutCubic 
                                            } 
                                        }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            MaterialSymbol {
                                                text: modelData.icon
                                                font.pixelSize: 16 
                                                color: flick.currentIndex === index ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                                Behavior on color { 
                                                    enabled: root.enableAnimations
                                                    ColorAnimation { 
                                                        duration: 250 
                                                    } 
                                                }
                                            }
                                            StyledText {
                                                text: modelData.label
                                                font.weight: Font.Bold
                                                font.pixelSize: 12 
                                                color: flick.currentIndex === index ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                                                Behavior on color { 
                                                    enabled: root.enableAnimations
                                                    ColorAnimation { 
                                                        duration: 250 
                                                    } 
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: flick.contentX = index * flick.width
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 380
                                clip: true

                                Flickable {
                                    id: flick
                                    anchors.fill: parent
                                    contentWidth: parent.width * root.tabList.length
                                    contentHeight: parent.height
                                    flickableDirection: Flickable.HorizontalFlick
                                    boundsBehavior: Flickable.StopAtBounds
                                    interactive: true

                                    onVisibleChanged: { 
                                        if (visible) contentX = 0 
                                    }

                                    property int currentIndex: Math.round(contentX / width)
                                    onDraggingChanged: { 
                                        if (!dragging) contentX = currentIndex * width 
                                    }
                                    
                                    Behavior on contentX { 
                                        enabled: root.enableAnimations
                                        NumberAnimation { 
                                            duration: 300
                                            easing.type: Easing.OutCubic 
                                        } 
                                    }

                                    Row {
                                        Item {
                                            width: flick.width
                                            height: flick.height
                                            
                                            GridLayout {
                                                anchors.fill: parent
                                                columns: 2
                                                rowSpacing: 12
                                                columnSpacing: 12

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 90
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true

                                                    WaveFill {
                                                        value: root.clamp01(ResourceUsage.cpuUsage !== undefined ? ResourceUsage.cpuUsage : 0)
                                                        color: Qt.alpha(Appearance.m3colors.m3primary, 0.25)
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 14
                                                        spacing: 12
                                                        Rectangle { 
                                                            width: 40
                                                            height: 40
                                                            radius: 10
                                                            color: Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4)
                                                            MaterialSymbol { 
                                                                anchors.centerIn: parent
                                                                text: "memory"
                                                                iconSize: 22
                                                                color: Appearance.m3colors.m3primary 
                                                            } 
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            StyledText { 
                                                                text: root.tr("processor")
                                                                font.bold: true
                                                                font.pixelSize: 14
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                text: root.processesVal + " procesos"
                                                                font.pixelSize: 11
                                                                color: Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                        StyledText { 
                                                            text: Math.round(root.clamp01(ResourceUsage.cpuUsage !== undefined ? ResourceUsage.cpuUsage : 0) * 100) + "%"
                                                            font.bold: true
                                                            font.pixelSize: 20
                                                            color: Appearance.m3colors.m3primary 
                                                        }
                                                    }
                                                }
                                                
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 90
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true

                                                    WaveFill {
                                                        value: root.memRatio()
                                                        color: Qt.alpha(Appearance.m3colors.m3primary, 0.25)
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 14
                                                        spacing: 12
                                                        Rectangle { 
                                                            width: 40
                                                            height: 40
                                                            radius: 10
                                                            color: Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4)
                                                            MaterialSymbol { 
                                                                anchors.centerIn: parent
                                                                text: "dns"
                                                                iconSize: 22
                                                                color: Appearance.m3colors.m3primary 
                                                            } 
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            StyledText { 
                                                                text: root.tr("ram")
                                                                font.bold: true
                                                                font.pixelSize: 14
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                text: root.formatGB(ResourceUsage.memoryUsed) + " / " + root.formatGB(ResourceUsage.memoryTotal)
                                                                font.pixelSize: 10
                                                                color: Appearance.colors.colOnSurfaceVariant
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true 
                                                            }
                                                        }
                                                        StyledText { 
                                                            text: Math.round(root.memRatio() * 100) + "%"
                                                            font.bold: true
                                                            font.pixelSize: 20
                                                            color: Appearance.m3colors.m3primary 
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 85
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true

                                                    WaveFill {
                                                        value: root.swapRatio()
                                                        color: Qt.alpha(Appearance.m3colors.m3secondary, 0.25)
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 14
                                                        spacing: 12
                                                        Rectangle { 
                                                            width: 36
                                                            height: 36
                                                            radius: 10
                                                            color: Qt.alpha(Appearance.colors.colSecondaryContainer, 0.4)
                                                            MaterialSymbol { 
                                                                anchors.centerIn: parent
                                                                text: "swap_horiz"
                                                                iconSize: 20
                                                                color: Appearance.m3colors.m3secondary 
                                                            } 
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            StyledText { 
                                                                text: root.tr("swap")
                                                                font.bold: true
                                                                font.pixelSize: 14
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                text: root.formatGB(ResourceUsage.swapUsed) + " / " + root.formatGB(ResourceUsage.swapTotal)
                                                                font.pixelSize: 10
                                                                color: Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                        StyledText { 
                                                            text: Math.round(root.swapRatio() * 100) + "%"
                                                            font.bold: true
                                                            font.pixelSize: 18
                                                            color: Appearance.m3colors.m3secondary 
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 85
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true
                                                    
                                                    WaveFill {
                                                        value: root.currentDisk.pct01
                                                        color: Qt.alpha(Appearance.m3colors.m3secondary, 0.25)
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onWheel: (wheel) => {
                                                            if (wheel.angleDelta.y > 0) {
                                                                root.currentDiskIndex = (root.currentDiskIndex - 1 + root.disks.length) % root.disks.length
                                                            } else {
                                                                root.currentDiskIndex = (root.currentDiskIndex + 1) % root.disks.length
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 14
                                                        spacing: 12
                                                        Rectangle { 
                                                            width: 36
                                                            height: 36
                                                            radius: 10
                                                            color: Qt.alpha(Appearance.colors.colSecondaryContainer, 0.4)
                                                            MaterialSymbol { 
                                                                anchors.centerIn: parent
                                                                text: "hard_drive"
                                                                iconSize: 20
                                                                color: Appearance.m3colors.m3secondary 
                                                            } 
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            RowLayout {
                                                                Layout.fillWidth: true
                                                                spacing: 4
                                                                MaterialSymbol { 
                                                                    text: "chevron_left"
                                                                    font.pixelSize: 16
                                                                    color: Appearance.colors.colOnSurfaceVariant
                                                                    MouseArea { 
                                                                        anchors.fill: parent
                                                                        onClicked: root.currentDiskIndex = (root.currentDiskIndex - 1 + root.disks.length) % root.disks.length 
                                                                    }
                                                                }
                                                                StyledText { 
                                                                    text: root.currentDisk.device
                                                                    font.bold: true
                                                                    font.pixelSize: 14
                                                                    color: Appearance.colors.colOnSurface
                                                                    Layout.fillWidth: true
                                                                    horizontalAlignment: Text.AlignHCenter
                                                                    elide: Text.ElideRight
                                                                }
                                                                MaterialSymbol { 
                                                                    text: "chevron_right"
                                                                    font.pixelSize: 16
                                                                    color: Appearance.colors.colOnSurfaceVariant
                                                                    MouseArea { 
                                                                        anchors.fill: parent
                                                                        onClicked: root.currentDiskIndex = (root.currentDiskIndex + 1) % root.disks.length 
                                                                    }
                                                                }
                                                            }
                                                            StyledText { 
                                                                text: root.currentDisk.avail + " libre de " + root.currentDisk.size
                                                                font.pixelSize: 10
                                                                color: Appearance.colors.colOnSurfaceVariant
                                                                Layout.alignment: Qt.AlignHCenter
                                                            }
                                                        }
                                                        StyledText { 
                                                            text: root.currentDisk.pct + "%"
                                                            font.bold: true
                                                            font.pixelSize: 18
                                                            color: Appearance.m3colors.m3secondary 
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.columnSpan: 2
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 120
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true

                                                    Canvas {
                                                        id: netGraphCanvas
                                                        anchors.fill: parent
                                                        anchors.margins: 1
                                                        
                                                        property color colorRx: Appearance.m3colors.m3tertiary
                                                        property color colorTx: Appearance.m3colors.m3error

                                                        onPaint: {
                                                            var ctx = getContext("2d")
                                                            ctx.clearRect(0, 0, width, height)

                                                            var maxVal = 1024
                                                            for(var i=0; i<root.rxHistory.length; i++) {
                                                                maxVal = Math.max(maxVal, root.rxHistory[i], root.txHistory[i])
                                                            }

                                                            function drawPath(history, col) {
                                                                ctx.beginPath()
                                                                ctx.moveTo(0, height)
                                                                for(var j=0; j<history.length; j++) {
                                                                    var x = (j / (history.length - 1)) * width
                                                                    var y = height - (history[j] / maxVal) * (height * 0.4)
                                                                    ctx.lineTo(x, y)
                                                                }
                                                                ctx.lineTo(width, height)
                                                                ctx.fillStyle = Qt.alpha(col, 0.15)
                                                                ctx.fill()
                                                                
                                                                ctx.beginPath()
                                                                for(var k=0; k<history.length; k++) {
                                                                    var x2 = (k / (history.length - 1)) * width
                                                                    var y2 = height - (history[k] / maxVal) * (height * 0.4)
                                                                    if(k===0) {
                                                                        ctx.moveTo(x2, y2)
                                                                    } else {
                                                                        ctx.lineTo(x2, y2)
                                                                    }
                                                                }
                                                                ctx.strokeStyle = col
                                                                ctx.lineWidth = 1.5
                                                                ctx.stroke()
                                                            }

                                                            drawPath(root.txHistory, colorTx)
                                                            drawPath(root.rxHistory, colorRx)
                                                        }
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 14
                                                        spacing: 16
                                                        
                                                        ColumnLayout {
                                                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                                            spacing: 6
                                                            RowLayout {
                                                                spacing: 8
                                                                MaterialSymbol { 
                                                                    text: "swap_vert"
                                                                    iconSize: 22
                                                                    color: Appearance.colors.colOnSurfaceVariant 
                                                                }
                                                                StyledText { 
                                                                    text: root.tr("network")
                                                                    font.bold: true
                                                                    font.pixelSize: 14
                                                                    color: Appearance.colors.colOnSurface 
                                                                }
                                                            }
                                                            StyledText { 
                                                                text: "Total: " + root.netTotalStr
                                                                font.pixelSize: 11
                                                                color: Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                        
                                                        Item { Layout.fillWidth: true }
                                                        
                                                        ColumnLayout {
                                                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                            spacing: 4
                                                            RowLayout {
                                                                spacing: 6
                                                                MaterialSymbol { 
                                                                    text: "arrow_downward"
                                                                    font.pixelSize: 14
                                                                    color: Appearance.m3colors.m3tertiary 
                                                                }
                                                                StyledText { 
                                                                    text: "Download"
                                                                    font.pixelSize: 12
                                                                    color: Appearance.colors.colOnSurfaceVariant 
                                                                }
                                                                Item { width: 10 }
                                                                StyledText { 
                                                                    text: root.netDownStr
                                                                    font.bold: true
                                                                    font.pixelSize: 13
                                                                    color: Appearance.colors.colOnSurface 
                                                                }
                                                            }
                                                            RowLayout {
                                                                spacing: 6
                                                                MaterialSymbol { 
                                                                    text: "arrow_upward"
                                                                    font.pixelSize: 14
                                                                    color: Appearance.m3colors.m3error 
                                                                }
                                                                StyledText { 
                                                                    text: "Upload"
                                                                    font.pixelSize: 12
                                                                    color: Appearance.colors.colOnSurfaceVariant 
                                                                }
                                                                Item { width: 23 }
                                                                StyledText { 
                                                                    text: root.netUpStr
                                                                    font.bold: true
                                                                    font.pixelSize: 13
                                                                    color: Appearance.colors.colOnSurface 
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            width: flick.width
                                            height: flick.height
                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 16
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true
                                                    
                                                    WaveFill {
                                                        value: root.cpuTemp01
                                                        color: Qt.alpha(Appearance.m3colors.m3error, 0.25)
                                                    }

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 16
                                                        MaterialSymbol { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "device_thermostat"
                                                            iconSize: 64
                                                            color: Appearance.m3colors.m3error 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "CPU"
                                                            font.bold: true
                                                            font.pixelSize: 20
                                                            color: Appearance.colors.colOnSurface 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: root.cpuTemp
                                                            font.pixelSize: 42
                                                            font.weight: Font.Black
                                                            color: Appearance.m3colors.m3error 
                                                        }
                                                        Rectangle {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            width: 140
                                                            height: 6
                                                            radius: 3
                                                            color: Qt.alpha(Appearance.colors.colOnSurface, 0.1)
                                                            Rectangle { 
                                                                height: parent.height
                                                                radius: 3
                                                                width: parent.width * root.cpuTemp01 * root.openAnim
                                                                color: Appearance.m3colors.m3error 
                                                            }
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true
                                                    
                                                    WaveFill {
                                                        value: root.gpuTemp01
                                                        color: Qt.alpha(Appearance.m3colors.m3primary, 0.25)
                                                    }

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 16
                                                        MaterialSymbol { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "thermostat"
                                                            iconSize: 64
                                                            color: Appearance.m3colors.m3primary 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "GPU"
                                                            font.bold: true
                                                            font.pixelSize: 20
                                                            color: Appearance.colors.colOnSurface 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: root.gpuTemp
                                                            font.pixelSize: 42
                                                            font.weight: Font.Black
                                                            color: Appearance.m3colors.m3primary 
                                                        }
                                                        Rectangle {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            width: 140
                                                            height: 6
                                                            radius: 3
                                                            color: Qt.alpha(Appearance.colors.colOnSurface, 0.1)
                                                            Rectangle { 
                                                                height: parent.height
                                                                radius: 3
                                                                width: parent.width * root.gpuTemp01 * root.openAnim
                                                                color: Appearance.m3colors.m3primary 
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            width: flick.width
                                            height: flick.height
                                            ColumnLayout {
                                                anchors.fill: parent
                                                spacing: 16
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 140
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    MaterialSymbol { 
                                                        text: "system_update_alt"
                                                        font.pixelSize: 130
                                                        color: Appearance.colors.colPrimary
                                                        opacity: 0.10
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: -10
                                                        anchors.verticalCenter: parent.verticalCenter 
                                                    }
                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 4
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: root.totalUpdates
                                                            font.pixelSize: 60
                                                            font.weight: Font.Black
                                                            color: Appearance.colors.colPrimary 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "Actualizaciones Pendientes"
                                                            font.bold: true
                                                            font.pixelSize: 16
                                                            color: Appearance.colors.colOnSurface 
                                                        }
                                                        StyledText { 
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "Última revisión: " + root.lastUpdateCheck
                                                            font.pixelSize: 12
                                                            color: Appearance.colors.colOnSurfaceVariant
                                                            opacity: 0.8 
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 90
                                                    spacing: 16
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 16
                                                        color: Appearance.colors.colLayer1
                                                        border.width: 1
                                                        border.color: Appearance.colors.colLayer0Border
                                                        ColumnLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6
                                                            MaterialSymbol { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: "archive"
                                                                font.pixelSize: 32
                                                                color: Appearance.m3colors.m3secondary 
                                                            }
                                                            StyledText { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: root.repoUpdates
                                                                font.pixelSize: 28
                                                                font.bold: true
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: "Repositorios"
                                                                font.pixelSize: 12
                                                                color: Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                    }
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 16
                                                        color: Appearance.colors.colLayer1
                                                        border.width: 1
                                                        border.color: Appearance.colors.colLayer0Border
                                                        ColumnLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6
                                                            MaterialSymbol { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: "build_circle"
                                                                font.pixelSize: 32
                                                                color: Appearance.m3colors.m3tertiary 
                                                            }
                                                            StyledText { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: root.aurUpdates
                                                                font.pixelSize: 28
                                                                font.bold: true
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: "AUR"
                                                                font.pixelSize: 12
                                                                color: Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 60
                                                    spacing: 16
                                                    
                                                    Rectangle { 
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 16
                                                        color: mouseCheck.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                                                        border.width: 1
                                                        border.color: Appearance.colors.colLayer0Border
                                                        Behavior on color { 
                                                            enabled: root.enableAnimations
                                                            ColorAnimation { 
                                                                duration: 200 
                                                            } 
                                                        }
                                                        MouseArea { 
                                                            id: mouseCheck
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: procUpdates.running = true 
                                                        }
                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 8
                                                            MaterialSymbol { 
                                                                text: "refresh"
                                                                font.pixelSize: 20
                                                                color: mouseCheck.containsMouse ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                            StyledText { 
                                                                text: "Comprobar"
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                                color: mouseCheck.containsMouse ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                    }
                                                    
                                                    Rectangle { 
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 16
                                                        color: mouseUpdate.containsMouse ? Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4) : Appearance.colors.colLayer1
                                                        border.width: 1
                                                        border.color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                                                        Behavior on color { 
                                                            enabled: root.enableAnimations
                                                            ColorAnimation { 
                                                                duration: 200 
                                                            } 
                                                        }
                                                        Behavior on border.color { 
                                                            enabled: root.enableAnimations
                                                            ColorAnimation { 
                                                                duration: 200 
                                                            } 
                                                        }
                                                        MouseArea {
                                                            id: mouseUpdate
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: { 
                                                                runSystemUpdate.running = true
                                                                root.open = false 
                                                            }
                                                        }
                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 8
                                                            MaterialSymbol { 
                                                                text: "terminal"
                                                                font.pixelSize: 20
                                                                color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                            StyledText { 
                                                                text: "Aplicar Actualización"
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                                color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant 
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            width: flick.width
                                            height: flick.height
                                            GridLayout {
                                                anchors.fill: parent
                                                columns: 2
                                                rowSpacing: 10
                                                columnSpacing: 10
                                                component PkgCard: Rectangle {
                                                    required property string title
                                                    required property string val
                                                    required property string iconName
                                                    property color icColor: Appearance.colors.colPrimary
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 16
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 16
                                                        spacing: 14
                                                        MaterialSymbol { 
                                                            text: iconName
                                                            font.pixelSize: 32
                                                            color: icColor 
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            StyledText { 
                                                                text: val
                                                                font.bold: true
                                                                font.pixelSize: 18
                                                                color: Appearance.colors.colOnSurface 
                                                            }
                                                            StyledText { 
                                                                text: title
                                                                font.pixelSize: 12
                                                                color: Appearance.colors.colOnSurfaceVariant
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true 
                                                            }
                                                        }
                                                    }
                                                }
                                                PkgCard { title: "Pacman"; val: root.pkgTotal; iconName: "package_2"; icColor: Appearance.m3colors.m3primary }
                                                PkgCard { title: "AUR (Externos)"; val: root.pkgAur; iconName: "build"; icColor: Appearance.m3colors.m3secondary }
                                                PkgCard { title: "Flatpaks"; val: root.flatpakCount; iconName: "box"; icColor: Appearance.m3colors.m3tertiary }
                                                PkgCard { title: "Snaps"; val: root.snapCount; iconName: "inventory"; icColor: Appearance.m3colors.m3error }
                                                PkgCard { title: "Huérfanos"; val: root.pkgOrphans; iconName: "delete_sweep"; icColor: Appearance.colors.colOnSurfaceVariant }
                                                PkgCard { title: "Caché Pacman"; val: root.pacmanCacheSize; iconName: "folder_zip"; icColor: Appearance.colors.colOnSurfaceVariant }
                                            }
                                        }

                                        Item {
                                            width: flick.width
                                            height: flick.height
                                            ColumnLayout {
                                                anchors.fill: parent
                                                spacing: 10
                                                component InfoRow: Rectangle {
                                                    required property string title
                                                    required property string val
                                                    required property string iconName
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 14
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 16
                                                        anchors.rightMargin: 24
                                                        anchors.topMargin: 12
                                                        anchors.bottomMargin: 12
                                                        spacing: 12
                                                        MaterialSymbol { 
                                                            text: iconName
                                                            font.pixelSize: 22
                                                            color: Appearance.colors.colPrimary 
                                                        }
                                                        StyledText { 
                                                            text: title
                                                            font.bold: true
                                                            font.pixelSize: 14
                                                            color: Appearance.colors.colOnSurface 
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        StyledText { 
                                                            text: val
                                                            font.pixelSize: 13
                                                            color: Appearance.colors.colOnSurfaceVariant
                                                            horizontalAlignment: Text.AlignRight
                                                            elide: Text.ElideRight
                                                            Layout.maximumWidth: 300 
                                                        }
                                                    }
                                                }
                                                InfoRow { title: "SO"; val: root.osName; iconName: "linux" }
                                                InfoRow { title: "Kernel"; val: root.kernelVal; iconName: "memory" }
                                                InfoRow { title: "Uptime"; val: root.uptimeVal; iconName: "schedule" }
                                                InfoRow { title: "Hyprland"; val: root.hyprVer; iconName: "layers" }
                                                InfoRow { title: "Quickshell"; val: root.qsVer; iconName: "code" }
                                                InfoRow { title: "Shell"; val: root.currentShell; iconName: "terminal" }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            function updateDismissable() {
                if (root.open) {
                    GlobalFocusGrab.addDismissable(panelWindow)
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow)
                }
            }

            Component.onCompleted: updateDismissable()
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
        }
    }

    Connections {
        target: root
        function onOpenChanged() {
            if (popupLoader.item) popupLoader.item.updateDismissable()
        }
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.open = false
        }
    }
}
