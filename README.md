# Movie Maker

A Windows-first, offline-first video editor inspired by classic Windows Movie Maker.

**Technology:** Rust application core, C++20, Qt Quick/QML, CXX bridge, Qt Multimedia's native FFmpeg-backed playback, and FFmpeg command-line tools for media import indexing. A custom Direct3D compositor and multitrack rendering come in later groups.

## Current state

**Group 5 — Source playback preview.** Select a file in the media library to preview native video/audio playback, pause, seek, approximate frame-step, change speed and volume, or view still images. Qt 6 Multimedia uses FFmpeg to decode local media and synchronize audio/video. Rust still owns the versioned project model and media references. **This previews an individual source file, not the edited timeline**; multitrack playback and export are not yet implemented.

## Build on Windows

Requirements:
- Windows 10/11 x64
- Visual Studio 2022 with Desktop development with C++ (MSVC v143 and Windows SDK)
- CMake 3.26 or newer
- Rust stable with `x86_64-pc-windows-msvc` target
- Qt 6.8 or newer, MSVC 2022 64-bit build (Quick, Quick Controls and **Qt Multimedia** add-on)
- CXX bridge generator **1.0.205**, matching the Rust `cxx` crate
- FFmpeg tools (`ffmpeg.exe` and `ffprobe.exe`) installed on PATH, or specify `MOVIE_MAKER_FFMPEG_DIR` pointing to their directory

Install the code generator:

```powershell
cargo install cxxbridge-cmd --version 1.0.205 --locked
```

Configure (adjust the Qt path to match your machine):

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/Qt/6.8.3/msvc2022_64"
cmake --build build --config Release
& ".\build\Release\movie_maker.exe" --self-test
& ".\build\Release\movie_maker.exe" --project-self-test
```

To run the GUI, ensure the Qt installation's `bin` directory is on PATH (or deploy the Qt runtime DLLs using `windeployqt`). The `--self-test` command checks the actual C++ → CXX → Rust bridge and exits without showing a window.

```powershell
& ".\build\Release\movie_maker.exe"
```

Run the Rust tests:

```powershell
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

Media importing and cache details: [docs/media-import.md](docs/media-import.md). Playback controls: [docs/playback.md](docs/playback.md). Full build details: [docs/building.md](docs/building.md). Project format: [docs/project-format.md](docs/project-format.md). Architecture: [docs/architecture.md](docs/architecture.md).

## Roadmap

Next: Group 6 timeline editing, then export, advanced GPU composition, effects, recovery, and release validation. The first public stable version will be `v1.0.0` only after all release requirements are met.

## Licensing

No codec binaries are committed to this repository. Group 4's indexing requires separately installed FFmpeg tools; Group 5's playback uses Qt Multimedia and its FFmpeg runtime dependencies (Qt-distributed libraries must be packaged and licensed appropriately for distribution). Export encoding has not been implemented. Qt and future FFmpeg deployment licenses and codec obligations must be assessed before distribution. See [docs/architecture.md](docs/architecture.md).
