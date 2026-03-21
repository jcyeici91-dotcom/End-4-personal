import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import Quickshell

Item {
    id: root

    property bool isBottom: false
    property bool themeIsDark: true
    property bool effectiveShowBorder: true
    property real borderOpacity: 0.1

    // Usamos OpacityMask para que el blur respete las esquinas redondeadas
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: 12 // Curvatura estilo iOS
        }
    }

    // 1. Imagen del wallpaper capturada y difuminada
    Image {
        id: wallpaperBg
        // Llama a la ruta de tu fondo de pantalla actual
        source: Config.options.background.wallpaperPath ? ("file://" + Config.options.background.wallpaperPath) : ""
        
        // Forzamos que la imagen cubra toda tu pantalla
        width: Quickshell.screens[0].width 
        height: Quickshell.screens[0].height 
        
        // Alineamos la imagen restándole la posición global del widget
        // Así los píxeles coinciden exactamente con lo que hay detrás
        x: -root.mapToItem(null, 0, 0).x
        y: -root.mapToItem(null, 0, 0).y
        
        fillMode: Image.PreserveAspectCrop
        
        layer.enabled: true
        layer.effect: GaussianBlur {
            radius: 35 // Fuerza del blur
            samples: 71
            transparentBorder: false
        }
    }

    // 2. Tinte translúcido estilo iOS (esmerilado)
    Rectangle {
        anchors.fill: parent
        color: root.themeIsDark ? Qt.rgba(0.08, 0.08, 0.08, 0.45) : Qt.rgba(0.95, 0.95, 0.95, 0.35)
        radius: 12
        border.width: 1
        border.color: root.themeIsDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.6)
    }

    // 3. La línea inferior/superior característica del modo "Line"
    Rectangle {
        width: parent.width
        height: 2
        anchors.bottom: root.isBottom ? undefined : parent.bottom
        anchors.top: root.isBottom ? parent.top : undefined
        color: root.themeIsDark ? Qt.rgba(1, 1, 1, root.borderOpacity * 2) : Qt.rgba(0, 0, 0, 0.20)
        visible: root.effectiveShowBorder
    }
}
