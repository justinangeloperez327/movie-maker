import QtQuick
import QtQuick.Controls

ToolButton {
    id: control
    required property var theme
    property bool selected: false
    property bool primary: false

    implicitHeight: 32
    implicitWidth: Math.max(70, contentItem.implicitWidth + 22)
    focusPolicy: Qt.StrongFocus

    contentItem: Text {
        text: control.text
        font.pixelSize: 12
        font.weight: control.primary ? Font.DemiBold : Font.Normal
        color: control.primary ? "#ffffff" : control.theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 2
        border.width: control.primary ? 0 : 1
        border.color: control.selected ? control.theme.accent : control.theme.border
        color: control.primary ?
                   (control.hovered ? control.theme.accentHover : control.theme.accent) :
                   (control.selected || control.hovered ? control.theme.raised : control.theme.surface)
    }
}
