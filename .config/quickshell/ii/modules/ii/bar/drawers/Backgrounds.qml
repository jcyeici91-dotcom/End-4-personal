import qs
import qs.modules.common
import qs.modules.ii.onScreenDisplay.drawer as Osd
import qs.modules.ii.overview.drawer as SearchOverview
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    Osd.Background {
        wrapper: root.panels.osd

        startX: (root.width - root.panels.osd.width) / 2 - Appearance.rounding.drawingPanelRounding
        startY: DrawerVisibilityConfig.osdBackgroundStickToBar ? 1 : 0
    }

    SearchOverview.Background {
        wrapper: root.panels.searchOverview

        startX: (root.width - root.panels.searchOverview.width) / 2 - Appearance.rounding.drawingPanelRounding
        startY: DrawerVisibilityConfig.searchOverviewBackgroundStickToBar ? 1 : 0
    }
}
