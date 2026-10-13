cmake_minimum_required(VERSION 3.26)
project(MovieMaker VERSION 0.1.0 LANGUAGES CXX)

if(NOT WIN32 OR NOT MSVC)
    message(FATAL_ERROR "The native desktop target currently supports Windows x64 and MSVC.")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "A 64-bit toolchain is required.")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 Concurrent Multimedia)
qt_standard_project_setup(REQUIRES 6.8)

find_program(CARGO_EXECUTABLE cargo REQUIRED)
find_program(CXXBRIDGE_EXECUTABLE cxxbridge REQUIRED)

set(RUST_BRIDGE_SOURCE "${CMAKE_SOURCE_DIR}/crates/editor-bridge/src/lib.rs")
set(BRIDGE_GENERATED_DIR "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${BRIDGE_GENERATED_DIR}/rust")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${RUST_BRIDGE_SOURCE}")

function(generate_bridge_file output_path)
    execute_process(
        COMMAND "${CXXBRIDGE_EXECUTABLE}" ${ARGN}
        OUTPUT_FILE "${output_path}"
        RESULT_VARIABLE generation_result
        ERROR_VARIABLE generation_error
    )
    if(NOT generation_result EQUAL 0)
        message(FATAL_ERROR "CXX generation failed: ${generation_error}")
    endif()
endfunction()

generate_bridge_file("${BRIDGE_GENERATED_DIR}/rust/cxx.h" --header)
generate_bridge_file("${BRIDGE_GENERATED_DIR}/bridge.h" "${RUST_BRIDGE_SOURCE}" --header)
generate_bridge_file("${BRIDGE_GENERATED_DIR}/bridge.cpp" "${RUST_BRIDGE_SOURCE}")

set(RUST_TARGET_DIR "${CMAKE_BINARY_DIR}/cargo-target")
add_custom_target(editor_rust_build
    COMMAND "${CMAKE_COMMAND}" -E env
        "CARGO_TARGET_DIR=${RUST_TARGET_DIR}"
        "${CARGO_EXECUTABLE}" build
        --manifest-path "${CMAKE_SOURCE_DIR}/Cargo.toml"
        --package editor-bridge
        $<$<NOT:$<CONFIG:Debug>>:--release>
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Building Rust application core and CXX bridge"
    VERBATIM
)

add_subdirectory(apps/desktop)
