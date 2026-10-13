# Movie Maker project format — v1

A `.mmproj` file is UTF-8 JSON. The first version's required fields are `format`, `version`, `id`, `name`, `settings`, `media`, and `timeline`. The application opens only documents with `format = movie-maker-project` and `version = 1`.

## Example

```json
{
  "format": "movie-maker-project",
  "version": 1,
  "id": "32e05a13-5c1b-4dd2-9850-f4967743566c",
  "name": "My Film",
  "settings": {
    "width": 1920,
    "height": 1080,
    "frame_rate": {"numerator": 30000, "denominator": 1001},
    "audio_sample_rate": 48000
  },
  "media": [],
  "timeline": {
    "tracks": [
      {"id": "2cb160b8-4e39-467d-ad4c-a6a1334ac35b", "kind": "video", "clips": []},
      {"id": "50d92d44-e1b9-4475-bfc7-e1683863130c", "kind": "audio", "clips": []}
    ]
  }
}
```

## Model

- All project/media/track/clip identifiers are UUIDs.
- Frame rate is stored as a rational number, never a floating-point timebase.
- Timeline and source timestamps are non-negative integer **microseconds**. A clip stores `start_us`, `source_in_us`, `duration_us`, `media_id`, and `id`.
- Media references include `id`, `path`, `kind` (`video`, `audio`, `image`), and nullable `duration_us`.
- Tracks are `video` or `audio`; initial projects contain one of each.
- For the initial editing model, clips cannot overlap on the same track, and every clip must reference an existing media entry.
- Media files themselves are never embedded into projects or modified by project persistence.

## Validation and safety

Documents are limited to 16 MiB, reject malformed UTF-8 and unsupported format versions, and validate project names, video dimensions, timebase, duplicate identifiers, clip bounds, source references, and track compatibility. Unknown object fields are rejected in v1.

Saving uses **QSaveFile** from Qt, which writes to a temporary file and commits the result without exposing partially written project contents. The Rust library owns serialization and validation. Opening an invalid project leaves the existing session intact.

Current limitations: imported media creation, editing operations, autosave/recovery journals and migrations for future schema versions belong to later implementation groups.

## Workflow

Use File → New project, enter a name, then File → Save project as. Use File → Open project to reopen a saved document. When replacing an unsaved project or quitting, the editor offers Save / Discard / Cancel.
