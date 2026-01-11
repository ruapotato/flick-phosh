import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: flickMain

    signal pageRequested(string pageName)

    background: Rectangle {
        color: "#0a0a0f"
    }

    // Hero header
    Rectangle {
        id: headerArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 180
        color: "transparent"

        // Ambient glow
        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: 180
            radius: 140
            color: root.accentColor
            opacity: 0.06

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.1; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.04; duration: 2000; easing.type: Easing.InOutSine }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Flick"
                font.pixelSize: 42
                font.weight: Font.ExtraLight
                font.letterSpacing: 6
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CONTROL CENTER"
                font.pixelSize: 11
                font.letterSpacing: 4
                color: "#555566"
            }
        }

        // Bottom accent line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: root.accentColor }
                GradientStop { position: 0.7; color: root.accentColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.4
        }
    }

    // Main grid
    GridView {
        id: mainGrid
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        anchors.bottomMargin: 80

        cellWidth: width / 2
        cellHeight: 160
        clip: true

        model: ListModel {
            ListElement {
                title: "Effects"
                subtitle: "Visual magic"
                icon: "fire"
                gradStart: "#4a1a4a"
                gradEnd: "#1a0d1a"
                pageName: "EffectsPage"
            }
            ListElement {
                title: "Apps"
                subtitle: "Manage apps"
                icon: "grid"
                gradStart: "#1a4a2a"
                gradEnd: "#0d1a12"
                pageName: "AppsPage"
            }
            ListElement {
                title: "Claude"
                subtitle: "Create apps"
                icon: "sparkle"
                gradStart: "#1a2a4a"
                gradEnd: "#0d121a"
                pageName: "ClaudePage"
            }
            ListElement {
                title: "Theme"
                subtitle: "Customize"
                icon: "palette"
                gradStart: "#4a2a1a"
                gradEnd: "#1a120d"
                pageName: "ThemePage"
            }
        }

        delegate: Item {
            width: mainGrid.cellWidth
            height: mainGrid.cellHeight

            Rectangle {
                id: tile
                anchors.fill: parent
                anchors.margins: 8
                radius: 24

                gradient: Gradient {
                    GradientStop { position: 0.0; color: model.gradStart }
                    GradientStop { position: 1.0; color: model.gradEnd }
                }

                // Subtle border
                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 1
                    opacity: tileMouse.pressed ? 0.2 : 0.05
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    // Icon
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            switch(model.icon) {
                                case "fire": return "\uD83D\uDD25"
                                case "grid": return "\uD83D\uDCF1"
                                case "sparkle": return "\u2728"
                                case "palette": return "\uD83C\uDFA8"
                                default: return "\u2699"
                            }
                        }
                        font.pixelSize: 36
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.title
                            font.pixelSize: 20
                            font.weight: Font.Medium
                            font.letterSpacing: 1
                            color: "#ffffff"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.subtitle
                            font.pixelSize: 11
                            color: "#888899"
                        }
                    }
                }

                // Entrance animation
                opacity: 0
                scale: 0.9
                Component.onCompleted: entranceAnim.start()

                ParallelAnimation {
                    id: entranceAnim
                    PauseAnimation { duration: index * 80 }
                    NumberAnimation { target: tile; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
                    NumberAnimation { target: tile; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    onClicked: flickMain.pageRequested(model.pageName)
                }
            }
        }
    }

    // Home indicator
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: 120
        height: 4
        radius: 2
        color: "#333344"
    }
}
