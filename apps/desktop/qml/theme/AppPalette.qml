import QtQuick

QtObject {
    property bool darkMode: true

    readonly property color canvas: darkMode ? "#101215" : "#f5f6f8"
    readonly property color surface: darkMode ? "#191c20" : "#ffffff"
    readonly property color raised: darkMode ? "#25292e" : "#edf0f3"
    readonly property color hover: darkMode ? "#2d3238" : "#e7eaf0"
    readonly property color border: darkMode ? "#353a41" : "#d9dde3"
    readonly property color text: darkMode ? "#f2f3f5" : "#1c2027"
    readonly property color muted: darkMode ? "#9ca3ac" : "#6b737e"
    readonly property color accent: "#d33b43"
    readonly property color accentHover: "#b92b35"
    readonly property color video: "#090b0d"
}
