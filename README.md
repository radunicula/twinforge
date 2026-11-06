# omapanel

A modern, fast dual-panel (orthodox) file manager for Linux, inspired by Total Commander and tailored for the Omarchy desktop.

## Features

- **Dual-Panel Workflow:** Independent left and right panels with synchronized navigation, disk jumps (`~`, `/`), and directory breadcrumbs.
- **Classic Total Commander Shortcuts:**
  - <kbd>Tab</kbd> – Switch between left and right panels.
  - <kbd>F3</kbd> – Quick view preview (text, source code, images, metadata).
  - <kbd>F4</kbd> – Edit in external editor (`$EDITOR` or default).
  - <kbd>F5</kbd> – Copy selected files/folders to the inactive panel.
  - <kbd>F6</kbd> – Move selected files/folders to the inactive panel.
  - <kbd>Shift+F6</kbd> – Inline rename file or directory.
  - <kbd>F7</kbd> – Create new folder (`mkdir`).
  - <kbd>F8</kbd> / <kbd>Delete</kbd> – Delete files/folders (Trash or permanent).
  - <kbd>Space</kbd> / <kbd>Insert</kbd> – Toggle selection and move to next item.
  - <kbd>Alt+F7</kbd> – Recursive file search with instant results.
  - <kbd>Ctrl+H</kbd> – Toggle hidden (dot) files.
  - <kbd>Ctrl+T</kbd> – Open terminal in current directory.
  - <kbd>Ctrl+A</kbd> / <kbd>Ctrl+D</kbd> – Select / Deselect all.
  - <kbd>?</kbd> – Interactive keyboard shortcut cheat-sheet.
- **Native Look & Feel:** Automatic live theme following (accent color and Hyprland corner radius).
- **Asynchronous Operations:** Copying and moving large trees run with status progress.
- **Multi-language Support:** Live dynamic translations (English, Romanian, etc.).

## Building & Running

### Requirements
- Qt 6 (base, declarative, wayland)
- GCC / G++ (C++20)
- `qmake6` and `make`

### Build
```bash
./bin/build
./build/omapanel
```

### Run Tests
```bash
./bin/test
```

### Install (Arch Linux)
```bash
./bin/install
```

## Keyboard Shortcuts

| Shortcut | Description |
|---|---|
| `Tab` | Switch active panel (Left / Right) |
| `Up` / `Down` | Navigate files in active panel |
| `Enter` | Enter directory / Open file |
| `Backspace` | Parent directory (`..`) |
| `Space` / `Insert` | Toggle item selection and advance cursor |
| `Ctrl+A` | Select all |
| `Ctrl+D` | Deselect all |
| `Ctrl+Shift+A`| Invert selection |
| `F3` | View file preview |
| `F4` | Edit file with editor |
| `F5` | Copy selected item(s) to target panel |
| `F6` | Move selected item(s) to target panel |
| `Shift+F6` | Rename highlighted item |
| `F7` | Create new folder |
| `F8` / `Delete` | Delete item(s) |
| `Alt+F7` | Search files |
| `Ctrl+H` | Show/hide hidden files |
| `Ctrl+R` | Refresh file list |
| `Ctrl+T` | Open terminal in current folder |
| `F10` | Quit omapanel |
| `?` | Show shortcut guide |
