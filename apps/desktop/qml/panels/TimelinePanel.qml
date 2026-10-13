import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property var theme
    color: palette.surface
    implicitHeight: 230

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "Timeline"
                color: root.theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Rectangle { width: 1; height: 18; color: root.theme.border }
            SmallAction {
                theme: root.theme
                text: "Split"
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Timeline splitting is scheduled for Group 6."
            }
            SmallAction {
                theme: root.theme
                text: "Trim"
                enabled: false
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Zoom"
                color: root.theme.muted
                font.pixelSize: 11
            }
            SmallAction {
                theme: root.theme
                text: "−"
                enabled: false
            }
            SmallAction {
                theme: root.theme
                text: "+"
                enabled: false
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.theme.border }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "TRACK"
                Layout.preferredWidth: 104
                color: root.theme.muted
                font.pixelSize: 10
            }
            Text {
                text: "00:00         00:10         00:20         00:30         00:40"
                Layout.fillWidth: true
                color: root.theme.muted
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: [
                { "name": "Video 1", "hint": "Drop video clips here (available later)" },
                { "name": "Audio 1", "hint": "Drop an audio track here (available later)" }
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                Rectangle {
                    Layout.preferredWidth: 104
                    Layout.fillHeight: true
                    color: root.theme.raised
                    radius: 2
                    Text {
                        text: modelData.name
                        anchors.centerIn: parent
                        color: root.theme.text
                        font.pixelSize: 11
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.theme.canvas
                    border.color: root.theme.border
                    radius: 2
                    Text {
                        text: modelData.hint
                        anchors.centerIn: parent
                        color: root.theme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
