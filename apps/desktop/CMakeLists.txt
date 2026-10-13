qt_add_executable(movie_maker WIN32
    main.cpp
    app_backend.cpp
    app_backend.h
    media_indexer.h
    media_indexer.cpp
    "${BRIDGE_GENERATED_DIR}/bridge.cpp"
)

qt_add_qml_module(movie_maker
    URI MovieMaker
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/theme/AppPalette.qml
        qml/components/WorkspaceButton.qml
        qml/components/SmallAction.qml
        qml/panels/MediaPanel.qml
        qml/panels/PreviewPanel.qml
        qml/panels/InspectorPanel.qml
        qml/panels/TimelinePanel.qml
)

target_include_directories(movie_maker PRIVATE "${BRIDGE_GENERATED_DIR}")

target_link_libraries(movie_maker PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Concurrent
    "${RUST_TARGET_DIR}/$<IF:$<CONFIG:Debug>,debug,release>/editor_bridge.lib"
    ws2_32
    userenv
    bcrypt
    ntdll
)

add_dependencies(movie_maker editor_rust_build)

if(MSVC)
    target_compile_options(movie_maker PRIVATE /W4 /permissive-)
endif()
