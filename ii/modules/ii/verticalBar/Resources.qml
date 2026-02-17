import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.ii.bar as Bar

MouseArea {
    id: root

    // ========================================================================
    // ORIENTACIÓN: VerticalBar
    // ========================================================================
    property bool vertical: true
    property bool rotateInVertical: true
    property int verticalRotationDegrees: -90

    // ========================================================================
    // AUTO-ADAPT a Bar width (Settings 30..50)
    // ========================================================================
    readonly property int barW: Math.floor(Appearance.sizes.verticalBarWidth)
    readonly property real barWT: {
        var t = (barW - 30) / 20.0
        return Math.max(0.0, Math.min(1.0, t))
    }

    function lerp(a, b, t) { return a + (b - a) * t }
    function lerpI(a, b, t) { return Math.round(lerp(a, b, t)) }
    function clamp01(x) { return Math.max(0, Math.min(1, x)); }

    // ========================================================================
    // AJUSTES RÁPIDOS (adaptados a vertical)
    // ========================================================================
    property int resourcesSpacingV: lerpI(2, 6, barWT)
    readonly property int resourcesSpacing: resourcesSpacingV

    property int resourceInnerSpacingV: lerpI(1, 2, barWT)
    readonly property int resourceInnerSpacing: resourceInnerSpacingV

    property int outerPaddingV: lerpI(4, 7, barWT)
    readonly property int outerPadding: outerPaddingV

    property int resourceLeftMarginV: lerpI(0, 2, barWT)
    readonly property int resourceLeftMargin: resourceLeftMarginV

    property bool enableEffects: true
    property bool enableTooltips: true
    readonly property bool tooltipsEnabledEffective: false // vertical: apagado

    // CONTRASTE / LEGIBILIDAD (sin opacity>1)
    property real resourceBackdropOpacity: 0.34
    property real resourceBackdropBorderOpacity: 0.16
    property int resourceBackdropRadius: 6
    property int resourceBackdropPadX: 6
    property int resourceBackdropPadY: 3

    // Gato
    property bool showCat: true
    property bool enableCatGif: true
    property bool enableCatEffects: true
    property bool reserveCatSpace: false

    // Dot
    property int dotSize: lerpI(4, 6, barWT)
    property int dotExtraBox: lerpI(8, 10, barWT)

    // Cat size
    property int catHeightV: lerpI(22, 28, barWT)
    readonly property int catHeight: catHeightV
    readonly property int catWidth: Math.round(catHeight * 1.30)

    // Visual
    property bool verticalCompact: true
    property real verticalScale: lerp(0.92, 1.00, barWT)
    property bool verticalCrispLayer: true

    property bool popupOpen: false
    function openPopup()  { root.popupOpen = true; root.forceActiveFocus() }
    function closePopup() {
        root.popupOpen = false
        if (popupLoader.item && popupLoader.item.close) popupLoader.item.close()
    }

    // Cierra si la app deja de estar activa
    Connections {
        target: Qt.application
        function onActiveChanged() {
            if (!Qt.application.active && root.popupOpen) root.closePopup()
        }
    }

    // Escape para cerrar
    focus: true
    Keys.onEscapePressed: (event) => {
        if (root.popupOpen) {
            root.closePopup()
            event.accepted = true
        }
    }

    property bool alwaysShowAllResources: false
    readonly property bool isMediaPlaying: (MprisController.activePlayer?.trackTitle?.length ?? 0) > 0

    property int cpuCatThresholdPercent: 10
    readonly property bool cpuCatRunRaw: (ResourceUsage.cpuUsage * 100.0) >= cpuCatThresholdPercent
    readonly property bool cpuCatRun: (enableEffects && enableCatEffects) ? cpuCatRunRaw : false

    readonly property bool cpuShown: Config.options.bar.resources.alwaysShowCpu
                                  || !isMediaPlaying
                                  || alwaysShowAllResources

    readonly property bool showCatEffective: showCat

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: false
    preventStealing: true
    propagateComposedEvents: false

    implicitWidth: paddedContent.implicitWidth
    implicitHeight: paddedContent.implicitHeight

    Process { id: btopProc; command: ["kitty", "-e", "btop"] }
    function openBtop() { btopProc.running = false; btopProc.running = true }

    onPressed: (mouse) => {
        mouse.accepted = true

        if (mouse.button === Qt.RightButton) {
            if (root.popupOpen) root.closePopup()
            else root.openPopup()
            return
        }

        if (mouse.button === Qt.LeftButton) {
            if (root.popupOpen) {
                root.closePopup()
                return
            }
            openBtop()
            return
        }
    }
    onClicked: (mouse) => { mouse.accepted = true }

    readonly property real t20: 0.20
    readonly property real t50: 0.50
    readonly property real t75: 0.75

    readonly property color colGreen:  "#22c55e"
    readonly property color colYellow: "#fde047"
    readonly property color colOrange: "#fb923c"
    readonly property color colRed:    "#ef4444"

    function mixColor(c1, c2, t) {
        t = clamp01(t)
        return Qt.rgba(
            c1.r * (1 - t) + c2.r * t,
            c1.g * (1 - t) + c2.g * t,
            c1.b * (1 - t) + c2.b * t,
            c1.a * (1 - t) + c2.a * t
        )
    }

    function alertColorByPercent(value01) {
        value01 = clamp01(value01)

        if (value01 < t20) {
            let t = value01 / Math.max(0.0001, t20)
            return mixColor(colGreen, colYellow, t * 0.20)
        }
        if (value01 < t50) {
            let t = (value01 - t20) / Math.max(0.0001, (t50 - t20))
            return mixColor(colYellow, colOrange, t * 0.25)
        }
        if (value01 < t75) {
            let t = (value01 - t50) / Math.max(0.0001, (t75 - t50))
            return mixColor(colOrange, colRed, t)
        }
        return colRed
    }

    function tempCTo01(tempC) {
        let t = Number(tempC)
        if (!isFinite(t) || t <= 0) return 0
        let minC = 35
        let maxC = 85
        return clamp01((t - minC) / Math.max(1, (maxC - minC)))
    }

    function roundToInt(x) {
        let n = Number(x)
        if (!isFinite(n)) return 0
        return Math.round(n)
    }

    // ========================================================================
    // TEMPS (JSON)
    // ========================================================================
    property real cpuTempC: 0
    property real gpuTempC: 0

    readonly property real cpuTemp01: tempCTo01(cpuTempC)
    readonly property real gpuTemp01: tempCTo01(gpuTempC)

    readonly property string cpuTempLabel: roundToInt(cpuTempC) + "°C"
    readonly property string gpuTempLabel: roundToInt(gpuTempC) + "°C"

    readonly property string tempsJsonPath: (Quickshell.env("HOME") || "") + "/.cache/quickshell/temps.json"
    property bool debugTemps: false

    function parseTempsJson(raw) {
        let s = String(raw || "").trim()
        if (!s.length) { cpuTempC = 0; gpuTempC = 0; return }

        try {
            let obj = JSON.parse(s)
            cpuTempC = Number(obj.cpu_c) || 0
            gpuTempC = Number(obj.gpu_c) || 0
            if (debugTemps) console.log("[temps] parsed cpuC=", cpuTempC, "gpuC=", gpuTempC)
        } catch (e) {
            if (debugTemps) console.log("[temps] JSON parse error:", e, "raw=", s)
            cpuTempC = 0
            gpuTempC = 0
        }
    }

    FileView { id: fileTemps; path: tempsJsonPath }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fileTemps.reload()
            parseTempsJson(fileTemps.text())
        }
    }

    component PulsingDot: Item {
        id: dot
        property color color: root.colGreen
        property int size: root.dotSize
        property real intensity: 0.0

        width: size + root.dotExtraBox
        height: size + root.dotExtraBox

        readonly property int pulseMs: Math.max(560, Math.round(980 - (dot.intensity * 420)))

        Rectangle { id: haloBig; anchors.centerIn: parent; width: dot.size; height: dot.size; radius: width/2; color: dot.color; opacity: 0.10; scale: 1.0 }
        Rectangle { id: haloMid; anchors.centerIn: parent; width: dot.size; height: dot.size; radius: width/2; color: dot.color; opacity: 0.18; scale: 1.0 }
        Rectangle { id: core;    anchors.centerIn: parent; width: dot.size; height: dot.size; radius: width/2; color: dot.color; opacity: 0.96 }

        Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.InOutQuad } }

        SequentialAnimation {
            running: root.enableEffects
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation { target: haloBig; property: "scale"; from: 1.0; to: 2.65; duration: Math.round(dot.pulseMs * 1.10); easing.type: Easing.OutCubic }
                NumberAnimation { target: haloBig; property: "opacity"; from: 0.10; to: 0.00; duration: Math.round(dot.pulseMs * 1.10); easing.type: Easing.OutCubic }
                NumberAnimation { target: haloMid; property: "scale"; from: 1.0; to: 2.15; duration: dot.pulseMs; easing.type: Easing.OutCubic }
                NumberAnimation { target: haloMid; property: "opacity"; from: 0.18; to: 0.00; duration: dot.pulseMs; easing.type: Easing.OutCubic }
                NumberAnimation { target: core; property: "scale"; from: 1.0; to: 1.18; duration: Math.round(dot.pulseMs * 0.42); easing.type: Easing.OutQuad }
                NumberAnimation { target: core; property: "scale"; from: 1.18; to: 1.0; duration: Math.round(dot.pulseMs * 0.58); easing.type: Easing.InOutQuad }
            }
        }
    }

component ResourceWithDot: RowLayout {
    id: wrap
    spacing: root.resourceInnerSpacing
    Layout.alignment: Qt.AlignVCenter

    property string iconName
    property real percentage: 0
    property string valueOverride: ""
    property bool shown: true
    property real warningThreshold01: 0.75
    visible: shown

    readonly property real value01: root.clamp01(wrap.percentage)

    Bar.Resource {
        iconName: wrap.iconName
        percentage: wrap.percentage
        warningThreshold: Math.round(wrap.warningThreshold01 * 100)
        valueOverride: wrap.valueOverride
        opacity: 1.0
    }

    PulsingDot {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: 1
        Layout.leftMargin: -3

        color: root.alertColorByPercent(wrap.value01)
        intensity: wrap.value01 < root.t20 ? 0.10
                   : wrap.value01 < root.t50 ? 0.35
                   : wrap.value01 < root.t75 ? 0.70
                   : 1.00
        visible: root.enableEffects
    }
}

    Item {
        id: paddedContent
        anchors.centerIn: parent

        implicitWidth: contentItem.implicitWidth + (root.outerPadding * 2)
        implicitHeight: contentItem.implicitHeight + (root.outerPadding * 2)

        Item {
            id: contentItem
            x: root.outerPadding
            y: root.outerPadding

            implicitWidth: loader.implicitWidth
            implicitHeight: loader.implicitHeight

            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: verticalContent
            }
        }
    }

    Component {
        id: verticalContent

        Item {
            id: vRoot
            readonly property real effScale: (root.verticalCompact ? root.verticalScale : 1.0)

            implicitWidth: Math.round(rowSameAsTop.implicitHeight * effScale)
            implicitHeight: Math.round(rowSameAsTop.implicitWidth * effScale)

            Item {
                anchors.centerIn: parent
                width: Math.round(rowSameAsTop.implicitHeight * vRoot.effScale)
                height: Math.round(rowSameAsTop.implicitWidth * vRoot.effScale)

                Item {
                    width: rowSameAsTop.implicitWidth
                    height: rowSameAsTop.implicitHeight
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)

                    rotation: root.verticalRotationDegrees
                    transformOrigin: Item.Center
                    antialiasing: true

                    // evita “barras”
                    layer.enabled: root.verticalCrispLayer
                    layer.smooth: true
                    layer.mipmap: true

                    RowLayout {
                        id: rowSameAsTop
                        spacing: root.resourcesSpacing

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.topMargin: -2

                            Layout.preferredHeight: (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catHeight : 0
                            Layout.preferredWidth:  (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catWidth  : 0

                            Loader {
                                active: root.showCatEffective && root.cpuShown && root.enableCatGif
                                visible: active
                                anchors.fill: parent

                                sourceComponent: Bar.ResourceCat {
                                    running: Qt.binding(function() { return root.cpuCatRun })
                                    runSource: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-run.gif"
                                    sleepSource: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-sleep.gif"
                                }
                            }
                        }

                        ResourceWithDot {
                            iconName: "memory"
                            percentage: root.clamp01(ResourceUsage.memoryUsedPercentage)
                            warningThreshold01: Config.options.bar.resources.memoryWarningThreshold / 100.0
                        }

                        ResourceWithDot {
                            iconName: "device_thermostat"
                            percentage: root.cpuTemp01
                            valueOverride: root.cpuTempLabel
                            Layout.leftMargin: root.resourceLeftMargin
                            warningThreshold01: 0.75
                        }

                        ResourceWithDot {
                            iconName: "thermostat"
                            percentage: root.gpuTemp01
                            valueOverride: root.gpuTempLabel
                            Layout.leftMargin: root.resourceLeftMargin
                            warningThreshold01: 0.75
                        }

                        ResourceWithDot {
                            iconName: "planner_review"
                            percentage: root.clamp01(ResourceUsage.cpuUsage)
                            shown: root.cpuShown
                            Layout.leftMargin: shown ? root.resourceLeftMargin : 0
                            warningThreshold01: Config.options.bar.resources.cpuWarningThreshold / 100.0
                        }
                    }
                }
            }
        }
    }


    Loader {
        id: popupLoader
        active: root.popupOpen

        sourceComponent: Bar.ResourcesPopup {
            // clave: solo conectar hoverTarget cuando ya está abierto
            hoverTarget: root.popupOpen ? root : null
        }

        onLoaded: {
            if (item && item.open) item.open()
        }
        onActiveChanged: {
            if (!active && item && item.close) item.close()
        }
    }


    MouseArea {
        id: closePopupCatcher
        anchors.fill: parent
        enabled: root.popupOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: false
        z: 9999
        propagateComposedEvents: true

        onPressed: (event) => {
            root.closePopup()
            event.accepted = false
        }
    }
}

