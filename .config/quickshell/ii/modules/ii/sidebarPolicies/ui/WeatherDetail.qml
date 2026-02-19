import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

import qs.modules.common.widgets
import qs.services 

Item {
    id: root

    required property var theme
    required property var model

    implicitWidth: 210
    implicitHeight: 120

    property bool autoDetectCity: true                 // intenta detectar ciudad por IP si el servicio no trae city
    property int cityRefreshMinutes: 720               // refrescar cada X minutos (12h)
    property string detectedCity: ""                   // ciudad detectada por IP

    readonly property color _surface: Qt.rgba(theme.colSurface.r, theme.colSurface.g, theme.colSurface.b, 0.60)
    readonly property color _border: Qt.rgba(255, 255, 255, 0.08)
    readonly property color _accent: theme.colAccent

    // Helpers
    function _clean(s) {
        if (s === null || s === undefined) return ""
        const t = String(s).trim()
        return t
    }

    readonly property string cityText: {
        const fromModel = _clean(root.model.weatherCity)
        if (fromModel.length > 0) return fromModel
        const fromDetect = _clean(root.detectedCity)
        if (fromDetect.length > 0) return fromDetect
        return Translation.tr("Location.Unknown") // agrega esta clave al JSON (o cámbiala por "—")
    }

    readonly property string tempText: {
        const t = _clean(root.model.weatherTemp)
        if (t.length === 0) return "--°C"
        if (t.includes("°")) return t
        return t + "°C"
    }

    // Detectar ciudad por IP (solo si el modelo no trae city)
    Timer {
        id: cityTimer
        running: root.autoDetectCity
        repeat: true
        triggeredOnStart: true
        interval: Math.max(1, root.cityRefreshMinutes) * 60 * 1000

        onTriggered: {
            // Solo detecta si el modelo NO trae ciudad
            if (_clean(root.model.weatherCity).length > 0) return
            if (!ipCityProc.running) ipCityProc.running = true
        }
    }

    Process {
        id: ipCityProc
        running: false

        // - Esto usa geolocalización por IP (no GPS).
        // - Requiere tener `curl` instalado.
        command: ["bash", "-lc",
            "curl -fsSL --max-time 2 https://ipapi.co/city/ 2>/dev/null | head -n 1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const c = root._clean(text)
                // ipapi a veces devuelve vacío o "Undefined"
                if (c.length > 0 && c.toLowerCase() !== "undefined" && c.toLowerCase() !== "null")
                    root.detectedCity = c
            }
        }
    }

      // UI
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 28
        color: root._surface
        border.width: 1
        border.color: root._border

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 24
            color: Qt.rgba(0, 0, 0, 0.25)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // Icono + Temperatura + Ciudad
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                radius: 20
                color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.15)
                border.width: 1
                border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.25)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.model.weatherIconFromCode(root.model.weatherCode)
                    font.pixelSize: 28
                    color: root._accent
                }
            }

            ColumnLayout {
                spacing: -2
                Layout.fillWidth: true

                Text {
                    text: root.tempText
                    color: theme.colText
                    font.family: theme.fontMain
                    font.pixelSize: 26
                    font.weight: Font.Black
                }

                // Si el nombre es largo, usa elide.
                Text {
                    text: root.cityText
                    color: theme.colSubText
                    font.family: theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.05)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    text: "device_thermostat"
                    font.pixelSize: 14
                    color: theme.colSubText
                    opacity: 0.7
                }

                Text {
                    text: root._clean(root.model.weatherCondition).length > 0
                            ? root.model.weatherCondition
                            : Translation.tr("Weather.Unknown")
                    color: theme.colSubText
                    font.family: theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }
    }
}

