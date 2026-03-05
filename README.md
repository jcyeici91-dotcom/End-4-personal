Credits to: @vynx: This repository contains personal settings: 1- Glass bar effect and others, copy the folder /.config/quickshell/ii/modules/ii/ui and add it to the same location, then copy the two files I) BarBgOverlayGlassBlur.qml II) BarBgCrystalOverlay.qml and leave them in /.config/quickshell/ii/modules/ii/bar/ 
How this works: BarBgOverlayGlassBlur.qml
What it does: It's an iOS-style blur effect.
It uses MultiEffect to blur what's behind it and a ShaderEffect to add noise (grain).
BarBgCrystalOverlay.qml:
What it does: It's a glass effect with physical properties.
Technique: It has complex gradients to simulate beveling and iridescence.
UIState.qml (The Brain):
It decides which of the two above should be displayed based on the surfaceStyle property.

