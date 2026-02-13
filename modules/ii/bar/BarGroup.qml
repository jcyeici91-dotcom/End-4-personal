import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // --- Configuración Visual ---
    property bool vertical: false
    property real padding: 6  // Un poco más de aire para que se vea elegante
    property real spacing: 6  // Espacio entre iconos
    
    // Color base 
    property color colBackground: Appearance.m3colors.m3surfaceContainerLow

    // Radios personalizables 
    property real startRadius: Appearance.rounding.normal
    property real endRadius: Appearance.rounding.normal

    // --- LÓGICA DE OCULTAMIENTO AUTOMÁTICO 
    // Detectamos si realmente hay contenido visible dentro
    readonly property bool hasContent: {
        if (gridLayout.children.length === 0) return false;
        // Verificamos si el layout tiene dimensiones reales (ignora items ocultos)
        return root.vertical ? gridLayout.implicitHeight > 0 : gridLayout.implicitWidth > 0;
    }

    // Si no hay contenido, colapsamos a 0 y ocultamos
    visible: hasContent
    implicitWidth: hasContent ? (root.vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + root.padding * 2)) : 0
    implicitHeight: hasContent ? (root.vertical ? (gridLayout.implicitHeight + root.padding * 2) : Appearance.sizes.baseBarHeight) : 0

    // Acceso directo a los hijos
    default property alias items: gridLayout.children

    // --- FONDO ESTILIZADO
    Rectangle {
        id: background
        visible: root.hasContent
        anchors.fill: parent
        // Pequeño margen para que la sombra o el borde no se corten
        anchors.topMargin: root.vertical ? 0 : 2
        anchors.bottomMargin: root.vertical ? 0 : 2
        anchors.leftMargin: root.vertical ? 2 : 0
        anchors.rightMargin: root.vertical ? 2 : 0

        // Color de fondo 
        color: Config.options?.bar.borderless ? "transparent" : root.colBackground

        // --- EL TOQUE 
               border.width: 1
        border.color: Config.options?.bar.borderless ? "transparent" : Qt.rgba(1, 1, 1, 0.08) // Sutil borde oscuro (o claro según tema)
        
        // Manejo avanzado de esquinas redondeadas
        topLeftRadius: root.startRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomRightRadius: root.endRadius

        // Suavizado 
        antialiasing: true

        // Animación suave si cambia el color (ej. cambio de tema)
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    // --- LAYOUT DE LOS WIDGETS ---
    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        
        // Centrado perfecto
        anchors.centerIn: parent
        
        // Espaciado controlado
        columnSpacing: root.vertical ? 0 : root.spacing
        rowSpacing: root.vertical ? root.spacing : 0
    }
}
