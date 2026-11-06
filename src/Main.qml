import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1200
    height: 760
    minimumWidth: 800
    minimumHeight: 500
    visible: true
    title: "omapanel — File Manager"
    color: "#0f1117"

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    // State
    property bool helpOpen: false
    property bool previewOpen: false
    property var previewData: ({})
    property bool searchOpen: false
    property var searchResults: []
    property bool newFolderOpen: false
    property bool renameOpen: false
    property string renameOldPath: ""
    property string renameOldName: ""
    property bool confirmCopyOpen: false
    property bool confirmMoveOpen: false
    property bool confirmDeleteOpen: false

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

    function getSelectedOrCurrentPaths() {
        var m = currentModel();
        var sel = m.selectedPaths();
        if (sel.length > 0)
            return sel;
        var lv = currentListView();
        if (lv.currentIndex >= 0 && lv.currentIndex < m.itemCount) {
            var p = m.itemPath(lv.currentIndex);
            if (p && !m.data(m.index(lv.currentIndex, 0), 258 /* IsParentRole */))
                return [p];
        }
        return [];
    }

    // Actions
    function triggerF3View() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
            previewData = backend.getPreview(paths[0]);
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
            confirmCopyOpen = true;
        } else {
            backend.showStatus(qsTr("No files selected to copy."));
        }
    }

    function triggerF6Move() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) {
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
            renameOldPath = m.itemPath(lv.currentIndex);
            renameOldName = m.itemName(lv.currentIndex);
            renameInput.text = renameOldName;
            renameOpen = true;
            renameInput.forceActiveFocus();
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

    // Global Shortcuts
    Shortcut { sequence: "Tab"; context: Qt.ApplicationShortcut; onActivated: {
        backend.switchPanel();
        currentListView().forceActiveFocus();
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
    Shortcut { sequence: "Alt+F7"; context: Qt.ApplicationShortcut; onActivated: {
        searchInput.text = "";
        searchResults = [];
        searchOpen = true;
        searchInput.forceActiveFocus();
    }}
    Shortcut { sequence: "Ctrl+H"; context: Qt.ApplicationShortcut; onActivated: {
        var m = currentModel();
        m.showHidden = !m.showHidden;
    }}
    Shortcut { sequence: "Ctrl+R"; context: Qt.ApplicationShortcut; onActivated: currentModel().refresh() }
    Shortcut { sequence: "Ctrl+A"; context: Qt.ApplicationShortcut; onActivated: currentModel().selectAll() }
    Shortcut { sequence: "Ctrl+D"; context: Qt.ApplicationShortcut; onActivated: currentModel().deselectAll() }
    Shortcut { sequence: "Ctrl+Shift+A"; context: Qt.ApplicationShortcut; onActivated: currentModel().invertSelection() }
    Shortcut { sequence: "Ctrl+T"; context: Qt.ApplicationShortcut; onActivated: backend.openInTerminal(currentModel().path) }
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: {
        if (helpOpen) { helpOpen = false; return; }
        if (previewOpen) { previewOpen = false; return; }
        if (searchOpen) { searchOpen = false; return; }
        if (newFolderOpen) { newFolderOpen = false; return; }
        if (renameOpen) { renameOpen = false; return; }
        if (confirmCopyOpen) { confirmCopyOpen = false; return; }
        if (confirmMoveOpen) { confirmMoveOpen = false; return; }
        if (confirmDeleteOpen) { confirmDeleteOpen = false; return; }
        if (currentModel().filter.length > 0) {
            currentModel().filter = "";
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
            height: 44
            color: "#151821"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

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

                Rectangle {
                    width: 1
                    height: 18
                    color: "#282c37"
                }

                // Quick buttons
                Button {
                    text: qsTr("Terminal (Ctrl+T)")
                    flat: true
                    font.pixelSize: 12
                    Material.foreground: "#a0a5b5"
                    onClicked: backend.openInTerminal(currentModel().path)
                }

                Button {
                    text: qsTr("Search (Alt+F7)")
                    flat: true
                    font.pixelSize: 12
                    Material.foreground: "#a0a5b5"
                    onClicked: {
                        searchInput.text = "";
                        searchResults = [];
                        searchOpen = true;
                        searchInput.forceActiveFocus();
                    }
                }

                Button {
                    text: currentModel().showHidden ? qsTr("Hide Hidden (Ctrl+H)") : qsTr("Show Hidden (Ctrl+H)")
                    flat: true
                    font.pixelSize: 12
                    Material.foreground: "#a0a5b5"
                    onClicked: {
                        var m = currentModel();
                        m.showHidden = !m.showHidden;
                    }
                }

                Item { Layout.fillWidth: true }

                // Shortcuts Help button
                Button {
                    text: qsTr("Help (?)")
                    flat: true
                    font.pixelSize: 12
                    Material.foreground: theme.accent
                    onClicked: win.helpOpen = true
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

                    // Panel Header: Path & Quick Jump
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "#181a24"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            // Drive/Location jumps
                            Button {
                                text: "~"
                                flat: true
                                implicitWidth: 32
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.leftPanel.cd("~")
                            }
                            Button {
                                text: "/"
                                flat: true
                                implicitWidth: 32
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.leftPanel.cd("/")
                            }

                            // Path input / breadcrumb
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

                            // Refresh button
                            Button {
                                text: "↻"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: backend.leftPanel.refresh()
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
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: qsTr("Name") + (backend.leftPanel.sortField === 0 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.leftPanel.sortField === 0 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.leftPanel.setSortField(0)
                                }
                            }
                            Text {
                                text: qsTr("Ext") + (backend.leftPanel.sortField === 1 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.leftPanel.sortField === 1 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 45
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.leftPanel.setSortField(1)
                                }
                            }
                            Text {
                                text: qsTr("Size") + (backend.leftPanel.sortField === 2 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.leftPanel.sortField === 2 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.leftPanel.setSortField(2)
                                }
                            }
                            Text {
                                text: qsTr("Date") + (backend.leftPanel.sortField === 3 ? (backend.leftPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.leftPanel.sortField === 3 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 125
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
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

                                // Icon
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

                                // Name
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

                                // Extension
                                Text {
                                    text: model.isDir ? "" : model.extension
                                    Layout.preferredWidth: 45
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#7e859b"
                                    elide: Text.ElideRight
                                }

                                // Size
                                Text {
                                    text: model.formattedSize
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: model.isDir ? theme.accent : "#9da5bc"
                                }

                                // Date
                                Text {
                                    text: model.modified
                                    Layout.preferredWidth: 125
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

                    // Panel Header: Path & Quick Jump
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "#181a24"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            // Drive/Location jumps
                            Button {
                                text: "~"
                                flat: true
                                implicitWidth: 32
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.rightPanel.cd("~")
                            }
                            Button {
                                text: "/"
                                flat: true
                                implicitWidth: 32
                                implicitHeight: 28
                                font.bold: true
                                onClicked: backend.rightPanel.cd("/")
                            }

                            // Path input / breadcrumb
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

                            // Refresh button
                            Button {
                                text: "↻"
                                flat: true
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: backend.rightPanel.refresh()
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
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: qsTr("Name") + (backend.rightPanel.sortField === 0 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.rightPanel.sortField === 0 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.rightPanel.setSortField(0)
                                }
                            }
                            Text {
                                text: qsTr("Ext") + (backend.rightPanel.sortField === 1 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.rightPanel.sortField === 1 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 45
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.rightPanel.setSortField(1)
                                }
                            }
                            Text {
                                text: qsTr("Size") + (backend.rightPanel.sortField === 2 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.rightPanel.sortField === 2 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.rightPanel.setSortField(2)
                                }
                            }
                            Text {
                                text: qsTr("Date") + (backend.rightPanel.sortField === 3 ? (backend.rightPanel.sortAscending ? " ▲" : " ▼") : "")
                                color: backend.rightPanel.sortField === 3 ? theme.accent : "#8b92a5"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.preferredWidth: 125
                                horizontalAlignment: Text.AlignRight
                                MouseArea {
                                    anchors.fill: parent
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

                                // Icon
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

                                // Name
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

                                // Extension
                                Text {
                                    text: model.isDir ? "" : model.extension
                                    Layout.preferredWidth: 45
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: "#7e859b"
                                    elide: Text.ElideRight
                                }

                                // Size
                                Text {
                                    text: model.formattedSize
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: 11
                                    color: model.isDir ? theme.accent : "#9da5bc"
                                }

                                // Date
                                Text {
                                    text: model.modified
                                    Layout.preferredWidth: 125
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
            height: (backend.isBusy || backend.statusMessage.length > 0) ? 28 : 0
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
                }

                ProgressBar {
                    visible: backend.isBusy
                    value: backend.busyProgress
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                }
            }
        }

        // Bottom Function Keys Bar (Total Commander classic F3-F10)
        Rectangle {
            Layout.fillWidth: true
            height: 40
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
                Layout.preferredWidth: 400
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
                Layout.preferredWidth: 400
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

    // File Preview Modal (F3 View)
    Dialog {
        id: previewDialog
        visible: win.previewOpen
        title: qsTr("Preview: %1").arg(previewData.name || "")
        anchors.centerIn: parent
        modal: true
        width: 700
        height: 520
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // Metadata row
            Text {
                text: qsTr("Path: %1 | Size: %2 | Modified: %3").arg(previewData.path || "").arg(previewData.size || 0).arg(previewData.modified || "")
                font.pixelSize: 11
                color: "#8b92a5"
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }

            // Image Preview
            Image {
                visible: previewData.isImage === true
                source: previewData.imagePath || ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: Image.PreserveAspectFit
            }

            // Text Preview
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
        width: 550
        height: 500
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { key: "Tab", desc: qsTr("Switch active panel (Left / Right)") },
                        { key: "Up / Down", desc: qsTr("Navigate files in active panel") },
                        { key: "Enter", desc: qsTr("Open directory or launch file") },
                        { key: "Backspace", desc: qsTr("Go to parent directory (..)") },
                        { key: "Space / Insert", desc: qsTr("Toggle item selection and advance cursor") },
                        { key: "Ctrl + A", desc: qsTr("Select all items in active panel") },
                        { key: "Ctrl + D", desc: qsTr("Deselect all items") },
                        { key: "Ctrl + Shift + A", desc: qsTr("Invert selection") },
                        { key: "F3", desc: qsTr("View file preview (Text, Image, Hex)") },
                        { key: "F4", desc: qsTr("Edit file with default editor ($EDITOR)") },
                        { key: "F5", desc: qsTr("Copy selected item(s) to target panel") },
                        { key: "F6", desc: qsTr("Move selected item(s) to target panel") },
                        { key: "Shift + F6", desc: qsTr("Rename highlighted item") },
                        { key: "F7", desc: qsTr("Create new folder") },
                        { key: "F8 / Delete", desc: qsTr("Delete selected item(s)") },
                        { key: "Alt + F7", desc: qsTr("Search files recursively") },
                        { key: "Ctrl + H", desc: qsTr("Toggle show/hide hidden dotfiles") },
                        { key: "Ctrl + R", desc: qsTr("Refresh active directory list") },
                        { key: "Ctrl + T", desc: qsTr("Open terminal in active folder") },
                        { key: "F10", desc: qsTr("Quit omapanel") },
                        { key: "Esc", desc: qsTr("Close any open dialog or clear filter") }
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
                                implicitWidth: 120
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
