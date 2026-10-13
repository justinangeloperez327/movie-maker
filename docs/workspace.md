# Desktop workspace

The UI is implemented with Qt Quick/QML. The appearance intentionally uses compact controls, flat surfaces, and a restrained red accent.

## Regions

- Left workspace rail: Media, Effects, Transitions, Titles.
- Context panel: selected workspace section, with explicit unavailable-feature messaging.
- Center preview: reserved for native GPU/video output in a later group.
- Right inspector: reserved for selected clip metadata and editing properties.
- Bottom timeline: vertically resizable editing dock with video and audio track placeholders.

The media browser and inspector can be hidden; the timeline can be collapsed. Qt SplitView supports mouse-based resizing. Workspace preferences persist locally through Qt QSettings.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| Ctrl+1 | Media section |
| Ctrl+2 | Effects section |
| Ctrl+3 | Transitions section |
| Ctrl+4 | Titles section |
| Ctrl+B | Show/hide media panel |
| Ctrl+I | Show/hide inspector |
| Ctrl+L | Show/hide timeline |
| Ctrl+Shift+D | Toggle light/dark appearance |
| F11 | Toggle fullscreen |
| Escape | Exit fullscreen |
| Ctrl+0 | Restore default workspace |
| F1 | About application |

Buttons for editing operations that are not yet implemented are deliberately disabled. The UI does not create fake projects, media items, or preview playback.

## Testing

```powershell
& ".\\build\\Release\\movie_maker.exe" --self-test
$env:QT_QPA_PLATFORM = "offscreen"
$env:QT_QUICK_BACKEND = "software"
& ".\\build\\Release\\movie_maker.exe" --ui-self-test
```

The second command checks real QML module loading and a state change through the C++ backend on Windows. Visual regression testing and real media UI tests will be added with functional editing workflows.
