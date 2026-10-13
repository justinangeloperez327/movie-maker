import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "qml/theme"
import "qml/components"
import "qml/panels"

ApplicationWindow {
    id: window
    objectName: "movieMakerMainWindow"
    visible: true
    width: 1320
    height: 820
    minimumWidth: 980
    minimumHeight: 650
    title: "Movie Maker"
    color: colors.canvas

    AppPalette {
        id: colors
        darkMode: appBackend.darkMode
    }

    function openSection(section) {
        appBackend.activeSection = section
        appBackend.mediaPanelVisible = true
    }

    Shortcut { sequence: "Ctrl+1"; onActivated: window.openSection("media") }
    Shortcut { sequence: "Ctrl+2"; onActivated: window.openSection("effects") }
    Shortcut { sequence: "Ctrl+3"; onActivated: window.openSection("transitions") }
    Shortcut { sequence: "Ctrl+4"; onActivated: window.openSection("titles") }
    Shortcut { sequence: "Ctrl+B"; onActivated: appBackend.mediaPanelVisible = !appBackend.mediaPanelVisible }
    Shortcut { sequence: "Ctrl+I"; onActivated: appBackend.inspectorVisible = !appBackend.inspectorVisible }
    Shortcut { sequence: "Ctrl+L"; onActivated: appBackend.timelineVisible = !appBackend.timelineVisible }
    Shortcut { sequence: "Ctrl+Shift+D"; onActivated: appBackend.darkMode = !appBackend.darkMode }
    Shortcut { sequence: "Ctrl+0"; onActivated: appBackend.restoreDefaultWorkspace() }
    Shortcut {
        sequence: "F11"
        onActivated: {
            if (window.visibility === Window.FullScreen) window.showNormal()
            else window.showFullScreen()
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.visibility === Window.FullScreen) window.showNormal()
        }
    }
    Shortcut { sequence: "F1"; onActivated: aboutDialog.open() }

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text: "New project"; enabled: false }
            MenuItem { text: "Open project"; enabled: false }
            MenuItem { text: "Save project"; enabled: false }
            MenuSeparator {}
            MenuItem { text: "Export"; enabled: false }
            MenuSeparator {}
            MenuItem { text: "Exit"; onTriggered: window.close() }
        }
        Menu {
            title: "View"
            MenuItem {
                text: appBackend.mediaPanelVisible ? "Hide media browser (Ctrl+B)" : "Show media browser (Ctrl+B)"
                onTriggered: appBackend.mediaPanelVisible = !appBackend.mediaPanelVisible
            }
            MenuItem {
                text: appBackend.inspectorVisible ? "Hide inspector (Ctrl+I)" : "Show inspector (Ctrl+I)"
                onTriggered: appBackend.inspectorVisible = !appBackend.inspectorVisible
            }
            MenuItem {
                text: appBackend.timelineVisible ? "Hide timeline (Ctrl+L)" : "Show timeline (Ctrl+L)"
                onTriggered: appBackend.timelineVisible = !appBackend.timelineVisible
            }
            MenuSeparator {}
            MenuItem {
                text: appBackend.darkMode ? "Light appearance (Ctrl+Shift+D)" : "Dark appearance (Ctrl+Shift+D)"
                onTriggered: appBackend.darkMode = !appBackend.darkMode
            }
            MenuItem {
                text: "Restore default workspace (Ctrl+0)"
                onTriggered: appBackend.restoreDefaultWorkspace()
            }
            MenuSeparator {}
            MenuItem {
                text: window.visibility === Window.FullScreen ? "Exit fullscreen (F11)" : "Fullscreen (F11)"
                onTriggered: {
                    if (window.visibility === Window.FullScreen) window.showNormal()
                    else window.showFullScreen()
                }
            }
        }
        Menu {
            title: "Help"
            MenuItem { text: "About Movie Maker (F1)"; onTriggered: aboutDialog.open() }
        }
    }

    header: Rectangle {
        height: 54
        color: colors.surface
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Rectangle {
                width: 30
                height: 30
                radius: 2
                color: colors.accent
                Text {
                    anchors.centerIn: parent
                    text: "M"
                    font.pixelSize: 17
                    font.bold: true
                    color: "white"
                }
            }
            Text {
                text: "Movie Maker"
                color: colors.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Rectangle { width: 1; height: 21; color: colors.border }
            Text {
                text: "Untitled workspace"
                color: colors.muted
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            SmallAction {
                palette: colors
                text: appBackend.darkMode ? "Light mode" : "Dark mode"
                onClicked: appBackend.darkMode = !appBackend.darkMode
            }
            SmallAction {
                palette: colors
                text: "Export"
                primary: true
                enabled: false
                ToolTip.visible: hovered
                ToolTip.text: "Export will be implemented after the editing engine."
            }
        }
    }

    SplitView {
        id: verticalWorkspace
        anchors.fill: parent
        orientation: Qt.Vertical
        handle: Rectangle {
            implicitHeight: 5
            color: SplitHandle.hovered ? colors.accent : colors.border
        }

        Item {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 280

            SplitView {
                anchors.fill: parent
                orientation: Qt.Horizontal
                handle: Rectangle {
                    implicitWidth: 5
                    color: SplitHandle.hovered ? colors.accent : colors.border
                }

                Rectangle {
                    color: colors.surface
                    SplitView.preferredWidth: 68
                    SplitView.minimumWidth: 68
                    SplitView.maximumWidth: 68

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 10
                        spacing: 4

                        Repeater {
                            model: [
                                { "section": "media", "symbol": "M", "caption": "Media" },
                                { "section": "effects", "symbol": "E", "caption": "Effects" },
                                { "section": "transitions", "symbol": "↔", "caption": "Transitions" },
                                { "section": "titles", "symbol": "T", "caption": "Titles" }
                            ]
                            delegate: WorkspaceButton {
                                required property var modelData
                                Layout.fillWidth: true
                                symbol: modelData.symbol
                                caption: modelData.caption
                                palette: colors
                                selected: appBackend.activeSection === modelData.section
                                onClicked: window.openSection(modelData.section)
                            }
                        }
                        Item { Layout.fillHeight: true }
                        WorkspaceButton {
                            Layout.fillWidth: true
                            symbol: "?"
                            caption: "About"
                            palette: colors
                            onClicked: aboutDialog.open()
                        }
                    }
                }

                MediaPanel {
                    palette: colors
                    section: appBackend.activeSection
                    visible: appBackend.mediaPanelVisible
                    SplitView.preferredWidth: 280
                    SplitView.minimumWidth: 225
                }

                PreviewPanel {
                    palette: colors
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 320
                }

                InspectorPanel {
                    palette: colors
                    visible: appBackend.inspectorVisible
                    SplitView.preferredWidth: 265
                    SplitView.minimumWidth: 210
                }
            }
        }

        TimelinePanel {
            objectName: "timelineDock"
            palette: colors
            visible: appBackend.timelineVisible
            SplitView.minimumHeight: 155
            SplitView.preferredHeight: 245
        }
    }

    footer: Rectangle {
        height: 28
        color: colors.surface
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Text {
                text: "Workspace ready · Media editing is not yet implemented"
                color: colors.muted
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: "Rust core " + appBackend.coreVersion
                color: colors.muted
                font.pixelSize: 11
            }
        }
    }

    Dialog {
        id: aboutDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: "About Movie Maker"
        standardButtons: Dialog.Close
        width: 390
        padding: 20
        background: Rectangle {
            color: colors.surface
            border.color: colors.border
            radius: 3
        }
        contentItem: ColumnLayout {
            spacing: 12
            Text {
                text: "Movie Maker"
                color: colors.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Text {
                text: "A native Windows video editor in development."
                color: colors.muted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Text {
                text: "Rust " + appBackend.coreVersion + " · C++20 · Qt Quick"
                color: colors.text
                font.pixelSize: 11
            }
            Text {
                text: "Group 2: desktop workspace. Playback and editing have not been implemented."
                color: colors.muted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
