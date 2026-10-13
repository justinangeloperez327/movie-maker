# Source playback engine (Group 5)

## Usage

Create or open a project, import video or audio, then click an item in **Project media**. The center preview displays decoded video frames, audio playback controls, and the media duration. Still images use Qt Quick's image preview and are not sent to the video player.

- **Play / Pause:** preview button or Space.
- **Seek:** drag the position slider. Seeking is only available for seekable files.
- **Step left / right:** preview buttons or arrow keys; uses the media's nominal frame rate and is not yet frame-accurate.
- **Audio:** use Mute and the volume slider. Speed choices are 0.5×, 1×, 1.5×, or 2×.
- **Loading/errors:** current media status or native decoder errors are shown in the preview panel.

The media player reads the original local file; source files are never modified. Selecting a different source stops and replaces the active player source. Opening another project clears the preview.

## Native stack

`PlaybackController` in C++ owns `QMediaPlayer` and `QAudioOutput`. A Qt Quick `VideoOutput.videoSink` is attached to the controller so video frames are displayed by Qt's graphics pipeline, without copying them through Rust. Qt 6.8's primary media backend is FFmpeg and handles decoding/audio synchronization. Hardware acceleration is backend-, driver- and codec-dependent; this stage does not implement custom Direct3D or GPU effects.

The current playback controller is distinct from the Rust editing model: Rust authoritatively stores imported media IDs and references, and only registered local media may be selected for playback.

## Test

On Windows, with FFmpeg tools available to create test fixtures:

```powershell
& ".\build\Release\movie_maker.exe" --playback-self-test "C:\media\sample.avi" "C:\media\sample.wav"
```

GitHub Actions synthesizes both fixtures and runs the actual Qt Multimedia decoder with a C++ `QVideoSink` to verify decoded frames and playback time advancement, as well as audio loading.

## Boundaries

This is **source media preview**, not timeline-composited output. Frame stepping is approximate with the QMediaPlayer seek API, which uses millisecond timestamps. Gapless scrubbing, timeline audio mixing, arbitrary compositing, accurate frame-level stepping, performance profiling, and production codec deployment belong to subsequent groups. The external `ffprobe`/`ffmpeg` tools remain a temporary dependency for media imports.
