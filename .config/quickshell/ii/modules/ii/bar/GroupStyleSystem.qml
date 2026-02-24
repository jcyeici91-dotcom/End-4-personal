// GroupStyleSystem.qml
import QtQuick
import qs
import qs.modules.common 
import "." as Bar

QtObject {
    id: sys
    
    // El único cable ((screen, monitor)
    property Bar.BarState state

    // 1. LECTURA DE LA CONFIGURACIÓN (De la UI de la imagen)
   readonly property string currentStyle: Config?.options?.bar?.groupBackgroundStyle ?? "pills"

    readonly property bool isPills: currentStyle === "pills"
    readonly property bool isRect: currentStyle === "rect"
    readonly property bool isHybrid: currentStyle === "hybrid"
    readonly property bool isLine: currentStyle === "line"

    // 2. MÉTRICAS Y DISEÑO (Autonomía visual)
    // Animación exclusiva de Hybrid
    readonly property int hybridResizeMs: 85

    // espaciado cambie según el estilo elegido!
    readonly property int spacing: 4
    readonly property int padding: 6
    readonly property int edgeInset: 2
    
    // Margen lateral de la barra (Si es hybrid no hay margen, si no, toma el de la pantalla)
    readonly property int screenMargin: isHybrid ? 0 : Math.ceil(Appearance.rounding.screenRounding / 2)

       // 3. LÓGICA DE DATOS (El Modelo)
    property var fullModel: (Config?.options?.bar?.layouts?.center ?? [])
    property var leftList: []
    property var centerList: []
    property var rightList: []

    function recomputeCenterSplit() {
        const model = sys.fullModel
        if (!model || model.length === undefined) {
            sys.leftList = []
            sys.centerList = []
            sys.rightList = []
            return
        }
        const idx = model.findIndex(item => item && item.centered === true)
        if (idx === -1) {
            sys.leftList = []
            sys.centerList = model
            sys.rightList = []
            return
        }
        sys.leftList = model.slice(0, idx)
        sys.centerList = [model[idx]]
        sys.rightList = model.slice(idx + 1)
    }

    onFullModelChanged: recomputeCenterSplit()
    
    // Para asegurar el cálculo inicial
    Component.onCompleted: recomputeCenterSplit() 
}
