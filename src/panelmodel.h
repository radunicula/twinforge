#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QHash>
#include <QSet>
#include <QStorageInfo>
#include <QVariantList>

struct PanelTab {
    QString path;
    QStringList backStack;
    QStringList forwardStack;
    bool isCollection = false;
    QString collectionTitle;
    QString collectionBasePath;
    QStringList collectionPaths;
};

struct ArchiveEntryInfo {
    QString internalPath; // normalized without leading/trailing '/'
    bool isDir = false;
    qint64 size = 0;
    QDateTime modified;
    QString permissions;
    bool isExecutable = false;
};

struct PanelItem {
    QString name;
    QString path;
    bool isDir = false;
    bool isParent = false;
    qint64 size = 0;
    bool dirSizeCalculated = false;
    QString formattedSize;
    QDateTime modified;
    QString formattedModified;
    QString extension;
    QString permissions;
    QString iconType;
    QString gitStatus; // "", "modified", "untracked", "staged", "deleted"
    bool isSelected = false;
};

class PanelModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(int sortField READ sortField WRITE setSortField NOTIFY sortChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortChanged)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY countChanged)
    Q_PROPERTY(int selectedCount READ selectedCount NOTIFY selectionChanged)
    Q_PROPERTY(QString totalSelectedSizeFormatted READ totalSelectedSizeFormatted NOTIFY selectionChanged)
    Q_PROPERTY(QString freeSpaceFormatted READ freeSpaceFormatted NOTIFY freeSpaceChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY historyChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY historyChanged)
    Q_PROPERTY(QVariantList tabs READ tabs NOTIFY tabsChanged)
    Q_PROPERTY(int activeTab READ activeTab WRITE setActiveTab NOTIFY tabsChanged)
    Q_PROPERTY(int tabCount READ tabCount NOTIFY tabsChanged)
    Q_PROPERTY(int viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(bool isGitRepo READ isGitRepo NOTIFY gitChanged)
    Q_PROPERTY(QString gitBranch READ gitBranch NOTIFY gitChanged)
    Q_PROPERTY(int gitModifiedCount READ gitModifiedCount NOTIFY gitChanged)
    Q_PROPERTY(int gitUntrackedCount READ gitUntrackedCount NOTIFY gitChanged)
    Q_PROPERTY(bool isWritable READ isWritable NOTIFY pathChanged)
    Q_PROPERTY(bool flatView READ flatView WRITE setFlatView NOTIFY flatViewChanged)
    Q_PROPERTY(bool isArchiveView READ isArchiveView NOTIFY pathChanged)
    Q_PROPERTY(QString archiveFilePath READ archiveFilePath NOTIFY pathChanged)
    Q_PROPERTY(QString archiveInternalPath READ archiveInternalPath NOTIFY pathChanged)
    Q_PROPERTY(bool isCollectionView READ isCollectionView NOTIFY pathChanged)
    Q_PROPERTY(QString collectionTitle READ collectionTitle NOTIFY pathChanged)
    Q_PROPERTY(bool diskUsageMode READ diskUsageMode WRITE setDiskUsageMode NOTIFY diskUsageModeChanged)
    Q_PROPERTY(qint64 maxItemSize READ maxItemSize NOTIFY countChanged)
    Q_PROPERTY(qint64 totalItemsSize READ totalItemsSize NOTIFY countChanged)
    Q_PROPERTY(QString totalItemsSizeFormatted READ totalItemsSizeFormatted NOTIFY countChanged)

public:
    enum SortField {
        SortByName = 0,
        SortByExt = 1,
        SortBySize = 2,
        SortByDate = 3
    };
    Q_ENUM(SortField)

    enum ViewMode {
        ViewModeList = 0,
        ViewModeGrid = 1
    };
    Q_ENUM(ViewMode)

    enum PanelRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsDirRole,
        IsParentRole,
        SizeRole,
        FormattedSizeRole,
        ModifiedRole,
        ExtensionRole,
        PermissionsRole,
        IconTypeRole,
        GitStatusRole,
        ThumbnailUrlRole,
        IsSelectedRole,
        SizeRatioRole,
        SizePercentRole
    };

    explicit PanelModel(const QString &initialPath = QString(), QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString path() const { return m_path; }
    Q_INVOKABLE void setPath(const QString &newPath);

    QString filter() const { return m_filter; }
    Q_INVOKABLE void setFilter(const QString &filter);

    bool showHidden() const { return m_showHidden; }
    Q_INVOKABLE void setShowHidden(bool show);

    int sortField() const { return m_sortField; }
    Q_INVOKABLE void setSortField(int field);

    bool sortAscending() const { return m_sortAscending; }
    Q_INVOKABLE void setSortAscending(bool asc);

    int itemCount() const { return m_items.size(); }
    int selectedCount() const;
    QString totalSelectedSizeFormatted() const;
    QString freeSpaceFormatted() const;

    bool canGoBack() const { return !m_backStack.isEmpty(); }
    bool canGoForward() const { return !m_forwardStack.isEmpty(); }

    QVariantList tabs() const;
    int activeTab() const { return m_activeTab; }
    int tabCount() const { return m_tabs.size(); }
    int viewMode() const { return m_viewMode; }
    Q_INVOKABLE void setViewMode(int mode);
    Q_INVOKABLE void toggleViewMode();

    bool isGitRepo() const { return m_isGitRepo; }
    QString gitBranch() const { return m_gitBranch; }
    int gitModifiedCount() const { return m_gitModifiedCount; }
    int gitUntrackedCount() const { return m_gitUntrackedCount; }
    bool isWritable() const;

    bool flatView() const { return m_flatView; }
    Q_INVOKABLE void setFlatView(bool flat);
    Q_INVOKABLE void toggleFlatView();

    bool isArchiveView() const { return !m_archiveFile.isEmpty(); }
    QString archiveFilePath() const { return m_archiveFile; }
    QString archiveInternalPath() const { return m_archiveInternalPath; }

    bool isCollectionView() const { return m_isCollectionView; }
    QString collectionTitle() const { return m_collectionTitle; }
    Q_INVOKABLE void feedItems(const QStringList &paths, const QString &title = QString(), const QString &basePath = QString());
    Q_INVOKABLE void exitCollectionView();

    bool diskUsageMode() const { return m_diskUsageMode; }
    Q_INVOKABLE void setDiskUsageMode(bool enabled);
    Q_INVOKABLE void toggleDiskUsageMode();
    qint64 maxItemSize() const { return m_maxItemSize; }
    qint64 totalItemsSize() const { return m_totalItemsSize; }
    QString totalItemsSizeFormatted() const { return formatSize(m_totalItemsSize, false); }

    static bool isArchiveFileName(const QString &path);
    static bool splitArchivePath(const QString &rawPath, QString *outArchiveFile, QString *outInternalPath = nullptr);
    static QList<ArchiveEntryInfo> readArchiveEntries(const QString &archivePath);

    Q_INVOKABLE void setActiveTab(int index);
    Q_INVOKABLE int addTab(const QString &path = {});
    Q_INVOKABLE void closeTab(int index = -1);
    Q_INVOKABLE void nextTab();
    Q_INVOKABLE void prevTab();

    QStringList tabPaths() const;
    void restoreTabs(const QStringList &paths, int activeIndex);

    Q_INVOKABLE void cd(const QString &nameOrPath);
    Q_INVOKABLE void cdUp();
    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggleSelection(int index);
    Q_INVOKABLE bool itemIsSelected(int index) const;
    Q_INVOKABLE void setItemSelected(int index, bool selected);
    Q_INVOKABLE void selectRange(int fromIndex, int toIndex, bool select = true);
    Q_INVOKABLE void setSelectedIndices(const QList<int> &indices, bool addToExisting = false);
    Q_INVOKABLE void selectByPattern(const QString &pattern, bool select = true);
    Q_INVOKABLE void deselectByPattern(const QString &pattern) { selectByPattern(pattern, false); }
    Q_INVOKABLE void calculateFolderSize(int index);
    Q_INVOKABLE void calculateAllFolderSizes();
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void deselectAll();
    Q_INVOKABLE void invertSelection();
    Q_INVOKABLE void selectDifferenceFrom(PanelModel *other);
    Q_INVOKABLE QString itemPath(int index) const;
    Q_INVOKABLE bool itemIsDir(int index) const;
    Q_INVOKABLE QString itemName(int index) const;
    Q_INVOKABLE QString itemGitStatus(int index) const;
    Q_INVOKABLE QStringList selectedPaths() const;
    Q_INVOKABLE QStringList allItemNames(bool excludeParent = true) const;
    Q_INVOKABLE QStringList allItemPaths(bool excludeParent = true) const;
    Q_INVOKABLE int findIndexByPrefix(const QString &prefix, int startIndex = 0) const;

    static QString formatSize(qint64 bytes, bool isDir);

signals:
    void pathChanged();
    void filterChanged();
    void showHiddenChanged();
    void sortChanged();
    void countChanged();
    void selectionChanged();
    void freeSpaceChanged();
    void historyChanged();
    void tabsChanged();
    void viewModeChanged();
    void gitChanged();
    void flatViewChanged();
    void diskUsageModeChanged();

private:
    void syncActiveTabState();
    static QString resolveDirectoryPath(const QString &rawPath);
    static QString tabTitleForPath(const QString &path);
    void loadDirectory();
    void loadArchiveDirectory();
    void loadCollectionItems();
    void recalculateSizeMetrics();
    void calculateFolderSizeInternal(int index, bool deferMetrics);
    void updateGitStatus();
    void sortItems();
    static qint64 computeDirectorySize(const QString &dirPath);
    static QString detectIconType(const QFileInfo &info);
    static QString detectIconTypeForName(const QString &fileName, bool isDir, bool isExec = false);

    QString m_path;
    QString m_filter;
    bool m_showHidden = false;
    bool m_flatView = false;
    bool m_isCollectionView = false;
    QString m_collectionTitle;
    QString m_collectionBasePath;
    QStringList m_collectionPaths;
    bool m_diskUsageMode = false;
    qint64 m_maxItemSize = 0;
    qint64 m_totalItemsSize = 0;
    QString m_archiveFile;
    QString m_archiveInternalPath;
    int m_sortField = SortByName;
    bool m_sortAscending = true;
    int m_viewMode = ViewModeList;

    bool m_isGitRepo = false;
    QString m_gitBranch;
    int m_gitModifiedCount = 0;
    int m_gitUntrackedCount = 0;

    QStringList m_backStack;
    QStringList m_forwardStack;
    bool m_navigatingHistory = false;
    bool m_switchingTab = false;
    QList<PanelTab> m_tabs;
    int m_activeTab = 0;

    QList<PanelItem> m_allItems;
    QList<PanelItem> m_items;
    QSet<QString> m_selectedPaths;
    QHash<QString, qint64> m_calculatedDirSizes;
    QString m_cachedArchiveFile;
    QDateTime m_cachedArchiveMtime;
    QList<ArchiveEntryInfo> m_cachedArchiveEntries;
    QFileSystemWatcher m_dirWatcher;
};
