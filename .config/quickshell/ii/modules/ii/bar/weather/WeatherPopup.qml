import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    // Estado interno (no depende de root.visible)
    property bool isOpen: false

    function toggle() {
        if (root.isOpen) {
            root._closeAndSync()
            return
        }

        root.isOpen = true
        root.open()

        // Forzar foco después de abrir (sin Timer: StyledPopup suele esperar un único hijo visual)
        Qt.callLater(function() {
            focusScope.forceActiveFocus()
        })
    }

    function requestOpen() { toggle() }

    function _closeAndSync() {
        if (!root.isOpen) return
        root.isOpen = false
        root.close()
    }

    // =============================
    // Data safe
    // =============================
    readonly property var w: Weather.data
    function _s(v) {
        if (v === null || v === undefined) return ""
        return ("" + v).trim()
    }

    readonly property string cityText: {
        var c = _s(w?.city || w?.location || w?.name || w?.place)
        if (c.length > 26) c = c.slice(0, 26) + "…"
        return c
    }

    readonly property string conditionText: {
        var s = _s(w?.condition || w?.summary || w?.description || w?.wText)
        if (s.length > 32) s = s.slice(0, 32) + "…"
        return s
    }

    readonly property string tempText: _s(w?.temp) !== "" ? _s(w?.temp) : "--"
    readonly property string feelsLikeText: {
        var f = _s(w?.tempFeelsLike || w?.feelsLike || w?.apparentTemp || w?.feels)
        return f === "" ? "" : Translation.tr("Feels like %1").arg(f)
    }

    readonly property string highLowText: {
        var hi = _s(w?.high || w?.tempMax || w?.max)
        var lo = _s(w?.low || w?.tempMin || w?.min)
        if (hi === "" && lo === "") return ""
        if (hi !== "" && lo !== "") return Translation.tr("High %1 · Low %2").arg(hi).arg(lo)
        if (hi !== "") return Translation.tr("High %1").arg(hi)
        return Translation.tr("Low %1").arg(lo)
    }

    readonly property string lastRefreshText: _s(w?.lastRefresh)
    readonly property var wCode: w?.wCode

    function weatherIcon() {
        return Icons.getWeatherIcon(wCode) ?? "cloud"
    }

    function accentBase() {
        var s = (wCode === undefined || wCode === null) ? "" : ("" + wCode).toLowerCase().trim()
        var n = parseInt(s)

        function kind() {
            if (!isNaN(n)) {
                if (n >= 200 && n < 300) return "storm"
                if (n >= 300 && n < 600) return "rain"
                if (n >= 600 && n < 700) return "snow"
                if (n >= 700 && n < 800) return "fog"
                if (n === 800) return "sun"
                if (n > 800 && n < 900) return "cloud"
            }
            if (s.indexOf("thunder") !== -1 || s.indexOf("storm") !== -1) return "storm"
            if (s.indexOf("rain") !== -1 || s.indexOf("drizzle") !== -1 || s.indexOf("shower") !== -1) return "rain"
            if (s.indexOf("snow") !== -1 || s.indexOf("sleet") !== -1 || s.indexOf("hail") !== -1) return "snow"
            if (s.indexOf("fog") !== -1 || s.indexOf("mist") !== -1 || s.indexOf("haze") !== -1) return "fog"
            if (s.indexOf("cloud") !== -1 || s.indexOf("overcast") !== -1) return "cloud"
            if (s.indexOf("clear") !== -1 || s.indexOf("sun") !== -1) return "sun"
            return "default"
        }

        switch (kind()) {
        case "sun":   return Qt.rgba(1.00, 0.78, 0.18, 1.0)
        case "cloud": return Qt.rgba(0.78, 0.86, 0.98, 1.0)
        case "rain":  return Qt.rgba(0.28, 0.68, 1.00, 1.0)
        case "storm": return Qt.rgba(0.72, 0.46, 1.00, 1.0)
        case "snow":  return Qt.rgba(0.66, 0.95, 1.00, 1.0)
        case "fog":   return Qt.rgba(0.80, 0.84, 0.88, 1.0)
        default:      return Qt.rgba(1, 1, 1, 1.0)
        }
    }

    // Animación suave del fondo
    property real phase: 0.0
    NumberAnimation on phase {
        running: root.isOpen
        loops: Animation.Infinite
        from: 0.0
        to: 1.0
        duration: 4200
        easing.type: Easing.InOutSine
    }

    // UN SOLO HIJO VISUAL (StyledPopup-friendly)
    FocusScope {
        id: focusScope
        focus: true

        Keys.onEscapePressed: root._closeAndSync()

        // Cierra al perder foco
        onActiveFocusChanged: {
            if (!focusScope.activeFocus && root.isOpen) {
                root._closeAndSync()
            }
        }

        Item {
            id: contentContainer
            anchors.centerIn: parent

            implicitWidth: mainLayout.implicitWidth + 28
            implicitHeight: mainLayout.implicitHeight + 30

            Rectangle {
                anchors.fill: parent
                radius: 22
                antialiasing: true
                clip: true

                color: Qt.rgba(0.05, 0.06, 0.08, 0.92)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: Qt.rgba(accentBase().r, accentBase().g, accentBase().b, 0.22) }
                        GradientStop { position: 0.55; color: Qt.rgba(0.20, 0.25, 0.38, 0.18) }
                        GradientStop { position: 1.00; color: Qt.rgba(0.05, 0.06, 0.08, 0.00) }
                    }
                    opacity: 0.85
                }

                Rectangle {
                    width: parent.width * 0.9
                    height: parent.height * 1.4
                    radius: 999
                    rotation: -18
                    x: (-parent.width * 0.6) + (parent.width * 1.2 * root.phase)
                    y: -parent.height * 0.3
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(accentBase().r, accentBase().g, accentBase().b, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.0) }
                    }
                    opacity: 0.9
                }
            }

            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent
                spacing: 10

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        MaterialSymbol {
                            text: "location_on"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Qt.rgba(accentBase().r, accentBase().g, accentBase().b, 0.95)
                            visible: cityText !== ""
                        }
                        StyledText {
                            text: cityText
                            visible: cityText !== ""
                            font.weight: Font.DemiBold
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Qt.rgba(1,1,1,0.92)
                            font.letterSpacing: 0.35
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: conditionText !== "" ? conditionText : Translation.tr("Current")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Qt.rgba(1,1,1,0.70)
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        StyledText {
                            text: tempText
                            font.weight: Font.Black
                            font.bold: true
                            font.pixelSize: 74
                            color: Qt.rgba(1,1,1,0.96)
                            font.features: ({ "tnum": 1 })
                        }

                        MaterialSymbol {
                            text: weatherIcon()
                            fill: 0
                            iconSize: 48
                            color: Qt.rgba(1,1,1,0.72)
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: feelsLikeText
                        visible: feelsLikeText !== ""
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Qt.rgba(1,1,1,0.62)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: highLowText
                        visible: highLowText !== ""
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Qt.rgba(1,1,1,0.62)
                    }
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    uniformCellWidths: true
                    Layout.alignment: Qt.AlignHCenter

                    component DetailCard: Rectangle {
                        id: dCard
                        Layout.preferredWidth: 150
                        Layout.minimumWidth: 140
                        Layout.preferredHeight: 62

                        radius: 18
                        color: Qt.rgba(0, 0, 0, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.07)

                        property string title: ""
                        property string value: ""
                        property string icon: ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 12
                                color: Qt.rgba(accentBase().r, accentBase().g, accentBase().b, 0.16)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: dCard.icon
                                    iconSize: 20
                                    color: Qt.rgba(1,1,1,0.86)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: dCard.title
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Qt.rgba(1,1,1,0.62)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: dCard.value
                                    font.weight: Font.DemiBold
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Qt.rgba(1,1,1,0.90)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    DetailCard { title: Translation.tr("Wind"); icon: "air"; value: _s(w?.wind) }
                    DetailCard { title: Translation.tr("Humidity"); icon: "humidity_percentage"; value: _s(w?.humidity) }
                    DetailCard { title: Translation.tr("UV Index"); icon: "wb_sunny"; value: _s(w?.uv) }
                    DetailCard { title: Translation.tr("Pressure"); icon: "compress"; value: _s(w?.press) }
                    DetailCard { title: Translation.tr("Visibility"); icon: "visibility"; value: _s(w?.visib) }
                    DetailCard { title: Translation.tr("Precipitation"); icon: "rainy"; value: _s(w?.precip) }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 18
                    color: Qt.rgba(0,0,0,0.14)
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.07)
                    Layout.topMargin: 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        RowLayout {
                            spacing: 8
                            MaterialSymbol { text: "wb_twilight"; color: "#FFA726"; iconSize: 20 }
                            StyledText {
                                text: _s(w?.sunrise)
                                font.weight: Font.Medium
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Qt.rgba(1,1,1,0.86)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 8
                            StyledText {
                                text: _s(w?.sunset)
                                font.weight: Font.Medium
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Qt.rgba(1,1,1,0.86)
                            }
                            MaterialSymbol { text: "bedtime"; color: "#7E57C2"; iconSize: 20 }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: lastRefreshText !== ""
                    text: Translation.tr("Updated: %1").arg(lastRefreshText)
                    font.pixelSize: 10
                    color: Qt.rgba(1,1,1,0.45)
                }
            }
        }
    }
}

