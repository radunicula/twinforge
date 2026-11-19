<p align="center">
  <img src="assets/logo_full.png" alt="TwinForge Logo" width="440">
</p>

<h1 align="center">TwinForge</h1>

<p align="center">
  <b>A fast, modern dual-panel orthodox file manager for Linux (<code>twinforge</code> / <code>tf</code>), built natively with C++20 & Qt 6.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20(Wayland%20%2F%20X11)-FCC624?logo=linux&logoColor=black" alt="Platform Linux">
  <img src="https://img.shields.io/badge/UI-Qt%206%20%2F%20QML-41CD52?logo=qt&logoColor=white" alt="Qt 6">
  <img src="https://img.shields.io/badge/CLI-twinforge%20%7C%20tf-00B4D8" alt="CLI twinforge / tf">
  <img src="https://img.shields.io/badge/License-Freeware-6366F1" alt="Freeware">
  <a href="https://revolut.me/radunicula"><img src="https://img.shields.io/badge/Donate-Revolut-0075EB?logo=revolut&logoColor=white" alt="Donate via Revolut"></a>
</p>

---

## ✨ What is TwinForge?

**TwinForge** is a free, native Linux dual-panel file manager designed for keyboard-first speed and modern desktop ergonomics. It brings classic orthodox dual-panel workflows together with a **100% non-blocking asynchronous architecture**, Freedesktop standards, and live **Dark / Light** theming (including automatic Omarchy / Hyprland accent sync).

> This repository hosts official prebuilt **binary releases**, **installers**, **SHA-256 checksums**, and the **issue tracker** for TwinForge.

---

## 🚀 Quick Install

### Option 1: One-Line Installer (Recommended — User Install in `~/.local/`, no `sudo` needed)
```bash
curl -fsSL https://raw.githubusercontent.com/radunicula/twinforge/main/install.sh | bash
```
For a system-wide install into `/usr/local/`:
```bash
curl -fsSL https://raw.githubusercontent.com/radunicula/twinforge/main/install.sh | bash -s -- --system
```

### Option 2: Arch Linux / Omarchy Package (`.pkg.tar.zst`)
Download `twinforge-<version>-1-x86_64.pkg.tar.zst` from the [Releases](https://github.com/radunicula/twinforge/releases) page and install via `pacman`:
```bash
sudo pacman -U twinforge-*-x86_64.pkg.tar.zst
```

### Runtime Dependencies
TwinForge dynamically links against standard system libraries:
- **Required:** `qt6-base`, `qt6-declarative`, `qt6-svg`, `qt6-wayland`, `libarchive`
- **Optional (for extra features):** `rclone` (Google Drive FUSE mounts), `zoxide` (Quick Jump frecency), `poppler` (PDF preview), `ffmpeg` (`ffprobe` media metadata), `gvfs` (`gio` for SFTP/SMB), `sshfs`, `udisksctl`

### Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/radunicula/twinforge/main/uninstall.sh | bash
```

---

## 🌟 Highlights

- **Dual-Panel Power Workflow:** Independent Left/Right panels, interactive resizable central splitter (double-click to reset `50/50`), classic `F3`–`F10` operations, and instant panel swap (`Ctrl+U`) / sync (`Alt+=`).
- **Locked / Pinned Tabs & Workspaces:** Lock tabs in *Allow Navigation* or *Strict* mode (`Ctrl+Alt+L`), reopen closed tabs (`Ctrl+Shift+W`), duplicate or move tabs across panels, and save/restore named dual-panel **Workspaces** (`Ctrl+Shift+L`).
- **Non-Blocking Async Engine:** Git status, folder sizes, duplicate finder, directory sync, checksums, PDF/media previews, archive pack/extract, `lsblk` drives, and remote mounts run asynchronously with progress & cancel.
- **Modern Dark & Light UI:** *Obsidian Carbon* & *Alabaster Daylight* (`Ctrl+Shift+T`), custom-themed controls, vibrant multi-tone SVG icons, and live Omarchy / Hyprland accent sync.
- **Command Palette & Quick Jump:** Fuzzy action launcher (`Ctrl+Shift+P`), `zoxide`/history folder jump (`Ctrl+P`), and multi-character Type-Ahead quick jump inside panels.
- **Async Command Bar & Live Output Drawer (`Ctrl+E` / `Ctrl+O`):** Run shell commands without freezing the UI, stream live output, browse persistent `↑`/`↓` history, use built-in `cd`, and insert filenames (`Ctrl+Enter`) or full paths (`Ctrl+Shift+Enter`).
- **Freedesktop Trash Manager (`trash://`, `Ctrl+Shift+Backspace`):** Browse trashed files with original paths & deletion dates, restore safely (collision-protected), delete permanently, or empty Trash.
- **Remote & Cloud Mounts (`Ctrl+Shift+M`):** Native **Google Drive** via `rclone` (with in-app OAuth sign-in), plus `SFTP`, `SMB`, and `SSHFS` directly in the Drives bar.
- **Built-In Power Tools:** Virtual archive browsing (`.zip`, `.tar.*`, `.7z`), Flat / Branch View (`Ctrl+Shift+B`), Disk Usage bars (`Ctrl+Shift+D`), RegEx Multi-Rename (`Ctrl+M`), Directory Sync (`Ctrl+Shift+S`), Duplicate Finder (`Ctrl+Shift+F7`), Visual File Diff (`Ctrl+Alt+D`), File Split & Combine `.001/.crc` (`Ctrl+Alt+S`), Next-Gen Quick View (`Ctrl+Q`), and Freedesktop Thumbnail Grid (`Ctrl+2`).
- **CLI & Shell `cd`-on-Exit (`tfcd`):**
  ```bash
  tf .                           # Open current folder in running window
  tf /left/dir /right/dir        # Open both panels at once
  tf -t ~/Downloads              # Open in a new tab
  tf --select ~/notes/todo.md    # Open folder and highlight file
  eval "$(tf --shell-init bash)" # Enable `tfcd` (also supports zsh & fish)
  ```

---

## ⌨️ Essential Shortcuts

| Shortcut | Action |
| :--- | :--- |
| <kbd>Tab</kbd> | Switch active panel |
| <kbd>Ctrl+Shift+P</kbd> / <kbd>Ctrl+P</kbd> | Command Palette / Quick Jump |
| <kbd>Ctrl+T</kbd> / <kbd>Ctrl+W</kbd> / <kbd>Ctrl+Shift+W</kbd> | New tab / Close tab / Reopen closed tab |
| <kbd>Ctrl+Alt+L</kbd> / <kbd>Ctrl+Shift+L</kbd> | Lock active tab / Workspaces Manager |
| <kbd>Ctrl+Shift+Backspace</kbd> | Open Trash Manager (`trash://`) |
| <kbd>Ctrl+E</kbd> / <kbd>Ctrl+O</kbd> | Focus Command Bar / Toggle Output Drawer |
| <kbd>Ctrl+1</kbd> / <kbd>Ctrl+2</kbd> | Detailed List / Thumbnail Grid view |
| <kbd>F3</kbd> / <kbd>Ctrl+Q</kbd> | Preview / Toggle Quick View |
| <kbd>F5</kbd> / <kbd>F6</kbd> / <kbd>F7</kbd> / <kbd>F8</kbd> | Copy / Move / New Folder / Delete |
| <kbd>Ctrl+M</kbd> / <kbd>Ctrl+Alt+S</kbd> | Multi-Rename / Split & Combine File |
| <kbd>Ctrl+Shift+T</kbd> | Switch Dark / Light theme |
| <kbd>?</kbd> / <kbd>F1</kbd> | Full Keyboard Shortcuts reference |

---

## 💖 Support TwinForge

TwinForge is **100% free** for personal and commercial use. If it saves you time and you'd like to support ongoing Linux development, you can buy me a coffee via Revolut (card, Apple Pay, Google Pay, or Revolut):

👉 **[Donate via Revolut (`revolut.me/radunicula`)](https://revolut.me/radunicula)** — or use the **Sponsor** button at the top of this repository.

---

## 📄 License & Third-Party Notices

TwinForge is distributed as **Freeware** (see [LICENSE](LICENSE)).

TwinForge dynamically links against open-source libraries:
- **Qt 6** — licensed under **GNU LGPLv3** ([qt.io/licensing](https://www.qt.io/licensing/), source at [download.qt.io](https://download.qt.io/official_releases/qt/)).
- **libarchive** — licensed under the **BSD 2-Clause License** ([libarchive.org](https://www.libarchive.org/)).
