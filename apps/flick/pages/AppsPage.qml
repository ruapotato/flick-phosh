import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: appsPage

    property string phoshStateDir: root.stateDir.replace("/flick", "/flick-phosh")
    property var excludedApps: []
    property var allApps: []
    property var defaultExcluded: ["furios-camera", "org.gnome.Calls", "firefox", "sm.puri.Chatty"]
    property int currentTab: 0

    Component.onCompleted: {
        loadExcludedApps()
        scanAllApps()
    }

    function loadExcludedApps() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + phoshStateDir + "/excluded_apps.json", false)
        try {
            xhr.send()
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText && xhr.responseText.trim().length > 2) {
                excludedApps = JSON.parse(xhr.responseText)
            } else {
                excludedApps = defaultExcluded.slice()
            }
        } catch (e) {
            excludedApps = defaultExcluded.slice()
        }
    }

    function saveExcludedApps() {
        console.log("SAVE_EXCLUDED:" + JSON.stringify(excludedApps))
        updateOtherApps()
    }

    function updateOtherApps() {
        var otherApps = []
        for (var i = 0; i < allApps.length; i++) {
            if (excludedApps.indexOf(allApps[i].id) < 0) {
                otherApps.push(allApps[i].id)
            }
        }
        console.log("SAVE_OTHER_APPS:" + JSON.stringify(otherApps))
    }

    function scanAllApps() {
        allApps = []
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + phoshStateDir + "/discovered_apps.json", false)
        try {
            xhr.send()
            if (xhr.status === 200 || xhr.status === 0) {
                var discovered = JSON.parse(xhr.responseText)
                for (var i = 0; i < discovered.length; i++) {
                    var app = discovered[i]
                    if (app.id.indexOf("flick-") !== 0) {
                        allApps.push({ id: app.id, name: app.name, icon: app.icon })
                    }
                }
            }
        } catch (e) {}
        updateModel()
    }

    function updateModel() {
        appsModel.clear()
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]
            appsModel.append({
                appId: app.id,
                name: app.name,
                icon: app.icon,
                excluded: excludedApps.indexOf(app.id) >= 0
            })
        }
    }

    function toggleApp(appId) {
        var idx = excludedApps.indexOf(appId)
        if (idx >= 0) {
            excludedApps.splice(idx, 1)
        } else {
            excludedApps.push(appId)
        }
        saveExcludedApps()
        updateModel()
    }

    background: Rectangle { color: "#0a0a0f" }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 120
        color: "transparent"

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "App Manager"
                font.pixelSize: 28
                font.weight: Font.ExtraLight
                font.letterSpacing: 3
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ORGANIZE YOUR APPS"
                font.pixelSize: 10
                font.letterSpacing: 3
                color: "#555566"
            }
        }
    }

    ListModel { id: appsModel }

    Row {
        id: tabs
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Repeater {
            model: ["Main Screen", "Other Apps"]

            Rectangle {
                width: 100
                height: 32
                radius: 16
                color: currentTab === index ? root.accentColor : "#1a1a28"

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 11
                    color: currentTab === index ? "#ffffff" : "#888899"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: currentTab = index
                }
            }
        }
    }

    Flickable {
        anchors.top: tabs.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: backButton.top
        anchors.margins: 16
        contentHeight: contentCol.height
        clip: true

        Column {
            id: contentCol
            width: parent.width
            spacing: 8

            Rectangle {
                width: contentCol.width
                height: descText.height + 20
                radius: 12
                color: "#14141e"

                Text {
                    id: descText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    text: currentTab === 0
                        ? "Apps here stay on main screen. Toggle OFF to move to Other Apps."
                        : "Apps here are in Other Apps folder. Toggle ON to move to main screen."
                    font.pixelSize: 11
                    color: "#666677"
                    wrapMode: Text.WordWrap
                }
            }

            Repeater {
                model: appsModel

                Rectangle {
                    width: contentCol.width
                    height: 56
                    radius: 12
                    color: model.excluded ? "#1a2a1a" : "#14141e"
                    border.color: model.excluded ? "#2a4a2a" : "#1a1a2e"
                    visible: (currentTab === 0 && model.excluded) || (currentTab === 1 && !model.excluded)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 8
                            color: "#2a2a3e"

                            Text {
                                anchors.centerIn: parent
                                text: model.name.charAt(0)
                                font.pixelSize: 16
                                font.bold: true
                                color: "#888899"
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: model.name
                                font.pixelSize: 14
                                color: "#ffffff"
                            }

                            Text {
                                text: model.appId
                                font.pixelSize: 10
                                color: "#555566"
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 26
                            radius: 13
                            color: model.excluded ? "#4CAF50" : "#2a2a3e"

                            Rectangle {
                                x: model.excluded ? parent.width - width - 3 : 3
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                radius: 10
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: toggleApp(model.appId)
                            }
                        }
                    }
                }
            }

            Text {
                visible: {
                    var count = 0
                    for (var i = 0; i < appsModel.count; i++) {
                        var item = appsModel.get(i)
                        if ((currentTab === 0 && item.excluded) || (currentTab === 1 && !item.excluded)) count++
                    }
                    return count === 0
                }
                text: currentTab === 0 ? "No apps on main screen." : "All apps are on main screen."
                color: "#555566"
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }
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
