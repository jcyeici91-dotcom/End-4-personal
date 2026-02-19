import QtQuick

QtObject {
    function getEndpoint(config) { return ""; }
    function getHeaders(config) { return []; }
    function getBody(messages, model, tools) { return {}; }
    function parseResponse(response) { return ""; }
}
