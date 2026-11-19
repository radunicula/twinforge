<p align="center">
  <img src="src/assets/logo_full.png" alt="TwinForge Logo" width="440">
</p>

<h1 align="center">TwinForge</h1>

<p align="center">
  <b>A fast, modern dual-panel orthodox file manager for Linux (<code>twinforge</code> / <code>tf</code>), built for keyboard-driven workflows and modern Linux desktops.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Qt-6-41CD52?logo=qt&logoColor=white" alt="Qt 6">
  <img src="https://img.shields.io/badge/C%2B%2B-20-00599C?logo=c%2B%2B&logoColor=white" alt="C++20">
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/CLI-twinforge%20%7C%20tf-00B4D8" alt="CLI twinforge / tf">
  <img src="https://img.shields.io/badge/Tests-63%20Passing-success" alt="Tests 63 Passing">
</p>

---

## ✨ About TwinForge

**TwinForge** (`twinforge` / `tf`) is a native Linux dual-panel orthodox file manager built with **C++20, Qt 6, and QML**. Designed for keyboard-driven speed and modern desktop polish, it pairs classic dual-panel ergonomics (independent panels, F3–F10 function keys, locked tabs, workspaces, multi-rename, file split/combine) with a **100% non-blocking asynchronous architecture**, Freedesktop standards (Thumbnails, Trash `trash://`, XDG MIME / `.desktop` integration), and live **Obsidian Carbon (Dark) / Alabaster Daylight (Light)** theming that syncs automatically with Omarchy / Hyprland accents.

---

## 🌟 Key Features

### 🎨 Modern 2026 UI & Dual Theme
- **Obsidian Carbon (Dark) & Alabaster Daylight (Light):** Instant dark/light palette switching (<kbd>Ctrl+Shift+T</kbd> or header toggle) with semantic badges, custom-themed controls (`AppCheckBox`, `AppComboBox`, `AppProgressBar`, `AppMenu`, slim `AppScrollBar`), smooth micro-animations, and live Omarchy / Hyprland accent synchronization.
- **Vibrant Multi-Tone SVG Iconography:** Cohesive gradient vector icons for folders, file types, drives, cloud mounts, bookmarks, filters, disk usage analytics, and toolbar actions — sharp at every DPI in both Dark and Light themes.
- **Resizable Dual-Panel Splitter & Clean Empty States:** Drag the central splitter handle to adjust panel width (`22%–78%`) or double-click to reset `50/50`, with an animated top accent indicator on the active panel, an **Active Workspace** pill in the header, and helpful empty-state hints.

### ⚡ Power-User Productivity
- **Command Palette (<kbd>Ctrl+Shift+P</kbd>) & Quick Jump (<kbd>Ctrl+P</kbd>):** Fuzzy-searchable action launcher and instant folder jump powered by bookmarks, tab/visit history, and `zoxide` frecency integration.
- **Async Command Bar, Live Output Drawer & History (<kbd>Ctrl+E</kbd> / <kbd>Ctrl+O</kbd>):** Non-blocking shell command execution with live streaming output drawer, cancel button, persistent <kbd>↑</kbd>/<kbd>↓</kbd> command history, built-in `cd` navigation (`cd ..`, `cd ~`, `cd -`, `cd trash://`), and instant <kbd>Ctrl+Enter</kbd> / <kbd>Ctrl+Shift+Enter</kbd> filename/path insertion.
- **Multi-Character Type-Ahead Quick Jump:** Type characters directly in List or Grid view to jump instantly to matching files (prefix + substring fallback, floating `Jump:` pill, <kbd>Backspace</kbd> editing, and repeating a letter to cycle).
- **File Split & Combine (<kbd>Ctrl+Alt+S</kbd>):** Split large files into `.001`, `.002`, … chunks with an optional `.crc` SHA-256 verification manifest, and recombine parts asynchronously with progress, cancel, and automatic integrity checking.
- **Flat / Branch View (<kbd>Ctrl+Shift+B</kbd>):** Flatten all files from subdirectories into a single panel list with relative subpath chips for rapid filtering, batch renaming, or bulk copying.
- **Virtual Archive Browsing:** Press <kbd>Enter</kbd> on `.zip`, `.tar.gz`, `.tar.zst`, `.tar.xz`, or `.7z` archives (powered by `libarchive`) to browse inside them like regular folders, preview individual files (<kbd>F3</kbd>/<kbd>Ctrl+Q</kbd>), or extract selected entries (<kbd>F5</kbd>).

### 🔍 Search, Compare & Disk Space Analysis
- **Async Content & RegEx Search (<kbd>Alt+F7</kbd>) + Feed to Panel:** Background search with live cancellation, file content / RegEx matching, size range, modification date, and type filters, plus **Feed to Panel** to send results into a virtual tab for selection, copying, or multi-rename.
- **Disk Usage Bars & Analyzer (<kbd>Ctrl+Shift+D</kbd>):** Proportional usage bars rendered directly behind the Size column and recursive directory space breakdown (`Alt+Shift+Enter` to calculate all folder sizes).
- **Recursive Directory Synchronization (<kbd>Ctrl+Shift+S</kbd>):** Compare left and right directory trees by Date & Size or SHA-256 hash, review directional actions (`→`, `←`, `≠`, `=`), and synchronize in one click.
- **Duplicate File Finder (<kbd>Ctrl+Shift+F7</kbd>):** Two-stage size + SHA-256 hash grouping across folders to locate and clean up duplicate files safely.

### 🚀 Transfers, Next-Gen Previews & Multi-Rename
- **Operation Queue, Speed/ETA & Pause/Resume (<kbd>Ctrl+Shift+Q</kbd>):** Queue multiple <kbd>F5</kbd>/<kbd>F6</kbd> copy/move transfers, monitor real-time transfer speed (`MB/s`), estimated time remaining (`ETA`), pause/resume active transfers, and manage queued/completed jobs.
- **Next-Gen Quick View (<kbd>Ctrl+Q</kbd>) & Preview (<kbd>F3</kbd>):**
  - **Source Code & Markdown:** Syntax-highlighted code viewer and formatted Markdown preview (with Rendered/Raw toggle).
  - **Paginated PDF Preview:** Page rendering via `pdftoppm`, page metadata via `pdfinfo`, and text extraction via `pdftotext`.
  - **Font Specimen Viewer:** Interactive typography waterfall for `.ttf`, `.otf`, and `.woff`/`.woff2` fonts.
  - **Photo EXIF & Media Mini-Player:** Camera/exposure/ISO/aperture/focal-length/GPS EXIF reader and Audio/Video media info (`ffprobe`) with embedded mini-player (`QtMultimedia`), plus Hex dump mode.
- **Advanced Multi-Rename (<kbd>Ctrl+M</kbd>):** Batch rename with RegEx capture groups (`$1`, `\1`), dynamic tags (`[N]`, `[Nstart-end]`, `[Date]`, `[Time]`, `[ParentFolder]`, `[Ext]`, `[C]`), custom counter (`Start`/`Step`/`Digits`), case transforms, and persistent presets.

### 🌐 Linux Desktop Connectivity & Integration
- **CLI Arguments, Single-Instance IPC & Shell `cd`-on-Exit:** Launch directly into specific folders (`tf /left /right`, `tf .`, `tf -t /path`, `tf --select /file`, or `file://` URIs from desktop apps); reuse the running window automatically via local-socket IPC (override with `-n` / `--new-window`), or integrate shell `cd`-on-exit via `eval "$(tf --shell-init bash)"` (`zsh` / `fish`).
- **Remote Connections (<kbd>Ctrl+Shift+M</kbd>):** Native **Google Drive** & cloud storage support via `rclone` (auto-discovers existing remotes, includes in-app Google OAuth sign-in, and mounts FUSE volumes with `--vfs-cache-mode writes`), plus `SFTP`, `SSH`, and `SMB` shares via GVFS (`gio mount`) or `sshfs` directly from the Drives bar with 1-click unmount/eject.
- **Open With... & Custom Actions (<kbd>Ctrl+Shift+O</kbd>):** XDG MIME detection (`QMimeDatabase`), `.desktop` application discovery & launching, persistent default app overrides (`mimeapps.list` / `xdg-mime`), cascading right-click **Open With** and **Custom Actions** submenus, and configurable Custom Actions (`%f`, `%F`, `%d`, `%n`, `%b`, `%e`, glob/MIME filters, terminal or output capture).
- **Removable Drive Mounting:** Discovers unmounted partitions via `lsblk` with 1-click mounting via `udisksctl` and 1-click eject.

### 📂 Dual-Panel Workflow, Locked Tabs, Workspaces & Trash Manager
- **Independent Panels:** Dual-panel orthodox layout with swift keyboard switching (<kbd>Tab</kbd>).
- **Locked / Pinned Tabs & Power Tab Actions:** Right-click any tab (or press <kbd>Ctrl+Alt+L</kbd>) to lock it in **Allow Navigation** mode (click tab to return to its locked root) or **Strict** mode (navigating opens a new tab); plus **Duplicate Tab**, **Move Tab to Opposite Panel**, **Move Left/Right**, **Reopen Closed Tab** (<kbd>Ctrl+Shift+W</kbd>), and **Close Other Unlocked Tabs** — all persisted across sessions.
- **Named Dual-Panel Workspaces (<kbd>Ctrl+Shift+L</kbd>):** Save, update, load, and delete complete dual-panel tab layouts (including locked tabs, sort order, and hidden-files settings) in `~/.config/twinforge/workspaces.json`.
- **Freedesktop Trash Manager (`trash://`, <kbd>Ctrl+Shift+Backspace</kbd>):** Browse trashed items directly in either panel (or via the Drives bar chip with live item count), inspect original paths and deletion dates, **Restore** with automatic collision safety, **Delete Permanently**, or **Empty Trash**.
- **History & Breadcrumbs:** Complete back/forward directory history per tab (<kbd>Alt+Left</kbd>, <kbd>Alt+Right</kbd>) and clickable breadcrumbs (<kbd>Ctrl+L</kbd> for manual path input).
- **Panel Synchronization:** Swap panels (<kbd>Ctrl+U</kbd>) or sync target directory with active panel (<kbd>Alt+=</kbd>).

### 📋 Batch Creation & CSV Text Export
- **Multiple File & Folder Creation:** Both **New Folder (<kbd>F7</kbd>)** and **New File (<kbd>Shift+F4</kbd>)** support comma-separated lists (e.g. `doc1.txt, doc2.txt, notes.md` or `src, include, assets/icons`) with automatic `mkpath` and a live preview badge.
- **Copy as CSV Text to Clipboard:** **Copy Name(s) as Text (<kbd>Ctrl+Shift+C</kbd>)** and **Copy Path(s) as Text (<kbd>Ctrl+Alt+C</kbd>)** export selected or folder items as comma-separated lists.

### 🖱️ Comprehensive Mouse & Context Menu Interaction
- **Selection Modifiers:** Standard <kbd>Ctrl</kbd>+Click, <kbd>Shift</kbd>+Click, and Rubberband / Marquee rectangular drag selection.
- **Context Menus:** Item right-click menu (including **Open With** and **Custom Actions** cascading submenus) and background right-click menu with keyboard & <kbd>Esc</kbd> dismissal.

### 🛡️ Safety, Permissions & Read-Only Detection
- **Conflict Handling:** Interactive prompt on file collision (*Overwrite*, *Skip*, *Rename to (1)*, *Cancel*, with *Apply to all*).
- **Read-Only Detection:** Automatic detection of non-writable system folders with visible `[Read-Only]` / `[Doar citire]` badges.

### 🛠️ Additional Tools
- **Non-Blocking Async Architecture:** Background worker execution with live progress & cancellation for Git status, recursive folder sizes, duplicate scanning, directory compare/sync, checksums, previews (`pdftoppm`/`ffprobe`), archive pack/extract, `lsblk` drive discovery, and remote mounts (`rclone`/`gio`/`sshfs`).
- **List & Grid Thumbnail Views (Freedesktop Cache):** Toggle between a detailed dual-panel list (<kbd>Ctrl+1</kbd>) and visual thumbnail grid (<kbd>Ctrl+2</kbd>) backed by an asynchronous Freedesktop-compliant thumbnail cache (`~/.cache/thumbnails/{normal,large}`) for images, videos, and PDFs.
- **Git Status Tracking:** Live repository detection showing branch name, modified/untracked counts, and per-item status badges (`M`, `?`, `A`, `D`).
- **Checksum Calculation & Verification:** MD5, SHA-1, and SHA-256 calculation, live matching against clipboard hashes, and `.sha256` / `.md5` verification.
- **Visual File Diff (<kbd>Ctrl+Alt+D</kbd>):** Side-by-side visual diff between two files or panel selections.
- **Undo Stack (<kbd>Ctrl+Z</kbd>):** Undo recent renames, moves, and Trash deletions.
- **Properties & Permissions (<kbd>Alt+Enter</kbd>):** Interactive 3×3 `chmod` matrix, octal permission input, owner/group info, and recursive apply.
- **Symbolic Link Creation (<kbd>Ctrl+Shift+F5</kbd>):** Fast relative or absolute symlink creation.
- **Archive Pack & Extract:** Pack to `.zip` / `.tar.gz` (<kbd>Alt+F5</kbd>) and extract (<kbd>Alt+F9</kbd>).
- **Session Persistence:** Remembers open tabs, theme mode, presets, remote connections, custom actions, sorting, hidden-files state, and window dimensions in `~/.config/twinforge/session.ini` (with bookmarks in `~/.config/twinforge/bookmarks.json`).

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| <kbd>Ctrl+Shift+P</kbd> / <kbd>Ctrl+P</kbd> | Command Palette / Quick Jump (`zoxide`, bookmarks, recent) |
| <kbd>Ctrl+Shift+T</kbd> | Toggle Dark / Light theme (`Obsidian Carbon` / `Alabaster Daylight`) |
| <kbd>Ctrl+Shift+B</kbd> | Toggle Flat / Branch View (flatten subdirectories) |
| <kbd>Tab</kbd> | Switch active panel (Left / Right) |
| <kbd>Ctrl+T</kbd> / <kbd>Ctrl+W</kbd> | New tab / Close active tab in panel |
| <kbd>Ctrl+Shift+W</kbd> | Reopen last closed tab in active panel |
| <kbd>Ctrl+Alt+L</kbd> | Lock / unlock active tab (right-click tab for strict mode & tab actions) |
| <kbd>Ctrl+Shift+L</kbd> | Open Workspaces manager (save & restore dual-panel layouts) |
| <kbd>Ctrl+Shift+Backspace</kbd> | Open Trash Manager (`trash://`) to restore or empty |
| <kbd>Ctrl+E</kbd> / <kbd>Ctrl+O</kbd> | Focus Command Line Bar (`↑`/`↓` history, built-in `cd`) / Toggle live Output Drawer |
| <kbd>Ctrl+Enter</kbd> / <kbd>Ctrl+Shift+Enter</kbd> | Insert highlighted filename / full path into Command Line Bar |
| <kbd>Ctrl+Alt+S</kbd> | Split / Combine File (`.001` parts + `.crc` SHA-256 verification) |
| <kbd>Ctrl+Tab</kbd> / <kbd>Ctrl+Shift+Tab</kbd> | Next / Previous tab in active panel |
| <kbd>Ctrl+1</kbd> / <kbd>Ctrl+2</kbd> | Detailed List view / Grid Thumbnails view |
| <kbd>F3</kbd> / <kbd>Ctrl+Q</kbd> | Next-gen Preview modal / Toggle live Quick View in opposite panel |
| <kbd>F4</kbd> | Edit file in default `$EDITOR` |
| <kbd>Shift+F4</kbd> | Create new file (or multiple files via comma) |
| <kbd>F5</kbd> / <kbd>F6</kbd> | Copy / Move selected items to opposite panel (queued) |
| <kbd>Ctrl+Shift+Q</kbd> | Operation Queue monitor (Speed/ETA, Pause/Resume) |
| <kbd>F7</kbd> | Create new folder (or multiple folders via comma) |
| <kbd>Shift+F6</kbd> / <kbd>Ctrl+M</kbd> | Quick rename / RegEx & Tag Multi-Rename tool |
| <kbd>F8</kbd> / <kbd>Delete</kbd> | Delete selected items (Trash or permanent) |
| <kbd>F9</kbd> / <kbd>Alt+T</kbd> | Open terminal in current directory |
| <kbd>F10</kbd> | Exit application |
| <kbd>Ctrl+C</kbd> / <kbd>Ctrl+X</kbd> / <kbd>Ctrl+V</kbd> | Copy / Cut / Paste via system clipboard |
| <kbd>Ctrl+Shift+C</kbd> / <kbd>Ctrl+Alt+C</kbd> | Copy selected names / paths as comma-separated text |
| <kbd>Ctrl+Z</kbd> | Undo last rename, move, or trash operation |
| <kbd>Alt+Enter</kbd> | Properties & interactive `chmod` permissions |
| <kbd>Ctrl+Shift+F5</kbd> | Create symbolic link in target panel |
| <kbd>Ctrl+Alt+D</kbd> | Visual side-by-side text file diff |
| <kbd>Alt+F5</kbd> / <kbd>Alt+F9</kbd> | Pack archive / Extract archive |
| <kbd>Alt+F7</kbd> | Async Search & Content/RegEx Search (+ Feed to Panel) |
| <kbd>Ctrl+Shift+D</kbd> | Toggle Disk Usage Bars / Space Analyzer |
| <kbd>Ctrl+Shift+S</kbd> | Recursive Synchronize Directories |
| <kbd>Ctrl+Shift+F7</kbd> | Find Duplicate Files (size + SHA-256) |
| <kbd>Ctrl+Shift+M</kbd> | Remote Connections (`Google Drive / rclone` / `SFTP` / `SSH` / `SMB` / `SSHFS`) |
| <kbd>Ctrl+Shift+O</kbd> | Open With... & Custom Actions chooser |
| <kbd>Num+</kbd> / <kbd>Num-</kbd> | Select / deselect by wildcard pattern (e.g. `*.jpg`) |
| <kbd>Num*</kbd> / <kbd>Ctrl+Shift+A</kbd> | Invert selection |
| <kbd>Ctrl+H</kbd> | Toggle hidden files |
| <kbd>Ctrl+S</kbd> | Quick filter active panel |
| <kbd>Ctrl+B</kbd> | Bookmark manager |
| <kbd>Ctrl+U</kbd> / <kbd>Alt+=</kbd> | Swap panels / Sync target to active panel |
| <kbd>?</kbd> / <kbd>F1</kbd> | Interactive keyboard shortcuts overlay |

---

## 🚀 Building & Installation

### Prerequisites
- **Qt 6:** `qt6-base`, `qt6-declarative`, `qt6-quickcontrols2`, `qt6-svg` (optional `qt6-multimedia` for the audio/video mini-player)
- **Libraries:** `libarchive` (virtual archive browsing & extraction)
- **C++ Compiler:** GCC or Clang with C++20 support
- **Build Tools:** `qmake6` and `make`
- **Optional Runtime Tools:** `rclone` (Google Drive & cloud FUSE mounts), `zoxide` (frecency Quick Jump), `poppler` (`pdfinfo`/`pdftotext`/`pdftoppm` for PDF preview), `ffmpeg` (`ffprobe` for media metadata), `gvfs` (`gio` for SFTP/SMB), `sshfs`, `7z`/`bsdtar`/`zip`, `udisksctl`

### Build
```bash
./bin/build
```
Binary will be created at `./build/twinforge` (with `./build/tf` symlink alias).

### Run Test Suite
```bash
./bin/test
```
Runs the full automated test suite (**63 test cases**) verifying file operations, operation queue/pause/resume, non-blocking async workers & cancellation, Freedesktop thumbnail cache compliance, CLI parsing & Single-Instance IPC, locked tabs & tab management, dual-panel workspaces, Freedesktop Trash (`trash://`) restore/delete/empty, multi-character type-ahead quick jump, async command runner with built-in `cd` & history, file split/combine with SHA-256 verification, next-gen previews, RegEx multi-rename, Google Drive (`rclone`), remote URIs, XDG Open With/Custom Actions, search, sync, duplicate finder, undo stack, git tracking, diffing, permissions, and full QML UI loading without errors.

---

## ⚙️ Configuration & Data Paths

| Path | Purpose |
| :--- | :--- |
| `~/.config/twinforge/session.ini` | Open tabs & lock states, command history, recent directories, theme mode, Multi-Rename presets, remote connections, custom actions, sort/hidden state, window size |
| `~/.config/twinforge/bookmarks.json` | Saved folder bookmarks |
| `~/.config/twinforge/workspaces.json` | Saved named dual-panel workspaces |
| `~/.cache/thumbnails/{normal,large}/` | Freedesktop-compliant PNG thumbnails for Grid View (`Ctrl+2`) |
| `~/.cache/twinforge/mounts/` | FUSE mountpoints for `rclone` (Google Drive) & `sshfs` |
| `~/.local/share/Trash/` | Freedesktop Trash managed via `trash://` |

### CLI Usage & Shell `cd`-on-Exit (`tfcd`)
```bash
tf .                           # Open current directory in active panel (reuses running window)
tf /path/left /path/right      # Open specific folders in Left and Right panels
tf -t ~/Downloads              # Open folder in a new tab in the running instance
tf --select ~/notes/todo.md    # Open parent folder and highlight todo.md
tf -n /etc                     # Force a new independent window
tf --print-last-dir            # Print active directory to stdout on exit

# Add shell cd-on-exit helper (`tfcd`) to ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish:
eval "$(tf --shell-init bash)" # bash
eval "$(tf --shell-init zsh)"  # zsh
tf --shell-init fish | source  # fish
```

### Install on Arch Linux (`twinforge` / `twinforge-git` / `twinforge-bin`)
```bash
./bin/install
```
Builds and installs the package defined in `pkgbuild/PKGBUILD`, placing the `twinforge` binary and `tf` CLI alias in `/usr/bin/`, plus `.desktop` entry and SVG/PNG icons in standard XDG directories.

---

## 🌐 Localization
TwinForge includes dynamic runtime localization:
- English (default)
- Romanian (Română)

Translations can be edited directly in `src/i18n/`.

---

## 📄 License
TwinForge Freeware License (see [LICENSE](LICENSE)) — dynamically linked against Qt 6 (GNU LGPLv3) and `libarchive` (BSD-2-Clause).
