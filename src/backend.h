#pragma once

#include <QDateTime>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include <atomic>
#include <functional>
#include <memory>

#include "fileoperation.h"
#include "panelmodel.h"

class QMimeData;
class QProcess;
class QTemporaryDir;
class QThread;

struct UndoPair {
    QString fromPath;
    QString toPath;
    QString trashInfoPath;
};

struct UndoEntry {
    enum Type { Rename, Move, Trash };
    Type type;
    QString description;
    QList<UndoPair> pairs;
};

struct QueuedFileOperation {
    int id = 0;
    FileOperation::Mode mode = FileOperation::Copy;
    QStringList sourcePaths;
    QString targetDir;
    QString title;
};

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(PanelModel* leftPanel READ leftPanel CONSTANT)
    Q_PROPERTY(PanelModel* rightPanel READ rightPanel CONSTANT)
    Q_PROPERTY(int activePanel READ activePanel WRITE setActivePanel NOTIFY activePanelChanged)
    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowSizeChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowSizeChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QString busyTitle READ busyTitle NOTIFY busyChanged)
    Q_PROPERTY(double busyProgress READ busyProgress NOTIFY busyChanged)
    Q_PROPERTY(QString busyDetail READ busyDetail NOTIFY busyChanged)
    Q_PROPERTY(bool canCancel READ canCancel NOTIFY busyChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY busyChanged)
    Q_PROPERTY(QString busySpeed READ busySpeed NOTIFY busyChanged)
    Q_PROPERTY(qint64 busySpeedBytes READ busySpeedBytes NOTIFY busyChanged)
    Q_PROPERTY(QString busyEta READ busyEta NOTIFY busyChanged)
    Q_PROPERTY(qint64 busyDoneBytes READ busyDoneBytes NOTIFY busyChanged)
    Q_PROPERTY(qint64 busyTotalBytes READ busyTotalBytes NOTIFY busyChanged)
    Q_PROPERTY(int queueCount READ queueCount NOTIFY operationQueueChanged)
    Q_PROPERTY(QVariantList operationQueue READ operationQueue NOTIFY operationQueueChanged)
    Q_PROPERTY(QVariantList multiRenamePresets READ multiRenamePresets NOTIFY multiRenamePresetsChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantList drives READ drives NOTIFY drivesChanged)
    Q_PROPERTY(QStringList bookmarks READ bookmarks NOTIFY bookmarksChanged)
    Q_PROPERTY(QStringList clipboardPaths READ clipboardPaths NOTIFY clipboardChanged)
    Q_PROPERTY(bool clipboardIsCut READ clipboardIsCut NOTIFY clipboardChanged)
    Q_PROPERTY(bool canPaste READ canPaste NOTIFY clipboardChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY undoChanged)
    Q_PROPERTY(QString undoDescription READ undoDescription NOTIFY undoChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(bool isDarkTheme READ isDarkTheme NOTIFY themeModeChanged)
    Q_PROPERTY(QStringList recentDirectories READ recentDirectories NOTIFY recentDirectoriesChanged)
    Q_PROPERTY(bool searchRunning READ searchRunning NOTIFY searchStateChanged)
    Q_PROPERTY(int searchScannedCount READ searchScannedCount NOTIFY searchProgressChanged)
    Q_PROPERTY(QVariantList searchResultItems READ searchResultItems NOTIFY searchResultsChanged)
    Q_PROPERTY(QVariantList remoteConnections READ remoteConnections NOTIFY remoteConnectionsChanged)
    Q_PROPERTY(bool rcloneAvailable READ rcloneAvailable NOTIFY rcloneRemotesChanged)
    Q_PROPERTY(QVariantList rcloneRemotes READ rcloneRemotes NOTIFY rcloneRemotesChanged)
    Q_PROPERTY(bool gdriveAuthRunning READ gdriveAuthRunning NOTIFY gdriveAuthChanged)
    Q_PROPERTY(QString gdriveAuthStatus READ gdriveAuthStatus NOTIFY gdriveAuthChanged)
    Q_PROPERTY(QString gdriveAuthUrl READ gdriveAuthUrl NOTIFY gdriveAuthChanged)
    Q_PROPERTY(QVariantList customActions READ customActions NOTIFY customActionsChanged)
    Q_PROPERTY(bool duplicateScanRunning READ duplicateScanRunning NOTIFY duplicateScanStateChanged)
    Q_PROPERTY(int duplicateScanScannedCount READ duplicateScanScannedCount NOTIFY duplicateScanProgressChanged)
    Q_PROPERTY(QString duplicateScanDetail READ duplicateScanDetail NOTIFY duplicateScanProgressChanged)
    Q_PROPERTY(QVariantList duplicateResults READ duplicateResults NOTIFY duplicateResultsChanged)
    Q_PROPERTY(bool syncRunning READ syncRunning NOTIFY syncStateChanged)
    Q_PROPERTY(double syncProgress READ syncProgress NOTIFY syncProgressChanged)
    Q_PROPERTY(QString syncDetail READ syncDetail NOTIFY syncProgressChanged)
    Q_PROPERTY(QVariantList syncCompareResults READ syncCompareResults NOTIFY syncCompareResultsChanged)
    Q_PROPERTY(bool checksumRunning READ checksumRunning NOTIFY checksumStateChanged)
    Q_PROPERTY(double checksumProgress READ checksumProgress NOTIFY checksumProgressChanged)
    Q_PROPERTY(QVariantMap checksumResult READ checksumResult NOTIFY checksumResultChanged)
    Q_PROPERTY(bool batchChecksumRunning READ batchChecksumRunning NOTIFY batchChecksumStateChanged)
    Q_PROPERTY(double batchChecksumProgress READ batchChecksumProgress NOTIFY batchChecksumProgressChanged)
    Q_PROPERTY(QString batchChecksumDetail READ batchChecksumDetail NOTIFY batchChecksumProgressChanged)
    Q_PROPERTY(QVariantMap batchChecksumResult READ batchChecksumResult NOTIFY batchChecksumResultChanged)
    Q_PROPERTY(bool previewLoading READ previewLoading NOTIFY previewLoadingChanged)
    Q_PROPERTY(bool quickViewLoading READ quickViewLoading NOTIFY previewLoadingChanged)
    Q_PROPERTY(bool archiveOpRunning READ archiveOpRunning NOTIFY archiveOpChanged)
    Q_PROPERTY(QString archiveOpTitle READ archiveOpTitle NOTIFY archiveOpChanged)
    Q_PROPERTY(QString archiveOpDetail READ archiveOpDetail NOTIFY archiveOpChanged)
    Q_PROPERTY(bool remoteOpRunning READ remoteOpRunning NOTIFY remoteOpChanged)
    Q_PROPERTY(QString remoteOpDetail READ remoteOpDetail NOTIFY remoteOpChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)
    Q_PROPERTY(QString activeWorkspaceName READ activeWorkspaceName NOTIFY workspacesChanged)
    Q_PROPERTY(int trashCount READ trashCount NOTIFY trashChanged)
    Q_PROPERTY(bool commandRunning READ commandRunning NOTIFY commandStateChanged)
    Q_PROPERTY(QString commandOutput READ commandOutput NOTIFY commandOutputChanged)
    Q_PROPERTY(QString commandRunningText READ commandRunningText NOTIFY commandStateChanged)
    Q_PROPERTY(int commandLastExitCode READ commandLastExitCode NOTIFY commandStateChanged)
    Q_PROPERTY(QStringList commandHistory READ commandHistory NOTIFY commandHistoryChanged)
    Q_PROPERTY(bool splitOpRunning READ splitOpRunning NOTIFY splitOpChanged)
    Q_PROPERTY(double splitOpProgress READ splitOpProgress NOTIFY splitOpChanged)
    Q_PROPERTY(QString splitOpDetail READ splitOpDetail NOTIFY splitOpChanged)

    // User Preferences / Settings (persisted in session INI)
    Q_PROPERTY(int fontSize READ fontSize WRITE setFontSize NOTIFY settingsChanged)
    Q_PROPERTY(int rowHeight READ rowHeight WRITE setRowHeight NOTIFY settingsChanged)
    Q_PROPERTY(QString customEditor READ customEditor WRITE setCustomEditor NOTIFY settingsChanged)
    Q_PROPERTY(QString customTerminal READ customTerminal WRITE setCustomTerminal NOTIFY settingsChanged)
    Q_PROPERTY(bool confirmCopy READ confirmCopy WRITE setConfirmCopy NOTIFY settingsChanged)
    Q_PROPERTY(bool confirmMove READ confirmMove WRITE setConfirmMove NOTIFY settingsChanged)
    Q_PROPERTY(bool confirmDelete READ confirmDelete WRITE setConfirmDelete NOTIFY settingsChanged)
    Q_PROPERTY(bool showExtColumn READ showExtColumn WRITE setShowExtColumn NOTIFY settingsChanged)
    Q_PROPERTY(bool showSizeColumn READ showSizeColumn WRITE setShowSizeColumn NOTIFY settingsChanged)
    Q_PROPERTY(bool showModifiedColumn READ showModifiedColumn WRITE setShowModifiedColumn NOTIFY settingsChanged)
    Q_PROPERTY(QString languageMode READ languageMode WRITE setLanguageMode NOTIFY settingsChanged)

public:
    explicit Backend(const QString &bookmarksFile = {}, QObject *parent = nullptr);
    ~Backend() override;

    PanelModel* leftPanel() { return &m_leftPanel; }
    PanelModel* rightPanel() { return &m_rightPanel; }

    int activePanel() const { return m_activePanel; }
    void setActivePanel(int index);

    int windowWidth() const { return m_windowWidth; }
    void setWindowWidth(int width);
    int windowHeight() const { return m_windowHeight; }
    void setWindowHeight(int height);

    bool isBusy() const { return m_isBusy; }
    QString busyTitle() const { return m_busyTitle; }
    double busyProgress() const { return m_busyProgress; }
    QString busyDetail() const { return m_busyDetail; }
    bool canCancel() const { return m_canCancel; }
    bool isPaused() const { return m_isPaused; }
    QString busySpeed() const { return m_busySpeed; }
    qint64 busySpeedBytes() const { return m_busySpeedBytes; }
    QString busyEta() const { return m_busyEta; }
    qint64 busyDoneBytes() const { return m_busyDoneBytes; }
    qint64 busyTotalBytes() const { return m_busyTotalBytes; }
    int queueCount() const { return m_operationQueue.size(); }
    QVariantList operationQueue() const;
    QString statusMessage() const { return m_statusMessage; }
    QVariantList drives() const { return m_drives; }
    QStringList bookmarks() const { return m_bookmarks; }

    QStringList clipboardPaths() const { return m_clipboardPaths; }
    bool clipboardIsCut() const { return m_clipboardIsCut; }
    bool canPaste() const { return !m_clipboardPaths.isEmpty(); }

    bool canUndo() const { return !m_undoStack.isEmpty(); }
    QString undoDescription() const { return m_undoStack.isEmpty() ? QString() : m_undoStack.last().description; }

    QString themeMode() const { return m_themeMode; }
    bool isDarkTheme() const { return m_themeMode != QLatin1String("light"); }
    void setThemeMode(const QString &mode);
    Q_INVOKABLE void toggleThemeMode();

    PanelModel* activeModel();
    PanelModel* targetModel();

    Q_INVOKABLE void switchPanel();
    Q_INVOKABLE void swapPanels();
    Q_INVOKABLE void syncPanels();
    Q_INVOKABLE void compareDirectories();

    Q_INVOKABLE void openItem(const QString &path);
    Q_INVOKABLE void openWithEditor(const QString &path);
    Q_INVOKABLE void openInTerminal(const QString &path);

    // Copy/move run on a worker thread; they return true once the operation has
    // started and report the outcome through operationFinished().
    Q_INVOKABLE bool copyItems(const QStringList &sourcePaths, const QString &targetDir);
    Q_INVOKABLE bool moveItems(const QStringList &sourcePaths, const QString &targetDir);
    Q_INVOKABLE void cancelOperation();
    Q_INVOKABLE void cancelAllOperations();
    Q_INVOKABLE void pauseOperation();
    Q_INVOKABLE void resumeOperation();
    Q_INVOKABLE void togglePauseOperation();
    Q_INVOKABLE bool removeQueuedOperation(int queueId);
    Q_INVOKABLE void clearOperationQueue();
    // action: FileOperation::ConflictAction (1 = overwrite, 2 = skip, 3 = rename, 4 = cancel)
    Q_INVOKABLE void resolveConflict(int action, bool applyToAll);
    Q_INVOKABLE QString formatConflictDetails(qint64 size, const QDateTime &modified, bool isDir) const;
    Q_INVOKABLE bool deleteItems(const QStringList &paths, bool permanent = false);
    Q_INVOKABLE bool createDirectory(const QString &name);
    Q_INVOKABLE int createDirectories(const QString &namesCsv);
    Q_INVOKABLE bool createNewFile(const QString &fileName);
    Q_INVOKABLE int createFiles(const QString &namesCsv);
    Q_INVOKABLE bool renameItem(const QString &oldPath, const QString &newName);

    // Copy names and paths as comma-separated text
    Q_INVOKABLE QString copyNamesAsCsv(const QStringList &paths = {});
    Q_INVOKABLE QString copyPathsAsCsv(const QStringList &paths = {});
    Q_INVOKABLE QString copyFolderContentsAsCsv(const QString &dirPath = {}, bool fullPaths = false);
    Q_INVOKABLE bool copyTextToClipboard(const QString &text, const QString &statusMsg = QString());

    // Symbolic link creation (Ctrl+Shift+F5)
    Q_INVOKABLE bool createSymlink(const QString &sourcePath, const QString &linkDir, const QString &linkName = QString());
    Q_INVOKABLE bool createSymlinks(const QStringList &sourcePaths, const QString &linkDir);

    // Text File Visual Diff Comparison
    Q_INVOKABLE QVariantMap compareFiles(const QString &path1, const QString &path2) const;

    // Checksum calculation and verification (MD5 / SHA1 / SHA256)
    Q_INVOKABLE QVariantMap calculateChecksums(const QString &filePath) const;
    bool checksumRunning() const { return m_checksumRunning; }
    double checksumProgress() const { return m_checksumProgress; }
    QVariantMap checksumResult() const { return m_checksumResult; }
    Q_INVOKABLE void startChecksumCalculation(const QString &filePath);
    Q_INVOKABLE void cancelChecksumCalculation();
    Q_INVOKABLE bool verifyChecksum(const QString &filePath, const QString &expectedHash) const;
    Q_INVOKABLE bool saveChecksumFile(const QString &filePath, const QString &algorithm, const QString &targetFilePath = {}) const;
    Q_INVOKABLE QVariantMap verifyChecksumFile(const QString &checksumFilePath) const;

    // Batch checksum generation & verification
    bool batchChecksumRunning() const { return m_batchChecksumRunning; }
    double batchChecksumProgress() const { return m_batchChecksumProgress; }
    QString batchChecksumDetail() const { return m_batchChecksumDetail; }
    QVariantMap batchChecksumResult() const { return m_batchChecksumResult; }
    Q_INVOKABLE QVariantMap generateBatchChecksumFile(const QStringList &filePaths,
                                                      const QString &algorithm = QStringLiteral("sha256"),
                                                      const QString &outputFilePath = {}) const;
    Q_INVOKABLE void startBatchChecksumGenerate(const QStringList &filePaths,
                                                const QString &algorithm = QStringLiteral("sha256"),
                                                const QString &outputFilePath = {});
    Q_INVOKABLE void startBatchChecksumVerify(const QString &checksumFilePath);
    Q_INVOKABLE void cancelBatchChecksum();

    // System clipboard (text/uri-list + GNOME/KDE cut-copy hints)
    Q_INVOKABLE bool copyToClipboard(const QStringList &paths);
    Q_INVOKABLE bool cutToClipboard(const QStringList &paths);
    Q_INVOKABLE bool pasteFromClipboard(const QString &targetDir = {});

    // Native OS & inter-panel Drag & Drop (text/uri-list)
    Q_INVOKABLE void startDrag(const QStringList &paths);
    Q_INVOKABLE bool handleDrop(const QVariantList &urls, const QString &targetDir, bool move = false);

    // USB / Block Device Mounting via udisksctl
    Q_INVOKABLE bool mountDevice(const QString &devPath);
    Q_INVOKABLE bool unmountDevice(const QString &mountOrDevPath);
    Q_INVOKABLE void mountDeviceAsync(const QString &devPath);
    Q_INVOKABLE void unmountDeviceAsync(const QString &mountOrDevPath);

    // Remote Connections (Google Drive / Cloud via rclone, SFTP / SMB / SSHFS via GVFS / sshfs)
    QVariantList remoteConnections() const;
    bool rcloneAvailable() const;
    QVariantList rcloneRemotes() const { return m_rcloneRemotes; }
    bool gdriveAuthRunning() const { return m_gdriveAuthRunning; }
    QString gdriveAuthStatus() const { return m_gdriveAuthStatus; }
    QString gdriveAuthUrl() const { return m_gdriveAuthUrl; }
    bool remoteOpRunning() const { return m_remoteOpRunning; }
    QString remoteOpDetail() const { return m_remoteOpDetail; }
    Q_INVOKABLE void refreshRcloneRemotes();
    Q_INVOKABLE void startGoogleDriveAuth(const QString &remoteName,
                                            const QString &clientId = QString(),
                                            const QString &clientSecret = QString());
    Q_INVOKABLE void cancelGoogleDriveAuth();
    Q_INVOKABLE QString buildRemoteUri(const QVariantMap &connection) const;
    Q_INVOKABLE QVariantMap parseRemoteUri(const QString &uri) const;
    Q_INVOKABLE QString resolveRemoteMountPath(const QVariantMap &connection) const;
    Q_INVOKABLE bool saveRemoteConnection(const QVariantMap &connection);
    Q_INVOKABLE bool deleteRemoteConnection(const QString &idOrName);
    Q_INVOKABLE QString connectRemote(const QString &idOrUri);
    Q_INVOKABLE bool disconnectRemote(const QString &idOrMountPath);
    Q_INVOKABLE void connectRemoteAsync(const QString &idOrUri);
    Q_INVOKABLE void disconnectRemoteAsync(const QString &idOrMountPath);
    Q_INVOKABLE void cancelRemoteOperation();

    // XDG MIME & Open With (.desktop applications) + Custom Actions
    Q_INVOKABLE QVariantMap getFileMimeInfo(const QString &path) const;
    Q_INVOKABLE QVariantList getApplicationsForFile(const QString &path) const;
    Q_INVOKABLE QVariantList getAllInstalledApplications() const;
    Q_INVOKABLE bool openWithApplication(const QStringList &paths, const QString &desktopIdOrExec, bool setAsDefault = false);
    Q_INVOKABLE bool setDefaultApplicationForMime(const QString &mimeType, const QString &desktopId);

    QVariantList customActions() const { return m_customActions; }
    Q_INVOKABLE QVariantList getCustomActionsForFile(const QString &path) const;
    Q_INVOKABLE bool saveCustomAction(const QVariantMap &action);
    Q_INVOKABLE bool deleteCustomAction(const QString &idOrName);
    Q_INVOKABLE QString expandCustomActionCommand(const QString &commandTemplate, const QStringList &paths) const;
    Q_INVOKABLE QVariantMap executeCustomAction(const QString &idOrName, const QStringList &paths = {});

    // Undo stack (Rename, Multi-Rename, Move, Trash)
    Q_INVOKABLE bool undoLastOperation();

    // Item Properties & Permissions (Alt+Enter / chmod)
    Q_INVOKABLE QVariantMap getItemProperties(const QString &path) const;
    Q_INVOKABLE bool setItemPermissions(const QString &path, int octalMode, bool recursive = false);
    Q_INVOKABLE QString fileName(const QString &path) const { return QFileInfo(path).fileName(); }
    Q_INVOKABLE QString formatSymbolicPermissions(int octalMode) const;

    // Session persistence (QSettings)
    Q_INVOKABLE void saveSession() const;

    Q_INVOKABLE QVariantList previewMultiRename(const QStringList &paths, const QString &findText,
                                                const QString &replaceText, const QString &prefix,
                                                const QString &suffix, int caseMode, bool addCounter,
                                                bool useRegex = false, const QString &nameMask = QString(),
                                                int counterStart = 1, int counterStep = 1, int counterDigits = 3) const;
    Q_INVOKABLE bool executeMultiRename(const QStringList &paths, const QString &findText,
                                        const QString &replaceText, const QString &prefix,
                                        const QString &suffix, int caseMode, bool addCounter,
                                        bool useRegex = false, const QString &nameMask = QString(),
                                        int counterStart = 1, int counterStep = 1, int counterDigits = 3);
    QVariantList multiRenamePresets() const { return m_multiRenamePresets; }
    Q_INVOKABLE bool saveMultiRenamePreset(const QString &name, const QVariantMap &preset);
    Q_INVOKABLE QVariantMap getMultiRenamePreset(const QString &name) const;
    Q_INVOKABLE bool deleteMultiRenamePreset(const QString &name);

    Q_INVOKABLE bool isArchive(const QString &path) const;
    Q_INVOKABLE bool packArchive(const QStringList &sourcePaths, const QString &archivePath);
    Q_INVOKABLE bool extractArchive(const QString &archivePath, const QString &targetDir);
    Q_INVOKABLE bool extractArchiveItems(const QString &archivePath, const QStringList &sourcePaths, const QString &targetDir);
    bool archiveOpRunning() const { return m_archiveOpRunning; }
    QString archiveOpTitle() const { return m_archiveOpTitle; }
    QString archiveOpDetail() const { return m_archiveOpDetail; }
    Q_INVOKABLE void packArchiveAsync(const QStringList &sourcePaths, const QString &archivePath);
    Q_INVOKABLE void extractArchiveAsync(const QString &archivePath, const QString &targetDir);
    Q_INVOKABLE void cancelArchiveOperation();

    QStringList recentDirectories() const { return m_recentDirs; }
    Q_INVOKABLE void recordRecentDirectory(const QString &path);
    Q_INVOKABLE QVariantList queryJumpDirectories(const QString &query = QString(), int maxResults = 40) const;
    static int fuzzyScore(const QString &pattern, const QString &candidate);

    Q_INVOKABLE void refreshDrives();
    Q_INVOKABLE void toggleBookmark(const QString &path);
    Q_INVOKABLE bool isBookmarked(const QString &path) const;

    Q_INVOKABLE QVariantMap runCommand(const QString &command);
    Q_INVOKABLE QVariantMap getPreview(const QString &path, int pdfPage = 1);
    bool previewLoading() const { return m_previewLoading; }
    bool quickViewLoading() const { return m_quickViewLoading; }
    Q_INVOKABLE void requestPreview(const QString &path, int pdfPage = 1, const QString &target = QStringLiteral("modal"));
    Q_INVOKABLE void cancelPreview(const QString &target = QString());
    Q_INVOKABLE QStringList searchFiles(const QString &rootPath, const QString &query, int maxResults = 200);

    bool searchRunning() const { return m_searchRunning; }
    int searchScannedCount() const { return m_searchScannedCount; }
    QVariantList searchResultItems() const { return m_searchResultItems; }
    Q_INVOKABLE void startAdvancedSearch(const QString &rootPath, const QVariantMap &options = {});
    Q_INVOKABLE void cancelSearch();
    Q_INVOKABLE QVariantList runAdvancedSearchSync(const QString &rootPath, const QVariantMap &options = {});
    Q_INVOKABLE void feedPathsToPanel(const QStringList &paths, const QString &title = QString(), bool newTab = false);

    Q_INVOKABLE QVariantList compareDirectoriesRecursive(const QString &leftRoot, const QString &rightRoot,
                                                         const QString &compareMode = QStringLiteral("date_size"),
                                                         bool includeHidden = false);
    Q_INVOKABLE QVariantMap executeDirectorySync(const QString &leftRoot, const QString &rightRoot,
                                                 const QVariantList &syncItems);
    bool syncRunning() const { return m_syncRunning; }
    double syncProgress() const { return m_syncProgress; }
    QString syncDetail() const { return m_syncDetail; }
    QVariantList syncCompareResults() const { return m_syncCompareResults; }
    Q_INVOKABLE void startDirectoryCompare(const QString &leftRoot, const QString &rightRoot,
                                           const QString &compareMode = QStringLiteral("date_size"),
                                           bool includeHidden = false);
    Q_INVOKABLE void startDirectorySync(const QString &leftRoot, const QString &rightRoot,
                                        const QVariantList &syncItems);
    Q_INVOKABLE void cancelSyncOperation();

    Q_INVOKABLE QVariantList findDuplicateFiles(const QString &rootPath,
                                                  const QString &secondaryRootPath = QString(),
                                                  qint64 minSizeBytes = 1,
                                                  bool includeHidden = false);
    bool duplicateScanRunning() const { return m_duplicateScanRunning; }
    int duplicateScanScannedCount() const { return m_duplicateScanScannedCount; }
    QString duplicateScanDetail() const { return m_duplicateScanDetail; }
    QVariantList duplicateResults() const { return m_duplicateResults; }
    Q_INVOKABLE void startDuplicateScan(const QString &rootPath,
                                        const QString &secondaryRootPath = QString(),
                                        qint64 minSizeBytes = 1,
                                        bool includeHidden = false);
    Q_INVOKABLE void cancelDuplicateScan();

    Q_INVOKABLE void showStatus(const QString &message);
    Q_INVOKABLE QString activeFilesystemPath() const;
    Q_INVOKABLE void applyNavigationRequest(const QString &leftPath,
                                            const QString &rightPath = QString(),
                                            const QString &selectPath = QString(),
                                            bool newTab = false);

    // Tab power actions
    Q_INVOKABLE bool moveTabToOppositePanel(int panelIndex, int tabIndex = -1);

    // Saved Dual-Panel Workspaces (workspaces.json)
    QVariantList workspaces() const { return m_workspaces; }
    QString activeWorkspaceName() const { return m_activeWorkspaceName; }
    Q_INVOKABLE bool saveWorkspace(const QString &name);
    Q_INVOKABLE bool loadWorkspace(const QString &nameOrId);
    Q_INVOKABLE bool deleteWorkspace(const QString &nameOrId);

    // Freedesktop Trash Manager (trash://)
    int trashCount() const;
    Q_INVOKABLE void openTrash();
    Q_INVOKABLE int restoreFromTrash(const QStringList &trashFilePaths);
    Q_INVOKABLE int deleteFromTrashPermanently(const QStringList &trashFilePaths);
    Q_INVOKABLE int emptyTrash();

    // Async Interactive Command Runner & Persistent Command History
    bool commandRunning() const { return m_commandRunning; }
    QString commandOutput() const { return m_commandOutput; }
    QString commandRunningText() const { return m_commandRunningText; }
    int commandLastExitCode() const { return m_commandLastExitCode; }
    QStringList commandHistory() const { return m_commandHistory; }
    Q_INVOKABLE void runCommandAsync(const QString &command);
    Q_INVOKABLE void cancelCommand();
    Q_INVOKABLE void clearCommandOutput();
    Q_INVOKABLE void clearCommandHistory();
    Q_INVOKABLE QString shellQuote(const QString &text) const;

    // File Split & Combine (.001 / .crc)
    bool splitOpRunning() const { return m_splitOpRunning; }
    double splitOpProgress() const { return m_splitOpProgress; }
    QString splitOpDetail() const { return m_splitOpDetail; }
    Q_INVOKABLE QVariantMap inspectSplitSource(const QString &path) const;
    Q_INVOKABLE QVariantMap splitFile(const QString &sourcePath, const QString &targetDir,
                                      qint64 partSizeBytes, bool writeCrc = true);
    Q_INVOKABLE QVariantMap combineFiles(const QString &firstPartOrCrcPath, const QString &targetDir);
    Q_INVOKABLE void startSplitFile(const QString &sourcePath, const QString &targetDir,
                                    qint64 partSizeBytes, bool writeCrc = true);
    Q_INVOKABLE void startCombineFiles(const QString &firstPartOrCrcPath, const QString &targetDir);
    Q_INVOKABLE void cancelSplitOperation();

    // User Preferences / Settings
    int fontSize() const { return m_fontSize; }
    void setFontSize(int size);
    int rowHeight() const { return m_rowHeight; }
    void setRowHeight(int height);
    QString customEditor() const { return m_customEditor; }
    void setCustomEditor(const QString &editor);
    QString customTerminal() const { return m_customTerminal; }
    void setCustomTerminal(const QString &terminal);
    bool confirmCopy() const { return m_confirmCopy; }
    void setConfirmCopy(bool confirm);
    bool confirmMove() const { return m_confirmMove; }
    void setConfirmMove(bool confirm);
    bool confirmDelete() const { return m_confirmDelete; }
    void setConfirmDelete(bool confirm);
    bool showExtColumn() const { return m_showExtColumn; }
    void setShowExtColumn(bool show);
    bool showSizeColumn() const { return m_showSizeColumn; }
    void setShowSizeColumn(bool show);
    bool showModifiedColumn() const { return m_showModifiedColumn; }
    void setShowModifiedColumn(bool show);
    QString languageMode() const { return m_languageMode; }
    void setLanguageMode(const QString &mode);
    Q_INVOKABLE void updateSettings(const QVariantMap &prefs);
    Q_INVOKABLE void resetSettingsToDefaults();

signals:
    void activePanelChanged();
    void windowSizeChanged();
    void busyChanged();
    void operationQueueChanged();
    void multiRenamePresetsChanged();
    void statusMessageChanged();
    void drivesChanged();
    void bookmarksChanged();
    void clipboardChanged();
    void undoChanged();
    void themeModeChanged();
    void recentDirectoriesChanged();
    void searchStateChanged();
    void searchProgressChanged();
    void searchResultsChanged();
    void remoteConnectionsChanged();
    void rcloneRemotesChanged();
    void gdriveAuthChanged();
    void gdriveAuthFinished(bool success, const QString &remoteName, const QString &message);
    void customActionsChanged();
    void duplicateScanStateChanged();
    void duplicateScanProgressChanged();
    void duplicateResultsChanged();
    void syncStateChanged();
    void syncProgressChanged();
    void syncCompareResultsChanged();
    void directorySyncFinished(const QVariantMap &summary);
    void checksumStateChanged();
    void checksumProgressChanged();
    void checksumResultChanged();
    void checksumFinished(const QVariantMap &result);
    void batchChecksumStateChanged();
    void batchChecksumProgressChanged();
    void batchChecksumResultChanged();
    void batchChecksumFinished(const QVariantMap &result);
    void previewLoadingChanged();
    void previewReady(const QString &target, const QVariantMap &data);
    void archiveOpChanged();
    void archiveOperationFinished(bool success, const QString &message);
    void remoteOpChanged();
    void remoteOperationFinished(bool success, const QString &mountPath, const QString &message);
    void operationFinished(bool success, const QString &message);
    void conflictRequested(const QVariantMap &info);
    void focusAndSelectRequested(int panelIndex, const QString &filePath);
    void windowActivateRequested();
    void workspacesChanged();
    void trashChanged();
    void commandStateChanged();
    void commandOutputChanged();
    void commandHistoryChanged();
    void commandFinished(bool success, int exitCode);
    void splitOpChanged();
    void splitOperationFinished(const QVariantMap &result);
    void settingsChanged();

private:
    QString resolvedTerminal(bool fallbackXterm = true, QStringList *prefixArgs = nullptr) const;
    QString ensureArchiveTempDir();
    static QString extractArchiveEntryToTempDir(const QString &archivePath, const QString &internalPath, const QString &tempDirPath);
    static QVariantMap buildPreviewData(const QString &path, int pdfPage, bool dark, const QString &tempDirPath,
                                        const std::atomic<bool> *cancelFlag = nullptr);
    void finalizeFontPreviewOnMainThread(QVariantMap &map) const;
    QVariantList buildBaseDrivesList() const;
    bool startFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir);
    bool launchFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir);
    void onFileOperationFinished();
    bool setClipboardFiles(const QStringList &paths, bool cut);
    void refreshClipboardState();
    static bool parseClipboardMime(const QMimeData *mime, QStringList &outPaths, bool &outIsCut);
    void pushUndo(UndoEntry entry);
    void loadSession();
    void loadBookmarks();
    void saveBookmarks() const;
    void loadWorkspaces();
    void saveWorkspaces() const;
    void recordCommandHistory(const QString &command);
    bool tryHandleBuiltinCd(const QString &command, QString *outMessage, int *outExitCode);
    static QVariantMap splitFileImpl(const QString &sourcePath, const QString &targetDir,
                                     qint64 partSizeBytes, bool writeCrc,
                                     const std::atomic<bool> *cancelFlag = nullptr,
                                     const std::function<void(double, const QString &)> &progressCb = {});
    static QVariantMap combineFilesImpl(const QString &firstPartOrCrcPath, const QString &targetDir,
                                        const std::atomic<bool> *cancelFlag = nullptr,
                                        const std::function<void(double, const QString &)> &progressCb = {});
    void ensureDefaultCustomActions();
    QString extractArchiveEntryToTemp(const QString &archivePath, const QString &internalPath);
    static QString computeNewName(const QFileInfo &fi, int index, const QString &findText,
                                  const QString &replaceText, const QString &prefix,
                                  const QString &suffix, int caseMode, bool addCounter,
                                  bool useRegex = false, const QString &nameMask = QString(),
                                  int counterStart = 1, int counterStep = 1, int counterDigits = 3);

    PanelModel m_leftPanel;
    PanelModel m_rightPanel;
    int m_activePanel = 0; // 0 = left, 1 = right
    int m_windowWidth = 1260;
    int m_windowHeight = 800;
    bool m_loadingSession = false;

    bool m_isBusy = false;
    QString m_busyTitle;
    double m_busyProgress = 0.0;
    QString m_busyDetail;
    bool m_canCancel = false;
    bool m_isPaused = false;
    QString m_busySpeed;
    qint64 m_busySpeedBytes = 0;
    QString m_busyEta;
    qint64 m_busyDoneBytes = 0;
    qint64 m_busyTotalBytes = 0;
    QList<QueuedFileOperation> m_operationQueue;
    int m_nextQueueId = 0;
    QVariantList m_multiRenamePresets;
    QVariantList m_remoteConnections;
    QVariantList m_rcloneRemotes;
    QProcess *m_gdriveAuthProc = nullptr;
    bool m_gdriveAuthRunning = false;
    QString m_gdriveAuthName;
    QString m_gdriveAuthClientId;
    QString m_gdriveAuthClientSecret;
    QString m_gdriveAuthStatus;
    QString m_gdriveAuthUrl;
    int m_gdriveAuthStep = 0;
    QVariantList m_customActions;
    QString m_statusMessage;

    FileOperation *m_fileOp = nullptr;
    QThread *m_fileOpThread = nullptr;

    QVariantList m_drives;
    QString m_bookmarksFile;
    QString m_sessionFile;
    QString m_workspacesFile;
    QStringList m_bookmarks;
    QVariantList m_workspaces;
    QString m_activeWorkspaceName;

    QStringList m_clipboardPaths;
    bool m_clipboardIsCut = false;
    QList<UndoEntry> m_undoStack;
    QString m_themeMode = QStringLiteral("dark");
    QStringList m_recentDirs;
    QTemporaryDir *m_archiveTempDir = nullptr;

    QThread *m_searchThread = nullptr;
    std::atomic<bool> m_searchCancelRequested{false};
    quint64 m_searchGeneration = 0;
    bool m_searchRunning = false;
    int m_searchScannedCount = 0;
    QVariantList m_searchResultItems;

    // Async drives (lsblk)
    std::atomic<quint64> m_drivesGeneration{0};
    std::shared_ptr<std::atomic<bool>> m_drivesCancel;

    // Async duplicate finder
    std::atomic<quint64> m_dupGeneration{0};
    std::shared_ptr<std::atomic<bool>> m_dupCancel;
    bool m_duplicateScanRunning = false;
    int m_duplicateScanScannedCount = 0;
    QString m_duplicateScanDetail;
    QVariantList m_duplicateResults;

    // Async directory compare & sync
    std::atomic<quint64> m_syncGeneration{0};
    std::shared_ptr<std::atomic<bool>> m_syncCancel;
    bool m_syncRunning = false;
    double m_syncProgress = 0.0;
    QString m_syncDetail;
    QVariantList m_syncCompareResults;

    // Async checksum
    std::atomic<quint64> m_checksumGeneration{0};
    std::shared_ptr<std::atomic<bool>> m_checksumCancel;
    bool m_checksumRunning = false;
    double m_checksumProgress = 0.0;
    QVariantMap m_checksumResult;

    // Async batch checksum generate & verify
    std::atomic<quint64> m_batchChecksumGeneration{0};
    std::shared_ptr<std::atomic<bool>> m_batchChecksumCancel;
    bool m_batchChecksumRunning = false;
    double m_batchChecksumProgress = 0.0;
    QString m_batchChecksumDetail;
    QVariantMap m_batchChecksumResult;

    // Async preview (modal & quickview tracked independently)
    std::atomic<quint64> m_modalPreviewGen{0};
    std::shared_ptr<std::atomic<bool>> m_modalPreviewCancel;
    std::atomic<quint64> m_quickViewPreviewGen{0};
    std::shared_ptr<std::atomic<bool>> m_quickViewPreviewCancel;
    bool m_previewLoading = false;
    bool m_quickViewLoading = false;

    // Async archive pack/extract
    std::atomic<quint64> m_archiveOpGen{0};
    std::shared_ptr<std::atomic<bool>> m_archiveOpCancel;
    bool m_archiveOpRunning = false;
    QString m_archiveOpTitle;
    QString m_archiveOpDetail;

    // Async remote / device mount & unmount
    std::atomic<quint64> m_remoteOpGen{0};
    std::shared_ptr<std::atomic<bool>> m_remoteOpCancel;
    bool m_remoteOpRunning = false;
    QString m_remoteOpDetail;

    // Async interactive command bar & history
    QProcess *m_cmdProc = nullptr;
    bool m_commandRunning = false;
    QString m_commandRunningText;
    QString m_commandOutput;
    int m_commandLastExitCode = 0;
    QStringList m_commandHistory;

    // Async file split & combine
    std::atomic<quint64> m_splitOpGen{0};
    std::shared_ptr<std::atomic<bool>> m_splitOpCancel;
    bool m_splitOpRunning = false;
    double m_splitOpProgress = 0.0;
    QString m_splitOpDetail;

    // User Preferences / Settings
    int m_fontSize = 12;
    int m_rowHeight = 27;
    QString m_customEditor;
    QString m_customTerminal;
    bool m_confirmCopy = true;
    bool m_confirmMove = true;
    bool m_confirmDelete = true;
    bool m_showExtColumn = true;
    bool m_showSizeColumn = true;
    bool m_showModifiedColumn = true;
    QString m_languageMode = QStringLiteral("auto");
};
