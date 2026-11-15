import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: backend.windowWidth
    height: backend.windowHeight
    minimumWidth: 860
    minimumHeight: 540
    visible: true
    title: "AeroCommander — Total Commander for Linux"
    color: p.windowBg

    readonly property bool isDark: backend.isDarkTheme

    // Modern 2026 Dual Palette ("Obsidian Carbon" Dark & "Alabaster Daylight" Light)
    readonly property QtObject themePalette: QtObject {
        id: p
        readonly property color accent: win.isDark ? theme.darkAccent : theme.lightAccent
        readonly property color accentFg: win.isDark ? theme.darkAccentForeground : theme.lightAccentForeground

        // Surfaces
        readonly property color windowBg: win.isDark ? "#09090b" : "#eef0f5"
        readonly property color appBarBg: win.isDark ? "#111114" : "#ffffff"
        readonly property color subBarBg: win.isDark ? "#0d0d10" : "#f7f8fb"
        readonly property color panelActiveBg: win.isDark ? "#121216" : "#ffffff"
        readonly property color panelInactiveBg: win.isDark ? "#0c0c0f" : "#f8f9fc"
        readonly property color panelHeaderActiveBg: win.isDark ? "#18181d" : "#f8fafc"
        readonly property color panelHeaderInactiveBg: win.isDark ? "#121216" : "#f1f4f9"
        readonly property color tabStripBg: win.isDark ? "#0c0c0f" : "#f3f5f9"
        readonly property color tabActivePanelBg: win.isDark ? "#202028" : "#ffffff"
        readonly property color tabActiveInactivePanelBg: win.isDark ? "#17171d" : "#eaedf4"
        readonly property color tabHoverBg: win.isDark ? "#16161c" : "#e8ecf4"
        readonly property color tableHeaderBg: win.isDark ? "#141419" : "#f6f8fb"
        readonly property color tableHeaderHoverBg: win.isDark ? "#1c1c24" : "#ebeef5"
        readonly property color panelFooterBg: win.isDark ? "#111115" : "#f7f8fb"
        readonly property color filterBarBg: win.isDark ? "#16161c" : "#f1f4fa"
        readonly property color inputBg: win.isDark ? "#09090c" : "#ffffff"
        readonly property color breadcrumbBg: win.isDark ? "#0a0a0e" : "#ffffff"
        readonly property color cardBg: win.isDark ? "#18181f" : "#f4f6fa"
        readonly property color cardAltBg: win.isDark ? "#131318" : "#f8fafc"
        readonly property color chipBg: win.isDark ? "#16161c" : "#ffffff"
        readonly property color chipUnmountedBg: win.isDark ? "#111116" : "#f1f3f8"
        readonly property color chipHoverBg: win.isDark ? "#22222b" : "#e9edf5"
        readonly property color badgeBg: win.isDark ? "#1b1b23" : "#eef1f7"
        readonly property color btnHoverBg: win.isDark ? "#22222b" : "#e8ecf4"
        readonly property color btnPressedBg: win.isDark ? "#2b2b36" : "#dce2ee"
        readonly property color fkeyBg: win.isDark ? "#16161c" : "#ffffff"
        readonly property color fkeyHoverBg: win.isDark ? "#202029" : "#eef2f9"
        readonly property color fkeyPressedBg: win.isDark ? "#2a2a36" : "#e2e8f4"
        readonly property color fkeyBarBg: win.isDark ? "#0b0b0e" : "#f3f5f9"
        readonly property color menuBg: win.isDark ? "#141419" : "#ffffff"
        readonly property color dialogBg: win.isDark ? "#14141a" : "#ffffff"
        readonly property color overlayDim: win.isDark ? Qt.rgba(0.02, 0.02, 0.04, 0.72) : Qt.rgba(0.06, 0.09, 0.16, 0.35)
        readonly property color menuShadow: win.isDark ? "#050507" : "#cbd5e1"

        // Row & Grid states
        readonly property color rowAltBg: win.isDark ? "#0f0f14" : "#f8fafc"
        readonly property color rowHoverBg: win.isDark ? "#191922" : "#eff3f9"
        readonly property color rowCurrentActiveBg: win.isDark ? "#21212c" : "#e4ecf9"
        readonly property color rowCurrentInactiveBg: win.isDark ? "#16161d" : "#edf0f6"
        readonly property color gridCardBg: win.isDark ? "#121217" : "#f8fafc"
        readonly property color scrollbarColor: win.isDark ? "#32323e" : "#cbd5e1"
        readonly property color scrollbarHoverColor: win.isDark ? "#525264" : "#94a3b8"

        // Borders & Dividers
        readonly property color borderSubtle: win.isDark ? "#1c1c24" : "#e7ebf2"
        readonly property color borderDefault: win.isDark ? "#262632" : "#d8dee9"
        readonly property color borderStrong: win.isDark ? "#353545" : "#c3ccdc"
        readonly property color cellDivider: win.isDark ? "#181820" : "#edf0f6"

        // Typography
        readonly property color textPrimary: win.isDark ? "#f4f4f6" : "#0f172a"
        readonly property color textSecondary: win.isDark ? "#d4d4dc" : "#334155"
        readonly property color textMuted: win.isDark ? "#9494a3" : "#5b677d"
        readonly property color textDim: win.isDark ? "#6c6c7c" : "#78849b"
        readonly property color textDisabled: win.isDark ? "#4e4e5c" : "#a0abc0"
        readonly property color textOnHover: win.isDark ? "#ffffff" : "#090d16"

        // Semantic File Icons
        readonly property color iconFolder: win.isDark ? "#f59e0b" : "#d97706"
        readonly property color iconParent: win.isDark ? "#8b8b9c" : "#64748b"
        readonly property color iconCode: win.isDark ? "#60a5fa" : "#2563eb"
        readonly property color iconArchive: win.isDark ? "#fb923c" : "#ea580c"
        readonly property color iconImage: win.isDark ? "#c084fc" : "#9333ea"
        readonly property color iconVideo: win.isDark ? "#f472b6" : "#db2777"
        readonly property color iconAudio: win.isDark ? "#2dd4bf" : "#0d9488"
        readonly property color iconBinary: win.isDark ? "#34d399" : "#059669"
        readonly property color iconDefault: win.isDark ? "#9494a3" : "#64748b"

        // Git & Status Semantics
        readonly property color gitBranchText: win.isDark ? "#60a5fa" : "#2563eb"
        readonly property color gitModBg: win.isDark ? "#451a03" : "#fef3c7"
        readonly property color gitModBorder: win.isDark ? "#f59e0b" : "#d97706"
        readonly property color gitModText: win.isDark ? "#fcd34d" : "#92400e"
        readonly property color gitUntrackedBg: win.isDark ? "#064e3b" : "#d1fae5"
        readonly property color gitUntrackedBorder: win.isDark ? "#10b981" : "#059669"
        readonly property color gitUntrackedText: win.isDark ? "#6ee7b7" : "#065f46"
        readonly property color gitStagedBg: win.isDark ? "#083344" : "#cffafe"
        readonly property color gitStagedBorder: win.isDark ? "#06b6d4" : "#0891b2"
        readonly property color gitStagedText: win.isDark ? "#67e8f9" : "#155e75"
        readonly property color gitDeletedBg: win.isDark ? "#450a0a" : "#fee2e2"
        readonly property color gitDeletedBorder: win.isDark ? "#ef4444" : "#dc2626"
        readonly property color gitDeletedText: win.isDark ? "#fca5a5" : "#991b1b"
        readonly property color gitDefaultBg: win.isDark ? "#1e293b" : "#e2e8f0"
        readonly property color gitDefaultBorder: win.isDark ? "#64748b" : "#64748b"
        readonly property color gitDefaultText: win.isDark ? "#cbd5e1" : "#334155"

        readonly property color dangerText: win.isDark ? "#fca5a5" : "#b91c1c"
        readonly property color dangerAccent: win.isDark ? "#f87171" : "#dc2626"
        readonly property color dangerHoverBg: win.isDark ? "#3b1e22" : "#fee2e2"
        readonly property color successText: win.isDark ? "#22c55e" : "#16a34a"
        readonly property color warningText: win.isDark ? "#f59e0b" : "#d97706"

        // Visual Diff
        readonly property color diffAddedBg: win.isDark ? "#13311f" : "#dcfce7"
        readonly property color diffAddedText: win.isDark ? "#86efac" : "#166534"
        readonly property color diffDeletedBg: win.isDark ? "#361618" : "#fee2e2"
        readonly property color diffDeletedText: win.isDark ? "#fca5a5" : "#991b1b"
        readonly property color diffModifiedBg: win.isDark ? "#32230b" : "#fef3c7"
        readonly property color diffModifiedText: win.isDark ? "#fde68a" : "#92400e"
    }

    property bool windowSessionReady: false
    Component.onCompleted: windowSessionReady = true
    onWidthChanged: if (windowSessionReady && width >= minimumWidth) backend.windowWidth = width
    onHeightChanged: if (windowSessionReady && height >= minimumHeight) backend.windowHeight = height

    Material.theme: win.isDark ? Material.Dark : Material.Light
    Material.accent: p.accent
    // Material.roundedScale is an enum, not a pixel radius; map Hyprland's rounding cleanly.
    Material.roundedScale: theme.radius <= 0 ? Material.NotRounded
                         : theme.radius <= 5 ? Material.ExtraSmallScale
                         : theme.radius <= 10 ? Material.SmallScale
                         : Material.MediumScale

    readonly property int panelRadius: Math.min(8, theme.radius)
    readonly property int smallRadius: Math.min(6, theme.radius)

    // UI State
    property bool helpOpen: false
    property bool previewOpen: false
    property var previewData: ({})
    property bool quickViewActive: false
    property var quickViewData: ({})
    property bool searchOpen: false
    property bool newFolderOpen: false
    property bool renameOpen: false
    property string renameOldPath: ""
    property string renameOldName: ""
    property bool multiRenameOpen: false
    property var multiRenamePreviewList: []
    property bool packArchiveOpen: false
    property bool bookmarksOpen: false
    property bool commandOutputOpen: false
    property string commandOutputText: ""
    property bool confirmCopyOpen: false
    property bool confirmMoveOpen: false
    property bool confirmDeleteOpen: false
    property bool propertiesOpen: false
    property var propData: ({})
    property int propMode: 420
    property bool propSyncingOctal: false
    property bool leftFilterVisible: false
    property bool rightFilterVisible: false
    property bool newFileOpen: false
    property bool symlinkOpen: false
    property bool maskOpen: false
    property bool checksumOpen: false
    property bool diffOpen: false
    property bool aboutOpen: false
    property bool commandPaletteOpen: false
    property string commandPaletteMode: "commands"
    property bool syncDirsOpen: false
    property bool duplicateFinderOpen: false
    property bool queueDialogOpen: false
    property bool remoteConnectionsOpen: false
    property bool openWithOpen: false
    property string openWithTargetPath: ""
    property var openWithAppsList: []
    property var openWithAllApps: []
    property var openWithMimeInfo: ({})
    property int openWithTab: 0
    property bool menuBarActive: false

    Connections {
        target: backend
        function onThemeModeChanged() {
            if (win.quickViewActive)
                win.updateQuickView();
            if (win.previewOpen && win.previewData && win.previewData.path)
                win.previewData = backend.getPreview(win.previewData.path, win.previewData.pdfPage || 1);
        }
    }

    function isAnyMenuOpen() {
        return (typeof filesMenu !== "undefined" && filesMenu.visible) ||
               (typeof editMenu !== "undefined" && editMenu.visible) ||
               (typeof viewMenu !== "undefined" && viewMenu.visible) ||
               (typeof commandsMenu !== "undefined" && commandsMenu.visible) ||
               (typeof helpMenu !== "undefined" && helpMenu.visible) ||
               (typeof leftPane !== "undefined" && leftPane.contextMenu && leftPane.contextMenu.visible) ||
               (typeof rightPane !== "undefined" && rightPane.contextMenu && rightPane.contextMenu.visible);
    }

    function closeAllMenus() {
        if (typeof filesMenu !== "undefined") filesMenu.close();
        if (typeof editMenu !== "undefined") editMenu.close();
        if (typeof viewMenu !== "undefined") viewMenu.close();
        if (typeof commandsMenu !== "undefined") commandsMenu.close();
        if (typeof helpMenu !== "undefined") helpMenu.close();
        if (typeof leftPane !== "undefined" && leftPane.contextMenu) leftPane.contextMenu.close();
        if (typeof rightPane !== "undefined" && rightPane.contextMenu) rightPane.contextMenu.close();
        win.menuBarActive = false;
    }

    // ================= REUSABLE INLINE UI COMPONENTS =================

    // Crisp 16x16 vector icon for files, folders, and UI actions — consistent across all font setups.
    component VectorIcon : Canvas {
        id: iconCanvas
        property string kind: "file"
        property color iconColor: p.iconDefault
        implicitWidth: 16
        implicitHeight: 16
        width: 16
        height: 16

        onKindChanged: requestPaint()
        onIconColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = iconColor;
            ctx.fillStyle = iconColor;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (kind === "folder") {
                ctx.beginPath();
                ctx.moveTo(1.5, 4.5);
                ctx.lineTo(1.5, 13);
                ctx.quadraticCurveTo(1.5, 14, 2.5, 14);
                ctx.lineTo(13.5, 14);
                ctx.quadraticCurveTo(14.5, 14, 14.5, 13);
                ctx.lineTo(14.5, 6);
                ctx.quadraticCurveTo(14.5, 5, 13.5, 5);
                ctx.lineTo(7.8, 5);
                ctx.lineTo(6.3, 3.2);
                ctx.lineTo(2.5, 3.2);
                ctx.quadraticCurveTo(1.5, 3.2, 1.5, 4.5);
                ctx.closePath();
                ctx.globalAlpha = 0.22;
                ctx.fill();
                ctx.globalAlpha = 1.0;
                ctx.stroke();
            } else if (kind === "parent") {
                ctx.beginPath();
                ctx.moveTo(11.5, 12.5);
                ctx.lineTo(7, 12.5);
                ctx.quadraticCurveTo(5, 12.5, 5, 10.5);
                ctx.lineTo(5, 4);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(2.5, 6.8);
                ctx.lineTo(5, 3.8);
                ctx.lineTo(7.5, 6.8);
                ctx.stroke();
            } else if (kind === "code") {
                ctx.beginPath();
                ctx.moveTo(5.5, 4.5);
                ctx.lineTo(2.2, 8);
                ctx.lineTo(5.5, 11.5);
                ctx.moveTo(10.5, 4.5);
                ctx.lineTo(13.8, 8);
                ctx.lineTo(10.5, 11.5);
                ctx.moveTo(8.8, 3.5);
                ctx.lineTo(7.2, 12.5);
                ctx.stroke();
            } else if (kind === "archive") {
                ctx.strokeRect(2.5, 2.5, 11, 11);
                ctx.beginPath();
                ctx.moveTo(2.5, 6);
                ctx.lineTo(13.5, 6);
                ctx.moveTo(8, 2.5);
                ctx.lineTo(8, 10.5);
                ctx.moveTo(6.5, 10.5);
                ctx.lineTo(9.5, 10.5);
                ctx.stroke();
            } else if (kind === "image") {
                ctx.strokeRect(2, 2.5, 12, 11);
                ctx.beginPath();
                ctx.arc(5.5, 6, 1.2, 0, Math.PI * 2);
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(2.5, 12.5);
                ctx.lineTo(6.5, 8.5);
                ctx.lineTo(9.2, 11);
                ctx.lineTo(11.2, 9.2);
                ctx.lineTo(13.5, 12.5);
                ctx.stroke();
            } else if (kind === "video") {
                ctx.strokeRect(2, 3, 12, 10);
                ctx.beginPath();
                ctx.moveTo(6.5, 5.5);
                ctx.lineTo(10.8, 8);
                ctx.lineTo(6.5, 10.5);
                ctx.closePath();
                ctx.fill();
            } else if (kind === "audio") {
                ctx.beginPath();
                ctx.moveTo(6, 11.5);
                ctx.lineTo(6, 4);
                ctx.lineTo(12.5, 2.8);
                ctx.lineTo(12.5, 10.2);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(4.5, 11.8, 1.8, 0, Math.PI * 2);
                ctx.arc(11, 10.5, 1.8, 0, Math.PI * 2);
                ctx.fill();
            } else if (kind === "binary") {
                ctx.strokeRect(2, 2.5, 12, 11);
                ctx.beginPath();
                ctx.moveTo(4.8, 6.2);
                ctx.lineTo(7.2, 8.2);
                ctx.lineTo(4.8, 10.2);
                ctx.moveTo(8.5, 10.2);
                ctx.lineTo(11.2, 10.2);
                ctx.stroke();
            } else if (kind === "drive") {
                ctx.strokeRect(2, 3.5, 12, 9);
                ctx.beginPath();
                ctx.moveTo(2, 9.5);
                ctx.lineTo(14, 9.5);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(11.5, 11, 0.9, 0, Math.PI * 2);
                ctx.fill();
            } else if (kind === "usb") {
                ctx.beginPath();
                ctx.moveTo(8, 2.5); ctx.lineTo(8, 12);
                ctx.moveTo(8, 6); ctx.lineTo(4.5, 8.5); ctx.lineTo(4.5, 11);
                ctx.moveTo(8, 7.5); ctx.lineTo(11.5, 9.5); ctx.lineTo(11.5, 11);
                ctx.stroke();
                ctx.fillRect(7, 2, 2, 2);
                ctx.beginPath();
                ctx.arc(4.5, 11.5, 1, 0, Math.PI * 2);
                ctx.arc(11.5, 11.5, 1, 0, Math.PI * 2);
                ctx.fill();
            } else if (kind === "network") {
                ctx.beginPath();
                ctx.arc(8, 8, 5.5, 0, Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(2.7, 8); ctx.lineTo(13.3, 8);
                ctx.moveTo(8, 2.5); ctx.lineTo(8, 13.5);
                ctx.stroke();
            } else if (kind === "grid") {
                ctx.strokeRect(3, 3, 4, 4);
                ctx.strokeRect(9, 3, 4, 4);
                ctx.strokeRect(3, 9, 4, 4);
                ctx.strokeRect(9, 9, 4, 4);
            } else if (kind === "list") {
                ctx.beginPath();
                ctx.moveTo(3, 4.5); ctx.lineTo(13, 4.5);
                ctx.moveTo(3, 8); ctx.lineTo(13, 8);
                ctx.moveTo(3, 11.5); ctx.lineTo(13, 11.5);
                ctx.stroke();
            } else if (kind === "back") {
                ctx.beginPath();
                ctx.moveTo(10, 3.5);
                ctx.lineTo(5.5, 8);
                ctx.lineTo(10, 12.5);
                ctx.stroke();
            } else if (kind === "forward") {
                ctx.beginPath();
                ctx.moveTo(6, 3.5);
                ctx.lineTo(10.5, 8);
                ctx.lineTo(6, 12.5);
                ctx.stroke();
            } else if (kind === "up") {
                ctx.beginPath();
                ctx.moveTo(8, 12.5);
                ctx.lineTo(8, 3.8);
                ctx.moveTo(4.5, 7.2);
                ctx.lineTo(8, 3.5);
                ctx.lineTo(11.5, 7.2);
                ctx.stroke();
            } else if (kind === "home") {
                ctx.beginPath();
                ctx.moveTo(2.5, 8);
                ctx.lineTo(8, 3);
                ctx.lineTo(13.5, 8);
                ctx.moveTo(4.5, 6.8);
                ctx.lineTo(4.5, 13);
                ctx.lineTo(11.5, 13);
                ctx.lineTo(11.5, 6.8);
                ctx.stroke();
            } else if (kind === "filter") {
                ctx.beginPath();
                ctx.moveTo(2.5, 3.5);
                ctx.lineTo(13.5, 3.5);
                ctx.lineTo(9.5, 8.2);
                ctx.lineTo(9.5, 12.8);
                ctx.lineTo(6.5, 11.5);
                ctx.lineTo(6.5, 8.2);
                ctx.closePath();
                ctx.stroke();
            } else if (kind === "refresh") {
                ctx.beginPath();
                ctx.arc(8, 8, 4.8, 0.35, Math.PI * 1.75);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(10.8, 2.6);
                ctx.lineTo(13, 4.5);
                ctx.lineTo(10.2, 5.4);
                ctx.stroke();
            } else if (kind === "close") {
                ctx.beginPath();
                ctx.moveTo(4.2, 4.2);
                ctx.lineTo(11.8, 11.8);
                ctx.moveTo(11.8, 4.2);
                ctx.lineTo(4.2, 11.8);
                ctx.stroke();
            } else if (kind === "star" || kind === "star-filled") {
                ctx.beginPath();
                for (var i = 0; i < 5; i++) {
                    var outer = (i * 72 - 90) * Math.PI / 180;
                    var inner = ((i * 72 + 36) - 90) * Math.PI / 180;
                    var ox = 8 + Math.cos(outer) * 5.5;
                    var oy = 8.2 + Math.sin(outer) * 5.5;
                    var ix = 8 + Math.cos(inner) * 2.4;
                    var iy = 8.2 + Math.sin(inner) * 2.4;
                    if (i === 0) ctx.moveTo(ox, oy);
                    else ctx.lineTo(ox, oy);
                    ctx.lineTo(ix, iy);
                }
                ctx.closePath();
                if (kind === "star-filled") ctx.fill();
                ctx.stroke();
            } else if (kind === "sun") {
                ctx.beginPath();
                ctx.arc(8, 8, 3.1, 0, Math.PI * 2);
                ctx.stroke();
                for (var r = 0; r < 8; r++) {
                    var angle = (r * 45) * Math.PI / 180;
                    ctx.beginPath();
                    ctx.moveTo(8 + Math.cos(angle) * 4.9, 8 + Math.sin(angle) * 4.9);
                    ctx.lineTo(8 + Math.cos(angle) * 6.4, 8 + Math.sin(angle) * 6.4);
                    ctx.stroke();
                }
            } else if (kind === "moon") {
                var r = 5.0;
                var cx = 8.5, cy = 8.0;
                var a1 = 0.38 * Math.PI;
                var a2 = 1.62 * Math.PI;
                ctx.beginPath();
                ctx.arc(cx, cy, r, a1, a2, false);
                ctx.quadraticCurveTo(5.6, cy, cx + Math.cos(a1) * r, cy + Math.sin(a1) * r);
                ctx.closePath();
                ctx.globalAlpha = 0.22;
                ctx.fill();
                ctx.globalAlpha = 1.0;
                ctx.stroke();
            } else if (kind === "branch") {
                ctx.beginPath();
                ctx.moveTo(3.5, 2.5);
                ctx.lineTo(3.5, 12.5);
                ctx.moveTo(3.5, 3.5);
                ctx.lineTo(7.2, 3.5);
                ctx.moveTo(9.5, 3.5);
                ctx.lineTo(13.5, 3.5);
                ctx.moveTo(3.5, 8.0);
                ctx.lineTo(7.2, 8.0);
                ctx.moveTo(9.5, 8.0);
                ctx.lineTo(13.5, 8.0);
                ctx.moveTo(3.5, 12.5);
                ctx.lineTo(7.2, 12.5);
                ctx.moveTo(9.5, 12.5);
                ctx.lineTo(13.5, 12.5);
                ctx.stroke();
            } else if (kind === "command") {
                ctx.beginPath();
                ctx.roundedRect(1.8, 2.5, 12.4, 11, 2.2, 2.2);
                ctx.globalAlpha = 0.14;
                ctx.fill();
                ctx.globalAlpha = 1.0;
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(4.6, 5.8);
                ctx.lineTo(7.4, 8.0);
                ctx.lineTo(4.6, 10.2);
                ctx.moveTo(8.8, 10.2);
                ctx.lineTo(11.6, 10.2);
                ctx.stroke();
            } else if (kind === "chart") {
                ctx.globalAlpha = 0.22;
                ctx.fillRect(2.5, 9.5, 2.8, 4.0);
                ctx.fillRect(6.6, 3.0, 2.8, 10.5);
                ctx.fillRect(10.7, 6.2, 2.8, 7.3);
                ctx.globalAlpha = 1.0;
                ctx.strokeRect(2.5, 9.5, 2.8, 4.0);
                ctx.strokeRect(6.6, 3.0, 2.8, 10.5);
                ctx.strokeRect(10.7, 6.2, 2.8, 7.3);
            } else if (kind === "sync") {
                ctx.beginPath();
                ctx.moveTo(13.5, 5.2);
                ctx.lineTo(2.8, 5.2);
                ctx.moveTo(5.4, 2.8);
                ctx.lineTo(2.8, 5.2);
                ctx.lineTo(5.4, 7.6);
                ctx.moveTo(2.5, 10.8);
                ctx.lineTo(13.2, 10.8);
                ctx.moveTo(10.6, 8.4);
                ctx.lineTo(13.2, 10.8);
                ctx.lineTo(10.6, 13.2);
                ctx.stroke();
            } else if (kind === "duplicate") {
                ctx.beginPath();
                ctx.moveTo(5.4, 4.4);
                ctx.lineTo(5.4, 2.2);
                ctx.lineTo(13.0, 2.2);
                ctx.lineTo(13.0, 11.2);
                ctx.lineTo(10.8, 11.2);
                ctx.stroke();
                ctx.beginPath();
                ctx.roundedRect(2.6, 4.6, 8.0, 9.2, 1.4, 1.4);
                ctx.globalAlpha = 0.2;
                ctx.fill();
                ctx.globalAlpha = 1.0;
                ctx.stroke();
            } else {
                // Default document icon with folded corner
                ctx.beginPath();
                ctx.moveTo(3.5, 2);
                ctx.lineTo(9.8, 2);
                ctx.lineTo(12.5, 4.8);
                ctx.lineTo(12.5, 14);
                ctx.lineTo(3.5, 14);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(9.5, 2);
                ctx.lineTo(9.5, 5);
                ctx.lineTo(12.5, 5);
                ctx.stroke();
            }
        }
    }

    // Compact icon button that never clips or elides inside narrow toolbars.
    component IconBtn : Rectangle {
        id: iconBtn
        property string iconKind: ""
        property string label: ""
        property string tooltipText: ""
        property bool active: false
        property bool btnEnabled: true
        signal clicked()

        implicitWidth: 26
        implicitHeight: 26
        radius: win.smallRadius
        opacity: btnEnabled ? 1.0 : 0.32
        color: {
            if (!btnEnabled) return "transparent";
            if (btnMouse.pressed) return p.btnPressedBg;
            if (active) return Qt.alpha(p.accent, 0.16);
            if (btnMouse.containsMouse) return p.btnHoverBg;
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(p.accent, 0.5)

        VectorIcon {
            visible: iconBtn.iconKind.length > 0
            anchors.centerIn: parent
            kind: iconBtn.iconKind
            iconColor: iconBtn.active ? p.accent : (btnMouse.containsMouse ? p.textOnHover : p.textMuted)
        }

        Text {
            visible: iconBtn.iconKind.length === 0
            anchors.centerIn: parent
            text: iconBtn.label
            font.pixelSize: 12
            font.bold: true
            color: iconBtn.active ? p.accent : (btnMouse.containsMouse ? p.textOnHover : p.textMuted)
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: iconBtn.btnEnabled
            hoverEnabled: true
            cursorShape: iconBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: iconBtn.clicked()
        }

        ToolTip.visible: btnMouse.containsMouse && iconBtn.tooltipText.length > 0
        ToolTip.delay: 450
        ToolTip.text: iconBtn.tooltipText
    }

    // Compact toolbar button with label and subtle shortcut hint.
    component ToolbarBtn : Rectangle {
        id: tbBtn
        property string label: ""
        property string shortcutHint: ""
        property string tooltipText: ""
        property bool active: false
        property bool accentHighlight: false
        property bool btnEnabled: true
        signal clicked()

        implicitHeight: 26
        implicitWidth: tbRow.implicitWidth + 10
        radius: win.smallRadius
        opacity: btnEnabled ? 1.0 : 0.36
        color: {
            if (!btnEnabled) return "transparent";
            if (tbMouse.pressed) return p.btnPressedBg;
            if (active) return Qt.alpha(p.accent, 0.16);
            if (tbMouse.containsMouse) return p.btnHoverBg;
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(p.accent, 0.5)

        RowLayout {
            id: tbRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: tbBtn.label
                font.pixelSize: 12
                font.weight: (tbBtn.active || tbBtn.accentHighlight) ? Font.DemiBold : Font.Normal
                color: (tbBtn.active || tbBtn.accentHighlight) ? p.accent
                     : (tbMouse.containsMouse && tbBtn.btnEnabled ? p.textPrimary : p.textSecondary)
            }

            Rectangle {
                visible: tbBtn.shortcutHint.length > 0
                implicitHeight: 16
                implicitWidth: hintText.implicitWidth + 8
                radius: Math.min(3, theme.radius)
                color: tbBtn.active ? Qt.alpha(p.accent, 0.18) : p.badgeBg
                border.width: 1
                border.color: tbBtn.active ? Qt.alpha(p.accent, 0.38) : p.borderDefault

                Text {
                    id: hintText
                    anchors.centerIn: parent
                    text: tbBtn.shortcutHint
                    font.pixelSize: 10
                    font.family: "monospace"
                    color: tbBtn.active ? p.accent : p.textMuted
                }
            }
        }

        MouseArea {
            id: tbMouse
            anchors.fill: parent
            enabled: tbBtn.btnEnabled
            hoverEnabled: true
            cursorShape: tbBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: tbBtn.clicked()
        }

        ToolTip.visible: tbMouse.containsMouse && tbBtn.tooltipText.length > 0
        ToolTip.delay: 450
        ToolTip.text: tbBtn.tooltipText
    }

    // Clean desktop menu bar button for top-level dropdown menus (Files, Edit, View, etc.).
    component MenuBarBtn : Rectangle {
        id: mbBtn
        property string label: ""
        property bool active: false
        property alias containsMouse: mbMouse.containsMouse
        signal clicked()
        signal entered()

        implicitHeight: 26
        implicitWidth: mbText.implicitWidth + 18
        radius: win.smallRadius
        color: {
            if (active) return Qt.alpha(p.accent, 0.18);
            if (mbMouse.containsMouse) return p.btnHoverBg;
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(p.accent, 0.5)

        Text {
            id: mbText
            anchors.centerIn: parent
            text: mbBtn.label
            font.pixelSize: 12
            font.weight: mbBtn.active ? Font.DemiBold : Font.Normal
            color: mbBtn.active ? p.accent
                 : (mbMouse.containsMouse ? p.textPrimary : p.textSecondary)
        }

        MouseArea {
            id: mbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mbBtn.clicked()
            onEntered: mbBtn.entered()
        }
    }

    // Sleek themed popup dropdown menu.
    component AppMenu : Menu {
        id: menuRoot
        topPadding: 5
        bottomPadding: 5
        leftPadding: 4
        rightPadding: 4
        modal: false
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            implicitWidth: 310
            color: p.menuBg
            border.width: 1
            border.color: p.borderDefault
            radius: win.panelRadius

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: win.panelRadius + 1
                color: "transparent"
                border.width: 1
                border.color: p.menuShadow
                opacity: win.isDark ? 0.8 : 0.45
            }
        }
    }

    // Sleek styled MenuItem with checkmark support, label, and right-aligned shortcut badge.
    component AppMenuItem : MenuItem {
        id: miRoot
        property string shortcutHint: ""

        implicitWidth: 310
        implicitHeight: visible ? 28 : 0
        height: visible ? 28 : 0
        leftPadding: 10
        rightPadding: 10
        topPadding: 0
        bottomPadding: 0
        indicator: null

        contentItem: RowLayout {
            implicitWidth: 290
            spacing: 8

            // Indicator column: shows checkmark when checked, empty 14px spacer if checkable
            Item {
                visible: miRoot.checkable
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14

                Text {
                    anchors.centerIn: parent
                    visible: miRoot.checked
                    text: "✓"
                    font.pixelSize: 12
                    font.bold: true
                    color: p.accent
                }
            }

            Text {
                text: miRoot.text
                font.pixelSize: 12
                font.weight: miRoot.highlighted ? Font.Medium : Font.Normal
                color: !miRoot.enabled ? p.textDisabled : (miRoot.highlighted ? p.textPrimary : p.textSecondary)
                Layout.fillWidth: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: miRoot.shortcutHint.length > 0
                text: miRoot.shortcutHint
                font.pixelSize: 11
                font.family: "monospace"
                color: !miRoot.enabled ? p.textDisabled : (miRoot.highlighted ? p.accent : p.textMuted)
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            implicitWidth: 310
            implicitHeight: 28
            radius: win.smallRadius
            color: {
                if (!miRoot.enabled) return "transparent";
                if (miRoot.highlighted) return Qt.alpha(p.accent, win.isDark ? 0.2 : 0.14);
                return "transparent";
            }
            border.width: miRoot.highlighted && miRoot.enabled ? 1 : 0
            border.color: Qt.alpha(p.accent, 0.45)
        }
    }

    // Subtle 1px divider between menu item groups.
    component AppMenuSeparator : MenuSeparator {
        id: sepRoot
        implicitHeight: visible ? 9 : 0
        height: visible ? 9 : 0
        topPadding: visible ? 4 : 0
        bottomPadding: visible ? 4 : 0
        leftPadding: 8
        rightPadding: 8
        contentItem: Rectangle {
            implicitHeight: sepRoot.visible ? 1 : 0
            implicitWidth: 294
            color: p.borderSubtle
        }
    }

    // Compact toggle chip for the 3x3 chmod permission matrix in Properties dialog.
    component PermBitBtn : Rectangle {
        id: permBtn
        property string label: ""
        property int bitMask: 0
        readonly property bool isChecked: (win.propMode & bitMask) !== 0

        Layout.fillWidth: true
        implicitHeight: 26
        radius: win.smallRadius
        color: {
            if (permMouse.pressed) return p.btnPressedBg;
            if (isChecked) return Qt.alpha(p.accent, 0.16);
            if (permMouse.containsMouse) return p.btnHoverBg;
            return p.cardBg;
        }
        border.width: 1
        border.color: isChecked ? Qt.alpha(p.accent, 0.55) : p.borderDefault

        Text {
            anchors.centerIn: parent
            text: (permBtn.isChecked ? "✓ " : "  ") + permBtn.label
            font.pixelSize: 11
            font.family: "monospace"
            font.weight: permBtn.isChecked ? Font.DemiBold : Font.Normal
            color: permBtn.isChecked ? p.accent : p.textMuted
        }

        MouseArea {
            id: permMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.togglePermBit(permBtn.bitMask)
        }
    }

    // Clean single-line input field without Material's 56px floating-label box overflow.
    component CompactField : Rectangle {
        id: fieldRoot
        property alias text: textInput.text
        property alias input: textInput
        property alias readOnly: textInput.readOnly
        property string placeholderText: ""
        property bool monospace: false
        signal accepted()
        signal escaped()
        signal textEdited()

        function forceFieldFocus() {
            textInput.forceActiveFocus();
        }

        implicitHeight: 32
        implicitWidth: 240
        radius: win.smallRadius
        color: p.inputBg
        border.width: 1
        border.color: textInput.activeFocus ? p.accent : p.borderDefault
        clip: true

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: textInput.text.length === 0 && !textInput.preeditText
            text: fieldRoot.placeholderText
            font.pixelSize: 12
            font.family: fieldRoot.monospace ? "monospace" : ""
            color: p.textDim
            elide: Text.ElideRight
        }

        TextInput {
            id: textInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 12
            font.family: fieldRoot.monospace ? "monospace" : ""
            color: p.textPrimary
            selectionColor: Qt.alpha(p.accent, 0.35)
            selectedTextColor: p.textOnHover
            selectByMouse: true
            onTextEdited: fieldRoot.textEdited()
            clip: true
            onAccepted: fieldRoot.accepted()
            Keys.onEscapePressed: function(event) {
                fieldRoot.escaped();
                event.accepted = true;
            }
        }
    }

    // Compact selectable filter chip for Search, Sync & Duplicate Finder dialogs.
    component FilterPill : Rectangle {
        id: pillRoot
        property string label: ""
        property bool active: false
        signal clicked()

        implicitHeight: 24
        implicitWidth: pillText.implicitWidth + 14
        radius: win.smallRadius
        color: active ? Qt.alpha(p.accent, win.isDark ? 0.24 : 0.16)
                      : (pillMouse.containsMouse ? p.btnHoverBg : p.cardBg)
        border.width: 1
        border.color: active ? Qt.alpha(p.accent, 0.55) : p.borderDefault

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pillRoot.label
            font.pixelSize: 11
            font.weight: pillRoot.active ? Font.DemiBold : Font.Normal
            color: pillRoot.active ? p.accent : p.textSecondary
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillRoot.clicked()
        }
    }

    // Next-Gen Preview Surface shared by Quick View (Ctrl+Q) and F3 Viewer.
    component RichPreviewSurface : Item {
        id: surface
        property var previewItem: ({})
        property bool markdownRendered: true
        property bool pdfShowImage: true
        property bool mediaPlaying: false
        property int mediaElapsedSecs: 0
        property var playbackPlayer: null
        property var playbackOutput: null

        signal requestPage(int page)

        function stopMediaPlayback() {
            mediaSimTimer.stop();
            mediaPlaying = false;
            mediaElapsedSecs = 0;
            if (playbackPlayer) {
                try { playbackPlayer.stop(); playbackPlayer.destroy(); } catch (e) {}
                playbackPlayer = null;
            }
            if (playbackOutput) {
                try { playbackOutput.destroy(); } catch (e) {}
                playbackOutput = null;
            }
        }

        function toggleMediaPlayback() {
            if (mediaPlaying) {
                mediaSimTimer.stop();
                mediaPlaying = false;
                if (playbackPlayer) {
                    try { playbackPlayer.pause(); } catch (e) {}
                }
                return;
            }
            mediaPlaying = true;
            mediaSimTimer.start();
            if (!playbackPlayer && previewItem && (previewItem.mediaUrl || "").length > 0 && previewItem.isAudio === true) {
                try {
                    playbackOutput = Qt.createQmlObject('import QtMultimedia; AudioOutput {}', surface);
                    playbackPlayer = Qt.createQmlObject('import QtMultimedia; MediaPlayer {}', surface);
                    if (playbackPlayer && playbackOutput) {
                        playbackPlayer.audioOutput = playbackOutput;
                        playbackPlayer.source = previewItem.mediaUrl;
                        playbackPlayer.play();
                    }
                } catch (e) {
                    playbackPlayer = null;
                    playbackOutput = null;
                }
            } else if (playbackPlayer) {
                try { playbackPlayer.play(); } catch (e) {}
            }
        }

        function formatSecs(secs) {
            var m = Math.floor(secs / 60);
            var s = Math.floor(secs % 60);
            return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s);
        }

        onPreviewItemChanged: stopMediaPlayback()
        onVisibleChanged: if (!visible) stopMediaPlayback()
        Component.onDestruction: stopMediaPlayback()

        Timer {
            id: mediaSimTimer
            interval: 1000
            repeat: true
            onTriggered: {
                var totalSecs = Math.floor((surface.previewItem && surface.previewItem.mediaDurationMs ? surface.previewItem.mediaDurationMs : 0) / 1000);
                if (totalSecs > 0 && surface.mediaElapsedSecs >= totalSecs)
                    surface.stopMediaPlayback();
                else
                    surface.mediaElapsedSecs += 1;
            }
        }

        FontLoader {
            id: surfaceFontLoader
            source: (surface.previewItem && surface.previewItem.isFont === true && surface.previewItem.fontUrl) ? surface.previewItem.fontUrl : ""
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            // Format / Metadata / Mode Controls Strip
            Rectangle {
                Layout.fillWidth: true
                height: visible ? 32 : 0
                visible: !!(surface.previewItem && (
                    surface.previewItem.isCode === true || surface.previewItem.isMarkdown === true ||
                    surface.previewItem.isPdf === true || surface.previewItem.isFont === true ||
                    surface.previewItem.isMedia === true || surface.previewItem.hasExif === true
                ))
                color: p.subBarBg
                radius: win.smallRadius
                border.width: 1
                border.color: p.borderSubtle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        height: 20
                        width: badgeLbl.implicitWidth + 12
                        radius: 4
                        color: p.badgeBg
                        Text {
                            id: badgeLbl
                            anchors.centerIn: parent
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "monospace"
                            color: p.accent
                            text: {
                                if (!surface.previewItem) return "";
                                if (surface.previewItem.isPdf) return "PDF";
                                if (surface.previewItem.isFont) return surface.previewItem.fontFormat || "FONT";
                                if (surface.previewItem.isMedia) return surface.previewItem.mediaCodec || "MEDIA";
                                if (surface.previewItem.syntaxLanguage) return surface.previewItem.syntaxLanguage;
                                return surface.previewItem.imageFormat || "EXIF";
                            }
                        }
                    }

                    // Markdown Rendered vs Raw Source toggle
                    RowLayout {
                        visible: !!(surface.previewItem && surface.previewItem.isMarkdown === true)
                        spacing: 4
                        FilterPill {
                            label: qsTr("Rendered")
                            active: surface.markdownRendered
                            onClicked: surface.markdownRendered = true
                        }
                        FilterPill {
                            label: qsTr("Raw Source")
                            active: !surface.markdownRendered
                            onClicked: surface.markdownRendered = false
                        }
                    }

                    // PDF Page Navigation & Mode
                    RowLayout {
                        visible: !!(surface.previewItem && surface.previewItem.isPdf === true)
                        spacing: 6
                        ToolbarBtn {
                            implicitHeight: 22
                            label: "◀ " + qsTr("Prev")
                            btnEnabled: !!(surface.previewItem && (surface.previewItem.pdfPage || 1) > 1)
                            onClicked: surface.requestPage((surface.previewItem.pdfPage || 1) - 1)
                        }
                        Text {
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textSecondary
                            text: surface.previewItem ? qsTr("Page %1 / %2").arg(surface.previewItem.pdfPage || 1).arg(surface.previewItem.pdfPageCount || 1) : ""
                        }
                        ToolbarBtn {
                            implicitHeight: 22
                            label: qsTr("Next") + " ▶"
                            btnEnabled: !!(surface.previewItem && (surface.previewItem.pdfPage || 1) < (surface.previewItem.pdfPageCount || 1))
                            onClicked: surface.requestPage((surface.previewItem.pdfPage || 1) + 1)
                        }
                        FilterPill {
                            visible: !!(surface.previewItem && (surface.previewItem.pdfPageImagePath || "").length > 0)
                            label: surface.pdfShowImage ? qsTr("Page Image") : qsTr("Page Text")
                            active: surface.pdfShowImage
                            onClicked: surface.pdfShowImage = !surface.pdfShowImage
                        }
                    }

                    // EXIF / Font / Media quick summary
                    Text {
                        visible: !!(surface.previewItem && !surface.previewItem.isPdf && !surface.previewItem.isMarkdown)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textSecondary
                        text: {
                            if (!surface.previewItem) return "";
                            if (surface.previewItem.hasExif) return surface.previewItem.exifSummary || "";
                            if (surface.previewItem.isFont) return (surface.previewItem.fontFamily || "") + ((surface.previewItem.fontStyles || "") ? " · " + surface.previewItem.fontStyles : "");
                            if (surface.previewItem.isMedia) {
                                var parts = [];
                                if (surface.previewItem.mediaDuration) parts.push(surface.previewItem.mediaDuration);
                                if (surface.previewItem.mediaResolution) parts.push(surface.previewItem.mediaResolution);
                                if (surface.previewItem.mediaSampleRate) parts.push(surface.previewItem.mediaSampleRate);
                                if (surface.previewItem.mediaBitrate) parts.push(surface.previewItem.mediaBitrate);
                                return parts.join(" · ");
                            }
                            return surface.previewItem.truncated ? qsTr("(showing first 128 KB)") : "";
                        }
                    }

                    Item { Layout.fillWidth: true; visible: !!(surface.previewItem && (surface.previewItem.isPdf || surface.previewItem.isMarkdown)) }
                }
            }

            // 1. Image + EXIF View
            ColumnLayout {
                visible: !!(surface.previewItem && surface.previewItem.isImage === true)
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Image {
                    source: (surface.previewItem && surface.previewItem.imagePath) ? surface.previewItem.imagePath : ""
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 4
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Rectangle {
                    visible: !!(surface.previewItem && surface.previewItem.hasExif === true)
                    Layout.fillWidth: true
                    implicitHeight: exifGrid.implicitHeight + 14
                    color: p.cardBg
                    radius: win.smallRadius
                    border.width: 1
                    border.color: p.borderSubtle

                    GridLayout {
                        id: exifGrid
                        anchors.fill: parent
                        anchors.margins: 7
                        columns: 4
                        columnSpacing: 14
                        rowSpacing: 4

                        Text { text: qsTr("Camera:"); font.pixelSize: 11; color: p.textMuted; visible: !!((surface.previewItem && surface.previewItem.exif && (surface.previewItem.exif.cameraMake || surface.previewItem.exif.cameraModel))) }
                        Text {
                            text: (surface.previewItem && surface.previewItem.exif) ? ((surface.previewItem.exif.cameraMake || "") + " " + (surface.previewItem.exif.cameraModel || "")).trim() : ""
                            font.pixelSize: 11; font.bold: true; color: p.textPrimary
                            visible: text.length > 0
                        }
                        Text { text: qsTr("Date Taken:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.exif && surface.previewItem.exif.dateTaken) }
                        Text { text: (surface.previewItem && surface.previewItem.exif && surface.previewItem.exif.dateTaken) ? surface.previewItem.exif.dateTaken : ""; font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary; visible: text.length > 0 }
                        Text { text: qsTr("Exposure:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.exif && (surface.previewItem.exif.aperture || surface.previewItem.exif.exposure || surface.previewItem.exif.iso)) }
                        Text {
                            text: {
                                if (!surface.previewItem || !surface.previewItem.exif) return "";
                                var pList = [];
                                if (surface.previewItem.exif.aperture) pList.push(surface.previewItem.exif.aperture);
                                if (surface.previewItem.exif.exposure) pList.push(surface.previewItem.exif.exposure);
                                if (surface.previewItem.exif.iso) pList.push("ISO " + surface.previewItem.exif.iso);
                                if (surface.previewItem.exif.focalLength) pList.push(surface.previewItem.exif.focalLength);
                                return pList.join(" · ");
                            }
                            font.pixelSize: 11; font.family: "monospace"; color: p.accent
                            visible: text.length > 0
                        }
                        Text { text: qsTr("GPS:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.exif && surface.previewItem.exif.gpsCoordinates) }
                        Text { text: (surface.previewItem && surface.previewItem.exif && surface.previewItem.exif.gpsCoordinates) ? surface.previewItem.exif.gpsCoordinates : ""; font.pixelSize: 11; font.family: "monospace"; color: p.successText; visible: text.length > 0 }
                    }
                }
            }

            // 2. PDF Preview View
            Item {
                visible: !!(surface.previewItem && surface.previewItem.isPdf === true)
                Layout.fillWidth: true
                Layout.fillHeight: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: surface.pdfShowImage && !!(surface.previewItem && (surface.previewItem.pdfPageImagePath || "").length > 0)
                    source: (surface.previewItem && surface.previewItem.pdfPageImagePath) ? surface.previewItem.pdfPageImagePath : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                ScrollView {
                    anchors.fill: parent
                    visible: !surface.pdfShowImage || !(surface.previewItem && (surface.previewItem.pdfPageImagePath || "").length > 0)
                    clip: true

                    TextArea {
                        text: (surface.previewItem && (surface.previewItem.pdfPageText || surface.previewItem.text)) ? (surface.previewItem.pdfPageText || surface.previewItem.text) : ""
                        readOnly: true
                        wrapMode: TextEdit.WordWrap
                        font.family: "monospace"
                        font.pixelSize: 12
                        color: p.textSecondary
                        background: Rectangle { color: p.inputBg; radius: win.smallRadius; border.width: 1; border.color: p.borderSubtle }
                    }
                }
            }

            // 3. Font Specimen View (.ttf / .otf / .woff)
            ScrollView {
                visible: !!(surface.previewItem && surface.previewItem.isFont === true)
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: surface.width - 16
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: fontHeaderCol.implicitHeight + 20
                        color: p.cardBg
                        radius: win.smallRadius
                        border.width: 1
                        border.color: p.borderDefault

                        ColumnLayout {
                            id: fontHeaderCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Text {
                                text: (surface.previewItem && surface.previewItem.fontFamily) ? surface.previewItem.fontFamily : ""
                                font.family: surfaceFontLoader.status === FontLoader.Ready ? surfaceFontLoader.name : "sans-serif"
                                font.pixelSize: 22
                                font.bold: true
                                color: p.textPrimary
                            }
                            Text {
                                text: qsTr("Format: %1  |  Styles: %2")
                                    .arg(surface.previewItem && surface.previewItem.fontFormat ? surface.previewItem.fontFormat : "")
                                    .arg(surface.previewItem && surface.previewItem.fontStyles ? surface.previewItem.fontStyles : qsTr("Regular"))
                                font.pixelSize: 11
                                color: p.textMuted
                            }
                        }
                    }

                    Repeater {
                        model: [34, 24, 18, 13]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: sampleTxt.implicitHeight + 14
                            color: index % 2 === 0 ? p.rowAltBg : p.inputBg
                            radius: win.smallRadius
                            border.width: 1
                            border.color: p.borderSubtle

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 10
                                Text {
                                    text: modelData + "px"
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: p.textMuted
                                    Layout.preferredWidth: 34
                                }
                                Text {
                                    id: sampleTxt
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    font.family: surfaceFontLoader.status === FontLoader.Ready ? surfaceFontLoader.name : "sans-serif"
                                    font.pixelSize: modelData
                                    color: p.textPrimary
                                    text: (surface.previewItem && surface.previewItem.fontPangram) ? surface.previewItem.fontPangram : "The quick brown fox jumps over the lazy dog — 0123456789"
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: glyphBox.implicitHeight + 16
                        color: p.cardBg
                        radius: win.smallRadius
                        border.width: 1
                        border.color: p.borderSubtle

                        Text {
                            id: glyphBox
                            anchors.fill: parent
                            anchors.margins: 8
                            wrapMode: Text.WordWrap
                            font.family: surfaceFontLoader.status === FontLoader.Ready ? surfaceFontLoader.name : "sans-serif"
                            font.pixelSize: 15
                            color: p.textSecondary
                            text: "ABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789  !@#$%^&*()-_=+[]{};:'\",.<>/?"
                        }
                    }
                }
            }

            // 4. Media Info & Audio/Video Mini-Player View
            Item {
                visible: !!(surface.previewItem && surface.previewItem.isMedia === true)
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 16, 540)
                    implicitHeight: mediaCardCol.implicitHeight + 32
                    color: p.cardBg
                    radius: win.panelRadius
                    border.width: 1
                    border.color: p.borderDefault

                    ColumnLayout {
                        id: mediaCardCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Rectangle {
                                width: 40; height: 40; radius: 8
                                color: Qt.alpha(p.accent, win.isDark ? 0.22 : 0.14)
                                border.width: 1; border.color: Qt.alpha(p.accent, 0.45)
                                Text {
                                    anchors.centerIn: parent
                                    text: (surface.previewItem && surface.previewItem.isVideo) ? "🎬" : "🎵"
                                    font.pixelSize: 18
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: (surface.previewItem && surface.previewItem.name) ? surface.previewItem.name : ""
                                    font.bold: true; font.pixelSize: 14; color: p.textPrimary
                                    elide: Text.ElideMiddle; Layout.fillWidth: true
                                }
                                Text {
                                    text: {
                                        if (!surface.previewItem || !surface.previewItem.mediaInfo) return "";
                                        var mi = surface.previewItem.mediaInfo;
                                        return (mi.artist && mi.title) ? (mi.artist + " — " + mi.title)
                                             : (mi.title ? mi.title : (surface.previewItem.isVideo ? qsTr("Video File") : qsTr("Audio File")));
                                    }
                                    font.pixelSize: 11; color: p.textMuted; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: mediaSpecGrid.implicitHeight + 16
                            color: p.subBarBg
                            radius: win.smallRadius
                            border.width: 1; border.color: p.borderSubtle

                            GridLayout {
                                id: mediaSpecGrid
                                anchors.fill: parent
                                anchors.margins: 8
                                columns: 4
                                columnSpacing: 12
                                rowSpacing: 6

                                Text { text: qsTr("Codec:"); font.pixelSize: 11; color: p.textMuted }
                                Text { text: (surface.previewItem && surface.previewItem.mediaCodec) ? surface.previewItem.mediaCodec : "-"; font.pixelSize: 11; font.bold: true; font.family: "monospace"; color: p.accent }
                                Text { text: qsTr("Duration:"); font.pixelSize: 11; color: p.textMuted }
                                Text { text: (surface.previewItem && surface.previewItem.mediaDuration) ? surface.previewItem.mediaDuration : "-"; font.pixelSize: 11; font.family: "monospace"; color: p.textPrimary }

                                Text { text: qsTr("Bitrate:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.mediaBitrate) }
                                Text { text: (surface.previewItem && surface.previewItem.mediaBitrate) ? surface.previewItem.mediaBitrate : ""; font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary; visible: !!(surface.previewItem && surface.previewItem.mediaBitrate) }
                                Text { text: qsTr("Resolution:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.mediaResolution) }
                                Text { text: (surface.previewItem && surface.previewItem.mediaResolution) ? surface.previewItem.mediaResolution : ""; font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary; visible: !!(surface.previewItem && surface.previewItem.mediaResolution) }

                                Text { text: qsTr("Sample Rate:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && surface.previewItem.mediaSampleRate) }
                                Text { text: (surface.previewItem && surface.previewItem.mediaSampleRate) ? surface.previewItem.mediaSampleRate : ""; font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary; visible: !!(surface.previewItem && surface.previewItem.mediaSampleRate) }
                                Text { text: qsTr("Channels:"); font.pixelSize: 11; color: p.textMuted; visible: !!(surface.previewItem && (surface.previewItem.mediaChannels || 0) > 0) }
                                Text { text: (surface.previewItem && surface.previewItem.mediaChannels) ? String(surface.previewItem.mediaChannels) : ""; font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary; visible: !!(surface.previewItem && (surface.previewItem.mediaChannels || 0) > 0) }
                            }
                        }

                        // Mini-Player Controls
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ToolbarBtn {
                                label: surface.mediaPlaying ? qsTr("Pause") : qsTr("Play")
                                accentHighlight: true
                                onClicked: surface.toggleMediaPlayback()
                            }
                            ToolbarBtn {
                                label: qsTr("Stop")
                                btnEnabled: surface.mediaPlaying || surface.mediaElapsedSecs > 0
                                onClicked: surface.stopMediaPlayback()
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 6
                                radius: 3
                                color: p.borderDefault
                                Rectangle {
                                    property real ratio: {
                                        var totalSecs = Math.max(1, Math.floor((surface.previewItem && surface.previewItem.mediaDurationMs ? surface.previewItem.mediaDurationMs : 0) / 1000));
                                        return Math.min(1.0, surface.mediaElapsedSecs / totalSecs);
                                    }
                                    width: parent.width * ratio
                                    height: parent.height
                                    radius: 3
                                    color: p.accent
                                }
                            }
                            Text {
                                font.pixelSize: 11; font.family: "monospace"; color: p.textSecondary
                                text: surface.formatSecs(surface.mediaElapsedSecs) + ((surface.previewItem && surface.previewItem.mediaDuration) ? (" / " + surface.previewItem.mediaDuration) : "")
                            }
                            ToolbarBtn {
                                label: qsTr("Open Externally")
                                onClicked: if (surface.previewItem && surface.previewItem.path) backend.openItem(surface.previewItem.path)
                            }
                        }
                    }
                }
            }

            // 5. Markdown / Syntax-Highlighted Code / Plain Text View
            ScrollView {
                visible: !!(surface.previewItem && surface.previewItem.isImage !== true && surface.previewItem.isPdf !== true && surface.previewItem.isFont !== true && surface.previewItem.isMedia !== true)
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    readOnly: true
                    wrapMode: (surface.previewItem && surface.previewItem.isMarkdown === true && surface.markdownRendered)
                              ? TextEdit.WordWrap : TextEdit.NoWrap
                    textFormat: (surface.previewItem && ((surface.previewItem.isMarkdown === true && surface.markdownRendered)
                                                  || surface.previewItem.isCode === true))
                                ? TextEdit.RichText : TextEdit.PlainText
                    text: {
                        if (!surface.previewItem) return "";
                        if (surface.previewItem.isMarkdown === true && surface.markdownRendered)
                            return surface.previewItem.renderedHtml || "";
                        if (surface.previewItem.isCode === true && (surface.previewItem.highlightedHtml || "").length > 0)
                            return surface.previewItem.highlightedHtml;
                        return surface.previewItem.text || "";
                    }
                    font.family: (surface.previewItem && surface.previewItem.isMarkdown === true && surface.markdownRendered) ? "sans-serif" : "monospace"
                    font.pixelSize: 12
                    color: p.textSecondary
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 10
                    bottomPadding: 10
                    background: Rectangle { color: p.inputBg; radius: win.smallRadius; border.width: 1; border.color: p.borderSubtle }
                    onLinkActivated: function(link) { Qt.openUrlExternally(link); }
                }
            }
        }
    }

    // Bottom Total-Commander function key button (F3..F10).
    component FKeyButton : Rectangle {
        id: fkeyBtn
        property string keyLabel: ""
        property string actionLabel: ""
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: win.smallRadius
        color: fkeyMouse.pressed ? p.fkeyPressedBg : (fkeyMouse.containsMouse ? p.fkeyHoverBg : p.fkeyBg)
        border.width: 1
        border.color: fkeyMouse.containsMouse ? p.borderStrong : p.borderDefault

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                implicitHeight: 18
                implicitWidth: fkeyText.implicitWidth + 8
                radius: Math.min(3, theme.radius)
                color: Qt.alpha(p.accent, 0.15)

                Text {
                    id: fkeyText
                    anchors.centerIn: parent
                    text: fkeyBtn.keyLabel
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "monospace"
                    color: p.accent
                }
            }

            Text {
                text: fkeyBtn.actionLabel
                font.pixelSize: 12
                font.weight: Font.Medium
                color: fkeyMouse.containsMouse ? p.textPrimary : p.textSecondary
            }
        }

        MouseArea {
            id: fkeyMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fkeyBtn.clicked()
        }
    }

    // Unified Dual-Panel File Browser Pane (used for both Left and Right panels).
    component FilePanel : Rectangle {
        id: panelRoot
        required property int panelIndex
        required property var panelModel
        property bool filterVisible: false
        property bool pathEditing: false
        property alias listView: fileList
        property alias gridView: fileGrid
        readonly property var activeView: panelModel.viewMode === 1 ? fileGrid : fileList
        property alias contextMenu: fileContextMenu
        property alias bgContextMenu: bgContextMenu

        property bool rubberBandActive: false
        property real rubberBandStartX: 0
        property real rubberBandStartY: 0

        function startRubberBand(startX, startY, isCtrl) {
            rubberBandStartX = startX;
            rubberBandStartY = startY;
            rubberBandActive = true;
            if (!isCtrl) {
                panelModel.deselectAll();
            }
            updateRubberBand(startX, startY, isCtrl);
        }

        function updateRubberBand(curX, curY, isCtrl) {
            if (!rubberBandActive) return;
            var rx = Math.min(rubberBandStartX, curX);
            var ry = Math.min(rubberBandStartY, curY);
            var rw = Math.abs(curX - rubberBandStartX);
            var rh = Math.abs(curY - rubberBandStartY);

            rubberBandBox.x = rx;
            rubberBandBox.y = ry;
            rubberBandBox.width = rw;
            rubberBandBox.height = rh;
            rubberBandBox.visible = (rw > 3 || rh > 3);

            if (panelModel.viewMode === 0) { // ListView
                var rowHeight = 27;
                var contentY = fileList.contentY;
                var count = panelModel.itemCount;
                var selectedIndices = [];

                if (rx + rw > 0 && rx < fileList.width) {
                    var firstRow = Math.max(0, Math.floor((ry + contentY) / rowHeight));
                    var lastRow = Math.min(count - 1, Math.floor((ry + rh + contentY) / rowHeight));
                    for (var i = firstRow; i <= lastRow; i++) {
                        if (!panelModel.itemIsDir(i) || panelModel.itemName(i) !== "..") {
                            selectedIndices.push(i);
                        }
                    }
                }
                panelModel.setSelectedIndices(selectedIndices, isCtrl);
            } else { // GridView
                var cellW = fileGrid.cellWidth;
                var cellH = fileGrid.cellHeight;
                var cols = Math.max(1, Math.floor(fileGrid.width / cellW));
                var contentY = fileGrid.contentY;
                var count = panelModel.itemCount;
                var selectedIndices = [];

                for (var j = 0; j < count; j++) {
                    if (panelModel.itemName(j) === "..") continue;
                    var col = j % cols;
                    var row = Math.floor(j / cols);
                    var itemX = col * cellW + 3;
                    var itemY = row * cellH + 3 - contentY;
                    var itemW = cellW - 6;
                    var itemH = cellH - 6;

                    if (rx < itemX + itemW && rx + rw > itemX &&
                        ry < itemY + itemH && ry + rh > itemY) {
                        selectedIndices.push(j);
                    }
                }
                panelModel.setSelectedIndices(selectedIndices, isCtrl);
            }
        }

        function finishRubberBand() {
            rubberBandActive = false;
            rubberBandBox.visible = false;
        }

        // Item Right-Click Context Menu (for files and folders)
        AppMenu {
            id: fileContextMenu
            modal: true
            dim: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            property int targetIndex: -1
            property string targetPath: ""
            property bool isTargetDir: false
            property var contextApps: []
            property var contextCustomActions: []

            onAboutToShow: {
                contextApps = targetPath ? backend.getApplicationsForFile(targetPath) : [];
                contextCustomActions = targetPath ? backend.getCustomActionsForFile(targetPath) : [];
            }

            // 1. Open / View
            AppMenuItem {
                text: fileContextMenu.isTargetDir ? qsTr("Open Folder") : qsTr("View / Preview")
                shortcutHint: fileContextMenu.isTargetDir ? "Enter" : "F3"
                onTriggered: {
                    if (fileContextMenu.isTargetDir) {
                        panelModel.cd(panelModel.itemName(fileContextMenu.targetIndex));
                    } else {
                        win.triggerF3View();
                    }
                }
            }

            AppMenuItem {
                visible: !fileContextMenu.isTargetDir
                text: qsTr("Open (Default App)")
                shortcutHint: "Enter"
                onTriggered: {
                    if (fileContextMenu.targetPath)
                        backend.openItem(fileContextMenu.targetPath);
                }
            }

            AppMenuItem {
                visible: !fileContextMenu.isTargetDir
                text: qsTr("Edit with $EDITOR")
                shortcutHint: "F4"
                onTriggered: {
                    if (fileContextMenu.targetPath)
                        backend.openWithEditor(fileContextMenu.targetPath);
                }
            }

            // 1b. Open With Submenu (XDG MIME compatible applications)
            AppMenu {
                id: openWithSubMenu
                title: qsTr("Open With")
                cascade: true

                Instantiator {
                    model: fileContextMenu.contextApps.slice(0, 10)
                    delegate: AppMenuItem {
                        required property var modelData
                        text: modelData.name + (modelData.isDefault ? " ★" : "")
                        onTriggered: {
                            var paths = win.getSelectedOrCurrentPaths();
                            if (paths.length === 0 && fileContextMenu.targetPath)
                                paths = [fileContextMenu.targetPath];
                            backend.openWithApplication(paths, modelData.desktopId, false);
                        }
                    }
                    onObjectAdded: function(index, object) { openWithSubMenu.insertItem(index, object); }
                    onObjectRemoved: function(index, object) { openWithSubMenu.removeItem(object); }
                }

                AppMenuSeparator {
                    visible: fileContextMenu.contextApps.length > 0
                }

                AppMenuItem {
                    text: qsTr("Choose Application...")
                    shortcutHint: "Ctrl+Shift+O"
                    onTriggered: win.openOpenWithDialog(fileContextMenu.targetPath, 0)
                }
            }

            // 1c. Custom Actions Submenu
            AppMenu {
                id: customActionsSubMenu
                title: qsTr("Custom Actions")
                cascade: true

                Instantiator {
                    model: fileContextMenu.contextCustomActions
                    delegate: AppMenuItem {
                        required property var modelData
                        text: modelData.name
                        onTriggered: win.runCustomActionAndShow(modelData.id, fileContextMenu.targetPath)
                    }
                    onObjectAdded: function(index, object) { customActionsSubMenu.insertItem(index, object); }
                    onObjectRemoved: function(index, object) { customActionsSubMenu.removeItem(object); }
                }

                AppMenuSeparator {
                    visible: fileContextMenu.contextCustomActions.length > 0
                }

                AppMenuItem {
                    text: qsTr("Manage Custom Actions...")
                    shortcutHint: "Ctrl+Shift+O"
                    onTriggered: win.openOpenWithDialog(fileContextMenu.targetPath, 1)
                }
            }

            AppMenuSeparator {}

            // 2. Cut to Clipboard (Ctrl+X)
            AppMenuItem {
                text: qsTr("Cut to Clipboard")
                shortcutHint: "Ctrl+X"
                onTriggered: {
                    var paths = win.getSelectedOrCurrentPaths();
                    if (paths.length > 0)
                        backend.cutToClipboard(paths);
                }
            }

            // 3. Copy to Clipboard (Ctrl+C)
            AppMenuItem {
                text: qsTr("Copy to Clipboard")
                shortcutHint: "Ctrl+C"
                onTriggered: {
                    var paths = win.getSelectedOrCurrentPaths();
                    if (paths.length > 0)
                        backend.copyToClipboard(paths);
                }
            }

            // 3b. Copy Names as Text (, )
            AppMenuItem {
                text: qsTr("Copy Name(s) as Text (, )")
                shortcutHint: "Ctrl+Shift+C"
                onTriggered: {
                    var paths = win.getSelectedOrCurrentPaths();
                    backend.copyNamesAsCsv(paths);
                }
            }

            // 3c. Copy Paths as Text (, )
            AppMenuItem {
                text: qsTr("Copy Path(s) as Text (, )")
                shortcutHint: "Ctrl+Alt+C"
                onTriggered: {
                    var paths = win.getSelectedOrCurrentPaths();
                    backend.copyPathsAsCsv(paths);
                }
            }

            // 4. Paste from Clipboard (Ctrl+V)
            AppMenuItem {
                text: backend.canPaste
                      ? (backend.clipboardIsCut ? qsTr("Paste Cut (%1)").arg(backend.clipboardPaths.length)
                                                : qsTr("Paste (%1)").arg(backend.clipboardPaths.length))
                      : qsTr("Paste")
                shortcutHint: "Ctrl+V"
                enabled: backend.canPaste
                onTriggered: {
                    backend.pasteFromClipboard(panelModel.path);
                }
            }

            AppMenuSeparator {}

            // 5. New File (Shift+F4)
            AppMenuItem {
                text: qsTr("New File...")
                shortcutHint: "Shift+F4"
                onTriggered: win.triggerNewFile()
            }

            // 6. New Folder (F7)
            AppMenuItem {
                text: qsTr("New Folder...")
                shortcutHint: "F7"
                onTriggered: win.triggerF7NewFolder()
            }

            // 7. Rename (Shift+F6)
            AppMenuItem {
                text: qsTr("Rename")
                shortcutHint: "Shift+F6"
                onTriggered: win.triggerRename()
            }

            // 8. Delete (F8)
            AppMenuItem {
                text: qsTr("Delete...")
                shortcutHint: "F8"
                onTriggered: win.triggerF8Delete()
            }

            AppMenuSeparator {}

            // 9. Properties (Alt+Enter)
            AppMenuItem {
                text: qsTr("Properties & Permissions...")
                shortcutHint: "Alt+Enter"
                onTriggered: win.triggerProperties()
            }
        }

        // Background Right-Click Context Menu (for empty spaces)
        AppMenu {
            id: bgContextMenu
            modal: true
            dim: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            // 1. Paste from Clipboard (Ctrl+V)
            AppMenuItem {
                text: backend.canPaste
                      ? (backend.clipboardIsCut ? qsTr("Paste Cut (%1)").arg(backend.clipboardPaths.length)
                                                : qsTr("Paste (%1)").arg(backend.clipboardPaths.length))
                      : qsTr("Paste")
                shortcutHint: "Ctrl+V"
                enabled: backend.canPaste
                onTriggered: {
                    backend.pasteFromClipboard(panelModel.path);
                }
            }

            // 1b. Copy All Names in Folder
            AppMenuItem {
                text: qsTr("Copy All Names in Folder (, )")
                onTriggered: backend.copyFolderContentsAsCsv(panelModel.path, false)
            }

            // 1c. Copy All Paths in Folder
            AppMenuItem {
                text: qsTr("Copy All Paths in Folder (, )")
                onTriggered: backend.copyFolderContentsAsCsv(panelModel.path, true)
            }

            AppMenuSeparator {}

            // 2. New File (Shift+F4)
            AppMenuItem {
                text: qsTr("New File...")
                shortcutHint: "Shift+F4"
                onTriggered: win.triggerNewFile()
            }

            // 3. New Folder (F7)
            AppMenuItem {
                text: qsTr("New Folder...")
                shortcutHint: "F7"
                onTriggered: win.triggerF7NewFolder()
            }

            AppMenuSeparator {}

            // 4. Select All (Ctrl+A)
            AppMenuItem {
                text: qsTr("Select All")
                shortcutHint: "Ctrl+A"
                onTriggered: panelModel.selectAll()
            }

            // 5. Refresh (Ctrl+R)
            AppMenuItem {
                text: qsTr("Refresh")
                shortcutHint: "Ctrl+R"
                onTriggered: panelModel.refresh()
            }

            // 6. Open Terminal Here (F9)
            AppMenuItem {
                text: qsTr("Open Terminal Here")
                shortcutHint: "F9"
                onTriggered: backend.openInTerminal(panelModel.path)
            }
        }

        readonly property bool isActive: backend.activePanel === panelIndex
        readonly property int colExtWidth: width < 480 ? 48 : 58
        readonly property int colSizeWidth: panelModel.diskUsageMode ? (width < 480 ? 110 : 128) : (width < 480 ? 74 : 84)
        readonly property int colDateWidth: width < 480 ? 114 : 124

        function focusList() {
            backend.activePanel = panelIndex;
            pathEditing = false;
            activeView.forceActiveFocus();
        }

        function openPathEditor() {
            backend.activePanel = panelIndex;
            pathEditField.text = panelModel.path;
            pathEditing = true;
            pathEditField.forceFieldFocus();
            pathEditField.input.selectAll();
        }

        function setFilterOpen(open) {
            filterVisible = open;
            if (open) {
                backend.activePanel = panelIndex;
                filterField.forceFieldFocus();
            } else {
                panelModel.setFilter("");
                focusList();
            }
        }

        function pathSegments(fullPath) {
            if (!fullPath || fullPath === "/")
                return [{ label: "/", target: "/" }];
            var parts = fullPath.split("/");
            var out = [{ label: "/", target: "/" }];
            var accum = "";
            for (var i = 0; i < parts.length; i++) {
                if (parts[i].length === 0)
                    continue;
                accum += "/" + parts[i];
                out.push({ label: parts[i], target: accum });
            }
            return out;
        }

        function displayStem(name, ext, isDir) {
            if (isDir || !ext || ext.length === 0)
                return name;
            // Keep dotfiles like .bashrc (or nested sub/.gitignore in Flat View) intact in the Name column.
            var nestedDot = "/." + ext;
            if (name === "." + ext || (name.length > nestedDot.length && name.slice(-nestedDot.length) === nestedDot))
                return name;
            var suffix = "." + ext;
            if (name.length > suffix.length && name.slice(-suffix.length) === suffix)
                return name.slice(0, name.length - suffix.length);
            return name;
        }

        function displayExt(name, ext, isDir) {
            var nestedDot = "/." + ext;
            if (isDir || !ext || ext.length === 0 || name === "." + ext
                    || (name.length > nestedDot.length && name.slice(-nestedDot.length) === nestedDot))
                return "";
            return ext;
        }

        function iconKindFor(isParent, isDir, iconType) {
            if (isParent) return "parent";
            if (isDir) return "folder";
            if (iconType === "code" || iconType === "image" || iconType === "archive"
                || iconType === "video" || iconType === "audio" || iconType === "binary")
                return iconType;
            return "file";
        }

        function iconColorFor(isParent, isDir, iconType, isSelected) {
            if (isSelected) return p.accent;
            if (isParent) return p.iconParent;
            if (isDir) return p.iconFolder;
            if (iconType === "code") return p.iconCode;
            if (iconType === "archive") return p.iconArchive;
            if (iconType === "image") return p.iconImage;
            if (iconType === "video") return p.iconVideo;
            if (iconType === "audio") return p.iconAudio;
            if (iconType === "binary") return p.iconBinary;
            return p.iconDefault;
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: isActive ? p.panelActiveBg : p.panelInactiveBg
        border.width: 1
        border.color: isActive ? Qt.alpha(p.accent, 0.65) : p.borderDefault
        radius: win.panelRadius
        clip: true

        // Top active-panel accent indicator line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            visible: panelRoot.isActive
            color: p.accent
            z: 5
        }

        // Quick View overlay when the OPPOSITE panel is active and QuickView is ON
        Rectangle {
            visible: win.quickViewActive && !panelRoot.isActive
            anchors.fill: parent
            anchors.margins: 1
            color: p.panelActiveBg
            radius: Math.max(0, win.panelRadius - 1)
            z: 10

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: p.panelHeaderActiveBg

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: qsTr("Quick View: %1").arg(win.quickViewData.name || "")
                            font.bold: true
                            font.pixelSize: 12
                            color: p.accent
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }

                        Text {
                            visible: (win.quickViewData.formattedSize || "").length > 0
                            text: win.quickViewData.formattedSize || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textMuted
                        }

                        Text {
                            visible: win.quickViewData.isImage === true && (win.quickViewData.imageDimensions || "").length > 0
                            text: (win.quickViewData.imageDimensions || "") + (win.quickViewData.imageFormat ? " (" + win.quickViewData.imageFormat + ")" : "")
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textSecondary
                        }

                        IconBtn {
                            iconKind: "close"
                            tooltipText: qsTr("Close Quick View (Ctrl+Q)")
                            onClicked: win.quickViewActive = false
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: p.borderSubtle
                    }
                }

                RichPreviewSurface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 8
                    previewItem: win.quickViewData
                    onRequestPage: function(page) {
                        if (win.quickViewData && win.quickViewData.path)
                            win.quickViewData = backend.getPreview(win.quickViewData.path, page);
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // 0. Per-Panel Tab Strip (Ctrl+T new tab, Ctrl+W close tab, Ctrl+Tab cycle, Drop onto tab)
            Rectangle {
                Layout.fillWidth: true
                height: 29
                color: p.tabStripBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 4

                    Flickable {
                        id: tabFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: tabsRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        onContentWidthChanged: {
                            if (contentWidth > width)
                                contentX = contentWidth - width;
                            else
                                contentX = 0;
                        }

                        Row {
                            id: tabsRow
                            height: parent.height
                            spacing: 3

                            Repeater {
                                model: panelRoot.panelModel.tabs

                                delegate: Rectangle {
                                    id: tabPill
                                    readonly property bool isTabActive: index === panelRoot.panelModel.activeTab
                                    property bool dropHover: tabDropArea.containsDrag

                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 22
                                    width: Math.min(180, Math.max(72, tabContentRow.implicitWidth + 14))
                                    radius: win.smallRadius
                                    color: {
                                        if (dropHover) return Qt.alpha(p.accent, 0.24);
                                        if (isTabActive) return panelRoot.isActive ? p.tabActivePanelBg : p.tabActiveInactivePanelBg;
                                        if (tabMouse.containsMouse) return p.tabHoverBg;
                                        return "transparent";
                                    }
                                    border.width: (isTabActive || dropHover) ? 1 : 0
                                    border.color: dropHover ? p.accent
                                                : (panelRoot.isActive ? Qt.alpha(p.accent, 0.52) : p.borderDefault)

                                    MouseArea {
                                        id: tabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.MiddleButton) {
                                                if (panelRoot.panelModel.tabCount > 1)
                                                    panelRoot.panelModel.closeTab(index);
                                            } else {
                                                backend.activePanel = panelRoot.panelIndex;
                                                panelRoot.panelModel.setActiveTab(index);
                                                fileList.forceActiveFocus();
                                            }
                                        }
                                    }

                                    DropArea {
                                        id: tabDropArea
                                        anchors.fill: parent
                                        onEntered: function(drag) {
                                            drag.accept((drag.modifiers & Qt.ShiftModifier) ? Qt.MoveAction : Qt.CopyAction);
                                        }
                                        onDropped: function(drop) {
                                            var moveOp = (drop.modifiers & Qt.ShiftModifier) !== 0
                                                         || drop.supportedActions === Qt.MoveAction;
                                            if (backend.handleDrop(drop.urls, modelData.path, moveOp))
                                                drop.acceptProposedAction();
                                        }
                                    }

                                    RowLayout {
                                        id: tabContentRow
                                        anchors.fill: parent
                                        anchors.leftMargin: 7
                                        anchors.rightMargin: panelRoot.panelModel.tabCount > 1 ? 4 : 7
                                        spacing: 5

                                        VectorIcon {
                                            width: 12
                                            height: 12
                                            kind: "folder"
                                            iconColor: tabPill.isTabActive
                                                       ? (panelRoot.isActive ? p.accent : p.textMuted)
                                                       : p.textDim
                                        }

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            font.weight: tabPill.isTabActive ? Font.DemiBold : Font.Normal
                                            color: tabPill.isTabActive ? p.textPrimary
                                                 : (tabMouse.containsMouse ? p.textSecondary : p.textMuted)
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                        }

                                        Rectangle {
                                            visible: panelRoot.panelModel.tabCount > 1
                                            width: 15
                                            height: 15
                                            radius: Math.min(3, theme.radius)
                                            color: closeTabMouse.containsMouse ? p.btnHoverBg : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "×"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: closeTabMouse.containsMouse ? p.textPrimary : p.textMuted
                                            }

                                            MouseArea {
                                                id: closeTabMouse
                                                anchors.fill: parent
                                                z: 2
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: panelRoot.panelModel.closeTab(index)
                                            }
                                        }
                                    }

                                    ToolTip.visible: tabMouse.containsMouse
                                    ToolTip.delay: 500
                                    ToolTip.text: modelData.path
                                }
                            }
                        }
                    }

                    IconBtn {
                        implicitWidth: 22
                        implicitHeight: 22
                        label: "+"
                        tooltipText: qsTr("New tab (Ctrl+T)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.addTab();
                            fileList.forceActiveFocus();
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }
            }

            // 1. Panel Header: History, Breadcrumb / Editable Path Bar, Bookmark, Filter & Refresh
            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: panelRoot.isActive ? p.panelHeaderActiveBg : p.panelHeaderInactiveBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 3

                    IconBtn {
                        iconKind: "back"
                        btnEnabled: panelRoot.panelModel.canGoBack
                        tooltipText: qsTr("Back (Alt+Left)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.goBack();
                            fileList.forceActiveFocus();
                        }
                    }

                    IconBtn {
                        iconKind: "forward"
                        btnEnabled: panelRoot.panelModel.canGoForward
                        tooltipText: qsTr("Forward (Alt+Right)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.goForward();
                            fileList.forceActiveFocus();
                        }
                    }

                    IconBtn {
                        iconKind: "up"
                        btnEnabled: panelRoot.panelModel.path !== "/"
                        tooltipText: qsTr("Parent folder (Backspace)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.cdUp();
                            fileList.forceActiveFocus();
                        }
                    }

                    IconBtn {
                        iconKind: "home"
                        tooltipText: qsTr("Home (~)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.setPath("~");
                            fileList.forceActiveFocus();
                        }
                    }

                    // Recessed Path Box: Clickable Breadcrumbs + 1-click Path Edit (or Ctrl+L)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        // Breadcrumb Bar (normal state)
                        Rectangle {
                            anchors.fill: parent
                            visible: !panelRoot.pathEditing
                            radius: win.smallRadius
                            color: p.breadcrumbBg
                            border.width: 1
                            border.color: panelRoot.isActive ? p.borderStrong : p.borderDefault
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 4
                                spacing: 2

                                Flickable {
                                    id: crumbFlick
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    contentWidth: crumbRow.implicitWidth
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    onContentWidthChanged: {
                                        if (contentWidth > width)
                                            contentX = contentWidth - width;
                                        else
                                            contentX = 0;
                                    }

                                    // Clicking empty space to the right of breadcrumbs opens text editor
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: panelRoot.openPathEditor()
                                    }

                                    Row {
                                        id: crumbRow
                                        height: parent.height
                                        spacing: 1

                                        Repeater {
                                            model: panelRoot.pathSegments(panelRoot.panelModel.path)

                                            delegate: Row {
                                                height: crumbRow.height
                                                spacing: 1
                                                readonly property bool isLast: index === (crumbRepeaterCount - 1)
                                                property int crumbRepeaterCount: panelRoot.pathSegments(panelRoot.panelModel.path).length

                                                Text {
                                                    visible: index > 0 && modelData.label !== "/"
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "›"
                                                    font.pixelSize: 12
                                                    color: p.textDim
                                                }

                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 22
                                                    width: segText.implicitWidth + 10
                                                    radius: Math.min(3, theme.radius)
                                                    color: segMouse.containsMouse ? p.btnHoverBg : "transparent"

                                                    Text {
                                                        id: segText
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        font.pixelSize: 12
                                                        font.family: "monospace"
                                                        font.weight: isLast ? Font.DemiBold : Font.Normal
                                                        color: isLast ? (panelRoot.isActive ? p.textPrimary : p.textSecondary)
                                                             : (segMouse.containsMouse ? p.textPrimary : p.textMuted)
                                                    }

                                                    MouseArea {
                                                        id: segMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: isLast ? Qt.IBeamCursor : Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (isLast) {
                                                                panelRoot.openPathEditor();
                                                            } else {
                                                                backend.activePanel = panelRoot.panelIndex;
                                                                panelRoot.panelModel.setPath(modelData.target);
                                                                fileList.forceActiveFocus();
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: panelRoot.panelModel.isArchiveView
                                    implicitHeight: 18
                                    implicitWidth: archBadgeText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha(p.accent, 0.16)
                                    border.width: 1
                                    border.color: Qt.alpha(p.accent, 0.45)
                                    Text {
                                        id: archBadgeText
                                        anchors.centerIn: parent
                                        text: qsTr("Archive")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.accent
                                    }
                                }

                                Rectangle {
                                    visible: panelRoot.panelModel.flatView
                                    implicitHeight: 18
                                    implicitWidth: flatBadgeText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha(p.accent, 0.16)
                                    border.width: 1
                                    border.color: Qt.alpha(p.accent, 0.45)
                                    Text {
                                        id: flatBadgeText
                                        anchors.centerIn: parent
                                        text: qsTr("Flat")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.accent
                                    }
                                }

                                Rectangle {
                                    visible: panelRoot.panelModel.isCollectionView
                                    implicitHeight: 18
                                    implicitWidth: colBadgeText.implicitWidth + 10
                                    radius: 3
                                    color: Qt.alpha(p.accent, 0.18)
                                    border.width: 1
                                    border.color: Qt.alpha(p.accent, 0.5)
                                    Text {
                                        id: colBadgeText
                                        anchors.centerIn: parent
                                        text: (panelRoot.panelModel.collectionTitle || qsTr("Results")) + "  ×"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.accent
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            backend.activePanel = panelRoot.panelIndex;
                                            panelRoot.panelModel.exitCollectionView();
                                            panelRoot.focusList();
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: panelRoot.panelModel.diskUsageMode
                                    implicitHeight: 18
                                    implicitWidth: duBadgeText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha(p.accent, 0.16)
                                    border.width: 1
                                    border.color: Qt.alpha(p.accent, 0.45)
                                    Text {
                                        id: duBadgeText
                                        anchors.centerIn: parent
                                        text: qsTr("Disk Usage")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.accent
                                    }
                                }

                                Rectangle {
                                    visible: !panelRoot.panelModel.isWritable && !panelRoot.panelModel.isArchiveView
                                    implicitHeight: 18
                                    implicitWidth: roText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha(p.dangerAccent, 0.14)
                                    border.width: 1
                                    border.color: Qt.alpha(p.dangerAccent, 0.4)
                                    Text {
                                        id: roText
                                        anchors.centerIn: parent
                                        text: qsTr("Read-Only")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.dangerText
                                    }
                                }

                                IconBtn {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    iconKind: {
                                        // Read backend.bookmarks so the binding updates live on toggle.
                                        var _ = backend.bookmarks;
                                        return backend.isBookmarked(panelRoot.panelModel.path) ? "star-filled" : "star";
                                    }
                                    active: {
                                        var _ = backend.bookmarks;
                                        return backend.isBookmarked(panelRoot.panelModel.path);
                                    }
                                    tooltipText: qsTr("Bookmark current folder")
                                    onClicked: {
                                        backend.activePanel = panelRoot.panelIndex;
                                        backend.toggleBookmark(panelRoot.panelModel.path);
                                    }
                                }
                            }
                        }

                        // Direct Path Input (when editing via click or Ctrl+L)
                        CompactField {
                            id: pathEditField
                            anchors.fill: parent
                            visible: panelRoot.pathEditing
                            monospace: true
                            placeholderText: qsTr("Enter folder path...")
                            onAccepted: {
                                panelRoot.pathEditing = false;
                                panelRoot.panelModel.setPath(pathEditField.text);
                                fileList.forceActiveFocus();
                            }
                            onEscaped: {
                                panelRoot.pathEditing = false;
                                fileList.forceActiveFocus();
                            }
                            Connections {
                                target: pathEditField.input
                                function onActiveFocusChanged() {
                                    if (!pathEditField.input.activeFocus && panelRoot.pathEditing)
                                        panelRoot.pathEditing = false;
                                }
                            }
                        }
                    }

                    IconBtn {
                        iconKind: "chart"
                        active: panelRoot.panelModel.diskUsageMode
                        tooltipText: qsTr("Disk Usage Analyzer (Ctrl+Shift+D)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.toggleDiskUsageMode();
                            panelRoot.focusList();
                        }
                    }

                    IconBtn {
                        iconKind: "branch"
                        active: panelRoot.panelModel.flatView
                        tooltipText: qsTr("Flat / Branch View (Ctrl+Shift+B)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.toggleFlatView();
                            panelRoot.focusList();
                        }
                    }

                    IconBtn {
                        iconKind: "filter"
                        active: panelRoot.filterVisible || panelRoot.panelModel.filter.length > 0
                        tooltipText: qsTr("Quick filter (Ctrl+S)")
                        onClicked: panelRoot.setFilterOpen(!(panelRoot.filterVisible || panelRoot.panelModel.filter.length > 0))
                    }

                    IconBtn {
                        iconKind: "refresh"
                        tooltipText: qsTr("Refresh (Ctrl+R)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.refresh();
                            panelRoot.focusList();
                        }
                    }

                    IconBtn {
                        iconKind: panelRoot.panelModel.viewMode === 1 ? "grid" : "list"
                        label: panelRoot.panelModel.viewMode === 1 ? "☷" : "☰"
                        active: panelRoot.panelModel.viewMode === 1
                        tooltipText: panelRoot.panelModel.viewMode === 1 ? qsTr("Switch to List View (Ctrl+1)") : qsTr("Switch to Grid View (Ctrl+2)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            panelRoot.panelModel.toggleViewMode();
                            panelRoot.focusList();
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }
            }

            // 2. Quick Filter Bar (Ctrl+S)
            Rectangle {
                visible: panelRoot.filterVisible || panelRoot.panelModel.filter.length > 0
                Layout.fillWidth: true
                height: 34
                color: p.filterBarBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: qsTr("Filter:")
                        font.pixelSize: 11
                        font.bold: true
                        color: p.accent
                    }

                    CompactField {
                        id: filterField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        placeholderText: qsTr("Type to filter files...")
                        Binding {
                            target: filterField
                            property: "text"
                            value: panelRoot.panelModel.filter
                            when: !filterField.input.activeFocus
                        }
                        Connections {
                            target: filterField.input
                            function onTextEdited() {
                                panelRoot.panelModel.setFilter(filterField.text);
                            }
                        }
                        onAccepted: fileList.forceActiveFocus()
                        onEscaped: panelRoot.setFilterOpen(false)
                    }

                    IconBtn {
                        implicitWidth: 22
                        implicitHeight: 22
                        iconKind: "close"
                        tooltipText: qsTr("Clear filter (Esc)")
                        onClicked: panelRoot.setFilterOpen(false)
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }
            }

            // 3. Table Column Header (exact pixel match with ListView rows)
            Rectangle {
                visible: panelRoot.panelModel.viewMode === 0
                Layout.fillWidth: true
                height: 26
                color: p.tableHeaderBg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Name Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: nameHdrMouse.containsMouse ? p.tableHeaderHoverBg : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Name") + (panelRoot.panelModel.sortField === 0 ? (panelRoot.panelModel.sortAscending ? "  ↑" : "  ↓") : "")
                            color: panelRoot.panelModel.sortField === 0 ? p.accent : p.textMuted
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: nameHdrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelRoot.focusList();
                                panelRoot.panelModel.setSortField(0);
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Ext Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colExtWidth
                        Layout.fillHeight: true
                        color: extHdrMouse.containsMouse ? p.tableHeaderHoverBg : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Ext") + (panelRoot.panelModel.sortField === 1 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 1 ? p.accent : p.textMuted
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: extHdrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelRoot.focusList();
                                panelRoot.panelModel.setSortField(1);
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Size Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colSizeWidth
                        Layout.fillHeight: true
                        color: sizeHdrMouse.containsMouse ? p.tableHeaderHoverBg : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: qsTr("Size") + (panelRoot.panelModel.sortField === 2 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 2 ? p.accent : p.textMuted
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideLeft
                        }

                        MouseArea {
                            id: sizeHdrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelRoot.focusList();
                                panelRoot.panelModel.setSortField(2);
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Date Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colDateWidth
                        Layout.fillHeight: true
                        color: dateHdrMouse.containsMouse ? p.tableHeaderHoverBg : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: qsTr("Modified") + (panelRoot.panelModel.sortField === 3 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 3 ? p.accent : p.textMuted
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideLeft
                        }

                        MouseArea {
                            id: dateHdrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelRoot.focusList();
                                panelRoot.panelModel.setSortField(3);
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderDefault
                }
            }

            // 4. Files ListView + Drag & Drop Target Surface
            Item {
                id: viewContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Translucent Rubberband selection rectangle
                Rectangle {
                    id: rubberBandBox
                    visible: false
                    z: 99
                    color: Qt.alpha(p.accent, 0.20)
                    border.width: 1
                    border.color: p.accent
                    radius: 2
                }

                ListView {
                    id: fileList
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: panelRoot.panelModel
                    visible: panelRoot.panelModel.viewMode === 0
                    focus: panelRoot.isActive && panelRoot.panelModel.viewMode === 0

                    onCountChanged: {
                        if (count > 0 && currentIndex < 0)
                            currentIndex = 0;
                    }
                    onCurrentIndexChanged: {
                        if (panelRoot.isActive)
                            win.updateQuickView();
                        if (panelRoot.panelModel.viewMode === 0 && fileGrid.currentIndex !== currentIndex)
                            fileGrid.currentIndex = currentIndex;
                    }

                    // Click on empty space below items activates panel, handles rubberband & background context menu
                    MouseArea {
                        id: listBackgroundMouse
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        preventStealing: true
                        property real startX: 0
                        property real startY: 0
                        property bool dragStarted: false

                        onPressed: function(mouse) {
                            panelRoot.focusList();
                            if (mouse.button === Qt.RightButton) {
                                var pt = listBackgroundMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                                bgContextMenu.popup(panelRoot, pt.x, pt.y);
                                return;
                            }
                            if (mouse.button === Qt.LeftButton) {
                                startX = mouse.x;
                                startY = mouse.y;
                                dragStarted = false;
                                var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                var pt = listBackgroundMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                panelRoot.startRubberBand(pt.x, pt.y, isCtrl);
                            }
                        }
                        onPositionChanged: function(mouse) {
                            if (mouse.buttons & Qt.LeftButton) {
                                var dx = mouse.x - startX;
                                var dy = mouse.y - startY;
                                if (!dragStarted && (dx * dx + dy * dy > 16)) {
                                    dragStarted = true;
                                }
                                if (dragStarted) {
                                    var pt = listBackgroundMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                    var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    panelRoot.updateRubberBand(pt.x, pt.y, isCtrl);
                                }
                            }
                        }
                        onReleased: function(mouse) {
                            if (dragStarted) {
                                panelRoot.finishRubberBand();
                                dragStarted = false;
                            } else if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier) === 0) {
                                panelModel.deselectAll();
                                panelRoot.finishRubberBand();
                            }
                        }
                    }

                    // Slim custom scrollbar that only appears when content actually overflows
                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AsNeeded
                        width: 6
                        padding: 1
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            visible: vbar.size < 1.0
                            color: vbar.pressed ? p.accent : (vbar.hovered ? p.scrollbarHoverColor : p.scrollbarColor)
                        }
                        background: Item {}
                    }

                    delegate: Rectangle {
                        id: rowDelegate
                        width: fileList.width
                        height: 27
                        property string itemPermissions: model.permissions || ""
                        readonly property bool isCurrent: fileList.currentIndex === index
                        readonly property bool isCutItem: backend.clipboardIsCut && backend.clipboardPaths.indexOf(model.path) !== -1
                        readonly property bool isDropTargetDir: panelDropArea.containsDrag && panelDropArea.hoveredDirIndex === index

                        opacity: isCutItem ? 0.48 : 1.0
                        border.width: isDropTargetDir ? 1 : 0
                        border.color: p.accent

                        color: {
                            if (isDropTargetDir)
                                return Qt.alpha(p.accent, 0.24);
                            if (model.isSelected && isCurrent && panelRoot.isActive)
                                return Qt.alpha(p.accent, win.isDark ? 0.26 : 0.18);
                            if (model.isSelected)
                                return Qt.alpha(p.accent, win.isDark ? 0.16 : 0.11);
                            if (isCurrent && panelRoot.isActive)
                                return p.rowCurrentActiveBg;
                            if (isCurrent)
                                return p.rowCurrentInactiveBg;
                            if (rowMouse.containsMouse)
                                return p.rowHoverBg;
                            return index % 2 === 0 ? "transparent" : p.rowAltBg;
                        }

                        // Crisp left cursor / selection accent bar instead of a noisy 4-sided box
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: (rowDelegate.isCurrent && panelRoot.isActive) ? 3 : (model.isSelected ? 2 : 0)
                            visible: width > 0
                            color: p.accent
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            property real pressX: 0
                            property real pressY: 0
                            property bool dragStarted: false
                            property bool isRubberBandDrag: false

                            function isBlankArea(x) {
                                var textRight = 34 + rowNameText.implicitWidth;
                                return x > textRight + 20;
                            }

                            onPressed: function(mouse) {
                                pressX = mouse.x;
                                pressY = mouse.y;
                                dragStarted = false;
                                isRubberBandDrag = false;
                                panelRoot.focusList();

                                if (mouse.button === Qt.RightButton) {
                                    if (!panelRoot.panelModel.itemIsSelected(index)) {
                                        if ((mouse.modifiers & Qt.ControlModifier) === 0)
                                            panelRoot.panelModel.deselectAll();
                                        if (!model.isParent)
                                            panelRoot.panelModel.setItemSelected(index, true);
                                    }
                                    fileList.currentIndex = index;
                                    fileContextMenu.targetIndex = index;
                                    fileContextMenu.targetPath = model.path;
                                    fileContextMenu.isTargetDir = model.isDir;
                                    var pt = rowMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                                    fileContextMenu.popup(panelRoot, pt.x, pt.y);
                                    return;
                                }

                                if (mouse.button === Qt.LeftButton) {
                                    var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    var isShift = (mouse.modifiers & Qt.ShiftModifier) !== 0;

                                    if (isCtrl) {
                                        if (!model.isParent)
                                            panelRoot.panelModel.toggleSelection(index);
                                        fileList.currentIndex = index;
                                    } else if (isShift) {
                                        var anchor = fileList.currentIndex >= 0 ? fileList.currentIndex : index;
                                        panelRoot.panelModel.selectRange(anchor, index, true);
                                        fileList.currentIndex = index;
                                    } else {
                                        if (!panelRoot.panelModel.itemIsSelected(index)) {
                                            panelRoot.panelModel.deselectAll();
                                            if (!model.isParent)
                                                panelRoot.panelModel.setItemSelected(index, true);
                                            fileList.currentIndex = index;
                                        }
                                    }
                                }
                            }

                            onPositionChanged: function(mouse) {
                                if ((mouse.buttons & Qt.LeftButton) && !dragStarted) {
                                    var dx = mouse.x - pressX;
                                    var dy = mouse.y - pressY;
                                    if (dx * dx + dy * dy > 36) {
                                        dragStarted = true;
                                        var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                        var inBlank = isBlankArea(pressX);

                                        if (isCtrl || inBlank) {
                                            isRubberBandDrag = true;
                                            var pt = rowMouse.mapToItem(viewContainer, pressX, pressY);
                                            panelRoot.startRubberBand(pt.x, pt.y, isCtrl);
                                        } else if (!model.isParent) {
                                            isRubberBandDrag = false;
                                            panelRoot.focusList();
                                            fileList.currentIndex = index;
                                            var dragPaths = model.isSelected
                                                            ? panelRoot.panelModel.selectedPaths()
                                                            : [model.path];
                                            backend.startDrag(dragPaths);
                                        }
                                    }
                                } else if (dragStarted && isRubberBandDrag) {
                                    var curPt = rowMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                    var isCtrlMod = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    panelRoot.updateRubberBand(curPt.x, curPt.y, isCtrlMod);
                                }
                            }

                            onReleased: function(mouse) {
                                if (isRubberBandDrag) {
                                    panelRoot.finishRubberBand();
                                    isRubberBandDrag = false;
                                    return;
                                }
                                if (dragStarted)
                                    return;

                                if (mouse.button === Qt.LeftButton) {
                                    if ((mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) === 0) {
                                        if (panelRoot.panelModel.selectedCount > 1) {
                                            panelRoot.panelModel.deselectAll();
                                            if (!model.isParent)
                                                panelRoot.panelModel.setItemSelected(index, true);
                                            fileList.currentIndex = index;
                                        }
                                    }
                                }
                            }

                            onClicked: function(mouse) {
                                if (dragStarted || isRubberBandDrag)
                                    return;
                                panelRoot.focusList();
                                if (mouse.button === Qt.MiddleButton && model.isDir) {
                                    panelRoot.panelModel.addTab(model.path);
                                }
                            }

                            onDoubleClicked: function(mouse) {
                                if (mouse.button !== Qt.LeftButton)
                                    return;
                                panelRoot.focusList();
                                if (model.isDir) {
                                    panelRoot.panelModel.cd(model.name);
                                } else if (panelRoot.panelModel.isArchiveView) {
                                    fileList.currentIndex = index;
                                    win.triggerF3View();
                                } else {
                                    backend.openItem(model.path);
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Name Cell (Icon + Stem/Name)
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    VectorIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        kind: panelRoot.iconKindFor(model.isParent, model.isDir, model.iconType)
                                        iconColor: panelRoot.iconColorFor(model.isParent, model.isDir, model.iconType, model.isSelected)
                                    }

                                    Text {
                                        id: rowNameText
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        text: panelRoot.displayStem(model.name, model.extension, model.isDir)
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 12
                                        font.weight: (model.isDir && !model.isParent) || model.isSelected ? Font.DemiBold : Font.Normal
                                        color: {
                                            if (model.isSelected) return p.accent;
                                            if (model.isParent) return p.textMuted;
                                            if (model.isDir) return p.textPrimary;
                                            return p.textSecondary;
                                        }
                                    }

                                    Rectangle {
                                        visible: (model.gitStatus || "").length > 0
                                        Layout.alignment: Qt.AlignVCenter
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        radius: 3
                                        color: {
                                            var s = model.gitStatus;
                                            if (s === "modified") return p.gitModBg;
                                            if (s === "untracked") return p.gitUntrackedBg;
                                            if (s === "staged") return p.gitStagedBg;
                                            if (s === "deleted") return p.gitDeletedBg;
                                            return p.gitDefaultBg;
                                        }
                                        border.width: 1
                                        border.color: {
                                            var s = model.gitStatus;
                                            if (s === "modified") return p.gitModBorder;
                                            if (s === "untracked") return p.gitUntrackedBorder;
                                            if (s === "staged") return p.gitStagedBorder;
                                            if (s === "deleted") return p.gitDeletedBorder;
                                            return p.gitDefaultBorder;
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                var s = model.gitStatus;
                                                if (s === "modified") return "M";
                                                if (s === "untracked") return "?";
                                                if (s === "staged") return "A";
                                                if (s === "deleted") return "D";
                                                return "";
                                            }
                                            font.pixelSize: 9
                                            font.bold: true
                                            font.family: "monospace"
                                            color: {
                                                var s = model.gitStatus;
                                                if (s === "modified") return p.gitModText;
                                                if (s === "untracked") return p.gitUntrackedText;
                                                if (s === "staged") return p.gitStagedText;
                                                if (s === "deleted") return p.gitDeletedText;
                                                return p.gitDefaultText;
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Ext Cell
                            Item {
                                Layout.preferredWidth: panelRoot.colExtWidth
                                Layout.fillHeight: true

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: panelRoot.displayExt(model.name, model.extension, model.isDir)
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    color: model.isSelected ? p.accent : p.textMuted
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Size Cell
                            Item {
                                Layout.preferredWidth: panelRoot.colSizeWidth
                                Layout.fillHeight: true

                                readonly property bool isPlaceholderTag: model.formattedSize === "<DIR>" || model.formattedSize === "<UP>"
                                readonly property real ratio: model.sizeRatio || 0
                                readonly property real pct: model.sizePercent || 0

                                // Proportional ncdu / WizTree disk usage bar
                                Rectangle {
                                    visible: !parent.isPlaceholderTag && parent.ratio > 0
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height - 6
                                    width: Math.max(3, Math.round((parent.width - 8) * Math.min(1.0, parent.ratio)))
                                    radius: 3
                                    color: Qt.alpha(p.accent,
                                                    panelRoot.panelModel.diskUsageMode
                                                    ? (win.isDark ? 0.30 : 0.22)
                                                    : (win.isDark ? 0.14 : 0.10))
                                    border.width: panelRoot.panelModel.diskUsageMode ? 1 : 0
                                    border.color: Qt.alpha(p.accent, 0.38)
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                    text: {
                                        if (model.formattedSize === "<DIR>") return qsTr("DIR");
                                        if (model.formattedSize === "<UP>") return qsTr("UP");
                                        if (panelRoot.panelModel.diskUsageMode && parent.pct >= 0.1)
                                            return model.formattedSize + " (" + Number(parent.pct).toFixed(parent.pct >= 10 ? 0 : 1) + "%)";
                                        return model.formattedSize;
                                    }
                                    font.pixelSize: parent.isPlaceholderTag ? 10 : 11
                                    font.family: "monospace"
                                    font.weight: (model.isDir && !parent.isPlaceholderTag) ? Font.DemiBold : Font.Normal
                                    color: {
                                        if (model.isSelected) return p.accent;
                                        if (parent.isPlaceholderTag) return p.textDim;
                                        if (model.isDir) return p.textPrimary;
                                        return p.textMuted;
                                    }
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Date Cell
                            Item {
                                Layout.preferredWidth: panelRoot.colDateWidth
                                Layout.fillHeight: true

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    text: model.isParent ? "" : model.modified
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    color: model.isSelected ? Qt.alpha(p.accent, 0.85) : p.textDim
                                }
                            }
                        }
                    }

                    Keys.onPressed: function(event) {
                        var m = panelRoot.panelModel;
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (currentIndex >= 0 && currentIndex < m.itemCount) {
                                if (m.itemIsDir(currentIndex))
                                    m.cd(m.itemName(currentIndex));
                                else if (m.isArchiveView)
                                    win.triggerF3View();
                                else
                                    backend.openItem(m.itemPath(currentIndex));
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backspace) {
                            m.cdUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Insert) {
                            m.toggleSelection(currentIndex);
                            if (currentIndex + 1 < m.itemCount)
                                currentIndex++;
                            event.accepted = true;
                        } else if (event.text.length === 1 && event.modifiers === Qt.NoModifier && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                            var idx = m.findIndexByPrefix(event.text, currentIndex + 1);
                            if (idx >= 0)
                                currentIndex = idx;
                            event.accepted = true;
                        }
                    }
                }

                GridView {
                    id: fileGrid
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: panelRoot.panelModel
                    visible: panelRoot.panelModel.viewMode === 1
                    focus: panelRoot.isActive && panelRoot.panelModel.viewMode === 1
                    cellWidth: Math.max(94, Math.floor(width / Math.max(1, Math.floor(width / 110))))
                    cellHeight: 114

                    onCountChanged: {
                        if (count > 0 && currentIndex < 0)
                            currentIndex = 0;
                    }
                    onCurrentIndexChanged: {
                        if (panelRoot.isActive)
                            win.updateQuickView();
                        if (panelRoot.panelModel.viewMode === 1 && fileList.currentIndex !== currentIndex)
                            fileList.currentIndex = currentIndex;
                    }

                    MouseArea {
                        id: gridBackgroundMouse
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        preventStealing: true
                        property real startX: 0
                        property real startY: 0
                        property bool dragStarted: false

                        onPressed: function(mouse) {
                            panelRoot.focusList();
                            if (mouse.button === Qt.RightButton) {
                                var pt = gridBackgroundMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                                bgContextMenu.popup(panelRoot, pt.x, pt.y);
                                return;
                            }
                            if (mouse.button === Qt.LeftButton) {
                                startX = mouse.x;
                                startY = mouse.y;
                                dragStarted = false;
                                var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                var pt = gridBackgroundMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                panelRoot.startRubberBand(pt.x, pt.y, isCtrl);
                            }
                        }
                        onPositionChanged: function(mouse) {
                            if (mouse.buttons & Qt.LeftButton) {
                                var dx = mouse.x - startX;
                                var dy = mouse.y - startY;
                                if (!dragStarted && (dx * dx + dy * dy > 16)) {
                                    dragStarted = true;
                                }
                                if (dragStarted) {
                                    var pt = gridBackgroundMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                    var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    panelRoot.updateRubberBand(pt.x, pt.y, isCtrl);
                                }
                            }
                        }
                        onReleased: function(mouse) {
                            if (dragStarted) {
                                panelRoot.finishRubberBand();
                                dragStarted = false;
                            } else if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier) === 0) {
                                panelModel.deselectAll();
                                panelRoot.finishRubberBand();
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: gridVbar
                        policy: ScrollBar.AsNeeded
                        width: 6
                        padding: 1
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            visible: gridVbar.size < 1.0
                            color: gridVbar.pressed ? p.accent : (gridVbar.hovered ? p.scrollbarHoverColor : p.scrollbarColor)
                        }
                        background: Item {}
                    }

                    delegate: Rectangle {
                        id: gridDelegate
                        width: fileGrid.cellWidth - 6
                        height: fileGrid.cellHeight - 6
                        x: 3
                        y: 3
                        radius: win.smallRadius
                        property string itemPermissions: model.permissions || ""
                        readonly property bool isCurrent: fileGrid.currentIndex === index
                        readonly property bool isCutItem: backend.clipboardIsCut && backend.clipboardPaths.indexOf(model.path) !== -1
                        readonly property bool isDropTargetDir: panelDropArea.containsDrag && panelDropArea.hoveredDirIndex === index

                        opacity: isCutItem ? 0.48 : 1.0
                        border.width: (isDropTargetDir || (isCurrent && panelRoot.isActive)) ? 1 : (model.isSelected ? 1 : 0)
                        border.color: isDropTargetDir ? p.accent
                                    : (isCurrent && panelRoot.isActive ? p.accent
                                    : (model.isSelected ? Qt.alpha(p.accent, 0.6) : "transparent"))

                        color: {
                            if (isDropTargetDir) return Qt.alpha(p.accent, 0.24);
                            if (model.isSelected && isCurrent && panelRoot.isActive) return Qt.alpha(p.accent, win.isDark ? 0.26 : 0.18);
                            if (model.isSelected) return Qt.alpha(p.accent, win.isDark ? 0.16 : 0.11);
                            if (isCurrent && panelRoot.isActive) return p.rowCurrentActiveBg;
                            if (gridItemMouse.containsMouse) return p.rowHoverBg;
                            return p.gridCardBg;
                        }

                        MouseArea {
                            id: gridItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            property real pressX: 0
                            property real pressY: 0
                            property bool dragStarted: false
                            property bool isRubberBandDrag: false

                            onPressed: function(mouse) {
                                pressX = mouse.x;
                                pressY = mouse.y;
                                dragStarted = false;
                                isRubberBandDrag = false;
                                panelRoot.focusList();

                                if (mouse.button === Qt.RightButton) {
                                    if (!panelRoot.panelModel.itemIsSelected(index)) {
                                        if ((mouse.modifiers & Qt.ControlModifier) === 0)
                                            panelRoot.panelModel.deselectAll();
                                        if (!model.isParent)
                                            panelRoot.panelModel.setItemSelected(index, true);
                                    }
                                    fileGrid.currentIndex = index;
                                    fileContextMenu.targetIndex = index;
                                    fileContextMenu.targetPath = model.path;
                                    fileContextMenu.isTargetDir = model.isDir;
                                    var pt = gridItemMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                                    fileContextMenu.popup(panelRoot, pt.x, pt.y);
                                    return;
                                }

                                if (mouse.button === Qt.LeftButton) {
                                    var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    var isShift = (mouse.modifiers & Qt.ShiftModifier) !== 0;

                                    if (isCtrl) {
                                        if (!model.isParent)
                                            panelRoot.panelModel.toggleSelection(index);
                                        fileGrid.currentIndex = index;
                                    } else if (isShift) {
                                        var anchor = fileGrid.currentIndex >= 0 ? fileGrid.currentIndex : index;
                                        panelRoot.panelModel.selectRange(anchor, index, true);
                                        fileGrid.currentIndex = index;
                                    } else {
                                        if (!panelRoot.panelModel.itemIsSelected(index)) {
                                            panelRoot.panelModel.deselectAll();
                                            if (!model.isParent)
                                                panelRoot.panelModel.setItemSelected(index, true);
                                            fileGrid.currentIndex = index;
                                        }
                                    }
                                }
                            }

                            onPositionChanged: function(mouse) {
                                if ((mouse.buttons & Qt.LeftButton) && !dragStarted) {
                                    var dx = mouse.x - pressX;
                                    var dy = mouse.y - pressY;
                                    if (dx * dx + dy * dy >= 49) {
                                        dragStarted = true;
                                        var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                        if (isCtrl) {
                                            isRubberBandDrag = true;
                                            var pt = gridItemMouse.mapToItem(viewContainer, pressX, pressY);
                                            panelRoot.startRubberBand(pt.x, pt.y, isCtrl);
                                        } else if (!model.isParent) {
                                            isRubberBandDrag = false;
                                            var paths = model.isSelected ? panelRoot.panelModel.selectedPaths() : [model.path];
                                            if (paths.length > 0)
                                                backend.startDrag(paths);
                                        }
                                    }
                                } else if (dragStarted && isRubberBandDrag) {
                                    var curPt = gridItemMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                    var isCtrlMod = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                    panelRoot.updateRubberBand(curPt.x, curPt.y, isCtrlMod);
                                }
                            }

                            onReleased: function(mouse) {
                                if (isRubberBandDrag) {
                                    panelRoot.finishRubberBand();
                                    isRubberBandDrag = false;
                                    return;
                                }
                                if (dragStarted)
                                    return;

                                if (mouse.button === Qt.LeftButton) {
                                    if ((mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) === 0) {
                                        if (panelRoot.panelModel.selectedCount > 1) {
                                            panelRoot.panelModel.deselectAll();
                                            if (!model.isParent)
                                                panelRoot.panelModel.setItemSelected(index, true);
                                            fileGrid.currentIndex = index;
                                        }
                                    }
                                }
                            }

                            onClicked: function(mouse) {
                                if (dragStarted || isRubberBandDrag)
                                    return;
                                panelRoot.focusList();
                                if (mouse.button === Qt.MiddleButton && model.isDir) {
                                    panelRoot.panelModel.addTab(model.path);
                                }
                            }

                            onDoubleClicked: function(mouse) {
                                if (mouse.button !== Qt.LeftButton)
                                    return;
                                panelRoot.focusList();
                                if (model.isDir) {
                                    panelRoot.panelModel.cd(model.name);
                                } else if (panelRoot.panelModel.isArchiveView) {
                                    fileGrid.currentIndex = index;
                                    win.triggerF3View();
                                } else {
                                    backend.openItem(model.path);
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Image {
                                    id: thumbImg
                                    visible: (model.thumbnailUrl || "").toString().length > 0
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, 76)
                                    height: Math.min(parent.height, 58)
                                    fillMode: Image.PreserveAspectFit
                                    source: model.thumbnailUrl || ""
                                    sourceSize: Qt.size(96, 96)
                                    asynchronous: true
                                    cache: true
                                }

                                VectorIcon {
                                    visible: !thumbImg.visible || thumbImg.status === Image.Error || thumbImg.status === Image.Null
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 36
                                    kind: panelRoot.iconKindFor(model.isParent, model.isDir, model.iconType)
                                    iconColor: panelRoot.iconColorFor(model.isParent, model.isDir, model.iconType, model.isSelected)
                                }

                                Rectangle {
                                    visible: (model.gitStatus || "").length > 0
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    width: 15
                                    height: 15
                                    radius: 3
                                    color: {
                                        var s = model.gitStatus;
                                        if (s === "modified") return p.gitModBg;
                                        if (s === "untracked") return p.gitUntrackedBg;
                                        if (s === "staged") return p.gitStagedBg;
                                        if (s === "deleted") return p.gitDeletedBg;
                                        return p.gitDefaultBg;
                                    }
                                    border.width: 1
                                    border.color: {
                                        var s = model.gitStatus;
                                        if (s === "modified") return p.gitModBorder;
                                        if (s === "untracked") return p.gitUntrackedBorder;
                                        if (s === "staged") return p.gitStagedBorder;
                                        if (s === "deleted") return p.gitDeletedBorder;
                                        return p.gitDefaultBorder;
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            var s = model.gitStatus;
                                            if (s === "modified") return "M";
                                            if (s === "untracked") return "?";
                                            if (s === "staged") return "A";
                                            if (s === "deleted") return "D";
                                            return "";
                                        }
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: "monospace"
                                        color: {
                                            var s = model.gitStatus;
                                            if (s === "modified") return p.gitModText;
                                            if (s === "untracked") return p.gitUntrackedText;
                                            if (s === "staged") return p.gitStagedText;
                                            if (s === "deleted") return p.gitDeletedText;
                                            return p.gitDefaultText;
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name
                                font.pixelSize: 11
                                font.weight: (model.isDir && !model.isParent) || model.isSelected ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                                color: {
                                    if (model.isSelected) return p.accent;
                                    if (model.isParent) return p.textMuted;
                                    if (model.isDir) return p.textPrimary;
                                    return p.textSecondary;
                                }
                            }
                        }
                    }

                    Keys.onPressed: function(event) {
                        var m = panelRoot.panelModel;
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (currentIndex >= 0 && currentIndex < m.itemCount) {
                                if (m.itemIsDir(currentIndex))
                                    m.cd(m.itemName(currentIndex));
                                else if (m.isArchiveView)
                                    win.triggerF3View();
                                else
                                    backend.openItem(m.itemPath(currentIndex));
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backspace) {
                            m.cdUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Insert) {
                            m.toggleSelection(currentIndex);
                            if (currentIndex + 1 < m.itemCount)
                                currentIndex++;
                            event.accepted = true;
                        } else if (event.text.length === 1 && event.modifiers === Qt.NoModifier && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                            var idx = m.findIndexByPrefix(event.text, currentIndex + 1);
                            if (idx >= 0)
                                currentIndex = idx;
                            event.accepted = true;
                        }
                    }
                }

                DropArea {
                    id: panelDropArea
                    anchors.fill: parent
                    property int hoveredDirIndex: -1
                    property bool shiftHeld: false

                    function updateHover(drag) {
                        shiftHeld = (drag.modifiers & Qt.ShiftModifier) !== 0;
                        var idx = panelRoot.panelModel.viewMode === 1
                                ? fileGrid.indexAt(drag.x, drag.y + fileGrid.contentY)
                                : fileList.indexAt(drag.x, drag.y + fileList.contentY);
                        if (idx >= 0 && idx < panelRoot.panelModel.itemCount
                                && panelRoot.panelModel.itemIsDir(idx)
                                && panelRoot.panelModel.itemName(idx) !== "..") {
                            hoveredDirIndex = idx;
                        } else {
                            hoveredDirIndex = -1;
                        }
                        drag.accept(shiftHeld ? Qt.MoveAction : Qt.CopyAction);
                    }

                    onEntered: function(drag) { updateHover(drag); }
                    onPositionChanged: function(drag) { updateHover(drag); }
                    onExited: { hoveredDirIndex = -1; shiftHeld = false; }
                    onDropped: function(drop) {
                        var targetDir = panelRoot.panelModel.path;
                        if (hoveredDirIndex >= 0 && hoveredDirIndex < panelRoot.panelModel.itemCount
                                && panelRoot.panelModel.itemIsDir(hoveredDirIndex)) {
                            targetDir = panelRoot.panelModel.itemPath(hoveredDirIndex);
                        }
                        var moveOp = (drop.modifiers & Qt.ShiftModifier) !== 0
                                     || drop.supportedActions === Qt.MoveAction;
                        hoveredDirIndex = -1;
                        shiftHeld = false;
                        if (backend.handleDrop(drop.urls, targetDir, moveOp)) {
                            backend.activePanel = panelRoot.panelIndex;
                            drop.acceptProposedAction();
                        }
                    }
                }

                // Visual Drop Overlay when hovering panel background / non-folder rows
                Rectangle {
                    visible: panelDropArea.containsDrag && panelDropArea.hoveredDirIndex < 0
                    anchors.fill: parent
                    color: Qt.alpha(p.accent, 0.06)
                    border.width: 2
                    border.color: p.accent

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        height: 26
                        width: dropHintLabel.implicitWidth + 20
                        radius: win.smallRadius
                        color: p.cardBg
                        border.width: 1
                        border.color: p.accent

                        Text {
                            id: dropHintLabel
                            anchors.centerIn: parent
                            text: panelDropArea.shiftHeld
                                  ? qsTr("Drop to Move here")
                                  : qsTr("Drop to Copy here (Shift = Move)")
                            font.pixelSize: 11
                            font.bold: true
                            color: p.accent
                        }
                    }
                }

                // Dedicated mouse surface covering the empty space below files for rubberband & context menu
                MouseArea {
                    id: emptySpaceMouse
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: Math.min(parent.height, contentBottom)
                    anchors.bottom: parent.bottom
                    readonly property real contentBottom: {
                        if (panelRoot.panelModel.viewMode === 1) { // GridView
                            var cellH = fileGrid.cellHeight;
                            var cols = Math.max(1, Math.floor(fileGrid.width / fileGrid.cellWidth));
                            var rows = Math.ceil(panelRoot.panelModel.itemCount / cols);
                            return Math.max(0, rows * cellH - fileGrid.contentY);
                        } else { // ListView
                            return Math.max(0, fileList.contentHeight - fileList.contentY);
                        }
                    }
                    visible: height > 0
                    z: 5
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true

                    property real pressX: 0
                    property real pressY: 0
                    property bool dragStarted: false

                    onPressed: function(mouse) {
                        panelRoot.focusList();
                        if (mouse.button === Qt.RightButton) {
                            var pt = emptySpaceMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                            bgContextMenu.popup(panelRoot, pt.x, pt.y);
                            return;
                        }
                        if (mouse.button === Qt.LeftButton) {
                            pressX = mouse.x;
                            pressY = mouse.y;
                            dragStarted = false;
                            var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                            var pt = emptySpaceMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                            panelRoot.startRubberBand(pt.x, pt.y, isCtrl);
                        }
                    }

                    onPositionChanged: function(mouse) {
                        if (mouse.buttons & Qt.LeftButton) {
                            var dx = mouse.x - pressX;
                            var dy = mouse.y - pressY;
                            if (!dragStarted && (dx * dx + dy * dy > 9)) {
                                dragStarted = true;
                            }
                            if (dragStarted) {
                                var pt = emptySpaceMouse.mapToItem(viewContainer, mouse.x, mouse.y);
                                var isCtrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                                panelRoot.updateRubberBand(pt.x, pt.y, isCtrl);
                            }
                        }
                    }

                    onReleased: function(mouse) {
                        if (dragStarted) {
                            panelRoot.finishRubberBand();
                            dragStarted = false;
                        } else if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier) === 0) {
                            panelModel.deselectAll();
                            panelRoot.finishRubberBand();
                        }
                    }

                    onWheel: function(wheel) {
                        wheel.accepted = false;
                    }
                }
            }

            // 5. Panel Footer: Selection Summary, Highlighted Permissions & Free Disk Space
            Rectangle {
                Layout.fillWidth: true
                height: 26
                color: p.panelFooterBg

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        visible: panelRoot.panelModel.selectedCount > 0
                        implicitHeight: 18
                        implicitWidth: selBadgeText.implicitWidth + 10
                        radius: Math.min(3, theme.radius)
                        color: Qt.alpha(p.accent, 0.16)

                        Text {
                            id: selBadgeText
                            anchors.centerIn: parent
                            text: qsTr("%1 selected (%2)")
                                  .arg(panelRoot.panelModel.selectedCount)
                                  .arg(panelRoot.panelModel.totalSelectedSizeFormatted)
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: p.accent
                        }
                    }

                    Text {
                        text: qsTr("%1 items").arg(panelRoot.panelModel.itemCount)
                        font.pixelSize: 11
                        color: p.textMuted
                    }

                    Rectangle {
                        visible: panelRoot.panelModel.isGitRepo
                        implicitHeight: 18
                        implicitWidth: gitRow.implicitWidth + 10
                        radius: Math.min(3, theme.radius)
                        color: p.chipBg
                        border.width: 1
                        border.color: p.borderDefault

                        RowLayout {
                            id: gitRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: " " + (panelRoot.panelModel.gitBranch || "HEAD")
                                font.pixelSize: 11
                                font.family: "monospace"
                                font.bold: true
                                color: p.gitBranchText
                            }

                            Text {
                                visible: panelRoot.panelModel.gitModifiedCount > 0
                                text: "±" + panelRoot.panelModel.gitModifiedCount
                                font.pixelSize: 10
                                font.family: "monospace"
                                font.bold: true
                                color: p.warningText
                            }

                            Text {
                                visible: panelRoot.panelModel.gitUntrackedCount > 0
                                text: "?" + panelRoot.panelModel.gitUntrackedCount
                                font.pixelSize: 10
                                font.family: "monospace"
                                font.bold: true
                                color: p.successText
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: fileList.currentItem && fileList.currentItem.itemPermissions.length > 0
                        text: fileList.currentItem ? fileList.currentItem.itemPermissions : ""
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textDim
                    }

                    Text {
                        visible: fileList.currentItem && fileList.currentItem.itemPermissions.length > 0
                        text: "·"
                        font.pixelSize: 11
                        color: p.textDisabled
                    }

                    Text {
                        text: qsTr("Free: %1").arg(panelRoot.panelModel.freeSpaceFormatted)
                        font.pixelSize: 11
                        color: p.textMuted
                    }
                }
            }
        }
    }

    // ================= HELPERS & ACTIONS =================

    function currentPanelItem() {
        return backend.activePanel === 0 ? leftPane : rightPane;
    }

    function currentModel() {
        return backend.activePanel === 0 ? backend.leftPanel : backend.rightPanel;
    }

    function targetModel() {
        return backend.activePanel === 0 ? backend.rightPanel : backend.leftPanel;
    }

    function currentListView() {
        return backend.activePanel === 0 ? leftPane.activeView : rightPane.activeView;
    }

    function currentHighlightedPath() {
        var m = currentModel();
        var lv = currentListView();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount)
            return m.itemPath(lv.currentIndex);
        return "";
    }

    function updateQuickView() {
        if (!win.quickViewActive)
            return;
        var p = currentHighlightedPath();
        win.quickViewData = p.length > 0 ? backend.getPreview(p) : ({});
    }

    function getSelectedOrCurrentPaths() {
        var m = currentModel();
        var sel = m.selectedPaths();
        if (sel.length > 0)
            return sel;
        var lv = currentListView();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            var p = m.itemPath(lv.currentIndex);
            var name = m.itemName(lv.currentIndex);
            if (p && name !== "..")
                return [p];
        }
        return [];
    }

    function refreshMultiRenamePreview() {
        if (!mrMaskField || !mrFindField || !mrReplaceField || !mrPrefixField || !mrSuffixField ||
            !mrCaseCombo || !mrCounterCheck || !mrRegexToggle ||
            !mrCounterStartField || !mrCounterStepField || !mrCounterDigitsField)
            return;
        var paths = getSelectedOrCurrentPaths();
        var cStart = parseInt(mrCounterStartField.text, 10);
        var cStep = parseInt(mrCounterStepField.text, 10);
        var cDigits = parseInt(mrCounterDigitsField.text, 10);
        multiRenamePreviewList = backend.previewMultiRename(
            paths,
            mrFindField.text,
            mrReplaceField.text,
            mrPrefixField.text,
            mrSuffixField.text,
            mrCaseCombo.currentIndex,
            mrCounterCheck.checked,
            mrRegexToggle.active,
            mrMaskField.text,
            isNaN(cStart) ? 1 : cStart,
            isNaN(cStep) ? 1 : cStep,
            isNaN(cDigits) ? 3 : cDigits
        );
    }

    function insertRenameTag(tag) {
        var cur = mrMaskField.text;
        mrMaskField.text = cur.length > 0 ? (cur + tag) : tag;
        mrMaskField.forceFieldFocus();
    }

    function triggerF3View() {
        var p = currentHighlightedPath();
        if (p.length > 0) {
            previewData = backend.getPreview(p);
            previewOpen = true;
        }
    }

    function triggerF4Edit() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            backend.openWithEditor(paths[0]);
    }

    function triggerF5Copy() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            copyDestField.text = targetModel().path;
            confirmCopyOpen = true;
            copyDestField.forceFieldFocus();
        } else {
            backend.showStatus(qsTr("No files selected to copy."));
        }
    }

    function triggerF6Move() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            moveDestField.text = targetModel().path;
            confirmMoveOpen = true;
            moveDestField.forceFieldFocus();
        } else {
            backend.showStatus(qsTr("No files selected to move."));
        }
    }

    function triggerF7NewFolder() {
        newFolderInput.text = "";
        newFolderOpen = true;
        newFolderInput.forceFieldFocus();
    }

    function triggerRename() {
        var lv = currentListView();
        var m = currentModel();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            var name = m.itemName(lv.currentIndex);
            if (name === "..")
                return;
            renameOldPath = m.itemPath(lv.currentIndex);
            renameOldName = backend.fileName(renameOldPath);
            renameInput.text = renameOldName;
            renameOpen = true;
            renameInput.forceFieldFocus();
        }
    }

    function triggerMultiRename() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length === 0) {
            backend.showStatus(qsTr("Select files first for Multi-Rename (Ctrl+M)."));
            return;
        }
        mrMaskField.text = "[N]";
        mrFindField.text = "";
        mrReplaceField.text = "";
        mrPrefixField.text = "";
        mrSuffixField.text = "";
        mrRegexToggle.active = false;
        mrCaseCombo.currentIndex = 0;
        mrCounterCheck.checked = false;
        mrCounterStartField.text = "1";
        mrCounterStepField.text = "1";
        mrCounterDigitsField.text = "3";
        mrPresetNameField.text = "";
        refreshMultiRenamePreview();
        multiRenameOpen = true;
        mrMaskField.forceFieldFocus();
    }

    function triggerPackArchive() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length === 0) {
            backend.showStatus(qsTr("Select files to pack (Alt+F5)."));
            return;
        }
        var baseName = paths.length === 1 ? currentModel().itemName(currentListView().currentIndex) : "archive";
        packArchiveField.text = targetModel().path + "/" + baseName + ".zip";
        packArchiveOpen = true;
        packArchiveField.forceFieldFocus();
    }

    function triggerExtractArchive() {
        var p = currentHighlightedPath();
        if (p.length > 0 && backend.isArchive(p))
            backend.extractArchive(p, targetModel().path);
        else
            backend.showStatus(qsTr("Highlight an archive (.zip, .tar.gz, .7z) to extract (Alt+F9)."));
    }

    function triggerF8Delete() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            confirmDeleteOpen = true;
        else
            backend.showStatus(qsTr("No files selected to delete."));
    }

    function toggleFilterBar() {
        var pane = currentPanelItem();
        pane.setFilterOpen(!(pane.filterVisible || currentModel().filter.length > 0));
    }

    function isTextInputFocused() {
        var item = win.activeFocusItem;
        if (!item)
            return false;
        var cls = item.toString();
        return cls.indexOf("QQuickTextInput") === 0
            || cls.indexOf("QQuickTextEdit") === 0
            || cls.indexOf("QQuickTextArea") === 0;
    }

    function formatOctalMode(mode) {
        var s = (mode & 0x1ff).toString(8);
        while (s.length < 3)
            s = "0" + s;
        return "0" + s;
    }

    function togglePermBit(bitMask) {
        if (win.propData.isSymLink)
            return;
        win.propMode = (win.propMode ^ bitMask) & 0x1ff;
        win.propSyncingOctal = true;
        propOctalField.text = formatOctalMode(win.propMode);
        win.propSyncingOctal = false;
    }

    function triggerProperties() {
        var m = currentModel();
        var lv = currentListView();
        var targetPath = m.path;
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            var name = m.itemName(lv.currentIndex);
            if (name !== "..")
                targetPath = m.itemPath(lv.currentIndex);
        }
        var props = backend.getItemProperties(targetPath);
        if (!props.exists) {
            backend.showStatus(qsTr("Could not read item properties."));
            return;
        }
        win.propData = props;
        win.propMode = props.mode;
        win.propSyncingOctal = true;
        propOctalField.text = props.octal;
        win.propSyncingOctal = false;
        propRecursiveCheck.checked = false;
        win.propertiesOpen = true;
    }

    function triggerNewFile() {
        newFileNameInput.text = "new_file.txt";
        win.newFileOpen = true;
        newFileNameInput.forceFieldFocus();
        newFileNameInput.input.selectAll();
    }

    function triggerSymlink() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length === 0) {
            backend.showStatus(qsTr("No files selected to create symlink."));
            return;
        }
        symlinkDialog.paths = paths;
        symlinkTargetDirInput.text = targetModel().path;
        if (paths.length === 1)
            symlinkNameInput.text = backend.fileName(paths[0]);
        win.symlinkOpen = true;
    }

    function openMaskDialog(isSelect) {
        maskSelectDialog.isSelecting = isSelect;
        win.maskOpen = true;
        maskPatternInput.forceFieldFocus();
        maskPatternInput.input.selectAll();
    }

    function triggerChecksum() {
        var p = currentHighlightedPath();
        if (p.length === 0 || currentModel().itemIsDir(currentListView().currentIndex)) {
            backend.showStatus(qsTr("Select a file to compute checksum."));
            return;
        }
        checksumDialog.filePath = p;
        checksumDialog.hashes = backend.calculateChecksums(p);
        checksumDialog.verificationResult = "";
        verifyHashInput.text = "";
        win.checksumOpen = true;
    }

    function triggerFileDiff() {
        var m = currentModel();
        var sel = m.selectedPaths();
        var p1 = "";
        var p2 = "";
        if (sel.length >= 2) {
            p1 = sel[0];
            p2 = sel[1];
        } else {
            p1 = currentHighlightedPath();
            var tm = targetModel();
            var targetLv = backend.activePanel === 0 ? rightPane.activeView : leftPane.activeView;
            if (targetLv.currentIndex >= 0 && targetLv.currentIndex < tm.itemCount)
                p2 = tm.itemPath(targetLv.currentIndex);
            else if (p1.length > 0)
                p2 = tm.path + "/" + backend.fileName(p1);
        }
        if (!p1 || !p2 || p1 === p2) {
            backend.showStatus(qsTr("Select two files to compare."));
            return;
        }
        diffDialog.path1 = p1;
        diffDialog.path2 = p2;
        diffDialog.diffData = backend.compareFiles(p1, p2);
        win.diffOpen = true;
    }

    function fuzzyScoreCommand(query, title, category, shortcut) {
        if (!query || query.length === 0)
            return 1;
        var q = query.toLowerCase().trim();
        if (q.length === 0)
            return 1;
        var haystackTitle = title.toLowerCase();
        var haystackAll = (category + " " + title + " " + shortcut).toLowerCase();

        var exactIdx = haystackTitle.indexOf(q);
        if (exactIdx === 0)
            return 500 - title.length;
        if (exactIdx > 0)
            return 350 - exactIdx * 2;

        var tokens = q.split(/\s+/);
        if (tokens.length > 1) {
            var allOk = true;
            for (var t = 0; t < tokens.length; t++) {
                if (tokens[t].length > 0 && haystackAll.indexOf(tokens[t]) === -1) {
                    allOk = false;
                    break;
                }
            }
            if (allOk)
                return 260 - title.length;
        }

        var qi = 0;
        var score = 0;
        var consecutive = 0;
        for (var i = 0; i < haystackTitle.length && qi < q.length; i++) {
            if (haystackTitle.charAt(i) === q.charAt(qi)) {
                score += 10 + consecutive * 6;
                if (i === 0 || haystackTitle.charAt(i - 1) === " " || haystackTitle.charAt(i - 1) === "/")
                    score += 12;
                consecutive++;
                qi++;
            } else {
                consecutive = 0;
            }
        }
        return qi === q.length ? score : -1;
    }

    function getCommandList() {
        var flatActive = currentModel().flatView;
        var hiddenActive = currentModel().showHidden;
        return [
            { id: "quickJump", title: qsTr("Quick Jump to Folder..."), category: qsTr("Navigation"), shortcut: "Ctrl+P", run: function() { win.openCommandPalette("jump"); } },
            { id: "flatView", title: flatActive ? qsTr("Disable Flat / Branch View") : qsTr("Flat / Branch View (Recursive)"), category: qsTr("View"), shortcut: "Ctrl+Shift+B", run: function() { currentModel().toggleFlatView(); } },
            { id: "toggleTheme", title: backend.isDarkTheme ? qsTr("Switch to Light Theme") : qsTr("Switch to Dark Theme"), category: qsTr("Appearance"), shortcut: "Ctrl+Shift+T", run: function() { backend.toggleThemeMode(); } },
            { id: "quickView", title: qsTr("Toggle Quick View Panel"), category: qsTr("View"), shortcut: "Ctrl+Q", run: function() { win.quickViewActive = !win.quickViewActive; if (win.quickViewActive) updateQuickView(); } },
            { id: "showHidden", title: hiddenActive ? qsTr("Hide Hidden Files") : qsTr("Show Hidden Files"), category: qsTr("View"), shortcut: "Ctrl+H", run: function() { var m = currentModel(); m.setShowHidden(!m.showHidden); } },
            { id: "listView", title: qsTr("View Mode: List"), category: qsTr("View"), shortcut: "Ctrl+1", run: function() { currentModel().setViewMode(0); } },
            { id: "gridView", title: qsTr("View Mode: Grid Thumbnails"), category: qsTr("View"), shortcut: "Ctrl+2", run: function() { currentModel().setViewMode(1); } },
            { id: "quickFilter", title: qsTr("Toggle Quick Filter"), category: qsTr("View"), shortcut: "Ctrl+S", run: function() { toggleFilterBar(); } },
            { id: "refresh", title: qsTr("Refresh Active Panel"), category: qsTr("View"), shortcut: "Ctrl+R", run: function() { currentModel().refresh(); } },
            { id: "calcSizes", title: qsTr("Calculate All Folder Sizes"), category: qsTr("View"), shortcut: "Alt+Shift+Enter", run: function() { currentModel().calculateAllFolderSizes(); backend.showStatus(qsTr("Calculated sizes for all folders.")); } },
            { id: "sortName", title: qsTr("Sort by Name"), category: qsTr("Sort"), shortcut: "Ctrl+F3", run: function() { currentModel().setSortField(0); } },
            { id: "sortExt", title: qsTr("Sort by Extension"), category: qsTr("Sort"), shortcut: "Ctrl+F4", run: function() { currentModel().setSortField(1); } },
            { id: "sortDate", title: qsTr("Sort by Date"), category: qsTr("Sort"), shortcut: "Ctrl+F5", run: function() { currentModel().setSortField(3); } },
            { id: "sortSize", title: qsTr("Sort by Size"), category: qsTr("Sort"), shortcut: "Ctrl+F6", run: function() { currentModel().setSortField(2); } },
            { id: "switchPanel", title: qsTr("Switch Active Panel"), category: qsTr("Navigation"), shortcut: "Tab", run: function() { backend.switchPanel(); currentListView().forceActiveFocus(); updateQuickView(); } },
            { id: "editPath", title: qsTr("Edit Active Path Bar"), category: qsTr("Navigation"), shortcut: "Ctrl+L", run: function() { currentPanelItem().openPathEditor(); } },
            { id: "goBack", title: qsTr("Navigate Back in History"), category: qsTr("Navigation"), shortcut: "Alt+Left", run: function() { currentModel().goBack(); } },
            { id: "goForward", title: qsTr("Navigate Forward in History"), category: qsTr("Navigation"), shortcut: "Alt+Right", run: function() { currentModel().goForward(); } },
            { id: "goUp", title: qsTr("Go to Parent Directory"), category: qsTr("Navigation"), shortcut: "Backspace", run: function() { currentModel().cdUp(); } },
            { id: "newTab", title: qsTr("Open New Tab"), category: qsTr("Tabs"), shortcut: "Ctrl+T", run: function() { currentModel().addTab(); currentListView().forceActiveFocus(); } },
            { id: "closeTab", title: qsTr("Close Active Tab"), category: qsTr("Tabs"), shortcut: "Ctrl+W", run: function() { currentModel().closeTab(); currentListView().forceActiveFocus(); } },
            { id: "nextTab", title: qsTr("Next Tab"), category: qsTr("Tabs"), shortcut: "Ctrl+Tab", run: function() { currentModel().nextTab(); currentListView().forceActiveFocus(); } },
            { id: "bookmarks", title: qsTr("Open Bookmarks Manager"), category: qsTr("Bookmarks"), shortcut: "Ctrl+B", run: function() { win.bookmarksOpen = true; } },
            { id: "toggleBookmark", title: qsTr("Toggle Bookmark for Current Folder"), category: qsTr("Bookmarks"), shortcut: "", run: function() { backend.toggleBookmark(currentModel().path); } },
            { id: "swapPanels", title: qsTr("Swap Left & Right Panels"), category: qsTr("Panels"), shortcut: "Ctrl+U", run: function() { backend.swapPanels(); } },
            { id: "syncPanels", title: qsTr("Sync Target Panel to Active"), category: qsTr("Panels"), shortcut: "Alt+=", run: function() { backend.syncPanels(); } },
            { id: "compareDirs", title: qsTr("Compare Left & Right Directories"), category: qsTr("Commands"), shortcut: "Shift+F2", run: function() { backend.compareDirectories(); } },
            { id: "findFiles", title: qsTr("Advanced Find Files (Name / Content / Filter)..."), category: qsTr("Commands"), shortcut: "Alt+F7", run: function() { win.openAdvancedSearchDialog(); } },
            { id: "diskUsage", title: flatActive ? qsTr("Disk Usage Analyzer (with Sizes)") : qsTr("Disk Usage Analyzer (Ctrl+Shift+D)"), category: qsTr("View"), shortcut: "Ctrl+Shift+D", run: function() { currentModel().toggleDiskUsageMode(); } },
            { id: "syncDirs", title: qsTr("Synchronize Directories (Recursive)..."), category: qsTr("Commands"), shortcut: "Ctrl+Shift+S", run: function() { win.openSyncDirsDialog(); } },
            { id: "duplicateFinder", title: qsTr("Find Duplicate Files..."), category: qsTr("Commands"), shortcut: "Ctrl+Shift+F7", run: function() { win.openDuplicateFinderDialog(); } },
            { id: "operationQueue", title: qsTr("Operation Queue & Transfer Monitor..."), category: qsTr("Commands"), shortcut: "Ctrl+Shift+Q", run: function() { win.openOperationQueueDialog(); } },
            { id: "remoteConnections", title: qsTr("Remote Connections (SFTP / SMB / SSHFS)..."), category: qsTr("Network"), shortcut: "Ctrl+Shift+M", run: function() { win.openRemoteConnectionsDialog(""); } },
            { id: "openWith", title: qsTr("Open With / Custom Actions..."), category: qsTr("Files"), shortcut: "Ctrl+Shift+O", run: function() { win.openOpenWithDialog("", 0); } },
            { id: "diffFiles", title: qsTr("Compare Files (Visual Diff)..."), category: qsTr("Commands"), shortcut: "Ctrl+Alt+D", run: function() { triggerFileDiff(); } },
            { id: "checksum", title: qsTr("Compute File Checksums..."), category: qsTr("Commands"), shortcut: "", run: function() { triggerChecksum(); } },
            { id: "terminal", title: qsTr("Open Terminal in Current Folder"), category: qsTr("Commands"), shortcut: "F9", run: function() { backend.openInTerminal(currentModel().path); } },
            { id: "preview", title: qsTr("View / Preview Item"), category: qsTr("Files"), shortcut: "F3", run: function() { triggerF3View(); } },
            { id: "editFile", title: qsTr("Edit Item with $EDITOR"), category: qsTr("Files"), shortcut: "F4", run: function() { triggerF4Edit(); } },
            { id: "newFile", title: qsTr("Create New File..."), category: qsTr("Files"), shortcut: "Shift+F4", run: function() { triggerNewFile(); } },
            { id: "copy", title: qsTr("Copy Selected to Target Panel..."), category: qsTr("Files"), shortcut: "F5", run: function() { triggerF5Copy(); } },
            { id: "move", title: qsTr("Move Selected to Target Panel..."), category: qsTr("Files"), shortcut: "F6", run: function() { triggerF6Move(); } },
            { id: "rename", title: qsTr("Rename Item..."), category: qsTr("Files"), shortcut: "Shift+F6", run: function() { triggerRename(); } },
            { id: "multiRename", title: qsTr("Multi-Rename Tool..."), category: qsTr("Files"), shortcut: "Ctrl+M", run: function() { triggerMultiRename(); } },
            { id: "symlink", title: qsTr("Create Symbolic Link..."), category: qsTr("Files"), shortcut: "Ctrl+Shift+F5", run: function() { triggerSymlink(); } },
            { id: "mkdir", title: qsTr("Create New Folder..."), category: qsTr("Files"), shortcut: "F7", run: function() { triggerF7NewFolder(); } },
            { id: "delete", title: qsTr("Delete Selected Item(s)"), category: qsTr("Files"), shortcut: "F8", run: function() { triggerF8Delete(); } },
            { id: "pack", title: qsTr("Pack Selected to Archive..."), category: qsTr("Archives"), shortcut: "Alt+F5", run: function() { triggerPackArchive(); } },
            { id: "extract", title: qsTr("Extract Archive"), category: qsTr("Archives"), shortcut: "Alt+F9", run: function() { triggerExtractArchive(); } },
            { id: "properties", title: qsTr("Item Properties & Permissions"), category: qsTr("Files"), shortcut: "Alt+Enter", run: function() { triggerProperties(); } },
            { id: "selectAll", title: qsTr("Select All Items"), category: qsTr("Selection"), shortcut: "Ctrl+A", run: function() { currentModel().selectAll(); } },
            { id: "deselectAll", title: qsTr("Deselect All Items"), category: qsTr("Selection"), shortcut: "Ctrl+D", run: function() { currentModel().deselectAll(); } },
            { id: "invertSel", title: qsTr("Invert Selection"), category: qsTr("Selection"), shortcut: "Ctrl+Shift+A", run: function() { currentModel().invertSelection(); } },
            { id: "selectMask", title: qsTr("Select by Wildcard..."), category: qsTr("Selection"), shortcut: "Num+", run: function() { openMaskDialog(true); } },
            { id: "deselectMask", title: qsTr("Deselect by Wildcard..."), category: qsTr("Selection"), shortcut: "Num-", run: function() { openMaskDialog(false); } },
            { id: "undo", title: qsTr("Undo Last Operation"), category: qsTr("Edit"), shortcut: "Ctrl+Z", run: function() { backend.undoLastOperation(); } },
            { id: "shortcuts", title: qsTr("Keyboard Shortcuts"), category: qsTr("Help"), shortcut: "?", run: function() { win.helpOpen = true; } },
            { id: "about", title: qsTr("About AeroCommander"), category: qsTr("Help"), shortcut: "", run: function() { win.aboutOpen = true; } }
        ];
    }

    function openCommandPalette(mode) {
        win.closeAllMenus();
        win.commandPaletteOpen = true;
        commandPaletteDialog.resetAndRefresh(mode);
    }

    function openAdvancedSearchDialog() {
        win.closeAllMenus();
        win.searchOpen = true;
        searchInput.forceFieldFocus();
    }

    function openSyncDirsDialog() {
        win.closeAllMenus();
        win.syncDirsOpen = true;
        syncDirsDialog.refreshCompare();
    }

    function openDuplicateFinderDialog() {
        win.closeAllMenus();
        win.duplicateFinderOpen = true;
        duplicateFinderDialog.runScan();
    }

    function openOperationQueueDialog() {
        win.closeAllMenus();
        win.queueDialogOpen = true;
    }

    function openRemoteConnectionsDialog(selectId) {
        win.closeAllMenus();
        win.remoteConnectionsOpen = true;
        if (selectId)
            remoteConnectionsDialog.loadConnectionById(selectId);
        else
            remoteConnectionsDialog.resetForm();
    }

    function openOpenWithDialog(targetPath, initialTab) {
        win.closeAllMenus();
        var tp = targetPath || currentHighlightedPath();
        if (!tp) {
            backend.showStatus(qsTr("Select a file or folder first."));
            return;
        }
        win.openWithTargetPath = tp;
        win.openWithTab = (initialTab === 1) ? 1 : 0;
        win.openWithMimeInfo = backend.getFileMimeInfo(tp);
        win.openWithAppsList = backend.getApplicationsForFile(tp);
        win.openWithAllApps = [];
        win.openWithOpen = true;
        openWithDialog.resetFilters();
    }

    function runCustomActionAndShow(actionId, fallbackPath) {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length === 0 && fallbackPath)
            paths = [fallbackPath];
        var res = backend.executeCustomAction(actionId, paths);
        if (res && res.showOutput) {
            win.commandOutputText = (res.output && res.output.length > 0) ? res.output : (res.command || "");
            win.commandOutputOpen = true;
        }
    }

    // ================= GLOBAL SHORTCUTS =================

    Shortcut { sequence: "Tab"; enabled: !win.commandPaletteOpen; context: Qt.ApplicationShortcut; onActivated: {
        backend.switchPanel();
        currentListView().forceActiveFocus();
        updateQuickView();
    }}
    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: win.helpOpen = !win.helpOpen }
    Shortcut { sequence: "F1"; context: Qt.ApplicationShortcut; onActivated: win.helpOpen = !win.helpOpen }
    Shortcut { sequence: "F3"; context: Qt.ApplicationShortcut; onActivated: triggerF3View() }
    Shortcut { sequence: "F4"; context: Qt.ApplicationShortcut; onActivated: triggerF4Edit() }
    Shortcut { sequence: "F5"; context: Qt.ApplicationShortcut; onActivated: triggerF5Copy() }
    Shortcut { sequence: "F6"; context: Qt.ApplicationShortcut; onActivated: triggerF6Move() }
    Shortcut { sequence: "Shift+F6"; context: Qt.ApplicationShortcut; onActivated: triggerRename() }
    Shortcut { sequence: "F7"; context: Qt.ApplicationShortcut; onActivated: triggerF7NewFolder() }
    Shortcut { sequence: "F8"; context: Qt.ApplicationShortcut; onActivated: triggerF8Delete() }
    Shortcut { sequence: "Delete"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: triggerF8Delete() }
    Shortcut { sequences: ["F9", "Alt+T"]; context: Qt.ApplicationShortcut; onActivated: backend.openInTerminal(currentModel().path) }
    Shortcut { sequence: "F10"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }

    // Per-panel Tabs
    Shortcut { sequence: "Ctrl+T"; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().addTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: "Ctrl+W"; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().closeTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: "Ctrl+Tab"; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().nextTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: "Ctrl+Shift+Tab"; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().prevTab();
        currentListView().forceActiveFocus();
    }}

    // System Clipboard & Undo (yields cleanly when editing text fields)
    Shortcut { sequence: "Ctrl+C"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            backend.copyToClipboard(paths);
    }}
    Shortcut { sequence: "Ctrl+X"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            backend.cutToClipboard(paths);
    }}
    Shortcut { sequence: "Ctrl+V"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        backend.pasteFromClipboard(currentModel().path);
    }}
    Shortcut { sequence: "Ctrl+Z"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        if (!backend.undoLastOperation() && !backend.canUndo)
            backend.showStatus(qsTr("Nothing to undo."));
    }}
    Shortcut { sequence: "Ctrl+Shift+C"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        backend.copyNamesAsCsv(paths);
    }}
    Shortcut { sequence: "Ctrl+Alt+C"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        backend.copyPathsAsCsv(paths);
    }}

    // Item Properties & Permissions
    Shortcut { sequences: ["Alt+Return", "Alt+Enter"]; enabled: !win.commandPaletteOpen; context: Qt.ApplicationShortcut; onActivated: triggerProperties() }

    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: {
        win.quickViewActive = !win.quickViewActive;
        if (win.quickViewActive)
            updateQuickView();
    }}
    Shortcut { sequence: "Ctrl+L"; context: Qt.ApplicationShortcut; onActivated: currentPanelItem().openPathEditor() }
    Shortcut { sequence: "Ctrl+U"; context: Qt.ApplicationShortcut; onActivated: backend.swapPanels() }
    Shortcut { sequence: "Alt+="; context: Qt.ApplicationShortcut; onActivated: backend.syncPanels() }
    Shortcut { sequence: "Shift+F2"; context: Qt.ApplicationShortcut; onActivated: backend.compareDirectories() }
    Shortcut { sequence: "Ctrl+M"; context: Qt.ApplicationShortcut; onActivated: triggerMultiRename() }
    Shortcut { sequence: "Alt+F5"; context: Qt.ApplicationShortcut; onActivated: triggerPackArchive() }
    Shortcut { sequence: "Alt+F9"; context: Qt.ApplicationShortcut; onActivated: triggerExtractArchive() }
    Shortcut { sequence: "Alt+Shift+Return"; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().calculateAllFolderSizes();
        backend.showStatus(qsTr("Calculated sizes for all folders."));
    }}
    Shortcut { sequence: "Alt+Left"; context: Qt.ApplicationShortcut; onActivated: currentModel().goBack() }
    Shortcut { sequence: "Alt+Right"; context: Qt.ApplicationShortcut; onActivated: currentModel().goForward() }
    Shortcut { sequence: "Ctrl+S"; context: Qt.ApplicationShortcut; onActivated: toggleFilterBar() }
    Shortcut { sequence: "Ctrl+B"; context: Qt.ApplicationShortcut; onActivated: win.bookmarksOpen = !win.bookmarksOpen }
    Shortcut { sequence: "Ctrl+D"; context: Qt.ApplicationShortcut; onActivated: currentModel().deselectAll() }
    Shortcut { sequence: "Alt+F7"; context: Qt.ApplicationShortcut; onActivated: win.openAdvancedSearchDialog() }
    Shortcut { sequence: "Ctrl+Shift+D"; context: Qt.ApplicationShortcut; onActivated: currentModel().toggleDiskUsageMode() }
    Shortcut { sequence: "Ctrl+Shift+S"; context: Qt.ApplicationShortcut; onActivated: win.openSyncDirsDialog() }
    Shortcut { sequence: "Ctrl+Shift+F7"; context: Qt.ApplicationShortcut; onActivated: win.openDuplicateFinderDialog() }
    Shortcut { sequence: "Ctrl+Shift+Q"; context: Qt.ApplicationShortcut; onActivated: win.openOperationQueueDialog() }
    Shortcut { sequence: "Ctrl+Shift+M"; context: Qt.ApplicationShortcut; onActivated: win.openRemoteConnectionsDialog("") }
    Shortcut { sequence: "Ctrl+Shift+O"; context: Qt.ApplicationShortcut; onActivated: win.openOpenWithDialog("", 0) }
    Shortcut { sequence: "Ctrl+H"; context: Qt.ApplicationShortcut; onActivated: {
        var m = currentModel();
        m.setShowHidden(!m.showHidden);
    }}
    Shortcut { sequence: "Ctrl+F3"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(0) }
    Shortcut { sequence: "Ctrl+F4"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(1) }
    Shortcut { sequence: "Ctrl+F5"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(3) }
    Shortcut { sequence: "Ctrl+F6"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(2) }
    Shortcut { sequence: "Ctrl+R"; context: Qt.ApplicationShortcut; onActivated: currentModel().refresh() }
    Shortcut { sequence: "Ctrl+A"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: currentModel().selectAll() }
    Shortcut { sequence: "Ctrl+Shift+A"; context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }

    // New File (Shift+F4)
    Shortcut { sequence: "Shift+F4"; context: Qt.ApplicationShortcut; onActivated: triggerNewFile() }

    // Create Symlink (Ctrl+Shift+F5)
    Shortcut { sequence: "Ctrl+Shift+F5"; context: Qt.ApplicationShortcut; onActivated: triggerSymlink() }

    // Visual Diff (Ctrl+Alt+D)
    Shortcut { sequence: "Ctrl+Alt+D"; context: Qt.ApplicationShortcut; onActivated: triggerFileDiff() }

    // Select / Deselect by Mask (Num+ / Num-)
    Shortcut { sequences: ["+", "Shift+=", "Num++"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: openMaskDialog(true) }
    Shortcut { sequences: ["-", "Num+-"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: openMaskDialog(false) }
    Shortcut { sequences: ["*", "Num+*"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }

    // View Modes (Ctrl+1 / Ctrl+2), Flat View (Ctrl+Shift+B), Palette (Ctrl+Shift+P / Ctrl+P) & Theme Toggle (Ctrl+Shift+T)
    Shortcut { sequence: "Ctrl+1"; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(0) }
    Shortcut { sequence: "Ctrl+2"; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(1) }
    Shortcut { sequence: "Ctrl+Shift+B"; context: Qt.ApplicationShortcut; onActivated: currentModel().toggleFlatView() }
    Shortcut { sequence: "Ctrl+Shift+P"; context: Qt.ApplicationShortcut; onActivated: win.openCommandPalette("commands") }
    Shortcut { sequence: "Ctrl+P"; context: Qt.ApplicationShortcut; onActivated: win.openCommandPalette("jump") }
    Shortcut { sequence: "Ctrl+Shift+T"; context: Qt.ApplicationShortcut; onActivated: backend.toggleThemeMode() }

    // Menu Bar Access Shortcuts (Alt+F, Alt+E, Alt+V, Alt+C, Alt+H)
    Shortcut { sequence: "Alt+F"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); filesMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+E"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); editMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+V"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); viewMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+C"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); commandsMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+H"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); helpMenu.open(); win.menuBarActive = true; } }

    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: {
        if (win.isAnyMenuOpen()) { win.closeAllMenus(); return; }
        if (commandPaletteOpen) { commandPaletteOpen = false; currentListView().forceActiveFocus(); return; }
        if (syncDirsOpen) { syncDirsOpen = false; currentListView().forceActiveFocus(); return; }
        if (duplicateFinderOpen) { duplicateFinderOpen = false; currentListView().forceActiveFocus(); return; }
        if (queueDialogOpen) { queueDialogOpen = false; currentListView().forceActiveFocus(); return; }
        if (remoteConnectionsOpen) { remoteConnectionsOpen = false; currentListView().forceActiveFocus(); return; }
        if (openWithOpen) { openWithOpen = false; currentListView().forceActiveFocus(); return; }
        if (aboutOpen) { aboutOpen = false; return; }
        if (conflictDialog.visible) { conflictDialog.answer(4); return; }
        if (propertiesOpen) { propertiesOpen = false; return; }
        if (helpOpen) { helpOpen = false; return; }
        if (previewOpen) { previewOpen = false; return; }
        if (searchOpen) {
            if (backend.searchRunning)
                backend.cancelSearch();
            searchOpen = false;
            return;
        }
        if (newFileOpen) { newFileOpen = false; return; }
        if (symlinkOpen) { symlinkOpen = false; return; }
        if (maskOpen) { maskOpen = false; return; }
        if (checksumOpen) { checksumOpen = false; return; }
        if (diffOpen) { diffOpen = false; return; }
        if (newFolderOpen) { newFolderOpen = false; return; }
        if (renameOpen) { renameOpen = false; return; }
        if (multiRenameOpen) { multiRenameOpen = false; return; }
        if (packArchiveOpen) { packArchiveOpen = false; return; }
        if (bookmarksOpen) { bookmarksOpen = false; return; }
        if (commandOutputOpen) { commandOutputOpen = false; return; }
        if (confirmCopyOpen) { confirmCopyOpen = false; return; }
        if (confirmMoveOpen) { confirmMoveOpen = false; return; }
        if (confirmDeleteOpen) { confirmDeleteOpen = false; return; }
        if (leftPane.pathEditing || rightPane.pathEditing) {
            leftPane.pathEditing = false;
            rightPane.pathEditing = false;
            currentListView().forceActiveFocus();
            return;
        }
        if (cmdLineInput.input.activeFocus) {
            currentListView().forceActiveFocus();
            return;
        }
        if (win.quickViewActive) { win.quickViewActive = false; return; }
        if (currentPanelItem().filterVisible || currentModel().filter.length > 0) {
            currentPanelItem().setFilterOpen(false);
            return;
        }
    }}

    // ================= MAIN WINDOW LAYOUT =================

    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Top App Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                implicitHeight: 40
                height: 40
                color: p.appBarBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    // App Brand Mark
                    RowLayout {
                        spacing: 8
                        Layout.preferredHeight: 24

                        Image {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            width: 22
                            height: 22
                            source: "qrc:/logo.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            smooth: true
                        }

                        Text {
                            text: "AeroCommander"
                            font.bold: true
                            font.pixelSize: 14
                            color: p.textPrimary
                        }
                    }

                    Rectangle { width: 1; height: 18; color: p.borderDefault }

                    // Dropdown Menu Bar
                    RowLayout {
                        spacing: 2

                        // Files Menu
                        MenuBarBtn {
                            id: btnFiles
                            label: qsTr("Files")
                            active: filesMenu.visible
                            onClicked: {
                                if (filesMenu.visible) {
                                    filesMenu.close();
                                    win.menuBarActive = false;
                                } else {
                                    win.closeAllMenus();
                                    filesMenu.open();
                                    win.menuBarActive = true;
                                }
                            }
                            onEntered: {
                                if (win.menuBarActive && !filesMenu.visible) {
                                    win.closeAllMenus();
                                    filesMenu.open();
                                    win.menuBarActive = true;
                                }
                            }

                            AppMenu {
                                id: filesMenu
                                y: btnFiles.height + 2
                                onClosed: Qt.callLater(function() { if (!win.isAnyMenuOpen()) win.menuBarActive = false; })

                                AppMenuItem {
                                    text: qsTr("New File...")
                                    shortcutHint: "Shift+F4"
                                    onTriggered: triggerNewFile()
                                }
                                AppMenuItem {
                                    text: qsTr("New Folder...")
                                    shortcutHint: "F7"
                                    onTriggered: triggerF7NewFolder()
                                }
                                AppMenuItem {
                                    text: qsTr("View / Preview")
                                    shortcutHint: "F3"
                                    onTriggered: triggerF3View()
                                }
                                AppMenuItem {
                                    text: qsTr("Edit File")
                                    shortcutHint: "F4"
                                    onTriggered: triggerF4Edit()
                                }
                                AppMenuItem {
                                    text: qsTr("Open With / Custom Actions...")
                                    shortcutHint: "Ctrl+Shift+O"
                                    onTriggered: win.openOpenWithDialog("", 0)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Copy...")
                                    shortcutHint: "F5"
                                    onTriggered: triggerF5Copy()
                                }
                                AppMenuItem {
                                    text: qsTr("Move / Rename...")
                                    shortcutHint: "F6"
                                    onTriggered: triggerF6Move()
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Rename")
                                    shortcutHint: "Shift+F6"
                                    onTriggered: triggerRename()
                                }
                                AppMenuItem {
                                    text: qsTr("Multi-Rename...")
                                    shortcutHint: "Ctrl+M"
                                    onTriggered: triggerMultiRename()
                                }
                                AppMenuItem {
                                    text: qsTr("Delete...")
                                    shortcutHint: "F8"
                                    onTriggered: triggerF8Delete()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Create Symlink...")
                                    shortcutHint: "Ctrl+Shift+F5"
                                    onTriggered: triggerSymlink()
                                }
                                AppMenuItem {
                                    text: qsTr("Calculate Checksum...")
                                    onTriggered: triggerChecksum()
                                }
                                AppMenuItem {
                                    text: qsTr("Properties & Permissions...")
                                    shortcutHint: "Alt+Enter"
                                    onTriggered: triggerProperties()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Pack Archive...")
                                    shortcutHint: "Alt+F5"
                                    onTriggered: triggerPackArchive()
                                }
                                AppMenuItem {
                                    text: qsTr("Extract Archive...")
                                    shortcutHint: "Alt+F9"
                                    onTriggered: triggerExtractArchive()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Exit")
                                    shortcutHint: "Alt+F4"
                                    onTriggered: Qt.quit()
                                }
                            }
                        }

                        // Edit Menu
                        MenuBarBtn {
                            id: btnEdit
                            label: qsTr("Edit")
                            active: editMenu.visible
                            onClicked: {
                                if (editMenu.visible) {
                                    editMenu.close();
                                    win.menuBarActive = false;
                                } else {
                                    win.closeAllMenus();
                                    editMenu.open();
                                    win.menuBarActive = true;
                                }
                            }
                            onEntered: {
                                if (win.menuBarActive && !editMenu.visible) {
                                    win.closeAllMenus();
                                    editMenu.open();
                                    win.menuBarActive = true;
                                }
                            }

                            AppMenu {
                                id: editMenu
                                objectName: "editMenu"
                                y: btnEdit.height + 2
                                onClosed: Qt.callLater(function() { if (!win.isAnyMenuOpen()) win.menuBarActive = false; })

                                AppMenuItem {
                                    text: backend.canUndo ? qsTr("Undo: %1").arg(backend.undoDescription) : qsTr("Undo")
                                    shortcutHint: "Ctrl+Z"
                                    enabled: backend.canUndo
                                    onTriggered: backend.undoLastOperation()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Cut to Clipboard")
                                    shortcutHint: "Ctrl+X"
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        if (paths.length > 0)
                                            backend.cutToClipboard(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Copy to Clipboard")
                                    shortcutHint: "Ctrl+C"
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        if (paths.length > 0)
                                            backend.copyToClipboard(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: backend.canPaste
                                          ? (backend.clipboardIsCut ? qsTr("Paste Cut (%1)").arg(backend.clipboardPaths.length)
                                                                    : qsTr("Paste (%1)").arg(backend.clipboardPaths.length))
                                          : qsTr("Paste")
                                    shortcutHint: "Ctrl+V"
                                    enabled: backend.canPaste
                                    onTriggered: backend.pasteFromClipboard(currentModel().path)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Copy Name(s) as Text (, )")
                                    shortcutHint: "Ctrl+Shift+C"
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        backend.copyNamesAsCsv(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Copy Path(s) as Text (, )")
                                    shortcutHint: "Ctrl+Alt+C"
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        backend.copyPathsAsCsv(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Copy All Names in Folder (, )")
                                    onTriggered: backend.copyFolderContentsAsCsv(currentModel().path, false)
                                }
                                AppMenuItem {
                                    text: qsTr("Copy All Paths in Folder (, )")
                                    onTriggered: backend.copyFolderContentsAsCsv(currentModel().path, true)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Select All")
                                    shortcutHint: "Ctrl+A"
                                    onTriggered: currentModel().selectAll()
                                }
                                AppMenuItem {
                                    text: qsTr("Deselect All")
                                    shortcutHint: "Ctrl+D"
                                    onTriggered: currentModel().deselectAll()
                                }
                                AppMenuItem {
                                    text: qsTr("Invert Selection")
                                    shortcutHint: "Num*"
                                    onTriggered: currentModel().invertSelection()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Select by Pattern...")
                                    shortcutHint: "Num+"
                                    onTriggered: openMaskDialog(true)
                                }
                                AppMenuItem {
                                    text: qsTr("Deselect by Pattern...")
                                    shortcutHint: "Num-"
                                    onTriggered: openMaskDialog(false)
                                }
                            }
                        }

                        // View Menu
                        MenuBarBtn {
                            id: btnView
                            label: qsTr("View")
                            active: viewMenu.visible
                            onClicked: {
                                if (viewMenu.visible) {
                                    viewMenu.close();
                                    win.menuBarActive = false;
                                } else {
                                    win.closeAllMenus();
                                    viewMenu.open();
                                    win.menuBarActive = true;
                                }
                            }
                            onEntered: {
                                if (win.menuBarActive && !viewMenu.visible) {
                                    win.closeAllMenus();
                                    viewMenu.open();
                                    win.menuBarActive = true;
                                }
                            }

                            AppMenu {
                                id: viewMenu
                                y: btnView.height + 2
                                onClosed: Qt.callLater(function() { if (!win.isAnyMenuOpen()) win.menuBarActive = false; })

                                AppMenuItem {
                                    text: qsTr("Detailed List")
                                    shortcutHint: "Ctrl+1"
                                    checkable: true
                                    checked: currentModel().viewMode === 0
                                    onTriggered: currentModel().setViewMode(0)
                                }
                                AppMenuItem {
                                    text: qsTr("Grid / Thumbnails")
                                    shortcutHint: "Ctrl+2"
                                    checkable: true
                                    checked: currentModel().viewMode === 1
                                    onTriggered: currentModel().setViewMode(1)
                                }
                                AppMenuItem {
                                    text: qsTr("Quick View Panel")
                                    shortcutHint: "Ctrl+Q"
                                    checkable: true
                                    checked: win.quickViewActive
                                    onTriggered: {
                                        win.quickViewActive = !win.quickViewActive;
                                        if (win.quickViewActive)
                                            updateQuickView();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Flat / Branch View")
                                    shortcutHint: "Ctrl+Shift+B"
                                    checkable: true
                                    checked: currentModel().flatView
                                    onTriggered: currentModel().toggleFlatView()
                                }
                                AppMenuItem {
                                    text: qsTr("Disk Usage Analyzer")
                                    shortcutHint: "Ctrl+Shift+D"
                                    checkable: true
                                    checked: currentModel().diskUsageMode
                                    onTriggered: currentModel().toggleDiskUsageMode()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Show Hidden Files")
                                    shortcutHint: "Ctrl+H"
                                    checkable: true
                                    checked: currentModel().showHidden
                                    onTriggered: {
                                        var m = currentModel();
                                        m.setShowHidden(!m.showHidden);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Filter")
                                    shortcutHint: "Ctrl+S"
                                    onTriggered: toggleFilterBar()
                                }
                                AppMenuItem {
                                    text: qsTr("Refresh")
                                    shortcutHint: "Ctrl+R"
                                    onTriggered: currentModel().refresh()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Sort by Name")
                                    checkable: true
                                    checked: currentModel().sortField === 0
                                    onTriggered: currentModel().setSortField(0)
                                }
                                AppMenuItem {
                                    text: qsTr("Sort by Extension")
                                    checkable: true
                                    checked: currentModel().sortField === 1
                                    onTriggered: currentModel().setSortField(1)
                                }
                                AppMenuItem {
                                    text: qsTr("Sort by Size")
                                    checkable: true
                                    checked: currentModel().sortField === 2
                                    onTriggered: currentModel().setSortField(2)
                                }
                                AppMenuItem {
                                    text: qsTr("Sort by Date")
                                    checkable: true
                                    checked: currentModel().sortField === 3
                                    onTriggered: currentModel().setSortField(3)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Theme: Dark")
                                    shortcutHint: "Ctrl+Shift+T"
                                    checkable: true
                                    checked: win.isDark
                                    onTriggered: backend.themeMode = "dark"
                                }
                                AppMenuItem {
                                    text: qsTr("Theme: Light")
                                    shortcutHint: "Ctrl+Shift+T"
                                    checkable: true
                                    checked: !win.isDark
                                    onTriggered: backend.themeMode = "light"
                                }
                            }
                        }

                        // Commands Menu
                        MenuBarBtn {
                            id: btnCommands
                            label: qsTr("Commands")
                            active: commandsMenu.visible
                            onClicked: {
                                if (commandsMenu.visible) {
                                    commandsMenu.close();
                                    win.menuBarActive = false;
                                } else {
                                    win.closeAllMenus();
                                    commandsMenu.open();
                                    win.menuBarActive = true;
                                }
                            }
                            onEntered: {
                                if (win.menuBarActive && !commandsMenu.visible) {
                                    win.closeAllMenus();
                                    commandsMenu.open();
                                    win.menuBarActive = true;
                                }
                            }

                            AppMenu {
                                id: commandsMenu
                                y: btnCommands.height + 2
                                onClosed: Qt.callLater(function() { if (!win.isAnyMenuOpen()) win.menuBarActive = false; })

                                AppMenuItem {
                                    text: qsTr("Command Palette...")
                                    shortcutHint: "Ctrl+Shift+P"
                                    onTriggered: win.openCommandPalette("commands")
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Jump to Folder...")
                                    shortcutHint: "Ctrl+P"
                                    onTriggered: win.openCommandPalette("jump")
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Find Files...")
                                    shortcutHint: "Alt+F7"
                                    onTriggered: win.openAdvancedSearchDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Find Duplicate Files...")
                                    shortcutHint: "Ctrl+Shift+F7"
                                    onTriggered: win.openDuplicateFinderDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Synchronize Directories...")
                                    shortcutHint: "Ctrl+Shift+S"
                                    onTriggered: win.openSyncDirsDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Operation Queue...")
                                    shortcutHint: "Ctrl+Shift+Q"
                                    onTriggered: win.openOperationQueueDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Remote Connections (SFTP / SMB)...")
                                    shortcutHint: "Ctrl+Shift+M"
                                    onTriggered: win.openRemoteConnectionsDialog("")
                                }
                                AppMenuItem {
                                    text: qsTr("Compare Directories")
                                    shortcutHint: "Shift+F2"
                                    onTriggered: backend.compareDirectories()
                                }
                                AppMenuItem {
                                    text: qsTr("Compare Files (Diff)...")
                                    shortcutHint: "Ctrl+Alt+D"
                                    onTriggered: triggerFileDiff()
                                }
                                AppMenuItem {
                                    text: qsTr("Calculate Folder Sizes")
                                    shortcutHint: "Alt+Shift+Enter"
                                    onTriggered: {
                                        currentModel().calculateAllFolderSizes();
                                        backend.showStatus(qsTr("Calculated sizes for all folders."));
                                    }
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("New Tab")
                                    shortcutHint: "Ctrl+T"
                                    onTriggered: {
                                        currentModel().addTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Close Tab")
                                    shortcutHint: "Ctrl+W"
                                    onTriggered: {
                                        currentModel().closeTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Next Tab")
                                    shortcutHint: "Ctrl+Tab"
                                    onTriggered: {
                                        currentModel().nextTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Swap Panels")
                                    shortcutHint: "Ctrl+U"
                                    onTriggered: backend.swapPanels()
                                }
                                AppMenuItem {
                                    text: qsTr("Sync Panels")
                                    shortcutHint: "Alt+="
                                    onTriggered: backend.syncPanels()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Add Bookmark")
                                    shortcutHint: "Ctrl+B"
                                    onTriggered: backend.addBookmark(currentModel().path)
                                }
                                AppMenuItem {
                                    text: qsTr("Open Terminal Here")
                                    shortcutHint: "F9"
                                    onTriggered: backend.openInTerminal(currentModel().path)
                                }
                            }
                        }

                        // Help Menu
                        MenuBarBtn {
                            id: btnHelp
                            label: qsTr("Help")
                            active: helpMenu.visible
                            onClicked: {
                                if (helpMenu.visible) {
                                    helpMenu.close();
                                    win.menuBarActive = false;
                                } else {
                                    win.closeAllMenus();
                                    helpMenu.open();
                                    win.menuBarActive = true;
                                }
                            }
                            onEntered: {
                                if (win.menuBarActive && !helpMenu.visible) {
                                    win.closeAllMenus();
                                    helpMenu.open();
                                    win.menuBarActive = true;
                                }
                            }

                            AppMenu {
                                id: helpMenu
                                y: btnHelp.height + 2
                                onClosed: Qt.callLater(function() { if (!win.isAnyMenuOpen()) win.menuBarActive = false; })

                                AppMenuItem {
                                    text: qsTr("Keyboard Shortcuts")
                                    shortcutHint: "?"
                                    onTriggered: win.helpOpen = true
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("About omapanel")
                                    onTriggered: win.aboutOpen = true
                                }
                            }
                        }
                    }

                    // Flexible middle spacer pushing quick actions to the right
                    Item { Layout.fillWidth: true }

                    // Compact right-side quick access toolbar (Undo, Paste, Quick View, Shortcuts)
                    RowLayout {
                        spacing: 4

                        ToolbarBtn {
                            visible: backend.canUndo
                            label: qsTr("Undo")
                            shortcutHint: "Ctrl+Z"
                            btnEnabled: backend.canUndo
                            accentHighlight: true
                            tooltipText: qsTr("Undo: %1").arg(backend.undoDescription)
                            onClicked: backend.undoLastOperation()
                        }

                        ToolbarBtn {
                            visible: backend.canPaste
                            label: backend.clipboardIsCut
                                   ? qsTr("Paste Cut (%1)").arg(backend.clipboardPaths.length)
                                   : qsTr("Paste (%1)").arg(backend.clipboardPaths.length)
                            shortcutHint: "Ctrl+V"
                            accentHighlight: true
                            onClicked: backend.pasteFromClipboard(currentModel().path)
                        }

                        ToolbarBtn {
                            label: qsTr("Quick View")
                            shortcutHint: "Ctrl+Q"
                            active: win.quickViewActive
                            tooltipText: qsTr("Toggle Quick View (Ctrl+Q)")
                            onClicked: {
                                win.quickViewActive = !win.quickViewActive;
                                if (win.quickViewActive)
                                    updateQuickView();
                            }
                        }

                        ToolbarBtn {
                            label: qsTr("Palette")
                            shortcutHint: "Ctrl+P"
                            tooltipText: qsTr("Command Palette (Ctrl+Shift+P) & Quick Jump (Ctrl+P)")
                            onClicked: win.openCommandPalette("commands")
                        }

                        ToolbarBtn {
                            label: qsTr("Shortcuts")
                            shortcutHint: "?"
                            accentHighlight: true
                            tooltipText: qsTr("Keyboard Shortcuts (?)")
                            onClicked: win.helpOpen = true
                        }

                        Rectangle { width: 1; height: 16; color: p.borderDefault }

                        // Segmented 2026 Light / Dark Theme Switcher Pill
                        Rectangle {
                            id: themeSwitcherPill
                            implicitHeight: 26
                            implicitWidth: themeSwitchRow.implicitWidth + 4
                            radius: win.smallRadius
                            color: p.subBarBg
                            border.width: 1
                            border.color: p.borderDefault

                            RowLayout {
                                id: themeSwitchRow
                                anchors.centerIn: parent
                                spacing: 2

                                Rectangle {
                                    implicitHeight: 20
                                    implicitWidth: lightSegRow.implicitWidth + 12
                                    radius: Math.max(0, win.smallRadius - 1)
                                    color: !win.isDark ? Qt.alpha(p.accent, 0.16)
                                                       : (lightSegMouse.containsMouse ? p.btnHoverBg : "transparent")
                                    border.width: !win.isDark ? 1 : 0
                                    border.color: Qt.alpha(p.accent, 0.48)

                                    RowLayout {
                                        id: lightSegRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        VectorIcon {
                                            width: 12
                                            height: 12
                                            kind: "sun"
                                            iconColor: !win.isDark ? p.accent : (lightSegMouse.containsMouse ? p.textPrimary : p.textMuted)
                                        }

                                        Text {
                                            text: qsTr("Light")
                                            font.pixelSize: 11
                                            font.weight: !win.isDark ? Font.DemiBold : Font.Normal
                                            color: !win.isDark ? p.accent : (lightSegMouse.containsMouse ? p.textPrimary : p.textMuted)
                                        }
                                    }

                                    MouseArea {
                                        id: lightSegMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.themeMode = "light"
                                    }

                                    ToolTip.visible: lightSegMouse.containsMouse
                                    ToolTip.delay: 450
                                    ToolTip.text: qsTr("Switch to Light theme (Ctrl+Shift+T)")
                                }

                                Rectangle {
                                    implicitHeight: 20
                                    implicitWidth: darkSegRow.implicitWidth + 12
                                    radius: Math.max(0, win.smallRadius - 1)
                                    color: win.isDark ? Qt.alpha(p.accent, 0.16)
                                                      : (darkSegMouse.containsMouse ? p.btnHoverBg : "transparent")
                                    border.width: win.isDark ? 1 : 0
                                    border.color: Qt.alpha(p.accent, 0.48)

                                    RowLayout {
                                        id: darkSegRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        VectorIcon {
                                            width: 12
                                            height: 12
                                            kind: "moon"
                                            iconColor: win.isDark ? p.accent : (darkSegMouse.containsMouse ? p.textPrimary : p.textMuted)
                                        }

                                        Text {
                                            text: qsTr("Dark")
                                            font.pixelSize: 11
                                            font.weight: win.isDark ? Font.DemiBold : Font.Normal
                                            color: win.isDark ? p.accent : (darkSegMouse.containsMouse ? p.textPrimary : p.textMuted)
                                        }
                                    }

                                    MouseArea {
                                        id: darkSegMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.themeMode = "dark"
                                    }

                                    ToolTip.visible: darkSegMouse.containsMouse
                                    ToolTip.delay: 450
                                    ToolTip.text: qsTr("Switch to Dark theme (Ctrl+Shift+T)")
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }
            }

            // Drives, Bookmarks & Panel Sync Strip
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: p.subBarBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: drivesBookmarksRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        RowLayout {
                            id: drivesBookmarksRow
                            height: parent.height
                            spacing: 5

                            Text {
                                text: qsTr("Drives")
                                font.pixelSize: 11
                                font.bold: true
                                color: p.textDim
                            }

                            Repeater {
                                model: backend.drives
                                delegate: Rectangle {
                                    readonly property bool isDevMounted: modelData.isMounted !== false
                                    readonly property bool isRemoteDev: modelData.isRemote === true
                                    implicitHeight: 22
                                    implicitWidth: driveRow.implicitWidth + (modelData.canUnmount ? 24 : 12)
                                    radius: win.smallRadius
                                    color: driveMouse.containsMouse ? p.chipHoverBg : (isDevMounted ? p.chipBg : p.chipUnmountedBg)
                                    border.width: 1
                                    border.color: !isDevMounted ? p.borderStrong : (currentModel().path === modelData.path ? Qt.alpha(p.accent, 0.55) : p.borderDefault)

                                    RowLayout {
                                        id: driveRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        VectorIcon {
                                            width: 13
                                            height: 13
                                            kind: isRemoteDev ? "network" : (modelData.isRemovable ? "usb" : "drive")
                                            iconColor: !isDevMounted ? p.textDim : (currentModel().path === modelData.path ? p.accent : p.textMuted)
                                        }

                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: isDevMounted ? p.textPrimary : p.textMuted
                                        }

                                        Text {
                                            visible: (modelData.free || "").length > 0
                                            text: modelData.free
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            color: isRemoteDev ? p.accent : p.textDim
                                        }

                                        // Mount / Connect button for unmounted disks & saved remotes
                                        Rectangle {
                                            visible: !isDevMounted
                                            implicitHeight: 16
                                            implicitWidth: mntText.implicitWidth + 8
                                            radius: 2
                                            color: mntMouse.containsMouse ? p.accent : p.badgeBg

                                            Text {
                                                id: mntText
                                                anchors.centerIn: parent
                                                text: isRemoteDev ? qsTr("Connect") : qsTr("Mount")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: mntMouse.containsMouse ? p.accentFg : p.textSecondary
                                            }

                                            MouseArea {
                                                id: mntMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (isRemoteDev)
                                                        backend.connectRemote(modelData.remoteId || modelData.remoteUri);
                                                    else
                                                        backend.mountDevice(modelData.devPath);
                                                }
                                            }
                                        }

                                        // Eject/unmount/disconnect button for removable & remote mounts
                                        Rectangle {
                                            visible: isDevMounted && modelData.canUnmount
                                            implicitHeight: 16
                                            implicitWidth: 16
                                            radius: 2
                                            color: unmountMouse.containsMouse ? p.dangerHoverBg : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "⏏"
                                                font.pixelSize: 10
                                                color: unmountMouse.containsMouse ? p.dangerAccent : p.textMuted
                                            }

                                            MouseArea {
                                                id: unmountMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (isRemoteDev)
                                                        backend.disconnectRemote(modelData.remoteId || modelData.path);
                                                    else
                                                        backend.unmountDevice(modelData.path);
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: driveMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton && isRemoteDev) {
                                                win.openRemoteConnectionsDialog(modelData.remoteId || "");
                                                return;
                                            }
                                            if (isDevMounted) {
                                                currentModel().setPath(modelData.path);
                                                currentListView().forceActiveFocus();
                                            } else if (isRemoteDev) {
                                                backend.connectRemote(modelData.remoteId || modelData.remoteUri);
                                            } else {
                                                backend.mountDevice(modelData.devPath);
                                            }
                                        }
                                    }

                                    ToolTip.visible: driveMouse.containsMouse && isRemoteDev
                                    ToolTip.delay: 450
                                    ToolTip.text: (modelData.remoteUri || modelData.path || "") + "  (" + qsTr("Right-click to edit") + ")"
                                }
                            }

                            Rectangle {
                                implicitHeight: 22
                                implicitWidth: addRemoteRow.implicitWidth + 12
                                radius: win.smallRadius
                                color: addRemoteMouse.containsMouse ? p.chipHoverBg : "transparent"
                                border.width: 1
                                border.color: p.borderDefault

                                RowLayout {
                                    id: addRemoteRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    VectorIcon {
                                        width: 12
                                        height: 12
                                        kind: "network"
                                        iconColor: p.accent
                                    }

                                    Text {
                                        text: "+ " + qsTr("Remote")
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: p.accent
                                    }
                                }

                                MouseArea {
                                    id: addRemoteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.openRemoteConnectionsDialog("")
                                }

                                ToolTip.visible: addRemoteMouse.containsMouse
                                ToolTip.delay: 450
                                ToolTip.text: qsTr("Remote Connections — SFTP / SMB / SSHFS (Ctrl+Shift+M)")
                            }

                            Rectangle { width: 1; height: 14; color: p.borderDefault }

                            Text {
                                text: qsTr("Bookmarks")
                                font.pixelSize: 11
                                font.bold: true
                                color: p.textDim
                            }

                            Repeater {
                                model: backend.bookmarks
                                delegate: Rectangle {
                                    implicitHeight: 22
                                    implicitWidth: bmRow.implicitWidth + 12
                                    radius: win.smallRadius
                                    color: bmMouse.containsMouse ? p.chipHoverBg : p.chipBg
                                    border.width: 1
                                    border.color: currentModel().path === modelData ? Qt.alpha(p.accent, 0.65) : p.borderDefault

                                    RowLayout {
                                        id: bmRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "★"
                                            font.pixelSize: 10
                                            color: p.accent
                                        }

                                        Text {
                                            text: modelData === "/" ? "/" : modelData.split("/").pop()
                                            font.pixelSize: 11
                                            color: currentModel().path === modelData ? p.accent : p.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        id: bmMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                backend.toggleBookmark(modelData);
                                            } else {
                                                currentModel().setPath(modelData);
                                                currentListView().forceActiveFocus();
                                            }
                                        }
                                    }

                                    ToolTip.visible: bmMouse.containsMouse
                                    ToolTip.delay: 500
                                    ToolTip.text: modelData + "  (" + qsTr("Right-click to remove") + ")"
                                }
                            }

                            Rectangle {
                                implicitHeight: 22
                                implicitWidth: addBmLabel.implicitWidth + 12
                                radius: win.smallRadius
                                color: addBmMouse.containsMouse ? p.chipHoverBg : "transparent"
                                border.width: 1
                                border.color: p.borderDefault

                                Text {
                                    id: addBmLabel
                                    anchors.centerIn: parent
                                    text: "+ ★"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: p.accent
                                }

                                MouseArea {
                                    id: addBmMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.toggleBookmark(currentModel().path)
                                }

                                ToolTip.visible: addBmMouse.containsMouse
                                ToolTip.delay: 450
                                ToolTip.text: qsTr("Toggle bookmark for active folder")
                            }
                        }
                    }

                    Rectangle { width: 1; height: 14; color: p.borderDefault }

                    // Pinned panel sync actions on the right so they never scroll out of view
                    ToolbarBtn {
                        implicitHeight: 22
                        label: "⇄ " + qsTr("Swap")
                        shortcutHint: "Ctrl+U"
                        onClicked: backend.swapPanels()
                    }

                    ToolbarBtn {
                        implicitHeight: 22
                        label: "= " + qsTr("Sync")
                        shortcutHint: "Alt+="
                        onClicked: backend.syncPanels()
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }
            }

            // Dual-Panel Workspace
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 6
                spacing: 6

                FilePanel {
                    id: leftPane
                    objectName: "leftPane"
                    panelIndex: 0
                    panelModel: backend.leftPanel
                    filterVisible: win.leftFilterVisible
                    onFilterVisibleChanged: win.leftFilterVisible = filterVisible
                }

                FilePanel {
                    id: rightPane
                    objectName: "rightPane"
                    panelIndex: 1
                    panelModel: backend.rightPanel
                    filterVisible: win.rightFilterVisible
                    onFilterVisibleChanged: win.rightFilterVisible = filterVisible
                }
            }

            // Status Notification / Background Progress Bar
            Rectangle {
                Layout.fillWidth: true
                height: backend.isBusy ? 34 : (backend.statusMessage.length > 0 ? 26 : 0)
                visible: height > 0
                color: p.panelFooterBg

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: backend.isPaused ? p.warningText : p.accent
                    }

                    Text {
                        text: backend.isBusy
                              ? (backend.isPaused ? (qsTr("Paused") + " · " + backend.busyTitle) : backend.busyTitle)
                              : backend.statusMessage
                        font.pixelSize: 11
                        font.weight: backend.isBusy ? Font.DemiBold : Font.Normal
                        color: backend.isPaused ? p.warningText : (backend.isBusy ? p.accent : p.textSecondary)
                        Layout.fillWidth: !backend.isBusy
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: backend.isBusy
                        text: backend.busyDetail
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textMuted
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }

                    Text {
                        visible: backend.isBusy && (backend.busySpeed || "").length > 0
                        text: backend.busySpeed
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.accent
                    }

                    Text {
                        visible: backend.isBusy && (backend.busyEta || "").length > 0
                        text: qsTr("ETA %1").arg(backend.busyEta)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textSecondary
                    }

                    Text {
                        visible: backend.isBusy
                        text: Math.round(backend.busyProgress * 100) + "%"
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textSecondary
                    }

                    // Slim custom progress track
                    Rectangle {
                        visible: backend.isBusy
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 6
                        radius: 3
                        color: p.borderDefault

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, backend.busyProgress))
                            height: parent.height
                            radius: 3
                            color: backend.isPaused ? p.warningText : p.accent
                        }
                    }

                    ToolbarBtn {
                        visible: backend.isBusy
                        implicitHeight: 22
                        label: qsTr("Queue (%1)").arg(backend.queueCount)
                        onClicked: win.openOperationQueueDialog()
                    }

                    ToolbarBtn {
                        visible: backend.isBusy
                        implicitHeight: 22
                        label: backend.isPaused ? qsTr("Resume") : qsTr("Pause")
                        accentHighlight: backend.isPaused
                        onClicked: backend.togglePauseOperation()
                    }

                    ToolbarBtn {
                        visible: backend.isBusy && backend.canCancel
                        implicitHeight: 22
                        label: qsTr("Cancel")
                        accentHighlight: !backend.isPaused
                        onClicked: backend.cancelOperation()
                    }
                }
            }

            // Mini Command Line Bar (Total Commander style)
            Rectangle {
                Layout.fillWidth: true
                height: 34
                color: p.subBarBg

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: currentModel().path + " ❯"
                        font.family: "monospace"
                        font.bold: true
                        font.pixelSize: 11
                        color: p.accent
                        Layout.maximumWidth: 360
                        elide: Text.ElideLeft
                    }

                    CompactField {
                        id: cmdLineInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        monospace: true
                        placeholderText: qsTr("Run command in active folder (e.g. git status, chmod +x ...)")
                        onAccepted: {
                            if (cmdLineInput.text.trim().length > 0) {
                                var res = backend.runCommand(cmdLineInput.text);
                                cmdLineInput.text = "";
                                if (res.output && res.output.indexOf("\n") !== -1) {
                                    win.commandOutputText = res.output;
                                    win.commandOutputOpen = true;
                                }
                                currentListView().forceActiveFocus();
                            }
                        }
                        onEscaped: currentListView().forceActiveFocus()
                    }
                }
            }

            // Bottom Function Keys Bar (Total Commander classic F3-F10)
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: p.fkeyBarBg

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderSubtle
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 5

                    FKeyButton { keyLabel: "F3"; actionLabel: qsTr("View"); onClicked: triggerF3View() }
                    FKeyButton { keyLabel: "F4"; actionLabel: qsTr("Edit"); onClicked: triggerF4Edit() }
                    FKeyButton { keyLabel: "F5"; actionLabel: qsTr("Copy"); onClicked: triggerF5Copy() }
                    FKeyButton { keyLabel: "F6"; actionLabel: qsTr("Move"); onClicked: triggerF6Move() }
                    FKeyButton { keyLabel: "F7"; actionLabel: qsTr("New Folder"); onClicked: triggerF7NewFolder() }
                    FKeyButton { keyLabel: "F8"; actionLabel: qsTr("Delete"); onClicked: triggerF8Delete() }
                    FKeyButton { keyLabel: "F9"; actionLabel: qsTr("Terminal"); onClicked: backend.openInTerminal(currentModel().path) }
                    FKeyButton { keyLabel: "F10"; actionLabel: qsTr("Exit"); onClicked: Qt.quit() }
                }
            }
        }
    }

    // ================= MODALS & DIALOGS =================

    // Consistent opaque themed dialog shell matching the app's surface palette.
    component AppDialog : Dialog {
        id: dlg
        property bool showCloseButton: true
        anchors.centerIn: parent
        modal: true
        padding: 16
        topPadding: 14
        bottomPadding: 14

        Overlay.modal: Rectangle {
            color: p.overlayDim
        }

        background: Rectangle {
            color: p.dialogBg
            border.width: 1
            border.color: p.borderDefault
            radius: Math.min(8, theme.radius)
        }

        header: Item {
            implicitHeight: 44

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 1
                anchors.rightMargin: 1
                height: 1
                color: p.borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: dlg.title
                    font.pixelSize: 14
                    font.bold: true
                    color: p.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                IconBtn {
                    visible: dlg.showCloseButton
                    iconKind: "close"
                    onClicked: dlg.reject()
                }
            }
        }

        Component {
            id: footerBgComponent
            Item {
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 1
                    anchors.rightMargin: 1
                    height: 1
                    color: p.borderSubtle
                }
            }
        }

        Component.onCompleted: {
            if (footer) {
                footer.background = footerBgComponent.createObject(footer);
            }
        }
    }

    Connections {
        target: backend
        function onConflictRequested(info) {
            conflictDialog.info = info;
            conflictApplyAll.checked = false;
            conflictDialog.open();
        }
        function onBusyChanged() {
            if (!backend.isBusy && conflictDialog.visible)
                conflictDialog.close();
        }
    }

    // File Exists (copy/move conflict) Dialog
    AppDialog {
        id: conflictDialog
        property var info: ({})
        title: qsTr("File already exists")
        showCloseButton: false
        closePolicy: Popup.NoAutoClose

        function answer(action) {
            backend.resolveConflict(action, conflictApplyAll.checked);
            close();
        }

        onOpened: conflictSkipButton.forceActiveFocus()
        onClosed: currentListView().forceActiveFocus()

        ColumnLayout {
            spacing: 10

            Text {
                text: qsTr("The destination already contains \"%1\".").arg(conflictDialog.info.name || "")
                color: p.textPrimary
                font.pixelSize: 13
                font.bold: true
                Layout.preferredWidth: 480
                wrapMode: Text.Wrap
            }

            GridLayout {
                columns: 2
                columnSpacing: 12
                rowSpacing: 4

                Text { text: qsTr("New:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: conflictDialog.info.sourcePath
                          ? backend.formatConflictDetails(conflictDialog.info.sourceSize,
                                                          conflictDialog.info.sourceModified,
                                                          conflictDialog.info.sourceIsDir)
                          : ""
                    color: p.textPrimary
                    font.pixelSize: 12
                }
                Text { text: qsTr("Existing:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: conflictDialog.info.destPath
                          ? backend.formatConflictDetails(conflictDialog.info.destSize,
                                                          conflictDialog.info.destModified,
                                                          conflictDialog.info.destIsDir)
                          : ""
                    color: p.textPrimary
                    font.pixelSize: 12
                }
                Text { text: qsTr("In:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: (conflictDialog.info.destPath || "").replace(/\/[^\/]*$/, "")
                    color: p.textSecondary
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                    Layout.preferredWidth: 400
                }
            }

            CheckBox {
                id: conflictApplyAll
                text: qsTr("Apply to all remaining conflicts")
            }
        }

        footer: DialogButtonBox {
            Button {
                text: qsTr("Overwrite")
                onClicked: conflictDialog.answer(1)
            }
            Button {
                id: conflictSkipButton
                text: qsTr("Skip")
                onClicked: conflictDialog.answer(2)
            }
            Button {
                text: qsTr("Rename")
                onClicked: conflictDialog.answer(3)
            }
            Button {
                text: qsTr("Cancel")
                flat: true
                onClicked: conflictDialog.answer(4)
            }
        }
    }

    // Confirm Copy Dialog
    AppDialog {
        id: copyDialog
        visible: win.confirmCopyOpen
        title: qsTr("Copy Files (F5)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Copy %1 item(s) to:").arg(getSelectedOrCurrentPaths().length)
                color: p.textSecondary
                font.pixelSize: 13
            }
            CompactField {
                id: copyDestField
                text: targetModel().path
                monospace: true
                Layout.preferredWidth: 440
                onAccepted: copyDialog.accept()
                onEscaped: copyDialog.reject()
            }
        }

        onAccepted: {
            win.confirmCopyOpen = false;
            backend.copyItems(getSelectedOrCurrentPaths(), copyDestField.text);
        }
        onRejected: win.confirmCopyOpen = false
    }

    // Confirm Move Dialog
    AppDialog {
        id: moveDialog
        visible: win.confirmMoveOpen
        title: qsTr("Move Files (F6)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Move %1 item(s) to:").arg(getSelectedOrCurrentPaths().length)
                color: p.textSecondary
                font.pixelSize: 13
            }
            CompactField {
                id: moveDestField
                text: targetModel().path
                monospace: true
                Layout.preferredWidth: 440
                onAccepted: moveDialog.accept()
                onEscaped: moveDialog.reject()
            }
        }

        onAccepted: {
            win.confirmMoveOpen = false;
            backend.moveItems(getSelectedOrCurrentPaths(), moveDestField.text);
        }
        onRejected: win.confirmMoveOpen = false
    }

    // Confirm Delete Dialog
    AppDialog {
        id: deleteDialog
        visible: win.confirmDeleteOpen
        title: qsTr("Delete Files (F8)")
        standardButtons: Dialog.Yes | Dialog.No

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Are you sure you want to delete %1 selected item(s)?").arg(getSelectedOrCurrentPaths().length)
                color: p.textSecondary
                font.pixelSize: 13
            }
            CheckBox {
                id: permDeleteCheck
                text: qsTr("Permanent delete (bypass trash)")
                checked: false
            }
        }

        onAccepted: {
            win.confirmDeleteOpen = false;
            backend.deleteItems(getSelectedOrCurrentPaths(), permDeleteCheck.checked);
        }
        onRejected: win.confirmDeleteOpen = false
    }

    // New Folder Dialog
    AppDialog {
        id: newFolderDialog
        visible: win.newFolderOpen
        title: qsTr("Create New Folder (F7)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 6
                Layout.preferredWidth: 380
                Text {
                    text: qsTr("In:")
                    color: p.textMuted
                    font.pixelSize: 12
                }
                Text {
                    text: currentModel().path
                    color: currentModel().isWritable ? p.accent : p.dangerAccent
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: !currentModel().isWritable
                Layout.preferredWidth: 380
                implicitHeight: 28
                radius: 4
                color: Qt.alpha(p.dangerAccent, 0.14)
                border.width: 1
                border.color: Qt.alpha(p.dangerAccent, 0.4)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text { text: "⚠"; color: p.dangerAccent; font.pixelSize: 13 }
                    Text {
                        text: qsTr("This folder is read-only (Permission denied)")
                        color: p.dangerText
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Text {
                text: qsTr("Folder name(s) (comma-separated for multiple):")
                color: p.textSecondary
                font.pixelSize: 13
            }
            CompactField {
                id: newFolderInput
                objectName: "newFolderInput"
                placeholderText: "folder1, folder2, folder3..."
                Layout.preferredWidth: 380
                onAccepted: newFolderDialog.accept()
                onEscaped: newFolderDialog.reject()
            }
            RowLayout {
                visible: newFolderInput.text.indexOf(',') !== -1
                spacing: 6
                Rectangle {
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: Qt.alpha(p.accent, 0.18)
                    border.width: 1
                    border.color: Qt.alpha(p.accent, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        font.pixelSize: 10
                        font.bold: true
                        color: p.accent
                    }
                }
                Text {
                    text: {
                        var count = newFolderInput.text.split(',').filter(function(s) { return s.trim().length > 0; }).length;
                        return qsTr("Will create %1 folders").arg(count);
                    }
                    font.pixelSize: 11
                    color: p.accent
                }
            }
        }

        onAccepted: {
            win.newFolderOpen = false;
            backend.createDirectory(newFolderInput.text);
        }
        onRejected: win.newFolderOpen = false
    }

    // Rename Dialog
    AppDialog {
        id: renameDialog
        visible: win.renameOpen
        title: qsTr("Rename (Shift+F6)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("New name for %1:").arg(win.renameOldName)
                color: p.textSecondary
                font.pixelSize: 13
            }
            CompactField {
                id: renameInput
                Layout.preferredWidth: 380
                onAccepted: renameDialog.accept()
                onEscaped: renameDialog.reject()
            }
        }

        onAccepted: {
            win.renameOpen = false;
            backend.renameItem(win.renameOldPath, renameInput.text);
        }
        onRejected: win.renameOpen = false
    }

    // Bookmarks Dialog (Ctrl+B)
    AppDialog {
        id: bookmarksDialog
        visible: win.bookmarksOpen
        title: qsTr("Bookmarks (Ctrl+B)")
        width: 520
        height: 380
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: qsTr("Active folder: %1").arg(currentModel().path)
                    color: p.textMuted
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }
                ToolbarBtn {
                    label: backend.isBookmarked(currentModel().path) ? qsTr("Remove Current") : qsTr("Add Current")
                    accentHighlight: true
                    onClicked: backend.toggleBookmark(currentModel().path)
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: backend.bookmarks

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 32
                    color: index % 2 === 0 ? p.rowAltBg : "transparent"
                    radius: win.smallRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            text: "★"
                            font.pixelSize: 12
                            color: p.accent
                        }

                        Text {
                            text: modelData
                            color: p.textSecondary
                            font.pixelSize: 12
                            font.family: "monospace"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    currentModel().setPath(modelData);
                                    win.bookmarksOpen = false;
                                    currentListView().forceActiveFocus();
                                }
                            }
                        }

                        IconBtn {
                            implicitWidth: 24
                            implicitHeight: 24
                            iconKind: "close"
                            tooltipText: qsTr("Remove bookmark")
                            onClicked: backend.toggleBookmark(modelData)
                        }
                    }
                }
            }
        }

        onRejected: win.bookmarksOpen = false
    }

    // Multi-Rename Tool Dialog (Ctrl+M) — RegEx, Dynamic Tags & Presets
    AppDialog {
        id: multiRenameDialog
        visible: win.multiRenameOpen
        title: qsTr("Multi-Rename Tool (Ctrl+M)")
        width: Math.min(820, win.width - 40)
        height: Math.min(620, win.height - 40)
        standardButtons: Dialog.Ok | Dialog.Cancel

        function applyPresetMap(preset) {
            if (!preset) return;
            mrMaskField.text = preset.nameMask !== undefined ? preset.nameMask : "[N]";
            mrFindField.text = preset.findText || "";
            mrReplaceField.text = preset.replaceText || "";
            mrPrefixField.text = preset.prefix || "";
            mrSuffixField.text = preset.suffix || "";
            mrCaseCombo.currentIndex = preset.caseMode !== undefined ? preset.caseMode : 0;
            mrCounterCheck.checked = !!preset.addCounter;
            mrRegexToggle.active = !!preset.useRegex;
            mrCounterStartField.text = preset.counterStart !== undefined ? String(preset.counterStart) : "1";
            mrCounterStepField.text = preset.counterStep !== undefined ? String(preset.counterStep) : "1";
            mrCounterDigitsField.text = preset.counterDigits !== undefined ? String(preset.counterDigits) : "3";
            refreshMultiRenamePreview();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // Preset Bar
            Rectangle {
                Layout.fillWidth: true
                height: 36
                color: p.subBarBg
                radius: win.smallRadius
                border.width: 1
                border.color: p.borderSubtle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text { text: qsTr("Preset:"); color: p.textMuted; font.pixelSize: 12 }
                    ComboBox {
                        id: mrPresetCombo
                        Layout.preferredWidth: 165
                        model: backend.multiRenamePresets
                        textRole: "name"
                        onActivated: function(idx) {
                            if (idx >= 0 && idx < backend.multiRenamePresets.length) {
                                var pr = backend.multiRenamePresets[idx];
                                mrPresetNameField.text = pr.name || "";
                                multiRenameDialog.applyPresetMap(pr);
                            }
                        }
                    }
                    CompactField {
                        id: mrPresetNameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Preset name...")
                    }
                    ToolbarBtn {
                        label: qsTr("Save Preset")
                        btnEnabled: mrPresetNameField.text.trim().length > 0
                        onClicked: {
                            var cStart = parseInt(mrCounterStartField.text, 10);
                            var cStep = parseInt(mrCounterStepField.text, 10);
                            var cDigits = parseInt(mrCounterDigitsField.text, 10);
                            backend.saveMultiRenamePreset(mrPresetNameField.text.trim(), {
                                nameMask: mrMaskField.text,
                                findText: mrFindField.text,
                                replaceText: mrReplaceField.text,
                                prefix: mrPrefixField.text,
                                suffix: mrSuffixField.text,
                                caseMode: mrCaseCombo.currentIndex,
                                addCounter: mrCounterCheck.checked,
                                useRegex: mrRegexToggle.active,
                                counterStart: isNaN(cStart) ? 1 : cStart,
                                counterStep: isNaN(cStep) ? 1 : cStep,
                                counterDigits: isNaN(cDigits) ? 3 : cDigits
                            });
                        }
                    }
                    ToolbarBtn {
                        label: qsTr("Delete")
                        btnEnabled: mrPresetCombo.currentIndex >= 0 && backend.multiRenamePresets.length > 0
                        onClicked: {
                            var targetName = mrPresetNameField.text.trim();
                            if (!targetName && mrPresetCombo.currentIndex >= 0 && mrPresetCombo.currentIndex < backend.multiRenamePresets.length)
                                targetName = backend.multiRenamePresets[mrPresetCombo.currentIndex].name || "";
                            if (targetName) {
                                backend.deleteMultiRenamePreset(targetName);
                                mrPresetNameField.text = "";
                            }
                        }
                    }
                }
            }

            // Dynamic Name Template Row + Quick Tag Chips
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: qsTr("Mask:"); color: p.textMuted; font.pixelSize: 12 }
                CompactField {
                    id: mrMaskField
                    monospace: true
                    text: "[N]"
                    Layout.fillWidth: true
                    placeholderText: "[N]_[Date]_[C]"
                    onTextChanged: refreshMultiRenamePreview()
                }
                Repeater {
                    model: ["[N]", "[Date]", "[Time]", "[ParentFolder]", "[Ext]", "[C]"]
                    delegate: FilterPill {
                        label: modelData
                        active: false
                        onClicked: insertRenameTag(modelData)
                    }
                }
            }

            GridLayout {
                columns: 5
                Layout.fillWidth: true
                columnSpacing: 8
                rowSpacing: 8

                Text { text: qsTr("Find:"); color: p.textMuted; font.pixelSize: 12 }
                CompactField {
                    id: mrFindField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Replace:"); color: p.textMuted; font.pixelSize: 12 }
                CompactField {
                    id: mrReplaceField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                FilterPill {
                    id: mrRegexToggle
                    label: "RegEx"
                    active: false
                    onClicked: {
                        active = !active;
                        refreshMultiRenamePreview();
                    }
                }

                Text { text: qsTr("Prefix:"); color: p.textMuted; font.pixelSize: 12 }
                CompactField {
                    id: mrPrefixField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Suffix:"); color: p.textMuted; font.pixelSize: 12 }
                CompactField {
                    id: mrSuffixField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Item { width: 1 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: qsTr("Case:"); color: p.textMuted; font.pixelSize: 12 }
                ComboBox {
                    id: mrCaseCombo
                    model: [qsTr("Unchanged"), qsTr("lowercase"), qsTr("UPPERCASE"), qsTr("Title Case")]
                    onCurrentIndexChanged: refreshMultiRenamePreview()
                }

                CheckBox {
                    id: mrCounterCheck
                    text: qsTr("Counter [C]")
                    onCheckedChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Start:"); color: p.textMuted; font.pixelSize: 11 }
                CompactField {
                    id: mrCounterStartField
                    monospace: true
                    text: "1"
                    Layout.preferredWidth: 48
                    onTextChanged: refreshMultiRenamePreview()
                }
                Text { text: qsTr("Step:"); color: p.textMuted; font.pixelSize: 11 }
                CompactField {
                    id: mrCounterStepField
                    monospace: true
                    text: "1"
                    Layout.preferredWidth: 48
                    onTextChanged: refreshMultiRenamePreview()
                }
                Text { text: qsTr("Digits:"); color: p.textMuted; font.pixelSize: 11 }
                CompactField {
                    id: mrCounterDigitsField
                    monospace: true
                    text: "3"
                    Layout.preferredWidth: 44
                    onTextChanged: refreshMultiRenamePreview()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 26
                color: p.tableHeaderBg
                radius: win.smallRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    Text { text: qsTr("Original Name"); font.bold: true; font.pixelSize: 11; color: p.textMuted; Layout.fillWidth: true }
                    Text { text: qsTr("New Name Preview"); font.bold: true; font.pixelSize: 11; color: p.accent; Layout.fillWidth: true }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.multiRenamePreviewList

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 26
                    color: index % 2 === 0 ? p.rowAltBg : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text {
                            text: modelData ? modelData.oldName : ""
                            color: p.textMuted
                            font.pixelSize: 12
                            font.family: "monospace"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                        Text {
                            text: modelData ? ("→  " + modelData.newName) : ""
                            color: p.accent
                            font.bold: true
                            font.pixelSize: 12
                            font.family: "monospace"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }
        }

        onAccepted: {
            win.multiRenameOpen = false;
            var cStart = parseInt(mrCounterStartField.text, 10);
            var cStep = parseInt(mrCounterStepField.text, 10);
            var cDigits = parseInt(mrCounterDigitsField.text, 10);
            backend.executeMultiRename(
                getSelectedOrCurrentPaths(),
                mrFindField.text,
                mrReplaceField.text,
                mrPrefixField.text,
                mrSuffixField.text,
                mrCaseCombo.currentIndex,
                mrCounterCheck.checked,
                mrRegexToggle.active,
                mrMaskField.text,
                isNaN(cStart) ? 1 : cStart,
                isNaN(cStep) ? 1 : cStep,
                isNaN(cDigits) ? 3 : cDigits
            );
        }
        onRejected: win.multiRenameOpen = false
    }

    // Pack Archive Dialog (Alt+F5)
    AppDialog {
        id: packDialog
        visible: win.packArchiveOpen
        title: qsTr("Pack Files into Archive (Alt+F5)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Create archive (.zip, .tar.gz, .tar.xz) from %1 item(s):").arg(getSelectedOrCurrentPaths().length)
                color: p.textSecondary
                font.pixelSize: 13
            }
            CompactField {
                id: packArchiveField
                monospace: true
                Layout.preferredWidth: 460
                onAccepted: packDialog.accept()
                onEscaped: packDialog.reject()
            }
        }

        onAccepted: {
            win.packArchiveOpen = false;
            backend.packArchive(getSelectedOrCurrentPaths(), packArchiveField.text);
        }
        onRejected: win.packArchiveOpen = false
    }

    // Command Output Modal
    AppDialog {
        id: cmdOutputDialog
        visible: win.commandOutputOpen
        title: qsTr("Command Output")
        width: 660
        height: 440
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent
            clip: true

            TextArea {
                text: win.commandOutputText
                readOnly: true
                font.family: "monospace"
                font.pixelSize: 12
                color: p.textSecondary
                background: Rectangle { color: p.inputBg; radius: win.smallRadius; border.width: 1; border.color: p.borderSubtle }
            }
        }

        onRejected: win.commandOutputOpen = false
    }

    // File Preview Modal (F3 Next-Gen View)
    AppDialog {
        id: previewDialog
        visible: win.previewOpen
        title: qsTr("Preview: %1").arg(previewData.name || "")
        width: Math.min(860, win.width - 40)
        height: Math.min(640, win.height - 40)
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: qsTr("Path: %1 | Size: %2 | Modified: %3").arg(previewData.path || "").arg(previewData.formattedSize || "").arg(previewData.modified || "")
                font.pixelSize: 11
                font.family: "monospace"
                color: p.textMuted
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }

            RichPreviewSurface {
                Layout.fillWidth: true
                Layout.fillHeight: true
                previewItem: win.previewData
                onRequestPage: function(page) {
                    if (win.previewData && win.previewData.path)
                        win.previewData = backend.getPreview(win.previewData.path, page);
                }
            }
        }

        onRejected: win.previewOpen = false
    }

    // Operation Queue & Transfer Monitor Dialog (Ctrl+Shift+Q)
    AppDialog {
        id: operationQueueDialog
        visible: win.queueDialogOpen
        title: qsTr("Operation Queue (Ctrl+Shift+Q)")
        width: Math.min(680, win.width - 40)
        height: Math.min(480, win.height - 40)
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Current Active Operation Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: activeOpCol.implicitHeight + 20
                color: p.cardBg
                radius: win.smallRadius
                border.width: 1
                border.color: backend.isBusy ? p.accent : p.borderSubtle

                ColumnLayout {
                    id: activeOpCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: backend.isBusy
                                  ? (backend.isPaused ? qsTr("PAUSED: %1").arg(backend.busyTitle) : backend.busyTitle)
                                  : qsTr("No transfer currently running")
                            font.bold: true
                            font.pixelSize: 12
                            color: backend.isPaused ? p.warningText : (backend.isBusy ? p.accent : p.textMuted)
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: backend.isBusy && (backend.busySpeed || "").length > 0
                            text: backend.busySpeed
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.accent
                        }
                        Text {
                            visible: backend.isBusy && (backend.busyEta || "").length > 0
                            text: qsTr("ETA %1").arg(backend.busyEta)
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textSecondary
                        }
                    }

                    Text {
                        visible: backend.isBusy
                        text: backend.busyDetail || ""
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textMuted
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }

                    Rectangle {
                        visible: backend.isBusy
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: p.borderDefault
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, backend.busyProgress))
                            height: parent.height
                            radius: 3
                            color: backend.isPaused ? p.warningText : p.accent
                        }
                    }

                    RowLayout {
                        visible: backend.isBusy
                        Layout.fillWidth: true
                        spacing: 8
                        Item { Layout.fillWidth: true }
                        ToolbarBtn {
                            label: backend.isPaused ? qsTr("Resume") : qsTr("Pause")
                            accentHighlight: backend.isPaused
                            onClicked: backend.togglePauseOperation()
                        }
                        ToolbarBtn {
                            label: qsTr("Cancel Current")
                            btnEnabled: backend.canCancel
                            onClicked: backend.cancelOperation()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: qsTr("Waiting in Queue (%1)").arg(backend.queueCount)
                    font.bold: true
                    font.pixelSize: 12
                    color: p.textSecondary
                    Layout.fillWidth: true
                }
                ToolbarBtn {
                    label: qsTr("Clear Queue")
                    btnEnabled: backend.queueCount > 0
                    onClicked: backend.clearOperationQueue()
                }
                ToolbarBtn {
                    label: qsTr("Cancel All")
                    btnEnabled: backend.isBusy || backend.queueCount > 0
                    onClicked: backend.cancelAllOperations()
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: backend.operationQueue

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 36
                    color: index % 2 === 0 ? p.rowAltBg : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            height: 18
                            width: qModeTxt.implicitWidth + 10
                            radius: 3
                            color: p.badgeBg
                            Text {
                                id: qModeTxt
                                anchors.centerIn: parent
                                text: modelData ? (modelData.mode === "move" ? "F6" : "F5") : ""
                                font.pixelSize: 10; font.bold: true; font.family: "monospace"; color: p.accent
                            }
                        }
                        Text {
                            text: modelData ? (modelData.title || "") : ""
                            font.pixelSize: 12
                            color: p.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                        ToolbarBtn {
                            implicitHeight: 22
                            label: qsTr("Remove")
                            onClicked: if (modelData) backend.removeQueuedOperation(modelData.id)
                        }
                    }
                }
            }
        }

        onRejected: win.queueDialogOpen = false
    }

    // Remote Connections Manager Dialog (SFTP / SMB / SSHFS via GVFS / sshfs)
    AppDialog {
        id: remoteConnectionsDialog
        visible: win.remoteConnectionsOpen
        title: qsTr("Remote Connections — SFTP / SMB / SSHFS (Ctrl+Shift+M)")
        width: Math.min(820, win.width - 40)
        height: Math.min(540, win.height - 40)
        standardButtons: Dialog.NoButton

        property string editingId: ""
        property string protocol: "sftp"

        function resetForm() {
            editingId = "";
            protocol = "sftp";
            if (!rcUriField) return;
            rcUriField.text = "";
            rcNameField.text = "";
            rcHostField.text = "";
            rcPortField.text = "22";
            rcUserField.text = "";
            rcPathField.text = "/";
            rcDomainField.text = "";
            rcHostField.forceFieldFocus();
        }

        function loadConnectionMap(m) {
            if (!m || !rcUriField) return;
            editingId = m.id || "";
            protocol = m.protocol || "sftp";
            rcUriField.text = m.uri || "";
            rcNameField.text = m.name || "";
            rcHostField.text = m.host || "";
            rcPortField.text = String(m.port || (protocol === "smb" ? 445 : 22));
            rcUserField.text = m.user || "";
            rcPathField.text = m.remotePath || (protocol === "smb" ? "/share" : "/");
            rcDomainField.text = m.domain || "";
        }

        function loadConnectionById(id) {
            var list = backend.remoteConnections;
            for (var i = 0; i < list.length; i++) {
                if (list[i].id === id) {
                    loadConnectionMap(list[i]);
                    return;
                }
            }
            resetForm();
        }

        function parseFromUriBar() {
            var parsed = backend.parseRemoteUri(rcUriField.text);
            if (!parsed || !parsed.host) {
                backend.showStatus(qsTr("Enter a valid URI like sftp://user@host/path or smb://server/share"));
                return;
            }
            protocol = parsed.protocol || "sftp";
            rcHostField.text = parsed.host || "";
            rcPortField.text = String(parsed.port || (protocol === "smb" ? 445 : 22));
            rcUserField.text = parsed.user || "";
            rcPathField.text = parsed.remotePath || "/";
            rcDomainField.text = parsed.domain || "";
            if (!rcNameField.text.trim())
                rcNameField.text = parsed.name || parsed.host;
        }

        function buildFormMap() {
            var portNum = parseInt(rcPortField.text, 10);
            if (isNaN(portNum) || portNum <= 0)
                portNum = (protocol === "smb") ? 445 : 22;
            return {
                id: editingId,
                name: rcNameField.text.trim(),
                protocol: protocol,
                host: rcHostField.text.trim(),
                port: portNum,
                user: rcUserField.text.trim(),
                remotePath: rcPathField.text.trim(),
                domain: rcDomainField.text.trim(),
                uri: rcUriField.text.trim()
            };
        }

        contentItem: RowLayout {
            spacing: 12

            // Saved Connections Sidebar
            ColumnLayout {
                Layout.preferredWidth: 255
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Saved Servers (%1)").arg(backend.remoteConnections.length)
                        font.bold: true
                        font.pixelSize: 12
                        color: p.textSecondary
                        Layout.fillWidth: true
                    }
                    ToolbarBtn {
                        implicitHeight: 24
                        label: "+ " + qsTr("New")
                        onClicked: remoteConnectionsDialog.resetForm()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: p.inputBg
                    radius: win.smallRadius
                    border.width: 1
                    border.color: p.borderSubtle

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 4
                        clip: true
                        spacing: 4
                        model: backend.remoteConnections

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 54
                            radius: win.smallRadius
                            readonly property bool isSel: modelData && modelData.id === remoteConnectionsDialog.editingId
                            color: isSel ? Qt.alpha(p.accent, win.isDark ? 0.2 : 0.12)
                                         : (rcItemMouse.containsMouse ? p.rowHoverBg : p.cardBg)
                            border.width: 1
                            border.color: isSel ? p.accent : p.borderSubtle

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: (modelData && modelData.isMounted) ? p.successText : p.textDisabled
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Rectangle {
                                            implicitHeight: 16
                                            implicitWidth: rcProtoLbl.implicitWidth + 8
                                            radius: 3
                                            color: p.badgeBg
                                            Text {
                                                id: rcProtoLbl
                                                anchors.centerIn: parent
                                                text: modelData ? (modelData.protocol || "sftp").toUpperCase() : ""
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: "monospace"
                                                color: p.accent
                                            }
                                        }
                                        Text {
                                            text: modelData ? (modelData.name || "") : ""
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: p.textPrimary
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Text {
                                        text: modelData ? (modelData.uri || "") : ""
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                        color: p.textDim
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                    }
                                }

                                ToolbarBtn {
                                    implicitHeight: 24
                                    label: (modelData && modelData.isMounted) ? qsTr("Open") : qsTr("Connect")
                                    onClicked: {
                                        if (modelData && backend.connectRemote(modelData.id).length > 0) {
                                            win.remoteConnectionsOpen = false;
                                            currentListView().forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rcItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (modelData) remoteConnectionsDialog.loadConnectionMap(modelData)
                                onDoubleClicked: {
                                    if (modelData && backend.connectRemote(modelData.id).length > 0) {
                                        win.remoteConnectionsOpen = false;
                                        currentListView().forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: backend.remoteConnections.length === 0
                        width: parent.width - 24
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("No saved servers yet.\nFill the form on the right to save SFTP, SMB, or SSHFS connections.")
                        font.pixelSize: 11
                        color: p.textDim
                    }
                }
            }

            // Connection Editor / Quick URI Connect
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Quick URI Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: qsTr("URI:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcUriField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: "sftp://user@server:22/var/www  |  smb://server/share"
                        onAccepted: remoteConnectionsDialog.parseFromUriBar()
                    }
                    ToolbarBtn {
                        label: qsTr("Parse")
                        onClicked: remoteConnectionsDialog.parseFromUriBar()
                    }
                }

                // Protocol Pills
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: qsTr("Protocol:"); color: p.textMuted; font.pixelSize: 12 }
                    FilterPill {
                        label: "SFTP / SSH (GVFS)"
                        active: remoteConnectionsDialog.protocol === "sftp"
                        onClicked: {
                            remoteConnectionsDialog.protocol = "sftp";
                            if (rcPortField.text === "445" || rcPortField.text === "")
                                rcPortField.text = "22";
                        }
                    }
                    FilterPill {
                        label: "SMB / Samba (GVFS)"
                        active: remoteConnectionsDialog.protocol === "smb"
                        onClicked: {
                            remoteConnectionsDialog.protocol = "smb";
                            if (rcPortField.text === "22" || rcPortField.text === "")
                                rcPortField.text = "445";
                        }
                    }
                    FilterPill {
                        label: "SSHFS (FUSE)"
                        active: remoteConnectionsDialog.protocol === "sshfs"
                        onClicked: {
                            remoteConnectionsDialog.protocol = "sshfs";
                            if (rcPortField.text === "445" || rcPortField.text === "")
                                rcPortField.text = "22";
                        }
                    }
                }

                GridLayout {
                    columns: 4
                    Layout.fillWidth: true
                    columnSpacing: 10
                    rowSpacing: 8

                    Text { text: qsTr("Name:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcNameField
                        Layout.fillWidth: true
                        Layout.columnSpan: 3
                        placeholderText: qsTr("Production Server / NAS Media")
                    }

                    Text { text: qsTr("Host / Server:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcHostField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: "192.168.1.50 / nas.local"
                    }

                    Text { text: qsTr("Port:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcPortField
                        monospace: true
                        text: "22"
                        Layout.preferredWidth: 82
                    }

                    Text { text: qsTr("Username:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcUserField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: qsTr("user (optional for guest SMB)")
                    }

                    Text { text: remoteConnectionsDialog.protocol === "smb" ? qsTr("Domain:") : qsTr("SSH Key:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcDomainField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: remoteConnectionsDialog.protocol === "smb" ? "WORKGROUP" : qsTr("~/.ssh/id_ed25519 (sshfs)")
                    }

                    Text { text: remoteConnectionsDialog.protocol === "smb" ? qsTr("Share / Path:") : qsTr("Remote Path:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcPathField
                        monospace: true
                        text: "/"
                        Layout.fillWidth: true
                        Layout.columnSpan: 3
                        placeholderText: remoteConnectionsDialog.protocol === "smb" ? "/share/folder" : "/var/www"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tipText.implicitHeight + 16
                    color: p.subBarBg
                    radius: win.smallRadius
                    border.width: 1
                    border.color: p.borderSubtle

                    Text {
                        id: tipText
                        anchors.fill: parent
                        anchors.margins: 8
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        color: p.textMuted
                        text: remoteConnectionsDialog.protocol === "sshfs"
                              ? qsTr("SSHFS mounts via FUSE under ~/.cache/omapanel/mounts/ using key authentication.")
                              : qsTr("GVFS mounts via 'gio mount' (uses SSH Agent / GNOME Keyring) and appears directly in your Drives bar.")
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ToolbarBtn {
                        label: qsTr("Delete")
                        btnEnabled: remoteConnectionsDialog.editingId.length > 0
                        onClicked: {
                            if (backend.deleteRemoteConnection(remoteConnectionsDialog.editingId))
                                remoteConnectionsDialog.resetForm();
                        }
                    }

                    ToolbarBtn {
                        label: qsTr("Save")
                        btnEnabled: rcHostField.text.trim().length > 0
                        onClicked: {
                            var form = remoteConnectionsDialog.buildFormMap();
                            if (backend.saveRemoteConnection(form))
                                rcUriField.text = backend.buildRemoteUri(form);
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ToolbarBtn {
                        label: qsTr("Close")
                        onClicked: remoteConnectionsDialog.reject()
                    }

                    ToolbarBtn {
                        label: qsTr("Save & Connect")
                        accentHighlight: true
                        btnEnabled: rcHostField.text.trim().length > 0 || rcUriField.text.trim().length > 0
                        onClicked: {
                            if (rcHostField.text.trim().length === 0 && rcUriField.text.trim().length > 0)
                                remoteConnectionsDialog.parseFromUriBar();
                            var form = remoteConnectionsDialog.buildFormMap();
                            if (form.host.length === 0) return;
                            backend.saveRemoteConnection(form);
                            var uri = backend.buildRemoteUri(form);
                            if (backend.connectRemote(uri).length > 0) {
                                win.remoteConnectionsOpen = false;
                                currentListView().forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.remoteConnectionsOpen = false
    }

    // Open With & Custom Actions Chooser Dialog (Ctrl+Shift+O)
    AppDialog {
        id: openWithDialog
        visible: win.openWithOpen
        title: qsTr("Open With & Custom Actions (Ctrl+Shift+O)")
        width: Math.min(820, win.width - 40)
        height: Math.min(580, win.height - 40)
        standardButtons: Dialog.NoButton

        property string editingActionId: ""
        property string appFilter: ""
        property bool showAllApps: false

        function resetFilters() {
            appFilter = "";
            showAllApps = false;
            editingActionId = "";
            if (!openWithAppSearchField) return;
            openWithAppSearchField.text = "";
            openWithCustomExecField.text = "";
            openWithSetDefaultCheck.checked = false;
            resetCustomActionForm();
        }

        function resetCustomActionForm() {
            editingActionId = "";
            if (!caNameField) return;
            caNameField.text = "";
            caCmdField.text = "";
            caPatternField.text = "*";
            caTerminalCheck.checked = false;
            caShowOutputCheck.checked = true;
        }

        function loadCustomAction(act) {
            if (!act || !caNameField) return;
            editingActionId = act.id || "";
            caNameField.text = act.name || "";
            caCmdField.text = act.command || "";
            caPatternField.text = act.pattern || "*";
            caTerminalCheck.checked = !!act.runInTerminal;
            caShowOutputCheck.checked = !!act.showOutput;
        }

        function filteredApplications() {
            var source = showAllApps ? win.openWithAllApps : win.openWithAppsList;
            if (!source) return [];
            var q = appFilter.trim().toLowerCase();
            if (!q) return source;
            var out = [];
            for (var i = 0; i < source.length; i++) {
                var a = source[i];
                var hay = ((a.name || "") + " " + (a.genericName || "") + " " + (a.exec || "") + " " + (a.desktopId || "")).toLowerCase();
                if (hay.indexOf(q) >= 0)
                    out.push(a);
            }
            return out;
        }

        contentItem: ColumnLayout {
            spacing: 10

            // Target File & MIME Header Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: owHeaderRow.implicitHeight + 16
                color: p.cardBg
                radius: win.smallRadius
                border.width: 1
                border.color: p.borderSubtle

                RowLayout {
                    id: owHeaderRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: win.openWithTargetPath ? backend.fileName(win.openWithTargetPath) : ""
                            font.bold: true
                            font.pixelSize: 13
                            color: p.textPrimary
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                        Text {
                            text: (win.openWithTargetPath || "") + ((win.openWithMimeInfo && win.openWithMimeInfo.comment) ? ("  •  " + win.openWithMimeInfo.comment) : "")
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: p.textDim
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        height: 22
                        width: owMimeTxt.implicitWidth + 14
                        radius: 4
                        color: p.badgeBg
                        border.width: 1
                        border.color: p.borderDefault
                        Text {
                            id: owMimeTxt
                            anchors.centerIn: parent
                            text: (win.openWithMimeInfo && win.openWithMimeInfo.mimeType) ? win.openWithMimeInfo.mimeType : "unknown"
                            font.pixelSize: 11
                            font.family: "monospace"
                            font.bold: true
                            color: p.accent
                        }
                    }
                }
            }

            // Tab Strip: Open With vs Custom Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FilterPill {
                    label: qsTr("Applications (%1)").arg(win.openWithAppsList ? win.openWithAppsList.length : 0)
                    active: win.openWithTab === 0
                    onClicked: win.openWithTab = 0
                }
                FilterPill {
                    label: qsTr("Custom Actions (%1)").arg(backend.customActions.length)
                    active: win.openWithTab === 1
                    onClicked: win.openWithTab = 1
                }
                Item { Layout.fillWidth: true }
            }

            // TAB 0: XDG Desktop Applications Chooser
            ColumnLayout {
                visible: win.openWithTab === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    CompactField {
                        id: openWithAppSearchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Filter installed applications...")
                        onTextChanged: openWithDialog.appFilter = text
                    }
                    FilterPill {
                        label: qsTr("Compatible Only")
                        active: !openWithDialog.showAllApps
                        onClicked: openWithDialog.showAllApps = false
                    }
                    FilterPill {
                        label: qsTr("All Installed")
                        active: openWithDialog.showAllApps
                        onClicked: {
                            if (!win.openWithAllApps || win.openWithAllApps.length === 0)
                                win.openWithAllApps = backend.getAllInstalledApplications();
                            openWithDialog.showAllApps = true;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: p.inputBg
                    radius: win.smallRadius
                    border.width: 1
                    border.color: p.borderSubtle

                    ListView {
                        id: owAppsListView
                        anchors.fill: parent
                        anchors.margins: 4
                        clip: true
                        spacing: 3
                        model: openWithDialog.filteredApplications()

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 46
                            radius: win.smallRadius
                            color: owRowMouse.containsMouse ? p.rowHoverBg : (index % 2 === 0 ? p.rowAltBg : "transparent")
                            border.width: (modelData && modelData.isDefault) ? 1 : 0
                            border.color: Qt.alpha(p.accent, 0.5)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        spacing: 6
                                        Text {
                                            text: modelData ? (modelData.name || "") : ""
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: p.textPrimary
                                        }
                                        Rectangle {
                                            visible: !!(modelData && modelData.isDefault)
                                            implicitHeight: 16
                                            implicitWidth: defLbl.implicitWidth + 8
                                            radius: 3
                                            color: Qt.alpha(p.accent, 0.18)
                                            Text {
                                                id: defLbl
                                                anchors.centerIn: parent
                                                text: qsTr("Default")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: p.accent
                                            }
                                        }
                                        Text {
                                            visible: !!(modelData && modelData.genericName)
                                            text: modelData ? ("· " + modelData.genericName) : ""
                                            font.pixelSize: 11
                                            color: p.textDim
                                        }
                                    }
                                    Text {
                                        text: modelData ? ((modelData.desktopId || "") + " — " + (modelData.exec || "")) : ""
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                        color: p.textDim
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                ToolbarBtn {
                                    implicitHeight: 24
                                    label: qsTr("Set Default")
                                    btnEnabled: !!(modelData && !modelData.isDefault && win.openWithMimeInfo && win.openWithMimeInfo.mimeType)
                                    onClicked: {
                                        if (modelData && win.openWithMimeInfo && win.openWithMimeInfo.mimeType) {
                                            backend.setDefaultApplicationForMime(win.openWithMimeInfo.mimeType, modelData.desktopId);
                                            win.openWithMimeInfo = backend.getFileMimeInfo(win.openWithTargetPath);
                                            win.openWithAppsList = backend.getApplicationsForFile(win.openWithTargetPath);
                                        }
                                    }
                                }

                                ToolbarBtn {
                                    implicitHeight: 24
                                    accentHighlight: true
                                    label: qsTr("Open")
                                    onClicked: {
                                        var paths = win.getSelectedOrCurrentPaths();
                                        if (paths.length === 0 && win.openWithTargetPath)
                                            paths = [win.openWithTargetPath];
                                        backend.openWithApplication(paths, modelData.desktopId, openWithSetDefaultCheck.checked);
                                        win.openWithOpen = false;
                                        currentListView().forceActiveFocus();
                                    }
                                }
                            }

                            MouseArea {
                                id: owRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onDoubleClicked: {
                                    var paths = win.getSelectedOrCurrentPaths();
                                    if (paths.length === 0 && win.openWithTargetPath)
                                        paths = [win.openWithTargetPath];
                                    backend.openWithApplication(paths, modelData.desktopId, openWithSetDefaultCheck.checked);
                                    win.openWithOpen = false;
                                    currentListView().forceActiveFocus();
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: owAppsListView.count === 0
                        text: openWithDialog.showAllApps ? qsTr("No matching applications found.") : qsTr("No MIME-specific apps matched. Switch to 'All Installed' or enter a custom command below.")
                        font.pixelSize: 12
                        color: p.textDim
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    CheckBox {
                        id: openWithSetDefaultCheck
                        text: qsTr("Set selected application as default for %1").arg((win.openWithMimeInfo && win.openWithMimeInfo.mimeType) ? win.openWithMimeInfo.mimeType : qsTr("this type"))
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: qsTr("Custom Command:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: openWithCustomExecField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: "e.g. code %f  |  mpv %F  |  gimp %f"
                        onAccepted: {
                            var cmd = text.trim();
                            if (cmd.length > 0) {
                                var paths = win.getSelectedOrCurrentPaths();
                                if (paths.length === 0 && win.openWithTargetPath)
                                    paths = [win.openWithTargetPath];
                                backend.openWithApplication(paths, cmd, false);
                                win.openWithOpen = false;
                                currentListView().forceActiveFocus();
                            }
                        }
                    }
                    ToolbarBtn {
                        label: qsTr("Launch")
                        btnEnabled: openWithCustomExecField.text.trim().length > 0
                        onClicked: {
                            var paths = win.getSelectedOrCurrentPaths();
                            if (paths.length === 0 && win.openWithTargetPath)
                                paths = [win.openWithTargetPath];
                            backend.openWithApplication(paths, openWithCustomExecField.text.trim(), false);
                            win.openWithOpen = false;
                            currentListView().forceActiveFocus();
                        }
                    }
                    ToolbarBtn {
                        label: qsTr("Close")
                        onClicked: openWithDialog.reject()
                    }
                }
            }

            // TAB 1: Saved Custom Actions Manager
            RowLayout {
                visible: win.openWithTab === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Left list of Custom Actions
                ColumnLayout {
                    Layout.preferredWidth: 270
                    Layout.fillHeight: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Saved Custom Actions")
                            font.bold: true
                            font.pixelSize: 12
                            color: p.textSecondary
                            Layout.fillWidth: true
                        }
                        ToolbarBtn {
                            implicitHeight: 24
                            label: "+ " + qsTr("New")
                            onClicked: openWithDialog.resetCustomActionForm()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: p.inputBg
                        radius: win.smallRadius
                        border.width: 1
                        border.color: p.borderSubtle

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true
                            spacing: 3
                            model: backend.customActions

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 50
                                radius: win.smallRadius
                                readonly property bool isSel: modelData && modelData.id === openWithDialog.editingActionId
                                color: isSel ? Qt.alpha(p.accent, win.isDark ? 0.2 : 0.12)
                                             : (caRowMouse.containsMouse ? p.rowHoverBg : p.cardBg)
                                border.width: 1
                                border.color: isSel ? p.accent : p.borderSubtle

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: modelData ? (modelData.name || "") : ""
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: p.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData ? ((modelData.pattern || "*") + "  ·  " + (modelData.command || "")) : ""
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            color: p.textDim
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    ToolbarBtn {
                                        implicitHeight: 24
                                        accentHighlight: true
                                        label: qsTr("Run")
                                        onClicked: {
                                            if (modelData) {
                                                win.runCustomActionAndShow(modelData.id, win.openWithTargetPath);
                                                win.openWithOpen = false;
                                                currentListView().forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: caRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (modelData) openWithDialog.loadCustomAction(modelData)
                                }
                            }
                        }
                    }
                }

                // Right Custom Action Editor
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Text { text: qsTr("Action Name:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: caNameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Compress PNG / Convert to WebP / Git Blame...")
                    }

                    Text { text: qsTr("Shell Command:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: caCmdField
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: "e.g. magick %f %b.webp  |  wc -l %F"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: qsTr("Insert:"); color: p.textDim; font.pixelSize: 11 }
                        Repeater {
                            model: ["%f", "%F", "%d", "%n", "%b", "%e"]
                            delegate: FilterPill {
                                label: modelData
                                active: false
                                onClicked: caCmdField.text = caCmdField.text + (caCmdField.text.length > 0 && !caCmdField.text.endsWith(" ") ? " " : "") + modelData
                            }
                        }
                    }

                    Text { text: qsTr("File / MIME Pattern (* = all, e.g. *.sh;*.py or image/*):"); color: p.textMuted; font.pixelSize: 11 }
                    CompactField {
                        id: caPatternField
                        monospace: true
                        text: "*"
                        Layout.fillWidth: true
                        placeholderText: "*  |  *.png;*.jpg  |  inode/directory  |  text/*"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        CheckBox {
                            id: caTerminalCheck
                            text: qsTr("Run in Terminal")
                        }
                        CheckBox {
                            id: caShowOutputCheck
                            checked: true
                            text: qsTr("Show Output Window")
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ToolbarBtn {
                            label: qsTr("Delete")
                            btnEnabled: openWithDialog.editingActionId.length > 0
                            onClicked: {
                                if (backend.deleteCustomAction(openWithDialog.editingActionId))
                                    openWithDialog.resetCustomActionForm();
                            }
                        }

                        ToolbarBtn {
                            label: qsTr("Save Action")
                            btnEnabled: caNameField.text.trim().length > 0 && caCmdField.text.trim().length > 0
                            onClicked: {
                                backend.saveCustomAction({
                                    id: openWithDialog.editingActionId,
                                    name: caNameField.text.trim(),
                                    command: caCmdField.text.trim(),
                                    pattern: caPatternField.text.trim(),
                                    runInTerminal: caTerminalCheck.checked,
                                    showOutput: caShowOutputCheck.checked
                                });
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToolbarBtn {
                            label: qsTr("Close")
                            onClicked: openWithDialog.reject()
                        }

                        ToolbarBtn {
                            label: qsTr("Save & Run")
                            accentHighlight: true
                            btnEnabled: caNameField.text.trim().length > 0 && caCmdField.text.trim().length > 0
                            onClicked: {
                                var actObj = {
                                    id: openWithDialog.editingActionId,
                                    name: caNameField.text.trim(),
                                    command: caCmdField.text.trim(),
                                    pattern: caPatternField.text.trim(),
                                    runInTerminal: caTerminalCheck.checked,
                                    showOutput: caShowOutputCheck.checked
                                };
                                backend.saveCustomAction(actObj);
                                win.runCustomActionAndShow(caNameField.text.trim(), win.openWithTargetPath);
                                win.openWithOpen = false;
                                currentListView().forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.openWithOpen = false
    }

    // Alt+F7 Asynchronous Advanced Search Dialog
    AppDialog {
        id: searchDialog
        visible: win.searchOpen
        title: qsTr("Advanced Search (Alt+F7)")
        width: Math.min(820, win.width - 40)
        height: Math.min(620, win.height - 40)
        standardButtons: Dialog.NoButton

        property string typeFilter: "all"
        property var minSizeBytes: 0
        property int modifiedWithinDays: 0
        property bool useRegex: false
        property bool caseSensitive: false
        property bool includeHidden: true

        function startSearch() {
            backend.startAdvancedSearch(currentModel().path, {
                nameQuery: searchInput.text,
                contentQuery: searchContentInput.text,
                caseSensitive: caseSensitive,
                useRegex: useRegex,
                includeHidden: includeHidden,
                typeFilter: typeFilter,
                minSizeBytes: minSizeBytes,
                modifiedWithinDays: modifiedWithinDays,
                maxResults: 2000
            });
        }

        function feedResults(newTab) {
            var items = backend.searchResultItems;
            if (!items || items.length === 0)
                return;
            var paths = [];
            for (var i = 0; i < items.length; i++) {
                if (items[i] && items[i].path)
                    paths.push(items[i].path);
            }
            if (paths.length === 0)
                return;
            var label = searchInput.text.trim();
            if (label.length === 0)
                label = searchContentInput.text.trim();
            if (label.length === 0)
                label = "*";
            backend.feedPathsToPanel(paths, qsTr("Search: %1").arg(label), newTab);
            win.searchOpen = false;
            currentListView().forceActiveFocus();
        }

        onRejected: {
            if (backend.searchRunning)
                backend.cancelSearch();
            win.searchOpen = false;
            currentListView().forceActiveFocus();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: qsTr("Name:")
                    font.pixelSize: 12
                    color: p.textSecondary
                    Layout.preferredWidth: 58
                }
                CompactField {
                    id: searchInput
                    placeholderText: qsTr("File name, wildcard (*.cpp), or RegEx (empty = all)...")
                    Layout.fillWidth: true
                    onAccepted: searchDialog.startSearch()
                    onEscaped: searchDialog.reject()
                }
                ToolbarBtn {
                    implicitHeight: 32
                    label: backend.searchRunning ? qsTr("Stop") : qsTr("Search")
                    accentHighlight: true
                    onClicked: {
                        if (backend.searchRunning)
                            backend.cancelSearch();
                        else
                            searchDialog.startSearch();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: qsTr("Content:")
                    font.pixelSize: 12
                    color: p.textSecondary
                    Layout.preferredWidth: 58
                }
                CompactField {
                    id: searchContentInput
                    placeholderText: qsTr("Contains text or RegEx inside files (optional)...")
                    Layout.fillWidth: true
                    onAccepted: searchDialog.startSearch()
                    onEscaped: searchDialog.reject()
                }
                FilterPill {
                    label: ".*"
                    active: searchDialog.useRegex
                    onClicked: searchDialog.useRegex = !searchDialog.useRegex
                }
                FilterPill {
                    label: "Aa"
                    active: searchDialog.caseSensitive
                    onClicked: searchDialog.caseSensitive = !searchDialog.caseSensitive
                }
                FilterPill {
                    label: qsTr("Hidden")
                    active: searchDialog.includeHidden
                    onClicked: searchDialog.includeHidden = !searchDialog.includeHidden
                }
            }

            // Filter Bar (Type / Min Size / Modified Date)
            Flow {
                Layout.fillWidth: true
                spacing: 6

                Text { text: qsTr("Type:"); font.pixelSize: 11; color: p.textDim; height: 24; verticalAlignment: Text.AlignVCenter }
                FilterPill { label: qsTr("All"); active: searchDialog.typeFilter === "all"; onClicked: searchDialog.typeFilter = "all" }
                FilterPill { label: qsTr("Files"); active: searchDialog.typeFilter === "files"; onClicked: searchDialog.typeFilter = "files" }
                FilterPill { label: qsTr("Folders"); active: searchDialog.typeFilter === "dirs"; onClicked: searchDialog.typeFilter = "dirs" }

                Item { width: 8; height: 24 }

                Text { text: qsTr("Min Size:"); font.pixelSize: 11; color: p.textDim; height: 24; verticalAlignment: Text.AlignVCenter }
                FilterPill { label: qsTr("Any"); active: searchDialog.minSizeBytes === 0; onClicked: searchDialog.minSizeBytes = 0 }
                FilterPill { label: "> 1 MB"; active: searchDialog.minSizeBytes === 1048576; onClicked: searchDialog.minSizeBytes = 1048576 }
                FilterPill { label: "> 10 MB"; active: searchDialog.minSizeBytes === 10485760; onClicked: searchDialog.minSizeBytes = 10485760 }
                FilterPill { label: "> 100 MB"; active: searchDialog.minSizeBytes === 104857600; onClicked: searchDialog.minSizeBytes = 104857600 }

                Item { width: 8; height: 24 }

                Text { text: qsTr("Modified:"); font.pixelSize: 11; color: p.textDim; height: 24; verticalAlignment: Text.AlignVCenter }
                FilterPill { label: qsTr("Any"); active: searchDialog.modifiedWithinDays === 0; onClicked: searchDialog.modifiedWithinDays = 0 }
                FilterPill { label: qsTr("24h"); active: searchDialog.modifiedWithinDays === 1; onClicked: searchDialog.modifiedWithinDays = 1 }
                FilterPill { label: qsTr("7d"); active: searchDialog.modifiedWithinDays === 7; onClicked: searchDialog.modifiedWithinDays = 7 }
                FilterPill { label: qsTr("30d"); active: searchDialog.modifiedWithinDays === 30; onClicked: searchDialog.modifiedWithinDays = 30 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: backend.searchRunning
                          ? qsTr("Scanning (%1 items)... %2 match(es) in %3")
                                .arg(backend.searchScannedCount)
                                .arg(backend.searchResultItems.length)
                                .arg(currentModel().path)
                          : qsTr("%1 result(s) across %2 item(s) in %3")
                                .arg(backend.searchResultItems.length)
                                .arg(backend.searchScannedCount)
                                .arg(currentModel().path)
                    font.pixelSize: 11
                    color: backend.searchRunning ? p.accent : p.textMuted
                    elide: Text.ElideMiddle
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderSubtle
                clip: true

                ListView {
                    id: searchResultsView
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: backend.searchResultItems

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: srRow
                        width: ListView.view.width
                        readonly property int lineNum: modelData ? (modelData.matchLine || 0) : 0
                        height: lineNum > 0 ? 44 : 28
                        color: srMouse.containsMouse ? p.rowHoverBg : (index % 2 === 0 ? p.rowAltBg : "transparent")
                        radius: win.smallRadius

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 3
                            anchors.bottomMargin: 3
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                VectorIcon {
                                    kind: (modelData && modelData.isDir) ? "folder" : "file"
                                    iconColor: (modelData && modelData.isDir) ? p.accent : p.textMuted
                                }

                                Text {
                                    text: modelData ? (modelData.relPath || modelData.path || "") : ""
                                    color: p.textPrimary
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    text: modelData ? (modelData.formattedSize || "") : ""
                                    color: p.textDim
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                }

                                Text {
                                    text: modelData ? (modelData.modified || "") : ""
                                    color: p.textDim
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                }

                                ToolbarBtn {
                                    implicitHeight: 22
                                    label: qsTr("Open")
                                    accentHighlight: true
                                    onClicked: {
                                        if (modelData && modelData.path) {
                                            backend.openItem(modelData.path);
                                            win.searchOpen = false;
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: srRow.lineNum > 0
                                Layout.fillWidth: true
                                Layout.leftMargin: 24
                                text: srRow.lineNum > 0
                                      ? (qsTr("Line %1: ").arg(srRow.lineNum) + (modelData ? (modelData.matchPreview || "") : ""))
                                      : ""
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: p.accent
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: srMouse
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                            onDoubleClicked: {
                                if (modelData && modelData.path) {
                                    backend.openItem(modelData.path);
                                    win.searchOpen = false;
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToolbarBtn {
                    label: qsTr("Feed to Panel")
                    accentHighlight: true
                    btnEnabled: backend.searchResultItems.length > 0
                    onClicked: searchDialog.feedResults(false)
                }

                ToolbarBtn {
                    label: qsTr("Feed to New Tab")
                    btnEnabled: backend.searchResultItems.length > 0
                    onClicked: searchDialog.feedResults(true)
                }

                Item { Layout.fillWidth: true }

                ToolbarBtn {
                    label: qsTr("Close")
                    onClicked: searchDialog.reject()
                }
            }
        }
    }

    // Item Properties & Permissions Dialog (Alt+Enter)
    AppDialog {
        id: propertiesDialog
        visible: win.propertiesOpen
        title: qsTr("Properties — %1").arg(win.propData.name || "")
        width: 540

        onClosed: currentListView().forceActiveFocus()
        onRejected: win.propertiesOpen = false

        ColumnLayout {
            width: parent.width
            spacing: 12

            // Summary Header Card
            Rectangle {
                Layout.fillWidth: true
                height: 54
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderDefault

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    VectorIcon {
                        width: 20
                        height: 20
                        kind: win.propData.isDir ? "folder" : "file"
                        iconColor: win.propData.isDir ? p.iconFolder : p.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: win.propData.name || ""
                                font.pixelSize: 13
                                font.bold: true
                                color: p.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            Rectangle {
                                visible: win.propData.isSymLink === true || win.propData.isDir === true
                                implicitHeight: 18
                                implicitWidth: kindTag.implicitWidth + 10
                                radius: Math.min(3, theme.radius)
                                color: Qt.alpha(p.accent, 0.16)

                                Text {
                                    id: kindTag
                                    anchors.centerIn: parent
                                    text: win.propData.isSymLink ? qsTr("SYMLINK") : qsTr("FOLDER")
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: "monospace"
                                    color: p.accent
                                }
                            }
                        }

                        Text {
                            text: win.propData.path || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textMuted
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // Metadata Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 14
                rowSpacing: 6

                Text { text: qsTr("MIME Type:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: (win.propData.mimeComment || "")
                          + ((win.propData.mimeName || "").length > 0 ? "  (" + win.propData.mimeName + ")" : "")
                    color: p.textPrimary
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: win.propData.isSymLink === true
                    text: qsTr("Link Target:")
                    color: p.textMuted
                    font.pixelSize: 12
                }
                Text {
                    visible: win.propData.isSymLink === true
                    text: win.propData.symLinkTarget || ""
                    color: p.accent
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                Text { text: qsTr("Size:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: (win.propData.formattedSize || "")
                          + ((win.propData.itemCounts || "").length > 0 ? "  —  " + win.propData.itemCounts : "")
                    color: p.textPrimary
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text { text: qsTr("Owner / Group:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: (win.propData.owner || "") + " : " + (win.propData.group || "")
                    color: p.textPrimary
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text { text: qsTr("Modified:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: win.propData.modified || "—"
                    color: p.textSecondary
                    font.pixelSize: 12
                    font.family: "monospace"
                }

                Text { text: qsTr("Created:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: win.propData.created || "—"
                    color: p.textSecondary
                    font.pixelSize: 12
                    font.family: "monospace"
                }

                Text { text: qsTr("Accessed:"); color: p.textMuted; font.pixelSize: 12 }
                Text {
                    text: win.propData.accessed || "—"
                    color: p.textSecondary
                    font.pixelSize: 12
                    font.family: "monospace"
                }
            }

            // Editable Permissions (chmod) Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: chmodCol.implicitHeight + 22
                radius: win.smallRadius
                color: p.cardAltBg
                border.width: 1
                border.color: p.borderDefault

                ColumnLayout {
                    id: chmodCol
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: qsTr("Permissions (chmod)")
                            font.pixelSize: 12
                            font.bold: true
                            color: p.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitHeight: 24
                            implicitWidth: symLabel.implicitWidth + 14
                            radius: win.smallRadius
                            color: p.chipBg
                            border.width: 1
                            border.color: p.borderDefault

                            Text {
                                id: symLabel
                                anchors.centerIn: parent
                                text: backend.formatSymbolicPermissions(win.propMode)
                                font.pixelSize: 12
                                font.family: "monospace"
                                font.bold: true
                                color: p.accent
                            }
                        }

                        Text {
                            text: qsTr("Octal:")
                            font.pixelSize: 11
                            color: p.textMuted
                        }

                        CompactField {
                            id: propOctalField
                            Layout.preferredWidth: 68
                            Layout.preferredHeight: 26
                            monospace: true
                            placeholderText: "0755"
                            onTextChanged: {
                                if (win.propSyncingOctal)
                                    return;
                                var t = propOctalField.text.trim();
                                if (/^[0-7]{3,4}$/.test(t))
                                    win.propMode = parseInt(t, 8) & 0x1ff;
                            }
                            onAccepted: propertiesDialog.applyPermissions()
                            onEscaped: propertiesDialog.reject()
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 6
                        rowSpacing: 6
                        opacity: win.propData.isSymLink ? 0.45 : 1.0

                        Text { text: qsTr("Owner"); color: p.textSecondary; font.pixelSize: 12; Layout.preferredWidth: 70 }
                        PermBitBtn { label: qsTr("Read (r)"); bitMask: 256 }
                        PermBitBtn { label: qsTr("Write (w)"); bitMask: 128 }
                        PermBitBtn { label: qsTr("Exec (x)"); bitMask: 64 }

                        Text { text: qsTr("Group"); color: p.textSecondary; font.pixelSize: 12; Layout.preferredWidth: 70 }
                        PermBitBtn { label: qsTr("Read (r)"); bitMask: 32 }
                        PermBitBtn { label: qsTr("Write (w)"); bitMask: 16 }
                        PermBitBtn { label: qsTr("Exec (x)"); bitMask: 8 }

                        Text { text: qsTr("Others"); color: p.textSecondary; font.pixelSize: 12; Layout.preferredWidth: 70 }
                        PermBitBtn { label: qsTr("Read (r)"); bitMask: 4 }
                        PermBitBtn { label: qsTr("Write (w)"); bitMask: 2 }
                        PermBitBtn { label: qsTr("Exec (x)"); bitMask: 1 }
                    }

                    CheckBox {
                        id: propRecursiveCheck
                        visible: win.propData.isDir === true && win.propData.isSymLink !== true
                        implicitHeight: 28
                        text: qsTr("Apply permissions recursively to folder contents")
                    }
                }
            }
        }

        function applyPermissions() {
            backend.setItemPermissions(win.propData.path, win.propMode, propRecursiveCheck.checked);
            win.propertiesOpen = false;
        }

        footer: DialogButtonBox {
            Button {
                text: qsTr("Apply Permissions")
                enabled: win.propData.isSymLink !== true
                onClicked: propertiesDialog.applyPermissions()
            }
            Button {
                text: qsTr("Close")
                flat: true
                onClicked: propertiesDialog.reject()
            }
        }
    }

    // Shift+F4 New File Dialog
    AppDialog {
        id: newFileDialog
        visible: win.newFileOpen
        title: qsTr("New File (Shift+F4)")
        width: 440
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                spacing: 6
                Layout.fillWidth: true
                Text {
                    text: qsTr("In:")
                    color: p.textMuted
                    font.pixelSize: 12
                }
                Text {
                    text: currentModel().path
                    color: currentModel().isWritable ? p.accent : p.dangerAccent
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: !currentModel().isWritable
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 4
                color: Qt.alpha(p.dangerAccent, 0.14)
                border.width: 1
                border.color: Qt.alpha(p.dangerAccent, 0.4)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text { text: "⚠"; color: p.dangerAccent; font.pixelSize: 13 }
                    Text {
                        text: qsTr("This folder is read-only (Permission denied)")
                        color: p.dangerText
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Text {
                text: qsTr("Enter file name(s) (comma-separated for multiple):")
                color: p.textSecondary
                font.pixelSize: 12
            }

            CompactField {
                id: newFileNameInput
                objectName: "newFileNameInput"
                Layout.fillWidth: true
                placeholderText: "file1.txt, file2.txt, notes.md..."
                text: "new_file.txt"
                onAccepted: newFileDialog.accept()
                onEscaped: newFileDialog.reject()
            }

            RowLayout {
                visible: newFileNameInput.text.indexOf(',') !== -1
                spacing: 6
                Rectangle {
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: Qt.alpha(p.accent, 0.18)
                    border.width: 1
                    border.color: Qt.alpha(p.accent, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        font.pixelSize: 10
                        font.bold: true
                        color: p.accent
                    }
                }
                Text {
                    text: {
                        var count = newFileNameInput.text.split(',').filter(function(s) { return s.trim().length > 0; }).length;
                        return qsTr("Will create %1 files").arg(count);
                    }
                    font.pixelSize: 11
                    color: p.accent
                }
            }
        }

        onAccepted: {
            win.newFileOpen = false;
            var name = newFileNameInput.text.trim();
            if (name.length > 0) {
                backend.createNewFile(name);
                currentModel().refresh();
            }
        }
        onRejected: win.newFileOpen = false
    }

    // Ctrl+Shift+F5 Create Symlink Dialog
    AppDialog {
        id: symlinkDialog
        visible: win.symlinkOpen
        title: qsTr("Create Symbolic Link (Ctrl+Shift+F5)")
        width: 480
        standardButtons: Dialog.Ok | Dialog.Cancel

        property var paths: []

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: symlinkDialog.paths.length === 1
                      ? qsTr("Create symlink for: %1").arg(backend.fileName(symlinkDialog.paths[0]))
                      : qsTr("Create %1 symlinks in target folder").arg(symlinkDialog.paths.length)
                color: p.textPrimary
                font.bold: true
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }

            Text {
                text: qsTr("Destination directory:")
                color: p.textMuted
                font.pixelSize: 11
            }

            CompactField {
                id: symlinkTargetDirInput
                Layout.fillWidth: true
                text: targetModel().path
                onAccepted: symlinkDialog.accept()
                onEscaped: symlinkDialog.reject()
            }

            Text {
                visible: symlinkDialog.paths.length === 1
                text: qsTr("Link name:")
                color: p.textMuted
                font.pixelSize: 11
            }

            CompactField {
                id: symlinkNameInput
                visible: symlinkDialog.paths.length === 1
                Layout.fillWidth: true
                text: symlinkDialog.paths.length === 1 ? backend.fileName(symlinkDialog.paths[0]) : ""
                onAccepted: symlinkDialog.accept()
                onEscaped: symlinkDialog.reject()
            }
        }

        onAccepted: {
            win.symlinkOpen = false;
            var dir = symlinkTargetDirInput.text.trim();
            if (symlinkDialog.paths.length === 1) {
                var linkName = symlinkNameInput.text.trim();
                backend.createSymlink(symlinkDialog.paths[0], dir, linkName);
            } else if (symlinkDialog.paths.length > 1) {
                backend.createSymlinks(symlinkDialog.paths, dir);
            }
            targetModel().refresh();
            currentModel().refresh();
        }
        onRejected: win.symlinkOpen = false
    }

    // Mask Selection Dialog (Num+ / Num-)
    AppDialog {
        id: maskSelectDialog
        visible: win.maskOpen
        property bool isSelecting: true
        title: isSelecting ? qsTr("Select by Pattern (Num+)") : qsTr("Deselect by Pattern (Num-)")
        width: 440
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: qsTr("Enter wildcard pattern (e.g. *.jpg; *.png):")
                color: p.textSecondary
                font.pixelSize: 12
            }

            CompactField {
                id: maskPatternInput
                Layout.fillWidth: true
                text: "*.jpg; *.png"
                onAccepted: maskSelectDialog.accept()
                onEscaped: maskSelectDialog.reject()
            }

            // Quick preset chips
            RowLayout {
                spacing: 6
                Text { text: qsTr("Presets:"); font.pixelSize: 11; color: p.textDim }
                Repeater {
                    model: ["*.*", "*.txt; *.md", "*.png; *.jpg", "*.tar.gz; *.zip", "*.cpp; *.h"]
                    delegate: Rectangle {
                        implicitHeight: 20
                        implicitWidth: presetText.implicitWidth + 8
                        radius: win.smallRadius
                        color: presetMouse.containsMouse ? p.chipHoverBg : p.chipBg
                        border.width: 1
                        border.color: p.borderDefault

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: p.textMuted
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: maskPatternInput.text = modelData
                        }
                    }
                }
            }
        }

        onAccepted: {
            win.maskOpen = false;
            var pat = maskPatternInput.text.trim();
            if (pat.length > 0) {
                if (maskSelectDialog.isSelecting)
                    currentModel().selectByPattern(pat, true);
                else
                    currentModel().deselectByPattern(pat);
            }
            currentListView().forceActiveFocus();
        }
        onRejected: {
            win.maskOpen = false;
            currentListView().forceActiveFocus();
        }
    }

    // Checksum & Verification Dialog
    AppDialog {
        id: checksumDialog
        visible: win.checksumOpen
        title: qsTr("Checksum (MD5 / SHA256)")
        width: 580

        property string filePath: ""
        property var hashes: ({})
        property string verificationResult: ""
        property bool verificationOk: false

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                VectorIcon { kind: "binary"; width: 20; height: 20; iconColor: p.accent }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: backend.fileName(checksumDialog.filePath)
                        font.bold: true
                        font.pixelSize: 13
                        color: p.textPrimary
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    Text {
                        text: checksumDialog.filePath
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textDim
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: p.borderSubtle }

            // Computed Hashes
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 8
                rowSpacing: 6

                Text { text: "MD5:"; font.bold: true; font.family: "monospace"; color: p.textMuted }
                CompactField {
                    Layout.fillWidth: true
                    text: checksumDialog.hashes.md5 || ""
                    readOnly: true
                    monospace: true
                }
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: 64
                    radius: win.smallRadius
                    color: copyMd5Mouse.containsMouse ? p.btnHoverBg : p.chipBg
                    border.width: 1
                    border.color: p.borderDefault

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: p.textPrimary
                    }

                    MouseArea {
                        id: copyMd5Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.copyToClipboard([checksumDialog.hashes.md5 || ""]);
                            backend.showStatus(qsTr("MD5 hash copied to clipboard."));
                        }
                    }
                }

                Text { text: "SHA1:"; font.bold: true; font.family: "monospace"; color: p.textMuted }
                CompactField {
                    Layout.fillWidth: true
                    text: checksumDialog.hashes.sha1 || ""
                    readOnly: true
                    monospace: true
                }
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: 64
                    radius: win.smallRadius
                    color: copySha1Mouse.containsMouse ? p.btnHoverBg : p.chipBg
                    border.width: 1
                    border.color: p.borderDefault

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: p.textPrimary
                    }

                    MouseArea {
                        id: copySha1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.copyToClipboard([checksumDialog.hashes.sha1 || ""]);
                            backend.showStatus(qsTr("SHA1 hash copied to clipboard."));
                        }
                    }
                }

                Text { text: "SHA256:"; font.bold: true; font.family: "monospace"; color: p.textMuted }
                CompactField {
                    Layout.fillWidth: true
                    text: checksumDialog.hashes.sha256 || ""
                    readOnly: true
                    monospace: true
                }
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: 64
                    radius: win.smallRadius
                    color: copySha256Mouse.containsMouse ? p.btnHoverBg : p.chipBg
                    border.width: 1
                    border.color: p.borderDefault

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: p.textPrimary
                    }

                    MouseArea {
                        id: copySha256Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.copyToClipboard([checksumDialog.hashes.sha256 || ""]);
                            backend.showStatus(qsTr("SHA256 hash copied to clipboard."));
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: p.borderSubtle }

            // Verify live against entered hash
            Text {
                text: qsTr("Verify against hash:")
                font.bold: true
                font.pixelSize: 11
                color: p.textSecondary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                CompactField {
                    id: verifyHashInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("Paste expected MD5 or SHA256 hash to verify...")
                    monospace: true
                    onTextEdited: {
                        var h = verifyHashInput.text.trim().toLowerCase();
                        if (h.length === 0) {
                            checksumDialog.verificationResult = "";
                            return;
                        }
                        if (h === (checksumDialog.hashes.md5 || "").toLowerCase()
                                || h === (checksumDialog.hashes.sha1 || "").toLowerCase()
                                || h === (checksumDialog.hashes.sha256 || "").toLowerCase()) {
                            checksumDialog.verificationOk = true;
                            checksumDialog.verificationResult = qsTr("✓ Checksum matches!");
                        } else {
                            checksumDialog.verificationOk = false;
                            checksumDialog.verificationResult = qsTr("✗ Checksum mismatch!");
                        }
                    }
                }
            }

            Text {
                visible: checksumDialog.verificationResult.length > 0
                text: checksumDialog.verificationResult
                font.bold: true
                font.pixelSize: 12
                color: checksumDialog.verificationOk ? p.successText : p.dangerAccent
            }

            // Save .sha256 / .md5 button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitHeight: 30
                    implicitWidth: saveShaText.implicitWidth + 24
                    radius: win.smallRadius
                    color: saveShaMouse.containsMouse ? p.accent : p.chipBg
                    border.width: 1
                    border.color: saveShaMouse.containsMouse ? p.accent : p.borderDefault

                    Text {
                        id: saveShaText
                        anchors.centerIn: parent
                        text: qsTr("Save .sha256 File")
                        font.pixelSize: 11
                        font.bold: true
                        color: saveShaMouse.containsMouse ? p.accentFg : p.textPrimary
                    }

                    MouseArea {
                        id: saveShaMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var target = checksumDialog.filePath + ".sha256";
                            if (backend.saveChecksumFile(checksumDialog.filePath, "sha256", target)) {
                                backend.showStatus(qsTr("Checksum file saved: %1").arg(backend.fileName(target)));
                                currentModel().refresh();
                            }
                        }
                    }
                }

                Rectangle {
                    implicitHeight: 30
                    implicitWidth: saveMd5Text.implicitWidth + 24
                    radius: win.smallRadius
                    color: saveMd5Mouse.containsMouse ? p.accent : p.chipBg
                    border.width: 1
                    border.color: saveMd5Mouse.containsMouse ? p.accent : p.borderDefault

                    Text {
                        id: saveMd5Text
                        anchors.centerIn: parent
                        text: qsTr("Save .md5 File")
                        font.pixelSize: 11
                        font.bold: true
                        color: saveMd5Mouse.containsMouse ? p.accentFg : p.textPrimary
                    }

                    MouseArea {
                        id: saveMd5Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var target = checksumDialog.filePath + ".md5";
                            if (backend.saveChecksumFile(checksumDialog.filePath, "md5", target)) {
                                backend.showStatus(qsTr("Checksum file saved: %1").arg(backend.fileName(target)));
                                currentModel().refresh();
                            }
                        }
                    }
                }

                Rectangle {
                    visible: checksumDialog.filePath.endsWith(".sha256") || checksumDialog.filePath.endsWith(".md5")
                    implicitHeight: 30
                    implicitWidth: verifyFileText.implicitWidth + 24
                    radius: win.smallRadius
                    color: verifyFileMouse.containsMouse ? p.accent : p.chipBg
                    border.width: 1
                    border.color: verifyFileMouse.containsMouse ? p.accent : p.borderDefault

                    Text {
                        id: verifyFileText
                        anchors.centerIn: parent
                        text: qsTr("Verify Checksum File")
                        font.pixelSize: 11
                        font.bold: true
                        color: verifyFileMouse.containsMouse ? p.accentFg : p.textPrimary
                    }

                    MouseArea {
                        id: verifyFileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var res = backend.verifyChecksumFile(checksumDialog.filePath);
                            backend.showStatus(res.message || "");
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: qsTr("Close")
                flat: true
                onClicked: checksumDialog.reject()
            }
        }

        onRejected: win.checksumOpen = false
    }

    // Visual File Diff Dialog
    AppDialog {
        id: diffDialog
        visible: win.diffOpen
        title: qsTr("Compare Files (Visual Diff)")
        width: 820
        height: 560

        property var diffData: ({})
        property string path1: ""
        property string path2: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // Header summary
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderDefault

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    Text {
                        text: diffDialog.diffData.isIdentical
                              ? qsTr("Files are identical")
                              : qsTr("Differences: %1").arg(diffDialog.diffData.differences || 0)
                        font.bold: true
                        font.pixelSize: 12
                        color: diffDialog.diffData.isIdentical ? p.successText : p.warningText
                    }

                    Rectangle { width: 1; height: 16; color: p.borderDefault }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("+%1 added").arg(diffDialog.diffData.added || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.diffAddedText
                    }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("-%1 deleted").arg(diffDialog.diffData.deleted || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.diffDeletedText
                    }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("~%1 modified").arg(diffDialog.diffData.modified || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.diffModifiedText
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: backend.fileName(diffDialog.path1) + "  ↔  " + backend.fileName(diffDialog.path2)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textMuted
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Binary difference notice
            Rectangle {
                visible: diffDialog.diffData.isBinary === true
                Layout.fillWidth: true
                height: 40
                color: p.diffDeletedBg
                border.width: 1
                border.color: Qt.alpha(p.dangerAccent, 0.35)
                radius: win.smallRadius
                Text {
                    anchors.centerIn: parent
                    text: qsTr("Binary files differ (visual diff not supported for binaries).")
                    color: p.diffDeletedText
                    font.bold: true
                }
            }

            // Text diff side-by-side / rows table
            ListView {
                visible: diffDialog.diffData.isBinary !== true
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: diffDialog.diffData.rows || []

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    width: parent.width
                    height: 22
                    color: {
                        var t = modelData.type;
                        if (t === "added") return p.diffAddedBg;
                        if (t === "deleted") return p.diffDeletedBg;
                        if (t === "modified") return p.diffModifiedBg;
                        return index % 2 === 0 ? "transparent" : p.rowAltBg;
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 6

                        // Left line number
                        Text {
                            Layout.preferredWidth: 36
                            text: modelData.line1 > 0 ? modelData.line1 : ""
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: p.textDim
                        }

                        // Left text
                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: modelData.text1 || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            elide: Text.ElideRight
                            color: {
                                var t = modelData.type;
                                if (t === "deleted") return p.diffDeletedText;
                                if (t === "modified") return p.diffModifiedText;
                                return p.textSecondary;
                            }
                        }

                        Rectangle { width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                        // Right line number
                        Text {
                            Layout.preferredWidth: 36
                            text: modelData.line2 > 0 ? modelData.line2 : ""
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: p.textDim
                        }

                        // Right text
                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: modelData.text2 || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            elide: Text.ElideRight
                            color: {
                                var t = modelData.type;
                                if (t === "added") return p.diffAddedText;
                                if (t === "modified") return p.diffModifiedText;
                                return p.textSecondary;
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.diffOpen = false

        footer: DialogButtonBox {
            Button {
                text: qsTr("Close")
                flat: true
                onClicked: diffDialog.reject()
            }
        }
    }

    // Keyboard Shortcuts Help Overlay
    AppDialog {
        id: helpDialog
        visible: win.helpOpen
        title: qsTr("AeroCommander — Keyboard Shortcuts")
        width: 640
        height: 580

        ScrollView {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 4

                Repeater {
                    model: [
                        { key: "Ctrl + Shift + P", desc: qsTr("Open Command Palette (fuzzy search actions)") },
                        { key: "Ctrl + P", desc: qsTr("Quick Jump to Folder (bookmarks, recent, zoxide)") },
                        { key: "Ctrl + Shift + B", desc: qsTr("Toggle Flat / Branch View (all subfolders in one list)") },
                        { key: "Ctrl + Shift + D", desc: qsTr("Toggle Disk Usage Analyzer (proportional bars & sorted sizes)") },
                        { key: "Ctrl + Shift + S", desc: qsTr("Synchronize Directories recursively between panels") },
                        { key: "Ctrl + Shift + F7", desc: qsTr("Find Duplicate Files by size and SHA-256 hash") },
                        { key: "Ctrl + Shift + Q", desc: qsTr("Open Operation Queue & Pause / Speed / ETA monitor") },
                        { key: "Ctrl + Shift + M", desc: qsTr("Connect & manage Remote SFTP / SMB / SSHFS servers") },
                        { key: "Ctrl + Shift + O", desc: qsTr("Open With compatible apps & manage Custom Actions") },
                        { key: "Enter (on archive)", desc: qsTr("Browse inside .zip / .tar.* / .7z archive as virtual folder") },
                        { key: "Tab", desc: qsTr("Switch active panel (Left / Right)") },
                        { key: "Ctrl + Shift + T", desc: qsTr("Toggle between Light and Dark theme") },
                        { key: "Ctrl + T / Ctrl + W", desc: qsTr("Open new tab / Close active tab in panel") },
                        { key: "Ctrl + Tab", desc: qsTr("Switch between open tabs in active panel") },
                        { key: "Ctrl + 1 / Ctrl + 2", desc: qsTr("Toggle List / Grid thumbnail view mode") },
                        { key: "Ctrl + C / X / V", desc: qsTr("Copy / Cut / Paste files via system clipboard") },
                        { key: "Ctrl+Shift+C / Ctrl+Alt+C", desc: qsTr("Copy names or paths as comma-separated text") },
                        { key: "Ctrl + Z", desc: qsTr("Undo last rename, move, or trash delete") },
                        { key: "Shift + F4", desc: qsTr("Create new file (or files via comma) and open in editor") },
                        { key: "Ctrl + Shift + F5", desc: qsTr("Create symbolic link in target panel") },
                        { key: "Num+ / Num-", desc: qsTr("Select / deselect items by wildcard pattern (*.jpg)") },
                        { key: "Num* / Ctrl+Shift+A", desc: qsTr("Invert selection in active panel") },
                        { key: "Ctrl + Alt + D", desc: qsTr("Compare two text files with visual side-by-side diff") },
                        { key: "Alt + Enter", desc: qsTr("Item properties & editable chmod permissions") },
                        { key: "Space / Insert", desc: qsTr("Select item (and calculate folder size) + advance") },
                        { key: "Alt + Shift + Enter", desc: qsTr("Calculate sizes for all folders in panel") },
                        { key: "Ctrl + L", desc: qsTr("Edit path of active panel") },
                        { key: "Ctrl + Q", desc: qsTr("Toggle live Quick View in opposite panel") },
                        { key: "Ctrl + S", desc: qsTr("Toggle real-time quick filter bar") },
                        { key: "Ctrl + B", desc: qsTr("Open Bookmarks manager") },
                        { key: "Ctrl + U / Alt + =", desc: qsTr("Swap panels / Sync target panel") },
                        { key: "Shift + F2", desc: qsTr("Compare Left & Right directories (select differences)") },
                        { key: "Ctrl + M", desc: qsTr("Multi-Rename Tool for selected items") },
                        { key: "Alt + F5 / Alt + F9", desc: qsTr("Pack files to archive / Extract archive") },
                        { key: "Alt + Left / Right", desc: qsTr("Navigate directory history Back / Forward") },
                        { key: "F3 / F4", desc: qsTr("Preview item (Text/Image/Hex) / Edit with $EDITOR") },
                        { key: "F5 / F6 / Shift+F6", desc: qsTr("Copy / Move / Rename item(s)") },
                        { key: "F7 / F8", desc: qsTr("Create new folder / Delete selected item(s)") },
                        { key: "F9 / Alt + T", desc: qsTr("Open terminal in active folder") },
                        { key: "Alt + F7", desc: qsTr("Search files recursively") },
                        { key: "Ctrl + F3..F6", desc: qsTr("Sort by Name, Ext, Date, or Size") },
                        { key: "Ctrl + A / Ctrl + D", desc: qsTr("Select all / Deselect all") },
                        { key: "Ctrl + H", desc: qsTr("Toggle show/hide hidden dotfiles") },
                        { key: "F10 / Esc", desc: qsTr("Quit omapanel / Close dialog") }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: index % 2 === 0 ? p.rowAltBg : "transparent"
                        radius: win.smallRadius

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                color: p.badgeBg
                                border.width: 1
                                border.color: p.borderDefault
                                radius: win.smallRadius
                                implicitWidth: 160
                                implicitHeight: 22

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    text: modelData.key
                                    font.bold: true
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    color: p.accent
                                }
                            }

                            Text {
                                text: modelData.desc
                                font.pixelSize: 12
                                color: p.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.helpOpen = false

        footer: DialogButtonBox {
            Button {
                text: qsTr("Close")
                flat: true
                onClicked: helpDialog.reject()
            }
        }
    }

    // About AeroCommander Dialog
    AppDialog {
        id: aboutDialog
        title: qsTr("About AeroCommander")
        visible: win.aboutOpen
        width: Math.min(460, win.width - 40)

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 14

                Image {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    width: 54
                    height: 54
                    source: "qrc:/logo.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    smooth: true
                }

                ColumnLayout {
                    spacing: 3

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "AeroCommander"
                            font.bold: true
                            font.pixelSize: 18
                            color: p.textPrimary
                        }
                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: vText.implicitWidth + 8
                            radius: 3
                            color: Qt.alpha(p.accent, 0.2)
                            border.width: 1
                            border.color: Qt.alpha(p.accent, 0.4)
                            Text {
                                id: vText
                                anchors.centerIn: parent
                                text: "v1.0"
                                font.pixelSize: 10
                                font.bold: true
                                color: p.accent
                            }
                        }
                    }

                    Text {
                        text: qsTr("Total Commander for Linux & Omarchy")
                        font.pixelSize: 12
                        color: p.textMuted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: p.borderSubtle
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                lineHeight: 1.4
                color: p.textSecondary
                text: qsTr("Dual-panel orthodox file manager featuring tabbed navigation, git status tracking, thumbnail grid, checksum calculation & verification, visual side-by-side diff, multi-file rename, and undoable operations.")
            }
        }

        onRejected: win.aboutOpen = false

        footer: DialogButtonBox {
            Button {
                text: qsTr("Close")
                flat: true
                onClicked: aboutDialog.reject()
            }
        }
    }

    // Command Palette (Ctrl+Shift+P) & Quick Folder Jump (Ctrl+P / zoxide)
    AppDialog {
        id: commandPaletteDialog
        title: win.commandPaletteMode === "jump" ? qsTr("Quick Jump to Folder") : qsTr("Command Palette")
        visible: win.commandPaletteOpen
        width: Math.min(640, win.width - 40)
        topPadding: 10
        bottomPadding: 10

        property var resultItems: []
        property int selectedIndex: 0

        function localizedSource(src) {
            if (src === "Bookmark") return qsTr("Bookmark");
            if (src === "Tab") return qsTr("Tab");
            if (src === "Recent") return qsTr("Recent");
            if (src === "Folder") return qsTr("Folder");
            if (src === "Drive") return qsTr("Drive");
            if (src === "Path") return qsTr("Path");
            return src;
        }

        function refreshResults() {
            var q = paletteInput.text;
            if (win.commandPaletteMode === "jump") {
                resultItems = backend.queryJumpDirectories(q, 50);
            } else {
                var cmds = win.getCommandList();
                var scored = [];
                for (var i = 0; i < cmds.length; i++) {
                    var c = cmds[i];
                    var s = win.fuzzyScoreCommand(q, c.title, c.category, c.shortcut);
                    if (s >= 0)
                        scored.push({ item: c, score: s, origIdx: i });
                }
                scored.sort(function(a, b) {
                    if (b.score !== a.score)
                        return b.score - a.score;
                    return a.origIdx - b.origIdx;
                });
                var out = [];
                for (var k = 0; k < scored.length; k++)
                    out.push(scored[k].item);
                resultItems = out;
            }
            selectedIndex = resultItems.length > 0 ? 0 : -1;
        }

        function switchMode(mode) {
            var next = (mode === "jump") ? "jump" : "commands";
            if (win.commandPaletteMode !== next) {
                resultItems = [];
                selectedIndex = -1;
                win.commandPaletteMode = next;
            }
            refreshResults();
            paletteSearchInput.forceActiveFocus();
        }

        function resetAndRefresh(mode) {
            resultItems = [];
            selectedIndex = -1;
            paletteInput.text = "";
            if (mode !== undefined)
                win.commandPaletteMode = (mode === "jump") ? "jump" : "commands";
            refreshResults();
            paletteSearchInput.forceActiveFocus();
        }

        function activateItem(idx, modifiers) {
            if (idx < 0 || idx >= resultItems.length)
                return;
            var item = resultItems[idx];
            if (win.commandPaletteMode === "jump") {
                var targetPath = item.path;
                win.commandPaletteOpen = false;
                if (modifiers & Qt.ControlModifier)
                    currentModel().addTab(targetPath);
                else if (modifiers & Qt.AltModifier)
                    targetModel().setPath(targetPath);
                else
                    currentModel().setPath(targetPath);
                currentListView().forceActiveFocus();
            } else {
                win.commandPaletteOpen = false;
                if (typeof item.run === "function")
                    item.run();
                if (!win.commandPaletteOpen && !win.confirmCopyOpen && !win.confirmMoveOpen
                        && !win.confirmDeleteOpen && !win.renameOpen && !win.newFolderOpen
                        && !win.newFileOpen && !win.multiRenameOpen && !win.packArchiveOpen
                        && !win.searchOpen && !win.bookmarksOpen && !win.propertiesOpen
                        && !win.checksumOpen && !win.diffOpen && !win.symlinkOpen
                        && !win.maskOpen && !win.helpOpen && !win.aboutOpen && !win.previewOpen
                        && !win.syncDirsOpen && !win.duplicateFinderOpen && !win.queueDialogOpen
                        && !win.remoteConnectionsOpen && !win.openWithOpen)
                    currentListView().forceActiveFocus();
            }
        }

        onOpened: paletteSearchInput.forceActiveFocus()
        onRejected: {
            win.commandPaletteOpen = false;
            currentListView().forceActiveFocus();
        }

        contentItem: ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    id: paletteInput
                    property alias text: paletteSearchInput.text
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: win.smallRadius
                    color: p.inputBg
                    border.width: 1
                    border.color: paletteSearchInput.activeFocus ? p.accent : p.borderDefault
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        VectorIcon {
                            kind: win.commandPaletteMode === "jump" ? "folder" : "command"
                            iconColor: p.accent
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: paletteSearchInput.text.length === 0 && !paletteSearchInput.preeditText
                                text: win.commandPaletteMode === "jump"
                                      ? qsTr("Type folder name, bookmark, zoxide query, or path (type > for commands)...")
                                      : qsTr("Type a command or shortcut...")
                                font.pixelSize: 12
                                color: p.textDim
                                elide: Text.ElideRight
                            }

                            TextInput {
                                id: paletteSearchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 13
                                color: p.textPrimary
                                selectionColor: Qt.alpha(p.accent, 0.35)
                                selectedTextColor: p.textOnHover
                                selectByMouse: true
                                clip: true

                                onTextEdited: {
                                    if (win.commandPaletteMode === "jump" && text.indexOf(">") === 0) {
                                        text = text.slice(1).replace(/^\s+/, "");
                                        commandPaletteDialog.switchMode("commands");
                                        return;
                                    }
                                    commandPaletteDialog.refreshResults();
                                }

                                Keys.onPressed: function(event) {
                                    var cnt = commandPaletteDialog.resultItems.length;
                                    if (event.key === Qt.Key_Down) {
                                        if (cnt > 0) {
                                            commandPaletteDialog.selectedIndex = (commandPaletteDialog.selectedIndex + 1) % cnt;
                                            paletteListView.positionViewAtIndex(commandPaletteDialog.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up) {
                                        if (cnt > 0) {
                                            commandPaletteDialog.selectedIndex = (commandPaletteDialog.selectedIndex - 1 + cnt) % cnt;
                                            paletteListView.positionViewAtIndex(commandPaletteDialog.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_PageDown) {
                                        if (cnt > 0) {
                                            commandPaletteDialog.selectedIndex = Math.min(cnt - 1, commandPaletteDialog.selectedIndex + 8);
                                            paletteListView.positionViewAtIndex(commandPaletteDialog.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_PageUp) {
                                        if (cnt > 0) {
                                            commandPaletteDialog.selectedIndex = Math.max(0, commandPaletteDialog.selectedIndex - 8);
                                            paletteListView.positionViewAtIndex(commandPaletteDialog.selectedIndex, ListView.Contain);
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                        commandPaletteDialog.switchMode(win.commandPaletteMode === "commands" ? "jump" : "commands");
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        commandPaletteDialog.activateItem(commandPaletteDialog.selectedIndex, event.modifiers);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        commandPaletteDialog.reject();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    implicitHeight: 34
                    implicitWidth: modePillRow.implicitWidth + 6
                    radius: win.smallRadius
                    color: p.cardBg
                    border.width: 1
                    border.color: p.borderDefault

                    RowLayout {
                        id: modePillRow
                        anchors.centerIn: parent
                        spacing: 2

                        Rectangle {
                            implicitHeight: 26
                            implicitWidth: cmdModeTxt.implicitWidth + 14
                            radius: win.smallRadius - 1
                            color: win.commandPaletteMode === "commands" ? Qt.alpha(p.accent, 0.2) : "transparent"
                            border.width: win.commandPaletteMode === "commands" ? 1 : 0
                            border.color: Qt.alpha(p.accent, 0.5)
                            Text {
                                id: cmdModeTxt
                                anchors.centerIn: parent
                                text: qsTr("Commands")
                                font.pixelSize: 11
                                font.weight: win.commandPaletteMode === "commands" ? Font.DemiBold : Font.Normal
                                color: win.commandPaletteMode === "commands" ? p.accent : p.textMuted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: commandPaletteDialog.switchMode("commands")
                            }
                        }

                        Rectangle {
                            implicitHeight: 26
                            implicitWidth: jumpModeTxt.implicitWidth + 14
                            radius: win.smallRadius - 1
                            color: win.commandPaletteMode === "jump" ? Qt.alpha(p.accent, 0.2) : "transparent"
                            border.width: win.commandPaletteMode === "jump" ? 1 : 0
                            border.color: Qt.alpha(p.accent, 0.5)
                            Text {
                                id: jumpModeTxt
                                anchors.centerIn: parent
                                text: qsTr("Quick Jump")
                                font.pixelSize: 11
                                font.weight: win.commandPaletteMode === "jump" ? Font.DemiBold : Font.Normal
                                color: win.commandPaletteMode === "jump" ? p.accent : p.textMuted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: commandPaletteDialog.switchMode("jump")
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(360, Math.max(120, Math.min(commandPaletteDialog.resultItems.length, 9) * 38 + 8))
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderSubtle
                clip: true

                ListView {
                    id: paletteListView
                    anchors.fill: parent
                    anchors.margins: 4
                    model: commandPaletteDialog.resultItems
                    currentIndex: commandPaletteDialog.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: palRow
                        width: paletteListView.width
                        height: 36
                        radius: win.smallRadius
                        readonly property bool isSelected: index === commandPaletteDialog.selectedIndex
                        color: isSelected
                               ? Qt.alpha(p.accent, win.isDark ? 0.22 : 0.14)
                               : (palRowMouse.containsMouse ? p.rowHoverBg : "transparent")
                        border.width: isSelected ? 1 : 0
                        border.color: Qt.alpha(p.accent, 0.45)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            VectorIcon {
                                kind: win.commandPaletteMode === "jump" ? "folder" : "command"
                                iconColor: palRow.isSelected ? p.accent : p.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData
                                          ? (win.commandPaletteMode === "jump" ? (modelData.label || "") : (modelData.title || ""))
                                          : ""
                                    font.pixelSize: 12
                                    font.weight: palRow.isSelected ? Font.DemiBold : Font.Normal
                                    color: p.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: Boolean(win.commandPaletteMode === "jump" && modelData && modelData.path && modelData.path !== modelData.label)
                                    Layout.fillWidth: true
                                    text: (win.commandPaletteMode === "jump" && modelData && modelData.path) ? modelData.path : ""
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: p.textDim
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: badgeTxt.implicitWidth + 10
                                radius: 3
                                color: Qt.alpha(p.accent, win.commandPaletteMode === "jump" ? 0.14 : 0.1)
                                border.width: 1
                                border.color: Qt.alpha(p.borderDefault, 0.8)

                                Text {
                                    id: badgeTxt
                                    anchors.centerIn: parent
                                    text: modelData
                                          ? (win.commandPaletteMode === "jump"
                                             ? commandPaletteDialog.localizedSource(modelData.source || "")
                                             : (modelData.category || ""))
                                          : ""
                                    font.pixelSize: 10
                                    color: p.textSecondary
                                }
                            }

                            Rectangle {
                                visible: Boolean(win.commandPaletteMode === "commands" && modelData && modelData.shortcut && modelData.shortcut.length > 0)
                                implicitHeight: 20
                                implicitWidth: scTxt.implicitWidth + 10
                                radius: 3
                                color: p.inputBg
                                border.width: 1
                                border.color: p.borderDefault

                                Text {
                                    id: scTxt
                                    anchors.centerIn: parent
                                    text: (win.commandPaletteMode === "commands" && modelData && modelData.shortcut) ? modelData.shortcut : ""
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: palRow.isSelected ? p.accent : p.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: palRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                commandPaletteDialog.selectedIndex = index;
                                commandPaletteDialog.activateItem(index, mouse.modifiers);
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: commandPaletteDialog.resultItems.length === 0
                    text: win.commandPaletteMode === "jump"
                          ? qsTr("No matching folders or zoxide entries found.")
                          : qsTr("No matching commands found.")
                    font.pixelSize: 12
                    color: p.textDim
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: win.commandPaletteMode === "jump"
                          ? qsTr("Enter: open  •  Ctrl+Enter: new tab  •  Alt+Enter: target panel  •  Tab: Commands")
                          : qsTr("↑/↓: navigate  •  Enter: execute  •  Tab: Quick Jump  •  Esc: close")
                    font.pixelSize: 10
                    color: p.textDim
                    elide: Text.ElideRight
                }

                Text {
                    text: commandPaletteDialog.resultItems.length + " " + qsTr("results")
                    font.pixelSize: 10
                    color: p.textMuted
                }
            }
        }
    }

    // Ctrl+Shift+S Recursive Directory Synchronization Dialog
    AppDialog {
        id: syncDirsDialog
        visible: win.syncDirsOpen
        title: qsTr("Synchronize Directories (Ctrl+Shift+S)")
        width: Math.min(860, win.width - 40)
        height: Math.min(620, win.height - 40)
        standardButtons: Dialog.NoButton

        property string compareMode: "date_size"
        property bool includeHidden: false
        property bool showLeftToRight: true
        property bool showRightToLeft: true
        property bool showEqual: false
        property bool showConflicts: true
        property var allItems: []
        property var visibleItems: []
        property int copyRightCount: 0
        property int copyLeftCount: 0
        property int equalCount: 0
        property int conflictCount: 0

        function refreshCompare() {
            if (backend.leftPanel.isArchiveView || backend.rightPanel.isArchiveView) {
                allItems = [];
                rebuildVisible();
                return;
            }
            var raw = backend.compareDirectoriesRecursive(
                backend.leftPanel.path, backend.rightPanel.path, compareMode, includeHidden
            );
            var indexed = [];
            for (var i = 0; i < raw.length; i++) {
                var r = raw[i];
                indexed.push({
                    syncIdx: i,
                    relPath: r.relPath,
                    leftPath: r.leftPath,
                    rightPath: r.rightPath,
                    leftExists: r.leftExists,
                    rightExists: r.rightExists,
                    leftFormattedSize: r.leftFormattedSize,
                    rightFormattedSize: r.rightFormattedSize,
                    leftModified: r.leftModified,
                    rightModified: r.rightModified,
                    status: r.status,
                    action: r.action
                });
            }
            allItems = indexed;
            rebuildVisible();
        }

        function rebuildVisible() {
            var cr = 0, cl = 0, eq = 0, cf = 0;
            var filtered = [];
            for (var i = 0; i < allItems.length; i++) {
                var it = allItems[i];
                if (it.action === "copy_to_right") cr++;
                else if (it.action === "copy_to_left") cl++;
                if (it.status === "equal") eq++;
                else if (it.status === "different" && it.action === "skip") cf++;

                var show = false;
                if (it.status === "equal")
                    show = showEqual;
                else if (it.action === "copy_to_right")
                    show = showLeftToRight;
                else if (it.action === "copy_to_left")
                    show = showRightToLeft;
                else
                    show = showConflicts;

                if (show)
                    filtered.push(it);
            }
            copyRightCount = cr;
            copyLeftCount = cl;
            equalCount = eq;
            conflictCount = cf;
            visibleItems = filtered;
        }

        function cycleAction(syncIdx) {
            if (syncIdx < 0 || syncIdx >= allItems.length)
                return;
            var next = allItems.slice();
            var cur = next[syncIdx];
            var updated = Object.assign({}, cur);
            if (cur.status === "equal")
                return;
            if (cur.action === "copy_to_right")
                updated.action = cur.rightExists ? "copy_to_left" : "skip";
            else if (cur.action === "copy_to_left")
                updated.action = "skip";
            else
                updated.action = cur.leftExists ? "copy_to_right" : "copy_to_left";
            next[syncIdx] = updated;
            allItems = next;
            rebuildVisible();
        }

        function applySync() {
            if (copyRightCount === 0 && copyLeftCount === 0)
                return;
            backend.executeDirectorySync(backend.leftPanel.path, backend.rightPanel.path, allItems);
            refreshCompare();
        }

        onRejected: {
            win.syncDirsOpen = false;
            currentListView().forceActiveFocus();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Left: %1").arg(backend.leftPanel.path)
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.textSecondary
                    elide: Text.ElideMiddle
                }
                VectorIcon { kind: "sync"; iconColor: p.accent }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Right: %1").arg(backend.rightPanel.path)
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.textSecondary
                    elide: Text.ElideMiddle
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text { text: qsTr("Compare:"); font.pixelSize: 11; color: p.textDim }
                FilterPill { label: qsTr("Date & Size"); active: syncDirsDialog.compareMode === "date_size"; onClicked: { syncDirsDialog.compareMode = "date_size"; syncDirsDialog.refreshCompare(); } }
                FilterPill { label: qsTr("Size Only"); active: syncDirsDialog.compareMode === "size"; onClicked: { syncDirsDialog.compareMode = "size"; syncDirsDialog.refreshCompare(); } }
                FilterPill { label: qsTr("SHA-256"); active: syncDirsDialog.compareMode === "sha256"; onClicked: { syncDirsDialog.compareMode = "sha256"; syncDirsDialog.refreshCompare(); } }
                FilterPill { label: qsTr("Hidden"); active: syncDirsDialog.includeHidden; onClicked: { syncDirsDialog.includeHidden = !syncDirsDialog.includeHidden; syncDirsDialog.refreshCompare(); } }

                Item { Layout.fillWidth: true }

                ToolbarBtn {
                    label: qsTr("Compare")
                    accentHighlight: true
                    onClicked: syncDirsDialog.refreshCompare()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                FilterPill { label: "→ " + syncDirsDialog.copyRightCount; active: syncDirsDialog.showLeftToRight; onClicked: { syncDirsDialog.showLeftToRight = !syncDirsDialog.showLeftToRight; syncDirsDialog.rebuildVisible(); } }
                FilterPill { label: "← " + syncDirsDialog.copyLeftCount; active: syncDirsDialog.showRightToLeft; onClicked: { syncDirsDialog.showRightToLeft = !syncDirsDialog.showRightToLeft; syncDirsDialog.rebuildVisible(); } }
                FilterPill { label: "≠ " + syncDirsDialog.conflictCount; active: syncDirsDialog.showConflicts; onClicked: { syncDirsDialog.showConflicts = !syncDirsDialog.showConflicts; syncDirsDialog.rebuildVisible(); } }
                FilterPill { label: "= " + syncDirsDialog.equalCount; active: syncDirsDialog.showEqual; onClicked: { syncDirsDialog.showEqual = !syncDirsDialog.showEqual; syncDirsDialog.rebuildVisible(); } }

                Item { Layout.fillWidth: true }
                Text {
                    text: qsTr("Click direction badge (→ / ← / Skip) to override per file")
                    font.pixelSize: 10
                    color: p.textDim
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderSubtle
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: syncDirsDialog.visibleItems

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 30
                        radius: win.smallRadius
                        color: index % 2 === 0 ? p.rowAltBg : "transparent"

                        readonly property string act: modelData ? (modelData.action || "skip") : "skip"
                        readonly property string st: modelData ? (modelData.status || "") : ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: modelData ? (modelData.relPath || "") : ""
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: st === "equal" ? p.textDim : p.textPrimary
                                elide: Text.ElideMiddle
                            }

                            Text {
                                Layout.preferredWidth: 118
                                horizontalAlignment: Text.AlignRight
                                text: (modelData && modelData.leftExists)
                                      ? (modelData.leftFormattedSize + " • " + (modelData.leftModified || "").slice(5, 16))
                                      : "—"
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: (modelData && modelData.leftExists) ? p.textSecondary : p.textDim
                            }

                            Rectangle {
                                implicitHeight: 22
                                implicitWidth: 54
                                radius: 4
                                color: act === "copy_to_right" || act === "copy_to_left"
                                       ? Qt.alpha(p.accent, 0.2)
                                       : (st === "different" ? Qt.alpha(p.warningText, 0.16) : p.inputBg)
                                border.width: 1
                                border.color: act !== "skip" ? Qt.alpha(p.accent, 0.5) : p.borderDefault

                                Text {
                                    anchors.centerIn: parent
                                    text: act === "copy_to_right" ? "→"
                                        : act === "copy_to_left" ? "←"
                                        : (st === "equal" ? "=" : (st === "different" ? "≠" : qsTr("Skip")))
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: act !== "skip" ? p.accent : p.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: st !== "equal" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (modelData && modelData.syncIdx !== undefined)
                                            syncDirsDialog.cycleAction(modelData.syncIdx);
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 118
                                horizontalAlignment: Text.AlignLeft
                                text: (modelData && modelData.rightExists)
                                      ? (modelData.rightFormattedSize + " • " + (modelData.rightModified || "").slice(5, 16))
                                      : "—"
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: (modelData && modelData.rightExists) ? p.textSecondary : p.textDim
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: syncDirsDialog.visibleItems.length === 0
                    text: (backend.leftPanel.isArchiveView || backend.rightPanel.isArchiveView)
                          ? qsTr("Directory synchronization is not supported inside archive views.")
                          : qsTr("No differences match current filter.")
                    font.pixelSize: 12
                    color: p.textDim
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: qsTr("%1 to sync (%2 → right, %3 ← left)")
                          .arg(syncDirsDialog.copyRightCount + syncDirsDialog.copyLeftCount)
                          .arg(syncDirsDialog.copyRightCount)
                          .arg(syncDirsDialog.copyLeftCount)
                    font.pixelSize: 11
                    color: p.textMuted
                }

                ToolbarBtn {
                    label: qsTr("Synchronize")
                    accentHighlight: true
                    btnEnabled: syncDirsDialog.copyRightCount + syncDirsDialog.copyLeftCount > 0
                    onClicked: syncDirsDialog.applySync()
                }

                ToolbarBtn {
                    label: qsTr("Close")
                    onClicked: syncDirsDialog.reject()
                }
            }
        }
    }

    // Ctrl+Shift+F7 Duplicate Files Finder Dialog
    AppDialog {
        id: duplicateFinderDialog
        visible: win.duplicateFinderOpen
        title: qsTr("Find Duplicate Files (Ctrl+Shift+F7)")
        width: Math.min(820, win.width - 40)
        height: Math.min(620, win.height - 40)
        standardButtons: Dialog.NoButton

        property bool bothPanels: false
        property var minSizeBytes: 1024
        property bool includeHidden: false
        property var dupItems: []
        property int groupCount: 0
        property int selectedCount: 0
        property string reclaimableFormatted: "0 B"

        function formatBytes(b) {
            if (b < 1024) return b + " B";
            if (b < 1048576) return (b / 1024.0).toFixed(1) + " KB";
            if (b < 1073741824) return (b / 1048576.0).toFixed(1) + " MB";
            return (b / 1073741824.0).toFixed(2) + " GB";
        }

        function recalcSummary() {
            var groups = {};
            var sel = 0;
            var reclaim = 0;
            for (var i = 0; i < dupItems.length; i++) {
                var it = dupItems[i];
                groups[it.groupIndex] = true;
                if (it.selected) {
                    sel++;
                    reclaim += (it.size || 0);
                }
            }
            groupCount = Object.keys(groups).length;
            selectedCount = sel;
            reclaimableFormatted = formatBytes(reclaim);
        }

        function runScan() {
            var r1 = currentModel().isArchiveView ? "" : currentModel().path;
            var r2 = (bothPanels && !targetModel().isArchiveView) ? targetModel().path : "";
            var raw = backend.findDuplicateFiles(r1, r2, minSizeBytes, includeHidden);
            var out = [];
            for (var i = 0; i < raw.length; i++) {
                var r = raw[i];
                out.push({
                    idx: i,
                    groupIndex: r.groupIndex,
                    hash: r.hash,
                    path: r.path,
                    name: r.name,
                    dirPath: r.dirPath,
                    size: r.size,
                    formattedSize: r.formattedSize,
                    modified: r.modified,
                    modifiedSecs: r.modifiedSecs,
                    groupCount: r.groupCount,
                    selected: Boolean(r.selected)
                });
            }
            dupItems = out;
            recalcSummary();
        }

        function toggleRowSelected(rowIdx) {
            if (rowIdx < 0 || rowIdx >= dupItems.length)
                return;
            var next = dupItems.slice();
            var upd = Object.assign({}, next[rowIdx]);
            upd.selected = !upd.selected;
            next[rowIdx] = upd;
            dupItems = next;
            recalcSummary();
        }

        function applyKeepStrategy(strategy) {
            if (dupItems.length === 0)
                return;
            var keeperByGroup = {};
            if (strategy !== "none") {
                for (var i = 0; i < dupItems.length; i++) {
                    var it = dupItems[i];
                    var g = it.groupIndex;
                    if (keeperByGroup[g] === undefined) {
                        keeperByGroup[g] = i;
                    } else if (strategy === "oldest") {
                        if (it.modifiedSecs <= dupItems[keeperByGroup[g]].modifiedSecs)
                            keeperByGroup[g] = i;
                    } else {
                        if (it.modifiedSecs > dupItems[keeperByGroup[g]].modifiedSecs)
                            keeperByGroup[g] = i;
                    }
                }
            }
            var next = [];
            for (var j = 0; j < dupItems.length; j++) {
                var item = Object.assign({}, dupItems[j]);
                item.selected = strategy === "none" ? false : (keeperByGroup[item.groupIndex] !== j);
                next.push(item);
            }
            dupItems = next;
            recalcSummary();
        }

        function selectedPaths() {
            var paths = [];
            for (var i = 0; i < dupItems.length; i++) {
                if (dupItems[i].selected)
                    paths.push(dupItems[i].path);
            }
            return paths;
        }

        onRejected: {
            win.duplicateFinderOpen = false;
            currentListView().forceActiveFocus();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text { text: qsTr("Scope:"); font.pixelSize: 11; color: p.textDim }
                FilterPill { label: qsTr("Active Panel"); active: !duplicateFinderDialog.bothPanels; onClicked: { duplicateFinderDialog.bothPanels = false; duplicateFinderDialog.runScan(); } }
                FilterPill { label: qsTr("Both Panels"); active: duplicateFinderDialog.bothPanels; onClicked: { duplicateFinderDialog.bothPanels = true; duplicateFinderDialog.runScan(); } }

                Item { width: 8; height: 24 }
                Text { text: qsTr("Min Size:"); font.pixelSize: 11; color: p.textDim }
                FilterPill { label: "> 0 B"; active: duplicateFinderDialog.minSizeBytes === 1; onClicked: { duplicateFinderDialog.minSizeBytes = 1; duplicateFinderDialog.runScan(); } }
                FilterPill { label: "> 1 KB"; active: duplicateFinderDialog.minSizeBytes === 1024; onClicked: { duplicateFinderDialog.minSizeBytes = 1024; duplicateFinderDialog.runScan(); } }
                FilterPill { label: "> 1 MB"; active: duplicateFinderDialog.minSizeBytes === 1048576; onClicked: { duplicateFinderDialog.minSizeBytes = 1048576; duplicateFinderDialog.runScan(); } }
                FilterPill { label: qsTr("Hidden"); active: duplicateFinderDialog.includeHidden; onClicked: { duplicateFinderDialog.includeHidden = !duplicateFinderDialog.includeHidden; duplicateFinderDialog.runScan(); } }

                Item { Layout.fillWidth: true }
                ToolbarBtn {
                    label: qsTr("Scan Duplicates")
                    accentHighlight: true
                    onClicked: duplicateFinderDialog.runScan()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                FilterPill { label: qsTr("Keep Newest"); onClicked: duplicateFinderDialog.applyKeepStrategy("newest") }
                FilterPill { label: qsTr("Keep Oldest"); onClicked: duplicateFinderDialog.applyKeepStrategy("oldest") }
                FilterPill { label: qsTr("Clear Selection"); onClicked: duplicateFinderDialog.applyKeepStrategy("none") }

                Item { Layout.fillWidth: true }

                Text {
                    text: qsTr("%1 file(s) in %2 duplicate group(s)  •  %3 selected (%4 reclaimable)")
                          .arg(duplicateFinderDialog.dupItems.length)
                          .arg(duplicateFinderDialog.groupCount)
                          .arg(duplicateFinderDialog.selectedCount)
                          .arg(duplicateFinderDialog.reclaimableFormatted)
                    font.pixelSize: 11
                    color: p.textMuted
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderSubtle
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: duplicateFinderDialog.dupItems

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 36
                        radius: win.smallRadius
                        readonly property bool isSel: modelData ? Boolean(modelData.selected) : false
                        readonly property int gIdx: modelData ? (modelData.groupIndex || 0) : 0
                        color: isSel
                               ? Qt.alpha(p.dangerAccent, win.isDark ? 0.14 : 0.09)
                               : (gIdx % 2 === 0 ? p.rowAltBg : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 3
                                color: isSel ? p.dangerAccent : "transparent"
                                border.width: 1
                                border.color: isSel ? p.dangerAccent : p.borderStrong
                                Text {
                                    anchors.centerIn: parent
                                    visible: isSel
                                    text: "✓"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: p.accentFg
                                }
                            }

                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: grpTxt.implicitWidth + 8
                                radius: 3
                                color: Qt.alpha(p.accent, 0.14)
                                Text {
                                    id: grpTxt
                                    anchors.centerIn: parent
                                    text: "#" + (gIdx + 1)
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: p.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? (modelData.name || "") : ""
                                    font.pixelSize: 12
                                    font.weight: isSel ? Font.Normal : Font.DemiBold
                                    color: p.textPrimary
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? (modelData.dirPath || "") : ""
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: p.textDim
                                    elide: Text.ElideMiddle
                                }
                            }

                            Text {
                                text: modelData ? (modelData.formattedSize || "") : ""
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: p.textSecondary
                            }

                            Text {
                                text: modelData ? (modelData.modified || "") : ""
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: p.textDim
                            }

                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: statusPillTxt.implicitWidth + 10
                                radius: 3
                                color: isSel ? Qt.alpha(p.dangerAccent, 0.16) : Qt.alpha(p.successText, 0.16)
                                Text {
                                    id: statusPillTxt
                                    anchors.centerIn: parent
                                    text: isSel ? qsTr("Trash") : qsTr("Keep")
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: isSel ? p.dangerText : p.successText
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: duplicateFinderDialog.toggleRowSelected(index)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: duplicateFinderDialog.dupItems.length === 0
                    text: qsTr("No duplicate files found for current filter.")
                    font.pixelSize: 12
                    color: p.textDim
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToolbarBtn {
                    label: qsTr("Feed Selected to Panel")
                    btnEnabled: duplicateFinderDialog.selectedCount > 0
                    onClicked: {
                        var paths = duplicateFinderDialog.selectedPaths();
                        if (paths.length > 0) {
                            backend.feedPathsToPanel(paths, qsTr("Duplicates"), false);
                            win.duplicateFinderOpen = false;
                            currentListView().forceActiveFocus();
                        }
                    }
                }

                ToolbarBtn {
                    label: qsTr("Move Selected to Trash")
                    accentHighlight: true
                    btnEnabled: duplicateFinderDialog.selectedCount > 0
                    onClicked: {
                        var paths = duplicateFinderDialog.selectedPaths();
                        if (paths.length > 0 && backend.deleteItems(paths, false))
                            duplicateFinderDialog.runScan();
                    }
                }

                Item { Layout.fillWidth: true }

                ToolbarBtn {
                    label: qsTr("Close")
                    onClicked: duplicateFinderDialog.reject()
                }
            }
        }
    }
}
