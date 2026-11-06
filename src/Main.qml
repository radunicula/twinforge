import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1260
    height: 800
    minimumWidth: 860
    minimumHeight: 540
    visible: true
    title: "omapanel — Total Commander for Linux"
    color: "#0f1117"

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    // UI State
    property bool helpOpen: false
    property bool previewOpen: false
    property var previewData: ({})
    property bool quickViewActive: false
    property var quickViewData: ({})
    property bool searchOpen: false
    property var searchResults: []
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
    property bool leftFilterVisible: false
    property bool rightFilterVisible: false

    // Helpers
    function currentModel() {
        return backend.activePanel === 0 ? backend.leftPanel : backend.rightPanel;
    }

    function targetModel() {
        return backend.activePanel === 0 ? backend.rightPanel : backend.leftPanel;
    }

    function currentListView() {
        return backend.activePanel === 0 ? leftList : rightList;
    }

    function currentHighlightedPath() {
        var m = currentModel();
        var lv = currentListView();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            return m.itemPath(lv.currentIndex);
        }
        return "";
    }

    function updateQuickView() {
        if (!win.quickViewActive)
            return;
        var p = currentHighlightedPath();
        if (p.length > 0) {
            win.quickViewData = backend.getPreview(p);
        } else {
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
        var paths = getSelectedOrCurrentPaths();
        multiRenamePreviewList = backend.previewMultiRename(
            paths,
            mrFindField.text,
            mrReplaceField.text,
            mrPrefixField.text,
            mrSuffixField.text,
            mrCaseCombo.currentIndex,
            mrCounterCheck.checked
        );
    }

    // Actions
    function triggerF3View() {
        var p = currentHighlightedPath();
        if (p.length > 0) {
            previewData = backend.getPreview(p);
            previewOpen = true;
        }
    }

    function triggerF4Edit() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            backend.openWithEditor(paths[0]);
        }
    }

    function triggerF5Copy() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            copyDestField.text = targetModel().path;
            confirmCopyOpen = true;
        } else {
            backend.showStatus(qsTr("No files selected to copy."));
        }
    }

    function triggerF6Move() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            moveDestField.text = targetModel().path;
            confirmMoveOpen = true;
        } else {
            backend.showStatus(qsTr("No files selected to move."));
        }
    }

    function triggerF7NewFolder() {
        newFolderInput.text = "";
        newFolderOpen = true;
        newFolderInput.forceActiveFocus();
    }

    function triggerRename() {
        var lv = currentListView();
        var m = currentModel();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            var name = m.itemName(lv.currentIndex);
            if (name === "..")
                return;
            renameOldPath = m.itemPath(lv.currentIndex);
            renameOldName = name;
            renameInput.text = renameOldName;
            renameOpen = true;
            renameInput.forceActiveFocus();
        }
    }

    function triggerMultiRename() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length === 0) {
            backend.showStatus(qsTr("Select files first for Multi-Rename (Ctrl+M)."));
            return;
        }
        mrFindField.text = "";
        mrReplaceField.text = "";
        mrPrefixField.text = "";
        mrSuffixField.text = "";
        mrCaseCombo.currentIndex = 0;
        mrCounterCheck.checked = false;
        refreshMultiRenamePreview();
        multiRenameOpen = true;
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
        packArchiveField.forceActiveFocus();
    }

    function triggerExtractArchive() {
        var p = currentHighlightedPath();
        if (p.length > 0 && backend.isArchive(p)) {
            backend.extractArchive(p, targetModel().path);
        } else {
            backend.showStatus(qsTr("Highlight an archive (.zip, .tar.gz, .7z) to extract (Alt+F9)."));
        }
    }

    function triggerF8Delete() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            confirmDeleteOpen = true;
        } else {
            backend.showStatus(qsTr("No files selected to delete."));
        }
    }

    function toggleFilterBar() {
        if (backend.activePanel === 0) {
            leftFilterVisible = !leftFilterVisible;
            if (leftFilterVisible) {
                leftFilterField.forceActiveFocus();
            } else {
                backend.leftPanel.setFilter("");
                leftList.forceActiveFocus();
            }
        } else {
            rightFilterVisible = !rightFilterVisible;
            if (rightFilterVisible) {
                rightFilterField.forceActiveFocus();
            } else {
                backend.rightPanel.setFilter("");
                rightList.forceActiveFocus();
            }
        }
    }

    // Global Shortcuts
    Shortcut { sequence: "Tab"; context: Qt.ApplicationShortcut; onActivated: {
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
    Shortcut { sequence: "Delete"; context: Qt.ApplicationShortcut; onActivated: triggerF8Delete() }
    Shortcut { sequence: "F10"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }

    // Total Commander Power Shortcuts
    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: {
        win.quickViewActive = !win.quickViewActive;
        if (win.quickViewActive)
            updateQuickView();
    }}
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
    Shortcut { sequence: "Alt+F7"; context: Qt.ApplicationShortcut; onActivated: {
        searchInput.text = "";
        searchResults = [];
        searchOpen = true;
        searchInput.forceActiveFocus();
    }}
    Shortcut { sequence: "Ctrl+H"; context: Qt.ApplicationShortcut; onActivated: {
        var m = currentModel();
        m.setShowHidden(!m.showHidden);
    }}
    Shortcut { sequence: "Ctrl+F3"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(0) }
    Shortcut { sequence: "Ctrl+F4"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(1) }
    Shortcut { sequence: "Ctrl+F5"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(3) }
    Shortcut { sequence: "Ctrl+F6"; context: Qt.ApplicationShortcut; onActivated: currentModel().setSortField(2) }
    Shortcut { sequence: "Ctrl+R"; context: Qt.ApplicationShortcut; onActivated: currentModel().refresh() }
    Shortcut { sequence: "Ctrl+A"; context: Qt.ApplicationShortcut; onActivated: currentModel().selectAll() }
    Shortcut { sequence: "Ctrl+Shift+A"; context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }
    Shortcut { sequence: "Ctrl+T"; context: Qt.ApplicationShortcut; onActivated: backend.openInTerminal(currentModel().path) }
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: {
        if (helpOpen) { helpOpen = false; return; }
        if (previewOpen) { previewOpen = false; return; }
        if (searchOpen) { searchOpen = false; return; }
        if (newFolderOpen) { newFolderOpen = false; return; }
        if (renameOpen) { renameOpen = false; return; }
        if (multiRenameOpen) { multiRenameOpen = false; return; }
        if (packArchiveOpen) { packArchiveOpen = false; return; }
        if (bookmarksOpen) { bookmarksOpen = false; return; }
        if (commandOutputOpen) { commandOutputOpen = false; return; }
        if (confirmCopyOpen) { confirmCopyOpen = false; return; }
        if (confirmMoveOpen) { confirmMoveOpen = false; return; }
        if (confirmDeleteOpen) { confirmDeleteOpen = false; return; }
        if (win.quickViewActive) { win.quickViewActive = false; return; }
        if (currentModel().filter.length > 0) {
            currentModel().setFilter("");
            leftFilterVisible = false;
            rightFilterVisible = false;
            currentListView().forceActiveFocus();
            return;
        }
    }}

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top App Bar
        Rectangle {
            Layout.fillWidth: true
            height: 42
            color: "#151821"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Logo & Title
                Rectangle {
                    width: 24
                    height: 24
                    radius: 5
                    color: theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "OP"
                        font.bold: true
                        font.pixelSize: 11
                        color: theme.accentForeground
                    }
                }

                Text {
                    text: "omapanel"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#ffffff"
                }

                Rectangle { width: 1; height: 18; color: "#282c37" }

                Button {
                    text: qsTr("QuickView (Ctrl+Q)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: win.quickViewActive ? theme.accent : "#a0a5b5"
                    onClicked: {
                        win.quickViewActive = !win.quickViewActive;
                        if (win.quickViewActive)
                            updateQuickView();
                    }
                }

                Button {
                    text: qsTr("Compare (Shift+F2)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: backend.compareDirectories()
                }

                Button {
                    text: qsTr("Multi-Rename (Ctrl+M)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: triggerMultiRename()
                }

                Button {
                    text: qsTr("Pack (Alt+F5)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: triggerPackArchive()
                }

                Button {
                    text: qsTr("Unpack (Alt+F9)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: triggerExtractArchive()
                }

                Button {
                    text: qsTr("Search (Alt+F7)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: {
                        searchInput.text = "";
                        searchResults = [];
                        searchOpen = true;
                        searchInput.forceActiveFocus();
                    }
                }

                Button {
                    text: qsTr("Terminal (Ctrl+T)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: "#a0a5b5"
                    onClicked: backend.openInTerminal(currentModel().path)
                }

                Button {
                    text: currentModel().showHidden ? qsTr("Dotfiles: ON") : qsTr("Dotfiles: OFF")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: currentModel().showHidden ? theme.accent : "#a0a5b5"
                    onClicked: {
                        var m = currentModel();
                        m.setShowHidden(!m.showHidden);
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Help (?)")
                    flat: true
                    font.pixelSize: 11
                    Material.foreground: theme.accent
                    onClicked: win.helpOpen = true
                }
            }
        }

        // Drives & Bookmarks Bar
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "#12141d"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    text: qsTr("Drives:")
                    font.pixelSize: 11
                    font.bold: true
                    color: "#6b7285"
                }

                Repeater {
                    model: backend.drives
                    delegate: Rectangle {
                        height: 22
                        implicitWidth: driveRow.implicitWidth + 12
                        radius: 3
                        color: driveMouse.containsMouse ? "#25293a" : "#1a1d2a"
                        border.width: 1
                        border.color: "#282d40"

                        RowLayout {
                            id: driveRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "💾 " + modelData.label
                                font.pixelSize: 11
                                color: "#d0d6e5"
                            }
                            Text {
                                visible: modelData.free.length > 0
                                text: "(" + modelData.free + ")"
                                font.pixelSize: 10
                                color: "#7d859c"
                            }
                        }

                        MouseArea {
                            id: driveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentModel().setPath(modelData.path)
                        }
                    }
                }

                Rectangle { width: 1; height: 16; color: "#282c37" }

                Text {
                    text: qsTr("Bookmarks:")
                    font.pixelSize: 11
                    font.bold: true
                    color: "#6b7285"
                }

                Repeater {
                    model: backend.bookmarks
                    delegate: Rectangle {
                        height: 22
                        implicitWidth: bmText.implicitWidth + 14
                        radius: 3
                        color: bmMouse.containsMouse ? "#25293a" : "#181b26"
                        border.width: 1
                        border.color: currentModel().path === modelData ? theme.accent : "#252938"

                        Text {
                            id: bmText
                            anchors.centerIn: parent
                            text: "★ " + (modelData === "/" ? "/" : modelData.split("/").pop())
                            font.pixelSize: 11
                            color: currentModel().path === modelData ? theme.accent : "#b8c0d4"
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
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    height: 22
                    implicitWidth: addBmText.implicitWidth + 12
                    radius: 3
                    color: addBmMouse.containsMouse ? "#262b3d" : "transparent"
                    border.width: 1
                    border.color: "#2c3146"

                    Text {
                        id: addBmText
                        anchors.centerIn: parent
                        text: "+ ★"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.accent
                    }

                    MouseArea {
                        id: addBmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.toggleBookmark(currentModel().path)
                    }
                }

                Item { Layout.fillWidth: true }

                // Swap & Sync quick buttons
                Rectangle {
                    height: 22
                    implicitWidth: swapTxt.implicitWidth + 12
                    radius: 3
                    color: swapMouse.containsMouse ? "#25293a" : "#181b26"
                    Text {
                        id: swapTxt
                        anchors.centerIn: parent
                        text: "⇄ Swap (Ctrl+U)"
                        font.pixelSize: 11
                        color: "#9da5bc"
                    }
                    MouseArea {
                        id: swapMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.swapPanels()
                    }
                }

                Rectangle {
                    height: 22
                    implicitWidth: syncTxt.implicitWidth + 12
                    radius: 3
                    color: syncMouse.containsMouse ? "#25293a" : "#181b26"
                    Text {
                        id: syncTxt
                        anchors.centerIn: parent
                        text: "= Sync (Alt+=)"
                        font.pixelSize: 11
                        color: "#9da5bc"
                    }
                    MouseArea {
                        id: syncMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.syncPanels()
                    }
                }
            }
        }

        // Two-Panel File Manager Area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            // ================= LEFT PANEL =================
            Rectangle {
                id: leftContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#11131a"
                border.width: backend.activePanel === 0 ? 2 : 1
                border.color: backend.activePanel === 0 ? theme.accent : "#222530"
                radius: Math.min(6, theme.radius)

                // Quick View overlay when Right Panel is active and QuickView is ON
                Rectangle {
                    visible: win.quickViewActive && backend.activePanel === 1
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "#12151f"
                    radius: 4
                    z: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "👁 " + qsTr("Quick View: %1").arg(win.quickViewData.name || "")
                                font.bold: true
                                font.pixelSize: 13
                                color: theme.accent
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Button {
                                text: "×"
                                flat: true
                                implicitWidth: 26
                                implicitHeight: 26
                                onClicked: win.quickViewActive = false
                            }
                        }

                        Image {
                            visible: win.quickViewData.isImage === true
                            source: win.quickViewData.imagePath || ""
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fillMode: Image.PreserveAspectFit
                        }

                        ScrollView {
                            visible: win.quickViewData.isImage !== true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                text: win.quickViewData.text || ""
                                readOnly: true
                                font.family: "monospace"
                                font.pixelSize: 12
                                color: "#d0d6e5"
                                background: Rectangle { color: "#0e1018"; radius: 4 }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onPressed: function(mouse) {
                        backend.activePanel = 0;
                        leftList.forceActiveFocus();
                        mouse.accepted = false;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // Panel Header: History, Path & Quick Jump
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "#181a24"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Button {
                                text: "◀"
                                flat: true
                                enabled: backend.leftPanel.canGoBack
                                implicitWidth: 26
                                implicitHeight: 28
                                onClicked: backend.leftPanel.goBack()
                            }
                            Button {
                                text: "▶"
                                flat: true
                                enabled: backend.leftPanel.canGoForward
                                implicitWidth: 26
                                implicitHeight: 28
                                onClicked: backend.leftPanel.goForward()
                            }
                            Button {
                                text: "~"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.leftPanel.setPath("~")
                            }

                            TextField {
                                id: leftPathField
                                Layout.fillWidth: true
                                text: backend.leftPanel.path
                                font.pixelSize: 12
                                selectByMouse: true
                                onAccepted: {
                                    backend.leftPanel.setPath(leftPathField.text);
                                    leftList.forceActiveFocus();
                                }
                            }

                            Button {
                                text: "🔍"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: {
                                    leftFilterVisible = !leftFilterVisible;
                                    if (leftFilterVisible)
                                        leftFilterField.forceActiveFocus();
                                    else
                                        backend.leftPanel.setFilter("");
                                }
                            }

                            Button {
                                text: "↻"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: backend.leftPanel.refresh()
                            }
                        }
                    }

                    // Filter Bar (Ctrl+S)
                    Rectangle {
                        visible: leftFilterVisible || backend.leftPanel.filter.length > 0
                        Layout.fillWidth: true
                        height: 30
                        color: "#1d2130"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: qsTr("Filter:")
                                font.pixelSize: 11
                                color: theme.accent
                                font.bold: true
                            }
                            TextField {
                                id: leftFilterField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Type to filter files...")
                                text: backend.leftPanel.filter
                                font.pixelSize: 12
                                onTextChanged: backend.leftPanel.setFilter(text)
                                Keys.onReturnPressed: leftList.forceActiveFocus()
                            }
                            Button {
                                text: "×"
                                flat: true
                                implicitWidth: 24
                                implicitHeight: 24
                                onClicked: {
                                    backend.leftPanel.setFilter("");
                                    leftFilterVisible = false;
                                    leftList.forceActiveFocus();
                                }
                            }
                        }
                    }

                    // Column Header Row
                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        color: "#1c1f2b"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: leftNameMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    Text {
                                        text: qsTr("Name") + (backend.leftPanel.sortField === 0 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.leftPanel.sortField === 0 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                    }
                                }
                                MouseArea {
                                    id: leftNameMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.leftPanel.setSortField(0)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 55
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: leftExtMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Ext") + (backend.leftPanel.sortField === 1 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.leftPanel.sortField === 1 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: leftExtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.leftPanel.setSortField(1)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 85
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: leftSizeMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Size") + (backend.leftPanel.sortField === 2 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.leftPanel.sortField === 2 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: leftSizeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.leftPanel.setSortField(2)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 130
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: leftDateMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Date") + (backend.leftPanel.sortField === 3 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.leftPanel.sortField === 3 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: leftDateMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.leftPanel.setSortField(3)
                                }
                            }
                        }
                    }

                    // Files ListView
                    ListView {
                        id: leftList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: backend.leftPanel
                        focus: backend.activePanel === 0
                        onCurrentIndexChanged: {
                            if (backend.activePanel === 0)
                                updateQuickView();
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: leftItemDelegate
                            width: leftList.width
                            height: 24
                            color: {
                                if (model.isSelected)
                                    return Qt.alpha(theme.accent, 0.28);
                                if (leftList.currentIndex === index && backend.activePanel === 0)
                                    return "#282c3c";
                                if (leftList.currentIndex === index)
                                    return "#1e212c";
                                return index % 2 === 0 ? "transparent" : "#131620";
                            }
                            border.width: (leftList.currentIndex === index && backend.activePanel === 0) ? 1 : 0
                            border.color: theme.accent
                            radius: 2

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    backend.activePanel = 0;
                                    leftList.currentIndex = index;
                                    leftList.forceActiveFocus();
                                    if (mouse.button === Qt.RightButton) {
                                        backend.leftPanel.toggleSelection(index);
                                    }
                                }
                                onDoubleClicked: {
                                    if (model.isDir) {
                                        backend.leftPanel.cd(model.name);
                                    } else {
                                        backend.openItem(model.path);
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: {
                                        if (model.isParent) return "⬆";
                                        if (model.isDir) return "📁";
                                        if (model.iconType === "image") return "🖼";
                                        if (model.iconType === "code") return "📄";
                                        if (model.iconType === "archive") return "📦";
                                        if (model.iconType === "video") return "🎬";
                                        if (model.iconType === "audio") return "🎵";
                                        if (model.iconType === "binary") return "⚙";
                                        return "🗎";
                                    }
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: model.name
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.bold: model.isDir
                                    font.pixelSize: 12
                                    color: {
                                        if (model.isSelected) return theme.accent;
                                        if (model.isDir) return "#ffffff";
                                        return "#c8cedd";
                                    }
                                }

                                Text {
                                    text: model.isDir ? "" : model.extension
                                    Layout.preferredWidth: 55
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#7e859b"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.formattedSize
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: model.isDir ? theme.accent : "#9da5bc"
                                }

                                Text {
                                    text: model.modified
                                    Layout.preferredWidth: 130
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#72788e"
                                }
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                var m = backend.leftPanel;
                                if (currentIndex >= 0 && currentIndex < m.itemCount) {
                                    if (m.itemIsDir(currentIndex))
                                        m.cd(m.itemName(currentIndex));
                                    else
                                        backend.openItem(m.itemPath(currentIndex));
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backspace) {
                                backend.leftPanel.cdUp();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Insert) {
                                backend.leftPanel.toggleSelection(currentIndex);
                                if (currentIndex + 1 < backend.leftPanel.itemCount)
                                    currentIndex++;
                                event.accepted = true;
                            } else if (event.text.length === 1 && event.modifiers === Qt.NoModifier && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                                var idx = backend.leftPanel.findIndexByPrefix(event.text, currentIndex + 1);
                                if (idx >= 0)
                                    currentIndex = idx;
                                event.accepted = true;
                            }
                        }
                    }

                    // Panel Footer / Status
                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        color: "#151722"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Text {
                                text: qsTr("%1 items | %2 selected (%3)").arg(backend.leftPanel.itemCount).arg(backend.leftPanel.selectedCount).arg(backend.leftPanel.totalSelectedSizeFormatted)
                                font.pixelSize: 11
                                color: "#8a91a5"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: qsTr("Free: %1").arg(backend.leftPanel.freeSpaceFormatted)
                                font.pixelSize: 11
                                color: "#6b7285"
                            }
                        }
                    }
                }
            }

            // ================= RIGHT PANEL =================
            Rectangle {
                id: rightContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#11131a"
                border.width: backend.activePanel === 1 ? 2 : 1
                border.color: backend.activePanel === 1 ? theme.accent : "#222530"
                radius: Math.min(6, theme.radius)

                // Quick View overlay when Left Panel is active and QuickView is ON
                Rectangle {
                    visible: win.quickViewActive && backend.activePanel === 0
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "#12151f"
                    radius: 4
                    z: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "👁 " + qsTr("Quick View: %1").arg(win.quickViewData.name || "")
                                font.bold: true
                                font.pixelSize: 13
                                color: theme.accent
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Button {
                                text: "×"
                                flat: true
                                implicitWidth: 26
                                implicitHeight: 26
                                onClicked: win.quickViewActive = false
                            }
                        }

                        Image {
                            visible: win.quickViewData.isImage === true
                            source: win.quickViewData.imagePath || ""
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fillMode: Image.PreserveAspectFit
                        }

                        ScrollView {
                            visible: win.quickViewData.isImage !== true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                text: win.quickViewData.text || ""
                                readOnly: true
                                font.family: "monospace"
                                font.pixelSize: 12
                                color: "#d0d6e5"
                                background: Rectangle { color: "#0e1018"; radius: 4 }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onPressed: function(mouse) {
                        backend.activePanel = 1;
                        rightList.forceActiveFocus();
                        mouse.accepted = false;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // Panel Header: History, Path & Quick Jump
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "#181a24"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Button {
                                text: "◀"
                                flat: true
                                enabled: backend.rightPanel.canGoBack
                                implicitWidth: 26
                                implicitHeight: 28
                                onClicked: backend.rightPanel.goBack()
                            }
                            Button {
                                text: "▶"
                                flat: true
                                enabled: backend.rightPanel.canGoForward
                                implicitWidth: 26
                                implicitHeight: 28
                                onClicked: backend.rightPanel.goForward()
                            }
                            Button {
                                text: "~"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.rightPanel.setPath("~")
                            }

                            TextField {
                                id: rightPathField
                                Layout.fillWidth: true
                                text: backend.rightPanel.path
                                font.pixelSize: 12
                                selectByMouse: true
                                onAccepted: {
                                    backend.rightPanel.setPath(rightPathField.text);
                                    rightList.forceActiveFocus();
                                }
                            }

                            Button {
                                text: "🔍"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: {
                                    rightFilterVisible = !rightFilterVisible;
                                    if (rightFilterVisible)
                                        rightFilterField.forceActiveFocus();
                                    else
                                        backend.rightPanel.setFilter("");
                                }
                            }

                            Button {
                                text: "↻"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: backend.rightPanel.refresh()
                            }
                        }
                    }

                    // Filter Bar (Ctrl+S)
                    Rectangle {
                        visible: rightFilterVisible || backend.rightPanel.filter.length > 0
                        Layout.fillWidth: true
                        height: 30
                        color: "#1d2130"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: qsTr("Filter:")
                                font.pixelSize: 11
                                color: theme.accent
                                font.bold: true
                            }
                            TextField {
                                id: rightFilterField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Type to filter files...")
                                text: backend.rightPanel.filter
                                font.pixelSize: 12
                                onTextChanged: backend.rightPanel.setFilter(text)
                                Keys.onReturnPressed: rightList.forceActiveFocus()
                            }
                            Button {
                                text: "×"
                                flat: true
                                implicitWidth: 24
                                implicitHeight: 24
                                onClicked: {
                                    backend.rightPanel.setFilter("");
                                    rightFilterVisible = false;
                                    rightList.forceActiveFocus();
                                }
                            }
                        }
                    }

                    // Column Header Row
                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        color: "#1c1f2b"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: rightNameMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    Text {
                                        text: qsTr("Name") + (backend.rightPanel.sortField === 0 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.rightPanel.sortField === 0 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                    }
                                }
                                MouseArea {
                                    id: rightNameMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.rightPanel.setSortField(0)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 55
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: rightExtMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Ext") + (backend.rightPanel.sortField === 1 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.rightPanel.sortField === 1 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: rightExtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.rightPanel.setSortField(1)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 85
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: rightSizeMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Size") + (backend.rightPanel.sortField === 2 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.rightPanel.sortField === 2 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: rightSizeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.rightPanel.setSortField(2)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 130
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: rightDateMouse.containsMouse ? "#262b3b" : "transparent"
                                    radius: 2
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    Text {
                                        text: qsTr("Date") + (backend.rightPanel.sortField === 3 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                        color: backend.rightPanel.sortField === 3 ? theme.accent : "#8b92a5"
                                        font.bold: true
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                MouseArea {
                                    id: rightDateMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.rightPanel.setSortField(3)
                                }
                            }
                        }
                    }

                    // Files ListView
                    ListView {
                        id: rightList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: backend.rightPanel
                        focus: backend.activePanel === 1
                        onCurrentIndexChanged: {
                            if (backend.activePanel === 1)
                                updateQuickView();
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: rightItemDelegate
                            width: rightList.width
                            height: 24
                            color: {
                                if (model.isSelected)
                                    return Qt.alpha(theme.accent, 0.28);
                                if (rightList.currentIndex === index && backend.activePanel === 1)
                                    return "#282c3c";
                                if (rightList.currentIndex === index)
                                    return "#1e212c";
                                return index % 2 === 0 ? "transparent" : "#131620";
                            }
                            border.width: (rightList.currentIndex === index && backend.activePanel === 1) ? 1 : 0
                            border.color: theme.accent
                            radius: 2

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    backend.activePanel = 1;
                                    rightList.currentIndex = index;
                                    rightList.forceActiveFocus();
                                    if (mouse.button === Qt.RightButton) {
                                        backend.rightPanel.toggleSelection(index);
                                    }
                                }
                                onDoubleClicked: {
                                    if (model.isDir) {
                                        backend.rightPanel.cd(model.name);
                                    } else {
                                        backend.openItem(model.path);
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: {
                                        if (model.isParent) return "⬆";
                                        if (model.isDir) return "📁";
                                        if (model.iconType === "image") return "🖼";
                                        if (model.iconType === "code") return "📄";
                                        if (model.iconType === "archive") return "📦";
                                        if (model.iconType === "video") return "🎬";
                                        if (model.iconType === "audio") return "🎵";
                                        if (model.iconType === "binary") return "⚙";
                                        return "🗎";
                                    }
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: model.name
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.bold: model.isDir
                                    font.pixelSize: 12
                                    color: {
                                        if (model.isSelected) return theme.accent;
                                        if (model.isDir) return "#ffffff";
                                        return "#c8cedd";
                                    }
                                }

                                Text {
                                    text: model.isDir ? "" : model.extension
                                    Layout.preferredWidth: 55
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#7e859b"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.formattedSize
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: model.isDir ? theme.accent : "#9da5bc"
                                }

                                Text {
                                    text: model.modified
                                    Layout.preferredWidth: 130
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#72788e"
                                }
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                var m = backend.rightPanel;
                                if (currentIndex >= 0 && currentIndex < m.itemCount) {
                                    if (m.itemIsDir(currentIndex))
                                        m.cd(m.itemName(currentIndex));
                                    else
                                        backend.openItem(m.itemPath(currentIndex));
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backspace) {
                                backend.rightPanel.cdUp();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Insert) {
                                backend.rightPanel.toggleSelection(currentIndex);
                                if (currentIndex + 1 < backend.rightPanel.itemCount)
                                    currentIndex++;
                                event.accepted = true;
                            } else if (event.text.length === 1 && event.modifiers === Qt.NoModifier && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                                var idx = backend.rightPanel.findIndexByPrefix(event.text, currentIndex + 1);
                                if (idx >= 0)
                                    currentIndex = idx;
                                event.accepted = true;
                            }
                        }
                    }

                    // Panel Footer / Status
                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        color: "#151722"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Text {
                                text: qsTr("%1 items | %2 selected (%3)").arg(backend.rightPanel.itemCount).arg(backend.rightPanel.selectedCount).arg(backend.rightPanel.totalSelectedSizeFormatted)
                                font.pixelSize: 11
                                color: "#8a91a5"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: qsTr("Free: %1").arg(backend.rightPanel.freeSpaceFormatted)
                                font.pixelSize: 11
                                color: "#6b7285"
                            }
                        }
                    }
                }
            }
        }

        // Status Notification / Busy Bar
        Rectangle {
            Layout.fillWidth: true
            height: (backend.isBusy || backend.statusMessage.length > 0) ? 26 : 0
            visible: height > 0
            color: "#181a26"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: backend.isBusy ? backend.busyTitle : backend.statusMessage
                    font.pixelSize: 11
                    color: backend.isBusy ? theme.accent : "#b0b8cb"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                ProgressBar {
                    visible: backend.isBusy
                    value: backend.busyProgress
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 4
                }
            }
        }

        // Mini Command Line Bar (Total Commander style)
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#141620"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: currentModel().path + " $"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 11
                    color: theme.accent
                    Layout.maximumWidth: 360
                    elide: Text.ElideLeft
                }

                TextField {
                    id: cmdLineInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("Run command in active folder (e.g. git status, chmod +x ...)")
                    font.family: "monospace"
                    font.pixelSize: 12
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
                }
            }
        }

        // Bottom Function Keys Bar (Total Commander classic F3-F10)
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#13151f"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F3 " + qsTr("View")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF3View()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F4 " + qsTr("Edit")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF4Edit()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F5 " + qsTr("Copy")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF5Copy()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F6 " + qsTr("Move")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF6Move()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F7 " + qsTr("NewFolder")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF7NewFolder()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F8 " + qsTr("Delete")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: triggerF8Delete()
                }
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "F10 " + qsTr("Exit")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: Qt.quit()
                }
            }
        }
    }

    // ================= MODALS & DIALOGS =================

    // Confirm Copy Dialog
    Dialog {
        id: copyDialog
        visible: win.confirmCopyOpen
        title: qsTr("Copy Files (F5)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Copy %1 item(s) to:").arg(getSelectedOrCurrentPaths().length)
                color: "#ffffff"
                font.pixelSize: 13
            }
            TextField {
                id: copyDestField
                text: targetModel().path
                Layout.preferredWidth: 420
                onAccepted: copyDialog.accept()
            }
        }

        onAccepted: {
            win.confirmCopyOpen = false;
            backend.copyItems(getSelectedOrCurrentPaths(), copyDestField.text);
        }
        onRejected: win.confirmCopyOpen = false
    }

    // Confirm Move Dialog
    Dialog {
        id: moveDialog
        visible: win.confirmMoveOpen
        title: qsTr("Move Files (F6)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Move %1 item(s) to:").arg(getSelectedOrCurrentPaths().length)
                color: "#ffffff"
                font.pixelSize: 13
            }
            TextField {
                id: moveDestField
                text: targetModel().path
                Layout.preferredWidth: 420
                onAccepted: moveDialog.accept()
            }
        }

        onAccepted: {
            win.confirmMoveOpen = false;
            backend.moveItems(getSelectedOrCurrentPaths(), moveDestField.text);
        }
        onRejected: win.confirmMoveOpen = false
    }

    // Confirm Delete Dialog
    Dialog {
        id: deleteDialog
        visible: win.confirmDeleteOpen
        title: qsTr("Delete Files (F8)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Are you sure you want to delete %1 selected item(s)?").arg(getSelectedOrCurrentPaths().length)
                color: "#ffffff"
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
    Dialog {
        id: newFolderDialog
        visible: win.newFolderOpen
        title: qsTr("Create New Folder (F7)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Folder name:")
                color: "#ffffff"
                font.pixelSize: 13
            }
            TextField {
                id: newFolderInput
                placeholderText: "New_Folder"
                Layout.preferredWidth: 350
                onAccepted: newFolderDialog.accept()
            }
        }

        onAccepted: {
            win.newFolderOpen = false;
            backend.createDirectory(newFolderInput.text);
        }
        onRejected: win.newFolderOpen = false
    }

    // Rename Dialog
    Dialog {
        id: renameDialog
        visible: win.renameOpen
        title: qsTr("Rename (Shift+F6)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("New name for %1:").arg(win.renameOldName)
                color: "#ffffff"
                font.pixelSize: 13
            }
            TextField {
                id: renameInput
                Layout.preferredWidth: 350
                onAccepted: renameDialog.accept()
            }
        }

        onAccepted: {
            win.renameOpen = false;
            backend.renameItem(win.renameOldPath, renameInput.text);
        }
        onRejected: win.renameOpen = false
    }

    // Multi-Rename Tool Dialog (Ctrl+M)
    Dialog {
        id: multiRenameDialog
        visible: win.multiRenameOpen
        title: qsTr("Multi-Rename Tool (Ctrl+M)")
        anchors.centerIn: parent
        modal: true
        width: 680
        height: 520
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            GridLayout {
                columns: 4
                Layout.fillWidth: true
                columnSpacing: 10
                rowSpacing: 8

                Text { text: qsTr("Find:"); color: "#b0b8cb"; font.pixelSize: 12 }
                TextField {
                    id: mrFindField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Replace:"); color: "#b0b8cb"; font.pixelSize: 12 }
                TextField {
                    id: mrReplaceField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Prefix:"); color: "#b0b8cb"; font.pixelSize: 12 }
                TextField {
                    id: mrPrefixField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Suffix:"); color: "#b0b8cb"; font.pixelSize: 12 }
                TextField {
                    id: mrSuffixField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text { text: qsTr("Case:"); color: "#b0b8cb"; font.pixelSize: 12 }
                ComboBox {
                    id: mrCaseCombo
                    model: [qsTr("Unchanged"), qsTr("lowercase"), qsTr("UPPERCASE"), qsTr("Title Case")]
                    onCurrentIndexChanged: refreshMultiRenamePreview()
                }

                CheckBox {
                    id: mrCounterCheck
                    text: qsTr("Append counter (_001, _002...)")
                    onCheckedChanged: refreshMultiRenamePreview()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 24
                color: "#1c1f2b"
                radius: 3

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text { text: qsTr("Original Name"); font.bold: true; font.pixelSize: 11; color: "#8b92a5"; Layout.fillWidth: true }
                    Text { text: qsTr("New Name Preview"); font.bold: true; font.pixelSize: 11; color: theme.accent; Layout.fillWidth: true }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.multiRenamePreviewList

                delegate: Rectangle {
                    width: parent.width
                    height: 24
                    color: index % 2 === 0 ? "#141722" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        Text {
                            text: modelData.oldName
                            color: "#9da5bc"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "→ " + modelData.newName
                            color: theme.accent
                            font.bold: true
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        onAccepted: {
            win.multiRenameOpen = false;
            backend.executeMultiRename(
                getSelectedOrCurrentPaths(),
                mrFindField.text,
                mrReplaceField.text,
                mrPrefixField.text,
                mrSuffixField.text,
                mrCaseCombo.currentIndex,
                mrCounterCheck.checked
            );
        }
        onRejected: win.multiRenameOpen = false
    }

    // Pack Archive Dialog (Alt+F5)
    Dialog {
        id: packDialog
        visible: win.packArchiveOpen
        title: qsTr("Pack Files into Archive (Alt+F5)")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Create archive (.zip, .tar.gz, .tar.xz) from %1 item(s):").arg(getSelectedOrCurrentPaths().length)
                color: "#ffffff"
                font.pixelSize: 13
            }
            TextField {
                id: packArchiveField
                Layout.preferredWidth: 440
                onAccepted: packDialog.accept()
            }
        }

        onAccepted: {
            win.packArchiveOpen = false;
            backend.packArchive(getSelectedOrCurrentPaths(), packArchiveField.text);
        }
        onRejected: win.packArchiveOpen = false
    }

    // Command Output Modal
    Dialog {
        id: cmdOutputDialog
        visible: win.commandOutputOpen
        title: qsTr("Command Output")
        anchors.centerIn: parent
        modal: true
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
                color: "#d0d6e5"
                background: Rectangle { color: "#12151f"; radius: 4 }
            }
        }

        onRejected: win.commandOutputOpen = false
    }

    // File Preview Modal (F3 View)
    Dialog {
        id: previewDialog
        visible: win.previewOpen
        title: qsTr("Preview: %1").arg(previewData.name || "")
        anchors.centerIn: parent
        modal: true
        width: 740
        height: 540
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: qsTr("Path: %1 | Size: %2 | Modified: %3").arg(previewData.path || "").arg(previewData.formattedSize || "").arg(previewData.modified || "")
                font.pixelSize: 11
                color: "#8b92a5"
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }

            Image {
                visible: previewData.isImage === true
                source: previewData.imagePath || ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: Image.PreserveAspectFit
            }

            ScrollView {
                visible: previewData.isImage !== true
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    text: previewData.text || ""
                    readOnly: true
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: "#d0d6e5"
                    background: Rectangle { color: "#131620"; radius: 4 }
                }
            }
        }

        onRejected: win.previewOpen = false
    }

    // Alt+F7 Search Dialog
    Dialog {
        id: searchDialog
        visible: win.searchOpen
        title: qsTr("Find Files (Alt+F7)")
        anchors.centerIn: parent
        modal: true
        width: 650
        height: 480
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: searchInput
                    placeholderText: qsTr("Type file name to search...")
                    Layout.fillWidth: true
                    onAccepted: {
                        win.searchResults = backend.searchFiles(currentModel().path, searchInput.text);
                    }
                }
                Button {
                    text: qsTr("Search")
                    font.bold: true
                    onClicked: {
                        win.searchResults = backend.searchFiles(currentModel().path, searchInput.text);
                    }
                }
            }

            Text {
                text: qsTr("%1 result(s) found in %2").arg(win.searchResults.length).arg(currentModel().path)
                font.pixelSize: 11
                color: "#8b92a5"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.searchResults

                delegate: Rectangle {
                    width: parent.width
                    height: 26
                    color: index % 2 === 0 ? "#141722" : "#181b28"
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        Text {
                            text: modelData
                            color: "#c8cedd"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                        Button {
                            text: qsTr("Open")
                            flat: true
                            implicitHeight: 22
                            onClicked: {
                                backend.openItem(modelData);
                                win.searchOpen = false;
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.searchOpen = false
    }

    // Keyboard Shortcuts Help Overlay
    Dialog {
        id: helpDialog
        visible: win.helpOpen
        title: qsTr("omapanel — Keyboard Shortcuts")
        anchors.centerIn: parent
        modal: true
        width: 580
        height: 540
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { key: "Tab", desc: qsTr("Switch active panel (Left / Right)") },
                        { key: "Space / Insert", desc: qsTr("Select item (and calculate folder size) + advance") },
                        { key: "Alt + Shift + Enter", desc: qsTr("Calculate sizes for all folders in panel") },
                        { key: "Ctrl + Q", desc: qsTr("Toggle live Quick View in opposite panel") },
                        { key: "Ctrl + S", desc: qsTr("Toggle real-time quick filter bar") },
                        { key: "Ctrl + U / Alt + =", desc: qsTr("Swap panels / Sync target panel") },
                        { key: "Shift + F2", desc: qsTr("Compare Left & Right directories (select differences)") },
                        { key: "Ctrl + M", desc: qsTr("Multi-Rename Tool for selected items") },
                        { key: "Alt + F5 / Alt + F9", desc: qsTr("Pack files to archive / Extract archive") },
                        { key: "Alt + Left / Right", desc: qsTr("Navigate directory history Back / Forward") },
                        { key: "F3", desc: qsTr("View file/folder/archive preview (Text, Image, Hex)") },
                        { key: "F4", desc: qsTr("Edit file with default editor ($EDITOR)") },
                        { key: "F5 / F6", desc: qsTr("Copy / Move selected item(s) to target panel") },
                        { key: "Shift + F6", desc: qsTr("Rename highlighted item") },
                        { key: "F7 / F8", desc: qsTr("Create new folder / Delete selected item(s)") },
                        { key: "Alt + F7", desc: qsTr("Search files recursively") },
                        { key: "Ctrl + F3..F6", desc: qsTr("Sort by Name, Ext, Date, or Size") },
                        { key: "Ctrl + A / Ctrl + D", desc: qsTr("Select all / Deselect all") },
                        { key: "Ctrl + H", desc: qsTr("Toggle show/hide hidden dotfiles") },
                        { key: "Ctrl + T", desc: qsTr("Open terminal in active folder") },
                        { key: "F10 / Esc", desc: qsTr("Quit omapanel / Close dialog") }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: index % 2 === 0 ? "#161822" : "transparent"
                        radius: 3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Rectangle {
                                color: "#222636"
                                radius: 4
                                implicitWidth: 145
                                implicitHeight: 22

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: theme.accent
                                }
                            }

                            Text {
                                text: modelData.desc
                                font.pixelSize: 12
                                color: "#d0d4e2"
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        onRejected: win.helpOpen = false
    }
}
