import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: m
    visible: false // Modelo lógico (no UI)

    // RELOJ
    property string timeHour: "00"
    property string timeMin: "00"
    property string timeSec: "00"
    property string dateString: ""
    property string greeting: "Hello"

    // DATOS ESTÁTICOS
    property string kernelVal: "..."
    property string archVal: "..."
    property string qsVer: "..."
    property string hyprVer: "..."
    property string currentShell: "..."

    // DATOS DINÁMICOS
    property real cpuProgress: (typeof ResourceUsage !== "undefined" && ResourceUsage.cpuUsage !== undefined && !isNaN(ResourceUsage.cpuUsage))
        ? ResourceUsage.cpuUsage
        : 0
    property string cpuVal: Math.round(cpuProgress * 100) + "%"

    property real ramProgress: (typeof ResourceUsage !== "undefined" && ResourceUsage.memoryUsedPercentage !== undefined && !isNaN(ResourceUsage.memoryUsedPercentage))
        ? ResourceUsage.memoryUsedPercentage
        : 0
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

    // helper robusto: permite valores "0" / 0 sin caer a fallback
    function getW(prop, fallback) {
        if (typeof Weather === "undefined") return fallback
        const d = Weather.data
        if (!d) return fallback
        const v = d[prop]
        if (v === undefined || v === null) return fallback
        // si es string vacío, usa fallback
        if (typeof v === "string" && v.trim().length === 0) return fallback
        return v
    }

    property string weatherTemp: String(getW("temp", "--"))
    property string weatherCode: String(getW("wCode", "113"))

    property string rawCity: String(getW("city", "Chalatenango"))
    property string weatherCity: rawCity === "Nueva San Salvador" ? "San Salvador" : rawCity

    property string wHum: String(getW("humidity", "0")) + "%"
    property string wVis: String(getW("visibility", "10")) + " km"

    // válido si hay temp numérica o code no vacío
    readonly property bool weatherIsValid: {
        const t = parseFloat(m.weatherTemp)
        return (!isNaN(t) && isFinite(t)) || (m.weatherCode && m.weatherCode.length > 0)
    }

    readonly property string weatherCondition: {
        var c = m.weatherCode.toString()
        if (c === "113") return "Sunny"
        if (c === "116") return "Partly Cloudy"
        if (c === "119" || c === "122") return "Cloudy"
        if (["176","263","296","302"].includes(c)) return "Rainy"
        if (["200","389"].includes(c)) return "Storm"
        return "Unknown"
    }

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

    // propiedad lista para UI
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
            m.dateString = d.toLocaleDateString(Qt.locale(), "ddd, d MMM")

            const h = d.getHours()
            m.greeting = h < 12 ? "Good Morning" : (h < 18 ? "Good Afternoon" : "Good Evening")

            // refrescar stats cada 3s
            if (d.getSeconds() % 3 === 0) procSystemStats.running = true
        }
    }

    Component.onCompleted: {
        procStaticInfo.running = true
        procSystemStats.running = true
    }

    Process {
        id: procStaticInfo
         command: ["bash", "-c",
            "uname -r && " +
            "uname -m && " +
            "qs --version | awk '{print $2}' && " +
            "hyprctl version | grep 'Tag' | awk '{print $2}' && " +
            "echo $SHELL | awk -F/ '{print $NF}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length >= 5) {
                    m.kernelVal = lines[0].trim()
                    m.archVal = lines[1].trim()
                    m.qsVer = lines[2].trim()
                    m.hyprVer = lines[3].trim()
                    m.currentShell = lines[4].trim()
                }
            }
        }
    }

    Process {
        id: procSystemStats
        // 6 líneas:
        // ramDetail, diskAvail(/), diskUsePct(/), processes, cpuTemp, gpuTemp
        command: ["bash", "-c",
            "free -h | awk 'NR==2 {print $3 \" / \" $2}' && " +
            "df -h --output=avail / | tail -n 1 && " +
            "df -P / | awk 'NR==2 {print $5}' && " +
            // ps -ax | wc -l incluye header en algunos entornos; restamos 1 si es posible
            "sh -c 'p=$(ps -ax | wc -l); if [ \"$p\" -gt 0 ]; then echo $((p-1)); else echo 0; fi' && " +
            "(sensors k10temp-* 2>/dev/null | grep -m1 'Tctl' | awk '{print $2}' | tr -d '+°C' || echo 0) && " +
            "(sensors amdgpu-* 2>/dev/null | grep -m1 'edge' | awk '{print $2}' | tr -d '+°C' || echo 0)"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
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
}

