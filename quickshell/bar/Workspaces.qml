import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaces

    required property var theme

    readonly property var jpNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: 9

            delegate: WorkspaceButton {
                required property int index
                property int wsId: index + 1

                // Usar focusedWorkspace en vez de focusedMonitor
                property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                property bool isOccupied: {
                    for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                        var ws = Hyprland.workspaces.values[i]
                        if (ws.id === wsId && ws.windowCount > 0) return true
                    }
                    return false
                }

                wsNumber: wsId
                jpLabel: workspaces.jpNumbers[index]
                active: isActive
                occupied: isOccupied
                theme: workspaces.theme

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + wsId)
                }
            }
        }
    }
}
