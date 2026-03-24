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

Item {
    id: root
    anchors.fill: parent

    property bool enableAnimations: Config.options.appearance !== undefined ? Config.options.appearance.enableAnimations : true
    property bool useSystemLanguage: true
    readonly property var _locale: Qt.locale()
    readonly property string _localeName: _locale ? String(_locale.name || "") : ""
    readonly property bool _isSpanish: root.useSystemLanguage && (_localeName.toLowerCase().startsWith("es") || _localeName.toLowerCase().includes("_es"))

    property string terminalCmd: "kitty"
    property int currentTab: 0 

    function tr(key) {
        const en = { system: "System", temp: "Temp", updates: "Updates", packages: "Packages", info: "Info", processor: "CPU", ram: "Memory", used: "USED", free: "FREE", total: "TOTAL", swap: "Swap", network: "Network", disk: "Storage", na: "N/A" }
        const es = { system: "Procesos", temp: "Temp", updates: "Updates", packages: "Paquetes", info: "Info", processor: "CPU", ram: "Memoria", used: "USADO", free: "LIBRE", total: "TOTAL", swap: "Swap", network: "Red", disk: "Almacenamiento", na: "N/A" }
        const dict = root._isSpanish ? es : en
        return dict[key] !== undefined ? dict[key] : (en[key] !== undefined ? en[key] : key)
    }

    function formatBytes(bytes) {
        if (bytes === 0 || bytes === undefined || isNaN(bytes)) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB", "TB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }

    function formatGB(bytes) {
        if (!bytes || bytes === 0 || isNaN(bytes)) return "0.0 GB"
        return (bytes / 1073741824).toFixed(1) + " GB"
    }

    function clamp01(x) { return Math.max(0, Math.min(1, x)) }

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

    property string hostName: "..."
    property string cpuModelName: "..."
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
    
     property string pkgDeps: (!isNaN(parseInt(root.pkgTotal)) && !isNaN(parseInt(root.pkgExplicit))) ? (parseInt(root.pkgTotal) - parseInt(root.pkgExplicit)).toString() : "0"

    property string cpuTemp: "0°C"
    property string gpuTemp: "0°C"
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

    function applyKeyValues(text) {
        const lines = String(text || "").trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line || line.indexOf("=") < 0) continue
            const k = line.slice(0, line.indexOf("=")).trim()
            const v = line.slice(line.indexOf("=") + 1).trim()
            switch (k) {
                case "host": root.hostName = v; break
                case "cpu": root.cpuModelName = v; break
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
                        let tempRx = root.rxHistory; let tempTx = root.txHistory
                        tempRx.push(dRate); tempRx.shift(); tempTx.push(uRate); tempTx.shift()
                        root.rxHistory = tempRx; root.txHistory = tempTx
                        if (root.visible) netGraphCanvas.requestPaint()
                    }
                    break
                case "disks":
                    let dList = v.split(";")
                    let parsedDisks = []
                    for(let d = 0; d < dList.length; d++) {
                        let discStr = dList[d]; if(!discStr) continue
                        let parts = discStr.split("|") 
                        if(parts.length >= 6) {
                            let pVal = parseFloat(parts[4].replace("%",""))
                            parsedDisks.push({
                                device: parts[0], size: parts[1], used: parts[2], avail: parts[3],
                                pct: isNaN(pVal) ? 0 : pVal, pct01: isNaN(pVal) ? 0 : (pVal / 100.0), mount: parts[5]
                            })
                        }
                    }
                    if (parsedDisks.length > 0) { root.disks = parsedDisks; if (root.currentDiskIndex >= parsedDisks.length) root.currentDiskIndex = 0 }
                    break
            }
        }
    }

        Component.onCompleted: { procStaticInfo.running = true; procPkgStats.running = true }
    Timer { interval: 3000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: procSystemStats.running = true }
    Timer { interval: 3000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: procNet.running = true }
    Timer { interval: 1800000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: procPkgStats.running = true }

    Process {
        id: procStaticInfo
        command: ["bash", "-lc", "set +e; printf 'kernel=%s\\n' \"$(uname -r 2>/dev/null)\"; printf 'uptime=%s\\n' \"$(uptime -p 2>/dev/null | sed 's/up //')\"; if command -v qs >/dev/null 2>&1; then printf 'qs=%s\\n' \"$(qs --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'qs=N/A\\n'; fi; if command -v hyprctl >/dev/null 2>&1; then printf 'hypr=%s\\n' \"$(hyprctl version 2>/dev/null | awk '/Tag/ {print $2; exit}')\"; else printf 'hypr=N/A\\n'; fi; printf 'shell=%s\\n' \"$(basename \"${SHELL:-sh}\")\"; printf 'os=%s\\n' \"$(. /etc/os-release 2>/dev/null; echo ${PRETTY_NAME:-Unknown})\"; if command -v pacman >/dev/null 2>&1; then printf 'pacman=%s\\n' \"$(pacman --version 2>/dev/null | awk 'NR==1{print $2}')\"; else printf 'pacman=N/A\\n'; fi; if command -v yay >/dev/null 2>&1; then printf 'yay=%s\\n' \"$(yay --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'yay=N/A\\n'; fi; if command -v flatpak >/dev/null 2>&1; then printf 'flatpakVer=%s\\n' \"$(flatpak --version 2>/dev/null | awk '{print $2}' | head -n1)\"; else printf 'flatpakVer=N/A\\n'; fi; if command -v snap >/dev/null 2>&1; then printf 'snapVer=%s\\n' \"$(snap version 2>/dev/null | awk -F': ' '/snapd /{print $2; exit}')\"; else printf 'snapVer=N/A\\n'; fi; printf 'host=%s\\n' \"$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null || echo 'PC')\"; printf 'cpu=%s\\n' \"$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}' || echo 'N/A')\"; "]
        stdout: StdioCollector { onStreamFinished: root.applyKeyValues(text) }
    }

    Process {
        id: procPkgStats
        command: ["bash", "-lc", "set +e; printf 'pkgTotal=%s\\n' \"$(pacman -Q 2>/dev/null | wc -l)\"; printf 'pkgExplicit=%s\\n' \"$(pacman -Qe 2>/dev/null | wc -l)\"; printf 'pkgAur=%s\\n' \"$(pacman -Qm 2>/dev/null | wc -l)\"; o=$(pacman -Qtdq 2>/dev/null | wc -l); printf 'pkgOrphans=%s\\n' \"$o\"; if command -v du >/dev/null 2>&1; then c=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}'); [ -z \"$c\" ] && c='0B'; printf 'pacmanCache=%s\\n' \"$c\"; else printf 'pacmanCache=...\\n'; fi; if command -v snap >/dev/null 2>&1; then sc=$(snap list 2>/dev/null | awk 'NR>1{c++} END{print c+0}'); printf 'snapCount=%s\\n' \"$sc\"; else printf 'snapCount=0\\n'; fi; if command -v flatpak >/dev/null 2>&1; then fc=$(flatpak list 2>/dev/null | wc -l); printf 'flatpakCount=%s\\n' \"$fc\"; else printf 'flatpakCount=0\\n'; fi; "]
        stdout: StdioCollector { onStreamFinished: root.applyKeyValues(text) }
    }

    Process {
        id: procUpdates
        command: ["bash", "-lc", "set +e; repo=0; aur=0; if command -v checkupdates >/dev/null 2>&1; then repo=$(checkupdates 2>/dev/null | wc -l); fi; if command -v yay >/dev/null 2>&1; then aur=$(yay -Qua 2>/dev/null | wc -l); fi; printf 'repoUpdates=%s\\n' \"$repo\"; printf 'aurUpdates=%s\\n' \"$aur\"; "]
        stdout: StdioCollector {
            onStreamFinished: {
                root.applyKeyValues(text)
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
        command: ["bash", "-lc", "set +e; d=$(df -h | awk '$1 ~ /^\\/dev\\// && $1 !~ /loop/ {name=$1; gsub(\"/dev/\",\"\",name); print name\"|\"$2\"|\"$3\"|\"$4\"|\"$5\"|\"$6}' | paste -sd \";\" -); printf 'disks=%s\\n' \"$d\" && sh -c 'p=$(ps -ax 2>/dev/null | wc -l); if [ \"$p\" -gt 0 ]; then echo $((p-1)); else echo 0; fi' && (sensors k10temp-* 2>/dev/null | grep -m1 'Tctl' | awk '{print $2}' | tr -d '+°C' || echo 0) && (sensors amdgpu-* 2>/dev/null | grep -m1 'edge' | awk '{print $2}' | tr -d '+°C' || echo 0)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text || "").trim().split("\n")
                if(lines.length > 0) root.applyKeyValues(lines[0]) 
                if (lines.length >= 4) {
                    root.processesVal = lines[1].trim()
                    const cpuT = parseFloat(lines[2]); if (!isNaN(cpuT) && isFinite(cpuT)) { root.cpuTemp = Math.round(cpuT) + "°C"; root.cpuTemp01 = root.clamp01((cpuT - 35) / 50) }
                    const gpuT = parseFloat(lines[3]); if (!isNaN(gpuT) && isFinite(gpuT)) { root.gpuTemp = Math.round(gpuT) + "°C"; root.gpuTemp01 = root.clamp01((gpuT - 35) / 50) }
                }
            }
        }
    }

    Process {
        id: procNet
        command: ["bash", "-lc", "set +e; iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}'); [ -z \"$iface\" ] && iface='-'; if [ \"$iface\" = '-' ]; then printf 'netRaw=0|0\\n'; exit 0; fi; state=\"/tmp/qs_net_${iface}.state\"; rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null); tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null); [ -z \"$rx\" ] && rx=0; [ -z \"$tx\" ] && tx=0; now=$(date +%s); if [ -f \"$state\" ]; then read prx ptx pnow < \"$state\"; dt=$((now - pnow)); [ $dt -le 0 ] && dt=1; drx=$((rx - prx)); dtx=$((tx - ptx)); [ $drx -lt 0 ] && drx=0; [ $dtx -lt 0 ] && dtx=0; else dt=1; drx=0; dtx=0; fi; echo \"$rx $tx $now\" > \"$state\"; printf 'netRaw=%s|%s\\n' \"$((drx/dt))\" \"$((dtx/dt))\"; "]
        stdout: StdioCollector { onStreamFinished: root.applyKeyValues(text) }
    }

    Process {
        id: runSystemUpdate
        command: [root.terminalCmd, "-e", "fish", "-c", "actualizar"] 
    }

    component WaveFill: Item {
        id: wroot
        anchors.fill: parent
        clip: true
        required property real value
        required property color color
        property bool isRunning: false 

        Rectangle {
            width: Math.max(wroot.width, wroot.height) * 2.8
            height: width
            x: (wroot.width - width) / 2
            y: wroot.height - (wroot.height * wroot.value)
            radius: width * 0.46
            color: wroot.color
            NumberAnimation on rotation {
                from: 0; to: 360; duration: 7000; loops: Animation.Infinite
                running: wroot.isRunning
            }
        }
    }

    component InfoRow: Rectangle {
        required property string title
        required property string val
        required property string iconName
        Layout.fillWidth: true; Layout.fillHeight: true
        radius: 14
        color: Appearance.colors.colLayer1
        border.width: 1; border.color: Appearance.colors.colLayer0Border
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 24; anchors.topMargin: 12; anchors.bottomMargin: 12; spacing: 12
            MaterialSymbol { text: iconName; font.pixelSize: 22; color: Appearance.colors.colPrimary }
            StyledText { text: title; font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface }
            Item { Layout.fillWidth: true }
            StyledText { text: val; font.pixelSize: 13; color: Appearance.colors.colOnSurfaceVariant; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; Layout.maximumWidth: 300 }
        }
    }

    component PkgCard: Rectangle {
        required property string title
        required property string val
        required property string iconName
        property color icColor: Appearance.colors.colPrimary
        Layout.fillWidth: true; Layout.fillHeight: true
        radius: 16
        color: Appearance.colors.colLayer1
        border.width: 1; border.color: Appearance.colors.colLayer0Border
        RowLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 14
            MaterialSymbol { text: iconName; font.pixelSize: 32; color: icColor }
            ColumnLayout {
                spacing: 2; Layout.fillWidth: true
                StyledText { text: val; font.bold: true; font.pixelSize: 18; color: Appearance.colors.colOnSurface }
                StyledText { text: title; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
    }

      property var tabList: [
        { id: 0, icon: "memory", label: root.tr("system") },
        { id: 1, icon: "device_thermostat", label: root.tr("temp") },
        { id: 2, icon: "update", label: root.tr("updates") },
        { id: 3, icon: "inventory_2", label: root.tr("packages") },
        { id: 4, icon: "info", label: root.tr("info") }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.maximumHeight: 38
            Layout.minimumHeight: 38
            spacing: 8 

            Repeater {
                model: root.tabList
                delegate: Rectangle {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 12
                    
                    color: root.currentTab === index ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                    border.width: root.currentTab === index ? 1 : 0
                    border.color: Appearance.colors.colLayer0Border
                    Behavior on color { enabled: root.enableAnimations; ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        MaterialSymbol { text: modelData.icon; font.pixelSize: 16; color: root.currentTab === index ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant }
                        StyledText { text: modelData.label; font.weight: Font.Bold; font.pixelSize: 12; color: root.currentTab === index ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant }
                    }
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: {
                            root.currentTab = index;
                            flick.contentX = index * flick.width;
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 440 
            clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width * root.tabList.length
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: true

                onVisibleChanged: { if (visible) { contentX = root.currentTab * width } }
                
                onDraggingChanged: { 
                    if (!dragging) {
                        root.currentTab = width > 0 ? Math.round(contentX / width) : 0;
                        contentX = root.currentTab * width;
                    } 
                }
                
                Behavior on contentX { enabled: root.enableAnimations; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Row {
                    height: flick.height
                    width: flick.width * root.tabList.length

                       Item {
                        width: flick.width; height: flick.height
                        GridLayout {
                            anchors.fill: parent; columns: 2; rowSpacing: 12; columnSpacing: 12

                                Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 90; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.clamp01(ResourceUsage.cpuUsage !== undefined ? ResourceUsage.cpuUsage : 0); color: Qt.alpha(Appearance.m3colors.m3primary, 0.25); isRunning: root.visible && root.enableAnimations }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                                    Rectangle { width: 40; height: 40; radius: 10; color: Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4)
                                        MaterialSymbol { anchors.centerIn: parent; text: "dns"; iconSize: 22; color: Appearance.m3colors.m3primary }
                                    }
                                    ColumnLayout {
                                        spacing: 2; Layout.fillWidth: true
                                        StyledText { text: root.tr("processor"); font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface }
                                        StyledText { text: root.processesVal + " procesos"; font.pixelSize: 11; color: Appearance.colors.colOnSurfaceVariant; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    StyledText { text: Math.round(root.clamp01(ResourceUsage.cpuUsage !== undefined ? ResourceUsage.cpuUsage : 0) * 100) + "%"; font.bold: true; font.pixelSize: 20; color: Appearance.m3colors.m3primary }
                                }
                            }

                             Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 90; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.memRatio(); color: Qt.alpha(Appearance.m3colors.m3primary, 0.25); isRunning: root.visible && root.enableAnimations }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                                    Rectangle { width: 40; height: 40; radius: 10; color: Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4)
                                        MaterialSymbol { anchors.centerIn: parent; text: "memory"; iconSize: 22; color: Appearance.m3colors.m3primary }
                                    }
                                    ColumnLayout {
                                        spacing: 2; Layout.fillWidth: true
                                        StyledText { text: root.tr("ram"); font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface }
                                        StyledText { text: root.formatGB(ResourceUsage.memoryUsed) + " / " + root.formatGB(ResourceUsage.memoryTotal); font.pixelSize: 10; color: Appearance.colors.colOnSurfaceVariant; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    StyledText { text: Math.round(root.memRatio() * 100) + "%"; font.bold: true; font.pixelSize: 20; color: Appearance.m3colors.m3primary }
                                }
                            }

                               Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 85; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.swapRatio(); color: Qt.alpha(Appearance.m3colors.m3secondary, 0.25); isRunning: root.visible && root.enableAnimations }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                                    Rectangle { width: 36; height: 36; radius: 10; color: Qt.alpha(Appearance.colors.colSecondaryContainer, 0.4)
                                        MaterialSymbol { anchors.centerIn: parent; text: "swap_horiz"; iconSize: 20; color: Appearance.m3colors.m3secondary }
                                    }
                                    ColumnLayout {
                                        spacing: 2; Layout.fillWidth: true
                                        StyledText { text: root.tr("swap"); font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface }
                                        StyledText { text: root.formatGB(ResourceUsage.swapUsed) + " / " + root.formatGB(ResourceUsage.swapTotal); font.pixelSize: 10; color: Appearance.colors.colOnSurfaceVariant }
                                    }
                                    StyledText { text: Math.round(root.swapRatio() * 100) + "%"; font.bold: true; font.pixelSize: 18; color: Appearance.m3colors.m3secondary }
                                }
                            }

                               Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 85; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.currentDisk.pct01; color: Qt.alpha(Appearance.m3colors.m3secondary, 0.25); isRunning: root.visible && root.enableAnimations }
                                
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
                                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                                    Rectangle { width: 36; height: 36; radius: 10; color: Qt.alpha(Appearance.colors.colSecondaryContainer, 0.4)
                                        MaterialSymbol { anchors.centerIn: parent; text: "hard_drive"; iconSize: 20; color: Appearance.m3colors.m3secondary }
                                    }
                                    ColumnLayout {
                                        spacing: 2; Layout.fillWidth: true
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 4
                                            MaterialSymbol { text: "chevron_left"; font.pixelSize: 16; color: Appearance.colors.colOnSurfaceVariant }
                                            StyledText { text: root.currentDisk.device; font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                            MaterialSymbol { text: "chevron_right"; font.pixelSize: 16; color: Appearance.colors.colOnSurfaceVariant }
                                        }
                                        StyledText { text: root.currentDisk.avail + " libres de " + root.currentDisk.size; font.pixelSize: 10; color: Appearance.colors.colOnSurfaceVariant; Layout.alignment: Qt.AlignHCenter }
                                    }
                                    StyledText { text: root.currentDisk.pct + "%"; font.bold: true; font.pixelSize: 18; color: Appearance.m3colors.m3secondary }
                                }
                            }

                               Rectangle {
                                Layout.columnSpan: 2; Layout.fillWidth: true; Layout.preferredHeight: 120; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                Canvas {
                                    id: netGraphCanvas
                                    anchors.fill: parent; anchors.margins: 1
                                    property color colorRx: Appearance.m3colors.m3tertiary
                                    property color colorTx: Appearance.m3colors.m3error
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                                        var maxVal = 1024
                                        for(var i=0; i<root.rxHistory.length; i++) maxVal = Math.max(maxVal, root.rxHistory[i], root.txHistory[i])
                                        function drawPath(history, col) {
                                            ctx.beginPath(); ctx.moveTo(0, height)
                                            for(var j=0; j<history.length; j++) {
                                                var x = (j / (history.length - 1)) * width
                                                var y = height - (history[j] / maxVal) * (height * 0.4)
                                                ctx.lineTo(x, y)
                                            }
                                            ctx.lineTo(width, height); ctx.fillStyle = Qt.alpha(col, 0.15); ctx.fill()
                                            ctx.beginPath()
                                            for(var k=0; k<history.length; k++) {
                                                var x2 = (k / (history.length - 1)) * width
                                                var y2 = height - (history[k] / maxVal) * (height * 0.4)
                                                if(k===0) ctx.moveTo(x2, y2); else ctx.lineTo(x2, y2)
                                            }
                                            ctx.strokeStyle = col; ctx.lineWidth = 1.5; ctx.stroke()
                                        }
                                        drawPath(root.txHistory, colorTx); drawPath(root.rxHistory, colorRx)
                                    }
                                }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 16
                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop; spacing: 6
                                        RowLayout { spacing: 8
                                            MaterialSymbol { text: "swap_vert"; iconSize: 22; color: Appearance.colors.colOnSurfaceVariant }
                                            StyledText { text: root.tr("network"); font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnSurface }
                                        }
                                        StyledText { text: "Total: " + root.netTotalStr; font.pixelSize: 11; color: Appearance.colors.colOnSurfaceVariant }
                                    }
                                    Item { Layout.fillWidth: true }
                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignRight | Qt.AlignTop; spacing: 4
                                        RowLayout { spacing: 6
                                            MaterialSymbol { text: "arrow_downward"; font.pixelSize: 14; color: Appearance.m3colors.m3tertiary }
                                            StyledText { text: "Descarga"; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant }
                                            Item { width: 10 }
                                            StyledText { text: root.netDownStr; font.bold: true; font.pixelSize: 13; color: Appearance.colors.colOnSurface }
                                        }
                                        RowLayout { spacing: 6
                                            MaterialSymbol { text: "arrow_upward"; font.pixelSize: 14; color: Appearance.m3colors.m3error }
                                            StyledText { text: "Subida"; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant }
                                            Item { width: 23 }
                                            StyledText { text: root.netUpStr; font.bold: true; font.pixelSize: 13; color: Appearance.colors.colOnSurface }
                                        }
                                    }
                                }
                            }
                        }
                    }

                       Item {
                        width: flick.width; height: flick.height
                        RowLayout {
                            anchors.fill: parent; spacing: 16
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.cpuTemp01; color: Qt.alpha(Appearance.m3colors.m3error, 0.25); isRunning: root.visible && root.enableAnimations }
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 16
                                    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "device_thermostat"; iconSize: 64; color: Appearance.m3colors.m3error }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: "CPU"; font.bold: true; font.pixelSize: 20; color: Appearance.colors.colOnSurface }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: root.cpuTemp; font.pixelSize: 42; font.weight: Font.Black; color: Appearance.m3colors.m3error }
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; width: 140; height: 6; radius: 3; color: Qt.alpha(Appearance.colors.colOnSurface, 0.1)
                                        Rectangle { height: parent.height; radius: 3; width: parent.width * root.cpuTemp01; color: Appearance.m3colors.m3error }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                WaveFill { value: root.gpuTemp01; color: Qt.alpha(Appearance.m3colors.m3primary, 0.25); isRunning: root.visible && root.enableAnimations }
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 16
                                    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "thermostat"; iconSize: 64; color: Appearance.m3colors.m3primary }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: "GPU"; font.bold: true; font.pixelSize: 20; color: Appearance.colors.colOnSurface }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: root.gpuTemp; font.pixelSize: 42; font.weight: Font.Black; color: Appearance.m3colors.m3primary }
                                    Rectangle { Layout.alignment: Qt.AlignHCenter; width: 140; height: 6; radius: 3; color: Qt.alpha(Appearance.colors.colOnSurface, 0.1)
                                        Rectangle { height: parent.height; radius: 3; width: parent.width * root.gpuTemp01; color: Appearance.m3colors.m3primary }
                                    }
                                }
                            }
                        }
                    }

                        Item {
                        width: flick.width; height: flick.height
                        ColumnLayout {
                            anchors.fill: parent; spacing: 16
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 140; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                MaterialSymbol { text: "system_update_alt"; font.pixelSize: 130; color: Appearance.colors.colPrimary; opacity: 0.10; anchors.right: parent.right; anchors.rightMargin: -10; anchors.verticalCenter: parent.verticalCenter }
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 4
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: root.totalUpdates; font.pixelSize: 60; font.weight: Font.Black; color: Appearance.colors.colPrimary }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: "Actualizaciones Pendientes"; font.bold: true; font.pixelSize: 16; color: Appearance.colors.colOnSurface }
                                    StyledText { Layout.alignment: Qt.AlignHCenter; text: "Última revisión: " + root.lastUpdateCheck; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant; opacity: 0.8 }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true; Layout.preferredHeight: 90; spacing: 16
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "archive"; font.pixelSize: 32; color: Appearance.m3colors.m3secondary }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; text: root.repoUpdates; font.pixelSize: 28; font.bold: true; color: Appearance.colors.colOnSurface }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; text: "Repositorios"; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: Appearance.colors.colLayer1; border.width: 1; border.color: Appearance.colors.colLayer0Border; clip: true
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "build_circle"; font.pixelSize: 32; color: Appearance.m3colors.m3tertiary }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; text: root.aurUpdates; font.pixelSize: 28; font.bold: true; color: Appearance.colors.colOnSurface }
                                        StyledText { Layout.alignment: Qt.AlignHCenter; text: "AUR"; font.pixelSize: 12; color: Appearance.colors.colOnSurfaceVariant }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true; Layout.preferredHeight: 60; spacing: 16
                                
                                Rectangle { 
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; border.width: 1; border.color: Appearance.colors.colLayer0Border
                                    color: mouseCheck.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                                    Behavior on color { enabled: root.enableAnimations; ColorAnimation { duration: 200 } }
                                    MouseArea { 
                                        id: mouseCheck; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: procUpdates.running = true 
                                    }
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 8
                                        MaterialSymbol { text: "refresh"; font.pixelSize: 20; color: mouseCheck.containsMouse ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant }
                                        StyledText { text: "Comprobar"; font.pixelSize: 13; font.bold: true; color: mouseCheck.containsMouse ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant }
                                    }
                                }
                                
                                Rectangle { 
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; border.width: 1
                                    border.color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                                    color: mouseUpdate.containsMouse ? Qt.alpha(Appearance.colors.colPrimaryContainer, 0.4) : Appearance.colors.colLayer1
                                    Behavior on color { enabled: root.enableAnimations; ColorAnimation { duration: 200 } }
                                    Behavior on border.color { enabled: root.enableAnimations; ColorAnimation { duration: 200 } }
                                    MouseArea {
                                        id: mouseUpdate; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { 
                                            runSystemUpdate.running = true
                                            GlobalStates.mediaControlsOpen = false 
                                        }
                                    }
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 8
                                        MaterialSymbol { text: "terminal"; font.pixelSize: 20; color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant }
                                        StyledText { text: "Aplicar Actualización"; font.pixelSize: 13; font.bold: true; color: mouseUpdate.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant }
                                    }
                                }
                            }
                        }
                    }

                       Item {
                        width: flick.width; height: flick.height
                        GridLayout {
                            anchors.fill: parent; columns: 2; rowSpacing: 10; columnSpacing: 10
                            PkgCard { title: "Pacman (Total)"; val: root.pkgTotal; iconName: "package_2"; icColor: Appearance.m3colors.m3primary }
                            PkgCard { title: "Explícitos (Manual)"; val: root.pkgExplicit; iconName: "person"; icColor: Appearance.colors.colPrimary }
                            PkgCard { title: "Dependencias (Auto)"; val: root.pkgDeps; iconName: "account_tree"; icColor: Appearance.m3colors.m3secondary }
                            PkgCard { title: "AUR (Externos)"; val: root.pkgAur; iconName: "build"; icColor: Appearance.m3colors.m3tertiary }
                            PkgCard { title: "Flatpaks"; val: root.flatpakCount; iconName: "box"; icColor: Appearance.colors.colTertiaryContainer }
                            PkgCard { title: "Snaps"; val: root.snapCount; iconName: "inventory"; icColor: Appearance.m3colors.m3error }
                            PkgCard { title: "Huérfanos"; val: root.pkgOrphans; iconName: "delete_sweep"; icColor: Appearance.colors.colOnSurfaceVariant }
                            PkgCard { title: "Caché Pacman"; val: root.pacmanCacheSize; iconName: "folder_zip"; icColor: Appearance.colors.colOnSurfaceVariant }
                        }
                    }

                     Item {
                        width: flick.width; height: flick.height
                        ColumnLayout {
                            anchors.fill: parent; spacing: 10
                            InfoRow { title: "SO"; val: root.osName; iconName: "linux" }
                            InfoRow { title: "Máquina"; val: root.hostName; iconName: "computer" }
                            InfoRow { title: "Procesador"; val: root.cpuModelName; iconName: "memory" }
                            InfoRow { title: "Kernel"; val: root.kernelVal; iconName: "terminal" }
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
