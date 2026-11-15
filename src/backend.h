#pragma once

#include <QDateTime>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include <atomic>

#include "fileoperation.h"
#include "panelmodel.h"

class QMimeData;
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
    Q_PROPERTY(QVariantList customActions READ customActions NOTIFY customActionsChanged)

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

    // Symbolic link creation (Ctrl+Shift+F5)
    Q_INVOKABLE bool createSymlink(const QString &sourcePath, const QString &linkDir, const QString &linkName = QString());
    Q_INVOKABLE bool createSymlinks(const QStringList &sourcePaths, const QString &linkDir);

    // Text File Visual Diff Comparison
    Q_INVOKABLE QVariantMap compareFiles(const QString &path1, const QString &path2) const;

    // Checksum calculation and verification (MD5 / SHA1 / SHA256)
    Q_INVOKABLE QVariantMap calculateChecksums(const QString &filePath) const;
    Q_INVOKABLE bool verifyChecksum(const QString &filePath, const QString &expectedHash) const;
    Q_INVOKABLE bool saveChecksumFile(const QString &filePath, const QString &algorithm, const QString &targetFilePath = {}) const;
    Q_INVOKABLE QVariantMap verifyChecksumFile(const QString &checksumFilePath) const;

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

    // Remote Connections (SFTP / SMB / SSHFS via GVFS gio mount / sshfs)
    QVariantList remoteConnections() const;
    Q_INVOKABLE QString buildRemoteUri(const QVariantMap &connection) const;
    Q_INVOKABLE QVariantMap parseRemoteUri(const QString &uri) const;
    Q_INVOKABLE QString resolveRemoteMountPath(const QVariantMap &connection) const;
    Q_INVOKABLE bool saveRemoteConnection(const QVariantMap &connection);
    Q_INVOKABLE bool deleteRemoteConnection(const QString &idOrName);
    Q_INVOKABLE QString connectRemote(const QString &idOrUri);
    Q_INVOKABLE bool disconnectRemote(const QString &idOrMountPath);

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

    QStringList recentDirectories() const { return m_recentDirs; }
    Q_INVOKABLE void recordRecentDirectory(const QString &path);
    Q_INVOKABLE QVariantList queryJumpDirectories(const QString &query = QString(), int maxResults = 40) const;
    static int fuzzyScore(const QString &pattern, const QString &candidate);

    Q_INVOKABLE void refreshDrives();
    Q_INVOKABLE void toggleBookmark(const QString &path);
    Q_INVOKABLE bool isBookmarked(const QString &path) const;

    Q_INVOKABLE QVariantMap runCommand(const QString &command);
    Q_INVOKABLE QVariantMap getPreview(const QString &path, int pdfPage = 1);
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
    Q_INVOKABLE QVariantList findDuplicateFiles(const QString &rootPath,
                                                  const QString &secondaryRootPath = QString(),
                                                  qint64 minSizeBytes = 1,
                                                  bool includeHidden = false);

    Q_INVOKABLE void showStatus(const QString &message);

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
    void customActionsChanged();
    void operationFinished(bool success, const QString &message);
    void conflictRequested(const QVariantMap &info);

private:
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
    QVariantList m_customActions;
    QString m_statusMessage;

    FileOperation *m_fileOp = nullptr;
    QThread *m_fileOpThread = nullptr;

    QVariantList m_drives;
    QString m_bookmarksFile;
    QString m_sessionFile;
    QStringList m_bookmarks;

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
};
