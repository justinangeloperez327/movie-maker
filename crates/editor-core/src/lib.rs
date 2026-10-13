//! Platform-independent application domain. No Qt or FFmpeg dependency.

/// The name exposed to the native desktop host.
pub const APPLICATION_NAME: &str = "Movie Maker";

/// The current pre-release foundation version; not a public stable release.
pub const CORE_VERSION: &str = "0.1.0-dev";

pub fn application_name() -> &'static str {
    APPLICATION_NAME
}

pub fn core_version() -> &'static str {
    CORE_VERSION
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn application_identity_is_available() {
        assert_eq!(application_name(), "Movie Maker");
        assert_eq!(core_version(), "0.1.0-dev");
    }
}
