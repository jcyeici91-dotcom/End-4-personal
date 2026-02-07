//==============================================================================
// 0) IMPORTS (ordenados por grupo)
//==============================================================================

// 0.1) QS / módulos internos
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions

// 0.2) Qt (base + layouts + controles + efectos)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

// 0.3) Quickshell / Wayland / Hyprland
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets


//==============================================================================
// 1) ROOT: Item principal
//==============================================================================

Item {
    id: root


    //==========================================================================
    // 1.1) FLAGS / OPCIONES (toggles) — fácil de mantener
    //==========================================================================

    // General
    property bool premium: true
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless

    // FX: fondo “ocupado” del workspace + píldora activa del workspace
    property bool fxOccupiedBackground: true         // fondo “ocupado” por workspace
    property bool fxActiveIndicatorPill: true        // píldora del workspace activo

    // FX Premium: indicador activo
    property bool premiumActiveIndicatorPulse: true  // pulso del indicador activo
    property bool premiumActiveIndicatorGlow: true   // brillo (glow) del indicador activo
    property bool premiumActiveIndicatorBorder: true // borde del indicador activo
    property bool neonBorders: true                  // borde neón giratorio (ConicalGradient)
    property bool activeParticles: true              // partículas dentro del indicador

    // FX Premium: hover sobre iconos
    property bool premiumIconHoverDot: false          // efecto feo 
    property int hoverDotSize: 8                     // tamaño base (se usa para el hover pill)
    property int hoverDotBottomMargin: 3
    property bool premiumIconHoverPulse: true        // pulso del hover pill

    // FX Premium: icono enfocado
    property bool premiumFocusedIconFx: true         // FX en icono enfocado
    property bool focusedIconChip: true              // chip detrás del icono enfocado
    property bool focusedIconRing: true              // aro del icono enfocado
    property bool focusedIconGlow: true              // glow del icono enfocado
    property bool focusedIconPulse: true             // pulso al cambiar foco
    property bool focusedIconCornerDot: false        // reservado (actualmente no usado)

    property real focusedChipOpacity: 0.22
    property real focusedChipBorderOpacity: 0.45
    property int focusToken: 0                       // token para disparar animaciones al cambiar foco

    // FX Premium: resaltar instancias de la misma app en el workspace activo
    property bool highlightSameAppInstances: true
    property real sameAppChipOpacity: 0.12
    property real sameAppChipBorderOpacity: 0.28
    property real sameAppRingOpacity: 0.45
    property bool sameAppGlow: true

    // FX Premium: “dot” activo inferior
    property bool bottomActiveDotEnabled: true
    property int bottomActiveDotSize: 10             // tamaño base (se usa para el dot activo)
    property int bottomActiveDotBottomMargin: 0
    property bool bottomActiveDotGlow: true
    property bool bottomActiveDotOutline: true
    property real bottomActiveDotGlowOpacity: 0.75
    property real bottomActiveDotGlowBlur: 1.05
    property real bottomActiveDotOutlineOpacity: 0.70

    //--------------------------------------------------------------------------
    // 1.1.x) EFECTO TECLA SUPER (Win): mostrar números + encoger/mover iconos
    //--------------------------------------------------------------------------

    property bool superNumbersEnabled: true     // activar/desactivar el efecto
    property bool superShowNumbers: false       // estado actual (runtime)
    property int superNumbersDelayMs: 100       // delay antes de activar números

    // Tamaños relativos del icono con/sin Super (respecto al "wrapper" del workspace)
    property real workspaceIconSizeFactor: 0.69         // normal (69%)
    property real workspaceIconSizeShrinkFactor: 0.55   // shrink (55%)

// Offset del icono en modo Super.
// +N = inset (hacia adentro), -N = outset (más a la esquina)
property int workspaceIconMarginShrinked: -4               // ajsute de la izquina al apretar super


    // Opacidad del icono cuando está shrink (lo dejo configurable por si quieres)
    property real workspaceIconOpacityShrinked: 1.0

    //==========================================================================
    // 1.2) “VALORES MÁGICOS” -> PROPIEDADES (cleanup para mantener fácil)
    //==========================================================================

    // 1.2.1) Hover pill (debajo del icono hovered)
    property int hoverPillWidth: hoverDotSize
    property int hoverPillHeight: Math.max(2, Math.round(hoverDotSize / 3))
    property int hoverPillRadius: Math.round(hoverPillHeight / 2)

    // 1.2.2) Dot activo inferior (debajo del icono enfocado)
    property int activeDotWidth: bottomActiveDotSize
    property int activeDotHeight: Math.max(2, Math.round(bottomActiveDotSize / 3))
    property int activeDotRadius: Math.round(activeDotHeight / 2)

    // 1.2.3) Indicador de workspace (píldoras cuando NO hay números)
    property int wsIndicatorPillWidth: 10
    property int wsIndicatorPillHeight: 4
    property int wsIndicatorPillGap: 4
    property int wsIndicatorPillRadius: Math.round(wsIndicatorPillHeight / 2)

    // 1.2.4) Insets del indicador activo (ajustes visuales)
    property real activeIndicatorInsetEmptyFactor: 0.07
    property real activeIndicatorInsetOneWindowFactor: 0.10
    property real activeIndicatorInsetDefaultFactor: 0.10

    // 1.2.5) Partículas
    property int activeParticlesCount: 5


    //==========================================================================
    // 1.3) ESTADO EXTERNO / BINDINGS (solo lectura)
    //==========================================================================

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property bool useWorkspaceMap: Config.options.bar.workspaces.useWorkspaceMap
    readonly property list<int> workspaceMap: Config.options.bar.workspaces.workspaceMap
    readonly property int monitorIndex: barLoader.monitorIndex
    property int workspaceOffset: useWorkspaceMap ? (workspaceMap[monitorIndex] ?? 0) : 0

    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspaceGroup: Math.floor(
        (monitor?.activeWorkspace?.id - root.workspaceOffset - 1) / root.workspacesShown
    )

    readonly property bool hyprReady: !!(Hyprland && Hyprland.workspaces && Hyprland.workspaces.values)
    readonly property bool appAwake: (
        Qt.application.state !== Qt.ApplicationSuspended &&
        Qt.application.state !== Qt.ApplicationHidden
    )
    readonly property bool fxEnabled: premium && visible && hyprReady && appAwake


    //==========================================================================
    // 1.4) CACHE / MODELOS (workspaces, ventanas, índices)
    //==========================================================================

    property list<bool> workspaceOccupied: []
    property var workspaceOccupiedById: ({})
    property list<int> visibleWorkspaces: []

    property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - root.workspaceOffset - 1) % root.workspacesShown
    property var monitorWindows

    readonly property int activeVisibleIndex: {
        const id = monitor?.activeWorkspace?.id ?? -1
        if (!visibleWorkspaces || visibleWorkspaces.length === 0) return -1
        return visibleWorkspaces.indexOf(id)
    }


    //==========================================================================
    // 1.5) TAMAÑOS / LAYOUT (presentación)
    //==========================================================================

    property int individualIconBoxHeight: 24
    property int iconBoxWrapperSize: 28
    property real iconRatio: 0.8
    property bool showIcons: Config.options.bar.workspaces.showAppIcons


    //==========================================================================
    // 1.6) TOKENS DE FX / ESTADO DE ANIMACIONES
    //==========================================================================

    property int burstToken: 0
    property int burstIndex: -1

    // Disparador: cuando cambia ventana activa, incrementa token para pulso del foco
    onActiveWindowChanged: focusToken = focusToken + 1


    //==========================================================================
    // 1.7) ANIMACIONES GLOBALES (p.ej. giro del borde neón)
    //==========================================================================

    property real spinningAngle: 0.0
    NumberAnimation on spinningAngle {
        running: fxEnabled && neonBorders
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 2600
        easing.type: Easing.Linear
    }

    QtObject {
        id: activeIndicatorPulse
        property real pulsePhase: 0.0
    }


    //==========================================================================
    // 2) FUNCIONES (lógica de datos / utilidades)
    //==========================================================================

    function rebuildVisibleWorkspaces(occupiedSet) {
        const shown = Math.max(0, root.workspacesShown)
        const activeId = monitor?.activeWorkspace?.id ?? -1
        const base = workspaceOffset + workspaceGroup * shown

        let slots = []
        for (let i = 0; i < shown; i++) slots.push(base + i + 1)

        const inGroup = new Set(slots)

        let outsideOccupied = Array.from(occupiedSet)
            .filter(id => id > 0 && !inGroup.has(id))
            .sort((a, b) => a - b)

        let replaceIdx = []
        for (let i = 0; i < shown; i++) {
            const wsId = slots[i]
            const isActive = (wsId === activeId)
            const isOccInGroup = (root.workspaceOccupied && root.workspaceOccupied[i] === true)
            if (!isActive && !isOccInGroup) replaceIdx.push(i)
        }

        for (let k = 0; k < replaceIdx.length && k < outsideOccupied.length; k++) {
            slots[replaceIdx[k]] = outsideOccupied[k]
        }

        slots.sort((a, b) => a - b)
        root.visibleWorkspaces = slots
    }

    function updateWorkspaceOccupied() {
        const shown = Math.max(0, root.workspacesShown)
        const base = workspaceOffset + workspaceGroup * shown
        const list = HyprlandData?.windowList ?? []

        workspaceOccupied = Array.from({ length: shown }, (_, i) => {
            const wsId = base + i + 1
            return list.some(w =>
                w &&
                !w.floating &&
                (w.monitor === root.monitorIndex) &&
                (w.workspace?.id === wsId)
            )
        })

        const occSet = new Set()
        const occMap = {}

        for (let i = 0; i < list.length; i++) {
            const w = list[i]
            const wsId = w?.workspace?.id
            if (!w || w.floating) continue
            if (w.monitor !== root.monitorIndex) continue
            if (!wsId || wsId <= 0) continue
            occSet.add(wsId)
        }

        occSet.forEach((id) => { occMap[id] = true })
        root.workspaceOccupiedById = occMap

        rebuildVisibleWorkspaces(occSet)
    }

    function getWindowCount(workspaceId) {
        return HyprlandData.windowList
            .filter(w => w.workspace.id === workspaceId && !w.floating)
            .length
    }


    //==========================================================================
    // 3) CONEXIONES / LIFECYCLE (eventos que refrescan el estado)
    //==========================================================================

    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            const windowsOnMonitor = HyprlandData.windowList
                .filter(win => win.monitor === root.monitorIndex && !win.floating)

            windowsOnMonitor.sort((a, b) => a.at[0] - b.at[0])

            root.monitorWindows = windowsOnMonitor.map(win => ({
                icon: Quickshell.iconPath(AppSearch.guessIcon(win?.class), "image-missing"),
                workspace: win.workspace?.id,
                class: win?.class ?? "",
                title: win?.title ?? "",
                address: win?.address ?? "",
                appId: win?.appId ?? win?.app_id ?? ""
            }))

            root.updateWorkspaceOccupied()
        }
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateWorkspaceOccupied() }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied()
            focusToken = focusToken + 1

            const idx = (root.activeVisibleIndex >= 0) ? root.activeVisibleIndex : root.workspaceIndexInGroup
            const activeId = monitor?.activeWorkspace?.id ?? -1
            const occ = (root.workspaceOccupiedById && root.workspaceOccupiedById[activeId] === true)

            if (fxEnabled && fxOccupiedBackground && occ) {
                triggerOccupiedBurst(idx, 1.0)
            }
        }
    }

    onWorkspaceGroupChanged: updateWorkspaceOccupied()
    onWorkspacesShownChanged: updateWorkspaceOccupied()

    //--------------------------------------------------------------------------
    // 3.x) SUPER (Win): timer + conexión para activar "modo números"
    //--------------------------------------------------------------------------

    Timer {
        id: superNumbersTimer
        interval: root.superNumbersDelayMs
        repeat: false
        onTriggered: {
            if (!root.superNumbersEnabled) return
            root.superShowNumbers = true
        }
    }

    Connections {
        target: GlobalStates

        // Se llama cuando cambia el estado de la tecla Super (Win)
        function onSuperDownChanged() {
            if (!root.superNumbersEnabled) {
                superNumbersTimer.stop()
                root.superShowNumbers = false
                return
            }

            if (GlobalStates.superDown) {
                // Espera 100ms antes de mostrar números (evita parpadeos)
                superNumbersTimer.restart()
            } else {
                // Al soltar: se desactiva inmediato
                superNumbersTimer.stop()
                root.superShowNumbers = false
            }
        }
    }

    //==========================================================================
    // 4) INPUT (rueda + mouse)
    //==========================================================================

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) Hyprland.dispatch(`workspace r+1`)
            else if (event.angleDelta.y > 0) Hyprland.dispatch(`workspace r-1`)
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.RightButton
        onPressed: (event) => {
            if (event.button === Qt.RightButton) GlobalStates.overviewOpen = !GlobalStates.overviewOpen
            if (event.button === Qt.BackButton) Hyprland.dispatch(`togglespecialworkspace`)
        }
    }


    //==========================================================================
    // 5) SIZING / BEHAVIORS (tamaño del widget)
    //==========================================================================

    implicitWidth: root.vertical
        ? Appearance.sizes.verticalBarWidth
        : contentLayout.implicitWidth

    implicitHeight: root.vertical
        ? contentLayout.implicitHeight
        : Appearance.sizes.barHeight

    Behavior on implicitHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }


    //==============================================================================
// 6) UI: INDICADOR ACTIVO (píldora + glow + borde + neon + partículas) [HQ FIX]
//==============================================================================

Rectangle {
    id: activeIndicator
    z: 2
    visible: fxActiveIndicatorPill && (root.activeVisibleIndex >= 0)

    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter

    color: Appearance.colors.colPrimary
    radius: Appearance.rounding.full
    antialiasing: true

    AnimatedTabIndexPair { id: idxPair; index: Math.max(0, root.activeVisibleIndex) }

    function offsetFor(index) {
        let y = 0
        for (let i = 0; i < index; i++) {
            const item = contentLayout.children[i]
            y += root.vertical ? (item?.height - baseHeight) : (item?.width - baseHeight)
        }
        return y
    }

    property int baseHeight: root.iconBoxWrapperSize
    property int index: Math.max(0, root.activeVisibleIndex)

    property int wsId: (root.visibleWorkspaces && root.visibleWorkspaces.length > index)
        ? root.visibleWorkspaces[index]
        : -1

    property int windowCount: (wsId > 0) ? getWindowCount(wsId) : 0
    property bool isEmptyWorkspace: windowCount === 0
    property bool isOneWindow: windowCount === 1

    property real indicatorInsetEmpty: root.iconBoxWrapperSize * root.activeIndicatorInsetEmptyFactor
    property real indicatorInsetOneWindow: root.iconBoxWrapperSize * root.activeIndicatorInsetOneWindowFactor
    property real indicatorInset: root.iconBoxWrapperSize * root.activeIndicatorInsetDefaultFactor

    property real visualInset: {
        if (isEmptyWorkspace) return indicatorInsetEmpty
        if (isOneWindow) return indicatorInsetOneWindow
        return indicatorInset
    }

    property real pairMin: Math.min(idxPair.idx1, idxPair.idx2)
    property real pairAbs: Math.abs(idxPair.idx1 - idxPair.idx2)

    property real currentItemOffset: {
        const item = contentLayout.children[Math.max(0, root.activeVisibleIndex)]
        const itemSize = root.vertical ? item?.height : item?.width
        return itemSize - baseHeight
    }

    readonly property real accumulatedPreviousOffsets: offsetFor(Math.max(0, root.activeVisibleIndex) + 1)
    readonly property real baseIndicatorPosition: pairMin * root.iconBoxWrapperSize
    readonly property real baseIndicatorLength: (pairAbs + 1) * root.iconBoxWrapperSize

    property real indicatorPosition: baseIndicatorPosition
        + accumulatedPreviousOffsets
        - currentItemOffset
        + visualInset

    property real indicatorLength: baseIndicatorLength
        + currentItemOffset
        - visualInset * 2

    // Pixel-perfect (clave para evitar artefactos y “pixelado” raro)
    y: root.vertical ? Math.round(indicatorPosition) : 0
    x: root.vertical ? 0 : Math.round(indicatorPosition)
    implicitHeight: root.vertical ? Math.round(indicatorLength) : individualIconBoxHeight
    implicitWidth: root.vertical ? individualIconBoxHeight : Math.round(indicatorLength)

    SequentialAnimation {
        running: fxEnabled && premiumActiveIndicatorPulse && fxActiveIndicatorPill
        loops: Animation.Infinite

        NumberAnimation {
            target: activeIndicatorPulse
            property: "pulsePhase"
            from: 0
            to: 1
            duration: 2000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: activeIndicatorPulse
            property: "pulsePhase"
            from: 1
            to: 0
            duration: 2000
            easing.type: Easing.InOutSine
        }
    }

    // NEON opcional (bordes enteros + AA)
    Item {
        anchors.centerIn: parent
        width: Math.round(parent.width + 4)
        height: Math.round(parent.height + 4)
        visible: fxEnabled && neonBorders

        Rectangle {
            anchors.fill: parent
            radius: Math.round(parent.height / 2)
            antialiasing: true
            color: "transparent"
            border.width: 2   // entero para evitar artifacts

            layer.enabled: true
            layer.effect: ConicalGradient {
                angle: root.spinningAngle
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "transparent" }
                    GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.7) }
                    GradientStop { position: 0.50; color: "transparent" }
                    GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.7) }
                    GradientStop { position: 1.00; color: "transparent" }
                }
            }
        }
    }

    // GLOW (solo aquí usamos layer.* y SOLO una vez)
    layer.enabled: fxEnabled && fxActiveIndicatorPill && premiumActiveIndicatorGlow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 1.0 + (activeIndicatorPulse.pulsePhase * 0.5)
        shadowOpacity: 0.28 + (activeIndicatorPulse.pulsePhase * 0.18)
        shadowColor: Appearance.colors.colPrimary
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }

    // Borde (AA)
    Rectangle {
        anchors.fill: parent
        radius: Math.round(parent.radius)
        antialiasing: true
        visible: premiumActiveIndicatorBorder && fxActiveIndicatorPill
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15 + (activeIndicatorPulse.pulsePhase * 0.08))
    }

    // Partículas (enteros + AA)
    Repeater {
        model: (fxEnabled && activeParticles) ? root.activeParticlesCount : 0
        Rectangle {
            width: Math.round(1 + Math.random() * 2)
            height: width
            radius: width / 2
            antialiasing: true
            color: "white"
            opacity: 0.2 + Math.random() * 0.4

            x: Math.round(Math.random() * activeIndicator.width)
            y: Math.round(Math.random() * activeIndicator.height)

            property real destX: Math.round(Math.random() * activeIndicator.width)
            property real destY: Math.round(Math.random() * activeIndicator.height)

            Behavior on x { NumberAnimation { duration: 3000 + Math.random() * 2000; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 3000 + Math.random() * 2000; easing.type: Easing.InOutQuad } }

            Timer {
                running: fxEnabled && activeParticles
                interval: 3000 + Math.random() * 2000
                repeat: true
                onTriggered: {
                    parent.destX = Math.round(Math.random() * activeIndicator.width)
                    parent.destY = Math.round(Math.random() * activeIndicator.height)
                    parent.x = parent.destX
                    parent.y = parent.destY
                }
            }
        }
    }
}



    //==========================================================================
    // 7) UI: FONDO “OCUPADO” POR WORKSPACE (celdas traseras)
    //==========================================================================

    GridLayout {
        id: occupiedBgLayout
        anchors.centerIn: parent
        columnSpacing: 0
        rowSpacing: 0
        z: 1

        columns: root.vertical ? 1 : 99
        rows: root.vertical ? 99 : 1

        visible: fxOccupiedBackground

        Repeater {
            model: root.workspacesShown

            delegate: Rectangle {
                Layout.alignment: Qt.AlignCenter

                readonly property int wsId: (root.visibleWorkspaces && root.visibleWorkspaces.length > index)
                    ? root.visibleWorkspaces[index]
                    : (workspaceOffset + workspaceGroup * root.workspacesShown + index + 1)

                implicitWidth: root.vertical
                    ? root.iconBoxWrapperSize
                    : (contentLayout.children[index]?.width ?? root.iconBoxWrapperSize)

                implicitHeight: root.vertical
                    ? (contentLayout.children[index]?.height ?? root.iconBoxWrapperSize)
                    : root.iconBoxWrapperSize

                radius: Math.min(width, height) / 2
                topLeftRadius: radius
                topRightRadius: radius
                bottomLeftRadius: radius
                bottomRightRadius: radius

                color: ColorUtils.transparentize(
                    Appearance.m3colors.m3secondaryContainer,
                    premium ? 0.30 : 0.40
                )

                readonly property bool isOccupied: (root.workspaceOccupiedById && root.workspaceOccupiedById[wsId] === true) &&
                    !(!activeWindow?.activated && monitor?.activeWorkspace?.id === wsId)

                opacity: isOccupied ? 1 : 0

                Behavior on opacity { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on implicitHeight { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }
                Behavior on implicitWidth { animation: Appearance.animation.elementResize.numberAnimation.createObject(this) }
            }
        }
    }

//==========================================================================
// 8) UI: CONTENIDO PRINCIPAL (workspaces + iconos + indicadores)
//==========================================================================

GridLayout {
    id: contentLayout
    anchors.centerIn: parent
    columnSpacing: 0
    rowSpacing: 0
    z: 3

    columns: root.vertical ? 1 : 99
    rows: root.vertical ? 99 : 1

    Repeater {
        model: root.workspacesShown

        delegate: MouseArea {
            id: background
            Layout.alignment: Qt.AlignCenter

            implicitWidth: root.vertical
                ? root.iconBoxWrapperSize
                : Math.max(layout.implicitWidth + 8, root.iconBoxWrapperSize)

            implicitHeight: root.vertical
                ? Math.max(layout.implicitHeight + 8, root.iconBoxWrapperSize)
                : root.iconBoxWrapperSize

            hoverEnabled: true

            readonly property int workspaceValue: (root.visibleWorkspaces && root.visibleWorkspaces.length > index)
                ? root.visibleWorkspaces[index]
                : (workspaceOffset + workspaceGroup * workspacesShown + index + 1)

            readonly property bool isActive: (monitor?.activeWorkspace?.id === workspaceValue)

            readonly property bool hasIconsHere: showIcons && (
                (monitorWindows?.some(w => w && w.workspace === workspaceValue)) ?? false
            )

            readonly property var winsHere: root.showIcons
                ? (root.monitorWindows
                    ?.filter(win => win && win.workspace === workspaceValue)
                    ?.slice(0, Config.options.bar.workspaces.maxWindowCount) ?? [])
                : []

            function appKeyFor(w) {
                const c = (w?.class ?? (w?.appId ?? ""))
                const t = (w?.title ?? "")
                if (c && c.length > 0) return c
                if (t && t.length > 0) return t
                return (w?.icon ?? "")
            }

            readonly property string focusedAddress: (root.activeWindow?.address ?? "")
            readonly property string focusedClass: (root.activeWindow?.class ?? root.activeWindow?.appId ?? root.activeWindow?.app_id ?? "")
            readonly property string focusedTitle: (root.activeWindow?.title ?? "")

            readonly property string focusedAppKey: {
                if (focusedClass && focusedClass.length > 0) return focusedClass
                if (focusedTitle && focusedTitle.length > 0) return focusedTitle
                return ""
            }

            readonly property int focusedIconIndex: {
                if (!background.isActive) return -1
                if (!root.showIcons) return -1
                if (!winsHere || winsHere.length === 0) return -1

                if (focusedAddress && focusedAddress.length > 0) {
                    for (let i = 0; i < winsHere.length; i++) {
                        if ((winsHere[i]?.address ?? "") === focusedAddress) return i
                    }
                }

                if (focusedClass && focusedClass.length > 0) {
                    for (let j = 0; j < winsHere.length; j++) {
                        const k = (winsHere[j]?.class ?? (winsHere[j]?.appId ?? ""))
                        if (k === focusedClass) return j
                    }
                }

                if (focusedTitle && focusedTitle.length > 0) {
                    for (let k2 = 0; k2 < winsHere.length; k2++) {
                        if ((winsHere[k2]?.title ?? "") === focusedTitle) return k2
                    }
                }

                return -1
            }

            readonly property int focusedAppCountHere: {
                if (!background.isActive) return 0
                if (!focusedAppKey || focusedAppKey.length === 0) return 0
                return (winsHere ?? []).filter(w => appKeyFor(w) === focusedAppKey).length
            }

            readonly property bool showCenteredActiveDot: fxEnabled
                && premium
                && root.bottomActiveDotEnabled
                && background.isActive
                && (background.focusedIconIndex >= 0)
                && (background.focusedAppCountHere === 2)

            readonly property int focusedAppFirstIndex: {
                if (!showCenteredActiveDot) return -1
                for (let i = 0; i < (winsHere ?? []).length; i++) {
                    if (appKeyFor(winsHere[i]) === focusedAppKey) return i
                }
                return -1
            }

            readonly property int focusedAppSecondIndex: {
                if (!showCenteredActiveDot) return -1
                let firstFound = false
                for (let i = 0; i < (winsHere ?? []).length; i++) {
                    if (appKeyFor(winsHere[i]) === focusedAppKey) {
                        if (!firstFound) firstFound = true
                        else return i
                    }
                }
                return -1
            }

            property int hoveredIconIndex: -1
            readonly property bool hoveringAnyIcon: hoveredIconIndex >= 0

            onClicked: Hyprland.dispatch(`workspace ${workspaceValue}`)

            //==================================================================
            // 8.0) Indicador de fondo (AISLADO) + soporte "modo Super"
            //==================================================================
            WorkspaceBackgroundIndicator {
                z: root.superShowNumbers ? 60 : 3
                workspaceValue: background.workspaceValue
                activeWorkspace: background.isActive

                // Si hay iconos, se suprime; EXCEPTO cuando Super está activo
                suppressed: background.hasIconsHere && !root.superShowNumbers

                // Forzar números con Super (o si config siempre muestra números)
                showNumbers: root.superShowNumbers || Config.options.bar.workspaces.alwaysShowNumbers

                // Entradas para hacerlo 100% autónomo
                iconsImplicitHeight: layout.implicitHeight
                iconsImplicitWidth: layout.implicitWidth
                wrapperSize: root.iconBoxWrapperSize
                paddingGuard: 8
            }

            //==================================================================
            // 8.1) Layout de iconos (por workspace)
            //==================================================================
            GridLayout {
                id: layout
                anchors.centerIn: parent
                columnSpacing: 0
                rowSpacing: 0
                columns: root.vertical ? 1 : 99
                rows: root.vertical ? 99 : 1
                z: 2

                Repeater {
                    model: background.winsHere

                    delegate: Item {
                        id: iconCell
                        Layout.alignment: Qt.AlignHCenter
                        width: root.individualIconBoxHeight
                        height: root.individualIconBoxHeight
                        clip: false

                        // Suspender FX de foco mientras Win (Super) está presionada
                        readonly property bool superFx: root.superShowNumbers

                        readonly property bool isFocusedIconExact: background.isActive && (index === background.focusedIconIndex)

                        readonly property string myAppKey: background.appKeyFor(modelData)
                        readonly property bool isSameAppAsFocused: background.isActive
                            && root.highlightSameAppInstances
                            && (background.focusedAppKey && background.focusedAppKey.length > 0)
                            && (myAppKey === background.focusedAppKey)
                            && (background.focusedAppCountHere > 1)

                        readonly property bool showSameAppFx: isSameAppAsFocused && !isFocusedIconExact

                        MouseArea {
                            id: iconHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: background.hoveredIconIndex = index
                            onExited: {
                                if (background.hoveredIconIndex === index)
                                    background.hoveredIconIndex = -1
                            }
                        }

                        // CHIP (oculto en modo Super)
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            radius: 999
                            visible: fxEnabled && premium && !iconCell.superFx
                                && premiumFocusedIconFx && root.focusedIconChip
                                && (iconCell.isFocusedIconExact || iconCell.showSameAppFx)

                            color: Qt.rgba(
                                Appearance.colors.colPrimary.r,
                                Appearance.colors.colPrimary.g,
                                Appearance.colors.colPrimary.b,
                                iconCell.isFocusedIconExact ? root.focusedChipOpacity : root.sameAppChipOpacity
                            )
                            border.width: 1
                            border.color: Qt.rgba(
                                Appearance.colors.colPrimary.r,
                                Appearance.colors.colPrimary.g,
                                Appearance.colors.colPrimary.b,
                                iconCell.isFocusedIconExact ? root.focusedChipBorderOpacity : root.sameAppChipBorderOpacity
                            )

                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            layer.enabled: fxEnabled && (root.focusedIconGlow || root.sameAppGlow)
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: iconCell.isFocusedIconExact ? 1.0 : 0.85
                                shadowOpacity: iconCell.isFocusedIconExact ? 0.55 : 0.32
                                shadowColor: Appearance.colors.colPrimary
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }
                        }

                        // RING (oculto en modo Super)
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: 999
                            visible: fxEnabled && premium && !iconCell.superFx
                                && premiumFocusedIconFx && root.focusedIconRing
                                && (iconCell.isFocusedIconExact || iconCell.showSameAppFx)

                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, iconCell.isFocusedIconExact ? 0.75 : root.sameAppRingOpacity)

                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

                        // PULSE (oculto en modo Super)
                        Rectangle {
                            id: focusedPulse
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: 999
                            visible: fxEnabled && premium && !iconCell.superFx
                                && premiumFocusedIconFx && root.focusedIconPulse
                                && iconCell.isFocusedIconExact

                            color: Appearance.colors.colPrimary
                            opacity: 0

                            Connections {
                                target: root
                                function onFocusTokenChanged() {
                                    if (!focusedPulse.visible) return
                                    focusedPulseAnim.restart()
                                }
                            }

                            SequentialAnimation {
                                id: focusedPulseAnim
                                running: false
                                PropertyAction { target: focusedPulse; property: "opacity"; value: 0.0 }
                                PropertyAction { target: focusedPulse; property: "scale"; value: 1.0 }
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: focusedPulse
                                        property: "opacity"
                                        from: 0.28; to: 0.0
                                        duration: 260
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: focusedPulse
                                        property: "scale"
                                        from: 1.0; to: 1.55
                                        duration: 260
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                   //==========================================================
// 8.1.1) Icono principal (EFECTO SUPER) [HQ - Qt Image]
//==========================================================
Item {
    id: iconFxBox
    width: root.iconBoxWrapperSize
    height: root.iconBoxWrapperSize
    anchors.centerIn: parent
    clip: false

    Image {
        id: mainAppIcon
        source: modelData.icon

        readonly property int superExtraDown: 3
        readonly property int cornerOffset: Math.max(-8, Math.min(8, root.workspaceIconMarginShrinked))

        width: Math.round(root.iconBoxWrapperSize * (
            root.superShowNumbers ? root.workspaceIconSizeShrinkFactor : root.workspaceIconSizeFactor
        ))
        height: width

        opacity: root.superShowNumbers ? root.workspaceIconOpacityShrinked : 1.0

        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        cache: true

        // Aquí sí existe:
        sourceSize.width: 64
        sourceSize.height: 64

        readonly property real focusYOffset: (root.bottomActiveDotEnabled
            && iconCell.isFocusedIconExact
            && !background.showCenteredActiveDot) ? -2 : 0

        x: root.superShowNumbers
            ? Math.round(iconFxBox.width - width - cornerOffset)
            : Math.round((iconFxBox.width - width) / 2)

        y: (root.superShowNumbers
            ? Math.round(iconFxBox.height - height - cornerOffset)
            : Math.round((iconFxBox.height - height) / 2))
           + focusYOffset
           + (root.superShowNumbers ? superExtraDown : 0)

        scale: iconCell.isFocusedIconExact ? 1.08 : (iconHover.containsMouse ? 1.05 : 1.0)

        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
}



                        // DOT activo (oculto en modo Super)
                        Rectangle {
                            visible: fxEnabled && premium && !iconCell.superFx
                                && root.bottomActiveDotEnabled
                                && iconCell.isFocusedIconExact
                                && !background.showCenteredActiveDot

                            width: root.activeDotWidth
                            height: root.activeDotHeight
                            radius: root.activeDotRadius

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: root.bottomActiveDotBottomMargin

                            color: Appearance.colors.colPrimary
                            opacity: 1.0

                            border.width: root.bottomActiveDotOutline ? 1 : 0
                            border.color: Qt.rgba(0, 0, 0, root.bottomActiveDotOutlineOpacity)

                            layer.enabled: fxEnabled && root.bottomActiveDotGlow
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: root.bottomActiveDotGlowBlur
                                shadowOpacity: root.bottomActiveDotGlowOpacity
                                shadowColor: Appearance.colors.colPrimary
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }
                        }

                        Loader {
                            active: Config.options.bar.workspaces.monochromeIcons
                            anchors.fill: mainAppIcon
                            sourceComponent: Item {
                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false
                                    anchors.fill: parent
                                    source: mainAppIcon
                                    desaturation: 0.8
                                }
                                ColorOverlay {
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.9)
                                }
                            }
                        }
                    }
                }
            }

            //==================================================================
            // 8.2) Dot centrado entre dos instancias
            //==================================================================
            Item {
                anchors.fill: layout
                z: 5
                visible: background.showCenteredActiveDot
                    && (background.focusedAppFirstIndex >= 0)
                    && (background.focusedAppSecondIndex >= 0)

                readonly property real iconW: root.individualIconBoxHeight
                readonly property real centerA: (background.focusedAppFirstIndex + 0.5) * iconW
                readonly property real centerB: (background.focusedAppSecondIndex + 0.5) * iconW
                readonly property real midCenter: (centerA + centerB) / 2.0

                Rectangle {
                    width: root.activeDotWidth
                    height: root.activeDotHeight
                    radius: root.activeDotRadius

                    x: parent.midCenter - width / 2
                    y: parent.height - height - root.bottomActiveDotBottomMargin

                    color: Appearance.colors.colPrimary
                    opacity: 1.0

                    border.width: root.bottomActiveDotOutline ? 1 : 0
                    border.color: Qt.rgba(0, 0, 0, root.bottomActiveDotOutlineOpacity)

                    layer.enabled: fxEnabled && root.bottomActiveDotGlow
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: root.bottomActiveDotGlowBlur
                        shadowOpacity: root.bottomActiveDotGlowOpacity
                        shadowColor: Appearance.colors.colPrimary
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }
            }

            //==================================================================
            // 8.3) Indicador hover
            //==================================================================
            Item {
                anchors.fill: parent
                z: 3.9

                visible: fxEnabled
                    && premium
                    && premiumIconHoverDot
                    && root.showIcons
                    && background.isActive
                    && background.hoveringAnyIcon

                readonly property int count: background.winsHere.length
                readonly property real iconW: root.individualIconBoxHeight
                readonly property real totalW: count * iconW
                readonly property real startX: (background.width - totalW) / 2
                readonly property int idx: Math.max(0, Math.min(background.hoveredIconIndex, Math.max(0, count - 1)))

                Rectangle {
                    width: root.hoverPillWidth
                    height: root.hoverPillHeight
                    radius: root.hoverPillRadius
                    color: Appearance.colors.colPrimary

                    x: startX + idx * iconW + (iconW - width) / 2
                    y: background.height - height - root.hoverDotBottomMargin

                    opacity: parent.visible ? 1 : 0
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}


   //==========================================================================
// 9) COMPONENTE: indicador de fondo del workspace (AISLADO / ROBUSTO)
//==========================================================================

component WorkspaceBackgroundIndicator: Item {
    // 9.1) Entradas
    property bool showNumbers: Config.options.bar.workspaces.alwaysShowNumbers
    property int workspaceValue
    property bool activeWorkspace
    property bool suppressed: false

    // 9.2) Entradas de “entorno” (antes dependía del id layout externo)
    property int iconsImplicitHeight: 0
    property int iconsImplicitWidth: 0
    property int wrapperSize: 28          // se setea desde fuera: root.iconBoxWrapperSize
    property int paddingGuard: 8          // margen de seguridad (antes era “+ 8” fijo)

    // 9.3) Estado
    readonly property bool hasWindows: (root.workspaceOccupiedById && root.workspaceOccupiedById[workspaceValue] === true)
    readonly property int windowCount: (activeWorkspace && hasWindows) ? getWindowCount(workspaceValue) : 0

    // 9.4) Visibilidad base (TOTALMENTE autónoma)
    // Usamos el tamaño “más grande” del bloque de iconos para decidir si hay espacio.
    readonly property int iconsFootprint: Math.max(iconsImplicitWidth, iconsImplicitHeight)

    // Si showNumbers está activo, NO bloqueamos por "iconsFootprint"
    // (queremos que el número se vea aunque haya iconos)
    readonly property bool baseVisible: !suppressed && (
        showNumbers ? true : (iconsFootprint + paddingGuard < wrapperSize)
    )

    readonly property bool showPill: baseVisible && !showNumbers && activeWorkspace && hasWindows
    readonly property bool showNumber: baseVisible && showNumbers

    anchors.centerIn: parent
    width: wrapperSize
    height: wrapperSize
    visible: baseVisible

    readonly property color indColor: Appearance.colors.colPrimary

    // 9.5) Número de workspace (con z alto + más contraste)
    StyledText {
        // Subimos el z para que quede por encima de iconos y fondos
        z: 50

        visible: showNumber
        opacity: showNumber ? 1 : 0
        anchors.centerIn: parent

        text: Config.options?.bar.workspaces.numberMap[workspaceValue - 1] || workspaceValue
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        // Colores más contrastados (recomendado para modo Super)
        color: activeWorkspace
            ? Qt.rgba(1, 1, 1, 1)
            : (hasWindows
                ? Qt.rgba(1, 1, 1, 0.75)
                : Qt.rgba(1, 1, 1, 0.45))

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    // 9.6) Píldoras (1 o 2) si hay ventanas y el workspace está activo
    Item {
        id: pillLayer
        visible: showPill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3

        readonly property int pillW: root.wsIndicatorPillWidth
        readonly property int pillH: root.wsIndicatorPillHeight
        readonly property int gap: root.wsIndicatorPillGap
        readonly property int pills: (windowCount >= 2) ? 2 : 1

        width: (pills === 2) ? (pillW * 2 + gap) : pillW
        height: pillH

        Row {
            anchors.centerIn: parent
            spacing: pillLayer.gap

            Repeater {
                model: pillLayer.pills
                delegate: Rectangle {
                    width: pillLayer.pillW
                    height: pillLayer.pillH
                    radius: root.wsIndicatorPillRadius
                    color: indColor

                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.25)

                    layer.enabled: fxEnabled && root.bottomActiveDotGlow
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: root.bottomActiveDotGlowBlur
                        shadowOpacity: root.bottomActiveDotGlowOpacity * 0.75
                        shadowColor: indColor
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }
            }
        }
    }
}


    //==========================================================================
    // 10) FUNCIONES: disparadores de FX (burst)
    //==========================================================================

    function triggerOccupiedBurst(index, strength) {
        if (!premium) return
        if (!fxEnabled) return
        if (!fxOccupiedBackground) return
        if (index < 0 || index >= workspacesShown) return

        const wsId = (root.visibleWorkspaces && root.visibleWorkspaces.length > index)
            ? root.visibleWorkspaces[index]
            : -1

        if (!(root.workspaceOccupiedById && root.workspaceOccupiedById[wsId] === true)) return

        burstIndex = index
        burstToken = burstToken + 1
    }
}

