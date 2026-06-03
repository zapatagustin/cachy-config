import QtQuick
import Quickshell.Io

Item {
    id: brightness

    required property var theme

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    property int percent: 100

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: { currentReader.reload(); maxReader.reload() }
    }

    property int rawCurrent: 0
    property int rawMax: 1

    FileView {
        id: currentReader
        // intel_backlight es el más común; si no funciona probar acpi_video0
        path: "/sys/class/backlight/intel_backlight/brightness"
        onLoaded: {
            var v = parseInt(currentReader.text())
            if (!isNaN(v)) {
                brightness.rawCurrent = v
                brightness.percent = Math.round(brightness.rawCurrent / brightness.rawMax * 100)
            }
        }
    }

    FileView {
        id: maxReader
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        onLoaded: {
            var v = parseInt(maxReader.text())
            if (!isNaN(v) && v > 0) {
                brightness.rawMax = v
                brightness.percent = Math.round(brightness.rawCurrent / brightness.rawMax * 100)
            }
        }
    }

    Component.onCompleted: {
        currentReader.reload()
        maxReader.reload()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: "BRI:"
            color: brightness.theme.fgDim
            font.pixelSize: 11
            font.family: "Noto Sans JP"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: brightness.percent + "%"
            color: brightness.theme.fg
            font.pixelSize: 11
            font.family: "Noto Sans JP"
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
