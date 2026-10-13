//! Versioned and validated, platform-independent Movie Maker project documents.
//! File I/O belongs to the desktop host, which commits serialized bytes via
//! QSaveFile. The native host never edits the authoritative Rust project model.

use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use thiserror::Error;
use uuid::Uuid;

pub const PROJECT_VERSION: u32 = 1;
pub const MAX_DOCUMENT_BYTES: usize = 16 * 1024 * 1024;
const MAX_TRACKS: usize = 128;
const MAX_MEDIA: usize = 10_000;
const MAX_CLIPS_PER_TRACK: usize = 50_000;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ProjectError {
    #[error("project document exceeds 16 MiB")]
    TooLarge,
    #[error("invalid project JSON: {0}")]
    InvalidJson(String),
    #[error("unsupported project version {0}; this editor supports version 1")]
    UnsupportedVersion(u32),
    #[error("invalid project: {0}")]
    Invalid(&'static str),
    #[error("duplicate identifier in project")]
    DuplicateId,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct FrameRate {
    pub numerator: u32,
    pub denominator: u32,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectSettings {
    pub width: u32,
    pub height: u32,
    pub frame_rate: FrameRate,
    pub audio_sample_rate: u32,
}

impl Default for ProjectSettings {
    fn default() -> Self {
        Self {
            width: 1920,
            height: 1080,
            frame_rate: FrameRate {
                numerator: 30,
                denominator: 1,
            },
            audio_sample_rate: 48_000,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MediaKind {
    Video,
    Audio,
    Image,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct MediaReference {
    pub id: String,
    /// Path to original media. Later import will decide relative vs absolute policies.
    pub path: String,
    pub kind: MediaKind,
    /// Source duration in microseconds; optional for still images.
    pub duration_us: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub width: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub height: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub codec: Option<String>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TrackKind {
    Video,
    Audio,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Clip {
    pub id: String,
    pub media_id: String,
    /// Position on the timeline, in integer microseconds.
    pub start_us: u64,
    pub source_in_us: u64,
    pub duration_us: u64,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Track {
    pub id: String,
    pub kind: TrackKind,
    pub clips: Vec<Clip>,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Timeline {
    pub tracks: Vec<Track>,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectDocument {
    pub format: String,
    pub version: u32,
    pub id: String,
    pub name: String,
    pub settings: ProjectSettings,
    pub media: Vec<MediaReference>,
    pub timeline: Timeline,
}

impl ProjectDocument {
    pub fn new(name: &str) -> Result<Self, ProjectError> {
        let project = Self {
            format: "movie-maker-project".to_owned(),
            version: PROJECT_VERSION,
            id: Uuid::new_v4().to_string(),
            name: name.trim().to_owned(),
            settings: ProjectSettings::default(),
            media: Vec::new(),
            timeline: Timeline {
                tracks: vec![
                    Track {
                        id: Uuid::new_v4().to_string(),
                        kind: TrackKind::Video,
                        clips: vec![],
                    },
                    Track {
                        id: Uuid::new_v4().to_string(),
                        kind: TrackKind::Audio,
                        clips: vec![],
                    },
                ],
            },
        };
        project.validate()?;
        Ok(project)
    }

    pub fn from_json(bytes: &[u8]) -> Result<Self, ProjectError> {
        if bytes.len() > MAX_DOCUMENT_BYTES {
            return Err(ProjectError::TooLarge);
        }
        // Check the version before deserialize so older/newer versions fail clearly.
        let value: serde_json::Value =
            serde_json::from_slice(bytes).map_err(|e| ProjectError::InvalidJson(e.to_string()))?;
        let version = value.get("version").and_then(serde_json::Value::as_u64);
        match version {
            Some(1) => {}
            Some(v) => {
                return Err(ProjectError::UnsupportedVersion(
                    u32::try_from(v).unwrap_or(u32::MAX),
                ))
            }
            None => return Err(ProjectError::Invalid("missing or invalid version")),
        }
        let project: Self =
            serde_json::from_value(value).map_err(|e| ProjectError::InvalidJson(e.to_string()))?;
        project.validate()?;
        Ok(project)
    }

    pub fn to_json(&self) -> Result<String, ProjectError> {
        self.validate()?;
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| ProjectError::InvalidJson(e.to_string()))?;
        if json.len() > MAX_DOCUMENT_BYTES {
            return Err(ProjectError::TooLarge);
        }
        Ok(format!("{json}\n"))
    }

    pub fn validate(&self) -> Result<(), ProjectError> {
        if self.format != "movie-maker-project" {
            return Err(ProjectError::Invalid("wrong document format"));
        }
        if self.version != PROJECT_VERSION {
            return Err(ProjectError::UnsupportedVersion(self.version));
        }
        check_id(&self.id)?;
        if self.name.trim().is_empty()
            || self.name.chars().count() > 200
            || self.name.chars().any(char::is_control)
        {
            return Err(ProjectError::Invalid(
                "project name must be 1–200 printable characters",
            ));
        }
        let settings = &self.settings;
        if settings.width == 0
            || settings.height == 0
            || settings.width > 16384
            || settings.height > 16384
        {
            return Err(ProjectError::Invalid("video dimensions out of range"));
        }
        if settings.frame_rate.denominator == 0
            || settings.frame_rate.numerator == 0
            || (settings.frame_rate.numerator as f64 / settings.frame_rate.denominator as f64)
                > 240.0
            || (settings.frame_rate.numerator as f64 / settings.frame_rate.denominator as f64) < 1.0
        {
            return Err(ProjectError::Invalid(
                "frame rate must be between 1 and 240 fps",
            ));
        }
        if !matches!(
            settings.audio_sample_rate,
            32000 | 44100 | 48000 | 96000 | 192000
        ) {
            return Err(ProjectError::Invalid(
                "unsupported project audio sample rate",
            ));
        }
        if self.media.len() > MAX_MEDIA {
            return Err(ProjectError::Invalid("too many media references"));
        }
        if self.timeline.tracks.len() > MAX_TRACKS {
            return Err(ProjectError::Invalid("too many tracks"));
        }

        let mut ids = HashSet::new();
        ids.insert(self.id.as_str());
        let mut media_ids = HashSet::new();
        let mut media_by_id = std::collections::HashMap::new();
        for media in &self.media {
            check_id(&media.id)?;
            if !ids.insert(media.id.as_str()) {
                return Err(ProjectError::DuplicateId);
            }
            media_ids.insert(media.id.as_str());
            media_by_id.insert(media.id.as_str(), media);
            if media.width.is_some_and(|value| value == 0 || value > 16384)
                || media
                    .height
                    .is_some_and(|value| value == 0 || value > 16384)
                || media.codec.as_ref().is_some_and(|value| {
                    value.is_empty() || value.len() > 64 || value.chars().any(char::is_control)
                })
            {
                return Err(ProjectError::Invalid("invalid imported media metadata"));
            }
            if media.path.is_empty()
                || media.path.len() > 32767
                || media.path.chars().any(char::is_control)
            {
                return Err(ProjectError::Invalid("invalid media path"));
            }
        }

        for track in &self.timeline.tracks {
            check_id(&track.id)?;
            if !ids.insert(track.id.as_str()) {
                return Err(ProjectError::DuplicateId);
            }
            if track.clips.len() > MAX_CLIPS_PER_TRACK {
                return Err(ProjectError::Invalid("too many clips on track"));
            }
            let mut clips = track.clips.iter().collect::<Vec<_>>();
            clips.sort_unstable_by_key(|clip| clip.start_us);
            let mut track_end = 0u64;
            for clip in clips {
                check_id(&clip.id)?;
                if !ids.insert(clip.id.as_str()) {
                    return Err(ProjectError::DuplicateId);
                }
                if !media_ids.contains(clip.media_id.as_str()) {
                    return Err(ProjectError::Invalid("clip refers to nonexistent media"));
                }
                let media = media_by_id[clip.media_id.as_str()];
                if matches!(
                    (track.kind, media.kind),
                    (TrackKind::Audio, MediaKind::Image)
                ) {
                    return Err(ProjectError::Invalid(
                        "image cannot be placed on audio track",
                    ));
                }
                if matches!(
                    (track.kind, media.kind),
                    (TrackKind::Video, MediaKind::Audio)
                ) {
                    return Err(ProjectError::Invalid(
                        "audio-only media cannot be placed on video track",
                    ));
                }
                if clip.duration_us == 0 {
                    return Err(ProjectError::Invalid("clip duration cannot be zero"));
                }
                let end = clip
                    .start_us
                    .checked_add(clip.duration_us)
                    .ok_or(ProjectError::Invalid("timeline time overflows"))?;
                let source_end = clip
                    .source_in_us
                    .checked_add(clip.duration_us)
                    .ok_or(ProjectError::Invalid("source time overflows"))?;
                if let Some(source_duration) = media.duration_us {
                    if source_end > source_duration {
                        return Err(ProjectError::Invalid("clip exceeds source duration"));
                    }
                }
                if clip.start_us < track_end {
                    return Err(ProjectError::Invalid("clips overlap on a track"));
                }
                track_end = end;
            }
        }
        Ok(())
    }

    /// Register a local media reference without modifying the source file.
    /// A duplicate canonical path leaves this document unchanged.
    pub fn add_media(
        &mut self,
        path: &str,
        kind: MediaKind,
        duration_us: Option<u64>,
        width: Option<u32>,
        height: Option<u32>,
        codec: Option<&str>,
    ) -> Result<bool, ProjectError> {
        if self.media.iter().any(|item| item.path == path) {
            return Ok(false);
        }
        let entry = MediaReference {
            id: Uuid::new_v4().to_string(),
            path: path.to_owned(),
            kind,
            duration_us,
            width,
            height,
            codec: codec.map(str::to_owned),
        };
        let mut next = self.clone();
        next.media.push(entry);
        next.validate()?;
        if next.to_json()?.len() > MAX_DOCUMENT_BYTES {
            return Err(ProjectError::TooLarge);
        }
        self.media = next.media;
        Ok(true)
    }

    pub fn media_json(&self) -> String {
        serde_json::to_string(&self.media).expect("validated media can serialize")
    }

    pub fn media_count(&self) -> usize {
        self.media.len()
    }

    pub fn track_count(&self) -> usize {
        self.timeline.tracks.len()
    }
}

fn check_id(value: &str) -> Result<(), ProjectError> {
    if Uuid::parse_str(value).is_err() {
        return Err(ProjectError::Invalid("identifiers must be valid UUIDs"));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_is_lossless() {
        let p = ProjectDocument::new("  My Film  ").unwrap();
        assert_eq!(p.name, "My Film");
        assert_eq!(p.track_count(), 2);
        assert_eq!(p.media_count(), 0);
        let json = p.to_json().unwrap();
        assert!(json.contains("movie-maker-project"));
        assert_eq!(ProjectDocument::from_json(json.as_bytes()).unwrap(), p);
    }

    #[test]
    fn unique_ids_for_new_documents() {
        let a = ProjectDocument::new("Film").unwrap();
        let b = ProjectDocument::new("Film").unwrap();
        assert_ne!(a.id, b.id);
        assert_ne!(a.timeline.tracks[0].id, a.timeline.tracks[1].id);
    }

    #[test]
    fn rejects_invalid_names() {
        for name in ["", "  ", "a\nb", &"x".repeat(201)] {
            assert!(ProjectDocument::new(name).is_err());
        }
    }

    #[test]
    fn rejects_future_version() {
        let p = ProjectDocument::new("A").unwrap();
        let json = p
            .to_json()
            .unwrap()
            .replace("\"version\": 1", "\"version\": 2");
        assert_eq!(
            ProjectDocument::from_json(json.as_bytes()),
            Err(ProjectError::UnsupportedVersion(2))
        );
    }

    #[test]
    fn rejects_invalid_frame_rate_and_duplicate_ids() {
        let mut p = ProjectDocument::new("A").unwrap();
        p.settings.frame_rate.denominator = 0;
        assert!(p.validate().is_err());
        p.settings.frame_rate.denominator = 1;
        p.timeline.tracks[1].id = p.timeline.tracks[0].id.clone();
        assert_eq!(p.validate(), Err(ProjectError::DuplicateId));
    }

    #[test]
    fn rejects_missing_media_and_overlap() {
        let mut p = ProjectDocument::new("A").unwrap();
        let media_id = Uuid::new_v4().to_string();
        let clip_id = Uuid::new_v4().to_string();
        p.timeline.tracks[0].clips.push(Clip {
            id: clip_id,
            media_id: media_id.clone(),
            start_us: 0,
            source_in_us: 0,
            duration_us: 1000,
        });
        assert!(p.validate().is_err());
        p.media.push(MediaReference {
            id: media_id.clone(),
            path: "sample.mp4".to_owned(),
            kind: MediaKind::Video,
            duration_us: Some(2000),
            width: Some(1280),
            height: Some(720),
            codec: Some("h264".to_owned()),
        });
        assert!(p.validate().is_ok());
        p.timeline.tracks[0].clips.push(Clip {
            id: Uuid::new_v4().to_string(),
            media_id,
            start_us: 999,
            source_in_us: 0,
            duration_us: 200,
        });
        assert!(p.validate().is_err());
    }

    #[test]
    fn media_is_added_only_once_and_survives_roundtrip() {
        let mut p = ProjectDocument::new("Import").unwrap();
        assert!(p
            .add_media(
                "C:/Clips/first.mp4",
                MediaKind::Video,
                Some(1_500_000),
                Some(1920),
                Some(1080),
                Some("h264"),
            )
            .unwrap());
        assert!(!p
            .add_media(
                "C:/Clips/first.mp4",
                MediaKind::Video,
                Some(1_500_000),
                Some(1920),
                Some(1080),
                Some("h264"),
            )
            .unwrap());
        assert_eq!(p.media_count(), 1);
        let reopened = ProjectDocument::from_json(p.to_json().unwrap().as_bytes()).unwrap();
        assert_eq!(p, reopened);
        assert!(reopened.media_json().contains("h264"));
    }

    #[test]
    fn old_version_one_media_entries_still_open() {
        let mut p = ProjectDocument::new("Old").unwrap();
        p.add_media("clip.mp4", MediaKind::Video, Some(1000), None, None, None)
            .unwrap();
        let json = p.to_json().unwrap();
        assert!(!json.contains("\"codec\""));
        assert_eq!(ProjectDocument::from_json(json.as_bytes()).unwrap(), p);
    }

    #[test]
    fn rejects_unrecognized_fields_and_malformed_docs() {
        let p = ProjectDocument::new("A").unwrap();
        let json = p
            .to_json()
            .unwrap()
            .replace("\"format\":", "\"unrecognized\": true, \"format\":");
        assert!(ProjectDocument::from_json(json.as_bytes()).is_err());
        assert!(ProjectDocument::from_json(b"not json").is_err());
        assert_eq!(
            ProjectDocument::from_json(&vec![0; MAX_DOCUMENT_BYTES + 1]),
            Err(ProjectError::TooLarge)
        );
    }
}
