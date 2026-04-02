import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland
import "../ii/bar" as CustomBar

ContentPage {
    id: rootPage
    forceWidth: true

    QtObject {
        id: uiState
        property string activeColorProfile: "mango"
        property string inactiveColorProfile: "dark"
        property string shadowColorProfile: "classic"
        property string blurProfile: "balanced"
        property string animationProfile: "smooth"
    }

    HyprlandConfigOption { id: optRounding; key: "decoration:rounding" }
    HyprlandConfigOption { id: optRoundingPower; key: "decoration:rounding_power" }
    HyprlandConfigOption { id: optBorderSize; key: "general:border_size" }
    HyprlandConfigOption { id: optGapsIn; key: "general:gaps_in" }
    HyprlandConfigOption { id: optGapsOut; key: "general:gaps_out" }
    HyprlandConfigOption { id: optGapsWorkspace; key: "general:gaps_workspaces" }
    HyprlandConfigOption { id: optResizeOnBorder; key: "general:resize_on_border" }
    HyprlandConfigOption { id: optExtendBorder; key: "general:extend_border_grab_area" }
    HyprlandConfigOption { id: optHoverIcon; key: "general:hover_icon_on_border" }

    HyprlandConfigOption { id: optActiveOpacity; key: "decoration:active_opacity" }
    HyprlandConfigOption { id: optInactiveOpacity; key: "decoration:inactive_opacity" }
    HyprlandConfigOption { id: optFullscreenOpacity; key: "decoration:fullscreen_opacity" }
    HyprlandConfigOption { id: optDimInactive; key: "decoration:dim_inactive" }
    HyprlandConfigOption { id: optDimStrength; key: "decoration:dim_strength" }
    HyprlandConfigOption { id: optDimSpecial; key: "decoration:dim_special" }
    HyprlandConfigOption { id: optDimAround; key: "decoration:dim_around" }

    HyprlandConfigOption { id: optBlurEnabled; key: "decoration:blur:enabled" }
    HyprlandConfigOption { id: optBlurSize; key: "decoration:blur:size" }
    HyprlandConfigOption { id: optBlurPasses; key: "decoration:blur:passes" }
    HyprlandConfigOption { id: optBlurXray; key: "decoration:blur:xray" }
    HyprlandConfigOption { id: optBlurPopups; key: "decoration:blur:popups" }
    HyprlandConfigOption { id: optBlurPopupsIgnoreAlpha; key: "decoration:blur:popups_ignorealpha" }
    HyprlandConfigOption { id: optBlurNewOptimizations; key: "decoration:blur:new_optimizations" }
    HyprlandConfigOption { id: optBlurIgnoreOpacity; key: "decoration:blur:ignore_opacity" }
    HyprlandConfigOption { id: optBlurSpecial; key: "decoration:blur:special" }
    HyprlandConfigOption { id: optBlurVibrancy; key: "decoration:blur:vibrancy" }
    HyprlandConfigOption { id: optBlurContrast; key: "decoration:blur:contrast" }
    HyprlandConfigOption { id: optBlurNoise; key: "decoration:blur:noise" }
    HyprlandConfigOption { id: optBlurBrightness; key: "decoration:blur:brightness" }

    HyprlandConfigOption { id: optShadowEnabled; key: "decoration:shadow:enabled" }
    HyprlandConfigOption { id: optShadowRange; key: "decoration:shadow:range" }
    HyprlandConfigOption { id: optShadowPower; key: "decoration:shadow:render_power" }
    HyprlandConfigOption { id: optShadowIgnoreWindow; key: "decoration:shadow:ignore_window" }
    HyprlandConfigOption { id: optShadowScale; key: "decoration:shadow:scale" }

    HyprlandConfigOption { id: optAnimEnabled; key: "animations:enabled" }

    HyprlandConfigOption { id: optVFR; key: "misc:vfr" }
    HyprlandConfigOption { id: optVRR; key: "misc:vrr" }
    HyprlandConfigOption { id: optDpmsMouse; key: "misc:mouse_move_enables_dpms" }
    HyprlandConfigOption { id: optDpmsKey; key: "misc:key_press_enables_dpms" }
    HyprlandConfigOption { id: optNoLogo; key: "misc:disable_hyprland_logo" }
    HyprlandConfigOption { id: optFocusActivate; key: "misc:focus_on_activate" }
    HyprlandConfigOption { id: optMiddleClickPaste; key: "misc:middle_click_paste" }

    HyprlandConfigOption { id: optNaturalScroll; key: "input:touchpad:natural_scroll" }
    HyprlandConfigOption { id: optDisableTyping; key: "input:touchpad:disable_while_typing" }
    HyprlandConfigOption { id: optSensitivity; key: "input:sensitivity" }
    HyprlandConfigOption { id: optCursorTimeout; key: "cursor:inactive_timeout" }
    HyprlandConfigOption { id: optCursorHide; key: "cursor:hide_on_key_press" }

    // ⚙️ Motor de inyección restaurado desde tu configuración vieja
    Process {
        id: qsApplyCmd
    }

    function applySetting(hyprKey, val) {
        let strVal = String(val)
        
        // 1. Aplicación rápida en RAM para evitar lag visual
        Quickshell.execDetached(["hyprctl", "keyword", hyprKey, strVal])
        
        // 2. Guardado en archivo (Tu método original)
        qsApplyCmd.running = false 
        qsApplyCmd.command = ["bash", "/home/jcgomez91/.config/hypr/hyprland/scripts/qs_hypr_edit.sh", hyprKey, strVal]
        qsApplyCmd.running = true
        
        // 3. LA CLAVE: Actualizar la UI interna para que Dwindle responda visualmente
        try { Config.setNestedValue("hyprland." + hyprKey.replace(/:/g, "_"), val) } catch(e) {}
    }

    function applyBatch(pairs) {
        for (let i = 0; i < pairs.length; i++) {
            let key = pairs[i][0]
            let val = String(pairs[i][1])
            Quickshell.execDetached(["hyprctl", "keyword", key, val])
        }
    }

    function isTrue(val) {
        if (val === undefined || val === null) return false
        return String(val) === "true" || String(val) === "1"
    }

    function toHyprBool(checked) {
        return checked ? "1" : "0"
    }

    function applyActiveBorderProfile(profile) {
        uiState.activeColorProfile = profile
        let colorCode = "rgba(33ccffee) rgba(00ff99ee) rgba(d980faee) 45deg"

        if (profile === "mango")
            colorCode = "rgba(ffb347ff) rgba(ffcc33ff) rgba(ff8c42ff) 45deg"
        else if (profile === "neon")
            colorCode = "rgba(00f5ffff) rgba(00ff87ff) rgba(00c2ffff) 45deg"
        else if (profile === "ice")
            colorCode = "rgba(8fd3ffff) rgba(4facfeff) rgba(00c6ffff) 90deg"
        else if (profile === "dark")
            colorCode = "rgba(5c6370ff) rgba(2f3542ff) 90deg"
        else if (profile === "royal")
            colorCode = "rgba(7f5af0ff) rgba(2cb67dff) rgba(00d4ffff) 45deg"

        applySetting("general:col.active_border", colorCode)
    }

    function applyInactiveBorderProfile(profile) {
        uiState.inactiveColorProfile = profile
        let colorCode = "rgba(3a3f4bcc)"

        if (profile === "transparent")
            colorCode = "rgba(00000000)"
        else if (profile === "dark")
            colorCode = "rgba(2b2f3acc) rgba(454b5acc) 90deg"
        else if (profile === "ice")
            colorCode = "rgba(4facfe88) rgba(00c6ff66) 90deg"
        else if (profile === "smoke")
            colorCode = "rgba(7b879455) rgba(4b556366) 90deg"

        applySetting("general:col.inactive_border", colorCode)
    }

    function applyShadowProfile(profile) {
        uiState.shadowColorProfile = profile
        let colorCode = "rgba(00000044)"

        if (profile === "classic")
            colorCode = "rgba(00000055)"
        else if (profile === "soft")
            colorCode = "rgba(00000033)"
        else if (profile === "neon")
            colorCode = "rgba(00ff9970)"
        else if (profile === "violet")
            colorCode = "rgba(9d4edd66)"

        applySetting("decoration:shadow:color", colorCode)
    }

    function applyBlurProfile(profile) {
        uiState.blurProfile = profile

        if (profile === "balanced") {
            applyBatch([
                ["decoration:blur:enabled", "1"],
                ["decoration:blur:size", "10"],
                ["decoration:blur:passes", "3"],
                ["decoration:blur:vibrancy", "0.22"],
                ["decoration:blur:contrast", "0.95"],
                ["decoration:blur:brightness", "1.00"],
                ["decoration:blur:noise", "0.015"],
                ["decoration:blur:new_optimizations", "1"],
                ["decoration:blur:ignore_opacity", "0"],
                ["decoration:blur:special", "1"]
            ])
        } else if (profile === "crystal") {
            applyBatch([
                ["decoration:blur:enabled", "1"],
                ["decoration:blur:size", "14"],
                ["decoration:blur:passes", "4"],
                ["decoration:blur:vibrancy", "0.35"],
                ["decoration:blur:contrast", "1.08"],
                ["decoration:blur:brightness", "1.03"],
                ["decoration:blur:noise", "0.020"],
                ["decoration:blur:new_optimizations", "1"],
                ["decoration:blur:ignore_opacity", "0"],
                ["decoration:blur:special", "1"]
            ])
        } else if (profile === "frosted") {
            applyBatch([
                ["decoration:blur:enabled", "1"],
                ["decoration:blur:size", "18"],
                ["decoration:blur:passes", "5"],
                ["decoration:blur:vibrancy", "0.12"],
                ["decoration:blur:contrast", "0.90"],
                ["decoration:blur:brightness", "0.98"],
                ["decoration:blur:noise", "0.028"],
                ["decoration:blur:new_optimizations", "1"],
                ["decoration:blur:ignore_opacity", "0"],
                ["decoration:blur:special", "1"]
            ])
        }
    }

    function applyAnimationProfile(profile) {
        uiState.animationProfile = profile

        if (profile === "smooth") {
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windows,1,7,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windowsOut,1,7,default,popin 80%"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "border,1,8,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "fade,1,7,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "workspaces,1,7,default"])
        } else if (profile === "snappy") {
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windows,1,5,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windowsOut,1,5,default,popin 87%"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "border,1,6,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "fade,1,5,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "workspaces,1,6,default"])
        } else if (profile === "luxury") {
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windows,1,8,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "windowsOut,1,8,default,popin 78%"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "border,1,10,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "fade,1,8,default"])
            Quickshell.execDetached(["hyprctl", "keyword", "animation", "workspaces,1,8,default"])
        }
    }

   ContentSection {
        icon: "dashboard_customize"
        title: Translation.tr("Window Management")

        ContentSubsection {
            title: Translation.tr("Active Layout")

            CustomBar.LayoutSelector {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                Layout.bottomMargin: 15
                orientation: "horizontal"
                
                activeLayout: Config.options.hyprland?.general_layout ?? "dwindle"
                applyToHyprland: false 
                
                onLayoutSelected: layout => {
                    applySetting("general:layout", layout)
                }
            }
        }
        

        ConfigSwitch {
            buttonIcon: "open_with"
            text: Translation.tr("Resize Windows by Dragging Borders")
            checked: isTrue(optResizeOnBorder.value)
            onCheckedChanged: applySetting("general:resize_on_border", toHyprBool(checked))
        }

        ConfigSpinBox {
            icon: "zoom_out_map"
            text: Translation.tr("Border Grab Area (Pixels)")
            value: Number(optExtendBorder.value || 15)
            from: 0; to: 50; stepSize: 5
            onValueChanged: applySetting("general:extend_border_grab_area", value)
        }

        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Show Hover Icon on Border")
            checked: isTrue(optHoverIcon.value)
            onCheckedChanged: applySetting("general:hover_icon_on_border", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "animation"
            text: Translation.tr("Master Animation Switch")
            checked: isTrue(optAnimEnabled.value)
            onCheckedChanged: applySetting("animations:enabled", toHyprBool(checked))
        }

        ContentSubsection {
            title: Translation.tr("Animation Profile")
            ConfigSelectionArray {
                currentValue: uiState.animationProfile
                onSelected: newValue => applyAnimationProfile(newValue)
                options: [
                    { displayName: "Smooth", value: "smooth", icon: "animation" },
                    { displayName: "Snappy", value: "snappy", icon: "bolt" },
                    { displayName: "Luxury", value: "luxury", icon: "auto_awesome" }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Focus Window on Activate")
            checked: isTrue(optFocusActivate.value)
            onCheckedChanged: applySetting("misc:focus_on_activate", toHyprBool(checked))
        }
    }

    ContentSection {
        icon: "border_style"
        title: Translation.tr("2. Borders & Shapes")

        ContentSubsection {
            title: Translation.tr("Active Border Color Profile")
            ConfigSelectionArray {
                currentValue: uiState.activeColorProfile
                onSelected: newValue => applyActiveBorderProfile(newValue)
                options: [
                    { displayName: "Mango", value: "mango", icon: "palette" },
                    { displayName: "Neon", value: "neon", icon: "flare" },
                    { displayName: "Ice", value: "ice", icon: "ac_unit" },
                    { displayName: "Dark", value: "dark", icon: "dark_mode" },
                    { displayName: "Royal", value: "royal", icon: "diamond" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Inactive Border Color Profile")
            ConfigSelectionArray {
                currentValue: uiState.inactiveColorProfile
                onSelected: newValue => applyInactiveBorderProfile(newValue)
                options: [
                    { displayName: "Transparent", value: "transparent", icon: "opacity" },
                    { displayName: "Dark Gray", value: "dark", icon: "dark_mode" },
                    { displayName: "Dim Ice", value: "ice", icon: "ac_unit" },
                    { displayName: "Smoke", value: "smoke", icon: "blur_on" }
                ]
            }
        }

        ConfigSpinBox {
            icon: "border_outer"
            text: Translation.tr("Border Thickness")
            value: Number(optBorderSize.value || 4)
            from: 0; to: 12; stepSize: 1
            onValueChanged: applySetting("general:border_size", value)
        }

        ConfigSpinBox {
            icon: "rounded_corner"
            text: Translation.tr("Corner Rounding (Radius)")
            value: Number(optRounding.value || 18)
            from: 0; to: 60; stepSize: 1
            onValueChanged: applySetting("decoration:rounding", value)
        }

        ConfigSpinBox {
            icon: "shape_line"
            text: Translation.tr("Rounding Power (Reduces Ghost Corners)")
            value: Math.round(Number(optRoundingPower.value || 2.4) * 10)
            from: 20; to: 60; stepSize: 1
            onValueChanged: applySetting("decoration:rounding_power", (value / 10.0).toFixed(1))
        }
    }

    ContentSection {
        icon: "aspect_ratio"
        title: Translation.tr("3. Spacing & Gaps")

        ConfigSpinBox {
            icon: "padding"
            text: Translation.tr("Gaps In (Inner Window Spacing)")
            value: Number(optGapsIn.value || 4)
            from: 0; to: 50; stepSize: 1
            onValueChanged: applySetting("general:gaps_in", value)
        }

        ConfigSpinBox {
            icon: "crop_free"
            text: Translation.tr("Gaps Out (Outer Screen Spacing)")
            value: Number(optGapsOut.value || 5)
            from: 0; to: 100; stepSize: 1
            onValueChanged: applySetting("general:gaps_out", value)
        }

        ConfigSpinBox {
            icon: "view_carousel"
            text: Translation.tr("Workspace Gaps")
            value: Number(optGapsWorkspace.value || 50)
            from: 0; to: 300; stepSize: 10
            onValueChanged: applySetting("general:gaps_workspaces", value)
        }
    }

    ContentSection {
        icon: "lens_blur"
        title: Translation.tr("4. Glass Effect & Blur")

        ContentSubsection {
            title: Translation.tr("Blur Preset")
            ConfigSelectionArray {
                currentValue: uiState.blurProfile
                onSelected: newValue => applyBlurProfile(newValue)
                options: [
                    { displayName: "Balanced", value: "balanced", icon: "blur_on" },
                    { displayName: "Crystal", value: "crystal", icon: "diamond" },
                    { displayName: "Frosted", value: "frosted", icon: "ac_unit" }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr("Master Blur Switch")
            checked: isTrue(optBlurEnabled.value)
            onCheckedChanged: applySetting("decoration:blur:enabled", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "layers_clear"
            text: Translation.tr("XRay Mode")
            checked: isTrue(optBlurXray.value)
            onCheckedChanged: applySetting("decoration:blur:xray", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "picture_in_picture_alt"
            text: Translation.tr("Blur Popups & Menus")
            checked: isTrue(optBlurPopups.value)
            onCheckedChanged: applySetting("decoration:blur:popups", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "opacity"
            text: Translation.tr("Ignore Popup Alpha")
            checked: isTrue(optBlurPopupsIgnoreAlpha.value)
            onCheckedChanged: applySetting("decoration:blur:popups_ignorealpha", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Enable New Blur Optimizations")
            checked: isTrue(optBlurNewOptimizations.value)
            onCheckedChanged: applySetting("decoration:blur:new_optimizations", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "layers"
            text: Translation.tr("Ignore Window Opacity for Blur")
            checked: isTrue(optBlurIgnoreOpacity.value)
            onCheckedChanged: applySetting("decoration:blur:ignore_opacity", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "auto_awesome_motion"
            text: Translation.tr("Blur on Special Workspaces")
            checked: isTrue(optBlurSpecial.value)
            onCheckedChanged: applySetting("decoration:blur:special", toHyprBool(checked))
        }

        ConfigSpinBox {
            icon: "blur_circular"
            text: Translation.tr("Blur Size (Spread)")
            value: Number(optBlurSize.value || 10)
            from: 1; to: 30; stepSize: 1
            onValueChanged: applySetting("decoration:blur:size", value)
        }

        ConfigSpinBox {
            icon: "filter_none"
            text: Translation.tr("Blur Passes (Smoothness)")
            value: Number(optBlurPasses.value || 3)
            from: 1; to: 8; stepSize: 1
            onValueChanged: applySetting("decoration:blur:passes", value)
        }

        ConfigSpinBox {
            icon: "auto_awesome"
            text: Translation.tr("Glass Vibrancy (Color Pop)")
            value: Math.round(Number(optBlurVibrancy.value || 0.22) * 100)
            from: 0; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:blur:vibrancy", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "contrast"
            text: Translation.tr("Glass Contrast")
            value: Math.round(Number(optBlurContrast.value || 0.95) * 100)
            from: 50; to: 200; stepSize: 5
            onValueChanged: applySetting("decoration:blur:contrast", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "brightness_medium"
            text: Translation.tr("Blur Brightness")
            value: Math.round(Number(optBlurBrightness.value || 1.0) * 100)
            from: 50; to: 200; stepSize: 5
            onValueChanged: applySetting("decoration:blur:brightness", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "grain"
            text: Translation.tr("Glass Noise (Grain Effect)")
            value: Math.round(Number(optBlurNoise.value || 0.015) * 1000)
            from: 0; to: 200; stepSize: 5
            onValueChanged: applySetting("decoration:blur:noise", (value / 1000.0).toFixed(3))
        }
    }

    ContentSection {
        icon: "opacity"
        title: Translation.tr("5. Transparency & Dimming")

        ConfigSpinBox {
            icon: "highlight"
            text: Translation.tr("Active Window Opacity")
            value: Math.round(Number(optActiveOpacity.value || 1.0) * 100)
            from: 10; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:active_opacity", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "filter_b_and_w"
            text: Translation.tr("Inactive Window Opacity")
            value: Math.round(Number(optInactiveOpacity.value || 0.90) * 100)
            from: 10; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:inactive_opacity", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "fullscreen"
            text: Translation.tr("Fullscreen Window Opacity")
            value: Math.round(Number(optFullscreenOpacity.value || 1.0) * 100)
            from: 10; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:fullscreen_opacity", (value / 100.0).toFixed(2))
        }

        ConfigSwitch {
            buttonIcon: "brightness_3"
            text: Translation.tr("Dim Inactive Windows")
            checked: isTrue(optDimInactive.value)
            onCheckedChanged: applySetting("decoration:dim_inactive", toHyprBool(checked))
        }

        ConfigSpinBox {
            icon: "tonality"
            text: Translation.tr("Inactive Dim Strength")
            value: Math.round(Number(optDimStrength.value || 0.08) * 100)
            from: 0; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:dim_strength", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "wb_twilight"
            text: Translation.tr("Special Workspace Dim Strength")
            value: Math.round(Number(optDimSpecial.value || 0.20) * 100)
            from: 0; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:dim_special", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "filter_center_focus"
            text: Translation.tr("Dim Around Strength (Popups)")
            value: Math.round(Number(optDimAround.value || 0.40) * 100)
            from: 0; to: 100; stepSize: 5
            onValueChanged: applySetting("decoration:dim_around", (value / 100.0).toFixed(2))
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("6. Drop Shadows")

        ConfigSwitch {
            buttonIcon: "shadow"
            text: Translation.tr("Enable Window Shadows")
            checked: isTrue(optShadowEnabled.value)
            onCheckedChanged: applySetting("decoration:shadow:enabled", toHyprBool(checked))
        }

        ConfigSpinBox {
            icon: "expand"
            text: Translation.tr("Shadow Range (Spread)")
            value: Number(optShadowRange.value || 50)
            from: 0; to: 200; stepSize: 5
            onValueChanged: applySetting("decoration:shadow:range", value)
        }

        ConfigSpinBox {
            icon: "contrast"
            text: Translation.tr("Shadow Render Power (Falloff)")
            value: Number(optShadowPower.value || 3)
            from: 1; to: 4; stepSize: 1
            onValueChanged: applySetting("decoration:shadow:render_power", value)
        }

        ConfigSpinBox {
            icon: "zoom_out"
            text: Translation.tr("Shadow Scale")
            value: Math.round(Number(optShadowScale.value || 1.0) * 100)
            from: 50; to: 200; stepSize: 5
            onValueChanged: applySetting("decoration:shadow:scale", (value / 100.0).toFixed(2))
        }

        ConfigSwitch {
            buttonIcon: "block"
            text: Translation.tr("Ignore Window Shape for Shadow")
            checked: isTrue(optShadowIgnoreWindow.value)
            onCheckedChanged: applySetting("decoration:shadow:ignore_window", toHyprBool(checked))
        }

        ContentSubsection {
            title: Translation.tr("Shadow Color Profile")
            ConfigSelectionArray {
                currentValue: uiState.shadowColorProfile
                onSelected: newValue => applyShadowProfile(newValue)
                options: [
                    { displayName: "Classic", value: "classic", icon: "dark_mode" },
                    { displayName: "Soft", value: "soft", icon: "cloud_queue" },
                    { displayName: "Neon", value: "neon", icon: "flare" },
                    { displayName: "Violet", value: "violet", icon: "filter_vintage" }
                ]
            }
        }
    }

    ContentSection {
        icon: "mouse"
        title: Translation.tr("7. Input Devices")

        ConfigSwitch {
            buttonIcon: "touchpad_mouse"
            text: Translation.tr("Touchpad Natural Scrolling")
            checked: isTrue(optNaturalScroll.value)
            onCheckedChanged: applySetting("input:touchpad:natural_scroll", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "keyboard"
            text: Translation.tr("Disable Touchpad While Typing")
            checked: isTrue(optDisableTyping.value)
            onCheckedChanged: applySetting("input:touchpad:disable_while_typing", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "mouse"
            text: Translation.tr("Middle Click Paste")
            checked: isTrue(optMiddleClickPaste.value)
            onCheckedChanged: applySetting("misc:middle_click_paste", toHyprBool(checked))
        }

        ConfigSpinBox {
            icon: "speed"
            text: Translation.tr("Mouse Sensitivity")
            value: Math.round(Number(optSensitivity.value || 0) * 100)
            from: -100; to: 100; stepSize: 5
            onValueChanged: applySetting("input:sensitivity", (value / 100.0).toFixed(2))
        }

        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Cursor Inactive Timeout (Seconds)")
            value: Number(optCursorTimeout.value || 0)
            from: 0; to: 60; stepSize: 1
            onValueChanged: applySetting("cursor:inactive_timeout", value)
        }

        ConfigSwitch {
            buttonIcon: "visibility_off"
            text: Translation.tr("Hide Cursor on Key Press")
            checked: isTrue(optCursorHide.value)
            onCheckedChanged: applySetting("cursor:hide_on_key_press", toHyprBool(checked))
        }
    }

    ContentSection {
        icon: "power"
        title: Translation.tr("8. Power & Display")

        ConfigSwitch {
            buttonIcon: "battery_charging_full"
            text: Translation.tr("Variable Frame Rate (VFR)")
            checked: isTrue(optVFR.value)
            onCheckedChanged: applySetting("misc:vfr", toHyprBool(checked))
        }

        ContentSubsection {
            title: Translation.tr("Variable Refresh Rate (VRR / FreeSync)")
            ConfigSelectionArray {
                currentValue: optVRR.value ?? "0"
                onSelected: newValue => applySetting("misc:vrr", newValue)
                options: [
                    { displayName: "Off", value: "0", icon: "cancel" },
                    { displayName: "Always On", value: "1", icon: "check_circle" },
                    { displayName: "Fullscreen Only", value: "2", icon: "fullscreen" }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "mouse"
            text: Translation.tr("Mouse Move Wakes Display")
            checked: isTrue(optDpmsMouse.value)
            onCheckedChanged: applySetting("misc:mouse_move_enables_dpms", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "keyboard"
            text: Translation.tr("Key Press Wakes Display")
            checked: isTrue(optDpmsKey.value)
            onCheckedChanged: applySetting("misc:key_press_enables_dpms", toHyprBool(checked))
        }

        ConfigSwitch {
            buttonIcon: "visibility_off"
            text: Translation.tr("Disable Hyprland Mascot Logo")
            checked: isTrue(optNoLogo.value)
            onCheckedChanged: applySetting("misc:disable_hyprland_logo", toHyprBool(checked))
        }

        ContentSubsection {
            title: Translation.tr("Auto-Suspend / Lock")

            ConfigSwitch {
                buttonIcon: "bedtime"
                text: Translation.tr("Enable Automatic Suspend")
                checked: Config.options.battery?.automaticSuspend ?? true
                onCheckedChanged: Config.setNestedValue("battery.automaticSuspend", checked)
            }

            ConfigSpinBox {
                icon: "timer"
                text: Translation.tr("Suspend Timeout (Minutes)")
                value: Config.options.battery?.suspend ?? 3
                from: 1; to: 60; stepSize: 1
                onValueChanged: Config.setNestedValue("battery.suspend", value)
            }
        }
    }
}
