# Movie Maker architecture

## Goals

A native, Windows-first, offline video editor with a memory-safe editing model and hardware-efficient native media pipeline.

## Group 3 implementation

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
