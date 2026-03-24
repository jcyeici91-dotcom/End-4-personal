pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

  property bool enableAnimations: Config.options.appearance !== undefined ? Config.options.appearance.enableAnimations : true
    
    property bool isNightTime: {
        let h = new Date().getHours();
        return h < 6 || h >= 19; 
    }

   property string currentTemp: Weather.data && Weather.data.temp ? String(Weather.data.temp).replace("°C","").replace("°F","") : "--"
    property string currentFeels: Weather.data && Weather.data.tempFeelsLike ? String(Weather.data.tempFeelsLike).replace("°C","").replace("°F","") : "--"
    property string currentWind: Weather.data && Weather.data.wind ? Weather.data.wind : "-- km/h"
    property string currentHum: Weather.data && Weather.data.humidity ? Weather.data.humidity : "--%"
    property string currentPress: Weather.data && Weather.data.press ? Weather.data.press : "-- hPa"
    property string currentVisib: Weather.data && Weather.data.visib ? Weather.data.visib : "10 km"
    property string currentUv: Weather.data && Weather.data.uv ? Weather.data.uv.toString() : "0"
    property string locName: Weather.data && Weather.data.city ? Weather.data.city : "Searching..."
    property string tempSymbol: Weather.useUSCS ? "°F" : "°C"
    
       property string currentCond: {
        let raw = Weather.data && Weather.data.condition ? Weather.data.condition : "Clear";
        let c = raw.toLowerCase();
        if (c.includes("clear") || c.includes("sunny") || c.includes("despejado")) return "Clear";
        if (c.includes("partly") || c.includes("parcialmente")) return "Partly Cloudy";
        if (c.includes("mostly") || c.includes("mayormente")) return "Mostly Cloudy";
        if (c.includes("cloud") || c.includes("overcast") || c.includes("nublado")) return "Cloudy";
        if (c.includes("heavy rain") || c.includes("violent")) return "Heavy Rain";
        if (c.includes("rain") || c.includes("shower") || c.includes("drizzle") || c.includes("lluvia")) return "Rainy";
        if (c.includes("heavy snow")) return "Heavy Snow";
        if (c.includes("snow") || c.includes("sleet") || c.includes("nieve")) return "Snow";
        if (c.includes("thunder") || c.includes("storm") || c.includes("tormenta")) return "Storm";
        if (c.includes("fog") || c.includes("mist") || c.includes("haze")) return "Fog";
        if (c.includes("wind")) return "Windy";
        return raw;
    }

     function resolveSvgIcon(conditionStr, isNight, code) {
        let c = String(conditionStr || "").toLowerCase();
        let wmo = String(code || "113");
        switch(wmo) {
            case "113": return isNight ? "clear_night.svg" : "clear_day.svg";
            case "116": return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg";
            case "119": case "122": return "cloudy.svg";
            case "143": case "248": case "260": return "haze_fog_dust_smoke.svg";
            case "176": case "263": case "266": case "293": case "296": case "299": case "302": case "305": case "308": case "353": case "356": case "359": return "showers_rain.svg";
            case "179": case "182": case "185": case "281": case "284": case "311": case "314": case "317": case "320": case "323": case "326": case "329": case "332": case "335": case "338": case "350": case "362": case "365": case "368": case "371": case "374": case "377": case "392": case "395": return "mostly_snow.svg";
            case "200": case "386": case "389": return "isolated_thunderstorms.svg";
        }
        if (c.includes("clear") || c.includes("sunny")) return isNight ? "clear_night.svg" : "clear_day.svg";
        if (c.includes("partly")) return isNight ? "partly_cloudy_night.svg" : "partly_cloudy_day.svg";
        if (c.includes("mostly") || c.includes("overcast")) return isNight ? "mostly_cloudy_night.svg" : "mostly_cloudy_day.svg";
        if (c.includes("cloud")) return "cloudy.svg";
        if (c.includes("rain") || c.includes("shower") || c.includes("drizzle")) return "showers_rain.svg";
        if (c.includes("snow")) return "mostly_snow.svg"; 
        if (c.includes("thunder") || c.includes("storm")) return "isolated_thunderstorms.svg";
        return isNight ? "clear_night.svg" : "clear_day.svg";
    }

    property string weatherIcon: resolveSvgIcon(Weather.data ? Weather.data.condition : "", root.isNightTime, Weather.data ? Weather.data.wCode : "")

    function getWeatherType() {
        let svg = weatherIcon.toLowerCase();
        if (svg.includes("thunder") || svg.includes("storm")) return "storm";
        if (svg.includes("rain") || svg.includes("drizzle") || svg.includes("shower")) return "rain";
        if (svg.includes("snow") || svg.includes("sleet")) return "snow";
        if (svg.includes("cloud") || svg.includes("fog")) return root.isNightTime ? "cloudy_night" : "cloudy_day";
        return root.isNightTime ? "night" : "day";
    }

    property string weatherType: getWeatherType()

    function getGradientColors(type) {
        switch(type) {
            case "day": return ["#4A90E2", "#63D8FF"];
            case "night": return ["#0B1220", "#18263A"];
            case "rain": return ["#23364A", "#1A2430"];
            case "snow": return ["#6E7F97", "#C6D5E8"];
            case "storm": return ["#111827", "#2A4365"];
            case "cloudy_day": return ["#6E86B6", "#B8C7E3"];
            case "cloudy_night": return ["#16243B", "#29323C"];
            default: return ["#0B1220", "#18263A"];
        }
    }

    property var daysEn: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    property var monthsEn: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    function getCurrentDateString() {
        let d = new Date();
        let dayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.getDay()];
        return `${dayName}, ${monthsEn[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
    }

    function getDayNameOffset(offset) {
        let d = new Date();
        d.setDate(d.getDate() + offset);
        return daysEn[d.getDay()];
    }

    function safe(v, fallback) {
        return (v === undefined || v === null || v === "") ? fallback : v;
    }

       function getForecastItem(index) {
        let dayStr = index === 0 ? "TODAY" : getDayNameOffset(index);
        let forecastArray = Weather.data && Weather.data.forecast ? Weather.data.forecast : null;
        
        if (forecastArray && Array.isArray(forecastArray) && forecastArray.length > index) {
            let item = forecastArray[index];
            if (item && item.max !== undefined && item.min !== undefined) {
                return {
                    dayName: dayStr,
                    maxTemp: String(item.max).replace(/[^0-9]/g, "") + "°",
                    minTemp: String(item.min).replace(/[^0-9]/g, "") + "°",
                    icon: resolveSvgIcon(item.desc || item.condition, false, item.code)
                }
            }
        }
        
        let baseT = parseInt(root.currentTemp);
        if (isNaN(baseT)) baseT = 24;
        let maxV = baseT + 1 + (index % 3);
        let minV = baseT - 3 - (index % 2);

        return {
            dayName: dayStr,
            maxTemp: maxV + "°",
            minTemp: minV + "°",
            icon: ["partly_cloudy_day.svg", "cloudy.svg", "clear_day.svg", "showers_rain.svg"][index % 4]
        };
    }

      component ForecastCard: Rectangle {
        property int dayIndex: 0
        property var fData: root.getForecastItem(dayIndex)

        radius: 18
        color: Qt.alpha("#ffffff", dayIndex === 0 ? 0.16 : 0.08)
        border.width: 1
        border.color: Qt.alpha("#ffffff", dayIndex === 0 ? 0.25 : 0.12)

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 70

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4 

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: fData.dayName
                font.pixelSize: 12 // Ligeramente más pequeño
                font.weight: Font.Bold
                color: "#ffffff"
                opacity: 0.95
            }

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 38 // Ícono un poco más compacto
                Layout.preferredHeight: 38
                source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/ii/assets/icons/google-weather/" + fData.icon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                sourceSize: Qt.size(76, 76)
                onStatusChanged: { if (status === Image.Error) { source = "file://" + Quickshell.env("HOME") + "/.config/quickshell/ii/assets/icons/google-weather/clear_day.svg"; } }
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0; verticalOffset: 4; radius: 8; samples: 16
                    color: Qt.alpha("#000000", 0.4); transparentBorder: true
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4 // Temps más juntas
                StyledText { text: fData.maxTemp; font.pixelSize: 14; font.weight: Font.DemiBold; color: "#ffffff" }
                StyledText { text: fData.minTemp; font.pixelSize: 12; font.weight: Font.Medium; color: "#ffffff"; opacity: 0.65 }
            }
        }
    }

    component StarsEffect: Item {
        anchors.fill: parent; clip: true
        
        Repeater {
            model: 70
            Rectangle {
                x: Math.random() * parent.width; y: Math.random() * (parent.height * 0.75)
                width: Math.random() * 2.5 + 1.5; height: width
                color: "#ffffff"; radius: width / 2
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: root.visible && root.enableAnimations
                    NumberAnimation { from: 0.15; to: Math.random() * 0.8 + 0.2; duration: 1800 + Math.random() * 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.15; duration: 1800 + Math.random() * 2000; easing.type: Easing.InOutSine }
                }
            }
        }

        Repeater {
            model: 2
            Rectangle {
                id: shootingStar
                width: Math.random() * 120 + 80; height: 1.5; radius: 1
                color: "transparent"
                rotation: -35 
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ffffff" } 
                    GradientStop { position: 0.2; color: Qt.alpha("#ffffff", 0.8) }
                    GradientStop { position: 1.0; color: "transparent" } 
                }

                SequentialAnimation {
                    loops: Animation.Infinite; running: root.visible && root.enableAnimations
                    PauseAnimation { duration: Math.random() * 10000 + 4000 } 
                    ParallelAnimation {
                        NumberAnimation { target: shootingStar; property: "x"; from: parent.width + 150; to: -300; duration: 1000 }
                        NumberAnimation { target: shootingStar; property: "y"; from: -100; to: parent.height + 200; duration: 1000 }
                        SequentialAnimation {
                            NumberAnimation { target: shootingStar; property: "opacity"; from: 0; to: 1; duration: 150 }
                            PauseAnimation { duration: 550 }
                            NumberAnimation { target: shootingStar; property: "opacity"; from: 1; to: 0; duration: 300 }
                        }
                    }
                }
            }
        }
    }

    component RainEffect: Item {
        anchors.fill: parent; clip: true
        Repeater {
            model: 120
            Rectangle {
                x: Math.random() * parent.width; y: Math.random() * parent.height - parent.height
                width: 1.5; height: Math.random() * 40 + 20
                color: "transparent"; rotation: 15
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.alpha("#ffffff", 0.6) }
                }
                NumberAnimation on y { from: y; to: parent.height + 100; duration: Math.random() * 300 + 350; loops: Animation.Infinite; running: root.visible && root.enableAnimations }
                NumberAnimation on x { from: x; to: x - 50; duration: Math.random() * 300 + 350; loops: Animation.Infinite; running: root.visible && root.enableAnimations }
            }
        }
    }

       component SnowEffect: Item {
        anchors.fill: parent; clip: true
        Repeater {
            model: 80
            Rectangle {
                x: Math.random() * parent.width; y: Math.random() * parent.height - parent.height
                width: Math.random() * 5 + 3; height: width
                color: Qt.alpha("#ffffff", Math.random() * 0.5 + 0.5); radius: width / 2
                NumberAnimation on y { from: y; to: parent.height + 50; duration: Math.random() * 4000 + 3500; loops: Animation.Infinite; running: root.visible && root.enableAnimations }
                NumberAnimation on x { from: x - 20; to: x + 20; duration: Math.random() * 2000 + 1500; loops: Animation.Infinite; running: root.visible && root.enableAnimations; easing.type: Easing.InOutSine }
            }
        }
    }

     component StormEffect: Item {
        anchors.fill: parent
        Loader { anchors.fill: parent; sourceComponent: rainComp }
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            opacity: 0
            SequentialAnimation on opacity {
                loops: Animation.Infinite; running: root.visible && root.enableAnimations
                PauseAnimation { duration: Math.random() * 5000 + 2000 } 
                NumberAnimation { to: 0.8; duration: 50; easing.type: Easing.OutExposed }
                NumberAnimation { to: 0; duration: 150; easing.type: Easing.InSine }
                PauseAnimation { duration: 100 }
                NumberAnimation { to: 0.5; duration: 50; easing.type: Easing.OutExposed }
                NumberAnimation { to: 0; duration: 250; easing.type: Easing.InSine }
            }
        }
    }

      component SunGlowEffect: Item {
        anchors.fill: parent; clip: true
        Rectangle {
            width: 480; height: 480; radius: 240
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: -120
            color: root.isNightTime ? Qt.alpha("#ffffff", 0.06) : Qt.alpha("#FFD56A", 0.14)
            SequentialAnimation on scale {
                loops: Animation.Infinite; running: root.visible && root.enableAnimations
                NumberAnimation { to: 1.08; duration: 4000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 14 // Espacio para el resplandor externo sutil

       Rectangle {
            id: maskShape
            anchors.fill: parent
            radius: 38
            visible: false
        }

            Item {
            id: maskedContent
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask { maskSource: maskShape }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.getGradientColors(root.weatherType)[0] }
                    GradientStop { position: 1.0; color: root.getGradientColors(root.weatherType)[1] }
                }
            }

           Rectangle { anchors.fill: parent; color: Qt.alpha("#000000", root.isNightTime ? 0.32 : 0.14) }
            Rectangle { anchors.fill: parent; color: Qt.alpha("#ffffff", 0.02) }

               Loader {
                id: effectLoader
                anchors.fill: parent
                sourceComponent: {
                    if (root.weatherType === "storm") return stormComp;
                    if (root.weatherType === "night" || root.weatherType === "cloudy_night") return starsComp;
                    if (root.weatherType === "day" || root.weatherType === "cloudy_day") return sunComp;
                    if (root.weatherType === "rain") return rainComp;
                    if (root.weatherType === "snow") return snowComp;
                    return null;
                }
            }
            Component { id: starsComp; StarsEffect {} }
            Component { id: rainComp; RainEffect {} }
            Component { id: snowComp; SnowEffect {} }
            Component { id: sunComp; SunGlowEffect {} }
            Component { id: stormComp; StormEffect {} }

           Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 38
                border.width: 1 
                border.color: Qt.alpha("#ffffff", 0.08)
                
                layer.enabled: true
                layer.effect: InnerShadow {
                    radius: 25 
                    samples: 40
                    color: Qt.alpha("#000000", root.isNightTime ? 0.5 : 0.25) 
                    horizontalOffset: 0; verticalOffset: 0
                }
            }
        }

           Rectangle {
            anchors.fill: parent
            radius: 38
            color: "transparent"
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 0
                radius: 15; samples: 31
                color: Qt.alpha("#000000", 0.2) 
                transparentBorder: true
            }
        }

            ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 0

                RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 10
                RowLayout {
                    spacing: 12
                    MaterialSymbol { text: "location_on"; font.pixelSize: 24; color: "#ffffff"; opacity: 0.95 }
                    StyledText {
                        text: root.locName
                        font.pixelSize: 32; font.weight: Font.Bold
                        color: "#ffffff"; opacity: 0.98; elide: Text.ElideRight; maximumLineCount: 1
                    }
                }
                Item { Layout.fillWidth: true }
            }

                RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                   ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

                    StyledText {
                        text: root.getCurrentDateString()
                        font.pixelSize: 16; color: "#ffffff"; opacity: 0.85; Layout.leftMargin: 4
                        Layout.bottomMargin: 20 
                    }

                    // Reloj Pastilla
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 125
                        radius: 28; color: Qt.alpha("#ffffff", 0.08)
                        border.width: 1; border.color: Qt.alpha("#ffffff", 0.15)
                        
                        layer.enabled: true
                        layer.effect: DropShadow { horizontalOffset: 0; verticalOffset: 8; radius: 20; samples: 28; color: Qt.alpha("#000000", 0.15); transparentBorder: true }

                        StyledText {
                            anchors.centerIn: parent
                            text: DateTime.time !== undefined ? DateTime.time : Qt.formatTime(new Date(), "hh:mm AP")
                            font.pixelSize: 92             
                            font.weight: 900               
                            font.bold: true                
                            font.letterSpacing: -2.0       
                            color: "#ffffff"
                            style: Text.Outline; styleColor: Qt.alpha("#000000", 0.12)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 22
                        spacing: 14
                        
                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "air"; font.pixelSize: 18; color: "#ffffff"; opacity: 0.9 }
                            StyledText { text: root.currentWind; font.pixelSize: 14; font.weight: Font.Medium; color: "#ffffff"; opacity: 0.95 }
                        }
                        
                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "visibility"; font.pixelSize: 18; color: "#ffffff"; opacity: 0.9 }
                            StyledText { text: root.currentVisib; font.pixelSize: 14; font.weight: Font.Medium; color: "#ffffff"; opacity: 0.95 }
                        }

                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "water_drop"; font.pixelSize: 18; color: "#ffffff"; opacity: 0.9 }
                            StyledText { text: root.currentHum; font.pixelSize: 14; font.weight: Font.Medium; color: "#ffffff"; opacity: 0.95 }
                        }

                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: "speed"; font.pixelSize: 18; color: "#ffffff"; opacity: 0.9 }
                            StyledText { text: root.currentPress; font.pixelSize: 14; font.weight: Font.Medium; color: "#ffffff"; opacity: 0.95 }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }

                    ColumnLayout {
                    Layout.preferredWidth: 230
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    spacing: -4

                    Item {
                        Layout.preferredWidth: 190; Layout.preferredHeight: 170
                        Layout.alignment: Qt.AlignHCenter

                        Image {
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/ii/assets/icons/google-weather/" + root.weatherIcon
                            fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true; sourceSize: Qt.size(256, 256)
                            onStatusChanged: { if (status === Image.Error) { source = "file://" + Quickshell.env("HOME") + "/.config/quickshell/ii/assets/icons/google-weather/clear_day.svg"; } }
                            layer.enabled: true
                            layer.effect: DropShadow { horizontalOffset: 0; verticalOffset: 10; radius: 22; samples: 32; color: Qt.alpha("#000000", 0.35); transparentBorder: true }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.currentTemp + root.tempSymbol
                        font.pixelSize: 64; font.weight: Font.Bold; font.letterSpacing: -2; color: "#ffffff"
                        style: Text.Outline; styleColor: Qt.alpha("#000000", 0.16)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Feels like " + root.currentFeels + root.tempSymbol
                        font.pixelSize: 15; color: "#ffffff"; opacity: 0.85
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.currentCond
                        font.pixelSize: 18; font.weight: Font.DemiBold; color: "#ffffff"
                        opacity: 0.95; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                        Layout.preferredWidth: 210; Layout.topMargin: 6
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha("#ffffff", 0.20); Layout.topMargin: 12; Layout.bottomMargin: 12 }

            // --- FOOTER: 5 DÍAS ---
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                
                StyledText { text: "5-Day Forecast"; font.pixelSize: 15; font.weight: Font.DemiBold; color: "#ffffff"; opacity: 0.95 }
                Item { Layout.fillWidth: true }
                StyledText { text: "Last update: " + root.safe(Weather.data ? Weather.data.lastRefresh : "", "--"); font.pixelSize: 12; color: "#ffffff"; opacity: 0.65 }
                
                Rectangle {
                    width: 28; height: 28; radius: 14; color: Qt.alpha("#ffffff", 0.10); border.width: 1; border.color: Qt.alpha("#ffffff", 0.14)
                    MaterialSymbol { anchors.centerIn: parent; text: "sync"; font.pixelSize: 16; color: "#ffffff"; opacity: 0.85 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (Weather.getData) Weather.getData(); } }
                }
            }

               RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 130 // Se aumentó de 120 a 130 para dar aire extra
                spacing: 12
                Layout.bottomMargin: 10 

                ForecastCard { dayIndex: 0 }
                ForecastCard { dayIndex: 1 }
                ForecastCard { dayIndex: 2 }
                ForecastCard { dayIndex: 3 }
                ForecastCard { dayIndex: 4 }
            }
        }
    }
}
