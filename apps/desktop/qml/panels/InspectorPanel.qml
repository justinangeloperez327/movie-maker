import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    required property var palette
    color: palette.surface

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        Text {
            text: "Properties"
            color: root.palette.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.palette.border
        }
        Text {
            text: "Nothing selected"
            color: root.palette.text
            font.pixelSize: 12
            font.weight: Font.Medium
        }
        Text {
            text: "When a clip is selected, its editing controls and metadata will appear here."
            color: root.palette.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
        Text {
            text: "Inspector · Group 2"
            color: root.palette.muted
            font.pixelSize: 11
        }
    }
}
