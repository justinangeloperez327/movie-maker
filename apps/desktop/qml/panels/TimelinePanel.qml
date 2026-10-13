import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property var palette
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
                color: root.palette.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Rectangle { width: 1; height: 18; color: root.palette.border }
            SmallAction {
                palette: root.palette
                text: "Split"
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Timeline splitting is scheduled for Group 6."
            }
            SmallAction {
                palette: root.palette
                text: "Trim"
                enabled: false
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Zoom"
                color: root.palette.muted
                font.pixelSize: 11
            }
            SmallAction {
                palette: root.palette
                text: "−"
                enabled: false
            }
            SmallAction {
                palette: root.palette
                text: "+"
                enabled: false
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.palette.border }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "TRACK"
                Layout.preferredWidth: 104
                color: root.palette.muted
                font.pixelSize: 10
            }
            Text {
                text: "00:00         00:10         00:20         00:30         00:40"
                Layout.fillWidth: true
                color: root.palette.muted
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
                    color: root.palette.raised
                    radius: 2
                    Text {
                        text: modelData.name
                        anchors.centerIn: parent
                        color: root.palette.text
                        font.pixelSize: 11
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.palette.canvas
                    border.color: root.palette.border
                    radius: 2
                    Text {
                        text: modelData.hint
                        anchors.centerIn: parent
                        color: root.palette.muted
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
