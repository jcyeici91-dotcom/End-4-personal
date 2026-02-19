import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property string editToken: pluginApi.pluginSettings.kagiSessionToken ?? ""
  property int editDebounce: pluginApi.pluginSettings.debounceMs ?? 500

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("Kagi", "Settings UI loaded");
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NTextInput {
      Layout.fillWidth: true
      label: "Kagi Session Token (Required)"
      text: root.editToken
      onTextChanged: root.editToken = text
    }

    Text {
      text: "To get your Kagi session token:\n- Open kagi.com in your browser, right click, and select \"Inspect Element\"\n- Switch to the \"Network\" tab and filter for \"Fetch/XHR\"\n- Type something in the search bar\n- Click on any entry that's labeled with \"autosuggest\"\n- Scroll down until you see an item labelled \"Set-Cookie\"\n- You'll see something like `kagi_session=Copy_this_its_long; ...`<br/>Copy the text after the `=` and before the `;` and paste it above, then hit save."
      color: Color.mOnSurfaceVariant
      font.pointSize: Style.fontSizeS
      textFormat: Text.MarkdownText
    }
    
    NLabel {
        label: "Debounce"
        description: "How long it'll take to search your query in milliseconds"
    }

    NSlider {
        id: debounceSlider
        from: 300
        to: 1500
        value: root.editDebounce
        stepSize: 100
        onValueChanged: {
            root.editDebounce = value
        }
    }
    
    Text {
        text: `${root.editDebounce}ms`
        color: Color.mOnSurfaceVariant
        font.pointSize: Style.fontSizeS
    }

  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Kagi", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.pluginSettings.kagiSessionToken = root.editToken.trim();
    pluginApi.pluginSettings.debounceMs = root.editDebounce;
    pluginApi.saveSettings();

    Logger.i("Kagi", "Settings saved successfully");
  }
}
