import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

ShellRoot {
    id: root

    // isDark: valor inicial por hora, luego controlado por set-theme.sh
    property bool isDark: {
        var h = new Date().getHours()
        return (h < 7 || h >= 20)
    }

    // Escuchar cambios de tema desde set-theme.sh
    Process {
        id: themeWatcher
        command: ["sh", "-c", "touch /tmp/qs-theme && tail -f /tmp/qs-theme"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var msg = line.trim()
                if (msg === "dark")  root.isDark = true
                if (msg === "light") root.isDark = false
            }
        }
        onRunningChanged: {
            if (!running) themeRestartTimer.restart()
        }
    }

    Timer {
        id: themeRestartTimer
        interval: 1000
        repeat: false
        onTriggered: themeWatcher.running = true
    }

    property var darkTheme: ({
        bg:          "#282828",
        bg1:         "#3c3836",
        bg2:         "#504945",
        fg:          "#ebdbb2",
        fgDim:       "#a89984",
        yellow:      "#d79921",
        blue:        "#83a598",
        aqua:        "#689d6a",
        accent:      "#d79921",
        accentFg:    "#282828",
        wsActive:    "#d79921",
        wsOccupied:  "#504945",
        wsEmpty:     "transparent",
        wsActiveText:"#282828",
        wsOccText:   "#ebdbb2",
        wsEmptyText: "#665c54",
        sep:         "#504945",
        border:      "#504945"
    })

    property var lightTheme: ({
        bg:          "#f9f5d7",
        bg1:         "#ebdbb2",
        bg2:         "#d5c4a1",
        fg:          "#3c3836",
        fgDim:       "#7c6f64",
        yellow:      "#b57614",
        blue:        "#076678",
        aqua:        "#427b58",
        accent:      "#b57614",
        accentFg:    "#f9f5d7",
        wsActive:    "#b57614",
        wsOccupied:  "#d5c4a1",
        wsEmpty:     "transparent",
        wsActiveText:"#f9f5d7",
        wsOccText:   "#3c3836",
        wsEmptyText: "#bdae93",
        sep:         "#d5c4a1",
        border:      "#d5c4a1"
    })

    property var theme: isDark ? darkTheme : lightTheme

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            theme: root.theme
            isDark: root.isDark
        }
    }

    NotificationServer { keepOnReload: true }

    NotificationPopup {
        id: notifPopup
        theme: root.theme
        screen: Quickshell.screens[0]
    }

    NotificationCenter {
        id: notifCenter
        theme: root.theme
        screen: Quickshell.screens[0]
    }

    PanelWindow {
        screen: Quickshell.screens[0]
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        visible: notifCenter.open
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
            anchors.fill: parent
            onClicked: notifCenter.doHide()
        }
    }

    Process {
        id: notifIpc
        command: ["sh", "-c", "touch /tmp/qs-notif && tail -f /tmp/qs-notif"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() === "toggle") {
                    if (notifCenter.open) notifCenter.doHide()
                    else notifCenter.doShow()
                }
            }
        }
        onRunningChanged: { if (!running) notifRestartTimer.restart() }
    }

    Timer {
        id: notifRestartTimer
        interval: 1000
        repeat: false
        onTriggered: notifIpc.running = true
    }

    Launcher {
        id: appLauncher
        theme: root.theme
        screen: Quickshell.screens[0]
    }

    ClipboardViewer {
        id: clipViewer
        theme: root.theme
        screen: Quickshell.screens[0]
    }

    // Backdrop transparente para cerrar clipboard al clickear afuera
    PanelWindow {
        screen: Quickshell.screens[0]
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        visible: clipViewer.open
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
            anchors.fill: parent
            onClicked: clipViewer.doHide()
        }
    }

    Process {
        id: ipcWatcher
        command: ["sh", "-c", "touch /tmp/qs-launcher && tail -f /tmp/qs-launcher"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var msg = line.trim()
                if (msg === "toggle") {
                    if (appLauncher.open) appLauncher.doHide()
                    else appLauncher.doShow()
                }
            }
        }
        onRunningChanged: {
            if (!running) launcherRestartTimer.restart()
        }
    }

    Timer {
        id: launcherRestartTimer
        interval: 1000
        repeat: false
        onTriggered: ipcWatcher.running = true
    }

    Process {
        id: clipboardIpc
        command: ["sh", "-c", "touch /tmp/qs-clipboard && tail -f /tmp/qs-clipboard"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var msg = line.trim()
                if (msg === "toggle") {
                    if (clipViewer.open) clipViewer.doHide()
                    else clipViewer.doShow()
                }
            }
        }
        onRunningChanged: {
            if (!running) clipboardRestartTimer.restart()
        }
    }

    Timer {
        id: clipboardRestartTimer
        interval: 1000
        repeat: false
        onTriggered: clipboardIpc.running = true
    }
}
