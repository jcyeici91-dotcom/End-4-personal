import QtQuick
import QtQuick.Shapes
import qs.modules.common

ShapePath {
    id: root

    required property Item wrapper
    readonly property real rounding: Appearance.rounding.drawingPanelRounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    fillColor: Appearance.colors.colLayer0
    strokeWidth: DrawerVisibilityConfig.osdStrokeVisible ? 1.2 : -1
    strokeColor: wrapper.visible ? Appearance.colors.colLayer0Border : "transparent"

    // The startX and startY are set by the parent Shape component
    // startX is at the left edge minus rounding, startY is at the top
    // The path starts with the top-left arc

    // Top-left corner arc
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }

    // Left edge (moving down)
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }

    // Bottom-left corner arc
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }

    // Bottom edge (moving right)
    PathLine {
        relativeX: root.wrapper.width - root.rounding * 2
        relativeY: 0
    }

    // Bottom-right corner arc
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }

    // Right edge (moving up) - closes the path back to start
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }

    // Top-right corner arc (back to start)
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
        }
    }
}
