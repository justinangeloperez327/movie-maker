import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property var theme
    color: palette.canvas

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Preview"
                color: root.theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Text {
                text: "1920 × 1080  ·  30 FPS"
                color: root.theme.muted
                font.pixelSize: 11
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 145

            Rectangle {
                anchors.centerIn: parent
                width: Math.max(0, Math.min(parent.width, parent.height * 16 / 9))
                height: width * 9 / 16
                color: root.theme.video
                border.color: root.theme.border
                radius: 2
                Text {
                    anchors.centerIn: parent
                    text: "No preview available\nImport media to begin editing"
                    color: "#9298a0"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.6
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "00:00:00:00"
                color: root.theme.text
                font.pixelSize: 12
                font.family: "Consolas"
                Layout.fillWidth: true
            }
            SmallAction {
                theme: root.theme
                text: "◀◀"
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Frame navigation requires playback engine."
            }
            SmallAction {
                theme: root.theme
                text: "Play"
                primary: true
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Playback will be implemented in Group 5."
            }
            SmallAction {
                theme: root.theme
                text: "▶▶"
                enabled: false
            }
            Text {
                text: "00:00:00:00"
                color: root.theme.muted
                font.pixelSize: 12
                font.family: "Consolas"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
