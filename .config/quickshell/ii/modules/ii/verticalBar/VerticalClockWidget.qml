pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: clockColumn.implicitHeight + 10
    implicitWidth: Appearance.sizes.verticalBarWidth

    ColumnLayout {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: DateTime.time.split(/[: ]/)

            delegate: StyledText {
                required property string modelData

                Layout.alignment: Qt.AlignHCenter

                font.pixelSize: modelData.match(/am|pm/i)
                    ? Appearance.font.pixelSize.smaller
                    : Appearance.font.pixelSize.large

                color: Appearance.colors.colOnLayer1

                text: modelData.padStart(2, "0")
            }
        }
    }
}
