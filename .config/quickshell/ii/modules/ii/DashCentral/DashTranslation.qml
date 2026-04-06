pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "translator"

Item {
    id: root

    property string targetLanguage: Config.options.language.translator.targetLanguage || "es"
    property string sourceLanguage: Config.options.language.translator.sourceLanguage || "auto"
    
    property string translatedText: ""
    property list<string> languages: []
    property bool isTranslating: false

    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false

    function showLanguageSelectorDialog(isTargetLang) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true;
    }

      Timer {
        id: translateTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (inputText.text.trim().length > 0) {
                root.isTranslating = true;
                translateProc.running = false;
                translateProc.buffer = ""; 
                translateProc.running = true; 
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi`
            + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(inputText.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser { onRead: data => { translateProc.buffer += data + "\n"; } }
        onExited: (exitCode, exitStatus) => {
            root.translatedText = translateProc.buffer.trim();
            root.isTranslating = false;
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser { onRead: data => { getLanguagesProc.bufferList.push(data.trim()); } }
        onExited: (exitCode, exitStatus) => {
            let langs = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0 && lang !== "auto")
                .sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = [];
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        Rectangle {
            Layout.fillHeight: true; Layout.fillWidth: true
            color: Appearance.colors.colLayer1 || "#1e1e2e"
            radius: Appearance.rounding.large || 20

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16

                   RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    MaterialSymbol { text: "translate"; iconSize: 24; color: Appearance.colors.colPrimary || "#cba6f7" }
                    StyledText { text: "Texto Original"; font.pixelSize: 18; font.weight: Font.Bold; color: "white" }
                    
                    Item { Layout.fillWidth: true } 
                    
                    LanguageSelectorButton {
                        displayText: root.sourceLanguage
                        implicitHeight: 36
                        onClicked: root.showLanguageSelectorDialog(false)
                    }
                }

                   TextCanvas {
                    id: inputCanvas
                    Layout.fillWidth: true; Layout.fillHeight: true
                    isInput: true
                    placeholderText: "Escribe o pega el texto aquí..."
                    
                    property var inputField: inputCanvas.inputTextArea
                    onInputTextChanged: translateTimer.restart()

                     GroupButton {
                        baseWidth: height; buttonRadius: Appearance.rounding.small
                        onClicked: { inputCanvas.inputTextArea.text = Quickshell.clipboardText; }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: 16; text: "content_paste"; color: Appearance.colors.colOnLayer1 }
                    }
                    GroupButton {
                        baseWidth: height; buttonRadius: Appearance.rounding.small
                        enabled: inputCanvas.inputTextArea.text.length > 0
                        onClicked: { inputCanvas.inputTextArea.text = ""; root.translatedText = ""; }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: 16; text: "close"; color: Appearance.colors.colSubtext }
                    }
                }
            }
        }

        MaterialSymbol { text: "arrow_forward"; iconSize: 28; color: Appearance.colors.colSubtext || "#a6adc8"; opacity: 0.3 }

           Rectangle {
            Layout.fillHeight: true; Layout.fillWidth: true
            color: Appearance.colors.colLayer2 || "#181825" 
            radius: Appearance.rounding.large || 20

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16

                  RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    StyledText { text: "Traducción"; font.pixelSize: 18; font.weight: Font.Bold; color: Appearance.colors.colPrimary || "#cba6f7" }
                    Item { Layout.fillWidth: true } 
                    
                    LanguageSelectorButton {
                        displayText: root.targetLanguage
                        implicitHeight: 36
                        onClicked: root.showLanguageSelectorDialog(true)
                    }
                }

                   TextCanvas {
                    id: outputCanvas
                    Layout.fillWidth: true; Layout.fillHeight: true
                    isInput: false
                    placeholderText: root.isTranslating ? "Traduciendo..." : "La traducción aparecerá aquí..."
                    text: root.translatedText
                    
                    opacity: root.isTranslating ? 0.4 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                       GroupButton {
                        baseWidth: height; buttonRadius: Appearance.rounding.small
                        enabled: root.translatedText.trim().length > 0
                        onClicked: Quickshell.clipboardText = root.translatedText
                        contentItem: MaterialSymbol { anchors.centerIn: parent; iconSize: 16; text: "content_copy"; color: Appearance.colors.colOnLayer1 }
                    }
                }

                   RowLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 8; visible: root.isTranslating
                        MaterialSymbol { text: "sync"; iconSize: 16; color: Appearance.colors.colPrimary; RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible } }
                        StyledText { text: "Traduciendo..."; font.pixelSize: 12; color: Appearance.colors.colPrimary }
                    }
                    Item { Layout.fillWidth: true } 
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            titleText: "Selecciona el Idioma"
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: () => { root.showLanguageSelector = false; }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return;

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result; 
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result; 
                }
                translateTimer.restart(); 
            }
        }
    }

     property alias inputText: inputCanvas.inputTextArea
}
