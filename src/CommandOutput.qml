import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool drawerOpen: false
    property var themeColors: ({})
    property int smallRadius: 6
    property var commandLogModel: null
    property bool commandRunning: false
    property string commandRunningText: ""
    readonly property int commandCount: commandLogModel ? commandLogModel.count : 0

    signal stopRequested()
    signal copyTextRequested(string text, string statusMsg)
    signal clearRequested()
    signal closeRequested()
    signal rerunRequested(string command)

    function col(key, fallback) {
        return (themeColors && themeColors[key] !== undefined) ? themeColors[key] : fallback;
    }

    visible: Layout.preferredHeight > 0
    Layout.fillWidth: true
    Layout.preferredHeight: drawerOpen ? 204 : 0
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight
    clip: true
    color: col("inputBg", "#09090c")

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.col("borderDefault", "#262632")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Drawer Header Bar
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: root.col("subBarBg", "#0d0d10")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: root.commandRunning
                          ? qsTr("Running: %1").arg(root.commandRunningText)
                          : (root.commandCount > 0
                             ? qsTr("Command Output (%1)").arg(root.commandCount)
                             : qsTr("Command Output"))
                    font.pixelSize: 11
                    font.bold: true
                    color: root.commandRunning
                           ? root.col("accent", "#3b82f6")
                           : root.col("textSecondary", "#d4d4dc")
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Stop Button
                Rectangle {
                    visible: root.commandRunning
                    implicitHeight: 20
                    implicitWidth: stopLbl.implicitWidth + 14
                    radius: root.smallRadius
                    color: stopMouse.containsMouse ? Qt.alpha(root.col("dangerAccent", "#f87171"), 0.22) : root.col("chipBg", "#16161c")
                    border.width: 1
                    border.color: root.col("dangerAccent", "#f87171")

                    Text {
                        id: stopLbl
                        anchors.centerIn: parent
                        text: qsTr("Stop")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: root.col("dangerText", "#fca5a5")
                    }

                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stopRequested()
                    }
                }

                // Copy All Button
                Rectangle {
                    implicitHeight: 20
                    implicitWidth: copyAllLbl.implicitWidth + 14
                    radius: root.smallRadius
                    opacity: root.commandCount > 0 ? 1.0 : 0.38
                    color: copyAllMouse.containsMouse && root.commandCount > 0 ? root.col("btnHoverBg", "#22222b") : "transparent"

                    Text {
                        id: copyAllLbl
                        anchors.centerIn: parent
                        text: qsTr("Copy All")
                        font.pixelSize: 11
                        color: root.col("textSecondary", "#d4d4dc")
                    }

                    MouseArea {
                        id: copyAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.commandCount > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.commandLogModel)
                                root.copyTextRequested(root.commandLogModel.formatAllForCopy(),
                                                       qsTr("Command output copied to clipboard."));
                        }
                    }
                }

                // Clear Button
                Rectangle {
                    implicitHeight: 20
                    implicitWidth: clearLbl.implicitWidth + 14
                    radius: root.smallRadius
                    opacity: root.commandCount > 0 ? 1.0 : 0.38
                    color: clearMouse.containsMouse && root.commandCount > 0 ? root.col("btnHoverBg", "#22222b") : "transparent"

                    Text {
                        id: clearLbl
                        anchors.centerIn: parent
                        text: qsTr("Clear")
                        font.pixelSize: 11
                        color: root.col("textSecondary", "#d4d4dc")
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.commandCount > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearRequested()
                    }
                }

                // Close Button
                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: root.smallRadius
                    color: closeMouse.containsMouse ? root.col("btnHoverBg", "#22222b") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 11
                        font.bold: true
                        color: closeMouse.containsMouse ? root.col("textPrimary", "#f4f4f6") : root.col("textMuted", "#9494a3")
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }

                    ToolTip.visible: closeMouse.containsMouse
                    ToolTip.delay: 400
                    ToolTip.text: qsTr("Hide output drawer (Ctrl+O / Esc)")
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: root.col("borderSubtle", "#1c1c24")
            }
        }

        // Grouped Per-Command Cards
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.commandCount === 0
                text: qsTr("No command output yet. Type a command below (Up/Down for history, Ctrl+Enter to insert filename).")
                font.family: "monospace"
                font.pixelSize: 11
                color: root.col("textDim", "#6c6c7c")
            }

            ListView {
                id: cmdLogList
                objectName: "commandLogList"
                anchors.fill: parent
                anchors.margins: 6
                visible: root.commandCount > 0
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: root.commandLogModel

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                onCountChanged: {
                    Qt.callLater(function() {
                        if (cmdLogList.count > 0)
                            cmdLogList.positionViewAtEnd();
                    });
                }

                delegate: Rectangle {
                    id: cmdCard
                    width: ListView.view ? ListView.view.width - 8 : 400
                    implicitHeight: cardCol.implicitHeight + 10
                    height: implicitHeight
                    radius: root.smallRadius
                    color: root.col("cardBg", "#18181f")
                    border.width: 1
                    border.color: model.running
                                  ? root.col("accent", "#3b82f6")
                                  : (model.exitCode !== 0 && !model.cancelled
                                     ? Qt.alpha(root.col("dangerAccent", "#f87171"), 0.55)
                                     : root.col("borderSubtle", "#1c1c24"))

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        // Command Header: cwd + ❯ + command + status + copy + rerun
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: Math.min(200, cwdTxt.implicitWidth + 10)
                                radius: 3
                                color: root.col("badgeBg", "#1b1b23")
                                border.width: 1
                                border.color: root.col("borderDefault", "#262632")

                                Text {
                                    id: cwdTxt
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    text: model.cwd || ""
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                    color: root.col("accent", "#3b82f6")
                                    elide: Text.ElideLeft
                                }
                            }

                            Text {
                                text: "❯"
                                font.family: "monospace"
                                font.bold: true
                                font.pixelSize: 11
                                color: root.col("accent", "#3b82f6")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.command || ""
                                font.family: "monospace"
                                font.bold: true
                                font.pixelSize: 11
                                color: root.col("textPrimary", "#f4f4f6")
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: (model.timestamp || "").length > 0
                                text: model.timestamp || ""
                                font.family: "monospace"
                                font.pixelSize: 9
                                color: root.col("textDim", "#6c6c7c")
                            }

                            // Status Badge
                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: statusTxt.implicitWidth + 10
                                radius: 3
                                color: model.running
                                       ? Qt.alpha(root.col("accent", "#3b82f6"), 0.18)
                                       : (model.cancelled
                                          ? Qt.alpha(root.col("warningText", "#f59e0b"), 0.18)
                                          : (model.exitCode === 0
                                             ? Qt.alpha(root.col("successText", "#22c55e"), 0.16)
                                             : Qt.alpha(root.col("dangerAccent", "#f87171"), 0.2)))

                                Text {
                                    id: statusTxt
                                    anchors.centerIn: parent
                                    text: model.running
                                          ? qsTr("running")
                                          : (model.cancelled ? qsTr("cancelled") : ("exit " + model.exitCode))
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: model.running
                                           ? root.col("accent", "#3b82f6")
                                           : (model.cancelled
                                              ? root.col("warningText", "#f59e0b")
                                              : (model.exitCode === 0
                                                 ? root.col("successText", "#22c55e")
                                                 : root.col("dangerText", "#fca5a5")))
                                }
                            }

                            // Per-command Copy
                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: cpyLbl.implicitWidth + 10
                                radius: 3
                                color: cpyMouse.containsMouse ? root.col("btnHoverBg", "#22222b") : root.col("chipBg", "#16161c")
                                border.width: 1
                                border.color: root.col("borderDefault", "#262632")

                                Text {
                                    id: cpyLbl
                                    anchors.centerIn: parent
                                    text: qsTr("Copy")
                                    font.pixelSize: 10
                                    color: root.col("textSecondary", "#d4d4dc")
                                }

                                MouseArea {
                                    id: cpyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.commandLogModel)
                                            root.copyTextRequested(root.commandLogModel.formatEntryForCopy(index),
                                                                   qsTr("Command block copied to clipboard."));
                                    }
                                }
                            }

                            // Re-run command
                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: rerunLbl.implicitWidth + 10
                                radius: 3
                                opacity: root.commandRunning ? 0.35 : 1.0
                                color: rerunMouse.containsMouse && !root.commandRunning ? root.col("btnHoverBg", "#22222b") : root.col("chipBg", "#16161c")
                                border.width: 1
                                border.color: root.col("borderDefault", "#262632")

                                Text {
                                    id: rerunLbl
                                    anchors.centerIn: parent
                                    text: qsTr("Re-run")
                                    font.pixelSize: 10
                                    color: root.col("accent", "#3b82f6")
                                }

                                MouseArea {
                                    id: rerunMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !root.commandRunning
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.rerunRequested(model.command)
                                }
                            }
                        }

                        // Output body immediately below command
                        TextEdit {
                            visible: (model.output || "").trim().length > 0
                            Layout.fillWidth: true
                            text: (model.output || "").replace(/\s+$/, "")
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            font.pixelSize: 11
                            color: model.exitCode !== 0 && !model.running && !model.cancelled
                                   ? root.col("dangerText", "#fca5a5")
                                   : root.col("textSecondary", "#d4d4dc")
                            selectionColor: Qt.alpha(root.col("accent", "#3b82f6"), 0.35)
                            selectedTextColor: root.col("textOnHover", "#ffffff")
                        }
                    }
                }
            }
        }
    }
}
