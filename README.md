# Movie Maker

A Windows-first, offline-first video editor inspired by classic Windows Movie Maker.

**Technology:** Rust application core, C++20, Qt 6 Quick/QML, CXX bridge, and FFmpeg command-line tools for media probing and preview indexing. Native FFmpeg libraries, real-time playback, and Direct3D rendering come in later groups.

## Current state

**Group 4 — Media import and indexing.** Import local video, image, and audio files using native Qt file dialogs. The C++ background indexer uses FFprobe to extract metadata and FFmpeg to generate cached thumbnails and audio waveform PNGs. The Rust project model stores validated media references and metadata inside versioned `.mmproj` project files. Playback, timeline editing, and export are not yet implemented.

## Build on Windows

Requirements:
- Windows 10/11 x64
- Visual Studio 2022 with Desktop development with C++ (MSVC v143 and Windows SDK)
- CMake 3.26 or newer
- Rust stable with `x86_64-pc-windows-msvc` target
- Qt 6.8 or newer, MSVC 2022 64-bit build (Quick and Quick Controls)
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

Media importing and cache details: [docs/media-import.md](docs/media-import.md). Full build details: [docs/building.md](docs/building.md). Project format: [docs/project-format.md](docs/project-format.md). Architecture: [docs/architecture.md](docs/architecture.md).

## Roadmap

Next: Group 5 playback engine, then timeline editing, export, GPU acceleration, effects, recovery, and release validation. The first public stable version will be `v1.0.0` only after all release requirements are met.

## Licensing

No FFmpeg codec binaries are bundled in this repository. Group 4 invokes a locally installed FFmpeg executable rather than linking to FFmpeg libraries. The native decoding/encoding engine will be introduced in later groups. Qt and future FFmpeg deployment licenses and codec obligations must be assessed before distribution. See [docs/architecture.md](docs/architecture.md).
