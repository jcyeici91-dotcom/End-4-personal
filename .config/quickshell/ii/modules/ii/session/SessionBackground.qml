import QtQuick
import QtQuick.Shapes
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string attachEdge: "right"
    property real rounding: Appearance.rounding.windowRounding ?? 18
    property real borderWidth: 1

    property real r: rounding

    // Esto hace que el panel "sangre" fuera del borde para evitar huecos
    property real edgeBleed: 2

    Shape {
        id: bgShape

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        // extendemos el shape hacia afuera
        width: parent.width + root.edgeBleed

        preferredRendererType: Shape.CurveRenderer

        antialiasing: true

        layer.enabled: true
        layer.samples: 8

        property real w: width
        property real h: height
        property real r: root.r

        ShapePath {
            fillColor: Appearance.colors.colLayer0
            strokeColor: "transparent"

            startX: bgShape.w
            startY: 0

            // curva cóncava superior derecha
            PathCubic {
                x: bgShape.w - bgShape.r
                y: bgShape.r
                control1X: bgShape.w
                control1Y: bgShape.r * 0.55
                control2X: bgShape.w - bgShape.r * 0.45
                control2Y: bgShape.r
            }

            // borde superior
            PathLine { x: bgShape.r; y: bgShape.r }

            // esquina superior izquierda
            PathCubic {
                x: 0
                y: 2 * bgShape.r
                control1X: bgShape.r * 0.45
                control1Y: bgShape.r
                control2X: 0
                control2Y: bgShape.r * 1.55
            }

            // lado izquierdo
            PathLine { x: 0; y: bgShape.h - 2 * bgShape.r }

            // esquina inferior izquierda
            PathCubic {
                x: bgShape.r
                y: bgShape.h - bgShape.r
                control1X: 0
                control1Y: bgShape.h - bgShape.r * 1.55
                control2X: bgShape.r * 0.45
                control2Y: bgShape.h - bgShape.r
            }

            // borde inferior
            PathLine { x: bgShape.w - bgShape.r; y: bgShape.h - bgShape.r }

            // curva cóncava inferior derecha
            PathCubic {
                x: bgShape.w
                y: bgShape.h
                control1X: bgShape.w - bgShape.r * 0.65
                control1Y: bgShape.h - bgShape.r
                control2X: bgShape.w
                control2Y: bgShape.h - bgShape.r * 0.65
            }

            PathLine { x: bgShape.w; y: 0 }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Appearance.colors.colLayer0Border
            strokeWidth: root.borderWidth

            startX: bgShape.w
            startY: 0

            PathCubic {
                x: bgShape.w - bgShape.r
                y: bgShape.r
                control1X: bgShape.w
                control1Y: bgShape.r * 0.55
                control2X: bgShape.w - bgShape.r * 0.45
                control2Y: bgShape.r
            }

            PathLine { x: bgShape.r; y: bgShape.r }

            PathCubic {
                x: 0
                y: 2 * bgShape.r
                control1X: bgShape.r * 0.45
                control1Y: bgShape.r
                control2X: 0
                control2Y: bgShape.r * 1.55
            }

            PathLine { x: 0; y: bgShape.h - 2 * bgShape.r }

            PathCubic {
                x: bgShape.r
                y: bgShape.h - bgShape.r
                control1X: 0
                control1Y: bgShape.h - bgShape.r * 1.55
                control2X: bgShape.r * 0.45
                control2Y: bgShape.h - bgShape.r
            }

            PathLine { x: bgShape.w - bgShape.r; y: bgShape.h - bgShape.r }

            PathCubic {
                x: bgShape.w
                y: bgShape.h
                control1X: bgShape.w - bgShape.r * 0.45
                control1Y: bgShape.h - bgShape.r
                control2X: bgShape.w
                control2Y: bgShape.h - bgShape.r * 0.55
            }
        }
    }
}
