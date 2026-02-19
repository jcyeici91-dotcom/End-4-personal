import QtQuick

QtObject {
    required property string name
    property string icon: ""
    property string description: ""
    required property string endpoint
    required property string model
    property bool requires_key: false
    property string key_id: ""
    property string key_get_link: ""
    property string key_get_description: ""
    required property string api_format
}
