# Media import and indexing

Group 4 adds media import to the Qt desktop shell. Open or create a project and select **File → Import media** (Ctrl+M). Multiple local files can be selected in one batch. The media browser shows file names, codec, size, duration, preview thumbnails and waveform thumbnails when available.

## Dependencies and implementation

Requires both `ffprobe.exe` and `ffmpeg.exe`, discovered from PATH or from the directory named by `MOVIE_MAKER_FFMPEG_DIR`. They are **not downloaded or bundled automatically**.

- FFprobe emits JSON stream metadata; the C++ worker chooses a video, image or audio media type, duration, dimensions and codec.
- FFmpeg generates up to 320×180 PNG thumbnails for images/video and 640×96 PNG waveforms from the first 45 seconds of tracks with audio.
- QtConcurrent performs indexing in the background. Qt signals apply results to Rust project data on the UI thread.
- Rust validates and persists the media references in the versioned project JSON. Importing the same canonical file path again does not duplicate the entry.
- Cache filenames are keyed by source path, size and modification time and written under the Qt application cache directory; cache failures do not prevent valid media registration.
- Source media is never overwritten. Missing media on project reopening is displayed as unavailable.

## Safety and limits

Media probing has a 15-second timeout per file, preview extraction a 30-second timeout per asset. FFprobe's JSON response is capped at 1 MiB, and invalid or incomplete files are rejected without corrupting the active project. Multiple files are independently scheduled. Longer source material should not block the UI while indexing.

The waveform only visualizes the first 45 seconds. It is **not** the final audio timeline waveform renderer.

## Testing

The Windows workflow installs FFmpeg and synthesizes video and audio test fixtures. The `--media-self-test video.avi audio.wav` command checks: FFprobe metadata, preview thumbnail, waveform, duplicate-safe Rust persistence after `QSaveFile`, and successful project reopen.

## Future work

Group 5 will implement actual playback with native decoding and audio synchronization. Group 6 will introduce timeline drag/drop and edit commands. Production packaging and FFmpeg/codec licensing review remain release requirements.
