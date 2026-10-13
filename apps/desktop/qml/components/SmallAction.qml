import QtQuick
import QtQuick.Controls

ToolButton {
    id: control
    required property var palette
    property bool selected: false
    property bool primary: false

    implicitHeight: 32
    implicitWidth: Math.max(70, contentItem.implicitWidth + 22)
    focusPolicy: Qt.StrongFocus

    contentItem: Text {
        text: control.text
        font.pixelSize: 12
        font.weight: control.primary ? Font.DemiBold : Font.Normal
        color: control.primary ? "#ffffff" : control.palette.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 2
        border.width: control.primary ? 0 : 1
        border.color: control.selected ? control.palette.accent : control.palette.border
        color: control.primary ?
                   (control.hovered ? control.palette.accentHover : control.palette.accent) :
                   (control.selected || control.hovered ? control.palette.raised : control.palette.surface)
    }
}
