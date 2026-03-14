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
        startY: root.panels.osd.height > 0 ? 0.3 : -1
    }

    SearchOverview.Background {
        wrapper: root.panels.searchOverview

        startX: (root.width - root.panels.searchOverview.width) / 2 - Appearance.rounding.drawingPanelRounding
        startY: root.panels.searchOverview.height > 0 ? 0.3 : -1
    }
}
