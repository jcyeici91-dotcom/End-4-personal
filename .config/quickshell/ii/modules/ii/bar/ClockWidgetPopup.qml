pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../sidebarDashboard/calendar" as SidebarCalendar
import qs.modules.ii.bar
import "weather"

Scope {
    id: root
    property bool open: false
    property string formattedUptime: DateTime.uptime
    property Item triggerItem: null
    property int defaultIndex: 0
    property var widgetRect: Qt.rect(0, 0, 0, 0)

    onOpenChanged: {
        if (open && triggerItem) {
            let pos = triggerItem.mapToItem(null, 0, 0)
            widgetRect = Qt.rect(pos.x, pos.y, triggerItem.width, triggerItem.height)
        }
    }

    property real openAnim: root.open ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuart }
    }

    // --- Lógica unificada para detectar si debe unirse o flotar ---
    readonly property bool isFloatOrHybrid: (Config.options.bar.cornerStyle === 1) || (Config.options.bar.barBackgroundStyle === 0) || (Config.options.bar.barBackgroundStyle === 3)
    readonly property int floatingGap: 12 

    Loader {
        id: clockLoader
        active: true
        sourceComponent: PanelWindow {
            id: panelWindow

            visible: root.open || root.openAnim > 0.0
            color: "transparent"

            readonly property real baseRadius: Appearance.rounding.windowRounding
            readonly property int contentW: 360 + (baseRadius * 2)
            readonly property int contentH: mainLayout.implicitHeight + 48 + baseRadius

            implicitWidth: contentW
            implicitHeight: contentH

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:clockPopup_" + root.defaultIndex
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

            margins {
                top: {
                    if (root.widgetRect.width === 0) return 0
                    if (isVertical) {
                        let targetY = root.widgetRect.y + (root.widgetRect.height / 2) - (panelWindow.contentH / 2)
                        return Math.max(0, Math.min(targetY, screen.height - panelWindow.contentH))
                    } else {
                        return !isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                    }
                }
                bottom: !isVertical && isBottomRight ? (barThickness + (root.isFloatOrHybrid ? root.floatingGap : 0)) : 0
                left: {
                    if (root.widgetRect.width === 0) return 0
                    if (!isVertical) {
                        let targetX = root.widgetRect.x + (root.widgetRect.width / 2) - (panelWindow.contentW / 2)
                        return Math.max(0, Math.min(targetX, screen.width - panelWindow.contentW))
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

                    // NOTA: Se ha eliminado la opacidad para replicar el efecto físico de deslizamiento puro.
                    x: panelWindow.barEdge === "left" ? -off * width : (panelWindow.barEdge === "right" ? off * width : 0)
                    y: panelWindow.barEdge === "top" ? -off * height : (panelWindow.barEdge === "bottom" ? off * height : 0)

                    Item {
                        id: background
                        anchors.fill: parent

                        // Fondo inteligente: Componentes importados exactamente igual que en MediaControls
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
                                    PathQuad { x: rad; y: rad; controlX: rad; controlY: 0 }
                                    PathLine { x: rad; y: h - rad }
                                    PathQuad { x: rad * 2; y: h; controlX: rad; controlY: h }
                                    PathLine { x: w - rad * 2; y: h }
                                    PathQuad { x: w - rad; y: h - rad; controlX: w - rad; controlY: h }
                                    PathLine { x: w - rad; y: rad }
                                    PathQuad { x: w; y: 0; controlX: w - rad; controlY: 0 }
                                    PathLine { x: 0; y: 0 }
                                }

                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Appearance.colors.colLayer0Border
                                    strokeWidth: 1
                                    capStyle: ShapePath.FlatCap
                                    startX: 0
                                    startY: 0
                                    PathQuad { x: rad; y: rad; controlX: rad; controlY: 0 }
                                    PathLine { x: rad; y: h - rad }
                                    PathQuad { x: rad * 2; y: h; controlX: rad; controlY: h }
                                    PathLine { x: w - rad * 2; y: h }
                                    PathQuad { x: w - rad; y: h - rad; controlX: w - rad; controlY: h }
                                    PathLine { x: w - rad; y: rad }
                                    PathQuad { x: w; y: 0; controlX: w - rad; controlY: 0 }
                                }
                            }
                        }
                    }

                    Item {
                        id: paddedContainer
                        anchors.fill: parent
                        anchors.topMargin: panelWindow.barEdge === "top" ? panelWindow.baseRadius : (panelWindow.barEdge === "bottom" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)
                        anchors.bottomMargin: panelWindow.barEdge === "bottom" ? panelWindow.baseRadius : (panelWindow.barEdge === "top" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)
                        anchors.leftMargin: panelWindow.barEdge === "left" ? panelWindow.baseRadius : (panelWindow.barEdge === "right" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)
                        anchors.rightMargin: panelWindow.barEdge === "right" ? panelWindow.baseRadius : (panelWindow.barEdge === "left" ? panelWindow.baseRadius / 2 : panelWindow.baseRadius)

                        ColumnLayout {
                            id: mainLayout
                            anchors.centerIn: parent
                            width: parent.width - 48 - panelWindow.baseRadius
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                spacing: 10

                                component TabButton: Rectangle {
                                    id: tabRect
                                    required property string text
                                    required property int tabIndex
                                    required property string icon
                                    property bool isActive: flick.currentIndex === tabIndex
                                    
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: height / 2
                                    color: isActive ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                                    border.width: isActive ? 1 : 0
                                    border.color: Appearance.colors.colLayer0Border
                                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        MaterialSymbol {
                                            text: tabRect.icon
                                            font.pixelSize: 18
                                            color: tabRect.isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                        }
                                        StyledText {
                                            text: tabRect.text
                                            font.weight: Font.Bold
                                            font.pixelSize: 13
                                            color: tabRect.isActive ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                        }
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: flick.contentX = tabIndex * flick.width
                                    }
                                }

                                TabButton { text: Translation.tr("Calendario"); icon: "calendar_month"; tabIndex: 0 }
                                TabButton { text: Translation.tr("Clima"); icon: "cloud"; tabIndex: 1 }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(calLayout.implicitHeight, weaLayout.implicitHeight)
                                clip: true

                                Flickable {
                                    id: flick
                                    anchors.fill: parent
                                    contentWidth: parent.width * 2
                                    contentHeight: parent.height
                                    flickableDirection: Flickable.HorizontalFlick
                                    boundsBehavior: Flickable.StopAtBounds
                                    interactive: true

                                    onVisibleChanged: {
                                        if (visible) contentX = root.defaultIndex * width
                                    }

                                    property int currentIndex: Math.round(contentX / width)

                                    onDraggingChanged: {
                                        if (!dragging) contentX = currentIndex * width
                                    }

                                    Behavior on contentX {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }

                                    Row {
                                        Item {
                                            width: Math.max(1, flick.width)
                                            height: flick.height
                                            ColumnLayout {
                                                id: calLayout
                                                anchors.centerIn: parent
                                                width: parent.width
                                                spacing: 16

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 4
                                                    spacing: 12
                                                    
                                                    Rectangle {
                                                        width: 46; height: 46; radius: 23
                                                        color: Appearance.colors.colLayer2
                                                        border.width: 2; border.color: Appearance.colors.colPrimary
                                                        clip: true
                                                        
                                                        Image {
                                                            id: userAvatar
                                                            anchors.fill: parent
                                                            source: "file:///home/" + (Quickshell.env("USER") || "") + "/.face"
                                                            fillMode: Image.PreserveAspectCrop
                                                            asynchronous: true
                                                            visible: status === Image.Ready
                                                        }
                                                        
                                                        MaterialSymbol {
                                                            anchors.centerIn: parent
                                                            text: "person"
                                                            font.pixelSize: 28
                                                            color: Appearance.colors.colPrimary
                                                            visible: !userAvatar.visible
                                                        }
                                                    }
                                                    
                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2
                                                        
                                                        StyledText {
                                                            text: Translation.tr("Hola, %1").arg(Quickshell.env("USER") || "Usuario")
                                                            font.pixelSize: Appearance.font.pixelSize.large
                                                            font.weight: Font.Bold
                                                            color: Appearance.colors.colOnSurface
                                                        }
                                                        StyledText {
                                                            text: Translation.tr("Aquí tienes tu agenda")
                                                            font.pixelSize: Appearance.font.pixelSize.small
                                                            color: Appearance.colors.colOnSurfaceVariant
                                                        }
                                                    }
                                                }

                                                SidebarCalendar.CalendarWidget {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                        }

                                        Item {
                                            width: Math.max(1, flick.width)
                                            height: flick.height
                                            ColumnLayout {
                                                id: weaLayout
                                                anchors.top: parent.top
                                                width: parent.width
                                                spacing: 12

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 110
                                                    radius: Appearance.rounding.windowRounding
                                                    color: Appearance.colors.colLayer1
                                                    border.width: 1
                                                    border.color: Appearance.colors.colLayer0Border
                                                    clip: true

                                                    MaterialSymbol {
                                                        text: "partly_cloudy_day"
                                                        font.pixelSize: 150
                                                        color: Appearance.colors.colPrimary
                                                        opacity: 0.15
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: -30
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 16
                                                        
                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 2
                                                            
                                                            RowLayout {
                                                                spacing: 6
                                                                MaterialSymbol {
                                                                    text: "location_on"
                                                                    font.pixelSize: 16
                                                                    color: Appearance.colors.colPrimary
                                                                }
                                                                StyledText {
                                                                    text: Weather.data.city !== undefined ? Weather.data.city : "Ubicación..."
                                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                                    font.weight: Font.Bold
                                                                    color: Appearance.colors.colOnSurface
                                                                }
                                                            }
                                                            
                                                            StyledText {
                                                                text: Weather.data.temp !== undefined ? Weather.data.temp : "--"
                                                                font.pixelSize: 36
                                                                font.weight: Font.Black
                                                                color: Appearance.colors.colPrimary
                                                            }
                                                            
                                                            StyledText {
                                                                text: Translation.tr("Sensación: %1").arg(Weather.data.tempFeelsLike !== undefined ? Weather.data.tempFeelsLike : "--")
                                                                font.pixelSize: Appearance.font.pixelSize.small
                                                                color: Appearance.colors.colOnSurfaceVariant
                                                            }
                                                        }
                                                    }
                                                }

                                                GridLayout {
                                                    columns: 2
                                                    rowSpacing: 10
                                                    columnSpacing: 10
                                                    Layout.fillWidth: true
                                                    uniformCellWidths: true

                                                    WeatherCard { title: Translation.tr("UV Index"); symbol: "wb_sunny"; value: Weather.data.uv !== undefined ? Weather.data.uv : "--" }
                                                    WeatherCard { title: Translation.tr("Wind"); symbol: "air"; value: `(${Weather.data.windDir !== undefined ? Weather.data.windDir : "-"}) ${Weather.data.wind !== undefined ? Weather.data.wind : "--"}` }
                                                    WeatherCard { title: Translation.tr("Precipitation"); symbol: "rainy_light"; value: Weather.data.precip !== undefined ? Weather.data.precip : "--" }
                                                    WeatherCard { title: Translation.tr("Humidity"); symbol: "humidity_low"; value: Weather.data.humidity !== undefined ? Weather.data.humidity : "--" }
                                                    WeatherCard { title: Translation.tr("Visibility"); symbol: "visibility"; value: Weather.data.visib !== undefined ? Weather.data.visib : "--" }
                                                    WeatherCard { title: Translation.tr("Pressure"); symbol: "readiness_score"; value: Weather.data.press !== undefined ? Weather.data.press : "--" }
                                                    WeatherCard { title: Translation.tr("Sunrise"); symbol: "wb_twilight"; value: Weather.data.sunrise !== undefined ? Weather.data.sunrise : "--" }
                                                    WeatherCard { title: Translation.tr("Sunset"); symbol: "bedtime"; value: Weather.data.sunset !== undefined ? Weather.data.sunset : "--" }
                                                }

                                                StyledText {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: Translation.tr("Última act: %1").arg(Weather.data.lastRefresh !== undefined ? Weather.data.lastRefresh : "--")
                                                    font.weight: Font.Medium
                                                    font.pixelSize: Appearance.font.pixelSize.tiny
                                                    color: Appearance.colors.colOnSurfaceVariant
                                                    opacity: 0.7
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Appearance.colors.colOnSurface
                                opacity: 0.08
                            }

                            StyledPopupValueRow {
                                icon: "timelapse"
                                label: Translation.tr("Tiempo de actividad")
                                value: root.formattedUptime
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            function updateDismissable() {
                if (root.open && !panelWindow.pinned) {
                    GlobalFocusGrab.addDismissable(panelWindow)
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow)
                }
            }

            property bool pinned: false

            Component.onCompleted: updateDismissable()
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
        }
    }

    Connections {
        target: root
        function onOpenChanged() {
            if (clockLoader.item) clockLoader.item.updateDismissable()
        }
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.open = false
        }
    }
}
