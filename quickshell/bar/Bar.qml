import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: bar

    required property var theme
    required property bool isDark

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 28
    color: "transparent"
    exclusiveZone: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: bar.theme.bg

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: bar.theme.sep
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 0

            // ── IZQUIERDA: Workspaces + título ventana ─────────────
            Workspaces {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            // Separador visual entre workspaces y título
            Rectangle {
                width: 1
                height: 14
                color: bar.theme.sep
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                Layout.rightMargin: 6
            }

            WindowTitle {
                theme: bar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            // Empuja la sección derecha al borde
            Item { Layout.fillWidth: true }

            // ── DERECHA: Vol + Bri + Bat + reloj ──────────────────
            RightSection {
                theme: bar.theme
                isDark: bar.isDark
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
