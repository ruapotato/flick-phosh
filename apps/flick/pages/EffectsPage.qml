import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: effectsPage

    property bool fireTouchEnabled: true
    property bool livingPixelsEnabled: false
    property bool lpStars: true
    property bool lpShootingStars: true
    property bool lpFireflies: true
    property string configPath: root.stateDir + "/effects_config.json"

    Component.onCompleted: loadConfig()

    function loadConfig() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + configPath, false)
        try {
            xhr.send()
            if (xhr.status === 200) {
                var config = JSON.parse(xhr.responseText)
                if (config.fire_touch_enabled !== undefined) fireTouchEnabled = config.fire_touch_enabled
                if (config.living_pixels_enabled !== undefined) livingPixelsEnabled = config.living_pixels_enabled
                if (config.lp_stars !== undefined) lpStars = config.lp_stars
                if (config.lp_shooting_stars !== undefined) lpShootingStars = config.lp_shooting_stars
                if (config.lp_fireflies !== undefined) lpFireflies = config.lp_fireflies
            }
        } catch (e) {}
    }

    function saveConfig() {
        var config = {
            fire_touch_enabled: fireTouchEnabled,
            living_pixels_enabled: livingPixelsEnabled,
            lp_stars: lpStars,
            lp_shooting_stars: lpShootingStars,
            lp_fireflies: lpFireflies
        }
        console.log("SAVE_EFFECTS:" + JSON.stringify(config))
    }

    background: Rectangle { color: "#0a0a0f" }

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 160
        color: "transparent"

        // Fire preview
        Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -40
            width: 80
            height: 80
            radius: 40
            color: "#ff6600"
            opacity: fireTouchEnabled ? 0.3 : 0.1

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: fireTouchEnabled
                NumberAnimation { to: 0.5; duration: 300 }
                NumberAnimation { to: 0.2; duration: 300 }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Effects"
                font.pixelSize: 32
                font.weight: Font.ExtraLight
                font.letterSpacing: 4
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VISUAL ENHANCEMENTS"
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
        contentHeight: col.height
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 12

            Text { text: "TOUCH EFFECTS"; font.pixelSize: 10; font.letterSpacing: 2; color: "#555566"; leftPadding: 8 }

            EffectToggle {
                width: col.width
                title: "Fire on Touch"
                subtitle: "Flame particles follow your finger"
                checked: fireTouchEnabled
                accentColor: "#ff6600"
                onToggled: { fireTouchEnabled = !fireTouchEnabled; saveConfig() }
            }

            Item { height: 8 }

            Text { text: "AMBIENT EFFECTS"; font.pixelSize: 10; font.letterSpacing: 2; color: "#555566"; leftPadding: 8 }

            EffectToggle {
                width: col.width
                title: "Living Pixels"
                subtitle: "Stars and fireflies on screen"
                checked: livingPixelsEnabled
                accentColor: "#ffaa00"
                onToggled: { livingPixelsEnabled = !livingPixelsEnabled; saveConfig() }
            }

            Rectangle {
                width: col.width
                height: subCol.height + 20
                radius: 16
                color: "#14141e"
                border.color: livingPixelsEnabled ? "#ffaa00" : "#1a1a2e"
                visible: livingPixelsEnabled

                Column {
                    id: subCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 8

                    Text { text: "Effect Types"; font.pixelSize: 12; color: "#888899" }

                    Row {
                        spacing: 8
                        SubToggle { label: "Stars"; checked: lpStars; onToggled: { lpStars = !lpStars; saveConfig() } }
                        SubToggle { label: "Shooting"; checked: lpShootingStars; onToggled: { lpShootingStars = !lpShootingStars; saveConfig() } }
                        SubToggle { label: "Fireflies"; checked: lpFireflies; onToggled: { lpFireflies = !lpFireflies; saveConfig() } }
                    }
                }
            }

            Item { height: 16 }

            Rectangle {
                width: col.width
                height: noteCol.height + 20
                radius: 12
                color: "#14141e"

                Column {
                    id: noteCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 6

                    Text { text: "Note"; font.pixelSize: 12; color: "#888899" }
                    Text {
                        width: parent.width
                        text: "Restart flick-effects service to apply changes."
                        font.pixelSize: 11
                        color: "#666677"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // Back button
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

    // Toggle component
    component EffectToggle: Rectangle {
        property string title
        property string subtitle
        property bool checked
        property color accentColor: root.accentColor
        signal toggled()

        height: 72
        radius: 16
        color: toggleMouse.pressed ? "#1e1e2e" : "#14141e"
        border.color: checked ? accentColor : "#1a1a2e"
        border.width: checked ? 2 : 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Column {
                Layout.fillWidth: true
                spacing: 4
                Text { text: title; font.pixelSize: 16; color: "#ffffff" }
                Text { text: subtitle; font.pixelSize: 11; color: "#666677" }
            }

            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 28
                radius: 14
                color: checked ? accentColor : "#2a2a3e"

                Rectangle {
                    x: checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: "#ffffff"
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
            }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            onClicked: toggled()
        }
    }

    component SubToggle: Rectangle {
        property string label
        property bool checked
        signal toggled()

        width: 80
        height: 36
        radius: 18
        color: checked ? "#2a2a38" : "#1a1a28"
        border.color: checked ? "#ffaa00" : "#2a2a3e"

        Text {
            anchors.centerIn: parent
            text: label
            font.pixelSize: 11
            color: checked ? "#ffffff" : "#666677"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: toggled()
        }
    }
}
