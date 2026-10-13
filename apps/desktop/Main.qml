import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "Movie Maker — Foundation"
    color: "#101114"

    property color surface: "#181a1e"
    property color raised: "#22252a"
    property color lineColor: "#34373d"
    property color textColor: "#eff0f2"
    property color mutedColor: "#a3a6ae"
    property color accentColor: "#cd3939"

    header: ToolBar {
        height: 58
        background: Rectangle { color: window.surface }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14
            Label {
                text: "MOVIE MAKER"
                font.pixelSize: 16
                font.bold: true
                color: window.textColor
            }
            Rectangle { width: 1; height: 20; color: window.lineColor }
            Label {
                text: "Foundation workspace"
                color: window.mutedColor
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            Label {
                text: appBackend.coreVersion
                color: window.mutedColor
                font.pixelSize: 12
            }
            Button {
                text: "Export"
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Export will be implemented in a later group."
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        Rectangle {
            SplitView.preferredWidth: 280
            SplitView.minimumWidth: 190
            color: window.surface
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                Label {
                    text: "Project media"
                    font.bold: true
                    color: window.textColor
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: window.raised
                    border.color: window.lineColor
                    Label {
                        anchors.centerIn: parent
                        text: "Import will be available\nin a later group."
                        horizontalAlignment: Text.AlignHCenter
                        color: window.mutedColor
                    }
                }
            }
        }

        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 350
            color: window.color
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10
                Label {
                    text: "Preview"
                    font.bold: true
                    color: window.textColor
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 220
                    color: "#090a0d"
                    border.color: window.lineColor
                    Label {
                        anchors.centerIn: parent
                        text: "Media preview not implemented"
                        color: window.mutedColor
                    }
                }
                Label {
                    text: "Engine connected: " + appBackend.engineName
                    color: window.mutedColor
                    font.pixelSize: 12
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    color: window.surface
                    border.color: window.lineColor
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        Label {
                            text: "Timeline"
                            font.bold: true
                            color: window.textColor
                        }
                        Label {
                            text: "Track editing will be implemented after media import."
                            color: window.mutedColor
                            wrapMode: Text.WordWrap
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        Rectangle {
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 190
            color: window.surface
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                Label {
                    text: "Properties"
                    font.bold: true
                    color: window.textColor
                }
                Label {
                    text: "Select an item to edit its properties."
                    color: window.mutedColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    footer: ToolBar {
        height: 28
        background: Rectangle { color: window.surface }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            text: "Rust core  •  CXX bridge  •  Qt Quick    |    Group 1: Foundation"
            font.pixelSize: 11
            color: window.mutedColor
        }
    }
}
