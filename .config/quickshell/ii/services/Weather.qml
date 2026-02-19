// Weather.qml
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root

    // --- Config values ---
    // Minutes -> ms (fallback to 10 if config is missing/0)
    readonly property int fetchIntervalMs: Math.max(1, (Config.options.bar.weather.fetchInterval || 10)) * 60 * 1000
    readonly property string city: (Config.options.bar.weather.city || "")
    readonly property bool useUSCS: !!Config.options.bar.weather.useUSCS
    readonly property bool gpsEnabled: !!Config.options.bar.weather.enableGPS

    // Runtime state (do NOT bind directly to Config if you plan to assign later)
    property bool gpsActive: gpsEnabled

    onUseUSCSChanged: root.getData()
    onCityChanged: {
        // If user changes city, and GPS is not active, refresh
        if (!root.gpsActive) root.getData()
    }
    onGpsEnabledChanged: {
        root.gpsActive = gpsEnabled
        if (root.gpsActive) {
            console.info("[WeatherService] Starting the GPS service.")
            positionSource.start()
        } else {
            positionSource.stop()
            root.location.valid = false
            root.getData()
        }
    }

    // --- Location state ---
    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    // --- Weather data exposed to UI ---
    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0
    })

    function refineData(data) {
        let temp = {}
        temp.uv = data?.current?.uvIndex || 0
        temp.humidity = (data?.current?.humidity || 0) + "%"
        temp.sunrise = data?.astronomy?.sunrise || "0.0"
        temp.sunset = data?.astronomy?.sunset || "0.0"
        temp.windDir = data?.current?.winddir16Point || "N"
        temp.wCode = data?.current?.weatherCode || "113"
        temp.city = data?.location?.areaName?.[0]?.value || "City"

        temp.temp = ""
        temp.tempFeelsLike = ""

        if (root.useUSCS) {
            temp.wind = (data?.current?.windspeedMiles || 0) + " mph"
            temp.precip = (data?.current?.precipInches || 0) + " in"
            temp.visib = (data?.current?.visibilityMiles || 0) + " mi"
            temp.press = (data?.current?.pressureInches || 0) + " inHg"
            temp.temp = (data?.current?.temp_F || 0) + "°F"
            temp.tempFeelsLike = (data?.current?.FeelsLikeF || 0) + "°F"
        } else {
            temp.wind = (data?.current?.windspeedKmph || 0) + " km/h"
            temp.precip = (data?.current?.precipMM || 0) + " mm"
            temp.visib = (data?.current?.visibility || 0) + " km"
            temp.press = (data?.current?.pressure || 0) + " hPa"
            temp.temp = (data?.current?.temp_C || 0) + "°C"
            temp.tempFeelsLike = (data?.current?.FeelsLikeC || 0) + "°C"
        }

        temp.lastRefresh = DateTime.time + " • " + DateTime.date
        root.data = temp
    }

    function formatCityName(cityName) {
        return (cityName || "").trim().split(/\s+/).join("+")
    }

    function buildCommand() {
        // Prefer GPS if enabled and we already have a valid fix
        let target = ""
        if (root.gpsActive && root.location.valid) {
            target = `${root.location.lat},${root.location.lon}`
        } else {
            const formattedCity = formatCityName(root.city)
            // If city is empty, wttr.in without path will use IP-based lookup
            target = formattedCity.length ? formattedCity : ""
        }

        let cmd = "curl -s"
        cmd += " 'wttr.in"
        if (target.length) cmd += `/${target}`
        cmd += "?format=j1'"
        cmd += " | "
        cmd += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'"
        return cmd
    }

    function getData() {
        const cmd = buildCommand()
        fetcher.command = ["bash", "-c", cmd]
        fetcher.running = true
    }

    Component.onCompleted: {
        // Kick off immediately: either start GPS or fallback fetch
        if (root.gpsActive) {
            console.info("[WeatherService] Starting the GPS service.")
            positionSource.start()
        } else {
            root.getData()
        }
    }

    Process {
        id: fetcher

        command: ["bash", "-c", ""]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.length === 0) return
                try {
                    const parsedData = JSON.parse(text)
                    root.refineData(parsedData)
                } catch (e) {
                    console.error(`[WeatherService] Failed to parse JSON: ${e.message}`)
                    // Optional: log the raw output to help debugging
                    // console.error(`[WeatherService] Raw stdout: ${text}`)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.length) {
                    console.error(`[WeatherService] stderr: ${text}`)
                }
            }
        }
    }

    PositionSource {
        id: positionSource

        updateInterval: root.fetchIntervalMs

        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude
                root.location.lon = position.coordinate.longitude   // FIX: lon (not long)
                root.location.valid = true
                root.getData()
            } else {
                // Keep last valid fix if we have one; otherwise fall back
                root.gpsActive = root.location.valid ? true : false
                console.error("[WeatherService] Failed to get a valid GPS position.")
                if (!root.gpsActive) root.getData()
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop()
                root.location.valid = false
                root.gpsActive = false
                Quickshell.execDetached([
                    "notify-send",
                    Translation.tr("Weather Service"),
                    Translation.tr("Cannot find a GPS service. Using the fallback method instead."),
                    "-a",
                    "Shell"
                ])
                console.error("[WeatherService] Could not acquire a valid backend plugin.")
                root.getData()
            }
        }
    }

    Timer {
        // Poll only when GPS is not active
        running: !root.gpsActive
        repeat: true
        interval: root.fetchIntervalMs
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}

