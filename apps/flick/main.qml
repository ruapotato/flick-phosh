import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    title: "Flick"
    color: "#0a0a0f"

    // Theme properties
    property color accentColor: "#e94560"
    property string stateDir: "/home/furios/.local/state/flick"
    property string flickPhoshDir: "/home/furios/flick-phosh"

    Component.onCompleted: {
        loadConfig()
    }

    function loadConfig() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + stateDir + "/display_config.json", false)
        try {
            xhr.send()
            if (xhr.status === 200 || xhr.status === 0) {
                var config = JSON.parse(xhr.responseText)
                if (config.accent_color) accentColor = config.accent_color
            }
        } catch (e) {}
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage
    }

    Component {
        id: mainPage
        FlickMain {
            onPageRequested: function(pageName) {
                var component = Qt.createComponent("pages/" + pageName + ".qml")
                if (component.status === Component.Ready) {
                    stackView.push(component)
                } else {
                    console.log("Failed to load page: " + pageName)
                }
            }
        }
    }
}
