import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Io

import qs.modules.ii.ui 1.0

import "." as Bar
import "parts" as Parts
import "utils/centerSplit.js" as CenterSplit

Item {
    id: root

    property var screen: root.QsWindow?.window?.screen ?? null
    property int monitorIndex: -1

    property var brightnessMonitor: null
    function recomputeBrightnessMonitor() {
        root.brightnessMonitor = Brightness.getMonitorForScreen(root.screen)
    }

    Parts.BarAdaptiveWindows {
        id: adaptiveWindows
        screen: root.screen
        monitorIndex: root.monitorIndex
        enabled: style.bgIsAdaptive
    }

    property bool hasActiveWindows: adaptiveWindows.hasActiveWindows

    Parts.BarStyle {
        id: style
        hasActiveWindows: root.hasActiveWindows
        screen: root.screen
    }

    // Re-export (para compatibilidad)
    readonly property bool followGlobalBarStyle: style.followGlobalBarStyle
    readonly property int barBackgroundStyleFromConfig: style.barBackgroundStyleFromConfig
    readonly property string resolvedStyle: style.resolvedStyle

    readonly property bool bgIsGlass: style.bgIsGlass
    readonly property bool bgIsSolid: style.bgIsSolid
    readonly property bool bgIsAdaptive: style.bgIsAdaptive
    readonly property bool bgIsCrystal: style.bgIsCrystal

    readonly property bool showSolidBackground: style.showSolidBackground
    readonly property bool useGlassMode: style.useGlassMode
    readonly property bool useOverlayBg: style.useOverlayBg

    readonly property bool useHybridGroups: style.useHybridGroups
    readonly property int cornerStyle: style.cornerStyle
    readonly property bool isBottom: style.isBottom

    readonly property bool allowFullBarBackgroundInHybrid: style.allowFullBarBackgroundInHybrid
    readonly property bool shouldDrawBackground: style.shouldDrawBackground

    readonly property int hybridResizeMs: style.hybridResizeMs

    readonly property bool themeIsDark: style.themeIsDark
    readonly property color glassTint: style.glassTint
    readonly property color glassRim: style.glassRim
    readonly property color glassRimInner: style.glassRimInner

    readonly property color barBgColor: style.barBgColor

    readonly property color onBarStrong: style.onBarStrong
    readonly property color onBar: style.onBar
    readonly property color onBarMuted: style.onBarMuted
    readonly property color onBarIcon: style.onBarIcon

    readonly property color chipBg: style.chipBg
    readonly property color chipBorder: style.chipBorder

    property real useShortenedForm: style.useShortenedForm
    readonly property int centerSideModuleWidth: style.centerSideModuleWidth

    // Split center -> JS
    property var fullModel: (Config?.options?.bar?.layouts?.center ?? [])
    property var leftList: []
    property var centerList: []
    property var rightList: []

    function recomputeCenterSplit() {
        const res = CenterSplit.split(root.fullModel)
        root.leftList = res.leftList
        root.centerList = res.centerList
        root.rightList = res.rightList
    }
    onFullModelChanged: recomputeCenterSplit()

    Parts.BarBackground {
        id: background
        shouldDrawBackground: root.shouldDrawBackground
        useOverlayBg: root.useOverlayBg
        showSolidBackground: root.showSolidBackground
        useGlassMode: root.useGlassMode
        bgIsCrystal: root.bgIsCrystal
        themeIsDark: root.themeIsDark
        glassTint: root.glassTint
        glassRim: root.glassRim
        glassRimInner: root.glassRimInner
    }

    Parts.BarBridges {
        useHybridGroups: root.useHybridGroups
        cornerStyle: root.cornerStyle
        allowFullBarBackgroundInHybrid: root.allowFullBarBackgroundInHybrid
        isBottom: root.isBottom
        bgIsCrystal: root.bgIsCrystal
        glassTint: root.glassTint
    }

    // === Secciones ===
    Parts.BarLeftSection {
        id: leftSection
        useHybridGroups: root.useHybridGroups
        hybridResizeMs: root.hybridResizeMs
        anchors.left: parent.left
    }

    Parts.BarCenterSection {
        id: middleSection
        useHybridGroups: root.useHybridGroups
        hybridResizeMs: root.hybridResizeMs
        leftList: root.leftList
        centerList: root.centerList
        rightList: root.rightList
    }

    Parts.BarRightSection {
        id: rightSection
        useHybridGroups: root.useHybridGroups
        hybridResizeMs: root.hybridResizeMs
        anchors.right: parent.right
    }

    // Mouse areas 
    Parts.BarSideMouseAreas {
        brightnessMonitor: root.brightnessMonitor
        middleSection: middleSection
    }

    Component.onCompleted: {
        recomputeBrightnessMonitor()
        recomputeCenterSplit()
        adaptiveWindows.kick()
    }

    onScreenChanged: {
        recomputeBrightnessMonitor()
        adaptiveWindows.kick()
    }
}

