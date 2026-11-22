//
// WebOS Lock — SDDM greeter styled like the WebOS hyprlock screen.
//
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#000000"

    // Wallpaper under a dark veil, like hyprlock's blurred screenshot.
    Image {
        anchors.fill: parent
        source: "/usr/share/webos/wallpaper/webos-wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.72
    }

    // Session selector — top left. Uses SDDM's own ComboBox, as shipped
    // themes do, so keyboard Up/Down/Enter works without a mouse.
    ComboBox {
        id: sessionBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 22
        width: 168
        height: 34

        model: sessionModel
        index: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

        color: "#1a1a1a"
        borderColor: "#3a3a3a"
        focusColor: "#d8d8d8"
        hoverColor: "#7a7a7a"
        menuColor: "#141414"
        textColor: "#d8d8d8"
        font.family: "Inter"
        font.pixelSize: 12
        arrowIcon: Qt.resolvedUrl("arrow.svg")
        arrowColor: "#d8d8d8"
    }

    // Clock — upper centre.
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.30
        text: Qt.formatDateTime(new Date(), "hh:mm")
        color: "#d8d8d8"
        opacity: 0.95
        font.family: "Inter"
        font.bold: true
        font.pixelSize: Math.min(108, parent.width * 0.075)
    }

    Text {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom
        anchors.topMargin: 6
        text: Qt.formatDateTime(new Date(), "dddd, dd MMMM")
        color: "#7a7a7a"
        opacity: 0.85
        font.family: "Inter"
        font.pixelSize: 17
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            clock.text = Qt.formatDateTime(now, "hh:mm")
            dateLabel.text = Qt.formatDateTime(now, "dddd, dd MMMM")
        }
    }

    // Logo + identity.
    Image {
        id: logo
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.51
        source: "/usr/share/webos/logo.svg"
        width: 84
        height: 84
        fillMode: Image.PreserveAspectFit
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: 8
        text: userModel.lastUser ? userModel.lastUser : ""
        color: "#e8e8e8"
        opacity: 0.9
        font.family: "Inter"
        font.bold: true
        font.pixelSize: 15
    }

    // Password field — hyprlock's rounded outlined box, plain TextInput
    // so no QtQuick.Controls dependency in the greeter.
    Rectangle {
        id: pwBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.66
        width: 320
        height: 52
        color: "#000000"
        opacity: 0.92
        border.color: "#3a3a3a"
        border.width: 1
        radius: 14

        Text {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: Text.AlignVCenter
            text: "enter password…"
            color: "#7a7a7a"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 13
            visible: password.text.length === 0
        }

        TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 13
            color: "#d8d8d8"
            onAccepted: attemptLogin()
        }
    }

    Text {
        id: failText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: pwBox.bottom
        anchors.topMargin: 10
        text: ""
        color: "#f87171"
        font.family: "Inter"
        font.pixelSize: 12
        visible: false
    }

    // Footer.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        text: "WebOS"
        color: "#7a7a7a"
        opacity: 0.8
        font.family: "Inter"
        font.pixelSize: 11
    }

    function attemptLogin() {
        var user = userModel.lastUser
        if (!user && sddm.users.length > 0)
            user = sddm.users[0]
        sddm.login(user, password.text, sessionBox.index)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            failText.text = "Login failed — try again"
            failText.visible = true
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            failText.visible = false
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
