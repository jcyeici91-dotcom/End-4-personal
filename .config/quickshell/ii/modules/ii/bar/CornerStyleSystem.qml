// CornerStyleSystem.qml
import QtQuick
import qs
import qs.modules.common 
import "." as Bar

Item {
    id: sys

    // estado global (screen, monitor, colores base)
    required property Bar.BarState state

     // 1. LECTURA DE LA CONFIGURACIÓN 
     readonly property int cornerStyleValue: Config?.options?.bar?.cornerStyle ?? 0

    readonly property bool isHug: cornerStyleValue === 0
    readonly property bool isFloat: cornerStyleValue === 1
    readonly property bool isRect: cornerStyleValue === 2

    // si estamos en Hybrid para los "bridges"
    readonly property bool isHybrid: (Config?.options?.bar?.groupBackgroundStyle ?? "rounded") === "hybrid"
    readonly property bool isBottom: Config?.options?.bar?.bottom ?? false

        // 2. MÉTRICAS Y DISEÑO
       // Bridges (Conectores para Hybrid + Hug/Float)
    readonly property bool bridgeEnabled: (
        isHybrid
        && (isHug || isFloat)
        && !state.allowFullBarBackgroundInHybrid // Depende de la lógica de fondo del estado
    )

    readonly property int seamOverlapPx: 3

    // para el estilo Float (para separarlo de los bordes)
    readonly property int bridgeOuterMargin: isFloat
        ? Math.max(0, Math.round(Appearance.sizes.hyprlandGapsOut ?? 0))
        : 0

    // Hug necesita un pequeño sangrado (bleed) para cubrir las uniones (seams)
    readonly property int bridgeExtraBleed: isHug ? seamOverlapPx : 0

    // El grosor de la banda conectora
    readonly property int bridgeBandPx: bridgeEnabled
        ? Math.max(4, Math.min(8, Math.round((Appearance.rounding.normal ?? 12) * 0.40)))
        : 0

    // Qué color debe "llenar el hueco"
    readonly property color bridgeColor: state.bgIsCrystal
        ? state.glassTint
        : Appearance.colors.colLayer0

       // Top bridge
    Item {
        z: -9
        visible: !isBottom && sys.bridgeEnabled
        clip: true
        layer.enabled: true
        layer.smooth: false

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: sys.bridgeOuterMargin - sys.bridgeExtraBleed
            rightMargin: sys.bridgeOuterMargin - sys.bridgeExtraBleed
        }

        height: Math.round(sys.bridgeBandPx + sys.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(sys.bridgeBandPx + sys.seamOverlapPx)
            antialiasing: false
            color: sys.bridgeColor
            radius: 0
        }
    }

    // Bottom bridge
    Item {
        z: -9
        visible: isBottom && sys.bridgeEnabled
        clip: true
        layer.enabled: true
        layer.smooth: false

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: sys.bridgeOuterMargin - sys.bridgeExtraBleed
            rightMargin: sys.bridgeOuterMargin - sys.bridgeExtraBleed
        }

        height: Math.round(sys.bridgeBandPx + sys.seamOverlapPx)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(sys.bridgeBandPx + sys.seamOverlapPx)
            antialiasing: false
            color: sys.bridgeColor
            radius: 0
        }
    }
}
