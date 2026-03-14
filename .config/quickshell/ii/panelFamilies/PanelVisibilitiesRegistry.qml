pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

// Creates one shared visibility object per screen and registers it with Visibilities,
// so both Bar and Drawers use the same instance (fixes OSD not toggling when fullscreen).
Variants {
    model: Quickshell.screens

    PersistentProperties {
        required property ShellScreen modelData

        property bool osd: false
        property bool searchOverview: false

        Component.onCompleted: Visibilities.load(modelData, this)
    }
}
