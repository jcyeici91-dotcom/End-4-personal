# BAR MODULE KNOWLEDGE BASE

## OVERVIEW
The `bar` module provides the primary system panel(s). It supports horizontal (top/bottom) and vertical (left/right) orientations, reactive auto-hiding, and space reservation via Quickshell's `PanelWindow`.

## STRUCTURE
- **Core Layout**:
  - `Bar.qml`: The `PanelWindow` wrapper; handles position, keyboard focus, and exclusive zones.
  - `BarContent.qml`: Orchestrates widget groups using `RowLayout`/`ColumnLayout` and manages auto-hide animations.
  - `BarBg.qml` / `BarBgShadow.qml`: Aesthetic layers for the bar background.
- **Widgets & Components**:
  - `clock/`: Time, date, and weather integration.
  - `systray/`: SNI-based system tray implementation.
  - `workspaces/`: Hyprland workspace visualization and navigation.
  - `IntegratedDock.qml`: A taskbar-style dock that embeds directly into the bar layout.
  - **System Indicators**: Sliders and buttons for volume, brightness, battery, and power profiles.

## WHERE TO LOOK
- **Auto-hide Logic**: `BarContent.qml` (see `reveal` property and `hideDelayTimer`).
- **Space Reservation**: `Bar.qml` (`exclusiveZone` calculation).
- **Adding Widgets**: Update `horizontalLayout` or `verticalLayout` in `BarContent.qml`.
- **Integrated Dock**: `IntegratedDock.qml` for app switching logic within the bar.

## CONVENTIONS
- **Adaptive Styling**: Widgets use `startRadius` and `endRadius` to maintain "pill" continuity depending on their position in a group.
- **Visibility**: Panels must register with `Visibilities` in `Component.onCompleted` to sync with the Dashboard and other overlays.
- **Orientation**: Always handle both `horizontal` and `vertical` cases in UI components.
- **Config Binding**: Prefer `Config.bar.*` properties for all layout-related state.
