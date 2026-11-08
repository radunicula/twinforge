#pragma once

#include <QDateTime>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include "fileoperation.h"
#include "panelmodel.h"

class QMimeData;
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
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantList drives READ drives NOTIFY drivesChanged)
    Q_PROPERTY(QStringList bookmarks READ bookmarks NOTIFY bookmarksChanged)
    Q_PROPERTY(QStringList clipboardPaths READ clipboardPaths NOTIFY clipboardChanged)
    Q_PROPERTY(bool clipboardIsCut READ clipboardIsCut NOTIFY clipboardChanged)
    Q_PROPERTY(bool canPaste READ canPaste NOTIFY clipboardChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY undoChanged)
    Q_PROPERTY(QString undoDescription READ undoDescription NOTIFY undoChanged)

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
    QString statusMessage() const { return m_statusMessage; }
    QVariantList drives() const { return m_drives; }
    QStringList bookmarks() const { return m_bookmarks; }

    QStringList clipboardPaths() const { return m_clipboardPaths; }
    bool clipboardIsCut() const { return m_clipboardIsCut; }
    bool canPaste() const { return !m_clipboardPaths.isEmpty(); }

    bool canUndo() const { return !m_undoStack.isEmpty(); }
    QString undoDescription() const { return m_undoStack.isEmpty() ? QString() : m_undoStack.last().description; }

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
                                                const QString &suffix, int caseMode, bool addCounter) const;
    Q_INVOKABLE bool executeMultiRename(const QStringList &paths, const QString &findText,
                                        const QString &replaceText, const QString &prefix,
                                        const QString &suffix, int caseMode, bool addCounter);

    Q_INVOKABLE bool isArchive(const QString &path) const;
    Q_INVOKABLE bool packArchive(const QStringList &sourcePaths, const QString &archivePath);
    Q_INVOKABLE bool extractArchive(const QString &archivePath, const QString &targetDir);

    Q_INVOKABLE void refreshDrives();
    Q_INVOKABLE void toggleBookmark(const QString &path);
    Q_INVOKABLE bool isBookmarked(const QString &path) const;

    Q_INVOKABLE QVariantMap runCommand(const QString &command);
    Q_INVOKABLE QVariantMap getPreview(const QString &path);
    Q_INVOKABLE QStringList searchFiles(const QString &rootPath, const QString &query, int maxResults = 200);

    Q_INVOKABLE void showStatus(const QString &message);

signals:
    void activePanelChanged();
    void windowSizeChanged();
    void busyChanged();
    void statusMessageChanged();
    void drivesChanged();
    void bookmarksChanged();
    void clipboardChanged();
    void undoChanged();
    void operationFinished(bool success, const QString &message);
    void conflictRequested(const QVariantMap &info);

private:
    bool startFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir);
    void onFileOperationFinished();
    bool setClipboardFiles(const QStringList &paths, bool cut);
    void refreshClipboardState();
    static bool parseClipboardMime(const QMimeData *mime, QStringList &outPaths, bool &outIsCut);
    void pushUndo(UndoEntry entry);
    void loadSession();
    void loadBookmarks();
    void saveBookmarks() const;
    static QString computeNewName(const QString &originalName, int index, const QString &findText,
                                  const QString &replaceText, const QString &prefix,
                                  const QString &suffix, int caseMode, bool addCounter);

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
};
