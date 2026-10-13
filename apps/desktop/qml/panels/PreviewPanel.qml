import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../components"

Rectangle {
    id: root
    required property var theme
    required property url sourceUrl
    required property string sourceKind
    required property string sourceName
    color: theme.canvas

    readonly property bool motionMedia: sourceKind === "video" || sourceKind === "audio"
    readonly property bool canSeek: motionMedia && playback.seekable
    property bool draggingSeek: false

    function formatTime(milliseconds) {
        const seconds = Math.max(0, Math.floor(milliseconds / 1000))
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        const remainder = seconds % 60
        const pad = function(value) { return value < 10 ? "0" + value : String(value) }
        return hours > 0 ? hours + ":" + pad(minutes) + ":" + pad(remainder)
                         : pad(minutes) + ":" + pad(remainder)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: root.sourceName.length > 0 ? root.sourceName : "Source preview"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.theme.text
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            Text {
                text: root.sourceKind === "image" ? "Image" :
                      root.motionMedia ? playback.status : "No source selected"
                font.pixelSize: 11
                color: root.theme.muted
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 145
            color: root.theme.video
            radius: 2
            clip: true
            border.color: root.theme.border

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                anchors.margins: 1
                visible: root.sourceKind === "video"
                fillMode: VideoOutput.PreserveAspectFit
                Component.onCompleted: {
                    if (!playback.attachVideoSink(videoOutput.videoSink)) {
                        console.error("Could not attach native video sink")
                    }
                }
            }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                visible: root.sourceKind === "image"
                source: visible ? root.sourceUrl : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.sourceKind === "audio"
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "♫"
                    font.pixelSize: 32
                    color: "#d33b43"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Audio preview"
                    font.pixelSize: 12
                    color: "#a8adb6"
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.sourceUrl.toString().length
                text: "Select an imported video, audio file, or image"
                font.pixelSize: 12
                color: "#989da6"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width - 20
            }

            Text {
                anchors.centerIn: parent
                visible: root.motionMedia && playback.errorString.length > 0
                text: playback.errorString
                font.pixelSize: 12
                color: "#f8b4b8"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 24
            }
        }

        Slider {
            id: seekSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            from: 0
            to: Math.max(1, playback.duration)
            enabled: root.canSeek && playback.duration > 0
            onMoved: {
                if (enabled) playback.seekMs(Math.round(value))
            }
            Binding {
                target: seekSlider
                property: "value"
                value: playback.position
                when: !seekSlider.pressed
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.formatTime(playback.position)
                color: root.theme.text
                font.pixelSize: 11
                font.family: "Consolas"
                Layout.preferredWidth: 52
            }
            Item { Layout.fillWidth: true }
            SmallAction {
                theme: root.theme
                text: "◀ Frame"
                enabled: root.sourceKind === "video" && playback.seekable
                onClicked: playback.stepFrame(-1)
                ToolTip.visible: hovered
                ToolTip.text: "Approximate frame step (not frame-accurate)"
            }
            SmallAction {
                theme: root.theme
                text: playback.playing ? "Pause" : "Play"
                primary: true
                enabled: root.motionMedia && root.sourceUrl.toString().length > 0
                onClicked: playback.toggle()
            }
            SmallAction {
                theme: root.theme
                text: "Frame ▶"
                enabled: root.sourceKind === "video" && playback.seekable
                onClicked: playback.stepFrame(1)
                ToolTip.visible: hovered
                ToolTip.text: "Approximate frame step (not frame-accurate)"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.formatTime(playback.duration)
                color: root.theme.muted
                font.pixelSize: 11
                font.family: "Consolas"
                Layout.preferredWidth: 52
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SmallAction {
                theme: root.theme
                text: playback.muted ? "Unmute" : "Mute"
                enabled: root.motionMedia
                onClicked: playback.muted = !playback.muted
            }
            Slider {
                Layout.preferredWidth: 100
                Layout.maximumWidth: 130
                from: 0
                to: 1
                enabled: root.motionMedia
                value: playback.volume
                onMoved: playback.volume = value
                ToolTip.visible: hovered
                ToolTip.text: "Preview volume"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Speed"
                color: root.theme.muted
                font.pixelSize: 11
            }
            ComboBox {
                id: speedSelect
                model: ["0.5×", "1×", "1.5×", "2×"]
                currentIndex: 1
                enabled: root.motionMedia
                implicitWidth: 85
                implicitHeight: 28
                onActivated: {
                    playback.playbackRate = [0.5, 1.0, 1.5, 2.0][currentIndex]
                }
            }
        }
    }
}
