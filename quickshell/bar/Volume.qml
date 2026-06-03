import QtQuick
import Quickshell.Io

Item {
    id: volume

    required property var theme

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    property int percent: 0
    property bool muted: false

    // Usar pactl para leer volumen del sink por defecto
    Process {
        id: volProcess
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var v = parseInt(line)
                if (!isNaN(v)) volume.percent = v
            }
        }
    }

    Process {
        id: muteProcess
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                volume.muted = line.indexOf("yes") !== -1
            }
        }
    }

    function refresh() {
        volProcess.running = true
        muteProcess.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: volume.refresh()
    }

    Component.onCompleted: volume.refresh()

    property string volColor: {
        if (volume.muted) return volume.theme.fgDim
        if (volume.percent > 100) return volume.theme.yellow
        return volume.theme.fg
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: volume.muted ? "VOL:M" : "VOL:"
            color: volume.theme.fgDim
            font.pixelSize: 11
            font.family: "Noto Sans JP"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: volume.muted ? "---" : volume.percent + "%"
            color: volume.volColor
            font.pixelSize: 11
            font.family: "Noto Sans JP"
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
