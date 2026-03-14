import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    Layout.fillHeight: true
    // MODIFICADO: Eliminado el cálculo con hyprlandGapsOut
    Layout.topMargin: 0 
    implicitWidth: implicitHeight - topInset - bottomInset
    buttonRadius: Appearance.rounding.normal

    background.implicitHeight: 50
}
