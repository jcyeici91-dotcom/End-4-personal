import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.ii.bar.weather
import qs.modules.ii.verticalBar as Vertical

Item {
    id: rootItem

    // =========================================================
    // 1) API / Props (contrato externo)
    // =========================================================
    // barSection: 0 = left, 1 = center, 2 = right
    property int barSection: 0
    property var list: []                // lista del layout actual (puede venir undefined)
    required property var modelData      // debe tener modelData.id
    required property int index
    property int originalIndex: index    // estable para operar sobre Config.layouts
    property bool vertical: false

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    // Helpers de sección (legibilidad)
    readonly property bool isLeft: barSection === 0
    readonly property bool isCenter: barSection === 1
    readonly property bool isRight: barSection === 2

    // Lista segura (evita crashes si list es null)
    readonly property var safeList: (Array.isArray(list) ? list : [])

    // =========================================================
    // 2) Visibilidad: toggle y persistencia en Config
    // =========================================================
    function toggleVisible(visibility) {
        rootItem.visible = visibility

        // Proteger contra layouts inexistentes / índices fuera de rango
        const layouts = Config?.options?.bar?.layouts
        if (!layouts) return

        let arr = null
        if (rootItem.isLeft) arr = layouts.left
        else if (rootItem.isCenter) arr = layouts.center
        else if (rootItem.isRight) arr = layouts.right

        if (!arr || rootItem.originalIndex < 0 || rootItem.originalIndex >= arr.length) return
        if (!arr[rootItem.originalIndex]) return

        arr[rootItem.originalIndex].visible = visibility
    }

    // =========================================================
    // 3) Mapa de componentes por id (horizontal/vertical)
    // =========================================================
    // Nota: se mantiene el mismo mapping que tu archivo original.
    property var compMap: ({
        // [horizontal, vertical]
        "workspaces": [workspaceComp, workspaceComp],
        "music_player": [musicPlayerComp, musicPlayerCompVert],
        "system_monitor": [systemMonitorComp, systemMonitorCompVert],
        "clock": [clockComp, clockCompVert],
        "battery": [batteryComp, batteryCompVert],
        "utility_buttons": [utilityButtonsComp, utilityButtonsComp],
        "system_tray": [systemTrayComp, systemTrayComp],
        "active_window": [activeWindowComp, activeWindowComp],
        "date": [dateCompVert, dateCompVert],
        "record_indicator": [recordIndicatorComp, recordIndicatorComp],
        "screen_share_indicator": [screenshareIndicatorComp, screenshareIndicatorComp],
        "timer": [timerComp, timerCompVert],
        "weather": [weatherComp, weatherComp],
        "left_sidebar_button": [leftSidebarButtonComp, leftSidebarButtonComp],
        "right_sidebar_button": [rightSidebarButtonComp, rightSidebarButtonCompVert]
    })

    // =========================================================
    // 4) Radios: cálculo robusto (no rompe si list está vacía)
    // =========================================================
    function anyVisibleBefore(i) {
        // items "visibles" si visible !== false (igual que tu lógica)
        return rootItem.safeList.slice(0, i).some(item => item && item.visible !== false)
    }

    function anyVisibleAfter(i) {
        return rootItem.safeList.slice(i + 1).some(item => item && item.visible !== false)
    }

    property real startRadius: {
        // LEFT: el primero es full, lo demás verysmall
        if (rootItem.isLeft) {
            return (rootItem.originalIndex === 0)
                ? Appearance.rounding.full
                : Appearance.rounding.verysmall
        }

        // RIGHT: full si no hay visibles a la izquierda (dentro de ESTE grupo/list)
        if (rootItem.isRight) {
            return rootItem.anyVisibleBefore(rootItem.originalIndex)
                ? Appearance.rounding.verysmall
                : Appearance.rounding.full
        }

        // CENTER
        if (rootItem.safeList.length <= 1) return Appearance.rounding.full
        return rootItem.anyVisibleBefore(rootItem.originalIndex)
            ? Appearance.rounding.verysmall
            : Appearance.rounding.full
    }

    property real endRadius: {
        // RIGHT: el último es full, lo demás verysmall
        if (rootItem.isRight) {
            return (rootItem.originalIndex === rootItem.safeList.length - 1)
                ? Appearance.rounding.full
                : Appearance.rounding.verysmall
        }

        // LEFT: full si no hay visibles a la derecha
        if (rootItem.isLeft) {
            return rootItem.anyVisibleAfter(rootItem.originalIndex)
                ? Appearance.rounding.verysmall
                : Appearance.rounding.full
        }

        // CENTER
        if (rootItem.safeList.length <= 1) return Appearance.rounding.full
        return rootItem.anyVisibleAfter(rootItem.originalIndex)
            ? Appearance.rounding.verysmall
            : Appearance.rounding.full
    }

    // =========================================================
    // 5) UI: wrapper (BarGroup) + Loader del item real
    // =========================================================
    BarGroup {
        id: wrapper
        vertical: rootItem.vertical

        // FIX importante: antes era root.vertical (root no existe)
        anchors {
            verticalCenter: rootItem.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: rootItem.vertical ? undefined : rootItem.horizontalCenter
        }

        startRadius: rootItem.startRadius
        endRadius: rootItem.endRadius

        // Toma el color del item cargado si expone backgroundColor, sino fallback
        colBackground: itemLoader.item && itemLoader.item.backgroundColor !== undefined
            ? itemLoader.item.backgroundColor
            : Appearance.colors.colLayer2

        items: Loader {
            id: itemLoader
            active: true

            // Selección segura del componente:
            // - Si modelData/id no existe o no está en compMap, usa fallback.
            readonly property string itemId: (rootItem.modelData && rootItem.modelData.id) ? rootItem.modelData.id : ""
            readonly property var pair: rootItem.compMap[itemId]
            readonly property var chosen: (pair && pair.length >= 2) ? pair[rootItem.vertical ? 1 : 0] : null

            sourceComponent: chosen ? chosen : unknownComp
        }
    }

    // =========================================================
    // 6) Components: definiciones (ordenadas por categorías)
    // =========================================================

    // 6.1) Fallback seguro si llega un id desconocido
    Component {
        id: unknownComp
        Item {
            // Mantener tamaño neutro para no romper layout
            implicitWidth: 1
            implicitHeight: 1
        }
    }

    // 6.2) Widgets (manteniendo tus componentes exactos)
    Component { id: weatherComp; WeatherBar { vertical: rootItem.vertical } }

    Component { id: timerComp; TimerWidget {} }
    Component { id: timerCompVert; Vertical.VerticalTimerWidget {} }

    Component { id: screenshareIndicatorComp; ScreenShareIndicator {} }
    Component { id: recordIndicatorComp; RecordIndicator { vertical: rootItem.vertical } }

    Component { id: activeWindowComp; ActiveWindow { vertical: rootItem.vertical } }

    Component { id: systemMonitorComp; Resources {} }
    Component { id: systemMonitorCompVert; Vertical.Resources {} }

    Component { id: musicPlayerComp; Media {} }
    Component { id: musicPlayerCompVert; Vertical.VerticalMedia {} }

    Component { id: utilityButtonsComp; UtilButtons { vertical: rootItem.vertical } }

    Component { id: batteryComp; BatteryIndicator {} }
    Component { id: batteryCompVert; Vertical.BatteryIndicator {} }

    Component { id: clockComp; ClockWidget {} }
    Component { id: clockCompVert; Vertical.VerticalClockWidget {} }

    Component { id: systemTrayComp; SysTray { vertical: rootItem.vertical } }

    Component { id: dateCompVert; Vertical.VerticalDateWidget {} }

    Component { id: workspaceComp; Workspaces { vertical: rootItem.vertical } }

    Component { id: leftSidebarButtonComp; LeftSidebarButton {} }

    Component { id: rightSidebarButtonComp; RightSidebarButton {} }
    Component { id: rightSidebarButtonCompVert; VerticalRightSidebarButton {} }
}

