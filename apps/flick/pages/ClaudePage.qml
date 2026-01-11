import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: claudePage

    property string requestFile: "/tmp/flick_claude_request"
    property string statusFile: "/tmp/flick_claude_status"
    property bool isProcessing: false
    property string statusText: ""

    Timer {
        id: statusTimer
        interval: 1000
        repeat: true
        running: isProcessing
        onTriggered: checkStatus()
    }

    function checkStatus() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + statusFile, false)
        try {
            xhr.send()
            if (xhr.status === 200 || xhr.status === 0) {
                var status = xhr.responseText.trim()
                if (status) {
                    statusText = status
                    if (status.indexOf("DONE:") === 0 || status.indexOf("ERROR:") === 0) {
                        isProcessing = false
                    }
                }
            }
        } catch (e) {}
    }

    function submitRequest() {
        if (requestInput.text.trim() === "") return

        isProcessing = true
        statusText = "Sending request to Claude..."

        // Write request to file for the shell script to pick up
        console.log("CLAUDE_REQUEST:" + requestInput.text.trim())
        requestInput.text = ""
    }

    background: Rectangle { color: "#0a0a0f" }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 140
        color: "transparent"

        // Sparkle effect
        Repeater {
            model: 8
            Rectangle {
                x: Math.random() * header.width
                y: 20 + Math.random() * 80
                width: 2
                height: 2
                radius: 1
                color: "#ffffff"
                opacity: 0.3

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.8; duration: 500 + Math.random() * 1000 }
                    NumberAnimation { to: 0.1; duration: 500 + Math.random() * 1000 }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Claude"
                font.pixelSize: 32
                font.weight: Font.ExtraLight
                font.letterSpacing: 4
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CREATE APPS WITH AI"
                font.pixelSize: 10
                font.letterSpacing: 3
                color: "#555566"
            }
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: backButton.top
        anchors.margins: 16
        contentHeight: contentCol.height
        clip: true

        Column {
            id: contentCol
            width: parent.width
            spacing: 16

            // Info card
            Rectangle {
                width: contentCol.width
                height: infoCol.height + 24
                radius: 16
                color: "#14141e"
                border.color: "#1a2a4a"

                Column {
                    id: infoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Describe what you want"
                        font.pixelSize: 14
                        color: "#ffffff"
                    }

                    Text {
                        width: parent.width
                        text: "Tell Claude what kind of app you need. Be specific about features and how it should look. Claude will create it in this folder."
                        font.pixelSize: 11
                        color: "#666677"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Input area
            Rectangle {
                width: contentCol.width
                height: 160
                radius: 16
                color: "#14141e"
                border.color: requestInput.activeFocus ? root.accentColor : "#1a1a2e"
                border.width: requestInput.activeFocus ? 2 : 1

                TextArea {
                    id: requestInput
                    anchors.fill: parent
                    anchors.margins: 12
                    placeholderText: "Example: Create a simple timer app with start, stop, and reset buttons. Dark theme with large digits..."
                    placeholderTextColor: "#444455"
                    color: "#ffffff"
                    font.pixelSize: 14
                    wrapMode: TextArea.Wrap
                    enabled: !isProcessing
                    background: Rectangle { color: "transparent" }
                }
            }

            // Submit button
            Rectangle {
                width: contentCol.width
                height: 52
                radius: 26
                color: isProcessing ? "#333344" : (submitMouse.pressed ? Qt.darker(root.accentColor, 1.2) : root.accentColor)
                opacity: requestInput.text.trim() === "" && !isProcessing ? 0.5 : 1

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: isProcessing ? "\u23F3" : "\u2728"
                        font.pixelSize: 18
                        color: "#ffffff"
                    }

                    Text {
                        text: isProcessing ? "Creating..." : "Create App"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    enabled: !isProcessing && requestInput.text.trim() !== ""
                    onClicked: submitRequest()
                }
            }

            // Status area
            Rectangle {
                width: contentCol.width
                height: statusCol.height + 24
                radius: 16
                color: "#14141e"
                visible: statusText !== ""

                Column {
                    id: statusCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Status"
                        font.pixelSize: 13
                        color: "#888899"
                    }

                    Text {
                        width: parent.width
                        text: statusText
                        font.pixelSize: 12
                        color: statusText.indexOf("ERROR") >= 0 ? "#ff6666" : (statusText.indexOf("DONE") >= 0 ? "#66ff66" : "#aaaaaa")
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Examples
            Text {
                text: "EXAMPLE REQUESTS"
                font.pixelSize: 10
                font.letterSpacing: 2
                color: "#555566"
                leftPadding: 4
            }

            Repeater {
                model: [
                    "A pomodoro timer with 25/5 minute cycles",
                    "A simple note-taking app with save/load",
                    "A flashlight app with brightness control",
                    "A stopwatch with lap times"
                ]

                Rectangle {
                    width: contentCol.width
                    height: 44
                    radius: 12
                    color: exMouse.pressed ? "#1e1e2e" : "#14141e"

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 12
                        text: modelData
                        font.pixelSize: 12
                        color: "#888899"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: exMouse
                        anchors.fill: parent
                        onClicked: requestInput.text = modelData
                    }
                }
            }

            Item { height: 40 }
        }
    }

    Rectangle {
        id: backButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 100
        width: 44
        height: 44
        radius: 22
        color: backMouse.pressed ? Qt.darker(root.accentColor, 1.2) : root.accentColor

        Text {
            anchors.centerIn: parent
            text: "\u2190"
            font.pixelSize: 20
            color: "#ffffff"
        }

        MouseArea {
            id: backMouse
            anchors.fill: parent
            onClicked: stackView.pop()
        }
    }
}
