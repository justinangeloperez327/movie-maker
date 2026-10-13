import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: root
    required property var theme
    required property string section
    required property int mediaCount
    required property var mediaItems
    required property bool hasProject
    required property bool importing
    required property int pendingImports
    required property string selectedMediaId
    signal previewRequested(string mediaId)
    signal importRequested()

    color: theme.surface

    readonly property string sectionTitle:
        section === "media" ? "Project media" :
        section === "effects" ? "Effects" :
        section === "transitions" ? "Transitions" : "Titles"

    readonly property string sectionDescription:
        section === "media" ? (hasProject
           ? "Import video, photos and audio files to build your media library."
           : "Create or open a project before importing media.") :
        section === "effects" ? "Visual effects are planned for a later editing milestone." :
        section === "transitions" ? "Clip transitions will be available after the timeline engine." :
                                 "Text and title overlays will arrive with editing tools."

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.sectionTitle
                color: root.theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            SmallAction {
                theme: root.theme
                text: root.importing ? "Indexing…" : "Import"
                enabled: root.section === "media" && root.hasProject && !root.importing
                onClicked: root.importRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Import local videos, images, or audio"
            }
        }

        TextField {
            id: search
            visible: root.section === "media" && root.mediaCount > 0
            Layout.fillWidth: true
            placeholderText: "Filter project media"
            color: root.theme.text
            font.pixelSize: 12
            background: Rectangle {
                implicitHeight: 34
                color: root.theme.raised
                border.color: search.activeFocus ? root.theme.accent : root.theme.border
                radius: 2
            }
            leftPadding: 10
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: library
                anchors.fill: parent
                spacing: 6
                clip: true
                visible: root.section === "media" && root.mediaCount > 0
                model: root.mediaItems
                ScrollBar.vertical: ScrollBar { }

                delegate: Rectangle {
                    id: mediaRow
                    required property var modelData
                    readonly property bool matches:
                        search.text.length === 0 ||
                        modelData.name.toLowerCase().includes(search.text.toLowerCase())
                    width: ListView.view.width - 8
                    height: matches ? 66 : 0
                    visible: matches
                    color: hoverHandler.hovered || mediaRow.modelData.id === root.selectedMediaId
                        ? root.theme.hover : root.theme.raised
                    radius: 2
                    border.color: mediaRow.modelData.id === root.selectedMediaId
                        ? root.theme.accent : root.theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 8

                        Rectangle {
                            width: 74
                            height: 48
                            radius: 2
                            color: root.theme.canvas
                            clip: true
                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                source: mediaRow.modelData.thumbnailUrl
                                        ? mediaRow.modelData.thumbnailUrl
                                        : mediaRow.modelData.waveformUrl
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: mediaRow.modelData.kind === "audio" &&
                                         !mediaRow.modelData.waveformUrl
                                text: "♪"
                                font.pixelSize: 23
                                color: root.theme.muted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                text: mediaRow.modelData.name
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: mediaRow.modelData.missing ? root.theme.accent : root.theme.text
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }
                            Text {
                                text: mediaRow.modelData.missing
                                      ? "Missing source file"
                                      : mediaRow.modelData.subtitle
                                font.pixelSize: 10
                                color: root.theme.muted
                                Layout.fillWidth: true
                                wrapMode: Text.NoWrap
                                elide: Text.ElideRight
                            }
                        }
                    }

                    ToolTip.visible: hoverHandler.hovered
                    ToolTip.text: mediaRow.modelData.path
                    HoverHandler { id: hoverHandler }
                    TapHandler {
                        onTapped: root.previewRequested(mediaRow.modelData.id)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !library.visible
                color: "transparent"
                border.color: root.theme.border
                radius: 2
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 32, 260)
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: root.section === "media" ? "No imported media" : "Coming later"
                        color: root.theme.text
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.sectionDescription
                        color: root.theme.muted
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.mediaCount + " items"
                color: root.theme.muted
                font.pixelSize: 11
                Layout.fillWidth: true
            }
            Text {
                visible: root.importing
                text: root.pendingImports + " indexing"
                color: root.theme.accent
                font.pixelSize: 11
            }
        }
    }
}
