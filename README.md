<p align="center">
  <img src="src/assets/logo_full.png" alt="AeroCommander Logo" width="400">
</p>

<h1 align="center">AeroCommander</h1>

<p align="center">
  <b>A fast, modern dual-panel orthodox file manager for Linux, inspired by Total Commander and tailored for modern Linux desktops & Omarchy.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Qt-6-41CD52?logo=qt&logoColor=white" alt="Qt 6">
  <img src="https://img.shields.io/badge/C%2B%2B-20-00599C?logo=c%2B%2B&logoColor=white" alt="C++20">
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/Desktop-Omarchy%20%2F%20Hyprland%20%2F%20Wayland-00B4D8" alt="Omarchy">
  <img src="https://img.shields.io/badge/Tests-51%20Passing-success" alt="Tests 51 Passing">
</p>

---

## 🌟 Key Features

### 🎨 Modern 2026 Dual Theme
- **Obsidian Carbon (Dark) & Alabaster Daylight (Light):** Instant dark/light palette switching (<kbd>Ctrl+Shift+T</kbd> or header toggle) with glassmorphism surfaces, semantic badges, animated transitions, and live Omarchy / Hyprland accent synchronization.

### ⚡ Power-User Productivity
- **Command Palette (<kbd>Ctrl+Shift+P</kbd>) & Quick Jump (<kbd>Ctrl+P</kbd>):** Fuzzy-searchable action launcher and instant folder jump powered by bookmarks, tab/visit history, and `zoxide` frecency integration.
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
- **Remote Connections (<kbd>Ctrl+Shift+M</kbd>):** Connect, mount, and browse `SFTP`, `SSH`, and `SMB` shares via GVFS (`gio mount`) or FUSE (`sshfs`) directly from the Drives bar, with saved connections and 1-click unmount/eject.
- **Open With... & Custom Actions (<kbd>Ctrl+Shift+O</kbd>):** XDG MIME detection (`QMimeDatabase`), `.desktop` application discovery & launching, persistent default app overrides (`mimeapps.list` / `xdg-mime`), cascading right-click **Open With** and **Custom Actions** submenus, and configurable Custom Actions (`%f`, `%F`, `%d`, `%n`, `%b`, `%e`, glob/MIME filters, terminal or output capture).
- **Removable Drive Mounting:** Discovers unmounted partitions via `lsblk` with 1-click mounting via `udisksctl` and 1-click eject.

### 📂 Dual-Panel Workflow & Per-Panel Tabs
- **Independent Panels:** Dual-panel orthodox layout with swift keyboard switching (<kbd>Tab</kbd>).
- **Per-Panel Tabs:** Open and close multiple tabs independently in each panel (<kbd>Ctrl+T</kbd>, <kbd>Ctrl+W</kbd>, <kbd>Ctrl+Tab</kbd>).
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
- **List & Grid Thumbnail Views:** Toggle between Total Commander-style detailed list (<kbd>Ctrl+1</kbd>) and visual thumbnail grid (<kbd>Ctrl+2</kbd>).
- **Git Status Tracking:** Live repository detection showing branch name, modified/untracked counts, and per-item status badges (`M`, `?`, `A`, `D`).
- **Checksum Calculation & Verification:** MD5, SHA-1, and SHA-256 calculation, live matching against clipboard hashes, and `.sha256` / `.md5` verification.
- **Visual File Diff (<kbd>Ctrl+Alt+D</kbd>):** Side-by-side visual diff between two files or panel selections.
- **Undo Stack (<kbd>Ctrl+Z</kbd>):** Undo recent renames, moves, and Trash deletions.
- **Properties & Permissions (<kbd>Alt+Enter</kbd>):** Interactive 3×3 `chmod` matrix, octal permission input, owner/group info, and recursive apply.
- **Symbolic Link Creation (<kbd>Ctrl+Shift+F5</kbd>):** Fast relative or absolute symlink creation.
- **Archive Pack & Extract:** Pack to `.zip` / `.tar.gz` (<kbd>Alt+F5</kbd>) and extract (<kbd>Alt+F9</kbd>).
- **Session Persistence:** Remembers open tabs, theme mode, presets, remote connections, custom actions, sorting, hidden-files state, and window dimensions in `~/.config/omapanel/session.ini`.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| <kbd>Ctrl+Shift+P</kbd> / <kbd>Ctrl+P</kbd> | Command Palette / Quick Jump (`zoxide`, bookmarks, recent) |
| <kbd>Ctrl+Shift+T</kbd> | Toggle Dark / Light theme (`Obsidian Carbon` / `Alabaster Daylight`) |
| <kbd>Ctrl+Shift+B</kbd> | Toggle Flat / Branch View (flatten subdirectories) |
| <kbd>Tab</kbd> | Switch active panel (Left / Right) |
| <kbd>Ctrl+T</kbd> / <kbd>Ctrl+W</kbd> | New tab / Close active tab in panel |
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
| <kbd>Ctrl+Shift+M</kbd> | Remote Connections (`SFTP` / `SSH` / `SMB` / `SSHFS`) |
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
- **Qt 6:** `qt6-base`, `qt6-declarative`, `qt6-quickcontrols2` (optional `qt6-multimedia` for the audio/video mini-player)
- **Libraries:** `libarchive` (virtual archive browsing & extraction)
- **C++ Compiler:** GCC or Clang with C++20 support
- **Build Tools:** `qmake6` and `make`
- **Optional Runtime Tools:** `zoxide` (frecency Quick Jump), `poppler` (`pdfinfo`/`pdftotext`/`pdftoppm` for PDF preview), `ffmpeg` (`ffprobe` for media metadata), `gvfs` (`gio` for SFTP/SMB), `sshfs`, `7z`/`bsdtar`/`zip`, `udisksctl`

### Build
```bash
./bin/build
```
Binary will be created at `./build/omapanel`.

### Run Test Suite
```bash
./bin/test
```
Runs the full automated test suite (51 test cases) verifying file operations, operation queue/pause/resume, next-gen previews, RegEx multi-rename, remote URIs, XDG Open With/Custom Actions, search, sync, duplicate finder, undo stack, git tracking, diffing, and permissions.

### Install on Arch Linux / Omarchy
```bash
./bin/install
```
Installs the binary to `~/.local/bin/omapanel` and places desktop entries and icons in standard XDG directories.

---

## 🌐 Localization
AeroCommander includes dynamic runtime localization:
- English (default)
- Romanian (Română)

Translations can be edited directly in `src/i18n/`.

---

## 📄 License
GPL-3.0 License. Inspired by Christian Ghisler's legendary Total Commander.
