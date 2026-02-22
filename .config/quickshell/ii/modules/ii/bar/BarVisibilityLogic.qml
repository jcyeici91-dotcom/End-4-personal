import QtQuick

QtObject {
    id: v

    // Inputs
    property bool autoHide: true
    property int visibleChildrenCount: 0

    // Outputs
    readonly property bool hasContent: visibleChildrenCount > 0
    readonly property bool shouldBeVisible: autoHide ? hasContent : true
}
