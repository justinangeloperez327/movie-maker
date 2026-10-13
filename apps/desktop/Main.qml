import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
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
    title: (appBackend.hasProject ? appBackend.projectName : "Movie Maker") + (appBackend.isModified ? " *" : "") + " — Movie Maker"
    color: colors.canvas

    AppPalette {
        id: colors
        darkMode: appBackend.darkMode
    }

    property string pendingAction: ""
    property bool bypassClose: false

    function openSection(section) {
        appBackend.activeSection = section
        appBackend.mediaPanelVisible = true
    }

    function requestAction(action) {
        pendingAction = action
        if (appBackend.isModified) unsavedDialog.open()
        else performPending()
    }

    function performPending() {
        const action = pendingAction
        pendingAction = ""
        if (action === "new") newProjectDialog.open()
        else if (action === "open") openFileDialog.open()
        else if (action === "exit") {
            bypassClose = true
            window.close()
        }
    }

    function saveNow() {
        if (!appBackend.hasProject) return
        if (appBackend.projectPath.length === 0) saveFileDialog.open()
        else if (appBackend.saveProject() && pendingAction.length > 0) performPending()
    }

    onClosing: function(close) {
        if (!bypassClose && appBackend.isModified) {
            close.accepted = false
            requestAction("exit")
        }
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
    Shortcut { sequence: "Space"; enabled: appBackend.previewKind === "video" || appBackend.previewKind === "audio"; onActivated: playback.toggle() }
    Shortcut { sequence: "Left"; enabled: appBackend.previewKind === "video"; onActivated: playback.stepFrame(-1) }
    Shortcut { sequence: "Right"; enabled: appBackend.previewKind === "video"; onActivated: playback.stepFrame(1) }

    Connections {
        target: appBackend
        function onPreviewChanged() {
            playback.load(appBackend.previewSource, appBackend.previewKind)
        }
    }
    Shortcut { sequence: "Ctrl+N"; onActivated: window.requestAction("new") }
    Shortcut {
        sequence: "Ctrl+M"
        enabled: appBackend.hasProject && !appBackend.importing
        onActivated: mediaImportDialog.open()
    }
    Shortcut { sequence: "Ctrl+O"; onActivated: window.requestAction("open") }
    Shortcut { sequence: "Ctrl+S"; enabled: appBackend.hasProject; onActivated: window.saveNow() }
    Shortcut {
        sequence: "Ctrl+Shift+S"
        enabled: appBackend.hasProject
        onActivated: saveFileDialog.open()
    }

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text: "New project (Ctrl+N)"; onTriggered: window.requestAction("new") }
            MenuItem { text: "Open project (Ctrl+O)"; onTriggered: window.requestAction("open") }
            MenuSeparator {}
            MenuItem {
                text: "Save project (Ctrl+S)"
                enabled: appBackend.hasProject
                onTriggered: window.saveNow()
            }
            MenuItem {
                text: "Save project as (Ctrl+Shift+S)"
                enabled: appBackend.hasProject
                onTriggered: saveFileDialog.open()
            }
            MenuSeparator {}
            MenuItem {
                text: "Import media (Ctrl+M)"
                enabled: appBackend.hasProject && !appBackend.importing
                onTriggered: mediaImportDialog.open()
            }
            MenuItem { text: "Export"; enabled: false }
            MenuSeparator {}
            MenuItem { text: "Exit"; onTriggered: window.requestAction("exit") }
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
                text: appBackend.hasProject ? appBackend.projectName + (appBackend.isModified ? "  •  Unsaved" : "") : "No project open"
                color: colors.muted
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            SmallAction {
                theme: colors
                text: appBackend.darkMode ? "Light mode" : "Dark mode"
                onClicked: appBackend.darkMode = !appBackend.darkMode
            }
            SmallAction {
                theme: colors
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
                                theme: colors
                                selected: appBackend.activeSection === modelData.section
                                onClicked: window.openSection(modelData.section)
                            }
                        }
                        Item { Layout.fillHeight: true }
                        WorkspaceButton {
                            Layout.fillWidth: true
                            symbol: "?"
                            caption: "About"
                            theme: colors
                            onClicked: aboutDialog.open()
                        }
                    }
                }

                MediaPanel {
                    theme: colors
                    mediaCount: appBackend.mediaCount
                    mediaItems: appBackend.mediaItems
                    hasProject: appBackend.hasProject
                    importing: appBackend.importing
                    pendingImports: appBackend.pendingImports
                    onImportRequested: mediaImportDialog.open()
                    selectedMediaId: appBackend.previewId
                    onPreviewRequested: function(mediaId) {
                        appBackend.selectPreviewMedia(mediaId)
                    }
                    section: appBackend.activeSection
                    visible: appBackend.mediaPanelVisible
                    SplitView.preferredWidth: 280
                    SplitView.minimumWidth: 225
                }

                PreviewPanel {
                    theme: colors
                    sourceUrl: appBackend.previewSource
                    sourceKind: appBackend.previewKind
                    sourceName: appBackend.previewName
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 320
                }

                InspectorPanel {
                    theme: colors
                    hasProject: appBackend.hasProject
                    projectName: appBackend.projectName
                    trackCount: appBackend.trackCount
                    visible: appBackend.inspectorVisible
                    SplitView.preferredWidth: 265
                    SplitView.minimumWidth: 210
                }
            }
        }

        TimelinePanel {
            objectName: "timelineDock"
            theme: colors
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
                text: appBackend.importing ? "Indexing " + appBackend.pendingImports + " media file(s)…"
                      : appBackend.hasProject
                      ? (appBackend.isModified ? "Unsaved project" : "Saved project") +
                        " · " + appBackend.mediaCount + " media · " + appBackend.trackCount + " tracks"
                      : "Create or open a project to begin"
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

    FileDialog {
        id: mediaImportDialog
        title: "Import media"
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "Media files (*.mp4 *.mov *.mkv *.avi *.webm *.mp3 *.wav *.flac *.m4a *.aac *.ogg *.png *.jpg *.jpeg *.webp *.bmp *.gif *.tif *.tiff)",
            "All files (*)"
        ]
        onAccepted: appBackend.importMedia(selectedFiles)
    }

    FileDialog {
        id: openFileDialog
        title: "Open Movie Maker project"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Movie Maker Projects (*.mmproj)"]
        onAccepted: appBackend.openProject(selectedFile)
    }

    FileDialog {
        id: saveFileDialog
        title: "Save Movie Maker project"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "mmproj"
        nameFilters: ["Movie Maker Projects (*.mmproj)"]
        onAccepted: {
            if (appBackend.saveProjectAs(selectedFile) && window.pendingAction.length > 0)
                window.performPending()
        }
        onRejected: window.pendingAction = ""
    }

    Dialog {
        id: newProjectDialog
        modal: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        title: "New project"
        width: 420
        padding: 18
        background: Rectangle { color: colors.surface; border.color: colors.border; radius: 2 }
        onOpened: projectNameField.forceActiveFocus()
        contentItem: ColumnLayout {
            spacing: 10
            Text {
                text: "Project name"
                color: colors.text
                font.pixelSize: 12
            }
            TextField {
                id: projectNameField
                Layout.fillWidth: true
                text: "Untitled Project"
                selectByMouse: true
                maximumLength: 200
                color: colors.text
                background: Rectangle {
                    implicitHeight: 38
                    color: colors.raised
                    border.color: colors.border
                    radius: 2
                }
                onAccepted: {
                    if (text.trim().length > 0 && appBackend.createProject(text))
                        newProjectDialog.close()
                }
            }
        }
        footer: RowLayout {
            spacing: 8
            Item { Layout.fillWidth: true }
            SmallAction {
                theme: colors
                text: "Cancel"
                onClicked: newProjectDialog.close()
            }
            SmallAction {
                theme: colors
                text: "Create project"
                primary: true
                enabled: projectNameField.text.trim().length > 0
                onClicked: {
                    if (appBackend.createProject(projectNameField.text))
                        newProjectDialog.close()
                }
            }
        }
    }

    Dialog {
        id: unsavedDialog
        title: "Unsaved project"
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 440
        padding: 18
        background: Rectangle { color: colors.surface; border.color: colors.border; radius: 2 }
        contentItem: Text {
            width: 400
            text: "Save your changes to \"" + appBackend.projectName + "\" before continuing?"
            wrapMode: Text.WordWrap
            color: colors.text
            font.pixelSize: 13
        }
        footer: RowLayout {
            spacing: 8
            SmallAction {
                theme: colors
                text: "Discard"
                onClicked: { unsavedDialog.close(); window.performPending() }
            }
            Item { Layout.fillWidth: true }
            SmallAction {
                theme: colors
                text: "Cancel"
                onClicked: { window.pendingAction = ""; unsavedDialog.close() }
            }
            SmallAction {
                theme: colors
                text: "Save"
                primary: true
                onClicked: { unsavedDialog.close(); window.saveNow() }
            }
        }
    }

    Connections {
        target: appBackend
        function onOperationFailed(detail) {
            errorDialog.errorText = detail
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        property string errorText: ""
        title: "Project error"
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 450
        padding: 18
        standardButtons: Dialog.Ok
        background: Rectangle { color: colors.surface; border.color: colors.border; radius: 2 }
        contentItem: Text {
            text: errorDialog.errorText
            wrapMode: Text.WordWrap
            color: colors.text
            font.pixelSize: 12
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
                text: "Group 5: native media preview playback. Timeline editing is not yet implemented."
                color: colors.muted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
