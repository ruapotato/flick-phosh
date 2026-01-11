import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: themePage

    property color selectedColor: root.accentColor
    property var colorPresets: [
        "#e94560", "#ff6b6b", "#ff9f43", "#feca57",
        "#48dbfb", "#0abde3", "#1dd1a1", "#10ac84",
        "#5f27cd", "#341f97", "#ff6b81", "#f368e0",
        "#576574", "#8395a7", "#c8d6e5", "#ffffff"
    ]

    function saveTheme() {
        console.log("SAVE_THEME:" + JSON.stringify({accent_color: selectedColor.toString()}))
        root.accentColor = selectedColor
    }

    background: Rectangle { color: "#0a0a0f" }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 140
        color: "transparent"

        // Preview glow
        Rectangle {
            anchors.centerIn: parent
            width: 100
            height: 100
            radius: 50
            color: selectedColor
            opacity: 0.2

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 1500 }
                NumberAnimation { to: 0.15; duration: 1500 }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Theme"
                font.pixelSize: 32
                font.weight: Font.ExtraLight
                font.letterSpacing: 4
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PERSONALIZE"
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

            Text {
                text: "ACCENT COLOR"
                font.pixelSize: 10
                font.letterSpacing: 2
                color: "#555566"
                leftPadding: 4
            }

            // Color grid
            Rectangle {
                width: contentCol.width
                height: colorGrid.height + 24
                radius: 16
                color: "#14141e"

                GridLayout {
                    id: colorGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    columns: 4
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: colorPresets

                        Rectangle {
                            Layout.preferredWidth: (contentCol.width - 24 - 36) / 4
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: 12
                            color: modelData
                            border.color: selectedColor.toString().toUpperCase() === modelData.toUpperCase() ? "#ffffff" : "transparent"
                            border.width: 3

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.4
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                visible: selectedColor.toString().toUpperCase() === modelData.toUpperCase()
                                opacity: 0.9

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2713"
                                    font.pixelSize: parent.width * 0.6
                                    font.bold: true
                                    color: modelData
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: selectedColor = modelData
                            }
                        }
                    }
                }
            }

            // Preview
            Text {
                text: "PREVIEW"
                font.pixelSize: 10
                font.letterSpacing: 2
                color: "#555566"
                leftPadding: 4
            }

            Rectangle {
                width: contentCol.width
                height: 80
                radius: 16
                color: "#14141e"

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                        width: 56
                        height: 56
                        radius: 28
                        color: selectedColor

                        Text {
                            anchors.centerIn: parent
                            text: "\u2605"
                            font.pixelSize: 24
                            color: "#ffffff"
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "Sample Button"
                            font.pixelSize: 16
                            color: "#ffffff"
                        }

                        Rectangle {
                            width: 100
                            height: 4
                            radius: 2
                            color: selectedColor
                        }
                    }
                }
            }

            // Apply button
            Rectangle {
                width: contentCol.width
                height: 52
                radius: 26
                color: applyMouse.pressed ? Qt.darker(selectedColor, 1.2) : selectedColor

                Text {
                    anchors.centerIn: parent
                    text: "Apply Theme"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#ffffff"
                }

                MouseArea {
                    id: applyMouse
                    anchors.fill: parent
                    onClicked: saveTheme()
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
