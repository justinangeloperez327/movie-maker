# Movie Maker architecture

## Goals

A native, Windows-first, offline video editor with a memory-safe editing model and hardware-efficient native media pipeline.

## Group 5 implementation

```text
Qt Quick / QML Main window
        |
        v
C++ QObject AppBackend
        |
        v
CXX-generated C++ glue + Rust staticlib
        |
        v
Rust editor-bridge -> Rust editor-core
```

The `editor-project` crate owns a versioned document schema with media references, rational frame rates and timeline tracks. A Rust opaque `ProjectSession` is held in the C++ desktop backend through CXX. Rust validates documents and generates canonical JSON; Qt saves them through `QSaveFile` for safe replacement. Failed opens never replace the active project. Qt handles UI rendering and event dispatch. The QObject host owns persisted workspace state and exposes it to QML through notifyable properties; this is presentation state only, not editable project data. CXX marshals a small, explicit bridge API. The foundation intentionally does **not** pretend to play video.

## Media indexing bridge (Group 4)

A C++ QtConcurrent worker runs separate `ffprobe` and `ffmpeg` executables for metadata, preview thumbnails, and short audio waveform representations. Import completion is marshalled back to the Qt UI thread and registered with the mutable Rust ProjectSession via CXX. The media references, codec metadata, dimensions, and duration are persisted in .mmproj. The worker never modifies original media, uses bounded process timeouts, and indexes files asynchronously.

This external-process integration is a bootstrapping solution for media indexing only. It is not the final playback or export pipeline. Executable dependencies must be present in PATH and are not bundled in this group.

## Native source playback subsystem (Group 5)

`PlaybackController` is a C++ QObject with a `QMediaPlayer` and `QAudioOutput`. The Qt Quick `VideoOutput` exposes its `QVideoSink`, which the controller attaches to the player. The controller handles local-file source loading, playback, pausing, seeking, nominal-rate frame stepping, volume, mute, rate control, media errors and source clearing. Qt Multimedia defaults to the FFmpeg media backend on supported Windows builds; its backend is responsible for A/V synchronization.

The Rust-backed `ProjectSession` remains the authoritative owner of which media IDs belong to a project. The selected source is validated against those IDs by the desktop `AppBackend`. Selecting a media item emits a URL/kind change; the native playback controller loads that source. Opening another project clears the selection and playback source so references cannot leak across projects.

This preview plays a **single imported source file**, not the timeline. Qt Multimedia does not expose guaranteed frame-accurate stepping through `QMediaPlayer`; frame step is best-effort seeking using nominal frame rate.

## Planned native media subsystem

Future groups will introduce a C++ multimedia adapter using FFmpeg libraries for demuxing, decoding, encoding, and muxing. Direct3D 11 will be the first Windows GPU path. The Rust core will own logical edit state and export scheduling; the native layer will retain decoded frames and GPU resource handles to avoid repetitive cross-FFI frame copies. Audio clock accuracy, VFR inputs, cache boundaries, and cancellation behavior require dedicated tests.

CXX-Qt is an option for Rust-backed QObjects later, when editing models need to be exposed directly to QML. Group 1 uses ordinary QObject/CXX rather than introducing unnecessary QObject ownership complexity.

## Concurrency and lifetime policy

- Qt/QML objects are touched only on the required Qt thread.
- Long-running operations cannot block the UI event loop.
- Rust is the single source of truth for editable project state.
- Native libraries own their internal buffers until released through explicit APIs.
- Bridge values should be small (metadata, IDs, timestamps, command results); avoid copying full video frames.
- Tests are required at both sides of bridge boundaries.

## Licensing

Qt modules have different LGPL/GPL/commercial licensing options, and future FFmpeg builds may include components with distinct licenses and codec obligations. Before publishing binaries, review exact Qt modules, dynamically linked dependencies, codecs, packaging, and required notices. No FFmpeg binaries are included in Group 1.

## Phased delivery

1. Foundation: native executable, Qt shell, CXX bridge, Windows CI.
2. Project/media import and timeline state.
3. Playback, export, GPU integration.
4. Effects, recovery, profiling, release testing.

No public v1.0.0 claim will be made until the editor actually supports end-to-end editing and passes release validation.
