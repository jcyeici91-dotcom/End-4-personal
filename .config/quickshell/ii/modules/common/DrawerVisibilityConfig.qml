pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    property bool barOsdVisible: Config.options.appearance.panelAnimation.enableBackgroundAnimation &&
                                !GlobalStates.screenLocked &&
                                !Config.options.bar.bottom &&
                                !Config.options.bar.vertical
    property bool fullScreenOsdVisible: !barOsdVisible || !GlobalStates.barOpen //GlobalStates.screenLocked
    property bool barSearchOverviewVisible: Config.options.appearance.panelAnimation.enableBackgroundAnimation &&
                                !GlobalStates.screenLocked &&
                                !Config.options.bar.bottom &&
                                !Config.options.bar.vertical
    property bool fullScreenSearchOverviewVisible: !barSearchOverviewVisible || !GlobalStates.barOpen //GlobalStates.screenLocked
    property bool osdStrokeVisible: Config.options.bar.cornerStyle === 1 &&
                                        (Config.options.bar.bottom ||
                                        Config.options.bar.vertical ||
                                        !Config.options.appearance.transparency.enable)
    property bool osdBackgroundStickToBar: Config.options.appearance.transparency.enable && !Config.options.bar.bottom && !Config.options.bar.vertical
    property bool searchOverviewBackgroundStickToBar: Config.options.appearance.transparency.enable && !Config.options.bar.bottom && !Config.options.bar.vertical
}