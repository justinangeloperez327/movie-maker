import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    required property var theme
    required property bool hasProject
    required property string projectName
    required property int trackCount
    color: palette.surface

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        Text {
            text: "Properties"
            color: root.theme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.theme.border
        }
        Text {
            text: root.hasProject ? root.projectName : "No project open"
            color: root.theme.text
            font.pixelSize: 12
            font.weight: Font.Medium
        }
        Text {
            text: root.hasProject
                  ? "Project initialized with " + root.trackCount + " tracks. Clip properties will appear here after media editing is implemented."
                  : "Create or open a project. Selected clip properties will appear here in later groups."
            color: root.theme.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
        Text {
            text: "Inspector · Group 3"
            color: root.theme.muted
            font.pixelSize: 11
        }
    }
}
