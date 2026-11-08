import QtQuick
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
    color: "#0b0d13"

    property bool windowSessionReady: false
    Component.onCompleted: windowSessionReady = true
    onWidthChanged: if (windowSessionReady && width >= minimumWidth) backend.windowWidth = width
    onHeightChanged: if (windowSessionReady && height >= minimumHeight) backend.windowHeight = height

    Material.theme: Material.Dark
    Material.accent: theme.accent
    // Material.roundedScale is an enum, not a pixel radius; map Hyprland's rounding cleanly.
    Material.roundedScale: theme.radius <= 0 ? Material.NotRounded
                         : theme.radius <= 5 ? Material.ExtraSmallScale
                         : theme.radius <= 10 ? Material.SmallScale
                         : Material.MediumScale

    readonly property int panelRadius: Math.min(6, theme.radius)
    readonly property int smallRadius: Math.min(4, theme.radius)

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
    property bool menuBarActive: false

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
        property color iconColor: "#94a3b8"
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
            if (btnMouse.pressed) return "#2a3147";
            if (active) return Qt.alpha(theme.accent, 0.18);
            if (btnMouse.containsMouse) return "#202637";
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(theme.accent, 0.5)

        VectorIcon {
            visible: iconBtn.iconKind.length > 0
            anchors.centerIn: parent
            kind: iconBtn.iconKind
            iconColor: iconBtn.active ? theme.accent : (btnMouse.containsMouse ? "#eef2ff" : "#9aa3b8")
        }

        Text {
            visible: iconBtn.iconKind.length === 0
            anchors.centerIn: parent
            text: iconBtn.label
            font.pixelSize: 12
            font.bold: true
            color: iconBtn.active ? theme.accent : (btnMouse.containsMouse ? "#eef2ff" : "#9aa3b8")
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
            if (tbMouse.pressed) return "#283046";
            if (active) return Qt.alpha(theme.accent, 0.18);
            if (tbMouse.containsMouse) return "#1c2233";
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(theme.accent, 0.5)

        RowLayout {
            id: tbRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: tbBtn.label
                font.pixelSize: 12
                font.weight: (tbBtn.active || tbBtn.accentHighlight) ? Font.DemiBold : Font.Normal
                color: (tbBtn.active || tbBtn.accentHighlight) ? theme.accent
                     : (tbMouse.containsMouse && tbBtn.btnEnabled ? "#f1f5f9" : "#b8c1d4")
            }

            Rectangle {
                visible: tbBtn.shortcutHint.length > 0
                implicitHeight: 16
                implicitWidth: hintText.implicitWidth + 8
                radius: Math.min(3, theme.radius)
                color: tbBtn.active ? Qt.alpha(theme.accent, 0.2) : "#171b27"
                border.width: 1
                border.color: tbBtn.active ? Qt.alpha(theme.accent, 0.35) : "#242a3b"

                Text {
                    id: hintText
                    anchors.centerIn: parent
                    text: tbBtn.shortcutHint
                    font.pixelSize: 10
                    font.family: "monospace"
                    color: tbBtn.active ? theme.accent : "#78829a"
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
            if (active) return Qt.alpha(theme.accent, 0.22);
            if (mbMouse.containsMouse) return "#1c2233";
            return "transparent";
        }
        border.width: active ? 1 : 0
        border.color: Qt.alpha(theme.accent, 0.5)

        Text {
            id: mbText
            anchors.centerIn: parent
            text: mbBtn.label
            font.pixelSize: 12
            font.weight: mbBtn.active ? Font.DemiBold : Font.Normal
            color: mbBtn.active ? theme.accent
                 : (mbMouse.containsMouse ? "#f8fafc" : "#b8c1d4")
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

    // Sleek dark-themed popup dropdown menu.
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
            color: "#111522"
            border.width: 1
            border.color: "#273046"
            radius: win.panelRadius

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: win.panelRadius + 1
                color: "transparent"
                border.width: 1
                border.color: "#07090f"
                opacity: 0.8
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
                    color: theme.accent
                }
            }

            Text {
                text: miRoot.text
                font.pixelSize: 12
                font.weight: miRoot.highlighted ? Font.Medium : Font.Normal
                color: !miRoot.enabled ? "#525c76" : (miRoot.highlighted ? "#ffffff" : "#d8dfed")
                Layout.fillWidth: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: miRoot.shortcutHint.length > 0
                text: miRoot.shortcutHint
                font.pixelSize: 11
                font.family: "monospace"
                color: !miRoot.enabled ? "#424b61" : (miRoot.highlighted ? theme.accent : "#7a859e")
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            implicitWidth: 310
            implicitHeight: 28
            radius: win.smallRadius
            color: {
                if (!miRoot.enabled) return "transparent";
                if (miRoot.highlighted) return Qt.alpha(theme.accent, 0.22);
                return "transparent";
            }
            border.width: miRoot.highlighted && miRoot.enabled ? 1 : 0
            border.color: Qt.alpha(theme.accent, 0.45)
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
            color: "#21293c"
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
            if (permMouse.pressed) return "#262f47";
            if (isChecked) return Qt.alpha(theme.accent, 0.18);
            if (permMouse.containsMouse) return "#1b2133";
            return "#131724";
        }
        border.width: 1
        border.color: isChecked ? Qt.alpha(theme.accent, 0.55) : "#22293d"

        Text {
            anchors.centerIn: parent
            text: (permBtn.isChecked ? "✓ " : "  ") + permBtn.label
            font.pixelSize: 11
            font.family: "monospace"
            font.weight: permBtn.isChecked ? Font.DemiBold : Font.Normal
            color: permBtn.isChecked ? theme.accent : "#8b95ab"
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
        color: "#0a0c12"
        border.width: 1
        border.color: textInput.activeFocus ? theme.accent : "#242a3d"
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
            color: "#5c657d"
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
            color: "#eef2ff"
            selectionColor: Qt.alpha(theme.accent, 0.38)
            selectedTextColor: "#ffffff"
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

    // Bottom Total-Commander function key button (F3..F10).
    component FKeyButton : Rectangle {
        id: fkeyBtn
        property string keyLabel: ""
        property string actionLabel: ""
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: win.smallRadius
        color: fkeyMouse.pressed ? "#252c40" : (fkeyMouse.containsMouse ? "#1c2233" : "#131722")
        border.width: 1
        border.color: fkeyMouse.containsMouse ? "#2f3750" : "#1e2436"

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                implicitHeight: 18
                implicitWidth: fkeyText.implicitWidth + 8
                radius: Math.min(3, theme.radius)
                color: Qt.alpha(theme.accent, 0.16)

                Text {
                    id: fkeyText
                    anchors.centerIn: parent
                    text: fkeyBtn.keyLabel
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "monospace"
                    color: theme.accent
                }
            }

            Text {
                text: fkeyBtn.actionLabel
                font.pixelSize: 12
                font.weight: Font.Medium
                color: fkeyMouse.containsMouse ? "#ffffff" : "#d5dceb"
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
        readonly property int colSizeWidth: width < 480 ? 74 : 84
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
            // Keep dotfiles like .bashrc intact in the Name column.
            if (name === "." + ext)
                return name;
            var suffix = "." + ext;
            if (name.length > suffix.length && name.slice(-suffix.length) === suffix)
                return name.slice(0, name.length - suffix.length);
            return name;
        }

        function displayExt(name, ext, isDir) {
            if (isDir || !ext || ext.length === 0 || name === "." + ext)
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
            if (isSelected) return theme.accent;
            if (isParent) return "#7c859c";
            if (isDir) return "#eab308";
            if (iconType === "code") return "#60a5fa";
            if (iconType === "archive") return "#f59e0b";
            if (iconType === "image") return "#c084fc";
            if (iconType === "video") return "#f472b6";
            if (iconType === "audio") return "#2dd4bf";
            if (iconType === "binary") return "#34d399";
            return "#8b95ab";
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: isActive ? "#10131d" : "#0c0f17"
        border.width: 1
        border.color: isActive ? Qt.alpha(theme.accent, 0.65) : "#1d2232"
        radius: win.panelRadius
        clip: true

        // Top active-panel accent indicator line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            visible: panelRoot.isActive
            color: theme.accent
            z: 5
        }

        // Quick View overlay when the OPPOSITE panel is active and QuickView is ON
        Rectangle {
            visible: win.quickViewActive && !panelRoot.isActive
            anchors.fill: parent
            anchors.margins: 1
            color: "#0f121b"
            radius: Math.max(0, win.panelRadius - 1)
            z: 10

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: "#151926"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: qsTr("Quick View: %1").arg(win.quickViewData.name || "")
                            font.bold: true
                            font.pixelSize: 12
                            color: theme.accent
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }

                        Text {
                            visible: (win.quickViewData.formattedSize || "").length > 0
                            text: win.quickViewData.formattedSize || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: "#7c859c"
                        }

                        Text {
                            visible: win.quickViewData.isImage === true && (win.quickViewData.imageDimensions || "").length > 0
                            text: (win.quickViewData.imageDimensions || "") + (win.quickViewData.imageFormat ? " (" + win.quickViewData.imageFormat + ")" : "")
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: "#9aa6bf"
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
                        color: "#202638"
                    }
                }

                Image {
                    visible: win.quickViewData.isImage === true
                    source: win.quickViewData.imagePath || ""
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 12
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
                        color: "#d4dceb"
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10
                        background: Rectangle { color: "transparent" }
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
                color: "#0b0e16"

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
                                        if (dropHover) return Qt.alpha(theme.accent, 0.24);
                                        if (isTabActive) return panelRoot.isActive ? "#192034" : "#151926";
                                        if (tabMouse.containsMouse) return "#131724";
                                        return "transparent";
                                    }
                                    border.width: (isTabActive || dropHover) ? 1 : 0
                                    border.color: dropHover ? theme.accent
                                                : (panelRoot.isActive ? Qt.alpha(theme.accent, 0.52) : "#252c40")

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
                                                       ? (panelRoot.isActive ? theme.accent : "#94a3b8")
                                                       : "#5c657d"
                                        }

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            font.weight: tabPill.isTabActive ? Font.DemiBold : Font.Normal
                                            color: tabPill.isTabActive ? "#f1f5f9"
                                                 : (tabMouse.containsMouse ? "#cbd5e1" : "#7e879e")
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                        }

                                        Rectangle {
                                            visible: panelRoot.panelModel.tabCount > 1
                                            width: 15
                                            height: 15
                                            radius: Math.min(3, theme.radius)
                                            color: closeTabMouse.containsMouse ? "#283048" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "×"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: closeTabMouse.containsMouse ? "#f8fafc" : "#737d96"
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
                    color: "#1b2133"
                }
            }

            // 1. Panel Header: History, Breadcrumb / Editable Path Bar, Bookmark, Filter & Refresh
            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: panelRoot.isActive ? "#151927" : "#10131d"

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
                            color: "#090b11"
                            border.width: 1
                            border.color: panelRoot.isActive ? "#252c40" : "#1b2030"
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
                                                    color: "#4c556b"
                                                }

                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 22
                                                    width: segText.implicitWidth + 10
                                                    radius: Math.min(3, theme.radius)
                                                    color: segMouse.containsMouse ? "#1b2133" : "transparent"

                                                    Text {
                                                        id: segText
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        font.pixelSize: 12
                                                        font.family: "monospace"
                                                        font.weight: isLast ? Font.DemiBold : Font.Normal
                                                        color: isLast ? (panelRoot.isActive ? "#f8fafc" : "#cbd5e1")
                                                             : (segMouse.containsMouse ? "#e2e8f0" : "#8b95ab")
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
                                    visible: !panelRoot.panelModel.isWritable
                                    implicitHeight: 18
                                    implicitWidth: roText.implicitWidth + 8
                                    radius: 3
                                    color: Qt.alpha("#ef4444", 0.15)
                                    border.width: 1
                                    border.color: Qt.alpha("#ef4444", 0.4)
                                    Text {
                                        id: roText
                                        anchors.centerIn: parent
                                        text: qsTr("Read-Only")
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: "#fca5a5"
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
                    color: "#1e2436"
                }
            }

            // 2. Quick Filter Bar (Ctrl+S)
            Rectangle {
                visible: panelRoot.filterVisible || panelRoot.panelModel.filter.length > 0
                Layout.fillWidth: true
                height: 34
                color: "#131826"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: qsTr("Filter:")
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.accent
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
                    color: "#1e2436"
                }
            }

            // 3. Table Column Header (exact pixel match with ListView rows)
            Rectangle {
                visible: panelRoot.panelModel.viewMode === 0
                Layout.fillWidth: true
                height: 26
                color: "#121622"

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Name Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: nameHdrMouse.containsMouse ? "#1a2030" : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Name") + (panelRoot.panelModel.sortField === 0 ? (panelRoot.panelModel.sortAscending ? "  ↑" : "  ↓") : "")
                            color: panelRoot.panelModel.sortField === 0 ? theme.accent : "#7e879e"
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

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#1c2132" }

                    // Ext Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colExtWidth
                        Layout.fillHeight: true
                        color: extHdrMouse.containsMouse ? "#1a2030" : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Ext") + (panelRoot.panelModel.sortField === 1 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 1 ? theme.accent : "#7e879e"
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

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#1c2132" }

                    // Size Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colSizeWidth
                        Layout.fillHeight: true
                        color: sizeHdrMouse.containsMouse ? "#1a2030" : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: qsTr("Size") + (panelRoot.panelModel.sortField === 2 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 2 ? theme.accent : "#7e879e"
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

                    Rectangle { width: 1; Layout.fillHeight: true; color: "#1c2132" }

                    // Date Header
                    Rectangle {
                        Layout.preferredWidth: panelRoot.colDateWidth
                        Layout.fillHeight: true
                        color: dateHdrMouse.containsMouse ? "#1a2030" : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: qsTr("Modified") + (panelRoot.panelModel.sortField === 3 ? (panelRoot.panelModel.sortAscending ? " ↑" : " ↓") : "")
                            color: panelRoot.panelModel.sortField === 3 ? theme.accent : "#7e879e"
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
                    color: "#202638"
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
                    color: Qt.alpha(theme.accent, 0.22)
                    border.width: 1
                    border.color: theme.accent
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
                            color: vbar.pressed ? theme.accent : (vbar.hovered ? "#586380" : "#343c52")
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
                        border.color: theme.accent

                        color: {
                            if (isDropTargetDir)
                                return Qt.alpha(theme.accent, 0.28);
                            if (model.isSelected && isCurrent && panelRoot.isActive)
                                return Qt.alpha(theme.accent, 0.28);
                            if (model.isSelected)
                                return Qt.alpha(theme.accent, 0.17);
                            if (isCurrent && panelRoot.isActive)
                                return "#1c2236";
                            if (isCurrent)
                                return "#141826";
                            if (rowMouse.containsMouse)
                                return "#151928";
                            return index % 2 === 0 ? "transparent" : "#0e111a";
                        }

                        // Crisp left cursor / selection accent bar instead of a noisy 4-sided box
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: (rowDelegate.isCurrent && panelRoot.isActive) ? 3 : (model.isSelected ? 2 : 0)
                            visible: width > 0
                            color: theme.accent
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
                                if (model.isDir)
                                    panelRoot.panelModel.cd(model.name);
                                else
                                    backend.openItem(model.path);
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
                                            if (model.isSelected) return theme.accent;
                                            if (model.isParent) return "#8b95ab";
                                            if (model.isDir) return "#f1f5f9";
                                            return "#cbd5e1";
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
                                            if (s === "modified") return "#451a03";
                                            if (s === "untracked") return "#064e3b";
                                            if (s === "staged") return "#083344";
                                            if (s === "deleted") return "#450a0a";
                                            return "#1e293b";
                                        }
                                        border.width: 1
                                        border.color: {
                                            var s = model.gitStatus;
                                            if (s === "modified") return "#f59e0b";
                                            if (s === "untracked") return "#10b981";
                                            if (s === "staged") return "#06b6d4";
                                            if (s === "deleted") return "#ef4444";
                                            return "#64748b";
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
                                                if (s === "modified") return "#fcd34d";
                                                if (s === "untracked") return "#6ee7b7";
                                                if (s === "staged") return "#67e8f9";
                                                if (s === "deleted") return "#fca5a5";
                                                return "#cbd5e1";
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: "#151926" }

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
                                    color: model.isSelected ? theme.accent : "#737d96"
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: "#151926" }

                            // Size Cell
                            Item {
                                Layout.preferredWidth: panelRoot.colSizeWidth
                                Layout.fillHeight: true

                                readonly property bool isPlaceholderTag: model.formattedSize === "<DIR>" || model.formattedSize === "<UP>"

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    text: model.formattedSize === "<DIR>" ? qsTr("DIR")
                                        : model.formattedSize === "<UP>" ? qsTr("UP")
                                        : model.formattedSize
                                    font.pixelSize: parent.isPlaceholderTag ? 10 : 11
                                    font.family: "monospace"
                                    font.weight: (model.isDir && !parent.isPlaceholderTag) ? Font.DemiBold : Font.Normal
                                    color: {
                                        if (model.isSelected) return theme.accent;
                                        if (parent.isPlaceholderTag) return "#566079";
                                        if (model.isDir) return "#e2e8f0";
                                        return "#94a0b8";
                                    }
                                }
                            }

                            Rectangle { width: 1; Layout.fillHeight: true; color: "#151926" }

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
                                    color: model.isSelected ? Qt.alpha(theme.accent, 0.85) : "#68728a"
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
                            color: gridVbar.pressed ? theme.accent : (gridVbar.hovered ? "#586380" : "#343c52")
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
                        border.color: isDropTargetDir ? theme.accent
                                    : (isCurrent && panelRoot.isActive ? theme.accent
                                    : (model.isSelected ? Qt.alpha(theme.accent, 0.6) : "transparent"))

                        color: {
                            if (isDropTargetDir) return Qt.alpha(theme.accent, 0.28);
                            if (model.isSelected && isCurrent && panelRoot.isActive) return Qt.alpha(theme.accent, 0.28);
                            if (model.isSelected) return Qt.alpha(theme.accent, 0.17);
                            if (isCurrent && panelRoot.isActive) return "#1c2236";
                            if (gridItemMouse.containsMouse) return "#151928";
                            return "#0f121b";
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
                                if (model.isDir)
                                    panelRoot.panelModel.cd(model.name);
                                else
                                    backend.openItem(model.path);
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
                                        if (s === "modified") return "#451a03";
                                        if (s === "untracked") return "#064e3b";
                                        if (s === "staged") return "#083344";
                                        if (s === "deleted") return "#450a0a";
                                        return "#1e293b";
                                    }
                                    border.width: 1
                                    border.color: {
                                        var s = model.gitStatus;
                                        if (s === "modified") return "#f59e0b";
                                        if (s === "untracked") return "#10b981";
                                        if (s === "staged") return "#06b6d4";
                                        if (s === "deleted") return "#ef4444";
                                        return "#64748b";
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
                                            if (s === "modified") return "#fcd34d";
                                            if (s === "untracked") return "#6ee7b7";
                                            if (s === "staged") return "#67e8f9";
                                            if (s === "deleted") return "#fca5a5";
                                            return "#cbd5e1";
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
                                    if (model.isSelected) return theme.accent;
                                    if (model.isParent) return "#8b95ab";
                                    if (model.isDir) return "#f1f5f9";
                                    return "#cbd5e1";
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
                    color: Qt.alpha(theme.accent, 0.05)
                    border.width: 2
                    border.color: theme.accent

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        height: 26
                        width: dropHintLabel.implicitWidth + 20
                        radius: win.smallRadius
                        color: "#151a2a"
                        border.width: 1
                        border.color: theme.accent

                        Text {
                            id: dropHintLabel
                            anchors.centerIn: parent
                            text: panelDropArea.shiftHeld
                                  ? qsTr("Drop to Move here")
                                  : qsTr("Drop to Copy here (Shift = Move)")
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.accent
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
                color: "#111520"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#1e2436"
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
                        color: Qt.alpha(theme.accent, 0.18)

                        Text {
                            id: selBadgeText
                            anchors.centerIn: parent
                            text: qsTr("%1 selected (%2)")
                                  .arg(panelRoot.panelModel.selectedCount)
                                  .arg(panelRoot.panelModel.totalSelectedSizeFormatted)
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: theme.accent
                        }
                    }

                    Text {
                        text: qsTr("%1 items").arg(panelRoot.panelModel.itemCount)
                        font.pixelSize: 11
                        color: "#7c859c"
                    }

                    Rectangle {
                        visible: panelRoot.panelModel.isGitRepo
                        implicitHeight: 18
                        implicitWidth: gitRow.implicitWidth + 10
                        radius: Math.min(3, theme.radius)
                        color: "#161d2d"
                        border.width: 1
                        border.color: "#2a344a"

                        RowLayout {
                            id: gitRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: " " + (panelRoot.panelModel.gitBranch || "HEAD")
                                font.pixelSize: 11
                                font.family: "monospace"
                                font.bold: true
                                color: "#60a5fa"
                            }

                            Text {
                                visible: panelRoot.panelModel.gitModifiedCount > 0
                                text: "±" + panelRoot.panelModel.gitModifiedCount
                                font.pixelSize: 10
                                font.family: "monospace"
                                font.bold: true
                                color: "#f59e0b"
                            }

                            Text {
                                visible: panelRoot.panelModel.gitUntrackedCount > 0
                                text: "?" + panelRoot.panelModel.gitUntrackedCount
                                font.pixelSize: 10
                                font.family: "monospace"
                                font.bold: true
                                color: "#10b981"
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: fileList.currentItem && fileList.currentItem.itemPermissions.length > 0
                        text: fileList.currentItem ? fileList.currentItem.itemPermissions : ""
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#5f6880"
                    }

                    Text {
                        visible: fileList.currentItem && fileList.currentItem.itemPermissions.length > 0
                        text: "·"
                        font.pixelSize: 11
                        color: "#434b61"
                    }

                    Text {
                        text: qsTr("Free: %1").arg(panelRoot.panelModel.freeSpaceFormatted)
                        font.pixelSize: 11
                        color: "#8b95ab"
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
            renameOldName = name;
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
        mrFindField.text = "";
        mrReplaceField.text = "";
        mrPrefixField.text = "";
        mrSuffixField.text = "";
        mrCaseCombo.currentIndex = 0;
        mrCounterCheck.checked = false;
        refreshMultiRenamePreview();
        multiRenameOpen = true;
        mrFindField.forceFieldFocus();
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

    // ================= GLOBAL SHORTCUTS =================

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
    Shortcut { sequences: ["Alt+Return", "Alt+Enter"]; context: Qt.ApplicationShortcut; onActivated: triggerProperties() }

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
    Shortcut { sequence: "Alt+F7"; context: Qt.ApplicationShortcut; onActivated: {
        searchInput.text = "";
        searchResults = [];
        searchOpen = true;
        searchInput.forceFieldFocus();
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

    // View Modes (Ctrl+1 / Ctrl+2)
    Shortcut { sequence: "Ctrl+1"; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(0) }
    Shortcut { sequence: "Ctrl+2"; context: Qt.ApplicationShortcut; onActivated: currentModel().setViewMode(1) }

    // Menu Bar Access Shortcuts (Alt+F, Alt+E, Alt+V, Alt+C, Alt+H)
    Shortcut { sequence: "Alt+F"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); filesMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+E"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); editMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+V"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); viewMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+C"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); commandsMenu.open(); win.menuBarActive = true; } }
    Shortcut { sequence: "Alt+H"; enabled: !win.isTextInputFocused(); context: Qt.ApplicationShortcut; onActivated: { win.closeAllMenus(); helpMenu.open(); win.menuBarActive = true; } }

    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: {
        if (win.isAnyMenuOpen()) { win.closeAllMenus(); return; }
        if (aboutOpen) { aboutOpen = false; return; }
        if (conflictDialog.visible) { conflictDialog.answer(4); return; }
        if (propertiesOpen) { propertiesOpen = false; return; }
        if (helpOpen) { helpOpen = false; return; }
        if (previewOpen) { previewOpen = false; return; }
        if (searchOpen) { searchOpen = false; return; }
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
                color: "#11141e"

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
                            color: "#f8fafc"
                        }
                    }

                    Rectangle { width: 1; height: 18; color: "#22283a" }

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
                                    text: qsTr("Find Files...")
                                    shortcutHint: "Alt+F7"
                                    onTriggered: {
                                        searchInput.text = "";
                                        searchResults = [];
                                        searchOpen = true;
                                        searchInput.forceFieldFocus();
                                    }
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
                            label: qsTr("Shortcuts")
                            shortcutHint: "?"
                            accentHighlight: true
                            tooltipText: qsTr("Keyboard Shortcuts (?)")
                            onClicked: win.helpOpen = true
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#1c2132"
                }
            }

            // Drives, Bookmarks & Panel Sync Strip
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: "#0e111a"

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
                                color: "#646e87"
                            }

                            Repeater {
                                model: backend.drives
                                delegate: Rectangle {
                                    readonly property bool isDevMounted: modelData.isMounted !== false
                                    implicitHeight: 22
                                    implicitWidth: driveRow.implicitWidth + (modelData.canUnmount ? 24 : 12)
                                    radius: win.smallRadius
                                    color: driveMouse.containsMouse ? "#1d2336" : (isDevMounted ? "#141824" : "#10131f")
                                    border.width: 1
                                    border.color: !isDevMounted ? "#333d59" : (currentModel().path === modelData.path ? Qt.alpha(theme.accent, 0.55) : "#21273a")

                                    RowLayout {
                                        id: driveRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        VectorIcon {
                                            width: 13
                                            height: 13
                                            kind: modelData.isRemovable ? "usb" : "drive"
                                            iconColor: !isDevMounted ? "#64748b" : (currentModel().path === modelData.path ? theme.accent : "#8b95ab")
                                        }

                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: isDevMounted ? "#dce3f2" : "#94a3b8"
                                        }

                                        Text {
                                            visible: (modelData.free || "").length > 0
                                            text: modelData.free
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            color: "#6b758f"
                                        }

                                        // Mount button for unmounted disks
                                        Rectangle {
                                            visible: !isDevMounted
                                            implicitHeight: 16
                                            implicitWidth: mntText.implicitWidth + 8
                                            radius: 2
                                            color: mntMouse.containsMouse ? theme.accent : "#1e293b"

                                            Text {
                                                id: mntText
                                                anchors.centerIn: parent
                                                text: qsTr("Mount")
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: mntMouse.containsMouse ? "#0f172a" : "#cbd5e1"
                                            }

                                            MouseArea {
                                                id: mntMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: backend.mountDevice(modelData.devPath)
                                            }
                                        }

                                        // Eject/unmount button for removable mounted volumes
                                        Rectangle {
                                            visible: isDevMounted && modelData.canUnmount
                                            implicitHeight: 16
                                            implicitWidth: 16
                                            radius: 2
                                            color: unmountMouse.containsMouse ? "#3b1e22" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "⏏"
                                                font.pixelSize: 10
                                                color: unmountMouse.containsMouse ? "#f87171" : "#94a3b8"
                                            }

                                            MouseArea {
                                                id: unmountMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: backend.unmountDevice(modelData.path)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: driveMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (isDevMounted) {
                                                currentModel().setPath(modelData.path);
                                                currentListView().forceActiveFocus();
                                            } else {
                                                backend.mountDevice(modelData.devPath);
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 14; color: "#22283a" }

                            Text {
                                text: qsTr("Bookmarks")
                                font.pixelSize: 11
                                font.bold: true
                                color: "#646e87"
                            }

                            Repeater {
                                model: backend.bookmarks
                                delegate: Rectangle {
                                    implicitHeight: 22
                                    implicitWidth: bmRow.implicitWidth + 12
                                    radius: win.smallRadius
                                    color: bmMouse.containsMouse ? "#1d2336" : "#141824"
                                    border.width: 1
                                    border.color: currentModel().path === modelData ? Qt.alpha(theme.accent, 0.65) : "#21273a"

                                    RowLayout {
                                        id: bmRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "★"
                                            font.pixelSize: 10
                                            color: theme.accent
                                        }

                                        Text {
                                            text: modelData === "/" ? "/" : modelData.split("/").pop()
                                            font.pixelSize: 11
                                            color: currentModel().path === modelData ? theme.accent : "#cbd5e1"
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
                                color: addBmMouse.containsMouse ? "#1d2336" : "transparent"
                                border.width: 1
                                border.color: "#252c40"

                                Text {
                                    id: addBmLabel
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

                                ToolTip.visible: addBmMouse.containsMouse
                                ToolTip.delay: 450
                                ToolTip.text: qsTr("Toggle bookmark for active folder")
                            }
                        }
                    }

                    Rectangle { width: 1; height: 14; color: "#22283a" }

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
                    color: "#191e2d"
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
                height: backend.isBusy ? 30 : (backend.statusMessage.length > 0 ? 26 : 0)
                visible: height > 0
                color: "#131724"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#1f2538"
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
                        color: theme.accent
                    }

                    Text {
                        text: backend.isBusy ? backend.busyTitle : backend.statusMessage
                        font.pixelSize: 11
                        font.weight: backend.isBusy ? Font.DemiBold : Font.Normal
                        color: backend.isBusy ? theme.accent : "#cbd5e1"
                        Layout.fillWidth: !backend.isBusy
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: backend.isBusy
                        text: backend.busyDetail
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#94a3b8"
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }

                    Text {
                        visible: backend.isBusy
                        text: Math.round(backend.busyProgress * 100) + "%"
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#cbd5e1"
                    }

                    // Slim custom progress track
                    Rectangle {
                        visible: backend.isBusy
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 6
                        radius: 3
                        color: "#22283a"

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, backend.busyProgress))
                            height: parent.height
                            radius: 3
                            color: theme.accent
                        }
                    }

                    ToolbarBtn {
                        visible: backend.isBusy && backend.canCancel
                        implicitHeight: 22
                        label: qsTr("Cancel")
                        accentHighlight: true
                        onClicked: backend.cancelOperation()
                    }
                }
            }

            // Mini Command Line Bar (Total Commander style)
            Rectangle {
                Layout.fillWidth: true
                height: 34
                color: "#0e111a"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#1a2030"
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
                        color: theme.accent
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
                color: "#0b0d14"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#1a2030"
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

    // Consistent opaque dark dialog shell matching the app's surface palette.
    component AppDialog : Dialog {
        id: dlg
        property bool showCloseButton: true
        anchors.centerIn: parent
        modal: true
        padding: 16
        topPadding: 14
        bottomPadding: 14

        Overlay.modal: Rectangle {
            color: Qt.rgba(0.02, 0.03, 0.06, 0.74)
        }

        background: Rectangle {
            color: "#111521"
            border.width: 1
            border.color: "#262f47"
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
                color: "#20273c"
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
                    color: "#f1f5f9"
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

        Component.onCompleted: {
            if (footer) {
                footer.background = Qt.createQmlObject(
                    'import QtQuick; Item { Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 1; anchors.rightMargin: 1; height: 1; color: "#20273c" } }',
                    footer
                );
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
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                Layout.preferredWidth: 480
                wrapMode: Text.Wrap
            }

            GridLayout {
                columns: 2
                columnSpacing: 12
                rowSpacing: 4

                Text { text: qsTr("New:"); color: "#8a92a6"; font.pixelSize: 12 }
                Text {
                    text: conflictDialog.info.sourcePath
                          ? backend.formatConflictDetails(conflictDialog.info.sourceSize,
                                                          conflictDialog.info.sourceModified,
                                                          conflictDialog.info.sourceIsDir)
                          : ""
                    color: "#ffffff"
                    font.pixelSize: 12
                }
                Text { text: qsTr("Existing:"); color: "#8a92a6"; font.pixelSize: 12 }
                Text {
                    text: conflictDialog.info.destPath
                          ? backend.formatConflictDetails(conflictDialog.info.destSize,
                                                          conflictDialog.info.destModified,
                                                          conflictDialog.info.destIsDir)
                          : ""
                    color: "#ffffff"
                    font.pixelSize: 12
                }
                Text { text: qsTr("In:"); color: "#8a92a6"; font.pixelSize: 12 }
                Text {
                    text: (conflictDialog.info.destPath || "").replace(/\/[^\/]*$/, "")
                    color: "#b0b8cb"
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
                color: "#e2e8f0"
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
                color: "#e2e8f0"
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
                color: "#e2e8f0"
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
                    color: "#94a3b8"
                    font.pixelSize: 12
                }
                Text {
                    text: currentModel().path
                    color: currentModel().isWritable ? theme.accent : "#f87171"
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
                color: Qt.alpha("#ef4444", 0.15)
                border.width: 1
                border.color: Qt.alpha("#ef4444", 0.4)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text { text: "⚠"; color: "#f87171"; font.pixelSize: 13 }
                    Text {
                        text: qsTr("This folder is read-only (Permission denied)")
                        color: "#fca5a5"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Text {
                text: qsTr("Folder name(s) (comma-separated for multiple):")
                color: "#e2e8f0"
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
                    color: Qt.alpha(theme.accent, 0.2)
                    border.width: 1
                    border.color: Qt.alpha(theme.accent, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        font.pixelSize: 10
                        font.bold: true
                        color: theme.accent
                    }
                }
                Text {
                    text: {
                        var count = newFolderInput.text.split(',').filter(function(s) { return s.trim().length > 0; }).length;
                        return qsTr("Will create %1 folders").arg(count);
                    }
                    font.pixelSize: 11
                    color: theme.accent
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
                color: "#e2e8f0"
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
                    color: "#94a3b8"
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
                    color: index % 2 === 0 ? "#141824" : "transparent"
                    radius: win.smallRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            text: "★"
                            font.pixelSize: 12
                            color: theme.accent
                        }

                        Text {
                            text: modelData
                            color: "#e2e8f0"
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

    // Multi-Rename Tool Dialog (Ctrl+M)
    AppDialog {
        id: multiRenameDialog
        visible: win.multiRenameOpen
        title: qsTr("Multi-Rename Tool (Ctrl+M)")
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
                CompactField {
                    id: mrFindField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Replace:"); color: "#b0b8cb"; font.pixelSize: 12 }
                CompactField {
                    id: mrReplaceField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Prefix:"); color: "#b0b8cb"; font.pixelSize: 12 }
                CompactField {
                    id: mrPrefixField
                    Layout.fillWidth: true
                    onTextChanged: refreshMultiRenamePreview()
                }

                Text { text: qsTr("Suffix:"); color: "#b0b8cb"; font.pixelSize: 12 }
                CompactField {
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
                height: 26
                color: "#151926"
                radius: win.smallRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
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
                    width: ListView.view.width
                    height: 26
                    color: index % 2 === 0 ? "#121520" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text {
                            text: modelData.oldName
                            color: "#9da5bc"
                            font.pixelSize: 12
                            font.family: "monospace"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                        Text {
                            text: "→  " + modelData.newName
                            color: theme.accent
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
    AppDialog {
        id: packDialog
        visible: win.packArchiveOpen
        title: qsTr("Pack Files into Archive (Alt+F5)")
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 10
            Text {
                text: qsTr("Create archive (.zip, .tar.gz, .tar.xz) from %1 item(s):").arg(getSelectedOrCurrentPaths().length)
                color: "#e2e8f0"
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
                color: "#d0d6e5"
                background: Rectangle { color: "#0d1018"; radius: win.smallRadius }
            }
        }

        onRejected: win.commandOutputOpen = false
    }

    // File Preview Modal (F3 View)
    AppDialog {
        id: previewDialog
        visible: win.previewOpen
        title: qsTr("Preview: %1").arg(previewData.name || "")
        width: 740
        height: 540
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: qsTr("Path: %1 | Size: %2 | Modified: %3").arg(previewData.path || "").arg(previewData.formattedSize || "").arg(previewData.modified || "")
                font.pixelSize: 11
                font.family: "monospace"
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
                    background: Rectangle { color: "#0d1018"; radius: win.smallRadius }
                }
            }
        }

        onRejected: win.previewOpen = false
    }

    // Alt+F7 Search Dialog
    AppDialog {
        id: searchDialog
        visible: win.searchOpen
        title: qsTr("Find Files (Alt+F7)")
        width: 650
        height: 480
        standardButtons: Dialog.Close

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                CompactField {
                    id: searchInput
                    placeholderText: qsTr("Type file name to search...")
                    Layout.fillWidth: true
                    onAccepted: {
                        win.searchResults = backend.searchFiles(currentModel().path, searchInput.text);
                    }
                    onEscaped: searchDialog.reject()
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
                    width: ListView.view.width
                    height: 28
                    color: index % 2 === 0 ? "#121520" : "transparent"
                    radius: win.smallRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        Text {
                            text: modelData
                            color: "#c8cedd"
                            font.pixelSize: 12
                            font.family: "monospace"
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                        ToolbarBtn {
                            implicitHeight: 22
                            label: qsTr("Open")
                            accentHighlight: true
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
                color: "#151a28"
                border.width: 1
                border.color: "#22293e"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    VectorIcon {
                        width: 20
                        height: 20
                        kind: win.propData.isDir ? "folder" : "file"
                        iconColor: win.propData.isDir ? "#eab308" : theme.accent
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
                                color: "#f8fafc"
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            Rectangle {
                                visible: win.propData.isSymLink === true || win.propData.isDir === true
                                implicitHeight: 18
                                implicitWidth: kindTag.implicitWidth + 10
                                radius: Math.min(3, theme.radius)
                                color: Qt.alpha(theme.accent, 0.16)

                                Text {
                                    id: kindTag
                                    anchors.centerIn: parent
                                    text: win.propData.isSymLink ? qsTr("SYMLINK") : qsTr("FOLDER")
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: "monospace"
                                    color: theme.accent
                                }
                            }
                        }

                        Text {
                            text: win.propData.path || ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: "#8b95ab"
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

                Text { text: qsTr("MIME Type:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: (win.propData.mimeComment || "")
                          + ((win.propData.mimeName || "").length > 0 ? "  (" + win.propData.mimeName + ")" : "")
                    color: "#e2e8f0"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: win.propData.isSymLink === true
                    text: qsTr("Link Target:")
                    color: "#8a93a8"
                    font.pixelSize: 12
                }
                Text {
                    visible: win.propData.isSymLink === true
                    text: win.propData.symLinkTarget || ""
                    color: theme.accent
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                Text { text: qsTr("Size:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: (win.propData.formattedSize || "")
                          + ((win.propData.itemCounts || "").length > 0 ? "  —  " + win.propData.itemCounts : "")
                    color: "#e2e8f0"
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text { text: qsTr("Owner / Group:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: (win.propData.owner || "") + " : " + (win.propData.group || "")
                    color: "#e2e8f0"
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text { text: qsTr("Modified:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: win.propData.modified || "—"
                    color: "#cbd5e1"
                    font.pixelSize: 12
                    font.family: "monospace"
                }

                Text { text: qsTr("Created:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: win.propData.created || "—"
                    color: "#cbd5e1"
                    font.pixelSize: 12
                    font.family: "monospace"
                }

                Text { text: qsTr("Accessed:"); color: "#8a93a8"; font.pixelSize: 12 }
                Text {
                    text: win.propData.accessed || "—"
                    color: "#cbd5e1"
                    font.pixelSize: 12
                    font.family: "monospace"
                }
            }

            // Editable Permissions (chmod) Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: chmodCol.implicitHeight + 22
                radius: win.smallRadius
                color: "#0d1018"
                border.width: 1
                border.color: "#20273c"

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
                            color: "#f1f5f9"
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitHeight: 24
                            implicitWidth: symLabel.implicitWidth + 14
                            radius: win.smallRadius
                            color: "#151a28"
                            border.width: 1
                            border.color: "#242c42"

                            Text {
                                id: symLabel
                                anchors.centerIn: parent
                                text: backend.formatSymbolicPermissions(win.propMode)
                                font.pixelSize: 12
                                font.family: "monospace"
                                font.bold: true
                                color: theme.accent
                            }
                        }

                        Text {
                            text: qsTr("Octal:")
                            font.pixelSize: 11
                            color: "#8a93a8"
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

                        Text { text: qsTr("Owner"); color: "#b8c1d4"; font.pixelSize: 12; Layout.preferredWidth: 70 }
                        PermBitBtn { label: qsTr("Read (r)"); bitMask: 256 }
                        PermBitBtn { label: qsTr("Write (w)"); bitMask: 128 }
                        PermBitBtn { label: qsTr("Exec (x)"); bitMask: 64 }

                        Text { text: qsTr("Group"); color: "#b8c1d4"; font.pixelSize: 12; Layout.preferredWidth: 70 }
                        PermBitBtn { label: qsTr("Read (r)"); bitMask: 32 }
                        PermBitBtn { label: qsTr("Write (w)"); bitMask: 16 }
                        PermBitBtn { label: qsTr("Exec (x)"); bitMask: 8 }

                        Text { text: qsTr("Others"); color: "#b8c1d4"; font.pixelSize: 12; Layout.preferredWidth: 70 }
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
                    color: "#94a3b8"
                    font.pixelSize: 12
                }
                Text {
                    text: currentModel().path
                    color: currentModel().isWritable ? theme.accent : "#f87171"
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
                color: Qt.alpha("#ef4444", 0.15)
                border.width: 1
                border.color: Qt.alpha("#ef4444", 0.4)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text { text: "⚠"; color: "#f87171"; font.pixelSize: 13 }
                    Text {
                        text: qsTr("This folder is read-only (Permission denied)")
                        color: "#fca5a5"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Text {
                text: qsTr("Enter file name(s) (comma-separated for multiple):")
                color: "#e2e8f0"
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
                    color: Qt.alpha(theme.accent, 0.2)
                    border.width: 1
                    border.color: Qt.alpha(theme.accent, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        font.pixelSize: 10
                        font.bold: true
                        color: theme.accent
                    }
                }
                Text {
                    text: {
                        var count = newFileNameInput.text.split(',').filter(function(s) { return s.trim().length > 0; }).length;
                        return qsTr("Will create %1 files").arg(count);
                    }
                    font.pixelSize: 11
                    color: theme.accent
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
                color: "#f8fafc"
                font.bold: true
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }

            Text {
                text: qsTr("Destination directory:")
                color: "#94a3b8"
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
                color: "#94a3b8"
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
                color: "#e2e8f0"
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
                Text { text: qsTr("Presets:"); font.pixelSize: 11; color: "#64748b" }
                Repeater {
                    model: ["*.*", "*.txt; *.md", "*.png; *.jpg", "*.tar.gz; *.zip", "*.cpp; *.h"]
                    delegate: Rectangle {
                        implicitHeight: 20
                        implicitWidth: presetText.implicitWidth + 8
                        radius: win.smallRadius
                        color: presetMouse.containsMouse ? "#1e293b" : "#131826"
                        border.width: 1
                        border.color: "#27324b"

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: "#94a3b8"
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
                VectorIcon { kind: "binary"; width: 20; height: 20; iconColor: theme.accent }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: backend.fileName(checksumDialog.filePath)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#f8fafc"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    Text {
                        text: checksumDialog.filePath
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#64748b"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

            // Computed Hashes
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 8
                rowSpacing: 6

                Text { text: "MD5:"; font.bold: true; font.family: "monospace"; color: "#94a3b8" }
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
                    color: copyMd5Mouse.containsMouse ? "#2a344d" : "#1c2336"
                    border.width: 1
                    border.color: "#2c3854"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: "#e2e8f0"
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

                Text { text: "SHA1:"; font.bold: true; font.family: "monospace"; color: "#94a3b8" }
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
                    color: copySha1Mouse.containsMouse ? "#2a344d" : "#1c2336"
                    border.width: 1
                    border.color: "#2c3854"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: "#e2e8f0"
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

                Text { text: "SHA256:"; font.bold: true; font.family: "monospace"; color: "#94a3b8" }
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
                    color: copySha256Mouse.containsMouse ? "#2a344d" : "#1c2336"
                    border.width: 1
                    border.color: "#2c3854"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        font.pixelSize: 11
                        font.bold: true
                        color: "#e2e8f0"
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

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

            // Verify live against entered hash
            Text {
                text: qsTr("Verify against hash:")
                font.bold: true
                font.pixelSize: 11
                color: "#cbd5e1"
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
                color: checksumDialog.verificationOk ? "#22c55e" : "#ef4444"
            }

            // Save .sha256 / .md5 button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitHeight: 30
                    implicitWidth: saveShaText.implicitWidth + 24
                    radius: win.smallRadius
                    color: saveShaMouse.containsMouse ? theme.accent : "#1c2336"
                    border.width: 1
                    border.color: saveShaMouse.containsMouse ? theme.accent : "#2c3854"

                    Text {
                        id: saveShaText
                        anchors.centerIn: parent
                        text: qsTr("Save .sha256 File")
                        font.pixelSize: 11
                        font.bold: true
                        color: saveShaMouse.containsMouse ? "#0f172a" : "#f1f5f9"
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
                    color: saveMd5Mouse.containsMouse ? theme.accent : "#1c2336"
                    border.width: 1
                    border.color: saveMd5Mouse.containsMouse ? theme.accent : "#2c3854"

                    Text {
                        id: saveMd5Text
                        anchors.centerIn: parent
                        text: qsTr("Save .md5 File")
                        font.pixelSize: 11
                        font.bold: true
                        color: saveMd5Mouse.containsMouse ? "#0f172a" : "#f1f5f9"
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
                    color: verifyFileMouse.containsMouse ? theme.accent : "#1c2336"
                    border.width: 1
                    border.color: verifyFileMouse.containsMouse ? theme.accent : "#2c3854"

                    Text {
                        id: verifyFileText
                        anchors.centerIn: parent
                        text: qsTr("Verify Checksum File")
                        font.pixelSize: 11
                        font.bold: true
                        color: verifyFileMouse.containsMouse ? "#0f172a" : "#f1f5f9"
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
                color: "#161b2b"
                border.width: 1
                border.color: "#252e46"

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
                        color: diffDialog.diffData.isIdentical ? "#22c55e" : "#f59e0b"
                    }

                    Rectangle { width: 1; height: 16; color: "#252e46" }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("+%1 added").arg(diffDialog.diffData.added || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#4ade80"
                    }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("-%1 deleted").arg(diffDialog.diffData.deleted || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#f87171"
                    }

                    Text {
                        visible: !diffDialog.diffData.isIdentical
                        text: qsTr("~%1 modified").arg(diffDialog.diffData.modified || 0)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#fbbf24"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: backend.fileName(diffDialog.path1) + "  ↔  " + backend.fileName(diffDialog.path2)
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: "#94a3b8"
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Binary difference notice
            Rectangle {
                visible: diffDialog.diffData.isBinary === true
                Layout.fillWidth: true
                height: 40
                color: "#291b1f"
                radius: win.smallRadius
                Text {
                    anchors.centerIn: parent
                    text: qsTr("Binary files differ (visual diff not supported for binaries).")
                    color: "#fca5a5"
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
                        if (t === "added") return "#13311f";
                        if (t === "deleted") return "#361618";
                        if (t === "modified") return "#32230b";
                        return index % 2 === 0 ? "transparent" : "#0d1017";
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
                            color: "#64748b"
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
                                if (t === "deleted") return "#fca5a5";
                                if (t === "modified") return "#fde68a";
                                return "#cbd5e1";
                            }
                        }

                        Rectangle { width: 1; Layout.fillHeight: true; color: "#1f273b" }

                        // Right line number
                        Text {
                            Layout.preferredWidth: 36
                            text: modelData.line2 > 0 ? modelData.line2 : ""
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: "#64748b"
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
                                if (t === "added") return "#86efac";
                                if (t === "modified") return "#fde68a";
                                return "#cbd5e1";
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
                        { key: "Tab", desc: qsTr("Switch active panel (Left / Right)") },
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
                        color: index % 2 === 0 ? "#141824" : "transparent"
                        radius: win.smallRadius

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                color: "#1d2336"
                                border.width: 1
                                border.color: "#29314a"
                                radius: win.smallRadius
                                implicitWidth: 160
                                implicitHeight: 22

                                Text {
                                    text: modelData.key
                                    font.bold: true
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    color: theme.accent
                                }
                            }

                            Text {
                                text: modelData.desc
                                font.pixelSize: 12
                                color: "#d0d4e2"
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
                            color: "#f8fafc"
                        }
                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: vText.implicitWidth + 8
                            radius: 3
                            color: Qt.alpha(theme.accent, 0.2)
                            border.width: 1
                            border.color: Qt.alpha(theme.accent, 0.4)
                            Text {
                                id: vText
                                anchors.centerIn: parent
                                text: "v1.0"
                                font.pixelSize: 10
                                font.bold: true
                                color: theme.accent
                            }
                        }
                    }

                    Text {
                        text: qsTr("Total Commander for Linux & Omarchy")
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#21283d"
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                lineHeight: 1.4
                color: "#cbd5e1"
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
}
