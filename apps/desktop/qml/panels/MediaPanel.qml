import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property var palette
    required property string section
    color: palette.surface

    readonly property string sectionTitle:
        section === "media" ? "Project media" :
        section === "effects" ? "Effects" :
        section === "transitions" ? "Transitions" : "Titles"

    readonly property string sectionDescription:
        section === "media" ? "Videos, photos and soundtracks will appear here after import is implemented." :
        section === "effects" ? "Visual effects are planned for the editing milestones." :
        section === "transitions" ? "Clip transitions will be available after the timeline engine." :
                               "Text and title overlays will arrive with editing tools."

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.sectionTitle
                color: root.palette.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            SmallAction {
                palette: root.palette
                text: "Import"
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Media importing will be implemented in Group 4."
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: root.palette.raised
            radius: 2
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Search (coming later)"
                color: root.palette.muted
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: root.palette.border
            radius: 2

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, 240)
                spacing: 12
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 44
                    height: 44
                    radius: 2
                    color: root.palette.raised
                    Text {
                        anchors.centerIn: parent
                        text: root.section === "media" ? "+" : root.section === "titles" ? "T" : "✦"
                        color: root.palette.accent
                        font.pixelSize: 22
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.section === "media" ? "Your media library is empty" : "Coming in a later group"
                    color: root.palette.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.sectionDescription
                    color: root.palette.muted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
        Text {
            text: "0 items"
            color: root.palette.muted
            font.pixelSize: 11
        }
    }
}
