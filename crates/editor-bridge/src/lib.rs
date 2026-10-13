//! The explicit CXX boundary consumed by the Qt/C++ desktop host.
//! Keep domain logic in editor-core. FFI methods must stay small.

#[cxx::bridge(namespace = "movie_maker")]
mod ffi {
    extern "Rust" {
        fn application_name() -> String;
        fn core_version() -> String;
    }
}

fn application_name() -> String {
    editor_core::application_name().to_owned()
}

fn core_version() -> String {
    editor_core::core_version().to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bridge_exposes_real_core_values() {
        assert_eq!(application_name(), "Movie Maker");
        assert_eq!(core_version(), "0.1.0-dev");
    }
}
