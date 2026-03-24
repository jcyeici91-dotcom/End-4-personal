pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root

    readonly property int fetchInterval: (Config.options.bar.weather.fetchInterval || 10) * 60 * 1000
    readonly property string city: Config.options.bar.weather.city || "San Salvador"
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS || false
    property bool gpsActive: Config.options.bar.weather.enableGPS || false

    onUseUSCSChanged: root.getData()
    onCityChanged: if (!root.gpsActive) root.getData()

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: "0%",
        sunrise: "--",
        sunset: "--",
        windDir: "N",
        wCode: "113",
        condition: "Checking...",
        city: "Buscando...",
        wind: "-- km/h",
        precip: "-- mm",
        visib: "-- km",
        press: "-- hPa",
        temp: "--",
        tempFeelsLike: "--",
        lastRefresh: "--:--",
        forecast: []
    })

    function formatCityName(cityName) {
        if (!cityName || cityName.trim() === "")
            return "San+Salvador";
        return cityName.trim().split(/\s+/).join("+");
    }

    function getSafeHourly(hourlyList, preferredIndex) {
        if (!hourlyList || hourlyList.length === 0)
            return null;

        if (hourlyList.length > preferredIndex)
            return hourlyList[preferredIndex];

        return hourlyList[Math.floor(hourlyList.length / 2)];
    }

    function refineData(apiData) {
        if (!apiData || !apiData.current_condition || apiData.current_condition.length === 0) {
            console.warn("[WeatherService] Datos inválidos recibidos");
            return;
        }

        let cur = apiData.current_condition[0];
        let ast = (apiData.weather && apiData.weather.length > 0 && apiData.weather[0].astronomy && apiData.weather[0].astronomy.length > 0)
                ? apiData.weather[0].astronomy[0]
                : null;
        let loc = (apiData.nearest_area && apiData.nearest_area.length > 0)
                ? apiData.nearest_area[0]
                : null;

        let temp = {};

        temp.uv = cur.uvIndex || 0;
        temp.humidity = (cur.humidity || 0) + "%";
        temp.sunrise = ast ? (ast.sunrise || "--") : "--";
        temp.sunset = ast ? (ast.sunset || "--") : "--";
        temp.windDir = cur.winddir16Point || "N";
        temp.wCode = cur.weatherCode || "113";
        temp.condition = (cur.weatherDesc && cur.weatherDesc[0] && cur.weatherDesc[0].value)
                ? cur.weatherDesc[0].value
                : "Despejado";

        temp.city = (loc && loc.areaName && loc.areaName[0] && loc.areaName[0].value)
                ? loc.areaName[0].value
                : root.city;

        temp.temp = root.useUSCS ? (cur.temp_F || "--") : (cur.temp_C || "--");
        temp.tempFeelsLike = root.useUSCS ? (cur.FeelsLikeF || "--") : (cur.FeelsLikeC || "--");
        temp.wind = root.useUSCS
                ? ((cur.windspeedMiles || 0) + " mph")
                : ((cur.windspeedKmph || 0) + " km/h");
        temp.precip = root.useUSCS
                ? ((cur.precipInches || 0) + " in")
                : ((cur.precipMM || 0) + " mm");
        temp.visib = root.useUSCS
                ? ((cur.visibilityMiles || 0) + " mi")
                : ((cur.visibility || 0) + " km");
        temp.press = root.useUSCS
                ? ((cur.pressure || 0) + " mb")
                : ((cur.pressure || 0) + " hPa");

        temp.forecast = [];

        if (apiData.weather && apiData.weather.length > 0) {
            for (let i = 0; i < apiData.weather.length; i++) {
                let w = apiData.weather[i];
                let hourly = getSafeHourly(w.hourly, 4); // intenta mediodía / tarde
                let weatherDesc = "Clear";
                let weatherCode = "113";

                if (hourly) {
                    weatherCode = hourly.weatherCode || "113";
                    if (hourly.weatherDesc && hourly.weatherDesc.length > 0 && hourly.weatherDesc[0].value) {
                        weatherDesc = hourly.weatherDesc[0].value;
                    }
                }

                temp.forecast.push({
                    date: w.date || "",
                    max: root.useUSCS ? (w.maxtempF || "--") : (w.maxtempC || "--"),
                    min: root.useUSCS ? (w.mintempF || "--") : (w.mintempC || "--"),
                    avg: root.useUSCS ? (w.avgtempF || "--") : (w.avgtempC || "--"),
                    sunHours: w.sunHour || "0",
                    code: weatherCode,
                    desc: weatherDesc
                });
            }
        }

        temp.lastRefresh = (DateTime.time || Qt.formatTime(new Date(), "hh:mm AP")) + " • " +
                           (DateTime.date || Qt.formatDate(new Date(), "dd/MM/yyyy"));

        root.data = temp;
    }

    function getData() {
        let command = "curl -sfL -m 12 'https://wttr.in";

        if (root.gpsActive && root.location.valid) {
            // CORREGIDO: lon, no long
            command += "/" + root.location.lat + "," + root.location.lon;
        } else {
            command += "/" + formatCityName(root.city);
        }

        command += "?format=j1'";

        fetcher.command = ["bash", "-c", command];
        fetcher.running = true;
    }

    Component.onCompleted: {
        if (root.gpsActive) {
            positionSource.start();
        } else {
            root.getData();
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) {
                    console.warn("[WeatherService] Respuesta vacía de wttr.in");
                    return;
                }

                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                } catch (e) {
                    console.error("[WeatherService JSON Parse Error] " + e.message);
                    console.error("[WeatherService Raw Output] " + text);
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("[WeatherService] curl terminó con código:", exitCode);
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval
        active: root.gpsActive

        onPositionChanged: {
            if (position.coordinate.isValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude; // CORREGIDO
                root.location.valid = true;
                root.getData();
            } else {
                root.location.valid = false;
            }
        }

        onSourceErrorChanged: {
            if (sourceError !== PositionSource.NoError) {
                console.warn("[WeatherService GPS] Error de GPS:", sourceError);
                root.location.valid = false;
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        onTriggered: {
            if (!root.gpsActive) {
                root.getData();
            } else if (root.location.valid) {
                root.getData();
            } else {
                positionSource.start();
            }
        }
    }
}
