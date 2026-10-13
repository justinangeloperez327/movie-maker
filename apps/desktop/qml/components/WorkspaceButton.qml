import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    required property string symbol
    required property string caption
    required property var theme
    property bool selected: false

    implicitWidth: 64
    implicitHeight: 62
    flat: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: caption

    contentItem: ColumnLayout {
        spacing: 4
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: control.symbol
            color: control.selected ? control.theme.accent : control.theme.text
            font.pixelSize: 17
            font.bold: true
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: control.caption
            color: control.selected ? control.theme.text : control.theme.muted
            font.pixelSize: 10
            font.weight: control.selected ? Font.DemiBold : Font.Normal
        }
    }
    background: Rectangle {
        radius: 2
        color: control.selected ? control.theme.raised :
               control.hovered ? control.theme.hover : "transparent"
        Rectangle {
            width: 3
            height: parent.height - 12
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: control.selected ? control.theme.accent : "transparent"
        }
    }
}
