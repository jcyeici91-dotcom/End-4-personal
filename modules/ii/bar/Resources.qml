import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Effects

MouseArea {
    id: root

    // ========================================================================
    //  🎨 DETECCIÓN INTELIGENTE DE TEMA
    // ========================================================================
    function _lin(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function _isDark(c) { return _lin(c) < 0.65 }

    readonly property bool themeIsDark: _isDark(Appearance.colors.colLayer0)

    // COLOR MAESTRO DEL TEXTO/ICONOS (Negro en claro / Blanco en oscuro)
    readonly property color smartContentColor: themeIsDark ? "#FFFFFF" : "#1D1D1D"

    // ========================================================================
    //  ✅ AJUSTES GENERALES
    // ========================================================================
    property bool vertical: false
    property bool rotateInVertical: true
    property int verticalRotationDegrees: -90

    property int resourcesSpacingH: 1
    property int resourcesSpacingV: 0
    readonly property int resourcesSpacing: root.vertical ? resourcesSpacingV : resourcesSpacingH

    property int resourceInnerSpacingH: 1
    property int resourceInnerSpacingV: 1
    readonly property int resourceInnerSpacing: root.vertical ? resourceInnerSpacingV : resourceInnerSpacingH

    property int outerPaddingH: 8
    property int outerPaddingV: 1
    readonly property int outerPadding: root.vertical ? outerPaddingV : outerPaddingH

    property int resourceLeftMarginH: 2
    property int resourceLeftMarginV: 0
    readonly property int resourceLeftMargin: root.vertical ? resourceLeftMarginV : resourceLeftMarginH

    // --- EFECTOS ---
    property bool enableEffects: true
    property bool enableTooltips: true

    // --- GATO ---
    property bool showCat: true
    property bool enableCatGif: true
    property bool enableCatEffects: true
    property bool reserveCatSpace: false

    // --- VERTICAL ---
    property bool verticalCompact: true
    property real verticalScale: 1.0
    property bool verticalCrispLayer: true
    property bool verticalLayerSmooth: false

    // --- PUNTITO (DOT) ---
    // He aumentado ligeramente el tamaño base para que se vea mejor
    property int dotSize: 7 
    property int dotExtraBox: 10

    property int catHeightH: 35
    property int catHeightV: 28

    // ========================================================================
    //  ESTADO DERIVADO
    // ========================================================================
    readonly property bool tooltipsEnabledEffective: root.enableTooltips && !root.vertical
    readonly property bool showCatEffective: root.showCat
    readonly property int catHeight: root.vertical ? catHeightV : catHeightH
    readonly property int catWidth: Math.round(root.catHeight * 1.30)
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: true
    readonly property bool isMediaPlaying: (MprisController.activePlayer?.trackTitle?.length ?? 0) > 0

    property int cpuCatThresholdPercent: 10
    readonly property bool cpuCatRunRaw: (ResourceUsage.cpuUsage * 100.0) >= cpuCatThresholdPercent
    readonly property bool cpuCatRun: (root.enableEffects && root.enableCatEffects) ? root.cpuCatRunRaw : false
    readonly property bool cpuShown: Config.options.bar.resources.alwaysShowCpu || !root.isMediaPlaying || root.alwaysShowAllResources

    // ========================================================================
    //  INPUT
    // ========================================================================
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: false
    preventStealing: true
    propagateComposedEvents: false

    implicitWidth: paddedContent.implicitWidth
    implicitHeight: root.vertical ? paddedContent.implicitHeight : Appearance.sizes.barHeight

    Process { id: btopProc; command: ["kitty", "-e", "btop"] }
    function openBtop() { btopProc.running = false; btopProc.running = true }

    onPressed: (mouse) => {
        mouse.accepted = true
        if (mouse.button === Qt.RightButton) { resourcesPopup.open(); return }
        if (mouse.button === Qt.LeftButton) { openBtop(); return }
    }
    onClicked: (mouse) => { mouse.accepted = true }

    // ========================================================================
    //  HELPERS
    // ========================================================================
    function clamp01(x) { return Math.max(0, Math.min(1, x)); }
    function mixColor(c1, c2, t) {
        t = clamp01(t);
        return Qt.rgba(c1.r*(1-t)+c2.r*t, c1.g*(1-t)+c2.g*t, c1.b*(1-t)+c2.b*t, c1.a*(1-t)+c2.a*t);
    }
    function tempCTo01(tempC) {
        let t = Number(tempC);
        if (!isFinite(t) || t <= 0) return 0;
        return clamp01((t - 35) / Math.max(1, (85 - 35)));
    }
    function roundToInt(x) { return Math.round(Number(x) || 0); }

    // ========================================================================
    //  COLORES
    // ========================================================================
    readonly property real t20: 0.20
    readonly property real t50: 0.50
    readonly property real t75: 0.75
    readonly property color colGreen:  "#22c55e"
    readonly property color colYellow: "#fde047"
    readonly property color colOrange: "#fb923c"
    readonly property color colRed:    "#ef4444"

    function alertColorByPercent(value01) {
        value01 = clamp01(value01);
        if (value01 < root.t20) {
            let t = value01 / Math.max(0.0001, root.t20);
            return root.mixColor(root.colGreen, root.colYellow, t * 0.20);
        }
        if (value01 < root.t50) {
            let t = (value01 - root.t20) / Math.max(0.0001, (root.t50 - root.t20));
            return root.mixColor(root.colYellow, root.colOrange, t * 0.25);
        }
        if (value01 < root.t75) {
            let t = (value01 - root.t50) / Math.max(0.0001, (root.t75 - root.t50));
            return root.mixColor(root.colOrange, root.colRed, t);
        }
        return root.colRed;
    }

    // ========================================================================
    //  TEMPS LOGIC
    // ========================================================================
    property real cpuTempC: 0
    property real gpuTempC: 0
    readonly property real cpuTemp01: root.tempCTo01(root.cpuTempC)
    readonly property real gpuTemp01: root.tempCTo01(root.gpuTempC)
    readonly property string cpuTempLabel: root.roundToInt(root.cpuTempC) + "°C"
    readonly property string gpuTempLabel: root.roundToInt(root.gpuTempC) + "°C"
    readonly property string tempsJsonPath: (Quickshell.env("HOME") || "") + "/.cache/quickshell/temps.json"

    function parseTempsJson(raw) {
        let s = String(raw || "").trim();
        if (!s.length) { cpuTempC = 0; gpuTempC = 0; return; }
        try {
            let obj = JSON.parse(s);
            cpuTempC = Number(obj.cpu_c) || 0;
            gpuTempC = Number(obj.gpu_c) || 0;
        } catch (e) { cpuTempC = 0; gpuTempC = 0; }
    }
    FileView { id: fileTemps; path: root.tempsJsonPath }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { fileTemps.reload(); root.parseTempsJson(fileTemps.text()) }
    }

    // ========================================================================
    //  TOOLTIP
    // ========================================================================
    Item {
        id: tooltipLayer
        anchors.fill: parent; z: 50; visible: root.tooltipsEnabledEffective && shown; enabled: false
        property string text: ""; property bool shown: false; property real px: 0; property real py: 0
        function showAt(item, localX, localY, t) {
            if (!root.tooltipsEnabledEffective) return
            text = t || ""; if (!text.length) { shown = false; return }
            let p = item.mapToItem(root, localX, localY); px = p.x; py = p.y; shown = true
        }
        function hide() { shown = false }
        Rectangle {
            visible: tooltipLayer.shown && tooltipLayer.text.length > 0
            opacity: visible ? 1 : 0; radius: 10; color: Qt.rgba(0, 0, 0, 0.72)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.10)
            x: Math.max(6, Math.min(root.width - width - 6, tooltipLayer.px - width / 2))
            y: Math.max(6, Math.min(root.height - height - 6, tooltipLayer.py - height - 10))
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Text {
                text: tooltipLayer.text; color: "white"; font.pixelSize: 11
                wrapMode: Text.NoWrap; leftPadding: 10; rightPadding: 10; topPadding: 6; bottomPadding: 6
                renderType: Text.NativeRendering
            }
            implicitWidth: childrenRect.width; implicitHeight: childrenRect.height
        }
    }

    // ========================================================================
    //  COMPONENTE: PUNTITO CON PULSO (MEJORADO PARA MODO CLARO)
    // ========================================================================
    component PulsingDot: Item {
        id: dot
        property color color: root.colGreen
        property int size: root.dotSize
        property real intensity: 0.0

        width: size + root.dotExtraBox
        height: size + root.dotExtraBox

        readonly property int pulseMs: Math.max(560, Math.round(980 - (dot.intensity * 420)))

        // LÓGICA DE OPACIDAD: En modo claro, los halos deben ser más sólidos (0.4/0.5) 
        // para que se vean sobre blanco. En oscuro, más transparentes (0.1/0.18) para brillar.
        readonly property real haloOpacityBig: root.themeIsDark ? 0.10 : 0.35 
        readonly property real haloOpacityMid: root.themeIsDark ? 0.18 : 0.50

        // HALO EXTERNO
        Rectangle { 
            id: haloBig
            anchors.centerIn: parent
            width: dot.size; height: dot.size; radius: width/2
            color: dot.color
            opacity: dot.haloOpacityBig
            scale: 1.0 
        }

        // HALO MEDIO
        Rectangle { 
            id: haloMid
            anchors.centerIn: parent
            width: dot.size; height: dot.size; radius: width/2
            color: dot.color
            opacity: dot.haloOpacityMid
            scale: 1.0 
        }
        
        // NÚCLEO SÓLIDO
        Rectangle { 
            id: core
            anchors.centerIn: parent
            width: dot.size
            height: dot.size
            radius: width/2
            color: dot.color
            opacity: 1.0 // Sólido total para que no se pierda el color
            
            // BORDE: En modo claro, agregamos un borde oscuro suave para separar el punto del fondo
            border.width: root.themeIsDark ? 0 : 1
            border.color: Qt.lighter(dot.color, 0.5) // Un tono más oscuro del mismo color
        }

        Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.InOutQuad } }

        SequentialAnimation {
            running: root.enableEffects
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation { target: haloBig; property: "scale"; from: 1.0; to: 2.65; duration: Math.round(dot.pulseMs * 1.10); easing.type: Easing.OutCubic }
                // La animación desvanece hasta 0, pero parte de una base más sólida en Light Mode
                NumberAnimation { target: haloBig; property: "opacity"; from: dot.haloOpacityBig; to: 0.00; duration: Math.round(dot.pulseMs * 1.10); easing.type: Easing.OutCubic }
                
                NumberAnimation { target: haloMid; property: "scale"; from: 1.0; to: 2.15; duration: dot.pulseMs; easing.type: Easing.OutCubic }
                NumberAnimation { target: haloMid; property: "opacity"; from: dot.haloOpacityMid; to: 0.00; duration: dot.pulseMs; easing.type: Easing.OutCubic }
                
                NumberAnimation { target: core; property: "scale"; from: 1.0; to: 1.18; duration: Math.round(dot.pulseMs * 0.42); easing.type: Easing.OutQuad }
                NumberAnimation { target: core; property: "scale"; from: 1.18; to: 1.0; duration: Math.round(dot.pulseMs * 0.58); easing.type: Easing.InOutQuad }
            }
        }
    }

    // ========================================================================
    //  COMPONENTE: RECURSO (CON FIX DE COLOR INTELIGENTE)
    // ========================================================================
    component ResourceWithDot: RowLayout {
        id: wrap
        spacing: root.resourceInnerSpacing
        Layout.alignment: Qt.AlignVCenter

        property string iconName
        property real percentage: 0
        property string valueOverride: ""
        property string tooltipText: ""
        property bool shown: true
        property real warningThreshold01: 0.75
        visible: shown

        readonly property real value01: root.clamp01(wrap.percentage)

        MouseArea {
            anchors.fill: parent
            enabled: root.tooltipsEnabledEffective
            hoverEnabled: root.tooltipsEnabledEffective
            acceptedButtons: Qt.NoButton
            onEntered: tooltipLayer.showAt(wrap, mouseX, mouseY, wrap.tooltipText)
            onPositionChanged: tooltipLayer.showAt(wrap, mouseX, mouseY, wrap.tooltipText)
            onExited: tooltipLayer.hide()
        }

        // TEXTO E ICONO (Negro en Light, Blanco en Dark)
        Resource {
            iconName: wrap.iconName
            percentage: wrap.percentage
            warningThreshold: Math.round(wrap.warningThreshold01 * 100)
            valueOverride: wrap.valueOverride
            
            // TRUCO: Usamos MultiEffect para forzar el color
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: root.smartContentColor // #FFFFFF o #1D1D1D
            }
        }

        PulsingDot {
            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: root.vertical ? 1 : 4
            Layout.leftMargin: root.vertical ? -3 : -2
            color: root.alertColorByPercent(wrap.value01)
            intensity: wrap.value01 < root.t20 ? 0.10 : wrap.value01 < root.t50 ? 0.35 : wrap.value01 < root.t75 ? 0.70 : 1.00
            visible: root.enableEffects
        }
    }

    // ========================================================================
    //  LAYOUT WRAPPER
    // ========================================================================
    Item {
        id: paddedContent
        anchors.centerIn: parent
        implicitWidth: contentItem.implicitWidth + (root.outerPadding * 2)
        implicitHeight: contentItem.implicitHeight + (root.outerPadding * 2)
        Item {
            id: contentItem
            x: root.outerPadding; y: root.outerPadding
            implicitWidth: loader.implicitWidth
            implicitHeight: loader.implicitHeight
            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: root.vertical ? verticalContent : horizontalContent
            }
        }
    }

    // ========================================================================
    //  HORIZONTAL
    // ========================================================================
    Component {
        id: horizontalContent
        RowLayout {
            spacing: root.resourcesSpacing
            Item {
                Layout.alignment: Qt.AlignVCenter; Layout.topMargin: -2
                Layout.preferredHeight: (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catHeight : 0
                Layout.preferredWidth:  (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catWidth  : 0
                Loader {
                    active: root.showCatEffective && root.cpuShown && root.enableCatGif; visible: active; anchors.fill: parent
                    source: "ResourceCat.qml"
                    onLoaded: {
                        if (!item) return
                        item.running = Qt.binding(function() { return root.cpuCatRun })
                        item.runSource = "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-run.gif"
                        item.sleepSource = "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-sleep.gif"
                    }
                }
            }
            ResourceWithDot { iconName: "memory"; percentage: root.clamp01(ResourceUsage.memoryUsedPercentage); tooltipText: "RAM"; warningThreshold01: Config.options.bar.resources.memoryWarningThreshold / 100.0 }
            ResourceWithDot { iconName: "device_thermostat"; percentage: root.cpuTemp01; valueOverride: root.cpuTempLabel; tooltipText: "CPU Temp"; Layout.leftMargin: root.resourceLeftMargin; warningThreshold01: 0.75 }
            ResourceWithDot { iconName: "thermostat"; percentage: root.gpuTemp01; valueOverride: root.gpuTempLabel; tooltipText: "GPU Temp"; Layout.leftMargin: root.resourceLeftMargin; warningThreshold01: 0.75 }
            ResourceWithDot { iconName: "planner_review"; percentage: root.clamp01(ResourceUsage.cpuUsage); tooltipText: "CPU Uso"; shown: root.cpuShown; Layout.leftMargin: shown ? root.resourceLeftMargin : 0; warningThreshold01: Config.options.bar.resources.cpuWarningThreshold / 100.0 }
        }
    }

    // ========================================================================
    //  VERTICAL
    // ========================================================================
    Component {
        id: verticalContent
        Item {
            id: vRoot
            readonly property real effScale: (root.verticalCompact ? root.verticalScale : 1.0)
            implicitWidth: root.rotateInVertical ? Math.round(rowSameAsTop.implicitHeight * effScale) : columnBlock.implicitWidth
            implicitHeight: root.rotateInVertical ? Math.round(rowSameAsTop.implicitWidth * effScale) : columnBlock.implicitHeight
            Item {
                id: rotContainer
                visible: root.rotateInVertical
                anchors.centerIn: parent
                width: Math.round(rowSameAsTop.implicitHeight * vRoot.effScale)
                height: Math.round(rowSameAsTop.implicitWidth * vRoot.effScale)
                Item {
                    id: rotContent
                    x: Math.round((parent.width - width) / 2); y: Math.round((parent.height - height) / 2)
                    width: rowSameAsTop.implicitWidth; height: rowSameAsTop.implicitHeight
                    rotation: root.verticalRotationDegrees; transformOrigin: Item.Center
                    antialiasing: true; layer.enabled: root.verticalCrispLayer; layer.smooth: root.verticalLayerSmooth; layer.mipmap: false
                    RowLayout {
                        id: rowSameAsTop
                        spacing: root.resourcesSpacing
                        Item {
                            Layout.alignment: Qt.AlignVCenter; Layout.topMargin: -2
                            Layout.preferredHeight: (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catHeight : 0
                            Layout.preferredWidth:  (root.showCatEffective && root.cpuShown && (root.enableCatGif || root.reserveCatSpace)) ? root.catWidth  : 0
                            Loader {
                                active: root.showCatEffective && root.cpuShown && root.enableCatGif; visible: active; anchors.fill: parent
                                source: "ResourceCat.qml"
                                onLoaded: {
                                    if (!item) return
                                    item.running = Qt.binding(function() { return root.cpuCatRun })
                                    item.runSource = "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-run.gif"
                                    item.sleepSource = "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/cat-sleep.gif"
                                }
                            }
                        }
                        ResourceWithDot { iconName: "memory"; percentage: root.clamp01(ResourceUsage.memoryUsedPercentage); tooltipText: "RAM"; warningThreshold01: Config.options.bar.resources.memoryWarningThreshold / 100.0 }
                        ResourceWithDot { iconName: "device_thermostat"; percentage: root.cpuTemp01; valueOverride: root.cpuTempLabel; tooltipText: "CPU Temp"; Layout.leftMargin: root.resourceLeftMargin; warningThreshold01: 0.75 }
                        ResourceWithDot { iconName: "thermostat"; percentage: root.gpuTemp01; valueOverride: root.gpuTempLabel; tooltipText: "GPU Temp"; Layout.leftMargin: root.resourceLeftMargin; warningThreshold01: 0.75 }
                        ResourceWithDot { iconName: "planner_review"; percentage: root.clamp01(ResourceUsage.cpuUsage); tooltipText: "CPU Uso"; shown: root.cpuShown; Layout.leftMargin: shown ? root.resourceLeftMargin : 0; warningThreshold01: Config.options.bar.resources.cpuWarningThreshold / 100.0 }
                    }
                }
            }
            ColumnLayout {
                id: columnBlock
                visible: !root.rotateInVertical; anchors.centerIn: parent; spacing: 10
            }
        }
    }

    ResourcesPopup { id: resourcesPopup; hoverTarget: root }
}
