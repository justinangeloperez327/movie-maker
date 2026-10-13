# Windows build instructions

This foundation intentionally targets **Windows x64 and MSVC** only. Qt Quick and CXX code generation run as part of the CMake configure/build process.

## Prerequisites

1. Visual Studio 2022, including MSVC v143, Windows 10/11 SDK, and C++ desktop workloads.
2. CMake 3.26 or newer and Ninja or the Visual Studio CMake generator.
3. Rust stable toolchain with the `x86_64-pc-windows-msvc` target.
4. Qt 6.8 or newer desktop libraries built for **MSVC 2022 x64**; ensure Quick, Quick Controls and Qt Multimedia are installed.
5. CXX bridge generator `cxxbridge-cmd` **1.0.205** in PATH.
6. `ffmpeg.exe` and `ffprobe.exe` installed for media imports. The executables may be supplied through `MOVIE_MAKER_FFMPEG_DIR` pointing to their directory.

Install the matching bridge generator:

```powershell
cargo install cxxbridge-cmd --version 1.0.205 --locked
```

## Build

From a Developer PowerShell for VS 2022:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/Qt/6.8.3/msvc2022_64"
cmake --build build --config Release
& ".\build\Release\movie_maker.exe" --self-test
```

The CMake build invokes Cargo automatically. The Rust `staticlib` is linked into the native Qt executable.

For local GUI runs, put `C:\Qt\6.8.3\msvc2022_64\bin` (adjust for your installation) in PATH. For deployment packaging use `windeployqt` to collect Qt runtime libraries; this is not yet a distribution build.

## Rust validation

```powershell
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

## Bridge generation

The CMake configure step calls `cxxbridge` to generate `bridge.h`, `bridge.cpp`, and `rust/cxx.h` into the build directory. The CXX generator version **must exactly match** the version of `cxx` declared in `crates/editor-bridge/Cargo.toml`.

The `--self-test` option validates the real Rust-to-C++ string roundtrip. With the Qt runtime available, use `--ui-self-test` to ensure the QML workspace loads, with `QT_QPA_PLATFORM=offscreen` and `QT_QUICK_BACKEND=software` for headless CI. Neither option tests future multimedia functionality.

The `--project-self-test` option round-trips a new project through CXX, QSaveFile and QFile, then confirms malformed JSON does not replace the active project.

The Windows CI `--playback-self-test video.avi audio.wav` test validates that the C++ `PlaybackController` decodes real video frames through `QVideoSink`, advances playback time, loads audio, and applies mute/volume commands. The test uses Qt Multimedia's FFmpeg backend.

## Known limitations

Media import, background FFprobe metadata indexing, cached thumbnails and waveforms are implemented. Individual imported files can now be played as source previews; multitrack timeline playback, clip editing and export do not yet exist. Workspace preferences are persisted using QSettings. Continuous integration must pass before considering the foundation validated on a Windows runner.
