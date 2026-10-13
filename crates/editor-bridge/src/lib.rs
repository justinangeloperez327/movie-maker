//! Native CXX API. Editing document state stays within Rust.
//! Qt handles atomic file I/O and user dialogs.

pub struct ProjectSession {
    document: editor_project::ProjectDocument,
}

#[cxx::bridge(namespace = "movie_maker")]
mod ffi {
    extern "Rust" {
        type ProjectSession;

        fn application_name() -> String;
        fn core_version() -> String;

        fn new_project(name: &str) -> Result<Box<ProjectSession>>;
        fn project_from_json(json: &str) -> Result<Box<ProjectSession>>;
        fn project_name(self: &ProjectSession) -> String;
        fn project_json(self: &ProjectSession) -> Result<String>;
        fn project_media_count(self: &ProjectSession) -> usize;
        fn project_track_count(self: &ProjectSession) -> usize;
        fn project_media_json(self: &ProjectSession) -> String;
        fn project_add_media(
            self: &mut ProjectSession,
            path: &str,
            kind: &str,
            duration_us: u64,
            width: u32,
            height: u32,
            codec: &str,
        ) -> Result<bool>;
    }
}

fn application_name() -> String {
    editor_core::application_name().to_owned()
}

fn core_version() -> String {
    editor_core::core_version().to_owned()
}

fn new_project(name: &str) -> Result<Box<ProjectSession>, editor_project::ProjectError> {
    Ok(Box::new(ProjectSession {
        document: editor_project::ProjectDocument::new(name)?,
    }))
}

fn project_from_json(json: &str) -> Result<Box<ProjectSession>, editor_project::ProjectError> {
    Ok(Box::new(ProjectSession {
        document: editor_project::ProjectDocument::from_json(json.as_bytes())?,
    }))
}

impl ProjectSession {
    fn project_name(&self) -> String {
        self.document.name.clone()
    }

    fn project_json(&self) -> Result<String, editor_project::ProjectError> {
        self.document.to_json()
    }

    fn project_media_json(&self) -> String {
        self.document.media_json()
    }

    fn project_add_media(
        &mut self,
        path: &str,
        kind: &str,
        duration_us: u64,
        width: u32,
        height: u32,
        codec: &str,
    ) -> Result<bool, editor_project::ProjectError> {
        use editor_project::MediaKind;
        let kind = match kind {
            "video" => MediaKind::Video,
            "audio" => MediaKind::Audio,
            "image" => MediaKind::Image,
            _ => return Err(editor_project::ProjectError::Invalid("unknown media kind")),
        };
        self.document.add_media(
            path,
            kind,
            if duration_us == 0 {
                None
            } else {
                Some(duration_us)
            },
            if width == 0 { None } else { Some(width) },
            if height == 0 { None } else { Some(height) },
            if codec.is_empty() { None } else { Some(codec) },
        )
    }

    fn project_media_count(&self) -> usize {
        self.document.media_count()
    }

    fn project_track_count(&self) -> usize {
        self.document.track_count()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bridge_exposes_real_core_values() {
        assert_eq!(application_name(), "Movie Maker");
        assert_eq!(core_version(), "0.1.0-dev");
    }

    #[test]
    fn session_roundtrip_through_bridge() {
        let session = new_project("A demo").unwrap();
        assert_eq!(session.project_name(), "A demo");
        assert_eq!(session.project_media_count(), 0);
        assert_eq!(session.project_track_count(), 2);
        let json = session.project_json().unwrap();
        let reopened = project_from_json(&json).unwrap();
        assert_eq!(reopened.project_name(), "A demo");
        assert_eq!(reopened.project_json().unwrap(), json);
    }

    #[test]
    fn bridge_imports_and_deduplicates_media() {
        let mut session = new_project("A demo").unwrap();
        assert!(session
            .project_add_media("a.mp4", "video", 1_000_000, 1920, 1080, "h264")
            .unwrap());
        assert!(!session
            .project_add_media("a.mp4", "video", 1_000_000, 1920, 1080, "h264")
            .unwrap());
        assert_eq!(session.project_media_count(), 1);
        let reopened = project_from_json(&session.project_json().unwrap()).unwrap();
        assert!(reopened.project_media_json().contains("a.mp4"));
        assert!(session
            .project_add_media("x", "unknown", 0, 0, 0, "")
            .is_err());
    }

    #[test]
    fn bridge_rejects_invalid_data() {
        assert!(new_project("").is_err());
        assert!(project_from_json("{broken").is_err());
    }
}
