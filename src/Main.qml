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
    title: "TwinForge — Dual-Panel File Manager for Linux"
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
    property bool workspacesOpen: false
    property bool settingsOpen: false
    property bool confirmEmptyTrashOpen: false
    property bool commandDrawerOpen: false
    property int cmdHistoryIndex: -1
    property string cmdHistoryDraft: ""
    property bool splitCombineOpen: false
    property string splitSourcePath: ""
    property var splitSourceInfo: ({})
    property real panelSplitRatio: 0.5
    property string openWithTargetPath: ""
    property var openWithAppsList: []
    property var openWithAllApps: []
    property var openWithMimeInfo: ({})
    property int openWithTab: 0
    property bool menuBarActive: false

    // Single source of truth for global keyboard shortcuts (Shortcuts, Toolbar, Menus, Palette, F1 Help).
    readonly property var shortcuts: ({
        commandPalette: "Ctrl+Shift+P",
        quickJump: "Ctrl+P",
        quickView: "Ctrl+Q",
        shortcutsHelp: "?",
        helpF1: "F1",
        view: "F3",
        edit: "F4",
        copy: "F5",
        move: "F6",
        rename: "Shift+F6",
        newFolder: "F7",
        deleteItem: "F8",
        terminal: "F9",
        terminalAlt: "Alt+T",
        exitApp: "F10",
        exitMenu: "Alt+F4",
        newTab: "Ctrl+T",
        closeTab: "Ctrl+W",
        reopenTab: "Ctrl+Shift+W",
        lockTab: "Ctrl+Alt+L",
        nextTab: "Ctrl+Tab",
        prevTab: "Ctrl+Shift+Tab",
        copyClip: "Ctrl+C",
        cutClip: "Ctrl+X",
        pasteClip: "Ctrl+V",
        undo: "Ctrl+Z",
        copyNamesCsv: "Ctrl+Shift+C",
        copyPathsCsv: "Ctrl+Alt+C",
        properties: "Alt+Enter",
        editPath: "Ctrl+L",
        swapPanels: "Ctrl+U",
        syncPanels: "Alt+=",
        compareDirs: "Shift+F2",
        multiRename: "Ctrl+M",
        packArchive: "Alt+F5",
        extractArchive: "Alt+F9",
        calcFolderSizes: "Alt+Shift+Enter",
        goBack: "Alt+Left",
        goForward: "Alt+Right",
        filter: "Ctrl+S",
        bookmarks: "Ctrl+B",
        selectAll: "Ctrl+A",
        deselectAll: "Ctrl+D",
        invertSelection: "Ctrl+Shift+A",
        maskSelect: "Num+",
        maskDeselect: "Num-",
        maskInvert: "Num*",
        findFiles: "Alt+F7",
        diskUsage: "Ctrl+Shift+D",
        syncDirs: "Ctrl+Shift+S",
        duplicateFinder: "Ctrl+Shift+F7",
        operationQueue: "Ctrl+Shift+Q",
        remoteConnections: "Ctrl+Shift+M",
        openWith: "Ctrl+Shift+O",
        showHidden: "Ctrl+H",
        sortName: "Ctrl+F3",
        sortExt: "Ctrl+F4",
        sortDate: "Ctrl+F5",
        sortSize: "Ctrl+F6",
        refresh: "Ctrl+R",
        newFile: "Shift+F4",
        symlink: "Ctrl+Shift+F5",
        diffFiles: "Ctrl+Alt+D",
        viewList: "Ctrl+1",
        viewGrid: "Ctrl+2",
        flatView: "Ctrl+Shift+B",
        themeToggle: "Ctrl+Shift+T",
        workspaces: "Ctrl+Shift+L",
        openTrash: "Ctrl+Shift+Backspace",
        cmdDrawerToggle: "Ctrl+O",
        cmdBarFocus: "Ctrl+E",
        cmdInsertName: "Ctrl+Enter",
        cmdInsertPath: "Ctrl+Shift+Enter",
        splitCombine: "Ctrl+Alt+S",
        settings: "Ctrl+,"
    })

    function formatShortcutDisplay(seq) {
        return (seq || "").replace(/\+/g, " + ");
    }

    function folderDisplayName(dirPath) {
        var raw = (dirPath || "").trim();
        if (raw.length === 0)
            return "/";
        if (raw === "trash://")
            return qsTr("Trash");
        var arcSep = raw.indexOf("::");
        if (arcSep >= 0) {
            var inner = raw.slice(arcSep + 2).replace(/\/+$/, "");
            if (inner.length > 0) {
                var innerParts = inner.split("/");
                var lastInner = innerParts[innerParts.length - 1];
                if (lastInner.length > 0)
                    return lastInner;
            }
            raw = raw.slice(0, arcSep);
        }
        if (raw === "/")
            return "/";
        var stripped = raw.replace(/\/+$/, "");
        if (stripped.length === 0)
            return "/";
        var parts = stripped.split("/");
        return parts[parts.length - 1] || "/";
    }

    function formatDriveChipLabel(d) {
        if (!d)
            return "";
        var lbl = d.label || "";
        if (d.isRemote === true && (d.protocol || "") === "gdrive" && lbl.toLowerCase() === "google drive (gdrive)")
            return "Google Drive";
        return lbl;
    }

    readonly property bool targetIsRight: backend.activePanel === 0
    readonly property string targetPanelPath: targetIsRight ? backend.rightPanel.path : backend.leftPanel.path
    readonly property string targetPanelName: folderDisplayName(targetPanelPath)
    readonly property string f5ActionLabel: targetIsRight
        ? qsTr("Copy to %1 →").arg(targetPanelName)
        : qsTr("← Copy to %1").arg(targetPanelName)
    readonly property string f6ActionLabel: targetIsRight
        ? qsTr("Move to %1 →").arg(targetPanelName)
        : qsTr("← Move to %1").arg(targetPanelName)
    readonly property string f5Tooltip: qsTr("Copy selected items to: %1 (%2)").arg(targetPanelPath).arg(shortcuts.copy)
    readonly property string f6Tooltip: qsTr("Move selected items to: %1 (%2)").arg(targetPanelPath).arg(shortcuts.move)

    Connections {
        target: backend
        function onThemeModeChanged() {
            if (win.quickViewActive)
                win.updateQuickView();
            if (win.previewOpen && win.previewData && win.previewData.path)
                backend.requestPreview(win.previewData.path, win.previewData.pdfPage || 1, "modal");
        }
        function onPreviewReady(target, data) {
            if (target === "quickview") {
                if (win.quickViewActive)
                    win.quickViewData = data || ({});
            } else {
                if (win.previewOpen)
                    win.previewData = data || ({});
            }
        }
        function onChecksumFinished(result) {
            if (win.checksumOpen)
                checksumDialog.hashes = result || ({});
        }
        function onBatchChecksumFinished(result) {
            if (win.checksumOpen)
                checksumDialog.batchResult = result || ({});
        }
        function onSyncCompareResultsChanged() {
            if (win.syncDirsOpen)
                syncDirsDialog.applyCompareResults(backend.syncCompareResults);
        }
        function onDirectorySyncFinished(summary) {
            if (win.syncDirsOpen)
                syncDirsDialog.refreshCompare();
        }
        function onDuplicateResultsChanged() {
            if (win.duplicateFinderOpen)
                duplicateFinderDialog.applyDuplicateResults(backend.duplicateResults);
        }
        function onRemoteOperationFinished(success, mountPath, message) {
            if (success && mountPath && mountPath.length > 0 && win.remoteConnectionsOpen) {
                win.remoteConnectionsOpen = false;
                currentListView().forceActiveFocus();
            }
        }
        function onFocusAndSelectRequested(panelIndex, filePath) {
            backend.activePanel = (panelIndex === 1) ? 1 : 0;
            var m = (panelIndex === 1) ? backend.rightPanel : backend.leftPanel;
            var pane = (panelIndex === 1) ? rightPane : leftPane;
            if (!pane || !m)
                return;
            var idx = m.findIndexByPath(filePath);
            if (idx >= 0 && pane.activeView) {
                pane.activeView.currentIndex = idx;
                if (typeof pane.activeView.positionViewAtIndex === "function")
                    pane.activeView.positionViewAtIndex(idx, ListView.Center);
                pane.activeView.forceActiveFocus();
            }
        }
        function onWindowActivateRequested() {
            win.raise();
            win.requestActivate();
        }
    }

    function isAnyMenuOpen() {
        return (typeof filesMenu !== "undefined" && filesMenu.visible) ||
               (typeof editMenu !== "undefined" && editMenu.visible) ||
               (typeof viewMenu !== "undefined" && viewMenu.visible) ||
               (typeof commandsMenu !== "undefined" && commandsMenu.visible) ||
               (typeof helpMenu !== "undefined" && helpMenu.visible) ||
               (typeof bookmarksOverflowMenu !== "undefined" && bookmarksOverflowMenu.visible) ||
               (typeof leftPane !== "undefined" && leftPane.contextMenu && leftPane.contextMenu.visible) ||
               (typeof rightPane !== "undefined" && rightPane.contextMenu && rightPane.contextMenu.visible);
    }

    function closeAllMenus() {
        if (typeof filesMenu !== "undefined") filesMenu.close();
        if (typeof editMenu !== "undefined") editMenu.close();
        if (typeof viewMenu !== "undefined") viewMenu.close();
        if (typeof commandsMenu !== "undefined") commandsMenu.close();
        if (typeof helpMenu !== "undefined") helpMenu.close();
        if (typeof bookmarksOverflowMenu !== "undefined") bookmarksOverflowMenu.close();
        if (typeof leftPane !== "undefined" && leftPane.contextMenu) leftPane.contextMenu.close();
        if (typeof rightPane !== "undefined" && rightPane.contextMenu) rightPane.contextMenu.close();
        win.menuBarActive = false;
    }

    // ================= REUSABLE INLINE UI COMPONENTS =================

    // 2026 Multi-Tone Glossy/Gradient HD SVG Vector Icon (4x HiDPI supersampled).
    component VectorIcon : Item {
        id: iconRoot
        property string kind: "file"
        property color iconColor: p.iconDefault
        readonly property alias status: iconImg.status
        readonly property alias sourceSize: iconImg.sourceSize
        readonly property alias source: iconImg.source
        implicitWidth: 16
        implicitHeight: 16
        width: implicitWidth
        height: implicitHeight

        readonly property var multiToneTemplates: ({
            "folder": "<defs><linearGradient id=\"gb\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#F59E0B\"/><stop offset=\"100%\" stop-color=\"#B45309\"/></linearGradient><linearGradient id=\"gf\" x1=\"0\" y1=\"0\" x2=\"0.2\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FDE047\"/><stop offset=\"45%\" stop-color=\"#FBBF24\"/><stop offset=\"100%\" stop-color=\"#D97706\"/></linearGradient></defs><path d=\"M2.5 6.2A2.2 2.2 0 0 1 4.7 4h4.1c.6 0 1.2.3 1.6.8l1.2 1.4h7.7A2.2 2.2 0 0 1 21.5 8.4v2H2.5Z\" fill=\"url(#gb)\"/><rect x=\"2.5\" y=\"7.5\" width=\"19\" height=\"12.5\" rx=\"2.4\" fill=\"url(#gf)\"/><path d=\"M4.6 8.2h14.8\" stroke=\"#FFFFFF\" stroke-opacity=\"0.48\" stroke-width=\"1\"/>",
            "parent": "<defs><linearGradient id=\"gp\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#818CF8\"/><stop offset=\"100%\" stop-color=\"#4F46E5\"/></linearGradient></defs><rect x=\"2.5\" y=\"2.5\" width=\"19\" height=\"19\" rx=\"5\" fill=\"url(#gp)\" fill-opacity=\"0.20\" stroke=\"url(#gp)\" stroke-width=\"1.4\" stroke-opacity=\"0.55\"/><path d=\"M16.5 16v-2.8A3.7 3.7 0 0 0 12.8 9.5H7.5\" stroke=\"url(#gp)\" stroke-width=\"2.1\"/><polyline points=\"10.5 6.3 7.2 9.5 10.5 12.7\" stroke=\"url(#gp)\" stroke-width=\"2.1\"/>",
            "pdf": "<defs><linearGradient id=\"gr\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FB7185\"/><stop offset=\"100%\" stop-color=\"#E11D48\"/></linearGradient></defs><path d=\"M5.5 2.5h8.2L19 7.8v11.7a2 2 0 0 1-2 2H5.5a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2Z\" fill=\"url(#gr)\"/><path d=\"M13.7 2.5v3.8a1.5 1.5 0 0 0 1.5 1.5H19Z\" fill=\"#FFFFFF\" fill-opacity=\"0.42\"/><rect x=\"6\" y=\"13\" width=\"10.5\" height=\"4.8\" rx=\"1.2\" fill=\"#FFFFFF\" fill-opacity=\"0.92\"/><path d=\"M7.6 14.3h1.5a.8.8 0 0 1 0 1.6H7.6v.9m3.1-2.5h1a1.1 1.1 0 0 1 0 2.5h-1v-2.5m3.3 2.5v-2.5h1.5m-1.5 1.2h1.1\" stroke=\"#E11D48\" stroke-width=\"1.15\"/>",
            "markdown": "<defs><linearGradient id=\"gm\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#0284C7\"/></linearGradient></defs><rect x=\"3\" y=\"3.5\" width=\"18\" height=\"17\" rx=\"3\" fill=\"url(#gm)\"/><path d=\"M6.2 15V9l2.4 2.9L11 9v6\" stroke=\"#FFFFFF\" stroke-width=\"1.7\"/><path d=\"M15.8 9v5.5m0 0-2-2m2 2 2-2\" stroke=\"#FFFFFF\" stroke-width=\"1.7\"/>",
            "sheet": "<defs><linearGradient id=\"gs\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"100%\" stop-color=\"#059669\"/></linearGradient></defs><rect x=\"3.5\" y=\"2.5\" width=\"17\" height=\"19\" rx=\"2.6\" fill=\"url(#gs)\"/><rect x=\"6.2\" y=\"6.5\" width=\"11.6\" height=\"11\" rx=\"1.4\" fill=\"#FFFFFF\" fill-opacity=\"0.22\" stroke=\"#FFFFFF\" stroke-width=\"1.3\"/><line x1=\"6.2\" y1=\"10.5\" x2=\"17.8\" y2=\"10.5\" stroke=\"#FFFFFF\" stroke-width=\"1.2\"/><line x1=\"6.2\" y1=\"14\" x2=\"17.8\" y2=\"14\" stroke=\"#FFFFFF\" stroke-width=\"1.2\"/><line x1=\"11.2\" y1=\"6.5\" x2=\"11.2\" y2=\"17.5\" stroke=\"#FFFFFF\" stroke-width=\"1.2\"/>",
            "doc": "<defs><linearGradient id=\"gd\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#60A5FA\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient></defs><path d=\"M5.5 2.5h8.2L19 7.8v11.7a2 2 0 0 1-2 2H5.5a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2Z\" fill=\"url(#gd)\"/><path d=\"M13.7 2.5v3.8a1.5 1.5 0 0 0 1.5 1.5H19Z\" fill=\"#FFFFFF\" fill-opacity=\"0.42\"/><path d=\"M7 11.2h8.5M7 14.4h8.5M7 17.6h5.5\" stroke=\"#FFFFFF\" stroke-width=\"1.6\" stroke-opacity=\"0.92\"/>",
            "config": "<defs><linearGradient id=\"gcfg\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#C084FC\"/><stop offset=\"100%\" stop-color=\"#7C3AED\"/></linearGradient></defs><rect x=\"3\" y=\"3\" width=\"18\" height=\"18\" rx=\"4\" fill=\"url(#gcfg)\"/><path d=\"M9.2 7.5c-1 0-1.4.5-1.4 1.4v1.7c0 .7-.4 1.2-1 1.4.6.2 1 .7 1 1.4v1.7c0 .9.4 1.4 1.4 1.4M14.8 7.5c1 0 1.4.5 1.4 1.4v1.7c0 .7.4 1.2 1 1.4-.6.2-1 .7-1 1.4v1.7c0 .9-.4 1.4-1.4 1.4\" stroke=\"#FFFFFF\" stroke-width=\"1.6\"/><circle cx=\"12\" cy=\"12\" r=\"1.3\" fill=\"#FDE047\" stroke=\"none\"/>",
            "script": "<defs><linearGradient id=\"gsh\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#10B981\"/><stop offset=\"100%\" stop-color=\"#047857\"/></linearGradient></defs><rect x=\"2.5\" y=\"3.5\" width=\"19\" height=\"17\" rx=\"3.2\" fill=\"url(#gsh)\"/><rect x=\"4.3\" y=\"5.3\" width=\"15.4\" height=\"13.4\" rx=\"2\" fill=\"#022C22\" fill-opacity=\"0.48\"/><polyline points=\"7 9.5 10 12 7 14.5\" stroke=\"#6EE7B7\" stroke-width=\"1.9\"/><line x1=\"11.8\" y1=\"14.8\" x2=\"16.5\" y2=\"14.8\" stroke=\"#FFFFFF\" stroke-width=\"1.9\"/>",
            "database": "<defs><linearGradient id=\"gdb\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FBBF24\"/><stop offset=\"100%\" stop-color=\"#B45309\"/></linearGradient></defs><path d=\"M4.5 6.5v11c0 1.7 3.4 3 7.5 3s7.5-1.3 7.5-3v-11Z\" fill=\"url(#gdb)\"/><ellipse cx=\"12\" cy=\"6.5\" rx=\"7.5\" ry=\"2.8\" fill=\"#FDE68A\" stroke=\"#F59E0B\" stroke-width=\"0.9\"/><path d=\"M4.5 12c0 1.6 3.4 2.8 7.5 2.8s7.5-1.2 7.5-2.8\" stroke=\"#FFFFFF\" stroke-opacity=\"0.55\" stroke-width=\"1.3\"/>",
            "font": "<defs><linearGradient id=\"gfnt\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#22D3EE\"/><stop offset=\"100%\" stop-color=\"#0891B2\"/></linearGradient></defs><rect x=\"3\" y=\"3\" width=\"18\" height=\"18\" rx=\"3.5\" fill=\"url(#gfnt)\"/><path d=\"M6.2 16.5 9.6 7.5h.8l3.4 9M7.4 13.8h5.2\" stroke=\"#FFFFFF\" stroke-width=\"1.7\"/><circle cx=\"17\" cy=\"14.5\" r=\"2.1\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/><line x1=\"19.1\" y1=\"12.2\" x2=\"19.1\" y2=\"16.6\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>",
            "lock": "<defs><linearGradient id=\"glk\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FDE047\"/><stop offset=\"100%\" stop-color=\"#D97706\"/></linearGradient></defs><path d=\"M7.5 10.5V7.8a4.5 4.5 0 0 1 9 0v2.7\" stroke=\"#CBD5E1\" stroke-width=\"2.2\"/><rect x=\"4.5\" y=\"10\" width=\"15\" height=\"11\" rx=\"2.8\" fill=\"url(#glk)\"/><circle cx=\"12\" cy=\"14.8\" r=\"1.5\" fill=\"#451A03\" stroke=\"none\"/><path d=\"M12 16v2\" stroke=\"#451A03\" stroke-width=\"1.6\"/>",
            "code": "<defs><linearGradient id=\"gc\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"55%\" stop-color=\"#2563EB\"/><stop offset=\"100%\" stop-color=\"#1D4ED8\"/></linearGradient></defs><rect x=\"2.5\" y=\"3.5\" width=\"19\" height=\"17\" rx=\"3.2\" fill=\"url(#gc)\"/><polyline points=\"8.5 9 5.5 12 8.5 15\" stroke=\"#FFFFFF\" stroke-width=\"1.9\"/><polyline points=\"15.5 9 18.5 12 15.5 15\" stroke=\"#FFFFFF\" stroke-width=\"1.9\"/><line x1=\"13.3\" y1=\"7.8\" x2=\"10.7\" y2=\"16.2\" stroke=\"#BAE6FD\" stroke-width=\"1.8\"/>",
            "archive": "<defs><linearGradient id=\"ga\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FB923C\"/><stop offset=\"100%\" stop-color=\"#C2410C\"/></linearGradient></defs><rect x=\"3.5\" y=\"3\" width=\"17\" height=\"18\" rx=\"3\" fill=\"url(#ga)\"/><path d=\"M3.5 8h17\" stroke=\"#FFFFFF\" stroke-opacity=\"0.42\" stroke-width=\"1.2\"/><path d=\"M12 3v9.5\" stroke=\"#FFFFFF\" stroke-width=\"1.6\" stroke-dasharray=\"1.8 1.4\"/><rect x=\"9.6\" y=\"12.5\" width=\"4.8\" height=\"5\" rx=\"1.2\" fill=\"#FFFFFF\" fill-opacity=\"0.92\"/><circle cx=\"12\" cy=\"15.5\" r=\"0.9\" fill=\"#C2410C\" stroke=\"none\"/>",
            "image": "<defs><linearGradient id=\"gi\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#2DD4BF\"/><stop offset=\"55%\" stop-color=\"#0EA5E9\"/><stop offset=\"100%\" stop-color=\"#6366F1\"/></linearGradient></defs><rect x=\"2.5\" y=\"3.5\" width=\"19\" height=\"17\" rx=\"3\" fill=\"url(#gi)\"/><circle cx=\"8\" cy=\"8.8\" r=\"2\" fill=\"#FDE047\" stroke=\"none\"/><path d=\"M3.2 18.8 8.8 13a1.2 1.2 0 0 1 1.7 0l2.8 2.8 2.4-2.5a1.2 1.2 0 0 1 1.7 0l3.4 3.6v2.1a1.5 1.5 0 0 1-1.5 1.5H4.7a1.5 1.5 0 0 1-1.5-1.5Z\" fill=\"#FFFFFF\" fill-opacity=\"0.90\"/>",
            "video": "<defs><linearGradient id=\"gv\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#F472B6\"/><stop offset=\"100%\" stop-color=\"#9333EA\"/></linearGradient></defs><rect x=\"2.5\" y=\"4\" width=\"19\" height=\"16\" rx=\"3.4\" fill=\"url(#gv)\"/><rect x=\"4\" y=\"5.5\" width=\"16\" height=\"2.2\" rx=\"1\" fill=\"#FFFFFF\" fill-opacity=\"0.28\"/><polygon points=\"10 9.6 16.2 13 10 16.4\" fill=\"#FFFFFF\" stroke=\"#FFFFFF\" stroke-width=\"1.2\" stroke-linejoin=\"round\"/>",
            "audio": "<defs><linearGradient id=\"gau\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FB7185\"/><stop offset=\"100%\" stop-color=\"#EA580C\"/></linearGradient></defs><rect x=\"3\" y=\"3\" width=\"18\" height=\"18\" rx=\"4.5\" fill=\"url(#gau)\"/><circle cx=\"8.5\" cy=\"16\" r=\"2.1\" fill=\"#FFFFFF\" stroke=\"none\"/><circle cx=\"15.5\" cy=\"14.5\" r=\"2.1\" fill=\"#FFFFFF\" stroke=\"none\"/><path d=\"M10.1 16V8.2l6.9-1.5V14.5\" stroke=\"#FFFFFF\" stroke-width=\"1.7\"/>",
            "binary": "<defs><linearGradient id=\"gbin\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#64748B\"/><stop offset=\"100%\" stop-color=\"#334155\"/></linearGradient></defs><path d=\"M9 2.5v2M15 2.5v2M9 19.5v2M15 19.5v2M2.5 9h2M2.5 15h2M19.5 9h2M19.5 15h2\" stroke=\"#94A3B8\" stroke-width=\"1.6\"/><rect x=\"4.5\" y=\"4.5\" width=\"15\" height=\"15\" rx=\"2.6\" fill=\"url(#gbin)\"/><rect x=\"8\" y=\"8\" width=\"8\" height=\"8\" rx=\"1.4\" fill=\"#38BDF8\" fill-opacity=\"0.9\"/>",
            "drive": "<defs><linearGradient id=\"gdrv\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#CBD5E1\"/><stop offset=\"100%\" stop-color=\"#475569\"/></linearGradient></defs><rect x=\"2.5\" y=\"5\" width=\"19\" height=\"14\" rx=\"3\" fill=\"url(#gdrv)\"/><rect x=\"3.8\" y=\"13.5\" width=\"16.4\" height=\"4.2\" rx=\"1.4\" fill=\"#1E293B\" fill-opacity=\"0.85\"/><circle cx=\"17.2\" cy=\"15.6\" r=\"1.2\" fill=\"#34D399\" stroke=\"none\"/><line x1=\"6.2\" y1=\"15.6\" x2=\"11.5\" y2=\"15.6\" stroke=\"#94A3B8\" stroke-width=\"1.5\"/>",
            "usb": "<defs><linearGradient id=\"gusb\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient></defs><rect x=\"7\" y=\"2.5\" width=\"10\" height=\"5\" rx=\"1\" fill=\"#CBD5E1\"/><rect x=\"5.5\" y=\"7\" width=\"13\" height=\"14\" rx=\"3\" fill=\"url(#gusb)\"/><circle cx=\"10\" cy=\"5\" r=\"0.8\" fill=\"#475569\" stroke=\"none\"/><circle cx=\"14\" cy=\"5\" r=\"0.8\" fill=\"#475569\" stroke=\"none\"/><path d=\"M9 12.5h6M12 10v6\" stroke=\"#FFFFFF\" stroke-opacity=\"0.85\" stroke-width=\"1.6\"/>",
            "cloud": "<defs><linearGradient id=\"gcld\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"50%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#3B82F6\"/></linearGradient></defs><path d=\"M6.8 18.8h10.4a4.2 4.2 0 0 0 .8-8.32A5.8 5.8 0 0 0 6.7 9 4 4 0 0 0 6.8 18.8Z\" fill=\"url(#gcld)\"/><path d=\"M7.5 11.2a4.6 4.6 0 0 1 8.4-1.3\" stroke=\"#FFFFFF\" stroke-opacity=\"0.55\" stroke-width=\"1.3\"/>",
            "network": "<defs><linearGradient id=\"gnet\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#4F46E5\"/></linearGradient></defs><circle cx=\"12\" cy=\"12\" r=\"9\" fill=\"url(#gnet)\"/><ellipse cx=\"12\" cy=\"12\" rx=\"4\" ry=\"9\" stroke=\"#FFFFFF\" stroke-opacity=\"0.78\" stroke-width=\"1.35\"/><line x1=\"3.4\" y1=\"12\" x2=\"20.6\" y2=\"12\" stroke=\"#FFFFFF\" stroke-opacity=\"0.78\" stroke-width=\"1.35\"/><path d=\"M5.5 7.5h13M5.5 16.5h13\" stroke=\"#FFFFFF\" stroke-opacity=\"0.42\" stroke-width=\"1.1\"/>",
            "sun": "<defs><linearGradient id=\"gsun\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FEF08A\"/><stop offset=\"100%\" stop-color=\"#F59E0B\"/></linearGradient></defs><circle cx=\"12\" cy=\"12\" r=\"4.8\" fill=\"url(#gsun)\"/><path d=\"M12 2.4v2.3M12 19.3v2.3M4.9 4.9l1.7 1.7M17.4 17.4l1.7 1.7M2.4 12h2.3M19.3 12h2.3M4.9 19.1l1.7-1.7M17.4 6.6l1.7-1.7\" stroke=\"#FBBF24\" stroke-width=\"2\"/>",
            "moon": "<defs><linearGradient id=\"gmn\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#E0E7FF\"/><stop offset=\"100%\" stop-color=\"#6366F1\"/></linearGradient></defs><path d=\"M19.8 14.2A7.8 7.8 0 0 1 9.8 4.2a7.8 7.8 0 1 0 10 10Z\" fill=\"url(#gmn)\"/><circle cx=\"17.5\" cy=\"6.5\" r=\"1.1\" fill=\"#FDE047\" stroke=\"none\"/><circle cx=\"14.5\" cy=\"4.5\" r=\"0.7\" fill=\"#E0E7FF\" stroke=\"none\"/>",
            "star-filled": "<defs><linearGradient id=\"gst\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FEF08A\"/><stop offset=\"50%\" stop-color=\"#FBBF24\"/><stop offset=\"100%\" stop-color=\"#D97706\"/></linearGradient></defs><polygon points=\"12 2.8 14.9 8.6 21.3 9.5 16.6 14 17.7 20.4 12 17.4 6.3 20.4 7.4 14 2.7 9.5 9.1 8.6\" fill=\"url(#gst)\"/>",
            "star": "<defs><linearGradient id=\"gsto\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FDE047\"/><stop offset=\"100%\" stop-color=\"#F59E0B\"/></linearGradient></defs><polygon points=\"12 3 14.8 8.7 21 9.6 16.5 14 17.6 20.2 12 17.2 6.4 20.2 7.5 14 3 9.6 9.2 8.7\" fill=\"url(#gsto)\" fill-opacity=\"0.20\" stroke=\"url(#gsto)\" stroke-width=\"1.8\"/>",
            "home": "<defs><linearGradient id=\"ghm\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient><linearGradient id=\"ghr\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0%\" stop-color=\"#FB7185\"/><stop offset=\"100%\" stop-color=\"#F59E0B\"/></linearGradient></defs><path d=\"M4.5 10.6V19a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-8.4L12 4.6Z\" fill=\"url(#ghm)\"/><path d=\"M2.5 11.2 12 3.5l9.5 7.7\" stroke=\"url(#ghr)\" stroke-width=\"2.3\"/><rect x=\"9.6\" y=\"13.6\" width=\"4.8\" height=\"7.4\" rx=\"1.3\" fill=\"#FEF08A\"/>",
            "chart": "<defs><linearGradient id=\"gc1\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"100%\" stop-color=\"#059669\"/></linearGradient><linearGradient id=\"gc2\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient><linearGradient id=\"gc3\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FBBF24\"/><stop offset=\"100%\" stop-color=\"#EA580C\"/></linearGradient></defs><rect x=\"3.4\" y=\"12.2\" width=\"4.6\" height=\"8.3\" rx=\"1.4\" fill=\"url(#gc1)\"/><rect x=\"9.7\" y=\"3.8\" width=\"4.6\" height=\"16.7\" rx=\"1.4\" fill=\"url(#gc2)\"/><rect x=\"16\" y=\"8.2\" width=\"4.6\" height=\"12.3\" rx=\"1.4\" fill=\"url(#gc3)\"/>",
            "filter": "<defs><linearGradient id=\"gflt\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#C084FC\"/><stop offset=\"100%\" stop-color=\"#7C3AED\"/></linearGradient></defs><path d=\"M3.2 4.8a1 1 0 0 1 .8-.4h16a1 1 0 0 1 .76 1.65l-6.16 7.2v5.45a1 1 0 0 1-.56.9l-3.2 1.55a1 1 0 0 1-1.44-.9v-7L3.24 6.05a1 1 0 0 1-.04-1.25Z\" fill=\"url(#gflt)\"/><path d=\"M6.2 6.8h11.6\" stroke=\"#FFFFFF\" stroke-opacity=\"0.48\" stroke-width=\"1.4\"/>",
            "branch": "<defs><linearGradient id=\"gbr\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"100%\" stop-color=\"#0D9488\"/></linearGradient></defs><path d=\"M7 8v8M17 10.2a5.2 5.2 0 0 1-5.2 5.2H7\" stroke=\"url(#gbr)\" stroke-width=\"2.2\"/><circle cx=\"7\" cy=\"5.6\" r=\"2.6\" fill=\"#34D399\"/><circle cx=\"17\" cy=\"8\" r=\"2.6\" fill=\"#38BDF8\"/><circle cx=\"7\" cy=\"18.4\" r=\"2.6\" fill=\"#10B981\"/>",
            "refresh": "<defs><linearGradient id=\"grf\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#22D3EE\"/><stop offset=\"100%\" stop-color=\"#0284C7\"/></linearGradient></defs><path d=\"M19.8 11.4a7.8 7.8 0 1 0 1.3 4.4\" stroke=\"url(#grf)\" stroke-width=\"2.2\"/><polygon points=\"21.2 4.2 21.2 10.2 15.2 10.2\" fill=\"#22D3EE\" stroke=\"none\"/>",
            "grid": "<defs><linearGradient id=\"ggr1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#60A5FA\"/><stop offset=\"100%\" stop-color=\"#4F46E5\"/></linearGradient><linearGradient id=\"ggr2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#0284C7\"/></linearGradient></defs><rect x=\"3.2\" y=\"3.2\" width=\"7.6\" height=\"7.6\" rx=\"2.1\" fill=\"url(#ggr1)\"/><rect x=\"13.2\" y=\"3.2\" width=\"7.6\" height=\"7.6\" rx=\"2.1\" fill=\"url(#ggr2)\"/><rect x=\"3.2\" y=\"13.2\" width=\"7.6\" height=\"7.6\" rx=\"2.1\" fill=\"url(#ggr2)\"/><rect x=\"13.2\" y=\"13.2\" width=\"7.6\" height=\"7.6\" rx=\"2.1\" fill=\"url(#ggr1)\"/>",
            "list": "<defs><linearGradient id=\"glst\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#6366F1\"/></linearGradient></defs><rect x=\"3.4\" y=\"4.9\" width=\"3.2\" height=\"3.2\" rx=\"1\" fill=\"#38BDF8\" stroke=\"none\"/><line x1=\"9\" y1=\"6.5\" x2=\"20.4\" y2=\"6.5\" stroke=\"url(#glst)\" stroke-width=\"2.3\"/><rect x=\"3.4\" y=\"10.4\" width=\"3.2\" height=\"3.2\" rx=\"1\" fill=\"#818CF8\" stroke=\"none\"/><line x1=\"9\" y1=\"12\" x2=\"20.4\" y2=\"12\" stroke=\"url(#glst)\" stroke-width=\"2.3\"/><rect x=\"3.4\" y=\"15.9\" width=\"3.2\" height=\"3.2\" rx=\"1\" fill=\"#34D399\" stroke=\"none\"/><line x1=\"9\" y1=\"17.5\" x2=\"20.4\" y2=\"17.5\" stroke=\"url(#glst)\" stroke-width=\"2.3\"/>",
            "back": "<defs><linearGradient id=\"gbk\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#60A5FA\"/><stop offset=\"100%\" stop-color=\"#4F46E5\"/></linearGradient></defs><circle cx=\"12\" cy=\"12\" r=\"9.2\" fill=\"url(#gbk)\" fill-opacity=\"0.16\" stroke=\"url(#gbk)\" stroke-width=\"1.2\" stroke-opacity=\"0.45\"/><path d=\"M14.2 7.2 9.4 12l4.8 4.8\" stroke=\"url(#gbk)\" stroke-width=\"2.3\"/>",
            "forward": "<defs><linearGradient id=\"gfw\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#60A5FA\"/><stop offset=\"100%\" stop-color=\"#4F46E5\"/></linearGradient></defs><circle cx=\"12\" cy=\"12\" r=\"9.2\" fill=\"url(#gfw)\" fill-opacity=\"0.16\" stroke=\"url(#gfw)\" stroke-width=\"1.2\" stroke-opacity=\"0.45\"/><path d=\"M9.8 7.2 14.6 12l-4.8 4.8\" stroke=\"url(#gfw)\" stroke-width=\"2.3\"/>",
            "up": "<defs><linearGradient id=\"gup\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#6366F1\"/></linearGradient></defs><circle cx=\"12\" cy=\"12\" r=\"9.2\" fill=\"url(#gup)\" fill-opacity=\"0.16\" stroke=\"url(#gup)\" stroke-width=\"1.2\" stroke-opacity=\"0.45\"/><path d=\"M12 16.8V7.6M7.8 11.4 12 7.2l4.2 4.2\" stroke=\"url(#gup)\" stroke-width=\"2.2\"/>",
            "copy": "<defs><linearGradient id=\"gcpy\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#60A5FA\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient></defs><rect x=\"3.4\" y=\"3.2\" width=\"11.4\" height=\"13\" rx=\"2.3\" fill=\"#93C5FD\" fill-opacity=\"0.45\" stroke=\"#60A5FA\" stroke-width=\"1.3\"/><rect x=\"8.6\" y=\"7.6\" width=\"11.8\" height=\"13.2\" rx=\"2.3\" fill=\"url(#gcpy)\"/><line x1=\"11.4\" y1=\"12.2\" x2=\"17.6\" y2=\"12.2\" stroke=\"#FFFFFF\" stroke-opacity=\"0.85\" stroke-width=\"1.5\"/><line x1=\"11.4\" y1=\"15.6\" x2=\"15.8\" y2=\"15.6\" stroke=\"#FFFFFF\" stroke-opacity=\"0.75\" stroke-width=\"1.5\"/>",
            "trash": "<defs><linearGradient id=\"gtr\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FB7185\"/><stop offset=\"100%\" stop-color=\"#E11D48\"/></linearGradient></defs><path d=\"M9 6.5V4.8a1.3 1.3 0 0 1 1.3-1.3h3.4A1.3 1.3 0 0 1 15 4.8v1.7\" stroke=\"#FB7185\" stroke-width=\"1.8\"/><rect x=\"4.2\" y=\"6\" width=\"15.6\" height=\"2.4\" rx=\"1.2\" fill=\"#F43F5E\"/><path d=\"M6.2 8.4l1.1 11a2 2 0 0 0 2 1.8h5.4a2 2 0 0 0 2-1.8l1.1-11Z\" fill=\"url(#gtr)\"/><line x1=\"10\" y1=\"11.4\" x2=\"10\" y2=\"17.6\" stroke=\"#FFFFFF\" stroke-opacity=\"0.82\" stroke-width=\"1.6\"/><line x1=\"14\" y1=\"11.4\" x2=\"14\" y2=\"17.6\" stroke=\"#FFFFFF\" stroke-opacity=\"0.82\" stroke-width=\"1.6\"/>",
            "workspace": "<defs><linearGradient id=\"gws1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient><linearGradient id=\"gws2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#C084FC\"/><stop offset=\"100%\" stop-color=\"#7C3AED\"/></linearGradient><linearGradient id=\"gws3\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"100%\" stop-color=\"#059669\"/></linearGradient></defs><rect x=\"3\" y=\"3.8\" width=\"8.2\" height=\"16.4\" rx=\"2.2\" fill=\"url(#gws1)\"/><rect x=\"13\" y=\"3.8\" width=\"8\" height=\"7.4\" rx=\"2.2\" fill=\"url(#gws2)\"/><rect x=\"13\" y=\"12.8\" width=\"8\" height=\"7.4\" rx=\"2.2\" fill=\"url(#gws3)\"/>",
            "sync": "<defs><linearGradient id=\"gsy1\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0%\" stop-color=\"#38BDF8\"/><stop offset=\"100%\" stop-color=\"#2563EB\"/></linearGradient><linearGradient id=\"gsy2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"0\"><stop offset=\"0%\" stop-color=\"#34D399\"/><stop offset=\"100%\" stop-color=\"#059669\"/></linearGradient></defs><path d=\"M19.5 8H6l3.4-3.4\" stroke=\"url(#gsy1)\" stroke-width=\"2.2\"/><path d=\"M4.5 16H18l-3.4 3.4\" stroke=\"url(#gsy2)\" stroke-width=\"2.2\"/>",
            "duplicate": "<defs><linearGradient id=\"gdup\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#F472B6\"/><stop offset=\"100%\" stop-color=\"#9333EA\"/></linearGradient></defs><rect x=\"3.2\" y=\"3\" width=\"11.6\" height=\"13.2\" rx=\"2.4\" fill=\"#C084FC\" fill-opacity=\"0.42\" stroke=\"#A855F7\" stroke-width=\"1.3\"/><rect x=\"8.8\" y=\"7.6\" width=\"11.8\" height=\"13.4\" rx=\"2.4\" fill=\"url(#gdup)\"/>",
            "command": "<defs><linearGradient id=\"gcmd\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#334155\"/><stop offset=\"100%\" stop-color=\"#0F172A\"/></linearGradient></defs><rect x=\"2.6\" y=\"3.8\" width=\"18.8\" height=\"16.4\" rx=\"3.4\" fill=\"url(#gcmd)\" stroke=\"#475569\" stroke-width=\"1.1\"/><path d=\"M7 9.4 10.4 12 7 14.6\" stroke=\"#34D399\" stroke-width=\"2.1\"/><line x1=\"12.2\" y1=\"14.6\" x2=\"16.8\" y2=\"14.6\" stroke=\"#38BDF8\" stroke-width=\"2.1\"/>",
            "eject": "<defs><linearGradient id=\"gej\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0%\" stop-color=\"#FB923C\"/><stop offset=\"100%\" stop-color=\"#EA580C\"/></linearGradient></defs><polygon points=\"12 5 19.2 13.6 4.8 13.6\" fill=\"url(#gej)\"/><rect x=\"4.8\" y=\"16.2\" width=\"14.4\" height=\"2.8\" rx=\"1.4\" fill=\"url(#gej)\"/>"
        })

        readonly property var actionTemplates: ({
            "file": "<path d=\"M5.5 2.5h8.2L19 7.8v11.7a2 2 0 0 1-2 2H5.5a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2Z\" fill=\"{C}\" fill-opacity=\"{FA}\"/><path d=\"M13.7 2.5v3.8a1.5 1.5 0 0 0 1.5 1.5H19\" fill=\"{C}\" fill-opacity=\"0.28\"/><line x1=\"7.5\" y1=\"12.5\" x2=\"15\" y2=\"12.5\" stroke-opacity=\"0.78\"/><line x1=\"7.5\" y1=\"16.2\" x2=\"12.2\" y2=\"16.2\" stroke-opacity=\"0.65\"/>",
            "eject": "<polygon points=\"12 5.5 19.2 13.5 4.8 13.5\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"5\" y=\"16.5\" width=\"14\" height=\"2.4\" rx=\"1.2\" fill=\"{C}\" stroke=\"none\"/>",
            "grid": "<rect x=\"3.5\" y=\"3.5\" width=\"7.2\" height=\"7.2\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"13.3\" y=\"3.5\" width=\"7.2\" height=\"7.2\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"3.5\" y=\"13.3\" width=\"7.2\" height=\"7.2\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"13.3\" y=\"13.3\" width=\"7.2\" height=\"7.2\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/>",
            "list": "<rect x=\"3.8\" y=\"5.3\" width=\"2.6\" height=\"2.6\" rx=\"0.9\" fill=\"{C}\" stroke=\"none\"/><line x1=\"8.8\" y1=\"6.6\" x2=\"20\" y2=\"6.6\" stroke-width=\"2\"/><rect x=\"3.8\" y=\"10.7\" width=\"2.6\" height=\"2.6\" rx=\"0.9\" fill=\"{C}\" stroke=\"none\"/><line x1=\"8.8\" y1=\"12\" x2=\"20\" y2=\"12\" stroke-width=\"2\"/><rect x=\"3.8\" y=\"16.1\" width=\"2.6\" height=\"2.6\" rx=\"0.9\" fill=\"{C}\" stroke=\"none\"/><line x1=\"8.8\" y1=\"17.4\" x2=\"20\" y2=\"17.4\" stroke-width=\"2\"/>",
            "back": "<path d=\"M14.8 5 7.8 12l7 7\" stroke-width=\"2.2\"/>",
            "forward": "<path d=\"M9.2 5l7 7-7 7\" stroke-width=\"2.2\"/>",
            "up": "<path d=\"M12 19.2V5\" stroke-width=\"2.1\"/><path d=\"M6.5 10.5 12 4.8l5.5 5.7\" stroke-width=\"2.1\"/>",
            "home": "<path d=\"M3.5 10.6 12 3.8l8.5 6.8V19a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2Z\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"9.4\" y=\"13.2\" width=\"5.2\" height=\"7.8\" rx=\"1.3\" fill=\"{C}\" fill-opacity=\"0.32\"/>",
            "filter": "<path d=\"M3.5 5.2h17l-6.4 7.4v5.3l-4.2 1.9v-7.2Z\" fill=\"{C}\" fill-opacity=\"{FA}\"/>",
            "refresh": "<path d=\"M20.2 11.4a8.2 8.2 0 1 0 1.4 4.6\" stroke-width=\"2\"/><polygon points=\"21 4.2 21 9.8 15.4 9.8\" fill=\"{C}\" stroke=\"none\"/>",
            "close": "<path d=\"M6.2 6.2l11.6 11.6M17.8 6.2 6.2 17.8\" stroke-width=\"2.1\"/>",
            "star": "<polygon points=\"12 3 14.8 8.7 21 9.6 16.5 14 17.6 20.2 12 17.2 6.4 20.2 7.5 14 3 9.6 9.2 8.7\"/>",
            "branch": "<circle cx=\"7\" cy=\"5.8\" r=\"2.2\" fill=\"{C}\" fill-opacity=\"0.35\"/><circle cx=\"17\" cy=\"8.2\" r=\"2.2\" fill=\"{C}\" fill-opacity=\"0.35\"/><circle cx=\"7\" cy=\"18.2\" r=\"2.2\" fill=\"{C}\" fill-opacity=\"0.35\"/><path d=\"M7 8v8M17 10.4a5 5 0 0 1-5 5H7\" stroke-width=\"2\"/>",
            "command": "<rect x=\"2.8\" y=\"4\" width=\"18.4\" height=\"16\" rx=\"3.4\" fill=\"{C}\" fill-opacity=\"{FA}\"/><path d=\"M7.4 9.3 10.6 12l-3.2 2.7\" stroke-width=\"2\"/><line x1=\"12.4\" y1=\"14.7\" x2=\"16.6\" y2=\"14.7\" stroke-width=\"2\"/>",
            "chart": "<rect x=\"3.8\" y=\"12.8\" width=\"4.2\" height=\"7.4\" rx=\"1.2\" fill=\"{C}\" fill-opacity=\"0.42\"/><rect x=\"9.9\" y=\"4.2\" width=\"4.2\" height=\"16\" rx=\"1.2\" fill=\"{C}\" fill-opacity=\"0.78\"/><rect x=\"16\" y=\"8.6\" width=\"4.2\" height=\"11.6\" rx=\"1.2\" fill=\"{C}\" fill-opacity=\"0.55\"/>",
            "sync": "<path d=\"M19.5 8H6l3.4-3.4M4.5 16H18l-3.4 3.4\" stroke-width=\"2.1\"/>",
            "duplicate": "<rect x=\"8.6\" y=\"8\" width=\"11.4\" height=\"12.5\" rx=\"2.4\" fill=\"{C}\" fill-opacity=\"{FA}\"/><path d=\"M5.6 15.5H5a2.2 2.2 0 0 1-2.2-2.2V5A2.2 2.2 0 0 1 5 2.8h8.5a2.2 2.2 0 0 1 2.2 2.2v1\"/>",
            "copy": "<rect x=\"8.6\" y=\"8\" width=\"11.4\" height=\"12.5\" rx=\"2.4\" fill=\"{C}\" fill-opacity=\"{FA}\"/><path d=\"M5.6 15.5H5a2.2 2.2 0 0 1-2.2-2.2V5A2.2 2.2 0 0 1 5 2.8h8.5a2.2 2.2 0 0 1 2.2 2.2v1\"/>",
            "trash": "<path d=\"M4.5 7h15M9.5 7V4.8a1.2 1.2 0 0 1 1.2-1.2h2.6a1.2 1.2 0 0 1 1.2 1.2V7\" stroke-width=\"1.9\"/><path d=\"M6.4 7l1 12.2a1.8 1.8 0 0 0 1.8 1.6h5.6a1.8 1.8 0 0 0 1.8-1.6l1-12.2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><line x1=\"10\" y1=\"11\" x2=\"10\" y2=\"16.8\" stroke-width=\"1.6\"/><line x1=\"14\" y1=\"11\" x2=\"14\" y2=\"16.8\" stroke-width=\"1.6\"/>",
            "workspace": "<rect x=\"3\" y=\"4\" width=\"8\" height=\"16\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"13\" y=\"4\" width=\"8\" height=\"7.2\" rx=\"2\" fill=\"{C}\" fill-opacity=\"{FA}\"/><rect x=\"13\" y=\"13\" width=\"8\" height=\"7\" rx=\"2\" fill=\"{C}\" fill-opacity=\"0.12\"/>",
            "check": "<circle cx=\"12\" cy=\"12\" r=\"9\" fill=\"#10B981\" fill-opacity=\"0.22\" stroke=\"#10B981\" stroke-width=\"1.5\"/><path d=\"M7.8 12.2 10.6 15 16.4 9\" stroke=\"#10B981\" stroke-width=\"2.2\"/>"
        })

        function hex2(n) {
            var v = Math.max(0, Math.min(255, Math.round(n * 255))).toString(16);
            return v.length === 1 ? "0" + v : v;
        }

        function buildSvgUri(k, col) {
            var mt = multiToneTemplates[k];
            if (mt) {
                var svgMt = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\">"
                          + mt + "</svg>";
                return "data:image/svg+xml;utf8," + encodeURIComponent(svgMt);
            }
            var hex = "#" + hex2(col.r) + hex2(col.g) + hex2(col.b);
            var alpha = Number(col.a).toFixed(2);
            var fillAlpha = Number(col.a * 0.24).toFixed(2);
            var tpl = actionTemplates[k] || actionTemplates["file"];
            var body = tpl.replace(/\{C\}/g, hex)
                          .replace(/\{FA\}/g, fillAlpha);
            var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + hex
                    + "\" stroke-opacity=\"" + alpha + "\" stroke-width=\"1.9\" stroke-linecap=\"round\" stroke-linejoin=\"round\">"
                    + body + "</svg>";
            return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
        }

        Image {
            id: iconImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: false
            cache: true
            sourceSize: Qt.size(Math.max(64, Math.round(iconRoot.width * 4)), Math.max(64, Math.round(iconRoot.height * 4)))
            source: iconRoot.buildSvgUri(iconRoot.kind, iconRoot.iconColor)
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
            width: 17
            height: 17
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
        delegate: AppMenuItem {}

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 95; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 75; easing.type: Easing.InCubic }
        }

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
        arrow: Item {}

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

            Text {
                visible: miRoot.subMenu !== null
                text: "▸"
                font.pixelSize: 11
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
        property int rightPadding: 10
        signal accepted()
        signal escaped()
        signal textEdited()
        signal upPressed()
        signal downPressed()

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
            anchors.rightMargin: fieldRoot.rightPadding
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
            anchors.rightMargin: fieldRoot.rightPadding
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
            Keys.onUpPressed: function(event) {
                fieldRoot.upPressed();
                event.accepted = false;
            }
            Keys.onDownPressed: function(event) {
                fieldRoot.downPressed();
                event.accepted = false;
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

    // Compact custom-themed CheckBox matching TwinForge's 12px dark/light palette.
    component AppCheckBox : CheckBox {
        id: cbRoot
        spacing: 7
        padding: 2
        leftPadding: 0
        rightPadding: 4
        implicitHeight: 24
        hoverEnabled: true

        indicator: Rectangle {
            implicitWidth: 16
            implicitHeight: 16
            x: cbRoot.leftPadding
            y: parent.height / 2 - height / 2
            radius: Math.min(4, win.smallRadius)
            color: cbRoot.checked ? p.accent : (cbRoot.hovered ? p.btnHoverBg : p.inputBg)
            border.width: 1
            border.color: cbRoot.checked ? p.accent : (cbRoot.hovered ? p.borderStrong : p.borderDefault)
            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                visible: cbRoot.checked
                text: "✓"
                font.pixelSize: 11
                font.bold: true
                color: p.accentFg
            }
        }

        contentItem: Text {
            text: cbRoot.text
            font.pixelSize: 12
            color: !cbRoot.enabled ? p.textDisabled : (cbRoot.hovered ? p.textPrimary : p.textSecondary)
            verticalAlignment: Text.AlignVCenter
            leftPadding: cbRoot.indicator.width + cbRoot.spacing
        }
    }

    // Compact custom-themed ComboBox matching CompactField and AppMenu styling.
    component AppComboBox : ComboBox {
        id: comboRoot
        implicitHeight: 30
        implicitWidth: 150
        leftPadding: 10
        rightPadding: 26
        topPadding: 0
        bottomPadding: 0
        hoverEnabled: true

        delegate: ItemDelegate {
            id: comboDel
            width: comboRoot.width - 8
            implicitHeight: 28
            highlighted: comboRoot.highlightedIndex === index
            contentItem: Text {
                text: comboRoot.textRole ? (Array.isArray(comboRoot.model) ? (modelData[comboRoot.textRole] || "") : model[comboRoot.textRole]) : modelData
                color: comboDel.highlighted ? p.textPrimary : p.textSecondary
                font.pixelSize: 12
                font.weight: comboDel.highlighted ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding: 6
                rightPadding: 6
            }
            background: Rectangle {
                radius: win.smallRadius
                color: comboDel.highlighted ? Qt.alpha(p.accent, win.isDark ? 0.22 : 0.14) : "transparent"
                border.width: comboDel.highlighted ? 1 : 0
                border.color: Qt.alpha(p.accent, 0.45)
            }
        }

        indicator: Text {
            x: comboRoot.width - width - 8
            y: (comboRoot.height - height) / 2
            text: "▾"
            font.pixelSize: 11
            color: comboRoot.hovered || comboRoot.activeFocus ? p.accent : p.textMuted
        }

        contentItem: Text {
            text: comboRoot.displayText
            font.pixelSize: 12
            color: !comboRoot.enabled ? p.textDisabled : p.textPrimary
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 150
            implicitHeight: 30
            radius: win.smallRadius
            color: comboRoot.hovered ? p.chipHoverBg : p.inputBg
            border.width: 1
            border.color: comboRoot.activeFocus || comboRoot.popup.visible ? p.accent : p.borderDefault
        }

        popup: Popup {
            y: comboRoot.height + 2
            width: comboRoot.width
            implicitHeight: Math.min(240, contentItem.implicitHeight + 10)
            padding: 4
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: comboRoot.popup.visible ? comboRoot.delegateModel : null
                currentIndex: comboRoot.highlightedIndex
                ScrollBar.vertical: AppScrollBar {}
            }
            background: Rectangle {
                color: p.menuBg
                border.width: 1
                border.color: p.borderDefault
                radius: win.panelRadius
            }
        }
    }

    // Sleek slim ProgressBar with animated accent fill and indeterminate pulse.
    component AppProgressBar : ProgressBar {
        id: pbRoot
        implicitHeight: 6
        implicitWidth: 160

        background: Rectangle {
            implicitHeight: 6
            radius: 3
            color: p.borderSubtle
        }

        contentItem: Item {
            implicitHeight: 6
            clip: true

            Rectangle {
                visible: !pbRoot.indeterminate
                width: Math.max(pbRoot.visualPosition > 0 ? 6 : 0, pbRoot.visualPosition * parent.width)
                height: parent.height
                radius: 3
                color: p.accent
                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: indBar
                visible: pbRoot.indeterminate
                width: Math.max(24, parent.width * 0.32)
                height: parent.height
                radius: 3
                color: p.accent
                SequentialAnimation on x {
                    running: pbRoot.visible && pbRoot.indeterminate
                    loops: Animation.Infinite
                    NumberAnimation { from: -indBar.width; to: pbRoot.width; duration: 1100; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // Reusable slim 6px hover-accented ScrollBar for all lists, grids & drawers.
    component AppScrollBar : ScrollBar {
        id: sbRoot
        policy: ScrollBar.AsNeeded
        implicitWidth: orientation === Qt.Vertical ? 6 : 120
        implicitHeight: orientation === Qt.Horizontal ? 6 : 120
        padding: 1
        contentItem: Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            radius: 2
            visible: sbRoot.size < 1.0
            color: sbRoot.pressed ? p.accent : (sbRoot.hovered ? p.scrollbarHoverColor : p.scrollbarColor)
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        background: Item {}
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
        property string tooltipText: ""
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
                id: fkeyBadge
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
                elide: Text.ElideMiddle
                Layout.maximumWidth: Math.max(36, fkeyBtn.width - fkeyBadge.width - 18)
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

        ToolTip.visible: fkeyMouse.containsMouse && fkeyBtn.tooltipText.length > 0
        ToolTip.delay: 350
        ToolTip.text: fkeyBtn.tooltipText
    }

    // Unified Dual-Panel File Browser Pane (used for both Left and Right panels).
    component FilePanel : Rectangle {
        id: panelRoot
        required property int panelIndex
        required property var panelModel
        property bool filterVisible: false
        property bool pathEditing: false
        property bool pathCopyFlashed: false
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
                var rowHeight = Math.max(18, backend.rowHeight);
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
            pathCopyFlashed = false;
            activeView.forceActiveFocus();
        }

        function openPathEditor() {
            backend.activePanel = panelIndex;
            pathCopyFlashed = false;
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

        property string typeAheadBuffer: ""
        Timer {
            id: typeAheadTimer
            interval: 1200
            onTriggered: panelRoot.typeAheadBuffer = ""
        }

        function handleTypeAheadKey(event, view) {
            var m = panelRoot.panelModel;
            if (event.key === Qt.Key_Backspace && panelRoot.typeAheadBuffer.length > 0) {
                panelRoot.typeAheadBuffer = panelRoot.typeAheadBuffer.slice(0, -1);
                if (panelRoot.typeAheadBuffer.length > 0) {
                    typeAheadTimer.restart();
                    var bIdx = m.findIndexByQuery(panelRoot.typeAheadBuffer, 0, true);
                    if (bIdx >= 0) view.currentIndex = bIdx;
                } else {
                    typeAheadTimer.stop();
                }
                event.accepted = true;
                return true;
            }
            if (event.key === Qt.Key_Escape && panelRoot.typeAheadBuffer.length > 0) {
                panelRoot.typeAheadBuffer = "";
                typeAheadTimer.stop();
                event.accepted = true;
                return true;
            }
            var mods = event.modifiers;
            if (event.text.length === 1
                    && (mods === Qt.NoModifier || mods === Qt.ShiftModifier)
                    && /^[A-Za-z0-9._-]$/.test(event.text)) {
                var ch = event.text;
                var idx = -1;
                if (panelRoot.typeAheadBuffer.length === 1
                        && panelRoot.typeAheadBuffer.toLowerCase() === ch.toLowerCase()) {
                    // Repeating the same letter cycles to the next item starting with that letter
                    idx = m.findIndexByQuery(panelRoot.typeAheadBuffer, view.currentIndex + 1, false);
                } else {
                    panelRoot.typeAheadBuffer += ch;
                    idx = m.findIndexByQuery(panelRoot.typeAheadBuffer, 0, true);
                }
                typeAheadTimer.restart();
                if (idx >= 0)
                    view.currentIndex = idx;
                event.accepted = true;
                return true;
            }
            return false;
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
            if (iconType && iconType.length > 0 && iconType !== "text")
                return iconType;
            if (iconType === "text")
                return "doc";
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
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        // Top active-panel accent indicator line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            opacity: panelRoot.isActive ? 1.0 : 0.0
            visible: opacity > 0.01
            color: p.accent
            z: 5
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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
                            visible: backend.quickViewLoading
                            text: qsTr("Loading…")
                            font.pixelSize: 11
                            font.bold: true
                            color: p.accent
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
                            backend.requestPreview(win.quickViewData.path, page, "quickview");
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
                height: 27
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
                            property int draggingTabIndex: -1
                            property int dropTargetIndex: -1
                            property real dropIndicatorX: -1
                            property bool dropToOtherPanel: false

                            Repeater {
                                id: tabRepeater
                                model: panelRoot.panelModel.tabs

                                delegate: Rectangle {
                                    id: tabPill
                                    readonly property bool isTabActive: index === panelRoot.panelModel.activeTab
                                    readonly property int tabLockMode: modelData.lockMode || 0
                                    readonly property bool isTabLocked: modelData.isLocked === true
                                    readonly property bool isTrashTab: modelData.isTrash === true
                                    property bool dropHover: tabDropArea.containsDrag

                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 22
                                    width: Math.min(200, Math.max(76, tabContentRow.implicitWidth + 14))
                                    radius: win.smallRadius
                                    opacity: tabsRow.draggingTabIndex === index ? 0.45 : 1.0
                                    color: {
                                        if (dropHover) return Qt.alpha(p.accent, 0.24);
                                        if (isTabActive) return panelRoot.isActive ? p.tabActivePanelBg : p.tabActiveInactivePanelBg;
                                        if (tabMouse.containsMouse) return p.tabHoverBg;
                                        return "transparent";
                                    }
                                    border.width: (isTabActive || dropHover || isTabLocked) ? 1 : 0
                                    border.color: dropHover ? p.accent
                                                : (isTabActive ? (panelRoot.isActive ? Qt.alpha(p.accent, 0.52) : p.borderDefault)
                                                : Qt.alpha(p.accent, 0.28))

                                    MouseArea {
                                        id: tabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        preventStealing: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        cursorShape: dragActive ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        property real pressXInRow: 0
                                        property real pressYInRow: 0
                                        property bool dragActive: false
                                        property bool suppressedClick: false

                                        function clearTabDrag() {
                                            dragActive = false;
                                            tabsRow.draggingTabIndex = -1;
                                            tabsRow.dropTargetIndex = -1;
                                            tabsRow.dropIndicatorX = -1;
                                            tabsRow.dropToOtherPanel = false;
                                        }

                                        onPressed: function(mouse) {
                                            dragActive = false;
                                            suppressedClick = false;
                                            if (mouse.button === Qt.LeftButton && panelRoot.panelModel.tabCount > 1) {
                                                var pt = tabMouse.mapToItem(tabsRow, mouse.x, mouse.y);
                                                pressXInRow = pt.x;
                                                pressYInRow = pt.y;
                                            }
                                        }

                                        onPositionChanged: function(mouse) {
                                            if ((mouse.buttons & Qt.LeftButton) === 0 || panelRoot.panelModel.tabCount <= 1)
                                                return;
                                            var pt = tabMouse.mapToItem(tabsRow, mouse.x, mouse.y);
                                            if (!dragActive && (Math.abs(pt.x - pressXInRow) > 6 || Math.abs(pt.y - pressYInRow) > 10)) {
                                                dragActive = true;
                                                suppressedClick = true;
                                                tabsRow.draggingTabIndex = index;
                                            }
                                            if (!dragActive)
                                                return;

                                            var otherPane = (panelRoot.panelIndex === 0) ? rightPane : leftPane;
                                            var opt = tabMouse.mapToItem(otherPane, mouse.x, mouse.y);
                                            if (opt.x >= 0 && opt.x <= otherPane.width && opt.y >= 0 && opt.y <= otherPane.height) {
                                                tabsRow.dropToOtherPanel = true;
                                                tabsRow.dropIndicatorX = -1;
                                                return;
                                            }
                                            tabsRow.dropToOtherPanel = false;

                                            var count = tabRepeater.count;
                                            if (count <= 1)
                                                return;
                                            var targetIdx = count - 1;
                                            var lastItem = tabRepeater.itemAt(count - 1);
                                            var indX = lastItem ? (lastItem.x + lastItem.width + 1) : 0;

                                            for (var i = 0; i < count; ++i) {
                                                var item = tabRepeater.itemAt(i);
                                                if (!item)
                                                    continue;
                                                if (pt.x < item.x + item.width * 0.5) {
                                                    targetIdx = (i <= tabsRow.draggingTabIndex) ? i : (i - 1);
                                                    indX = item.x - 1;
                                                    break;
                                                }
                                            }
                                            tabsRow.dropTargetIndex = Math.max(0, Math.min(count - 1, targetIdx));
                                            tabsRow.dropIndicatorX = indX;
                                        }

                                        onReleased: function(mouse) {
                                            if (mouse.button === Qt.LeftButton && dragActive) {
                                                var fromIdx = tabsRow.draggingTabIndex;
                                                var toIdx = tabsRow.dropTargetIndex;
                                                var toOther = tabsRow.dropToOtherPanel;
                                                clearTabDrag();
                                                if (fromIdx >= 0) {
                                                    if (toOther)
                                                        backend.moveTabToOppositePanel(panelRoot.panelIndex, fromIdx);
                                                    else if (toIdx >= 0 && fromIdx !== toIdx)
                                                        panelRoot.panelModel.moveTab(fromIdx, toIdx);
                                                }
                                            }
                                        }

                                        onCanceled: {
                                            clearTabDrag();
                                            suppressedClick = false;
                                        }

                                        onClicked: function(mouse) {
                                            if (suppressedClick) {
                                                suppressedClick = false;
                                                return;
                                            }
                                            if (mouse.button === Qt.RightButton) {
                                                backend.activePanel = panelRoot.panelIndex;
                                                tabContextMenu.targetTabIndex = index;
                                                tabContextMenu.targetLockMode = tabPill.tabLockMode;
                                                tabContextMenu.targetPath = modelData.path || "";
                                                tabContextMenu.targetLockedRoot = modelData.lockedRootPath || "";
                                                var pt = tabMouse.mapToItem(panelRoot, mouse.x, mouse.y);
                                                tabContextMenu.popup(panelRoot, pt.x, pt.y);
                                                return;
                                            }
                                            if (mouse.button === Qt.MiddleButton) {
                                                if (!tabPill.isTabLocked && panelRoot.panelModel.tabCount > 1)
                                                    panelRoot.panelModel.closeTab(index);
                                            } else {
                                                backend.activePanel = panelRoot.panelIndex;
                                                if (tabPill.isTabActive && tabPill.isTabLocked
                                                        && (modelData.lockedRootPath || "").length > 0
                                                        && modelData.path !== modelData.lockedRootPath) {
                                                    panelRoot.panelModel.resetLockedTab(index);
                                                } else {
                                                    panelRoot.panelModel.setActiveTab(index);
                                                }
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
                                        anchors.rightMargin: (!tabPill.isTabLocked && panelRoot.panelModel.tabCount > 1) ? 4 : 7
                                        spacing: 5

                                        VectorIcon {
                                            width: 12
                                            height: 12
                                            kind: tabPill.isTabLocked ? "lock" : (tabPill.isTrashTab ? "trash" : "folder")
                                            iconColor: tabPill.isTabActive
                                                       ? (panelRoot.isActive ? p.accent : p.textMuted)
                                                       : p.textDim
                                        }

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            font.weight: (tabPill.isTabActive || tabPill.isTabLocked) ? Font.DemiBold : Font.Normal
                                            color: tabPill.isTabActive ? p.textPrimary
                                                 : (tabMouse.containsMouse ? p.textSecondary : p.textMuted)
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                        }

                                        Rectangle {
                                            visible: !tabPill.isTabLocked && panelRoot.panelModel.tabCount > 1
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
                                    ToolTip.text: {
                                        var tip = modelData.path;
                                        if (tabPill.tabLockMode === 1)
                                            tip += "\n" + qsTr("Locked (strict — navigation opens new tab)");
                                        else if (tabPill.tabLockMode === 2) {
                                            tip += "\n" + qsTr("Locked (allow navigation)");
                                            if ((modelData.lockedRootPath || "").length > 0 && modelData.lockedRootPath !== modelData.path)
                                                tip += "\n" + qsTr("Locked root: %1 (click tab to return)").arg(modelData.lockedRootPath);
                                        }
                                        return tip;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: tabDropIndicator
                            visible: tabsRow.draggingTabIndex >= 0 && !tabsRow.dropToOtherPanel && tabsRow.dropIndicatorX >= 0
                            x: tabsRow.dropIndicatorX
                            y: 2
                            width: 2
                            height: tabFlick.height - 4
                            radius: 1
                            color: p.accent
                            z: 5
                        }
                    }

                    AppMenu {
                        id: tabContextMenu
                        property int targetTabIndex: -1
                        property int targetLockMode: 0
                        property string targetPath: ""
                        property string targetLockedRoot: ""

                        AppMenuItem {
                            text: qsTr("Lock Tab (Allow Navigation)")
                            checkable: true
                            checked: tabContextMenu.targetLockMode === 2
                            onTriggered: panelRoot.panelModel.setTabLockMode(tabContextMenu.targetTabIndex, tabContextMenu.targetLockMode === 2 ? 0 : 2)
                        }
                        AppMenuItem {
                            text: qsTr("Lock Tab (Strict)")
                            checkable: true
                            checked: tabContextMenu.targetLockMode === 1
                            onTriggered: panelRoot.panelModel.setTabLockMode(tabContextMenu.targetTabIndex, tabContextMenu.targetLockMode === 1 ? 0 : 1)
                        }
                        AppMenuItem {
                            text: qsTr("Unlock Tab")
                            enabled: tabContextMenu.targetLockMode !== 0
                            onTriggered: panelRoot.panelModel.setTabLockMode(tabContextMenu.targetTabIndex, 0)
                        }
                        AppMenuItem {
                            text: qsTr("Return to Locked Root")
                            enabled: tabContextMenu.targetLockMode !== 0 && tabContextMenu.targetLockedRoot.length > 0 && tabContextMenu.targetPath !== tabContextMenu.targetLockedRoot
                            onTriggered: panelRoot.panelModel.resetLockedTab(tabContextMenu.targetTabIndex)
                        }

                        AppMenuSeparator {}

                        AppMenuItem {
                            text: qsTr("Duplicate Tab")
                            onTriggered: panelRoot.panelModel.duplicateTab(tabContextMenu.targetTabIndex)
                        }
                        AppMenuItem {
                            text: qsTr("Move Tab to Opposite Panel")
                            onTriggered: backend.moveTabToOppositePanel(panelRoot.panelIndex, tabContextMenu.targetTabIndex)
                        }
                        AppMenuItem {
                            text: qsTr("Move Tab Left")
                            enabled: tabContextMenu.targetTabIndex > 0
                            onTriggered: panelRoot.panelModel.moveTab(tabContextMenu.targetTabIndex, tabContextMenu.targetTabIndex - 1)
                        }
                        AppMenuItem {
                            text: qsTr("Move Tab Right")
                            enabled: tabContextMenu.targetTabIndex >= 0 && tabContextMenu.targetTabIndex < panelRoot.panelModel.tabCount - 1
                            onTriggered: panelRoot.panelModel.moveTab(tabContextMenu.targetTabIndex, tabContextMenu.targetTabIndex + 1)
                        }

                        AppMenuSeparator {}

                        AppMenuItem {
                            text: qsTr("Reopen Closed Tab")
                            shortcutHint: "Ctrl+Shift+W"
                            enabled: panelRoot.panelModel.canReopenClosedTab
                            onTriggered: panelRoot.panelModel.reopenClosedTab()
                        }
                        AppMenuItem {
                            text: qsTr("Close Other Unlocked Tabs")
                            enabled: panelRoot.panelModel.tabCount > 1
                            onTriggered: panelRoot.panelModel.closeOtherTabs(tabContextMenu.targetTabIndex)
                        }
                        AppMenuItem {
                            text: qsTr("Close Tab")
                            shortcutHint: "Ctrl+W"
                            enabled: tabContextMenu.targetLockMode === 0 && panelRoot.panelModel.tabCount > 1
                            onTriggered: panelRoot.panelModel.closeTab(tabContextMenu.targetTabIndex)
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
                height: 34
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
                            id: crumbBox
                            objectName: "crumbBox_" + panelRoot.panelIndex
                            anchors.fill: parent
                            visible: !panelRoot.pathEditing
                            radius: win.smallRadius
                            color: p.breadcrumbBg
                            border.width: 1
                            border.color: panelRoot.isActive ? p.borderStrong : p.borderDefault
                            clip: true

                            // Clicking anywhere inside empty box area, separators, or margins opens text editor
                            MouseArea {
                                id: crumbBgMouse
                                objectName: "crumbBgMouse_" + panelRoot.panelIndex
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: panelRoot.openPathEditor()
                            }

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
                                    interactive: false
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    onContentWidthChanged: {
                                        if (contentWidth > width)
                                            contentX = contentWidth - width;
                                        else
                                            contentX = 0;
                                    }

                                    WheelHandler {
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        onWheel: function(event) {
                                            if (crumbFlick.contentWidth <= crumbFlick.width)
                                                return;
                                            var delta = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
                                            crumbFlick.contentX = Math.max(0, Math.min(crumbFlick.contentWidth - crumbFlick.width, crumbFlick.contentX - delta));
                                            event.accepted = true;
                                        }
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
                                    visible: panelRoot.panelModel.isTrashView
                                    implicitHeight: 18
                                    implicitWidth: trashBadgeText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha(p.dangerAccent, 0.14)
                                    border.width: 1
                                    border.color: Qt.alpha(p.dangerAccent, 0.4)
                                    Text {
                                        id: trashBadgeText
                                        anchors.centerIn: parent
                                        text: qsTr("Trash")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: p.dangerText
                                    }
                                }

                                Rectangle {
                                    visible: !panelRoot.panelModel.isWritable && !panelRoot.panelModel.isArchiveView && !panelRoot.panelModel.isTrashView
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
                                    id: bookmarkPathBtn
                                    objectName: "bookmarkPathBtn_" + panelRoot.panelIndex
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
                            objectName: "pathEditField_" + panelRoot.panelIndex
                            anchors.fill: parent
                            visible: panelRoot.pathEditing
                            monospace: true
                            rightPadding: 32
                            placeholderText: qsTr("Enter folder path...")
                            onAccepted: {
                                panelRoot.pathEditing = false;
                                panelRoot.pathCopyFlashed = false;
                                panelRoot.panelModel.setPath(pathEditField.text);
                                fileList.forceActiveFocus();
                            }
                            onEscaped: {
                                panelRoot.pathEditing = false;
                                panelRoot.pathCopyFlashed = false;
                                fileList.forceActiveFocus();
                            }
                            Connections {
                                target: pathEditField.input
                                function onActiveFocusChanged() {
                                    if (!pathEditField.input.activeFocus && panelRoot.pathEditing) {
                                        panelRoot.pathEditing = false;
                                        panelRoot.pathCopyFlashed = false;
                                    }
                                }
                            }

                            Timer {
                                id: copyFlashTimer
                                interval: 1200
                                onTriggered: panelRoot.pathCopyFlashed = false
                            }

                            IconBtn {
                                id: copyPathBtn
                                objectName: "copyPathBtn_" + panelRoot.panelIndex
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 22
                                implicitHeight: 22
                                z: 2
                                iconKind: panelRoot.pathCopyFlashed ? "check" : "copy"
                                active: panelRoot.pathCopyFlashed
                                tooltipText: qsTr("Copy path to clipboard")
                                onClicked: {
                                    var textToCopy = pathEditField.text.length > 0 ? pathEditField.text : panelRoot.panelModel.path;
                                    if (backend.copyTextToClipboard(textToCopy, qsTr("Copied path to clipboard: %1").arg(textToCopy))) {
                                        panelRoot.pathCopyFlashed = true;
                                        copyFlashTimer.restart();
                                    }
                                    pathEditField.forceFieldFocus();
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
                readonly property bool filterOpen: panelRoot.filterVisible || panelRoot.panelModel.filter.length > 0
                visible: Layout.preferredHeight > 0
                Layout.fillWidth: true
                Layout.preferredHeight: filterOpen ? 34 : 0
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                clip: true
                color: p.filterBarBg
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

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

            // 2b. Trash Manager Action Bar (visible when browsing trash://)
            Rectangle {
                visible: panelRoot.panelModel.isTrashView
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.minimumHeight: 34
                color: p.filterBarBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    VectorIcon {
                        width: 14
                        height: 14
                        kind: "trash"
                        iconColor: p.dangerText
                    }

                    Text {
                        text: qsTr("Trash (%1)").arg(panelRoot.panelModel.itemCount)
                        font.pixelSize: 11
                        font.bold: true
                        color: p.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    ToolbarBtn {
                        label: qsTr("Restore")
                        accentHighlight: true
                        btnEnabled: panelRoot.panelModel.itemCount > 0
                        tooltipText: qsTr("Restore selected item(s) to original location")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            var paths = win.getSelectedOrCurrentPaths();
                            if (paths.length > 0)
                                backend.restoreFromTrash(paths);
                            panelRoot.focusList();
                        }
                    }

                    ToolbarBtn {
                        label: qsTr("Delete Permanently")
                        btnEnabled: panelRoot.panelModel.itemCount > 0
                        tooltipText: qsTr("Permanently remove selected item(s) from Trash (F8)")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            win.triggerF8Delete();
                        }
                    }

                    ToolbarBtn {
                        label: qsTr("Empty Trash")
                        btnEnabled: panelRoot.panelModel.itemCount > 0
                        tooltipText: qsTr("Permanently delete all items in Trash")
                        onClicked: {
                            backend.activePanel = panelRoot.panelIndex;
                            win.confirmEmptyTrashOpen = true;
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

                    Rectangle { visible: backend.showExtColumn; width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Ext Header
                    Rectangle {
                        visible: backend.showExtColumn
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

                    Rectangle { visible: backend.showSizeColumn; width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Size Header
                    Rectangle {
                        visible: backend.showSizeColumn
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

                    Rectangle { visible: backend.showModifiedColumn; width: 1; Layout.fillHeight: true; color: p.borderSubtle }

                    // Date Header
                    Rectangle {
                        visible: backend.showModifiedColumn
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
                        height: backend.rowHeight
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
                                        width: Math.round(Math.max(15, Math.min(21, backend.rowHeight * 0.65)))
                                        height: width
                                        kind: panelRoot.iconKindFor(model.isParent, model.isDir, model.iconType)
                                        iconColor: panelRoot.iconColorFor(model.isParent, model.isDir, model.iconType, model.isSelected)
                                    }

                                    Text {
                                        id: rowNameText
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        text: panelRoot.displayStem(model.name, model.extension, model.isDir)
                                        elide: Text.ElideMiddle
                                        font.pixelSize: backend.fontSize
                                        font.weight: (model.isDir && !model.isParent) || model.isSelected ? Font.DemiBold : Font.Normal
                                        color: {
                                            if (model.isSelected) return p.accent;
                                            if (model.isParent) return p.textMuted;
                                            if (model.isDir) return p.textPrimary;
                                            return p.textSecondary;
                                        }
                                    }

                                    Text {
                                        visible: panelRoot.panelModel.isTrashView && (model.originalPath || "").length > 0
                                        Layout.maximumWidth: 260
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "← " + (model.originalPath || "")
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                        color: p.textDim
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

                            Rectangle { visible: backend.showExtColumn; width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Ext Cell
                            Item {
                                visible: backend.showExtColumn
                                Layout.preferredWidth: panelRoot.colExtWidth
                                Layout.fillHeight: true

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: panelRoot.displayExt(model.name, model.extension, model.isDir)
                                    font.pixelSize: Math.max(9, backend.fontSize - 1)
                                    font.family: "monospace"
                                    color: model.isSelected ? p.accent : p.textMuted
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle { visible: backend.showSizeColumn; width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Size Cell
                            Item {
                                visible: backend.showSizeColumn
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
                                    font.pixelSize: parent.isPlaceholderTag ? Math.max(9, backend.fontSize - 2) : Math.max(9, backend.fontSize - 1)
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

                            Rectangle { visible: backend.showModifiedColumn; width: 1; Layout.fillHeight: true; color: p.cellDivider }

                            // Date Cell
                            Item {
                                visible: backend.showModifiedColumn
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
                                    font.pixelSize: Math.max(9, backend.fontSize - 1)
                                    font.family: "monospace"
                                    color: model.isSelected ? Qt.alpha(p.accent, 0.85) : p.textDim
                                }
                            }
                        }
                    }

                    Keys.onPressed: function(event) {
                        var m = panelRoot.panelModel;
                        if (panelRoot.handleTypeAheadKey(event, this))
                            return;
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            panelRoot.typeAheadBuffer = "";
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
                            panelRoot.typeAheadBuffer = "";
                            m.toggleSelection(currentIndex);
                            if (currentIndex + 1 < m.itemCount)
                                currentIndex++;
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
                    ScrollBar.vertical: AppScrollBar {}

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
                                    sourceSize: Qt.size(192, 192)
                                    mipmap: true
                                    smooth: true
                                    asynchronous: true
                                    cache: true
                                }

                                VectorIcon {
                                    visible: !thumbImg.visible || thumbImg.status === Image.Error || thumbImg.status === Image.Null
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
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
                        if (panelRoot.handleTypeAheadKey(event, this))
                            return;
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            panelRoot.typeAheadBuffer = "";
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
                            panelRoot.typeAheadBuffer = "";
                            m.toggleSelection(currentIndex);
                            if (currentIndex + 1 < m.itemCount)
                                currentIndex++;
                            event.accepted = true;
                        }
                    }
                }

                // Clean Empty State Overlay (non-blocking — passes mouse events to background)
                ColumnLayout {
                    readonly property bool isEmptyPanel: panelRoot.panelModel.itemCount === 0
                        || (panelRoot.panelModel.itemCount === 1 && panelRoot.panelModel.itemName(0) === "..")
                    visible: isEmptyPanel
                    anchors.centerIn: parent
                    spacing: 6
                    opacity: 0.72
                    z: 2

                    VectorIcon {
                        Layout.alignment: Qt.AlignHCenter
                        width: 30
                        height: 30
                        kind: panelRoot.panelModel.isTrashView ? "trash"
                              : (panelRoot.panelModel.filter.length > 0 ? "filter" : "folder")
                        iconColor: p.textDim
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: panelRoot.panelModel.isTrashView ? qsTr("Trash is empty")
                              : (panelRoot.panelModel.filter.length > 0
                                 ? qsTr("No items match \"%1\"").arg(panelRoot.panelModel.filter)
                                 : qsTr("This folder is empty"))
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: p.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: !panelRoot.panelModel.isTrashView && panelRoot.panelModel.filter.length === 0
                        text: qsTr("Press F7 for new folder · Shift+F4 for new file")
                        font.pixelSize: 11
                        color: p.textDim
                    }
                }

                // Floating Type-Ahead Quick Search badge
                Rectangle {
                    visible: panelRoot.typeAheadBuffer.length > 0
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 10
                    z: 20
                    height: 26
                    width: typeAheadRow.implicitWidth + 18
                    radius: win.smallRadius
                    color: p.dialogBg
                    border.width: 1
                    border.color: p.accent

                    RowLayout {
                        id: typeAheadRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: qsTr("Jump:")
                            font.pixelSize: 10
                            font.bold: true
                            color: p.accent
                        }

                        Text {
                            text: panelRoot.typeAheadBuffer
                            font.pixelSize: 12
                            font.family: "monospace"
                            font.bold: true
                            color: p.textPrimary
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
        if (!win.quickViewActive) {
            backend.cancelPreview("quickview");
            return;
        }
        var p = currentHighlightedPath();
        if (p.length > 0) {
            backend.requestPreview(p, 1, "quickview");
        } else {
            backend.cancelPreview("quickview");
            win.quickViewData = ({});
        }
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
            previewData = ({ path: p, name: backend.fileName(p), exists: true });
            previewOpen = true;
            backend.requestPreview(p, 1, "modal");
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
            if (!backend.confirmCopy) {
                backend.copyItems(paths, targetModel().path);
                return;
            }
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
            if (!backend.confirmMove) {
                backend.moveItems(paths, targetModel().path);
                return;
            }
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
            backend.extractArchiveAsync(p, targetModel().path);
        else
            backend.showStatus(qsTr("Highlight an archive (.zip, .tar.gz, .7z) to extract (Alt+F9)."));
    }

    function insertIntoCmdBar(fullPath) {
        var m = currentModel();
        var lv = currentListView();
        if (lv.currentIndex < 0 || lv.currentIndex >= m.itemCount)
            return;
        var name = m.itemName(lv.currentIndex);
        if (name === "..")
            return;
        var raw = fullPath ? m.itemPath(lv.currentIndex) : name;
        var quoted = backend.shellQuote(raw);
        if (cmdLineInput.text.length > 0 && !cmdLineInput.text.endsWith(" "))
            cmdLineInput.text += " ";
        cmdLineInput.text += quoted + " ";
        cmdLineInput.forceFieldFocus();
        cmdLineInput.input.cursorPosition = cmdLineInput.text.length;
    }

    function navigateCmdHistory(direction) {
        var hist = backend.commandHistory;
        if (!hist || hist.length === 0)
            return;
        if (direction < 0) {
            if (win.cmdHistoryIndex === -1) {
                win.cmdHistoryDraft = cmdLineInput.text;
                win.cmdHistoryIndex = hist.length - 1;
            } else if (win.cmdHistoryIndex > 0) {
                win.cmdHistoryIndex--;
            }
            cmdLineInput.text = hist[win.cmdHistoryIndex];
        } else {
            if (win.cmdHistoryIndex === -1)
                return;
            if (win.cmdHistoryIndex < hist.length - 1) {
                win.cmdHistoryIndex++;
                cmdLineInput.text = hist[win.cmdHistoryIndex];
            } else {
                win.cmdHistoryIndex = -1;
                cmdLineInput.text = win.cmdHistoryDraft;
            }
        }
        cmdLineInput.input.cursorPosition = cmdLineInput.text.length;
    }

    function openSplitCombineDialog() {
        var path = currentHighlightedPath();
        if (!path || path.length === 0) {
            backend.showStatus(qsTr("Highlight a file to split or a .001 / .crc file to combine."));
            return;
        }
        var info = backend.inspectSplitSource(path);
        if (!info.valid) {
            backend.showStatus(qsTr("Select a regular file to split or combine."));
            return;
        }
        win.splitSourcePath = path;
        win.splitSourceInfo = info;
        splitTargetDirField.text = targetModel().isTrashView || targetModel().isArchiveView
                                   ? currentModel().path
                                   : targetModel().path;
        win.splitCombineOpen = true;
    }

    function triggerF8Delete() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            if (!backend.confirmDelete && !currentModel().isTrashView) {
                backend.deleteItems(paths, false);
                return;
            }
            confirmDeleteOpen = true;
        } else {
            backend.showStatus(qsTr("No files selected to delete."));
        }
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

    function openSettingsDialog() {
        win.closeAllMenus();
        settingsDialog.loadFromBackend();
        win.settingsOpen = true;
    }

    function collectSelectedRegularFiles() {
        var m = currentModel();
        var files = [];
        for (var i = 0; i < m.itemCount; ++i) {
            if (m.itemIsSelected(i) && !m.itemIsDir(i))
                files.push(m.itemPath(i));
        }
        if (files.length === 0) {
            var idx = currentListView().currentIndex;
            if (idx >= 0 && idx < m.itemCount && !m.itemIsDir(idx))
                files.push(m.itemPath(idx));
        }
        return files;
    }

    function triggerChecksum() {
        var cur = currentHighlightedPath();
        var curIdx = currentListView().currentIndex;
        var curIsDir = (curIdx >= 0 && curIdx < currentModel().itemCount) ? currentModel().itemIsDir(curIdx) : true;
        var files = collectSelectedRegularFiles();
        var lower = cur.toLowerCase();
        var isManifest = (!curIsDir && (lower.endsWith(".sha256") || lower.endsWith(".sha1") || lower.endsWith(".md5")));

        if (files.length === 0 && !isManifest) {
            backend.showStatus(qsTr("Select file(s) to compute checksum."));
            return;
        }

        checksumDialog.filePath = !curIsDir ? cur : (files.length > 0 ? files[0] : "");
        checksumDialog.hashes = ({});
        checksumDialog.verificationResult = "";
        verifyHashInput.text = "";
        checksumDialog.batchFilePaths = files;
        checksumDialog.batchResult = ({});
        var baseDir = currentModel().path;
        batchOutputField.text = (baseDir.endsWith("/") ? baseDir : baseDir + "/") + "checksums." + checksumDialog.batchAlgorithm;

        if (isManifest && files.length <= 1) {
            checksumDialog.activeTab = 1;
            batchVerifyField.text = cur;
            win.checksumOpen = true;
            backend.startBatchChecksumVerify(cur);
        } else if (files.length > 1) {
            checksumDialog.activeTab = 1;
            batchVerifyField.text = "";
            win.checksumOpen = true;
        } else {
            checksumDialog.activeTab = 0;
            batchVerifyField.text = "";
            win.checksumOpen = true;
            backend.startChecksumCalculation(checksumDialog.filePath);
        }
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
            { id: "quickJump", title: qsTr("Quick Jump to Folder..."), category: qsTr("Navigation"), shortcut: win.shortcuts.quickJump, run: function() { win.openCommandPalette("jump"); } },
            { id: "flatView", title: flatActive ? qsTr("Disable Flat / Branch View") : qsTr("Flat / Branch View (Recursive)"), category: qsTr("View"), shortcut: win.shortcuts.flatView, run: function() { currentModel().toggleFlatView(); } },
            { id: "toggleTheme", title: backend.isDarkTheme ? qsTr("Switch to Light Theme") : qsTr("Switch to Dark Theme"), category: qsTr("Appearance"), shortcut: win.shortcuts.themeToggle, run: function() { backend.toggleThemeMode(); } },
            { id: "quickView", title: qsTr("Toggle Quick View Panel"), category: qsTr("View"), shortcut: win.shortcuts.quickView, run: function() { win.quickViewActive = !win.quickViewActive; if (win.quickViewActive) updateQuickView(); } },
            { id: "showHidden", title: hiddenActive ? qsTr("Hide Hidden Files") : qsTr("Show Hidden Files"), category: qsTr("View"), shortcut: win.shortcuts.showHidden, run: function() { var m = currentModel(); m.setShowHidden(!m.showHidden); } },
            { id: "listView", title: qsTr("View Mode: List"), category: qsTr("View"), shortcut: win.shortcuts.viewList, run: function() { currentModel().setViewMode(0); } },
            { id: "gridView", title: qsTr("View Mode: Grid Thumbnails"), category: qsTr("View"), shortcut: win.shortcuts.viewGrid, run: function() { currentModel().setViewMode(1); } },
            { id: "quickFilter", title: qsTr("Toggle Quick Filter"), category: qsTr("View"), shortcut: win.shortcuts.filter, run: function() { toggleFilterBar(); } },
            { id: "refresh", title: qsTr("Refresh Active Panel"), category: qsTr("View"), shortcut: win.shortcuts.refresh, run: function() { currentModel().refresh(); } },
            { id: "calcSizes", title: qsTr("Calculate All Folder Sizes"), category: qsTr("View"), shortcut: win.shortcuts.calcFolderSizes, run: function() { currentModel().calculateAllFolderSizes(); backend.showStatus(qsTr("Calculating folder sizes…")); } },
            { id: "sortName", title: qsTr("Sort by Name"), category: qsTr("Sort"), shortcut: win.shortcuts.sortName, run: function() { currentModel().setSortField(0); } },
            { id: "sortExt", title: qsTr("Sort by Extension"), category: qsTr("Sort"), shortcut: win.shortcuts.sortExt, run: function() { currentModel().setSortField(1); } },
            { id: "sortDate", title: qsTr("Sort by Date"), category: qsTr("Sort"), shortcut: win.shortcuts.sortDate, run: function() { currentModel().setSortField(3); } },
            { id: "sortSize", title: qsTr("Sort by Size"), category: qsTr("Sort"), shortcut: win.shortcuts.sortSize, run: function() { currentModel().setSortField(2); } },
            { id: "switchPanel", title: qsTr("Switch Active Panel"), category: qsTr("Navigation"), shortcut: "Tab", run: function() { backend.switchPanel(); currentListView().forceActiveFocus(); updateQuickView(); } },
            { id: "editPath", title: qsTr("Edit Active Path Bar"), category: qsTr("Navigation"), shortcut: win.shortcuts.editPath, run: function() { currentPanelItem().openPathEditor(); } },
            { id: "goBack", title: qsTr("Navigate Back in History"), category: qsTr("Navigation"), shortcut: win.shortcuts.goBack, run: function() { currentModel().goBack(); } },
            { id: "goForward", title: qsTr("Navigate Forward in History"), category: qsTr("Navigation"), shortcut: win.shortcuts.goForward, run: function() { currentModel().goForward(); } },
            { id: "goUp", title: qsTr("Go to Parent Directory"), category: qsTr("Navigation"), shortcut: "Backspace", run: function() { currentModel().cdUp(); } },
            { id: "newTab", title: qsTr("Open New Tab"), category: qsTr("Tabs"), shortcut: win.shortcuts.newTab, run: function() { currentModel().addTab(); currentListView().forceActiveFocus(); } },
            { id: "closeTab", title: qsTr("Close Active Tab"), category: qsTr("Tabs"), shortcut: win.shortcuts.closeTab, run: function() { currentModel().closeTab(); currentListView().forceActiveFocus(); } },
            { id: "reopenTab", title: qsTr("Reopen Closed Tab"), category: qsTr("Tabs"), shortcut: win.shortcuts.reopenTab, run: function() { currentModel().reopenClosedTab(); currentListView().forceActiveFocus(); } },
            { id: "lockTab", title: currentModel().activeTabLockMode > 0 ? qsTr("Unlock Active Tab") : qsTr("Lock / Pin Active Tab"), category: qsTr("Tabs"), shortcut: win.shortcuts.lockTab, run: function() { currentModel().toggleTabLock(); } },
            { id: "lockTabStrict", title: qsTr("Lock Active Tab (Strict)"), category: qsTr("Tabs"), shortcut: "", run: function() { currentModel().setTabLockMode(currentModel().activeTab, 1); } },
            { id: "duplicateTab", title: qsTr("Duplicate Active Tab"), category: qsTr("Tabs"), shortcut: "", run: function() { currentModel().duplicateTab(); currentListView().forceActiveFocus(); } },
            { id: "moveTabOpposite", title: qsTr("Move Active Tab to Opposite Panel"), category: qsTr("Tabs"), shortcut: "", run: function() { backend.moveTabToOppositePanel(backend.activePanel); } },
            { id: "closeOtherTabs", title: qsTr("Close Other Unlocked Tabs"), category: qsTr("Tabs"), shortcut: "", run: function() { currentModel().closeOtherTabs(); } },
            { id: "nextTab", title: qsTr("Next Tab"), category: qsTr("Tabs"), shortcut: win.shortcuts.nextTab, run: function() { currentModel().nextTab(); currentListView().forceActiveFocus(); } },
            { id: "workspaces", title: qsTr("Workspaces (Save / Load Dual-Panel Layout)..."), category: qsTr("Workspaces"), shortcut: win.shortcuts.workspaces, run: function() { win.workspacesOpen = true; } },
            { id: "openTrash", title: qsTr("Open Trash (trash://)"), category: qsTr("Trash"), shortcut: win.shortcuts.openTrash, run: function() { backend.openTrash(); currentListView().forceActiveFocus(); } },
            { id: "emptyTrash", title: qsTr("Empty Trash..."), category: qsTr("Trash"), shortcut: "", run: function() { win.confirmEmptyTrashOpen = true; } },
            { id: "bookmarks", title: qsTr("Open Bookmarks Manager"), category: qsTr("Bookmarks"), shortcut: win.shortcuts.bookmarks, run: function() { win.bookmarksOpen = true; } },
            { id: "toggleBookmark", title: qsTr("Toggle Bookmark for Current Folder"), category: qsTr("Bookmarks"), shortcut: "", run: function() { backend.toggleBookmark(currentModel().path); } },
            { id: "swapPanels", title: qsTr("Swap Left & Right Panels"), category: qsTr("Panels"), shortcut: win.shortcuts.swapPanels, run: function() { backend.swapPanels(); } },
            { id: "syncPanels", title: qsTr("Sync Target Panel to Active"), category: qsTr("Panels"), shortcut: win.shortcuts.syncPanels, run: function() { backend.syncPanels(); } },
            { id: "compareDirs", title: qsTr("Compare Left & Right Directories"), category: qsTr("Commands"), shortcut: win.shortcuts.compareDirs, run: function() { backend.compareDirectories(); } },
            { id: "findFiles", title: qsTr("Advanced Find Files (Name / Content / Filter)..."), category: qsTr("Commands"), shortcut: win.shortcuts.findFiles, run: function() { win.openAdvancedSearchDialog(); } },
            { id: "diskUsage", title: flatActive ? qsTr("Disk Usage Analyzer (with Sizes)") : qsTr("Disk Usage Analyzer (Ctrl+Shift+D)"), category: qsTr("View"), shortcut: win.shortcuts.diskUsage, run: function() { currentModel().toggleDiskUsageMode(); } },
            { id: "syncDirs", title: qsTr("Synchronize Directories (Recursive)..."), category: qsTr("Commands"), shortcut: win.shortcuts.syncDirs, run: function() { win.openSyncDirsDialog(); } },
            { id: "duplicateFinder", title: qsTr("Find Duplicate Files..."), category: qsTr("Commands"), shortcut: win.shortcuts.duplicateFinder, run: function() { win.openDuplicateFinderDialog(); } },
            { id: "operationQueue", title: qsTr("Operation Queue & Transfer Monitor..."), category: qsTr("Commands"), shortcut: win.shortcuts.operationQueue, run: function() { win.openOperationQueueDialog(); } },
            { id: "remoteConnections", title: qsTr("Remote Connections (Google Drive / SFTP / SMB)..."), category: qsTr("Network"), shortcut: win.shortcuts.remoteConnections, run: function() { win.openRemoteConnectionsDialog(""); } },
            { id: "openWith", title: qsTr("Open With / Custom Actions..."), category: qsTr("Files"), shortcut: win.shortcuts.openWith, run: function() { win.openOpenWithDialog("", 0); } },
            { id: "diffFiles", title: qsTr("Compare Files (Visual Diff)..."), category: qsTr("Commands"), shortcut: win.shortcuts.diffFiles, run: function() { triggerFileDiff(); } },
            { id: "checksum", title: qsTr("Compute / Batch Verify Checksums..."), category: qsTr("Commands"), shortcut: "", run: function() { triggerChecksum(); } },
            { id: "settings", title: qsTr("Preferences / Settings..."), category: qsTr("View"), shortcut: win.shortcuts.settings, run: function() { win.openSettingsDialog(); } },
            { id: "terminal", title: qsTr("Open Terminal in Current Folder"), category: qsTr("Commands"), shortcut: win.shortcuts.terminal, run: function() { backend.openInTerminal(currentModel().path); } },
            { id: "focusCmdBar", title: qsTr("Focus Command Line Bar"), category: qsTr("Commands"), shortcut: win.shortcuts.cmdBarFocus, run: function() { cmdLineInput.forceFieldFocus(); } },
            { id: "toggleCmdOutput", title: qsTr("Toggle Command Output Drawer"), category: qsTr("Commands"), shortcut: win.shortcuts.cmdDrawerToggle, run: function() { win.commandDrawerOpen = !win.commandDrawerOpen; } },
            { id: "splitCombine", title: qsTr("Split / Combine File (.001 / .crc)..."), category: qsTr("Files"), shortcut: win.shortcuts.splitCombine, run: function() { win.openSplitCombineDialog(); } },
            { id: "preview", title: qsTr("View / Preview Item"), category: qsTr("Files"), shortcut: win.shortcuts.view, run: function() { triggerF3View(); } },
            { id: "editFile", title: qsTr("Edit Item with $EDITOR"), category: qsTr("Files"), shortcut: win.shortcuts.edit, run: function() { triggerF4Edit(); } },
            { id: "newFile", title: qsTr("Create New File..."), category: qsTr("Files"), shortcut: win.shortcuts.newFile, run: function() { triggerNewFile(); } },
            { id: "copy", title: qsTr("Copy Selected to Target Panel..."), category: qsTr("Files"), shortcut: win.shortcuts.copy, run: function() { triggerF5Copy(); } },
            { id: "move", title: qsTr("Move Selected to Target Panel..."), category: qsTr("Files"), shortcut: win.shortcuts.move, run: function() { triggerF6Move(); } },
            { id: "rename", title: qsTr("Rename Item..."), category: qsTr("Files"), shortcut: win.shortcuts.rename, run: function() { triggerRename(); } },
            { id: "multiRename", title: qsTr("Multi-Rename Tool..."), category: qsTr("Files"), shortcut: win.shortcuts.multiRename, run: function() { triggerMultiRename(); } },
            { id: "symlink", title: qsTr("Create Symbolic Link..."), category: qsTr("Files"), shortcut: win.shortcuts.symlink, run: function() { triggerSymlink(); } },
            { id: "mkdir", title: qsTr("Create New Folder..."), category: qsTr("Files"), shortcut: win.shortcuts.newFolder, run: function() { triggerF7NewFolder(); } },
            { id: "delete", title: qsTr("Delete Selected Item(s)"), category: qsTr("Files"), shortcut: win.shortcuts.deleteItem, run: function() { triggerF8Delete(); } },
            { id: "pack", title: qsTr("Pack Selected to Archive..."), category: qsTr("Archives"), shortcut: win.shortcuts.packArchive, run: function() { triggerPackArchive(); } },
            { id: "extract", title: qsTr("Extract Archive"), category: qsTr("Archives"), shortcut: win.shortcuts.extractArchive, run: function() { triggerExtractArchive(); } },
            { id: "properties", title: qsTr("Item Properties & Permissions"), category: qsTr("Files"), shortcut: win.shortcuts.properties, run: function() { triggerProperties(); } },
            { id: "selectAll", title: qsTr("Select All Items"), category: qsTr("Selection"), shortcut: win.shortcuts.selectAll, run: function() { currentModel().selectAll(); } },
            { id: "deselectAll", title: qsTr("Deselect All Items"), category: qsTr("Selection"), shortcut: win.shortcuts.deselectAll, run: function() { currentModel().deselectAll(); } },
            { id: "invertSel", title: qsTr("Invert Selection"), category: qsTr("Selection"), shortcut: win.shortcuts.invertSelection, run: function() { currentModel().invertSelection(); } },
            { id: "selectMask", title: qsTr("Select by Wildcard..."), category: qsTr("Selection"), shortcut: win.shortcuts.maskSelect, run: function() { openMaskDialog(true); } },
            { id: "deselectMask", title: qsTr("Deselect by Wildcard..."), category: qsTr("Selection"), shortcut: win.shortcuts.maskDeselect, run: function() { openMaskDialog(false); } },
            { id: "undo", title: qsTr("Undo Last Operation"), category: qsTr("Edit"), shortcut: win.shortcuts.undo, run: function() { backend.undoLastOperation(); } },
            { id: "shortcuts", title: qsTr("Keyboard Shortcuts"), category: qsTr("Help"), shortcut: win.shortcuts.shortcutsHelp, run: function() { win.helpOpen = true; } },
            { id: "about", title: qsTr("About TwinForge"), category: qsTr("Help"), shortcut: "", run: function() { win.aboutOpen = true; } }
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
        backend.refreshRcloneRemotes();
        backend.refreshDrives();
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
    Shortcut { sequence: win.shortcuts.shortcutsHelp; context: Qt.ApplicationShortcut; onActivated: win.helpOpen = !win.helpOpen }
    Shortcut { sequence: win.shortcuts.helpF1; context: Qt.ApplicationShortcut; onActivated: win.helpOpen = !win.helpOpen }
    Shortcut { sequence: win.shortcuts.view; context: Qt.ApplicationShortcut; onActivated: triggerF3View() }
    Shortcut { sequence: win.shortcuts.edit; context: Qt.ApplicationShortcut; onActivated: triggerF4Edit() }
    Shortcut { sequence: win.shortcuts.copy; context: Qt.ApplicationShortcut; onActivated: triggerF5Copy() }
    Shortcut { sequence: win.shortcuts.move; context: Qt.ApplicationShortcut; onActivated: triggerF6Move() }
    Shortcut { sequence: win.shortcuts.rename; context: Qt.ApplicationShortcut; onActivated: triggerRename() }
    Shortcut { sequence: win.shortcuts.newFolder; context: Qt.ApplicationShortcut; onActivated: triggerF7NewFolder() }
    Shortcut { sequence: win.shortcuts.deleteItem; context: Qt.ApplicationShortcut; onActivated: triggerF8Delete() }
    Shortcut { sequence: "Delete"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: triggerF8Delete() }
    Shortcut { sequences: [win.shortcuts.terminal, win.shortcuts.terminalAlt]; context: Qt.ApplicationShortcut; onActivated: backend.openInTerminal(currentModel().path) }
    Shortcut { sequence: win.shortcuts.exitApp; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }

    // Per-panel Tabs
    Shortcut { sequence: win.shortcuts.newTab; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().addTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: win.shortcuts.closeTab; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().closeTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: win.shortcuts.nextTab; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().nextTab();
        currentListView().forceActiveFocus();
    }}
    Shortcut { sequence: win.shortcuts.prevTab; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().prevTab();
        currentListView().forceActiveFocus();
    }}

    // System Clipboard & Undo (yields cleanly when editing text fields)
    Shortcut { sequence: win.shortcuts.copyClip; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            backend.copyToClipboard(paths);
    }}
    Shortcut { sequence: win.shortcuts.cutClip; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0)
            backend.cutToClipboard(paths);
    }}
    Shortcut { sequence: win.shortcuts.pasteClip; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        backend.pasteFromClipboard(currentModel().path);
    }}
    Shortcut { sequence: win.shortcuts.undo; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        if (!backend.undoLastOperation() && !backend.canUndo)
            backend.showStatus(qsTr("Nothing to undo."));
    }}
    Shortcut { sequence: win.shortcuts.copyNamesCsv; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        backend.copyNamesAsCsv(paths);
    }}
    Shortcut { sequence: win.shortcuts.copyPathsCsv; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: {
        var paths = getSelectedOrCurrentPaths();
        backend.copyPathsAsCsv(paths);
    }}

    // Item Properties & Permissions
    Shortcut { sequences: ["Alt+Return", win.shortcuts.properties]; enabled: !win.commandPaletteOpen; context: Qt.ApplicationShortcut; onActivated: triggerProperties() }

    Shortcut { sequence: win.shortcuts.quickView; context: Qt.ApplicationShortcut; onActivated: {
        win.quickViewActive = !win.quickViewActive;
        if (win.quickViewActive)
            updateQuickView();
    }}
    Shortcut { sequence: win.shortcuts.editPath; context: Qt.ApplicationShortcut; onActivated: currentPanelItem().openPathEditor() }
    Shortcut { sequence: win.shortcuts.swapPanels; context: Qt.ApplicationShortcut; onActivated: backend.swapPanels() }
    Shortcut { sequence: win.shortcuts.syncPanels; context: Qt.ApplicationShortcut; onActivated: backend.syncPanels() }
    Shortcut { sequence: win.shortcuts.compareDirs; context: Qt.ApplicationShortcut; onActivated: backend.compareDirectories() }
    Shortcut { sequence: win.shortcuts.multiRename; context: Qt.ApplicationShortcut; onActivated: triggerMultiRename() }
    Shortcut { sequence: win.shortcuts.packArchive; context: Qt.ApplicationShortcut; onActivated: triggerPackArchive() }
    Shortcut { sequence: win.shortcuts.extractArchive; context: Qt.ApplicationShortcut; onActivated: triggerExtractArchive() }
    Shortcut { sequence: win.shortcuts.calcFolderSizes; context: Qt.ApplicationShortcut; onActivated: {
        currentModel().calculateAllFolderSizes();
        backend.showStatus(qsTr("Calculated sizes for all folders."));
    }}
    Shortcut { sequence: win.shortcuts.goBack; context: Qt.ApplicationShortcut; onActivated: currentModel().goBack() }
    Shortcut { sequence: win.shortcuts.goForward; context: Qt.ApplicationShortcut; onActivated: currentModel().goForward() }
    Shortcut { sequence: win.shortcuts.filter; context: Qt.ApplicationShortcut; onActivated: toggleFilterBar() }
    Shortcut { sequence: win.shortcuts.bookmarks; context: Qt.ApplicationShortcut; onActivated: win.bookmarksOpen = !win.bookmarksOpen }
    Shortcut { sequence: win.shortcuts.deselectAll; context: Qt.ApplicationShortcut; onActivated: currentModel().deselectAll() }
    Shortcut { sequence: win.shortcuts.findFiles; context: Qt.ApplicationShortcut; onActivated: win.openAdvancedSearchDialog() }
    Shortcut { sequence: win.shortcuts.diskUsage; context: Qt.ApplicationShortcut; onActivated: currentModel().toggleDiskUsageMode() }
    Shortcut { sequence: win.shortcuts.syncDirs; context: Qt.ApplicationShortcut; onActivated: win.openSyncDirsDialog() }
    Shortcut { sequence: win.shortcuts.duplicateFinder; context: Qt.ApplicationShortcut; onActivated: win.openDuplicateFinderDialog() }
    Shortcut { sequence: win.shortcuts.operationQueue; context: Qt.ApplicationShortcut; onActivated: win.openOperationQueueDialog() }
    Shortcut { sequence: win.shortcuts.remoteConnections; context: Qt.ApplicationShortcut; onActivated: win.openRemoteConnectionsDialog("") }
    Shortcut { sequence: win.shortcuts.openWith; context: Qt.ApplicationShortcut; onActivated: win.openOpenWithDialog("", 0) }
    Shortcut { sequence: win.shortcuts.showHidden; context: Qt.ApplicationShortcut; onActivated: {
        var m = currentModel();
        m.setShowHidden(!m.showHidden);
    }}
    Shortcut { sequence: win.shortcuts.sortName; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(0) }
    Shortcut { sequence: win.shortcuts.sortExt; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(1) }
    Shortcut { sequence: win.shortcuts.sortDate; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(3) }
    Shortcut { sequence: win.shortcuts.sortSize; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(2) }
    Shortcut { sequence: win.shortcuts.refresh; context: Qt.ApplicationShortcut; onActivated: currentModel().refresh() }
    Shortcut { sequence: win.shortcuts.selectAll; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: currentModel().selectAll() }
    Shortcut { sequence: win.shortcuts.invertSelection; context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }

    // New File (Shift+F4)
    Shortcut { sequence: win.shortcuts.newFile; context: Qt.ApplicationShortcut; onActivated: triggerNewFile() }

    // Create Symlink (Ctrl+Shift+F5)
    Shortcut { sequence: win.shortcuts.symlink; context: Qt.ApplicationShortcut; onActivated: triggerSymlink() }

    // Visual Diff (Ctrl+Alt+D)
    Shortcut { sequence: win.shortcuts.diffFiles; context: Qt.ApplicationShortcut; onActivated: triggerFileDiff() }

    // Select / Deselect by Mask (Num+ / Num-)
    Shortcut { sequences: ["+", "Shift+=", "Num++"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: openMaskDialog(true) }
    Shortcut { sequences: ["-", "Num+-"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: openMaskDialog(false) }
    Shortcut { sequences: ["*", "Num+*"]; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }

    // View Modes (Ctrl+1 / Ctrl+2), Flat View (Ctrl+Shift+B), Palette (Ctrl+Shift+P / Ctrl+P) & Theme Toggle (Ctrl+Shift+T)
    Shortcut { sequence: win.shortcuts.viewList; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(0) }
    Shortcut { sequence: win.shortcuts.viewGrid; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(1) }
    Shortcut { sequence: win.shortcuts.flatView; context: Qt.ApplicationShortcut; onActivated: currentModel().toggleFlatView() }
    Shortcut { sequence: win.shortcuts.commandPalette; context: Qt.ApplicationShortcut; onActivated: win.openCommandPalette("commands") }
    Shortcut { sequence: win.shortcuts.quickJump; context: Qt.ApplicationShortcut; onActivated: win.openCommandPalette("jump") }
    Shortcut { sequence: win.shortcuts.themeToggle; context: Qt.ApplicationShortcut; onActivated: backend.toggleThemeMode() }
    Shortcut { sequence: win.shortcuts.workspaces; context: Qt.ApplicationShortcut; onActivated: win.workspacesOpen = !win.workspacesOpen }
    Shortcut { sequence: win.shortcuts.lockTab; context: Qt.ApplicationShortcut; onActivated: currentModel().toggleTabLock() }
    Shortcut { sequence: win.shortcuts.reopenTab; context: Qt.ApplicationShortcut; onActivated: { currentModel().reopenClosedTab(); currentListView().forceActiveFocus(); } }
    Shortcut { sequence: win.shortcuts.openTrash; context: Qt.ApplicationShortcut; onActivated: { backend.openTrash(); currentListView().forceActiveFocus(); } }
    Shortcut { sequence: win.shortcuts.cmdDrawerToggle; context: Qt.ApplicationShortcut; onActivated: win.commandDrawerOpen = !win.commandDrawerOpen }
    Shortcut { sequence: win.shortcuts.cmdBarFocus; context: Qt.ApplicationShortcut; onActivated: cmdLineInput.forceFieldFocus() }
    Shortcut { sequence: win.shortcuts.cmdInsertName; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: win.insertIntoCmdBar(false) }
    Shortcut { sequence: win.shortcuts.cmdInsertPath; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: win.insertIntoCmdBar(true) }
    Shortcut { sequence: win.shortcuts.splitCombine; context: Qt.ApplicationShortcut; onActivated: win.openSplitCombineDialog() }
    Shortcut { sequence: win.shortcuts.settings; context: Qt.ApplicationShortcut; onActivated: win.openSettingsDialog() }

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
        if (workspacesOpen) { workspacesOpen = false; currentListView().forceActiveFocus(); return; }
        if (settingsOpen) { settingsOpen = false; currentListView().forceActiveFocus(); return; }
        if (confirmEmptyTrashOpen) { confirmEmptyTrashOpen = false; currentListView().forceActiveFocus(); return; }
        if (splitCombineOpen) { splitCombineOpen = false; currentListView().forceActiveFocus(); return; }
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
        if (checksumOpen) {
            backend.cancelChecksumCalculation();
            backend.cancelBatchChecksum();
            checksumOpen = false;
            return;
        }
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
        if (win.commandDrawerOpen) {
            win.commandDrawerOpen = false;
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
                Layout.preferredHeight: 36
                implicitHeight: 36
                height: 36
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
                            text: "TwinForge"
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
                                    shortcutHint: win.shortcuts.newFile
                                    onTriggered: triggerNewFile()
                                }
                                AppMenuItem {
                                    text: qsTr("New Folder...")
                                    shortcutHint: win.shortcuts.newFolder
                                    onTriggered: triggerF7NewFolder()
                                }
                                AppMenuItem {
                                    text: qsTr("View / Preview")
                                    shortcutHint: win.shortcuts.view
                                    onTriggered: triggerF3View()
                                }
                                AppMenuItem {
                                    text: qsTr("Edit File")
                                    shortcutHint: win.shortcuts.edit
                                    onTriggered: triggerF4Edit()
                                }
                                AppMenuItem {
                                    text: qsTr("Open With / Custom Actions...")
                                    shortcutHint: win.shortcuts.openWith
                                    onTriggered: win.openOpenWithDialog("", 0)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Copy...")
                                    shortcutHint: win.shortcuts.copy
                                    onTriggered: triggerF5Copy()
                                }
                                AppMenuItem {
                                    text: qsTr("Move / Rename...")
                                    shortcutHint: win.shortcuts.move
                                    onTriggered: triggerF6Move()
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Rename")
                                    shortcutHint: win.shortcuts.rename
                                    onTriggered: triggerRename()
                                }
                                AppMenuItem {
                                    text: qsTr("Multi-Rename...")
                                    shortcutHint: win.shortcuts.multiRename
                                    onTriggered: triggerMultiRename()
                                }
                                AppMenuItem {
                                    text: qsTr("Delete...")
                                    shortcutHint: win.shortcuts.deleteItem
                                    onTriggered: triggerF8Delete()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Create Symlink...")
                                    shortcutHint: win.shortcuts.symlink
                                    onTriggered: triggerSymlink()
                                }
                                AppMenuItem {
                                    text: qsTr("Calculate Checksum...")
                                    onTriggered: triggerChecksum()
                                }
                                AppMenuItem {
                                    text: qsTr("Properties & Permissions...")
                                    shortcutHint: win.shortcuts.properties
                                    onTriggered: triggerProperties()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Pack Archive...")
                                    shortcutHint: win.shortcuts.packArchive
                                    onTriggered: triggerPackArchive()
                                }
                                AppMenuItem {
                                    text: qsTr("Extract Archive...")
                                    shortcutHint: win.shortcuts.extractArchive
                                    onTriggered: triggerExtractArchive()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Exit")
                                    shortcutHint: win.shortcuts.exitMenu
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
                                    shortcutHint: win.shortcuts.undo
                                    enabled: backend.canUndo
                                    onTriggered: backend.undoLastOperation()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Cut to Clipboard")
                                    shortcutHint: win.shortcuts.cutClip
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        if (paths.length > 0)
                                            backend.cutToClipboard(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Copy to Clipboard")
                                    shortcutHint: win.shortcuts.copyClip
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
                                    shortcutHint: win.shortcuts.pasteClip
                                    enabled: backend.canPaste
                                    onTriggered: backend.pasteFromClipboard(currentModel().path)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Copy Name(s) as Text (, )")
                                    shortcutHint: win.shortcuts.copyNamesCsv
                                    onTriggered: {
                                        var paths = getSelectedOrCurrentPaths();
                                        backend.copyNamesAsCsv(paths);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Copy Path(s) as Text (, )")
                                    shortcutHint: win.shortcuts.copyPathsCsv
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
                                    shortcutHint: win.shortcuts.selectAll
                                    onTriggered: currentModel().selectAll()
                                }
                                AppMenuItem {
                                    text: qsTr("Deselect All")
                                    shortcutHint: win.shortcuts.deselectAll
                                    onTriggered: currentModel().deselectAll()
                                }
                                AppMenuItem {
                                    text: qsTr("Invert Selection")
                                    shortcutHint: win.shortcuts.maskInvert
                                    onTriggered: currentModel().invertSelection()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Select by Pattern...")
                                    shortcutHint: win.shortcuts.maskSelect
                                    onTriggered: openMaskDialog(true)
                                }
                                AppMenuItem {
                                    text: qsTr("Deselect by Pattern...")
                                    shortcutHint: win.shortcuts.maskDeselect
                                    onTriggered: openMaskDialog(false)
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Preferences / Settings...")
                                    shortcutHint: win.shortcuts.settings
                                    onTriggered: win.openSettingsDialog()
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
                                    shortcutHint: win.shortcuts.viewList
                                    checkable: true
                                    checked: currentModel().viewMode === 0
                                    onTriggered: currentModel().setViewMode(0)
                                }
                                AppMenuItem {
                                    text: qsTr("Grid / Thumbnails")
                                    shortcutHint: win.shortcuts.viewGrid
                                    checkable: true
                                    checked: currentModel().viewMode === 1
                                    onTriggered: currentModel().setViewMode(1)
                                }
                                AppMenuItem {
                                    text: qsTr("Quick View Panel")
                                    shortcutHint: win.shortcuts.quickView
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
                                    shortcutHint: win.shortcuts.flatView
                                    checkable: true
                                    checked: currentModel().flatView
                                    onTriggered: currentModel().toggleFlatView()
                                }
                                AppMenuItem {
                                    text: qsTr("Disk Usage Analyzer")
                                    shortcutHint: win.shortcuts.diskUsage
                                    checkable: true
                                    checked: currentModel().diskUsageMode
                                    onTriggered: currentModel().toggleDiskUsageMode()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Show Hidden Files")
                                    shortcutHint: win.shortcuts.showHidden
                                    checkable: true
                                    checked: currentModel().showHidden
                                    onTriggered: {
                                        var m = currentModel();
                                        m.setShowHidden(!m.showHidden);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Filter")
                                    shortcutHint: win.shortcuts.filter
                                    onTriggered: toggleFilterBar()
                                }
                                AppMenuItem {
                                    text: qsTr("Refresh")
                                    shortcutHint: win.shortcuts.refresh
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
                                    shortcutHint: win.shortcuts.themeToggle
                                    checkable: true
                                    checked: win.isDark
                                    onTriggered: backend.themeMode = "dark"
                                }
                                AppMenuItem {
                                    text: qsTr("Theme: Light")
                                    shortcutHint: win.shortcuts.themeToggle
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
                                    shortcutHint: win.shortcuts.commandPalette
                                    onTriggered: win.openCommandPalette("commands")
                                }
                                AppMenuItem {
                                    text: qsTr("Quick Jump to Folder...")
                                    shortcutHint: win.shortcuts.quickJump
                                    onTriggered: win.openCommandPalette("jump")
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Find Files...")
                                    shortcutHint: win.shortcuts.findFiles
                                    onTriggered: win.openAdvancedSearchDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Find Duplicate Files...")
                                    shortcutHint: win.shortcuts.duplicateFinder
                                    onTriggered: win.openDuplicateFinderDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Synchronize Directories...")
                                    shortcutHint: win.shortcuts.syncDirs
                                    onTriggered: win.openSyncDirsDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Operation Queue...")
                                    shortcutHint: win.shortcuts.operationQueue
                                    onTriggered: win.openOperationQueueDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Remote Connections (Google Drive / SFTP / SMB)...")
                                    shortcutHint: win.shortcuts.remoteConnections
                                    onTriggered: win.openRemoteConnectionsDialog("")
                                }
                                AppMenuItem {
                                    text: qsTr("Compare Directories")
                                    shortcutHint: win.shortcuts.compareDirs
                                    onTriggered: backend.compareDirectories()
                                }
                                AppMenuItem {
                                    text: qsTr("Compare Files (Diff)...")
                                    shortcutHint: win.shortcuts.diffFiles
                                    onTriggered: triggerFileDiff()
                                }
                                AppMenuItem {
                                    text: qsTr("Split / Combine File...")
                                    shortcutHint: win.shortcuts.splitCombine
                                    onTriggered: win.openSplitCombineDialog()
                                }
                                AppMenuItem {
                                    text: qsTr("Toggle Command Output Drawer")
                                    shortcutHint: win.shortcuts.cmdDrawerToggle
                                    onTriggered: win.commandDrawerOpen = !win.commandDrawerOpen
                                }
                                AppMenuItem {
                                    text: qsTr("Calculate Folder Sizes")
                                    shortcutHint: win.shortcuts.calcFolderSizes
                                    onTriggered: {
                                        currentModel().calculateAllFolderSizes();
                                        backend.showStatus(qsTr("Calculated sizes for all folders."));
                                    }
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("New Tab")
                                    shortcutHint: win.shortcuts.newTab
                                    onTriggered: {
                                        currentModel().addTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Close Tab")
                                    shortcutHint: win.shortcuts.closeTab
                                    onTriggered: {
                                        currentModel().closeTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Next Tab")
                                    shortcutHint: win.shortcuts.nextTab
                                    onTriggered: {
                                        currentModel().nextTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: currentModel().activeTabLockMode > 0 ? qsTr("Unlock Active Tab") : qsTr("Lock / Pin Active Tab")
                                    shortcutHint: win.shortcuts.lockTab
                                    onTriggered: currentModel().toggleTabLock()
                                }
                                AppMenuItem {
                                    text: qsTr("Reopen Closed Tab")
                                    shortcutHint: win.shortcuts.reopenTab
                                    enabled: currentModel().canReopenClosedTab
                                    onTriggered: {
                                        currentModel().reopenClosedTab();
                                        currentListView().forceActiveFocus();
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Workspaces...")
                                    shortcutHint: win.shortcuts.workspaces
                                    onTriggered: win.workspacesOpen = true
                                }
                                AppMenuItem {
                                    text: qsTr("Open Trash")
                                    shortcutHint: win.shortcuts.openTrash
                                    onTriggered: {
                                        backend.openTrash();
                                        currentListView().forceActiveFocus();
                                    }
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Swap Panels")
                                    shortcutHint: win.shortcuts.swapPanels
                                    onTriggered: backend.swapPanels()
                                }
                                AppMenuItem {
                                    text: qsTr("Sync Panels")
                                    shortcutHint: win.shortcuts.syncPanels
                                    onTriggered: backend.syncPanels()
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("Add Bookmark")
                                    shortcutHint: win.shortcuts.bookmarks
                                    onTriggered: {
                                        if (!backend.isBookmarked(currentModel().path))
                                            backend.toggleBookmark(currentModel().path);
                                    }
                                }
                                AppMenuItem {
                                    text: qsTr("Open Terminal Here")
                                    shortcutHint: win.shortcuts.terminal
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
                                    shortcutHint: win.shortcuts.shortcutsHelp
                                    onTriggered: win.helpOpen = true
                                }

                                AppMenuSeparator {}

                                AppMenuItem {
                                    text: qsTr("About TwinForge")
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
                            shortcutHint: win.shortcuts.undo
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
                            shortcutHint: win.shortcuts.pasteClip
                            accentHighlight: true
                            onClicked: backend.pasteFromClipboard(currentModel().path)
                        }

                        // Active Workspace Pill (Ctrl+Shift+L)
                        Rectangle {
                            visible: backend.activeWorkspaceName.length > 0
                            implicitHeight: 24
                            implicitWidth: wsPillRow.implicitWidth + 14
                            radius: win.smallRadius
                            color: wsPillMouse.containsMouse ? Qt.alpha(p.accent, win.isDark ? 0.28 : 0.2) : Qt.alpha(p.accent, win.isDark ? 0.16 : 0.11)
                            border.width: 1
                            border.color: Qt.alpha(p.accent, 0.45)

                            RowLayout {
                                id: wsPillRow
                                anchors.centerIn: parent
                                spacing: 5

                                VectorIcon {
                                    width: 12
                                    height: 12
                                    kind: "workspace"
                                    iconColor: p.accent
                                }

                                Text {
                                    text: backend.activeWorkspaceName
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: p.accent
                                    Layout.maximumWidth: 120
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: wsPillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.workspacesOpen = true
                            }

                            ToolTip.visible: wsPillMouse.containsMouse
                            ToolTip.delay: 450
                            ToolTip.text: qsTr("Active workspace: %1 (Ctrl+Shift+L)").arg(backend.activeWorkspaceName)
                        }

                        ToolbarBtn {
                            label: qsTr("Quick View")
                            shortcutHint: win.shortcuts.quickView
                            active: win.quickViewActive
                            tooltipText: qsTr("Toggle Quick View (%1)").arg(win.shortcuts.quickView)
                            onClicked: {
                                win.quickViewActive = !win.quickViewActive;
                                if (win.quickViewActive)
                                    updateQuickView();
                            }
                        }

                        ToolbarBtn {
                            objectName: "paletteToolbarBtn"
                            label: qsTr("Palette")
                            shortcutHint: win.shortcuts.commandPalette
                            tooltipText: qsTr("Command Palette (%1) & Quick Jump (%2)").arg(win.shortcuts.commandPalette).arg(win.shortcuts.quickJump)
                            onClicked: win.openCommandPalette("commands")
                        }

                        ToolbarBtn {
                            label: qsTr("Shortcuts")
                            shortcutHint: win.shortcuts.shortcutsHelp
                            accentHighlight: true
                            tooltipText: qsTr("Keyboard Shortcuts (%1)").arg(win.shortcuts.shortcutsHelp)
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

            // Drives, Adaptive Bookmarks & Panel Sync Strip
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: p.subBarBg

                RowLayout {
                    id: subBarRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Flickable {
                        id: drivesFlick
                        Layout.preferredWidth: Math.min(contentWidth, Math.max(220, subBarRow.width * 0.56))
                        Layout.fillHeight: true
                        contentWidth: drivesRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        RowLayout {
                            id: drivesRow
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
                                    readonly property bool isTrashChip: modelData.isTrash === true
                                    readonly property string chipLabel: win.formatDriveChipLabel(modelData)
                                    readonly property string freeBadge: modelData.free || ""
                                    readonly property bool showFreeBadge: freeBadge.length > 0 && !(
                                        isRemoteDev && (
                                            (modelData.protocol || "") === "gdrive"
                                            || !isDevMounted
                                            || chipLabel.toUpperCase().indexOf(freeBadge.toUpperCase()) !== -1
                                        )
                                    )
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
                                            width: isTrashChip ? 14 : 16
                                            height: isTrashChip ? 14 : 16
                                            kind: isTrashChip
                                                  ? "trash"
                                                  : (isRemoteDev
                                                     ? ((modelData.protocol === "gdrive" || modelData.protocol === "rclone") ? "cloud" : "network")
                                                     : (modelData.isRemovable ? "usb" : "drive"))
                                            iconColor: !isDevMounted ? p.textDim : (currentModel().path === modelData.path ? p.accent : (isTrashChip ? p.dangerText : p.textMuted))
                                        }

                                        Text {
                                            text: chipLabel
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: isDevMounted ? p.textPrimary : p.textMuted
                                        }

                                        Text {
                                            visible: showFreeBadge
                                            text: freeBadge
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            color: isTrashChip ? p.dangerText : (isRemoteDev ? p.accent : p.textDim)
                                        }

                                        Text {
                                            visible: !isDevMounted && isRemoteDev
                                            text: "·"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: p.textDim
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
                                                        backend.connectRemoteAsync(modelData.remoteId || modelData.remoteUri);
                                                    else
                                                        backend.mountDeviceAsync(modelData.devPath);
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

                                            VectorIcon {
                                                anchors.centerIn: parent
                                                width: 11
                                                height: 11
                                                kind: "eject"
                                                iconColor: unmountMouse.containsMouse ? p.dangerAccent : p.textMuted
                                            }

                                            MouseArea {
                                                id: unmountMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (isRemoteDev)
                                                        backend.disconnectRemoteAsync(modelData.remoteId || modelData.path);
                                                    else
                                                        backend.unmountDeviceAsync(modelData.path);
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
                                                backend.connectRemoteAsync(modelData.remoteId || modelData.remoteUri);
                                            } else {
                                                backend.mountDeviceAsync(modelData.devPath);
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
                                        width: 14
                                        height: 14
                                        kind: "cloud"
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
                                ToolTip.text: qsTr("Remote Connections — Google Drive / SFTP / SMB (%1)").arg(win.shortcuts.remoteConnections)
                            }
                        }
                    }

                    Rectangle { width: 1; height: 14; color: p.borderDefault }

                    // Adaptive Bookmarks Strip with Automatic "⋯" Overflow Menu
                    Item {
                        id: bookmarksStrip
                        objectName: "bookmarksStrip"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        function estimateBookmarkChipWidth(bmPath) {
                            var label = (bmPath === "/") ? "/" : (bmPath || "").split("/").pop();
                            return Math.min(148, Math.max(54, label.length * 7 + 34));
                        }

                        readonly property int visibleBookmarkCount: {
                            var bms = backend.bookmarks || [];
                            var avail = Math.max(0, width - 130);
                            var used = 0;
                            var count = 0;
                            for (var i = 0; i < bms.length; ++i) {
                                var w = estimateBookmarkChipWidth(bms[i]) + 5;
                                var reserveOverflow = (i < bms.length - 1) ? 54 : 0;
                                if (used + w + reserveOverflow <= avail) {
                                    used += w;
                                    count++;
                                } else {
                                    break;
                                }
                            }
                            return count;
                        }
                        readonly property var visibleBookmarks: (backend.bookmarks || []).slice(0, visibleBookmarkCount)
                        readonly property var overflowBookmarks: (backend.bookmarks || []).slice(visibleBookmarkCount)

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                text: qsTr("Bookmarks")
                                font.pixelSize: 11
                                font.bold: true
                                color: p.textDim
                            }

                            Repeater {
                                model: bookmarksStrip.visibleBookmarks
                                delegate: Rectangle {
                                    implicitHeight: 22
                                    implicitWidth: Math.min(148, bmRow.implicitWidth + 12)
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
                                            elide: Text.ElideMiddle
                                            Layout.maximumWidth: 116
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
                                id: bookmarksOverflowBtn
                                objectName: "bookmarksOverflowBtn"
                                visible: bookmarksStrip.overflowBookmarks.length > 0
                                implicitHeight: 22
                                implicitWidth: overflowText.implicitWidth + 12
                                radius: win.smallRadius
                                color: bookmarksOverflowMenu.visible ? Qt.alpha(p.accent, 0.18)
                                     : (bmOverflowMouse.containsMouse ? p.chipHoverBg : p.chipBg)
                                border.width: 1
                                border.color: bookmarksOverflowMenu.visible ? p.accent : p.borderDefault

                                Text {
                                    id: overflowText
                                    anchors.centerIn: parent
                                    text: "⋯ +" + bookmarksStrip.overflowBookmarks.length
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: p.accent
                                }

                                MouseArea {
                                    id: bmOverflowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (bookmarksOverflowMenu.visible) {
                                            bookmarksOverflowMenu.close();
                                        } else {
                                            win.closeAllMenus();
                                            bookmarksOverflowMenu.popup(bookmarksOverflowBtn, 0, bookmarksOverflowBtn.height + 2);
                                        }
                                    }
                                }

                                ToolTip.visible: bmOverflowMouse.containsMouse
                                ToolTip.delay: 400
                                ToolTip.text: qsTr("More bookmarks (%1 hidden)").arg(bookmarksStrip.overflowBookmarks.length)

                                AppMenu {
                                    id: bookmarksOverflowMenu

                                    Instantiator {
                                        model: bookmarksStrip.overflowBookmarks
                                        delegate: AppMenuItem {
                                            required property var modelData
                                            text: "★ " + (modelData === "/" ? "/" : modelData.split("/").pop()) + "  (" + modelData + ")"
                                            onTriggered: {
                                                currentModel().setPath(modelData);
                                                currentListView().forceActiveFocus();
                                            }
                                        }
                                        onObjectAdded: function(index, object) { bookmarksOverflowMenu.insertItem(index, object); }
                                        onObjectRemoved: function(index, object) { bookmarksOverflowMenu.removeItem(object); }
                                    }

                                    AppMenuSeparator {
                                        visible: bookmarksStrip.overflowBookmarks.length > 0
                                    }

                                    AppMenuItem {
                                        text: qsTr("Manage Bookmarks...")
                                        shortcutHint: win.shortcuts.bookmarks
                                        onTriggered: win.bookmarksOpen = true
                                    }
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
                        shortcutHint: win.shortcuts.swapPanels
                        onClicked: backend.swapPanels()
                    }

                    ToolbarBtn {
                        implicitHeight: 22
                        label: "= " + qsTr("Sync")
                        shortcutHint: win.shortcuts.syncPanels
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

            // Dual-Panel Workspace with Interactive Resizable Splitter (double-click resets 50/50)
            Item {
                id: dualPanelWorkspace
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 6

                readonly property real handleWidth: 8
                readonly property real availWidth: Math.max(200, width - handleWidth)

                FilePanel {
                    id: leftPane
                    objectName: "leftPane"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round(dualPanelWorkspace.availWidth * win.panelSplitRatio)
                    panelIndex: 0
                    panelModel: backend.leftPanel
                    filterVisible: win.leftFilterVisible
                    onFilterVisibleChanged: win.leftFilterVisible = filterVisible
                }

                Item {
                    id: panelSplitterHandle
                    anchors.left: leftPane.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: dualPanelWorkspace.handleWidth

                    Rectangle {
                        anchors.centerIn: parent
                        width: (splitterMouse.containsMouse || splitterMouse.pressed) ? 4 : 2
                        height: (splitterMouse.containsMouse || splitterMouse.pressed) ? 44 : 28
                        radius: 2
                        color: splitterMouse.pressed ? p.accent
                               : (splitterMouse.containsMouse ? Qt.alpha(p.accent, 0.72) : p.borderStrong)
                        opacity: (splitterMouse.containsMouse || splitterMouse.pressed) ? 1.0 : 0.65
                        Behavior on width { NumberAnimation { duration: 100 } }
                        Behavior on height { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: splitterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SplitHCursor
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                var pt = splitterMouse.mapToItem(dualPanelWorkspace, mouse.x, mouse.y);
                                var ratio = (pt.x - dualPanelWorkspace.handleWidth / 2) / Math.max(1, dualPanelWorkspace.availWidth);
                                win.panelSplitRatio = Math.max(0.22, Math.min(0.78, ratio));
                            }
                        }
                        onDoubleClicked: win.panelSplitRatio = 0.5
                    }

                    ToolTip.visible: splitterMouse.containsMouse && !splitterMouse.pressed
                    ToolTip.delay: 600
                    ToolTip.text: qsTr("Drag to resize panels · Double-click to reset 50/50")
                }

                FilePanel {
                    id: rightPane
                    objectName: "rightPane"
                    anchors.left: panelSplitterHandle.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    panelIndex: 1
                    panelModel: backend.rightPanel
                    filterVisible: win.rightFilterVisible
                    onFilterVisibleChanged: win.rightFilterVisible = filterVisible
                }
            }

            // Status Notification / Background Progress Bar
            Rectangle {
                id: statusProgressBar
                readonly property bool bgAuxBusy: !backend.isBusy && (
                    backend.archiveOpRunning
                    || backend.remoteOpRunning
                    || backend.leftPanel.calculatingFolderSizes
                    || backend.rightPanel.calculatingFolderSizes
                )
                readonly property string bgAuxTitle: backend.archiveOpRunning
                    ? backend.archiveOpTitle
                    : (backend.remoteOpRunning
                        ? qsTr("Remote / Mount")
                        : qsTr("Calculating Folder Sizes"))
                readonly property string bgAuxDetail: backend.archiveOpRunning
                    ? backend.archiveOpDetail
                    : (backend.remoteOpRunning
                        ? backend.remoteOpDetail
                        : (backend.leftPanel.calculatingFolderSizes
                            ? qsTr("%1 / %2 folder(s)").arg(backend.leftPanel.folderSizeDone).arg(backend.leftPanel.folderSizeTotal)
                            : qsTr("%1 / %2 folder(s)").arg(backend.rightPanel.folderSizeDone).arg(backend.rightPanel.folderSizeTotal)))
                readonly property double bgAuxProgress: {
                    if (backend.archiveOpRunning || backend.remoteOpRunning)
                        return -1;
                    var pModel = backend.leftPanel.calculatingFolderSizes ? backend.leftPanel : backend.rightPanel;
                    return pModel.folderSizeTotal > 0 ? (pModel.folderSizeDone / pModel.folderSizeTotal) : -1;
                }
                Layout.fillWidth: true
                height: (backend.isBusy || bgAuxBusy) ? 34 : (backend.statusMessage.length > 0 ? 26 : 0)
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
                              : (statusProgressBar.bgAuxBusy ? statusProgressBar.bgAuxTitle : backend.statusMessage)
                        font.pixelSize: 11
                        font.weight: (backend.isBusy || statusProgressBar.bgAuxBusy) ? Font.DemiBold : Font.Normal
                        color: backend.isPaused ? p.warningText : ((backend.isBusy || statusProgressBar.bgAuxBusy) ? p.accent : p.textSecondary)
                        Layout.fillWidth: !backend.isBusy && !statusProgressBar.bgAuxBusy
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: backend.isBusy || statusProgressBar.bgAuxBusy
                        text: backend.isBusy ? backend.busyDetail : statusProgressBar.bgAuxDetail
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
                        visible: backend.isBusy || (statusProgressBar.bgAuxBusy && statusProgressBar.bgAuxProgress >= 0)
                        text: Math.round((backend.isBusy ? backend.busyProgress : statusProgressBar.bgAuxProgress) * 100) + "%"
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: p.textSecondary
                    }

                    // Slim custom progress track
                    Rectangle {
                        visible: backend.isBusy || statusProgressBar.bgAuxBusy
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 6
                        radius: 3
                        color: p.borderDefault
                        clip: true

                        Rectangle {
                            width: (backend.isBusy || statusProgressBar.bgAuxProgress >= 0)
                                   ? parent.width * Math.max(0, Math.min(1, backend.isBusy ? backend.busyProgress : statusProgressBar.bgAuxProgress))
                                   : parent.width * 0.42
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
                        visible: (backend.isBusy && backend.canCancel) || statusProgressBar.bgAuxBusy
                        implicitHeight: 22
                        label: qsTr("Cancel")
                        accentHighlight: !backend.isPaused
                        onClicked: {
                            if (backend.isBusy) {
                                backend.cancelOperation();
                            } else if (backend.archiveOpRunning) {
                                backend.cancelArchiveOperation();
                            } else if (backend.remoteOpRunning) {
                                backend.cancelRemoteOperation();
                            } else {
                                backend.leftPanel.cancelFolderSizeCalculation();
                                backend.rightPanel.cancelFolderSizeCalculation();
                            }
                        }
                    }
                }
            }

            // Collapsible Live Command Output Drawer (Ctrl+O)
            Rectangle {
                visible: Layout.preferredHeight > 0
                Layout.fillWidth: true
                Layout.preferredHeight: win.commandDrawerOpen ? 176 : 0
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                clip: true
                color: p.inputBg
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: p.borderDefault
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: p.subBarBg

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: backend.commandRunning
                                      ? qsTr("Running: %1").arg(backend.commandRunningText)
                                      : qsTr("Command Output")
                                font.pixelSize: 11
                                font.bold: true
                                color: backend.commandRunning ? p.accent : p.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: !backend.commandRunning && backend.commandOutput.length > 0
                                implicitHeight: 18
                                implicitWidth: exitCodeText.implicitWidth + 10
                                radius: 3
                                color: backend.commandLastExitCode === 0
                                       ? Qt.alpha(p.accent, 0.16)
                                       : Qt.alpha(p.dangerAccent, 0.16)
                                Text {
                                    id: exitCodeText
                                    anchors.centerIn: parent
                                    text: "exit " + backend.commandLastExitCode
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    font.bold: true
                                    color: backend.commandLastExitCode === 0 ? p.accent : p.dangerText
                                }
                            }

                            ToolbarBtn {
                                visible: backend.commandRunning
                                label: qsTr("Stop")
                                tooltipText: qsTr("Cancel running command")
                                onClicked: backend.cancelCommand()
                            }

                            ToolbarBtn {
                                label: qsTr("Copy")
                                btnEnabled: backend.commandOutput.length > 0
                                onClicked: backend.copyTextToClipboard(backend.commandOutput, qsTr("Command output copied to clipboard."))
                            }

                            ToolbarBtn {
                                label: qsTr("Clear")
                                btnEnabled: backend.commandOutput.length > 0
                                onClicked: backend.clearCommandOutput()
                            }

                            IconBtn {
                                implicitWidth: 22
                                implicitHeight: 22
                                iconKind: "close"
                                tooltipText: qsTr("Hide output drawer (Ctrl+O / Esc)")
                                onClicked: {
                                    win.commandDrawerOpen = false;
                                    currentListView().forceActiveFocus();
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

                    ScrollView {
                        id: cmdDrawerScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        background: Rectangle { color: p.inputBg }
                        ScrollBar.vertical: AppScrollBar {}

                        TextEdit {
                            id: cmdDrawerText
                            width: cmdDrawerScroll.availableWidth
                            text: backend.commandOutput.length > 0
                                  ? backend.commandOutput
                                  : qsTr("No command output yet. Type a command below (Up/Down for history, Ctrl+Enter to insert filename).")
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            font.pixelSize: 11
                            color: backend.commandOutput.length > 0 ? p.textSecondary : p.textDim
                            selectionColor: Qt.alpha(p.accent, 0.35)
                            selectedTextColor: p.textOnHover
                            leftPadding: 10
                            rightPadding: 10
                            topPadding: 6
                            bottomPadding: 6
                            onTextChanged: {
                                if (cmdDrawerScroll.ScrollBar.vertical)
                                    cmdDrawerScroll.ScrollBar.vertical.position = Math.max(0, 1.0 - cmdDrawerScroll.ScrollBar.vertical.size);
                            }
                        }
                    }
                }
            }

            // Mini Command Line Bar (Async + History + Built-in cd)
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
                    anchors.rightMargin: 8
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
                        placeholderText: qsTr("Run command (Ctrl+E focus, ↑/↓ history, Ctrl+Enter insert name, cd <dir>)")
                        onTextEdited: win.cmdHistoryIndex = -1
                        onUpPressed: win.navigateCmdHistory(-1)
                        onDownPressed: win.navigateCmdHistory(1)
                        onAccepted: {
                            var cmd = cmdLineInput.text.trim();
                            if (cmd.length > 0) {
                                cmdLineInput.text = "";
                                win.cmdHistoryIndex = -1;
                                win.cmdHistoryDraft = "";
                                var isSimpleCd = (cmd === "cd" || (cmd.indexOf("cd ") === 0 && cmd.indexOf("&&") === -1 && cmd.indexOf(";") === -1 && cmd.indexOf("|") === -1));
                                if (!isSimpleCd)
                                    win.commandDrawerOpen = true;
                                backend.runCommandAsync(cmd);
                                currentListView().forceActiveFocus();
                            }
                        }
                        onEscaped: currentListView().forceActiveFocus()
                    }

                    ToolbarBtn {
                        visible: backend.commandRunning
                        label: qsTr("Stop")
                        tooltipText: qsTr("Cancel running command")
                        onClicked: backend.cancelCommand()
                    }

                    ToolbarBtn {
                        label: qsTr("Output")
                        active: win.commandDrawerOpen
                        tooltipText: qsTr("Toggle Command Output Drawer (Ctrl+O)")
                        onClicked: win.commandDrawerOpen = !win.commandDrawerOpen
                    }
                }
            }

            // Bottom Function Keys Bar (F3-F10)
            Rectangle {
                Layout.fillWidth: true
                height: 32
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

                    FKeyButton { Layout.preferredWidth: 96; keyLabel: win.shortcuts.view; actionLabel: qsTr("View"); onClicked: triggerF3View() }
                    FKeyButton { Layout.preferredWidth: 96; keyLabel: win.shortcuts.edit; actionLabel: qsTr("Edit"); onClicked: triggerF4Edit() }
                    FKeyButton { objectName: "f5KeyBtn"; Layout.preferredWidth: 196; keyLabel: win.shortcuts.copy; actionLabel: win.f5ActionLabel; tooltipText: win.f5Tooltip; onClicked: triggerF5Copy() }
                    FKeyButton { objectName: "f6KeyBtn"; Layout.preferredWidth: 196; keyLabel: win.shortcuts.move; actionLabel: win.f6ActionLabel; tooltipText: win.f6Tooltip; onClicked: triggerF6Move() }
                    FKeyButton { Layout.preferredWidth: 108; keyLabel: win.shortcuts.newFolder; actionLabel: qsTr("New Folder"); onClicked: triggerF7NewFolder() }
                    FKeyButton { Layout.preferredWidth: 98; keyLabel: win.shortcuts.deleteItem; actionLabel: qsTr("Delete"); onClicked: triggerF8Delete() }
                    FKeyButton { Layout.preferredWidth: 102; keyLabel: win.shortcuts.terminal; actionLabel: qsTr("Terminal"); onClicked: backend.openInTerminal(currentModel().path) }
                    FKeyButton { Layout.preferredWidth: 88; keyLabel: win.shortcuts.exitApp; actionLabel: qsTr("Exit"); onClicked: Qt.quit() }
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

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 110; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 85; easing.type: Easing.InCubic }
        }

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

            AppCheckBox {
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
        title: currentModel().isTrashView ? qsTr("Delete Permanently from Trash (F8)") : qsTr("Delete Files (F8)")
        standardButtons: Dialog.Yes | Dialog.No

        ColumnLayout {
            spacing: 10
            Text {
                text: currentModel().isTrashView
                      ? qsTr("Permanently delete %1 selected item(s) from Trash? This cannot be undone.").arg(getSelectedOrCurrentPaths().length)
                      : qsTr("Are you sure you want to delete %1 selected item(s)?").arg(getSelectedOrCurrentPaths().length)
                color: p.textSecondary
                font.pixelSize: 13
            }
            AppCheckBox {
                id: permDeleteCheck
                visible: !currentModel().isTrashView
                text: qsTr("Permanent delete (bypass trash)")
                checked: false
            }
        }

        onAccepted: {
            win.confirmDeleteOpen = false;
            if (currentModel().isTrashView)
                backend.deleteFromTrashPermanently(getSelectedOrCurrentPaths());
            else
                backend.deleteItems(getSelectedOrCurrentPaths(), permDeleteCheck.checked);
        }
        onRejected: win.confirmDeleteOpen = false
    }

    // Confirm Empty Trash Dialog
    AppDialog {
        id: emptyTrashDialog
        visible: win.confirmEmptyTrashOpen
        title: qsTr("Empty Trash")
        standardButtons: Dialog.Yes | Dialog.No

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Permanently delete all %1 item(s) in Trash? This cannot be undone.").arg(backend.trashCount)
                color: p.textSecondary
                font.pixelSize: 13
            }
        }

        onAccepted: {
            win.confirmEmptyTrashOpen = false;
            backend.emptyTrash();
            currentListView().forceActiveFocus();
        }
        onRejected: win.confirmEmptyTrashOpen = false
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
                ScrollBar.vertical: AppScrollBar {}

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

    // Workspaces Dialog (Ctrl+Shift+L) — Save & Restore Dual-Panel Layouts
    AppDialog {
        id: workspacesDialog
        visible: win.workspacesOpen
        title: qsTr("Workspaces (Ctrl+Shift+L)")
        width: 580
        height: 420
        standardButtons: Dialog.Close

        onOpened: {
            workspaceNameField.text = backend.activeWorkspaceName || "";
            workspaceNameField.forceFieldFocus();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Text {
                text: qsTr("Save both panels' tabs, lock states, and sort order as a named workspace.")
                color: p.textMuted
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CompactField {
                    id: workspaceNameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Workspace name (e.g. Web Dev, Media, Server)...")
                    onAccepted: {
                        if (workspaceNameField.text.trim().length > 0) {
                            backend.saveWorkspace(workspaceNameField.text);
                            workspaceNameField.text = "";
                        }
                    }
                    onEscaped: win.workspacesOpen = false
                }

                ToolbarBtn {
                    label: qsTr("Save Layout")
                    accentHighlight: true
                    btnEnabled: workspaceNameField.text.trim().length > 0
                    onClicked: {
                        backend.saveWorkspace(workspaceNameField.text);
                        workspaceNameField.text = "";
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: backend.workspaces.length === 0
                    text: qsTr("No workspaces saved yet.")
                    color: p.textDim
                    font.pixelSize: 12
                }

                ListView {
                    anchors.fill: parent
                    visible: backend.workspaces.length > 0
                    clip: true
                    spacing: 4
                    model: backend.workspaces
                    ScrollBar.vertical: AppScrollBar {}

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 46
                        radius: win.smallRadius
                        color: wsMouse.containsMouse ? p.rowHoverBg : (index % 2 === 0 ? p.rowAltBg : "transparent")
                        border.width: modelData.name === backend.activeWorkspaceName ? 1 : 0
                        border.color: Qt.alpha(p.accent, 0.55)

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onDoubleClicked: {
                                backend.loadWorkspace(modelData.id || modelData.name);
                                win.workspacesOpen = false;
                                currentListView().forceActiveFocus();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            VectorIcon {
                                width: 16
                                height: 16
                                kind: "workspace"
                                iconColor: modelData.name === backend.activeWorkspaceName ? p.accent : p.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.name || ""
                                        color: p.textPrimary
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        visible: modelData.name === backend.activeWorkspaceName
                                        implicitHeight: 16
                                        implicitWidth: activeWsBadge.implicitWidth + 8
                                        radius: 3
                                        color: Qt.alpha(p.accent, 0.18)
                                        Text {
                                            id: activeWsBadge
                                            anchors.centerIn: parent
                                            text: qsTr("Active")
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: p.accent
                                        }
                                    }
                                }

                                Text {
                                    text: qsTr("Left: %1 tab(s) · Right: %2 tab(s)")
                                          .arg((modelData.leftTabs || []).length)
                                          .arg((modelData.rightTabs || []).length)
                                    color: p.textMuted
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            ToolbarBtn {
                                label: qsTr("Load")
                                accentHighlight: true
                                onClicked: {
                                    backend.loadWorkspace(modelData.id || modelData.name);
                                    win.workspacesOpen = false;
                                    currentListView().forceActiveFocus();
                                }
                            }

                            ToolbarBtn {
                                label: qsTr("Update")
                                tooltipText: qsTr("Overwrite this workspace with the current dual-panel layout")
                                onClicked: backend.saveWorkspace(modelData.name)
                            }

                            IconBtn {
                                implicitWidth: 24
                                implicitHeight: 24
                                iconKind: "close"
                                tooltipText: qsTr("Delete workspace")
                                onClicked: backend.deleteWorkspace(modelData.id || modelData.name)
                            }
                        }
                    }
                }
            }
        }

        onRejected: {
            win.workspacesOpen = false;
            currentListView().forceActiveFocus();
        }
    }

    // Split / Combine File Dialog (Ctrl+Alt+S) — .001/.002... + .crc SHA-256 verification
    AppDialog {
        id: splitCombineDialog
        visible: win.splitCombineOpen
        title: (win.splitSourceInfo.mode === "combine")
               ? qsTr("Combine Split Files (Ctrl+Alt+S)")
               : qsTr("Split File (Ctrl+Alt+S)")
        width: 540
        standardButtons: Dialog.NoButton

        property double customSizeMb: 100
        property string lastResultMsg: ""
        property bool lastResultOk: true

        onOpened: {
            lastResultMsg = "";
            splitPartSizeField.text = String(customSizeMb);
        }

        Connections {
            target: backend
            function onSplitOperationFinished(result) {
                splitCombineDialog.lastResultMsg = result.message || "";
                splitCombineDialog.lastResultOk = result.success === true;
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            // Source info box
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: splitInfoCol.implicitHeight + 14
                radius: win.smallRadius
                color: p.rowAltBg
                border.width: 1
                border.color: p.borderSubtle

                ColumnLayout {
                    id: splitInfoCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Text {
                        text: (win.splitSourceInfo.mode === "combine")
                              ? qsTr("Combine: %1 (%2 parts, %3)")
                                .arg(win.splitSourceInfo.fileName || "")
                                .arg(win.splitSourceInfo.partCount || 0)
                                .arg(win.splitSourceInfo.formattedSize || "")
                              : qsTr("Split: %1 (%2)")
                                .arg(win.splitSourceInfo.fileName || "")
                                .arg(win.splitSourceInfo.formattedSize || "")
                        color: p.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: win.splitSourceInfo.mode === "combine"
                        text: win.splitSourceInfo.hasCrc
                              ? qsTr(".crc manifest detected — SHA-256 integrity will be verified automatically.")
                              : qsTr("No .crc manifest found — parts will be concatenated sequentially.")
                        color: win.splitSourceInfo.hasCrc ? p.accent : p.textMuted
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Split part size controls (Split mode only)
            ColumnLayout {
                visible: win.splitSourceInfo.mode !== "combine"
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Part size (MB):")
                    color: p.textSecondary
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    CompactField {
                        id: splitPartSizeField
                        Layout.preferredWidth: 110
                        monospace: true
                        text: "100"
                        onTextEdited: {
                            var v = parseFloat(text);
                            if (!isNaN(v) && v > 0)
                                splitCombineDialog.customSizeMb = v;
                        }
                    }

                    Repeater {
                        model: [
                            { label: "10 MB", mb: 10 },
                            { label: "100 MB", mb: 100 },
                            { label: "700 MB", mb: 700 },
                            { label: "4 GB", mb: 4096 }
                        ]
                        delegate: FilterPill {
                            label: modelData.label
                            active: Math.abs(splitCombineDialog.customSizeMb - modelData.mb) < 0.01
                            onClicked: {
                                splitCombineDialog.customSizeMb = modelData.mb;
                                splitPartSizeField.text = String(modelData.mb);
                            }
                        }
                    }
                }

                Text {
                    readonly property real partBytes: Math.max(1, splitCombineDialog.customSizeMb * 1024 * 1024)
                    readonly property int estParts: Math.max(1, Math.ceil((win.splitSourceInfo.totalBytes || 0) / partBytes))
                    text: qsTr("Estimated output: %1 part(s)").arg(estParts)
                    color: p.textMuted
                    font.pixelSize: 11
                    font.family: "monospace"
                }

                AppCheckBox {
                    id: splitWriteCrcCheck
                    text: qsTr("Write .crc verification manifest (SHA-256)")
                    checked: true
                }
            }

            // Target directory
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: qsTr("Destination folder:")
                    color: p.textSecondary
                    font.pixelSize: 12
                }
                CompactField {
                    id: splitTargetDirField
                    Layout.fillWidth: true
                    monospace: true
                    placeholderText: qsTr("Target directory...")
                }
            }

            // Progress bar when running
            ColumnLayout {
                visible: backend.splitOpRunning
                Layout.fillWidth: true
                spacing: 4

                AppProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: backend.splitOpProgress
                }
                Text {
                    text: backend.splitOpDetail
                    color: p.accent
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Outcome banner
            Text {
                visible: !backend.splitOpRunning && splitCombineDialog.lastResultMsg.length > 0
                text: splitCombineDialog.lastResultMsg
                color: splitCombineDialog.lastResultOk ? p.accent : p.dangerText
                font.pixelSize: 11
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                ToolbarBtn {
                    visible: backend.splitOpRunning
                    label: qsTr("Cancel")
                    onClicked: backend.cancelSplitOperation()
                }

                ToolbarBtn {
                    visible: !backend.splitOpRunning
                    label: (win.splitSourceInfo.mode === "combine") ? qsTr("Combine Files") : qsTr("Split File")
                    accentHighlight: true
                    onClicked: {
                        splitCombineDialog.lastResultMsg = "";
                        if (win.splitSourceInfo.mode === "combine") {
                            backend.startCombineFiles(win.splitSourcePath, splitTargetDirField.text);
                        } else {
                            var mb = parseFloat(splitPartSizeField.text);
                            if (isNaN(mb) || mb <= 0)
                                mb = 100;
                            var bytes = Math.max(1024, Math.round(mb * 1024 * 1024));
                            backend.startSplitFile(win.splitSourcePath, splitTargetDirField.text, bytes, splitWriteCrcCheck.checked);
                        }
                    }
                }

                ToolbarBtn {
                    label: qsTr("Close")
                    onClicked: {
                        if (backend.splitOpRunning)
                            backend.cancelSplitOperation();
                        win.splitCombineOpen = false;
                        currentListView().forceActiveFocus();
                    }
                }
            }
        }

        onRejected: {
            if (backend.splitOpRunning)
                backend.cancelSplitOperation();
            win.splitCombineOpen = false;
            currentListView().forceActiveFocus();
        }
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
                    AppComboBox {
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
                AppComboBox {
                    id: mrCaseCombo
                    model: [qsTr("Unchanged"), qsTr("lowercase"), qsTr("UPPERCASE"), qsTr("Title Case")]
                    onCurrentIndexChanged: refreshMultiRenamePreview()
                }

                AppCheckBox {
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
            backend.packArchiveAsync(getSelectedOrCurrentPaths(), packArchiveField.text);
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: qsTr("Path: %1 | Size: %2 | Modified: %3").arg(previewData.path || "").arg(previewData.formattedSize || "").arg(previewData.modified || "")
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.textMuted
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }
                Text {
                    visible: backend.previewLoading
                    text: qsTr("Loading…")
                    font.pixelSize: 11
                    font.bold: true
                    color: p.accent
                }
            }

            RichPreviewSurface {
                Layout.fillWidth: true
                Layout.fillHeight: true
                previewItem: win.previewData
                onRequestPage: function(page) {
                    if (win.previewData && win.previewData.path)
                        backend.requestPreview(win.previewData.path, page, "modal");
                }
            }
        }

        onRejected: {
            backend.cancelPreview("modal");
            win.previewOpen = false;
        }
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

    // Remote Connections Manager Dialog (Google Drive / rclone / SFTP / SMB / SSHFS)
    AppDialog {
        id: remoteConnectionsDialog
        visible: win.remoteConnectionsOpen
        title: qsTr("Remote Connections — Google Drive / SFTP / SMB (Ctrl+Shift+M)")
        width: Math.min(860, win.width - 40)
        height: Math.min(600, win.height - 40)
        standardButtons: Dialog.NoButton

        property string editingId: ""
        property string protocol: "gdrive"
        readonly property bool isCloudProto: protocol === "gdrive" || protocol === "rclone"

        function selectProtocol(newProto) {
            protocol = newProto;
            if (!rcPortField) return;
            if (newProto === "smb")
                rcPortField.text = "445";
            else if (newProto === "sftp" || newProto === "sshfs")
                rcPortField.text = "22";
            else
                rcPortField.text = "";
        }

        function resetForm() {
            editingId = "";
            var defaultProto = backend.rcloneAvailable ? "gdrive" : "sftp";
            protocol = defaultProto;
            if (!rcUriField) return;
            rcUriField.text = "";
            rcNameField.text = "";
            rcHostField.text = "";
            rcPortField.text = (defaultProto === "sftp") ? "22" : "";
            rcUserField.text = "";
            rcPathField.text = "/";
            rcDomainField.text = "";
            if (defaultProto === "gdrive" && backend.rcloneRemotes.length > 0) {
                var first = backend.rcloneRemotes[0];
                rcHostField.text = first.name || "gdrive";
                rcNameField.text = first.label || "";
                rcUriField.text = first.uri || "";
            }
            rcHostField.forceFieldFocus();
        }

        function loadConnectionMap(m) {
            if (!m || !rcUriField) return;
            editingId = m.id || "";
            protocol = m.protocol || "sftp";
            rcUriField.text = m.uri || "";
            rcNameField.text = m.name || "";
            rcHostField.text = m.host || "";
            rcPortField.text = isCloudProto ? "" : String(m.port || (protocol === "smb" ? 445 : 22));
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
                backend.showStatus(qsTr("Enter a valid URI like gdrive://gdrive or sftp://user@host/path"));
                return;
            }
            protocol = parsed.protocol || "sftp";
            rcHostField.text = parsed.host || "";
            rcPortField.text = isCloudProto ? "" : String(parsed.port || (protocol === "smb" ? 445 : 22));
            rcUserField.text = parsed.user || "";
            rcPathField.text = parsed.remotePath || "/";
            rcDomainField.text = parsed.domain || "";
            if (!rcNameField.text.trim())
                rcNameField.text = parsed.name || parsed.host;
        }

        function buildFormMap() {
            var portNum = 0;
            if (!isCloudProto) {
                portNum = parseInt(rcPortField.text, 10);
                if (isNaN(portNum) || portNum <= 0)
                    portNum = (protocol === "smb") ? 445 : 22;
            }
            return {
                id: editingId,
                name: rcNameField.text.trim(),
                protocol: protocol,
                host: rcHostField.text.trim(),
                port: portNum,
                user: isCloudProto ? "" : rcUserField.text.trim(),
                remotePath: rcPathField.text.trim(),
                domain: isCloudProto ? "" : rcDomainField.text.trim(),
                uri: rcUriField.text.trim()
            };
        }

        Connections {
            target: backend
            function onGdriveAuthFinished(ok, remoteName, msg) {
                if (!ok || !rcHostField) return;
                remoteConnectionsDialog.protocol = "gdrive";
                rcHostField.text = remoteName;
                rcNameField.text = "Google Drive (" + remoteName + ")";
                rcPathField.text = "/";
                rcUriField.text = "gdrive://" + remoteName + "/";
            }
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
                                    btnEnabled: !backend.remoteOpRunning
                                    onClicked: {
                                        if (modelData)
                                            backend.connectRemoteAsync(modelData.id);
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
                                    if (modelData && !backend.remoteOpRunning)
                                        backend.connectRemoteAsync(modelData.id);
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
                        text: qsTr("No saved connections yet.\nPick Google Drive or configure SFTP, SMB, or SSHFS on the right.")
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
                        placeholderText: "gdrive://gdrive  |  sftp://user@server/var/www  |  smb://server/share"
                        onAccepted: remoteConnectionsDialog.parseFromUriBar()
                    }
                    ToolbarBtn {
                        label: qsTr("Parse")
                        onClicked: remoteConnectionsDialog.parseFromUriBar()
                    }
                }

                // Protocol Pills
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    FilterPill {
                        label: "Google Drive (rclone)"
                        active: remoteConnectionsDialog.protocol === "gdrive"
                        onClicked: remoteConnectionsDialog.selectProtocol("gdrive")
                    }
                    FilterPill {
                        label: "rclone (Cloud)"
                        active: remoteConnectionsDialog.protocol === "rclone"
                        onClicked: remoteConnectionsDialog.selectProtocol("rclone")
                    }
                    FilterPill {
                        label: "SFTP / SSH (GVFS)"
                        active: remoteConnectionsDialog.protocol === "sftp"
                        onClicked: remoteConnectionsDialog.selectProtocol("sftp")
                    }
                    FilterPill {
                        label: "SMB / Samba (GVFS)"
                        active: remoteConnectionsDialog.protocol === "smb"
                        onClicked: remoteConnectionsDialog.selectProtocol("smb")
                    }
                    FilterPill {
                        label: "SSHFS (FUSE)"
                        active: remoteConnectionsDialog.protocol === "sshfs"
                        onClicked: remoteConnectionsDialog.selectProtocol("sshfs")
                    }
                }

                // Discovered rclone remotes quick selector
                Rectangle {
                    Layout.fillWidth: true
                    visible: remoteConnectionsDialog.isCloudProto && backend.rcloneRemotes.length > 0
                    implicitHeight: rcloneChipsCol.implicitHeight + 14
                    color: p.subBarBg
                    radius: win.smallRadius
                    border.width: 1
                    border.color: p.borderSubtle

                    ColumnLayout {
                        id: rcloneChipsCol
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: qsTr("Detected rclone Remotes (%1):").arg(backend.rcloneRemotes.length)
                                font.pixelSize: 11
                                font.bold: true
                                color: p.textSecondary
                                Layout.fillWidth: true
                            }
                            ToolbarBtn {
                                implicitHeight: 22
                                label: qsTr("Refresh")
                                onClicked: backend.refreshRcloneRemotes()
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: backend.rcloneRemotes
                                delegate: FilterPill {
                                    label: (modelData.isMounted ? "● " : "") + (modelData.name + " (" + modelData.type + ")")
                                    active: rcHostField.text.trim() === modelData.name
                                    onClicked: {
                                        remoteConnectionsDialog.editingId = "";
                                        remoteConnectionsDialog.protocol = modelData.protocol || "gdrive";
                                        rcHostField.text = modelData.name || "";
                                        rcNameField.text = modelData.label || "";
                                        rcPathField.text = "/";
                                        rcUriField.text = modelData.uri || "";
                                    }
                                }
                            }
                        }
                    }
                }

                // New Google Drive Account OAuth Setup Card
                Rectangle {
                    Layout.fillWidth: true
                    visible: remoteConnectionsDialog.protocol === "gdrive"
                    implicitHeight: gdriveAuthCol.implicitHeight + 14
                    color: Qt.alpha(p.accent, win.isDark ? 0.08 : 0.05)
                    radius: win.smallRadius
                    border.width: 1
                    border.color: Qt.alpha(p.accent, 0.25)

                    ColumnLayout {
                        id: gdriveAuthCol
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: qsTr("Add Google Account:")
                                font.pixelSize: 11
                                font.bold: true
                                color: p.textSecondary
                            }
                            CompactField {
                                id: gdriveNewAliasField
                                monospace: true
                                text: "gdrive"
                                Layout.preferredWidth: 140
                                placeholderText: "gdrive_work"
                            }
                            ToolbarBtn {
                                implicitHeight: 26
                                label: backend.gdriveAuthRunning ? qsTr("Authorizing...") : qsTr("Sign in with Google")
                                accentHighlight: !backend.gdriveAuthRunning
                                btnEnabled: !backend.gdriveAuthRunning && backend.rcloneAvailable
                                onClicked: backend.startGoogleDriveAuth(gdriveNewAliasField.text.trim())
                            }
                            ToolbarBtn {
                                implicitHeight: 26
                                visible: backend.gdriveAuthRunning
                                label: qsTr("Cancel")
                                onClicked: backend.cancelGoogleDriveAuth()
                            }
                            Item { Layout.fillWidth: true }
                            ToolbarBtn {
                                implicitHeight: 26
                                visible: backend.gdriveAuthUrl.length > 0
                                label: qsTr("Open Link")
                                onClicked: Qt.openUrlExternally(backend.gdriveAuthUrl)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: backend.gdriveAuthStatus.length > 0 || !backend.rcloneAvailable
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            color: backend.rcloneAvailable ? p.textMuted : p.dangerText
                            text: backend.rcloneAvailable
                                  ? backend.gdriveAuthStatus
                                  : qsTr("rclone is not installed. Install rclone to authorize and mount Google Drive.")
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
                        placeholderText: remoteConnectionsDialog.protocol === "gdrive"
                                         ? qsTr("My Google Drive")
                                         : qsTr("Production Server / NAS Media")
                    }

                    Text {
                        text: remoteConnectionsDialog.isCloudProto ? qsTr("rclone Remote:") : qsTr("Host / Server:")
                        color: p.textMuted
                        font.pixelSize: 12
                    }
                    CompactField {
                        id: rcHostField
                        monospace: true
                        Layout.fillWidth: true
                        Layout.columnSpan: remoteConnectionsDialog.isCloudProto ? 3 : 1
                        placeholderText: remoteConnectionsDialog.isCloudProto
                                         ? "gdrive"
                                         : "192.168.1.50 / nas.local"
                    }

                    Text { visible: !remoteConnectionsDialog.isCloudProto; text: qsTr("Port:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcPortField
                        visible: !remoteConnectionsDialog.isCloudProto
                        monospace: true
                        text: "22"
                        Layout.preferredWidth: 82
                    }

                    Text { visible: !remoteConnectionsDialog.isCloudProto; text: qsTr("Username:"); color: p.textMuted; font.pixelSize: 12 }
                    CompactField {
                        id: rcUserField
                        visible: !remoteConnectionsDialog.isCloudProto
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: qsTr("user (optional for guest SMB)")
                    }

                    Text {
                        visible: !remoteConnectionsDialog.isCloudProto
                        text: remoteConnectionsDialog.protocol === "smb" ? qsTr("Domain:") : qsTr("SSH Key:")
                        color: p.textMuted
                        font.pixelSize: 12
                    }
                    CompactField {
                        id: rcDomainField
                        visible: !remoteConnectionsDialog.isCloudProto
                        monospace: true
                        Layout.fillWidth: true
                        placeholderText: remoteConnectionsDialog.protocol === "smb" ? "WORKGROUP" : qsTr("~/.ssh/id_ed25519 (sshfs)")
                    }

                    Text {
                        text: remoteConnectionsDialog.protocol === "smb"
                              ? qsTr("Share / Path:")
                              : (remoteConnectionsDialog.isCloudProto ? qsTr("Drive Folder:") : qsTr("Remote Path:"))
                        color: p.textMuted
                        font.pixelSize: 12
                    }
                    CompactField {
                        id: rcPathField
                        monospace: true
                        text: "/"
                        Layout.fillWidth: true
                        Layout.columnSpan: 3
                        placeholderText: remoteConnectionsDialog.protocol === "smb"
                                         ? "/share/folder"
                                         : (remoteConnectionsDialog.isCloudProto ? "/ or /Documents" : "/var/www")
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
                        text: remoteConnectionsDialog.isCloudProto
                              ? qsTr("Mounts rclone remote via FUSE (--vfs-cache-mode writes) under ~/.cache/twinforge/mounts/ and appears in your Drives bar.")
                              : (remoteConnectionsDialog.protocol === "sshfs"
                                 ? qsTr("SSHFS mounts via FUSE under ~/.cache/twinforge/mounts/ using key authentication.")
                                 : qsTr("GVFS mounts via 'gio mount' (uses SSH Agent / GNOME Keyring) and appears directly in your Drives bar."))
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

                    Text {
                        visible: backend.remoteOpRunning
                        text: backend.remoteOpDetail
                        font.pixelSize: 11
                        color: p.accent
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item { visible: !backend.remoteOpRunning; Layout.fillWidth: true }

                    ToolbarBtn {
                        visible: backend.remoteOpRunning
                        label: qsTr("Cancel")
                        onClicked: backend.cancelRemoteOperation()
                    }

                    ToolbarBtn {
                        label: qsTr("Close")
                        onClicked: remoteConnectionsDialog.reject()
                    }

                    ToolbarBtn {
                        label: qsTr("Save & Connect")
                        accentHighlight: true
                        btnEnabled: !backend.remoteOpRunning && (rcHostField.text.trim().length > 0 || rcUriField.text.trim().length > 0)
                        onClicked: {
                            if (rcHostField.text.trim().length === 0 && rcUriField.text.trim().length > 0)
                                remoteConnectionsDialog.parseFromUriBar();
                            var form = remoteConnectionsDialog.buildFormMap();
                            if (form.host.length === 0) return;
                            backend.saveRemoteConnection(form);
                            var uri = backend.buildRemoteUri(form);
                            backend.connectRemoteAsync(uri);
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
                    AppCheckBox {
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
                        AppCheckBox {
                            id: caTerminalCheck
                            text: qsTr("Run in Terminal")
                        }
                        AppCheckBox {
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
                        width: 30
                        height: 30
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

                    AppCheckBox {
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

    // Checksum & Verification Dialog (Single File + Batch Generate & Verify)
    AppDialog {
        id: checksumDialog
        visible: win.checksumOpen
        title: qsTr("Checksum & Integrity (MD5 / SHA1 / SHA256)")
        width: 660

        property int activeTab: 0 // 0 = Single File, 1 = Batch Generate & Verify
        property string filePath: ""
        property var hashes: ({})
        property string verificationResult: ""
        property bool verificationOk: false
        property var batchFilePaths: []
        property string batchAlgorithm: "sha256"
        property var batchResult: ({})

        function setBatchAlgorithm(algo) {
            checksumDialog.batchAlgorithm = algo;
            var cur = batchOutputField.text;
            var replaced = cur.replace(/checksums\.(sha256|sha1|md5)$/i, "checksums." + algo);
            if (replaced !== cur)
                batchOutputField.text = replaced;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Segmented Mode Switcher
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                FilterPill {
                    label: qsTr("Single File")
                    active: checksumDialog.activeTab === 0
                    onClicked: checksumDialog.activeTab = 0
                }

                FilterPill {
                    label: qsTr("Batch Generate & Verify")
                    active: checksumDialog.activeTab === 1
                    onClicked: checksumDialog.activeTab = 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: checksumDialog.activeTab === 1
                    text: qsTr("%1 file(s) queued").arg(checksumDialog.batchFilePaths.length)
                    font.pixelSize: 11
                    font.bold: true
                    color: p.accent
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: p.borderSubtle }

            // TAB 0: Single File Checksums
            ColumnLayout {
                visible: checksumDialog.activeTab === 0
                Layout.fillWidth: true
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

                // Async checksum progress bar + cancel
                RowLayout {
                    Layout.fillWidth: true
                    visible: backend.checksumRunning
                    spacing: 8

                    Text {
                        text: qsTr("Computing hashes… %1%").arg(Math.round(backend.checksumProgress * 100))
                        font.pixelSize: 11
                        font.bold: true
                        color: p.accent
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: p.borderDefault
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, backend.checksumProgress))
                            height: parent.height
                            radius: 3
                            color: p.accent
                        }
                    }

                    ToolbarBtn {
                        implicitHeight: 22
                        label: qsTr("Cancel")
                        onClicked: backend.cancelChecksumCalculation()
                    }
                }

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
                            onClicked: backend.copyTextToClipboard(checksumDialog.hashes.md5 || "", qsTr("MD5 hash copied to clipboard."))
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
                            onClicked: backend.copyTextToClipboard(checksumDialog.hashes.sha1 || "", qsTr("SHA1 hash copied to clipboard."))
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
                            onClicked: backend.copyTextToClipboard(checksumDialog.hashes.sha256 || "", qsTr("SHA256 hash copied to clipboard."))
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
                        placeholderText: qsTr("Paste expected MD5, SHA1, or SHA256 hash to verify...")
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

                // Save .sha256 / .md5 / Verify manifest buttons
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
                        visible: checksumDialog.filePath.toLowerCase().endsWith(".sha256")
                              || checksumDialog.filePath.toLowerCase().endsWith(".sha1")
                              || checksumDialog.filePath.toLowerCase().endsWith(".md5")
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
                                checksumDialog.activeTab = 1;
                                batchVerifyField.text = checksumDialog.filePath;
                                backend.startBatchChecksumVerify(checksumDialog.filePath);
                            }
                        }
                    }
                }
            }

            // TAB 1: Batch Generate & Verify
            ColumnLayout {
                visible: checksumDialog.activeTab === 1
                Layout.fillWidth: true
                spacing: 10

                // Card 1: Batch Generate
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: batchGenCol.implicitHeight + 16
                    radius: win.smallRadius
                    color: p.cardBg
                    border.width: 1
                    border.color: p.borderDefault

                    ColumnLayout {
                        id: batchGenCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: qsTr("Generate Checksum Manifest")
                                font.pixelSize: 12
                                font.bold: true
                                color: p.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            FilterPill {
                                label: "SHA256"
                                active: checksumDialog.batchAlgorithm === "sha256"
                                onClicked: checksumDialog.setBatchAlgorithm("sha256")
                            }
                            FilterPill {
                                label: "SHA1"
                                active: checksumDialog.batchAlgorithm === "sha1"
                                onClicked: checksumDialog.setBatchAlgorithm("sha1")
                            }
                            FilterPill {
                                label: "MD5"
                                active: checksumDialog.batchAlgorithm === "md5"
                                onClicked: checksumDialog.setBatchAlgorithm("md5")
                            }

                            ToolbarBtn {
                                label: qsTr("Use Selection")
                                onClicked: {
                                    checksumDialog.batchFilePaths = win.collectSelectedRegularFiles();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            CompactField {
                                id: batchOutputField
                                Layout.fillWidth: true
                                monospace: true
                                placeholderText: qsTr("Output manifest path (e.g. checksums.sha256)...")
                            }

                            ToolbarBtn {
                                label: qsTr("Generate")
                                accentHighlight: true
                                btnEnabled: !backend.batchChecksumRunning
                                            && checksumDialog.batchFilePaths.length > 0
                                            && batchOutputField.text.trim().length > 0
                                onClicked: {
                                    backend.startBatchChecksumGenerate(
                                        checksumDialog.batchFilePaths,
                                        checksumDialog.batchAlgorithm,
                                        batchOutputField.text.trim()
                                    );
                                }
                            }
                        }
                    }
                }

                // Card 2: Batch Verify
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: batchVerCol.implicitHeight + 16
                    radius: win.smallRadius
                    color: p.cardBg
                    border.width: 1
                    border.color: p.borderDefault

                    ColumnLayout {
                        id: batchVerCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: qsTr("Verify Manifest (.sha256 / .sha1 / .md5)")
                                font.pixelSize: 12
                                font.bold: true
                                color: p.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            ToolbarBtn {
                                label: qsTr("Use Active File")
                                onClicked: {
                                    var cur = currentHighlightedPath();
                                    if (cur.length > 0)
                                        batchVerifyField.text = cur;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            CompactField {
                                id: batchVerifyField
                                Layout.fillWidth: true
                                monospace: true
                                placeholderText: qsTr("Path to .sha256 / .sha1 / .md5 manifest...")
                            }

                            ToolbarBtn {
                                label: qsTr("Verify")
                                accentHighlight: true
                                btnEnabled: !backend.batchChecksumRunning
                                            && batchVerifyField.text.trim().length > 0
                                onClicked: backend.startBatchChecksumVerify(batchVerifyField.text.trim())
                            }
                        }
                    }
                }

                // Batch async progress
                RowLayout {
                    Layout.fillWidth: true
                    visible: backend.batchChecksumRunning
                    spacing: 8

                    Text {
                        text: qsTr("Processing %1%").arg(Math.round(backend.batchChecksumProgress * 100))
                              + (backend.batchChecksumDetail.length > 0 ? (" — " + backend.batchChecksumDetail) : "")
                        font.pixelSize: 11
                        font.bold: true
                        color: p.accent
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 260
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: p.borderDefault
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, backend.batchChecksumProgress))
                            height: parent.height
                            radius: 3
                            color: p.accent
                        }
                    }

                    ToolbarBtn {
                        implicitHeight: 22
                        label: qsTr("Cancel")
                        onClicked: backend.cancelBatchChecksum()
                    }
                }

                // Results summary + per-file table
                ColumnLayout {
                    visible: Boolean(checksumDialog.batchResult && (checksumDialog.batchResult.message || (checksumDialog.batchResult.details && checksumDialog.batchResult.details.length > 0)))
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: (checksumDialog.batchResult && checksumDialog.batchResult.message) ? checksumDialog.batchResult.message : ""
                            font.pixelSize: 12
                            font.bold: true
                            color: (checksumDialog.batchResult && checksumDialog.batchResult.success) ? p.successText : p.dangerAccent
                            elide: Text.ElideMiddle
                        }

                        ToolbarBtn {
                            visible: Boolean(checksumDialog.batchResult && checksumDialog.batchResult.outputFile)
                            label: qsTr("Copy Path")
                            onClicked: backend.copyTextToClipboard(checksumDialog.batchResult.outputFile || "", qsTr("Manifest path copied to clipboard."))
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170
                        radius: win.smallRadius
                        color: p.inputBg
                        border.width: 1
                        border.color: p.borderDefault
                        clip: true

                        ListView {
                            id: batchDetailsList
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 3
                            model: (checksumDialog.batchResult && checksumDialog.batchResult.details) ? checksumDialog.batchResult.details : []

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: batchDetailsList.width
                                height: 32
                                radius: win.smallRadius
                                color: index % 2 === 0 ? p.cardAltBg : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    Rectangle {
                                        implicitWidth: 68
                                        implicitHeight: 20
                                        radius: Math.min(4, win.smallRadius)
                                        color: {
                                            if (modelData.status === "ok") return Qt.alpha(p.successText, 0.16);
                                            if (modelData.status === "missing") return Qt.alpha(p.warningText, 0.18);
                                            if (modelData.status === "skipped") return p.badgeBg;
                                            return Qt.alpha(p.dangerAccent, 0.18);
                                        }
                                        border.width: 1
                                        border.color: {
                                            if (modelData.status === "ok") return p.successText;
                                            if (modelData.status === "missing") return p.warningText;
                                            if (modelData.status === "skipped") return p.borderDefault;
                                            return p.dangerAccent;
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (modelData.status === "ok") return "OK";
                                                if (modelData.status === "missing") return "MISSING";
                                                if (modelData.status === "skipped") return "SKIPPED";
                                                if (modelData.status === "error") return "ERROR";
                                                return "MISMATCH";
                                            }
                                            font.pixelSize: 9
                                            font.bold: true
                                            font.family: "monospace"
                                            color: {
                                                if (modelData.status === "ok") return p.successText;
                                                if (modelData.status === "missing") return p.warningText;
                                                if (modelData.status === "skipped") return p.textMuted;
                                                return p.dangerAccent;
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 190
                                        text: modelData.file || ""
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: p.textPrimary
                                        elide: Text.ElideMiddle
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.hash
                                              || (modelData.status === "mismatch"
                                                  ? (qsTr("got %1").arg((modelData.actual || "").slice(0, 16) + "…"))
                                                  : (modelData.expected || modelData.status || ""))
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                        color: p.textMuted
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
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

        onRejected: {
            backend.cancelChecksumCalculation();
            backend.cancelBatchChecksum();
            win.checksumOpen = false;
        }
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
        title: qsTr("TwinForge — Keyboard Shortcuts")
        width: 640
        height: 580

        ScrollView {
            anchors.fill: parent
            clip: true
            ScrollBar.vertical: AppScrollBar {}

            ColumnLayout {
                width: parent.width
                spacing: 4

                Repeater {
                    model: [
                        { key: win.formatShortcutDisplay(win.shortcuts.commandPalette), desc: qsTr("Open Command Palette (fuzzy search actions)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.quickJump), desc: qsTr("Quick Jump to Folder (bookmarks, recent, zoxide)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.flatView), desc: qsTr("Toggle Flat / Branch View (all subfolders in one list)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.diskUsage), desc: qsTr("Toggle Disk Usage Analyzer (proportional bars & sorted sizes)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.syncDirs), desc: qsTr("Synchronize Directories recursively between panels") },
                        { key: win.formatShortcutDisplay(win.shortcuts.duplicateFinder), desc: qsTr("Find Duplicate Files by size and SHA-256 hash") },
                        { key: win.formatShortcutDisplay(win.shortcuts.operationQueue), desc: qsTr("Open Operation Queue & Pause / Speed / ETA monitor") },
                        { key: win.formatShortcutDisplay(win.shortcuts.remoteConnections), desc: qsTr("Connect & manage Google Drive (rclone), SFTP, SMB & SSHFS servers") },
                        { key: win.formatShortcutDisplay(win.shortcuts.openWith), desc: qsTr("Open With compatible apps & manage Custom Actions") },
                        { key: "Enter (on archive)", desc: qsTr("Browse inside .zip / .tar.* / .7z archive as virtual folder") },
                        { key: "Tab", desc: qsTr("Switch active panel (Left / Right)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.themeToggle), desc: qsTr("Toggle between Light and Dark theme") },
                        { key: win.formatShortcutDisplay(win.shortcuts.newTab) + " / " + win.formatShortcutDisplay(win.shortcuts.closeTab), desc: qsTr("Open new tab / Close active tab in panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.reopenTab), desc: qsTr("Reopen last closed tab in active panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.lockTab), desc: qsTr("Lock / unlock active tab (right-click tab for strict mode & actions)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.workspaces), desc: qsTr("Open Workspaces manager (save & restore dual-panel layouts)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.openTrash), desc: qsTr("Open Trash Manager (trash://) to restore or empty") },
                        { key: win.formatShortcutDisplay(win.shortcuts.cmdBarFocus) + " / " + win.formatShortcutDisplay(win.shortcuts.cmdDrawerToggle), desc: qsTr("Focus command bar (↑/↓ history, built-in cd) / Toggle live output drawer") },
                        { key: win.formatShortcutDisplay(win.shortcuts.cmdInsertName) + " / " + win.shortcuts.cmdInsertPath, desc: qsTr("Insert highlighted filename / full path into command bar") },
                        { key: win.formatShortcutDisplay(win.shortcuts.splitCombine), desc: qsTr("Split large file into .001 parts (+ .crc) or combine parts back") },
                        { key: "Type letters", desc: qsTr("Multi-character Type-Ahead quick jump inside active panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.nextTab), desc: qsTr("Switch between open tabs in active panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.viewList) + " / " + win.formatShortcutDisplay(win.shortcuts.viewGrid), desc: qsTr("Toggle List / Grid thumbnail view mode") },
                        { key: "Ctrl + C / X / V", desc: qsTr("Copy / Cut / Paste files via system clipboard") },
                        { key: win.shortcuts.copyNamesCsv + " / " + win.shortcuts.copyPathsCsv, desc: qsTr("Copy names or paths as comma-separated text") },
                        { key: win.formatShortcutDisplay(win.shortcuts.undo), desc: qsTr("Undo last rename, move, or trash delete") },
                        { key: win.formatShortcutDisplay(win.shortcuts.newFile), desc: qsTr("Create new file (or files via comma) and open in editor") },
                        { key: win.formatShortcutDisplay(win.shortcuts.symlink), desc: qsTr("Create symbolic link in target panel") },
                        { key: "Num+ / Num-", desc: qsTr("Select / deselect items by wildcard pattern (*.jpg)") },
                        { key: "Num* / " + win.shortcuts.invertSelection, desc: qsTr("Invert selection in active panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.diffFiles), desc: qsTr("Compare two text files with visual side-by-side diff") },
                        { key: win.formatShortcutDisplay(win.shortcuts.properties), desc: qsTr("Item properties & editable chmod permissions") },
                        { key: "Space / Insert", desc: qsTr("Select item (and calculate folder size) + advance") },
                        { key: win.formatShortcutDisplay(win.shortcuts.calcFolderSizes), desc: qsTr("Calculate sizes for all folders in panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.editPath), desc: qsTr("Edit path of active panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.quickView), desc: qsTr("Toggle live Quick View in opposite panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.filter), desc: qsTr("Toggle real-time quick filter bar") },
                        { key: win.formatShortcutDisplay(win.shortcuts.bookmarks), desc: qsTr("Open Bookmarks manager") },
                        { key: win.formatShortcutDisplay(win.shortcuts.swapPanels) + " / " + win.formatShortcutDisplay(win.shortcuts.syncPanels), desc: qsTr("Swap panels / Sync target panel") },
                        { key: win.formatShortcutDisplay(win.shortcuts.compareDirs), desc: qsTr("Compare Left & Right directories (select differences)") },
                        { key: win.formatShortcutDisplay(win.shortcuts.multiRename), desc: qsTr("Multi-Rename Tool for selected items") },
                        { key: win.formatShortcutDisplay(win.shortcuts.packArchive) + " / " + win.formatShortcutDisplay(win.shortcuts.extractArchive), desc: qsTr("Pack files to archive / Extract archive") },
                        { key: "Alt + Left / Right", desc: qsTr("Navigate directory history Back / Forward") },
                        { key: win.shortcuts.view + " / " + win.shortcuts.edit, desc: qsTr("Preview item (Text/Image/Hex) / Edit with $EDITOR") },
                        { key: win.shortcuts.copy + " / " + win.shortcuts.move + " / " + win.shortcuts.rename, desc: qsTr("Copy / Move / Rename item(s)") },
                        { key: win.shortcuts.newFolder + " / " + win.shortcuts.deleteItem, desc: qsTr("Create new folder / Delete selected item(s)") },
                        { key: win.shortcuts.terminal + " / " + win.formatShortcutDisplay(win.shortcuts.terminalAlt), desc: qsTr("Open terminal in active folder") },
                        { key: win.formatShortcutDisplay(win.shortcuts.findFiles), desc: qsTr("Search files recursively") },
                        { key: "Ctrl + F3..F6", desc: qsTr("Sort by Name, Ext, Date, or Size") },
                        { key: win.formatShortcutDisplay(win.shortcuts.selectAll) + " / " + win.formatShortcutDisplay(win.shortcuts.deselectAll), desc: qsTr("Select all / Deselect all") },
                        { key: win.formatShortcutDisplay(win.shortcuts.showHidden), desc: qsTr("Toggle show/hide hidden dotfiles") },
                        { key: win.formatShortcutDisplay(win.shortcuts.settings), desc: qsTr("Open Preferences / Settings dialog") },
                        { key: win.shortcuts.exitApp + " / Esc", desc: qsTr("Quit TwinForge / Close dialog") }
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

    // About TwinForge Dialog
    AppDialog {
        id: aboutDialog
        title: qsTr("About TwinForge")
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
                            text: "TwinForge"
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
                                text: "v0.1.0"
                                font.pixelSize: 10
                                font.bold: true
                                color: p.accent
                            }
                        }
                    }

                    Text {
                        text: qsTr("Modern Dual-Panel File Manager for Linux")
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
                text: qsTr("Dual-panel orthodox file manager featuring locked tabs, workspaces, Freedesktop Trash, async workers, thumbnail grid, git status, visual diff, RegEx multi-rename, file split/combine, and remote mounts.")
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                lineHeight: 1.35
                color: p.textDim
                text: qsTr("Open-Source (GNU GPLv3) © 2026 Radu. Built with C++20, Qt 6 & libarchive.")
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
                        && !win.remoteConnectionsOpen && !win.openWithOpen
                        && !win.workspacesOpen && !win.settingsOpen && !win.confirmEmptyTrashOpen
                        && !win.splitCombineOpen && !cmdLineInput.input.activeFocus)
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
        objectName: "syncDirsDialog"
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
        property string quickFocusFilter: "all" // "all" | "copy_right" | "copy_left" | "overwrites" | "conflicts" | "equal"
        property var allItems: []
        property var visibleItems: []
        property int copyRightCount: 0
        property int copyLeftCount: 0
        property int overwriteCount: 0
        property int newRightCount: 0
        property int newLeftCount: 0
        property int equalCount: 0
        property int conflictCount: 0

        function isOverwriteItem(it) {
            return Boolean(it && ((it.action === "copy_to_right" && it.rightExists === true)
                                  || (it.action === "copy_to_left" && it.leftExists === true)));
        }

        function toggleQuickFocus(bucket) {
            quickFocusFilter = (quickFocusFilter === bucket) ? "all" : bucket;
            rebuildVisible();
        }

        function applyCompareResults(raw) {
            var list = raw || [];
            var indexed = [];
            for (var i = 0; i < list.length; i++) {
                var r = list[i];
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
            quickFocusFilter = "all";
            allItems = indexed;
            rebuildVisible();
        }

        function refreshCompare() {
            if (backend.leftPanel.isArchiveView || backend.rightPanel.isArchiveView) {
                backend.cancelSyncOperation();
                quickFocusFilter = "all";
                allItems = [];
                rebuildVisible();
                return;
            }
            backend.startDirectoryCompare(
                backend.leftPanel.path, backend.rightPanel.path, compareMode, includeHidden
            );
        }

        function rebuildVisible() {
            var cr = 0, cl = 0, ow = 0, nr = 0, nl = 0, eq = 0, cf = 0;
            var filtered = [];
            for (var i = 0; i < allItems.length; i++) {
                var it = allItems[i];
                var isOw = isOverwriteItem(it);
                if (it.action === "copy_to_right") {
                    cr++;
                    if (isOw) ow++;
                    else nr++;
                } else if (it.action === "copy_to_left") {
                    cl++;
                    if (isOw) ow++;
                    else nl++;
                }
                if (it.status === "equal") eq++;
                else if (it.status === "different" && it.action === "skip") cf++;

                var show = false;
                if (quickFocusFilter === "copy_right") {
                    show = (it.action === "copy_to_right");
                } else if (quickFocusFilter === "copy_left") {
                    show = (it.action === "copy_to_left");
                } else if (quickFocusFilter === "overwrites") {
                    show = isOw;
                } else if (quickFocusFilter === "conflicts") {
                    show = (it.status === "different" && it.action === "skip");
                } else if (quickFocusFilter === "equal") {
                    show = (it.status === "equal");
                } else {
                    if (it.status === "equal")
                        show = showEqual;
                    else if (it.action === "copy_to_right")
                        show = showLeftToRight;
                    else if (it.action === "copy_to_left")
                        show = showRightToLeft;
                    else
                        show = showConflicts;
                }

                if (show)
                    filtered.push(it);
            }
            copyRightCount = cr;
            copyLeftCount = cl;
            overwriteCount = ow;
            newRightCount = nr;
            newLeftCount = nl;
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
            backend.startDirectorySync(backend.leftPanel.path, backend.rightPanel.path, allItems);
        }

        onRejected: {
            backend.cancelSyncOperation();
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
                    label: backend.syncRunning ? qsTr("Cancel") : qsTr("Compare")
                    accentHighlight: true
                    onClicked: {
                        if (backend.syncRunning)
                            backend.cancelSyncOperation();
                        else
                            syncDirsDialog.refreshCompare();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: backend.syncRunning
                spacing: 8

                Text {
                    text: backend.syncDetail || qsTr("Working…")
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.accent
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                Text {
                    text: Math.round(backend.syncProgress * 100) + "%"
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.textSecondary
                }

                Rectangle {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 6
                    radius: 3
                    color: p.borderDefault
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, backend.syncProgress))
                        height: parent.height
                        radius: 3
                        color: p.accent
                    }
                }
            }

            // Pre-Execution Summary & Clickable Filters Bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: summaryFlow.implicitHeight + 10
                radius: win.smallRadius
                color: p.cardAltBg
                border.width: 1
                border.color: p.borderSubtle

                RowLayout {
                    id: summaryFlow
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5
                    spacing: 6

                    FilterPill {
                        label: qsTr("%1 → right").arg(syncDirsDialog.copyRightCount)
                        active: syncDirsDialog.quickFocusFilter === "copy_right"
                        onClicked: syncDirsDialog.toggleQuickFocus("copy_right")
                    }

                    Text { text: "·"; font.pixelSize: 12; color: p.textDim }

                    FilterPill {
                        label: qsTr("%1 ← left").arg(syncDirsDialog.copyLeftCount)
                        active: syncDirsDialog.quickFocusFilter === "copy_left"
                        onClicked: syncDirsDialog.toggleQuickFocus("copy_left")
                    }

                    Text { text: "·"; font.pixelSize: 12; color: p.textDim }

                    // Warning-highlighted overwrite counter pill
                    Rectangle {
                        id: overwriteSummaryPill
                        objectName: "syncOverwriteFilterBtn"
                        implicitHeight: 24
                        implicitWidth: owPillText.implicitWidth + 14
                        radius: win.smallRadius
                        color: syncDirsDialog.quickFocusFilter === "overwrites"
                               ? Qt.alpha(p.warningText, win.isDark ? 0.28 : 0.22)
                               : (owPillMouse.containsMouse ? p.btnHoverBg
                                  : (syncDirsDialog.overwriteCount > 0 ? Qt.alpha(p.warningText, 0.12) : p.cardBg))
                        border.width: 1
                        border.color: syncDirsDialog.quickFocusFilter === "overwrites" || syncDirsDialog.overwriteCount > 0
                                      ? p.warningText : p.borderDefault

                        Text {
                            id: owPillText
                            anchors.centerIn: parent
                            text: qsTr("%1 overwrite(s)").arg(syncDirsDialog.overwriteCount)
                            font.pixelSize: 11
                            font.weight: (syncDirsDialog.quickFocusFilter === "overwrites" || syncDirsDialog.overwriteCount > 0)
                                         ? Font.DemiBold : Font.Normal
                            color: syncDirsDialog.overwriteCount > 0 || syncDirsDialog.quickFocusFilter === "overwrites"
                                   ? p.warningText : p.textSecondary
                        }

                        MouseArea {
                            id: owPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: syncDirsDialog.toggleQuickFocus("overwrites")
                        }

                        ToolTip.visible: owPillMouse.containsMouse
                        ToolTip.delay: 350
                        ToolTip.text: qsTr("Show only files that will overwrite an existing target")
                    }

                    Text { text: "·"; font.pixelSize: 12; color: p.textDim }

                    FilterPill {
                        label: qsTr("%1 conflict(s)").arg(syncDirsDialog.conflictCount)
                        active: syncDirsDialog.quickFocusFilter === "conflicts"
                        onClicked: syncDirsDialog.toggleQuickFocus("conflicts")
                    }

                    Text { text: "·"; font.pixelSize: 12; color: p.textDim }

                    FilterPill {
                        label: qsTr("%1 equal").arg(syncDirsDialog.equalCount)
                        active: syncDirsDialog.quickFocusFilter === "equal"
                        onClicked: syncDirsDialog.toggleQuickFocus("equal")
                    }

                    ToolbarBtn {
                        visible: syncDirsDialog.quickFocusFilter !== "all"
                        implicitHeight: 22
                        label: qsTr("Show all")
                        accentHighlight: true
                        onClicked: {
                            syncDirsDialog.quickFocusFilter = "all";
                            syncDirsDialog.rebuildVisible();
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: qsTr("Click badge to override")
                        font.pixelSize: 10
                        color: p.textDim
                    }
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

                            Rectangle {
                                visible: syncDirsDialog.isOverwriteItem(modelData)
                                implicitHeight: 20
                                implicitWidth: owRowTag.implicitWidth + 10
                                radius: 3
                                color: Qt.alpha(p.warningText, 0.16)
                                border.width: 1
                                border.color: Qt.alpha(p.warningText, 0.55)

                                Text {
                                    id: owRowTag
                                    anchors.centerIn: parent
                                    text: qsTr("OVERWRITE")
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.family: "monospace"
                                    color: p.warningText
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
                    text: backend.syncRunning
                          ? (backend.syncDetail || qsTr("Comparing directories…"))
                          : ((backend.leftPanel.isArchiveView || backend.rightPanel.isArchiveView)
                              ? qsTr("Directory synchronization is not supported inside archive views.")
                              : qsTr("No differences match current filter."))
                    font.pixelSize: 12
                    color: backend.syncRunning ? p.accent : p.textDim
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
                    btnEnabled: !backend.syncRunning && (syncDirsDialog.copyRightCount + syncDirsDialog.copyLeftCount > 0)
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

        function applyDuplicateResults(raw) {
            var list = raw || [];
            var out = [];
            for (var i = 0; i < list.length; i++) {
                var r = list[i];
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

        function runScan() {
            var r1 = currentModel().isArchiveView ? "" : currentModel().path;
            var r2 = (bothPanels && !targetModel().isArchiveView) ? targetModel().path : "";
            backend.startDuplicateScan(r1, r2, minSizeBytes, includeHidden);
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
            backend.cancelDuplicateScan();
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
                    label: backend.duplicateScanRunning ? qsTr("Cancel") : qsTr("Scan Duplicates")
                    accentHighlight: true
                    onClicked: {
                        if (backend.duplicateScanRunning)
                            backend.cancelDuplicateScan();
                        else
                            duplicateFinderDialog.runScan();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: backend.duplicateScanRunning
                spacing: 8

                Text {
                    text: qsTr("Scanning… %1 file(s)").arg(backend.duplicateScanScannedCount)
                    font.pixelSize: 11
                    font.bold: true
                    color: p.accent
                }

                Text {
                    text: backend.duplicateScanDetail || ""
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: p.textMuted
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
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
                    text: backend.duplicateScanRunning
                          ? qsTr("Scanning for duplicate files… (%1 scanned)").arg(backend.duplicateScanScannedCount)
                          : qsTr("No duplicate files found for current filter.")
                    font.pixelSize: 12
                    color: backend.duplicateScanRunning ? p.accent : p.textDim
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

    // Preferences / Settings Dialog (Ctrl+,)
    AppDialog {
        id: settingsDialog
        visible: win.settingsOpen
        title: qsTr("Preferences / Settings")
        width: 580

        property int draftFontSize: 12
        property int draftRowHeight: 27
        property string draftLanguageMode: "auto"

        function loadFromBackend() {
            draftFontSize = backend.fontSize;
            draftRowHeight = backend.rowHeight;
            draftLanguageMode = backend.languageMode;
            customEditorField.text = backend.customEditor;
            customTerminalField.text = backend.customTerminal;
            confirmCopyCheck.checked = backend.confirmCopy;
            confirmMoveCheck.checked = backend.confirmMove;
            confirmDeleteCheck.checked = backend.confirmDelete;
            showExtColCheck.checked = backend.showExtColumn;
            showSizeColCheck.checked = backend.showSizeColumn;
            showModifiedColCheck.checked = backend.showModifiedColumn;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Section 1: Appearance & Layout
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: appearanceCol.implicitHeight + 18
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderDefault

                ColumnLayout {
                    id: appearanceCol
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 9

                    Text {
                        text: qsTr("Appearance & Columns")
                        font.pixelSize: 12
                        font.bold: true
                        color: p.accent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Font size stepper
                        RowLayout {
                            spacing: 6
                            Text {
                                text: qsTr("Font size:")
                                font.pixelSize: 12
                                color: p.textSecondary
                            }
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: fontDecMouse.containsMouse && settingsDialog.draftFontSize > 10 ? p.btnHoverBg : p.chipBg
                                border.width: 1
                                border.color: p.borderDefault
                                opacity: settingsDialog.draftFontSize > 10 ? 1.0 : 0.4
                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 13; font.bold: true; color: p.textPrimary }
                                MouseArea {
                                    id: fontDecMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: settingsDialog.draftFontSize > 10
                                    onClicked: settingsDialog.draftFontSize--
                                }
                            }
                            Rectangle {
                                implicitWidth: 52
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: p.badgeBg
                                border.width: 1
                                border.color: p.borderDefault
                                Text {
                                    anchors.centerIn: parent
                                    text: settingsDialog.draftFontSize + " px"
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    font.bold: true
                                    color: p.textPrimary
                                }
                            }
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: fontIncMouse.containsMouse && settingsDialog.draftFontSize < 16 ? p.btnHoverBg : p.chipBg
                                border.width: 1
                                border.color: p.borderDefault
                                opacity: settingsDialog.draftFontSize < 16 ? 1.0 : 0.4
                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 13; font.bold: true; color: p.textPrimary }
                                MouseArea {
                                    id: fontIncMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: settingsDialog.draftFontSize < 16
                                    onClicked: settingsDialog.draftFontSize++
                                }
                            }
                        }

                        // Row height stepper
                        RowLayout {
                            spacing: 6
                            Text {
                                text: qsTr("Row height:")
                                font.pixelSize: 12
                                color: p.textSecondary
                            }
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: rowDecMouse.containsMouse && settingsDialog.draftRowHeight > 22 ? p.btnHoverBg : p.chipBg
                                border.width: 1
                                border.color: p.borderDefault
                                opacity: settingsDialog.draftRowHeight > 22 ? 1.0 : 0.4
                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 13; font.bold: true; color: p.textPrimary }
                                MouseArea {
                                    id: rowDecMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: settingsDialog.draftRowHeight > 22
                                    onClicked: settingsDialog.draftRowHeight--
                                }
                            }
                            Rectangle {
                                implicitWidth: 52
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: p.badgeBg
                                border.width: 1
                                border.color: p.borderDefault
                                Text {
                                    anchors.centerIn: parent
                                    text: settingsDialog.draftRowHeight + " px"
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    font.bold: true
                                    color: p.textPrimary
                                }
                            }
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: win.smallRadius
                                color: rowIncMouse.containsMouse && settingsDialog.draftRowHeight < 38 ? p.btnHoverBg : p.chipBg
                                border.width: 1
                                border.color: p.borderDefault
                                opacity: settingsDialog.draftRowHeight < 38 ? 1.0 : 0.4
                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 13; font.bold: true; color: p.textPrimary }
                                MouseArea {
                                    id: rowIncMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: settingsDialog.draftRowHeight < 38
                                    onClicked: settingsDialog.draftRowHeight++
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Text {
                            text: qsTr("Visible columns:")
                            font.pixelSize: 12
                            color: p.textSecondary
                        }

                        AppCheckBox {
                            id: showExtColCheck
                            text: qsTr("Ext")
                            checked: true
                        }
                        AppCheckBox {
                            id: showSizeColCheck
                            text: qsTr("Size")
                            checked: true
                        }
                        AppCheckBox {
                            id: showModifiedColCheck
                            text: qsTr("Modified")
                            checked: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: qsTr("Language:")
                            font.pixelSize: 12
                            color: p.textSecondary
                        }

                        FilterPill {
                            label: qsTr("Auto (System)")
                            active: settingsDialog.draftLanguageMode === "auto"
                            onClicked: settingsDialog.draftLanguageMode = "auto"
                        }
                        FilterPill {
                            label: "English (EN)"
                            active: settingsDialog.draftLanguageMode === "en"
                            onClicked: settingsDialog.draftLanguageMode = "en"
                        }
                        FilterPill {
                            label: "Română (RO)"
                            active: settingsDialog.draftLanguageMode === "ro"
                            onClicked: settingsDialog.draftLanguageMode = "ro"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            readonly property string activeLangCode: (typeof translator !== "undefined" && translator)
                                ? translator.language
                                : backend.languageMode
                            text: qsTr("Active: %1").arg(activeLangCode.toUpperCase())
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: p.textMuted
                        }
                    }
                }
            }

            // Section 2: External Tools ($EDITOR / $TERMINAL)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: toolsCol.implicitHeight + 18
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderDefault

                ColumnLayout {
                    id: toolsCol
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 8

                    Text {
                        text: qsTr("External Applications")
                        font.pixelSize: 12
                        font.bold: true
                        color: p.accent
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 8

                        Text {
                            text: qsTr("Custom $EDITOR:")
                            font.pixelSize: 12
                            color: p.textSecondary
                        }
                        CompactField {
                            id: customEditorField
                            Layout.fillWidth: true
                            monospace: true
                            placeholderText: qsTr("Leave blank to use $EDITOR / system default (e.g. nvim, code, kate)")
                        }

                        Text {
                            text: qsTr("Custom $TERMINAL:")
                            font.pixelSize: 12
                            color: p.textSecondary
                        }
                        CompactField {
                            id: customTerminalField
                            Layout.fillWidth: true
                            monospace: true
                            placeholderText: qsTr("Leave blank to use $TERMINAL or auto-detect (foot, alacritty, kitty)")
                        }
                    }
                }
            }

            // Section 3: Operation Confirmations
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: confirmCol.implicitHeight + 18
                radius: win.smallRadius
                color: p.cardBg
                border.width: 1
                border.color: p.borderDefault

                ColumnLayout {
                    id: confirmCol
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 6

                    Text {
                        text: qsTr("Confirmations")
                        font.pixelSize: 12
                        font.bold: true
                        color: p.accent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        AppCheckBox {
                            id: confirmCopyCheck
                            text: qsTr("Confirm Copy (F5)")
                            checked: true
                        }
                        AppCheckBox {
                            id: confirmMoveCheck
                            text: qsTr("Confirm Move (F6)")
                            checked: true
                        }
                        AppCheckBox {
                            id: confirmDeleteCheck
                            text: qsTr("Confirm Delete (F8)")
                            checked: true
                        }
                    }
                }
            }

            // Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ToolbarBtn {
                    label: qsTr("Reset Defaults")
                    onClicked: {
                        backend.resetSettingsToDefaults();
                        settingsDialog.loadFromBackend();
                    }
                }

                Item { Layout.fillWidth: true }

                ToolbarBtn {
                    label: qsTr("Cancel")
                    onClicked: settingsDialog.reject()
                }

                ToolbarBtn {
                    label: qsTr("Apply")
                    accentHighlight: true
                    onClicked: {
                        backend.updateSettings({
                            fontSize: settingsDialog.draftFontSize,
                            rowHeight: settingsDialog.draftRowHeight,
                            customEditor: customEditorField.text,
                            customTerminal: customTerminalField.text,
                            confirmCopy: confirmCopyCheck.checked,
                            confirmMove: confirmMoveCheck.checked,
                            confirmDelete: confirmDeleteCheck.checked,
                            showExtColumn: showExtColCheck.checked,
                            showSizeColumn: showSizeColCheck.checked,
                            showModifiedColumn: showModifiedColCheck.checked,
                            languageMode: settingsDialog.draftLanguageMode
                        });
                        win.settingsOpen = false;
                        currentListView().forceActiveFocus();
                    }
                }
            }
        }

        onRejected: {
            win.settingsOpen = false;
            currentListView().forceActiveFocus();
        }
    }
}
