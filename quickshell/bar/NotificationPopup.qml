import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: popup
    required property var theme

    anchors.top: true
    anchors.right: true
    implicitWidth: 360
    implicitHeight: current !== null ? box.implicitHeight + 12 : 0
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    property var current: null
    property int prevCount: 0

    Connections {
        target: NotificationServer
        function onTrackedNotificationsChanged() {
            var all = NotificationServer.trackedNotifications.values
            if (all.length > popup.prevCount) {
                popup.current = all[all.length - 1]
                var timeout = popup.current.expireTimeout > 0
                    ? popup.current.expireTimeout
                    : 5000
                dismissTimer.interval = timeout
                dismissTimer.restart()
            }
            popup.prevCount = all.length
        }
    }

    Timer {
        id: dismissTimer
        onTriggered: popup.current = null
    }

    Rectangle {
        id: box
        width: parent.width - 10
        x: 5
        y: 6
        implicitHeight: inner.implicitHeight + 16
        color: popup.theme.bg1
        border.color: urgencyColor()
        border.width: 2
        radius: 4
        visible: popup.current !== null
        clip: true

        function urgencyColor() {
            if (!popup.current) return popup.theme.sep
            switch (popup.current.urgency) {
                case NotificationUrgency.Critical: return "#fb4934"
                case NotificationUrgency.Low:      return popup.theme.sep
                default:                           return popup.theme.accent
            }
        }

        Column {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 8 }
            spacing: 3

            RowLayout {
                width: parent.width
                spacing: 6

                Text {
                    text: popup.current ? popup.current.appName : ""
                    color: popup.theme.accent
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.family: "Noto Sans JP"
                    Layout.fillWidth: true
                }

                Text {
                    text: "✕"
                    color: popup.theme.fgDim
                    font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (popup.current) popup.current.dismiss(); popup.current = null }
                    }
                }
            }

            Text {
                width: parent.width
                text: popup.current ? popup.current.summary : ""
                color: popup.theme.fg
                font.pixelSize: 12
                font.weight: Font.Medium
                font.family: "Noto Sans JP"
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: popup.current ? popup.current.body : ""
                color: popup.theme.fgDim
                font.pixelSize: 11
                font.family: "Noto Sans JP"
                wrapMode: Text.WordWrap
                visible: text !== ""
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (popup.current && popup.current.actions.length > 0)
                    popup.current.actions[0].invoke()
                popup.current = null
            }
        }
    }
}
