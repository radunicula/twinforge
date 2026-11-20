%global debug_package %{nil}

Name:           twinforge
Version:        %{?pkgver}%{!?pkgver:0.1.0}
Release:        %{?pkgrel}%{!?pkgrel:1}%{?dist}
Summary:        Modern dual-panel orthodox file manager for Linux

License:        GPL-3.0-or-later
URL:            https://github.com/radunicula/twinforge
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtsvg-devel
BuildRequires:  libarchive-devel
BuildRequires:  desktop-file-utils

Requires:       qt6-qtbase-gui
Requires:       qt6-qtdeclarative
Requires:       qt6-qtsvg
Requires:       qt6-qtwayland
Requires:       hicolor-icon-theme
Requires:       xdg-utils

Recommends:     bsdtar
Recommends:     zstd
Recommends:     poppler-utils
Recommends:     ffmpeg
Recommends:     p7zip
Recommends:     rclone
Recommends:     git

%description
TwinForge (twinforge / tf) is a fast, modern dual-panel orthodox file manager
for Linux built with C++20, Qt 6, QML, and libarchive. It features a
non-blocking asynchronous architecture, virtual archive browsing, live dark/light
theming, work-linked saved searches, interrupted transfer recovery, batch
checksums, and Freedesktop desktop integration.

%prep
%autosetup -n %{name}-%{version}

%build
QMAKE_BIN="$(command -v qmake6 || command -v qmake-qt6 || echo /usr/lib64/qt6/bin/qmake)"
if [ ! -x "$QMAKE_BIN" ]; then
    echo "Error: Qt 6 qmake not found" >&2
    exit 1
fi
mkdir -p build
cd build
"$QMAKE_BIN" ../twinforge.pro
make %{?_smp_mflags}

%install
install -Dm755 build/twinforge %{buildroot}%{_bindir}/twinforge
ln -sf twinforge %{buildroot}%{_bindir}/tf
install -Dm644 pkgbuild/twinforge.desktop %{buildroot}%{_datadir}/applications/twinforge.desktop
install -Dm644 pkgbuild/twinforge.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/twinforge.png
install -Dm644 pkgbuild/twinforge.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/twinforge.svg

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/twinforge.desktop

%files
%license LICENSE
%doc README.md ARCHITECTURE.md
%{_bindir}/twinforge
%{_bindir}/tf
%{_datadir}/applications/twinforge.desktop
%{_datadir}/icons/hicolor/256x256/apps/twinforge.png
%{_datadir}/icons/hicolor/scalable/apps/twinforge.svg

%changelog
* Fri Nov 20 2026 Radu Nicula <radunicula@users.noreply.github.com> - 0.1.0-1
- Add native Fedora RPM packaging and clean-container archive smoke test
- Add 50,000-file interactivity benchmark harness and PanelModel/Backend optimizations
