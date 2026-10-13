# Movie Maker

A Windows-first, offline-first video editor inspired by classic Windows Movie Maker.

**Technology:** Rust application core, C++20, Qt 6 Quick/QML, CXX bridge. FFmpeg and Direct3D integration are planned for subsequent implementation groups, not implemented yet.

## Current state

**Group 1 — Foundation.** The repository contains a native Qt desktop shell with a real CXX connection to a Rust core, a Rust unit test, and a Windows build workflow. Import, playback, editing, and exporting are not yet implemented.

## Build on Windows

Requirements:
- Windows 10/11 x64
- Visual Studio 2022 with Desktop development with C++ (MSVC v143 and Windows SDK)
- CMake 3.26 or newer
- Rust stable with `x86_64-pc-windows-msvc` target
- Qt 6.8 or newer, MSVC 2022 64-bit build (Quick and Quick Controls)
- CXX bridge generator **1.0.205**, matching the Rust `cxx` crate

Install the code generator:

```powershell
cargo install cxxbridge-cmd --version 1.0.205 --locked
```

Configure (adjust the Qt path to match your machine):

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/Qt/6.8.3/msvc2022_64"
cmake --build build --config Release
& ".\build\apps\desktop\Release\movie_maker.exe" --self-test
```

To run the GUI, ensure the Qt installation's `bin` directory is on PATH (or deploy the Qt runtime DLLs using `windeployqt`). The `--self-test` command checks the actual C++ → CXX → Rust bridge and exits without showing a window.

```powershell
& ".\build\apps\desktop\Release\movie_maker.exe"
```

Run the Rust tests:

```powershell
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

Full build details: [docs/building.md](docs/building.md). Architecture: [docs/architecture.md](docs/architecture.md).

## Roadmap

Next: media import and timeline foundation, then preview, exporting, GPU support, effects, recovery, and release validation. The first public stable version will be `v1.0.0` only after all release requirements are met.

## Licensing

No media codec binaries are bundled in this foundation. Qt and future FFmpeg deployment licenses and codec obligations must be assessed before distribution. See [docs/architecture.md](docs/architecture.md).
