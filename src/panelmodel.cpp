#include <archive.h>
#include <archive_entry.h>

#include "panelmodel.h"

#include <algorithm>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QProcess>
#include <QRegularExpression>
#include <QUrl>
#include <QVariantMap>

namespace {

QString formatPosixPermissions(int mode)
{
    QString perm;
    perm.reserve(9);
    const int flags[9] = {0400, 0200, 0100, 0040, 0020, 0010, 0004, 0002, 0001};
    const char chars[3] = {'r', 'w', 'x'};
    for (int i = 0; i < 9; ++i)
        perm += (mode & flags[i]) ? chars[i % 3] : '-';
    return perm;
}

int toPosixMode(QFile::Permissions p)
{
    int mode = 0;
    if (p & QFile::ReadOwner) mode |= 0400;
    if (p & QFile::WriteOwner) mode |= 0200;
    if (p & QFile::ExeOwner) mode |= 0100;
    if (p & QFile::ReadGroup) mode |= 0040;
    if (p & QFile::WriteGroup) mode |= 0020;
    if (p & QFile::ExeGroup) mode |= 0010;
    if (p & QFile::ReadOther) mode |= 0004;
    if (p & QFile::WriteOther) mode |= 0002;
    if (p & QFile::ExeOther) mode |= 0001;
    return mode;
}

QString expandUserTilde(const QString &rawPath)
{
    QString expanded = rawPath.trimmed();
    if (expanded == QLatin1String("~"))
        return QDir::homePath();
    if (expanded.startsWith(QLatin1String("~/")))
        return QDir::homePath() + expanded.mid(1);
    return expanded;
}

bool hasHiddenSegment(const QString &relPath)
{
    const QStringList parts = relPath.split('/', Qt::SkipEmptyParts);
    for (const QString &part : parts) {
        if (part.startsWith('.'))
            return true;
    }
    return false;
}

} // namespace

PanelModel::PanelModel(const QString &initialPath, QObject *parent)
    : QAbstractListModel(parent)
{
    connect(&m_dirWatcher, &QFileSystemWatcher::directoryChanged, this, &PanelModel::refresh);
    connect(&m_dirWatcher, &QFileSystemWatcher::fileChanged, this, &PanelModel::refresh);

    QString target = initialPath;
    if (target.isEmpty() || !QDir(target).exists()) {
        target = QDir::homePath();
    }
    setPath(target);
}

int PanelModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_items.size();
}

QVariant PanelModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const PanelItem &item = m_items.at(index.row());
    switch (role) {
    case NameRole:
        return item.name;
    case PathRole:
        return item.path;
    case IsDirRole:
        return item.isDir;
    case IsParentRole:
        return item.isParent;
    case SizeRole:
        return item.size;
    case FormattedSizeRole:
        return item.formattedSize;
    case ModifiedRole:
        return item.formattedModified;
    case ExtensionRole:
        return item.extension;
    case PermissionsRole:
        return item.permissions;
    case IconTypeRole:
        return item.iconType;
    case GitStatusRole:
        return item.gitStatus;
    case ThumbnailUrlRole:
        return (item.iconType == QLatin1String("image") && !item.isParent)
                   ? QUrl::fromLocalFile(item.path).toString()
                   : QString();
    case IsSelectedRole:
        return item.isSelected;
    case SizeRatioRole:
        return (!item.isParent && (!item.isDir || item.dirSizeCalculated) && m_maxItemSize > 0)
                   ? (static_cast<double>(item.size) / static_cast<double>(m_maxItemSize))
                   : 0.0;
    case SizePercentRole:
        return (!item.isParent && (!item.isDir || item.dirSizeCalculated) && m_totalItemsSize > 0)
                   ? (static_cast<double>(item.size) * 100.0 / static_cast<double>(m_totalItemsSize))
                   : 0.0;
    default:
        return {};
    }
}

QHash<int, QByteArray> PanelModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[IsDirRole] = "isDir";
    roles[IsParentRole] = "isParent";
    roles[SizeRole] = "size";
    roles[FormattedSizeRole] = "formattedSize";
    roles[ModifiedRole] = "modified";
    roles[ExtensionRole] = "extension";
    roles[PermissionsRole] = "permissions";
    roles[IconTypeRole] = "iconType";
    roles[GitStatusRole] = "gitStatus";
    roles[ThumbnailUrlRole] = "thumbnailUrl";
    roles[IsSelectedRole] = "isSelected";
    roles[SizeRatioRole] = "sizeRatio";
    roles[SizePercentRole] = "sizePercent";
    return roles;
}

bool PanelModel::isArchiveFileName(const QString &path)
{
    const QString lower = path.toLower();
    return lower.endsWith(".zip") || lower.endsWith(".tar") || lower.endsWith(".tar.gz") ||
           lower.endsWith(".tgz") || lower.endsWith(".tar.xz") || lower.endsWith(".txz") ||
           lower.endsWith(".tar.bz2") || lower.endsWith(".tbz2") || lower.endsWith(".tar.zst") ||
           lower.endsWith(".tzst") || lower.endsWith(".7z");
}

bool PanelModel::splitArchivePath(const QString &rawPath, QString *outArchiveFile, QString *outInternalPath)
{
    if (outArchiveFile)
        outArchiveFile->clear();
    if (outInternalPath)
        outInternalPath->clear();

    const QString expanded = expandUserTilde(rawPath);
    if (expanded.isEmpty())
        return false;

    const int dblColon = expanded.indexOf(QLatin1String("::"));
    if (dblColon > 0) {
        const QString archiveCandidate = QDir::cleanPath(expanded.left(dblColon));
        QFileInfo fi(archiveCandidate);
        if (fi.isFile() && isArchiveFileName(fi.fileName())) {
            const QString canon = fi.canonicalFilePath();
            if (outArchiveFile)
                *outArchiveFile = canon.isEmpty() ? fi.absoluteFilePath() : canon;
            if (outInternalPath) {
                QString inner = expanded.mid(dblColon + 2);
                inner.replace('\\', '/');
                while (inner.startsWith('/'))
                    inner.remove(0, 1);
                while (inner.endsWith('/'))
                    inner.chop(1);
                *outInternalPath = inner;
            }
            return true;
        }
        return false;
    }

    QString clean = QDir::cleanPath(expanded);
    if (!clean.startsWith('/'))
        clean = QDir::cleanPath(QFileInfo(clean).absoluteFilePath());

    const QStringList parts = clean.split('/', Qt::SkipEmptyParts);
    QString accum;
    for (int i = 0; i < parts.size(); ++i) {
        accum += '/' + parts.at(i);
        if (isArchiveFileName(parts.at(i))) {
            QFileInfo fi(accum);
            if (fi.isFile()) {
                const QString canon = fi.canonicalFilePath();
                if (outArchiveFile)
                    *outArchiveFile = canon.isEmpty() ? fi.absoluteFilePath() : canon;
                if (outInternalPath && i + 1 < parts.size())
                    *outInternalPath = parts.mid(i + 1).join('/');
                return true;
            }
        }
    }
    return false;
}

QList<ArchiveEntryInfo> PanelModel::readArchiveEntries(const QString &archivePath)
{
    QList<ArchiveEntryInfo> result;
    struct archive *a = archive_read_new();
    if (!a)
        return result;

    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    const QByteArray encodedPath = QFile::encodeName(archivePath);
    if (archive_read_open_filename(a, encodedPath.constData(), 65536) != ARCHIVE_OK) {
        archive_read_free(a);
        return result;
    }

    struct archive_entry *entry = nullptr;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        const char *utf8Name = archive_entry_pathname_utf8(entry);
        QString rawName = utf8Name ? QString::fromUtf8(utf8Name)
                                   : QString::fromLocal8Bit(archive_entry_pathname(entry));
        const bool endsWithSlash = rawName.endsWith('/') || rawName.endsWith('\\');
        rawName.replace('\\', '/');

        const QStringList rawParts = rawName.split('/', Qt::SkipEmptyParts);
        QStringList safeParts;
        for (const QString &part : rawParts) {
            if (part == QLatin1String("."))
                continue;
            if (part == QLatin1String("..")) {
                if (!safeParts.isEmpty())
                    safeParts.removeLast();
                continue;
            }
            safeParts.append(part);
        }

        if (safeParts.isEmpty()) {
            archive_read_data_skip(a);
            continue;
        }

        ArchiveEntryInfo info;
        info.internalPath = safeParts.join('/');
        info.isDir = (archive_entry_filetype(entry) == AE_IFDIR) || endsWithSlash;
        info.size = std::max<qint64>(0, static_cast<qint64>(archive_entry_size(entry)));
        if (archive_entry_mtime_is_set(entry))
            info.modified = QDateTime::fromSecsSinceEpoch(archive_entry_mtime(entry));

        int perm = static_cast<int>(archive_entry_perm(entry)) & 0777;
        if (perm == 0)
            perm = info.isDir ? 0755 : 0644;
        info.permissions = formatPosixPermissions(perm);
        info.isExecutable = !info.isDir && ((perm & 0111) != 0);

        result.append(info);
        archive_read_data_skip(a);
    }

    archive_read_free(a);
    return result;
}

QString PanelModel::resolveDirectoryPath(const QString &rawPath)
{
    const QString expanded = expandUserTilde(rawPath);
    if (expanded.isEmpty())
        return {};

    QFileInfo dirInfo(expanded);
    if (dirInfo.exists() && dirInfo.isDir()) {
        const QString canonical = dirInfo.canonicalFilePath();
        return canonical.isEmpty() ? dirInfo.absoluteFilePath() : canonical;
    }

    QString archiveFile;
    QString internalPath;
    if (splitArchivePath(expanded, &archiveFile, &internalPath)) {
        return internalPath.isEmpty() ? archiveFile : (archiveFile + "/" + internalPath);
    }

    return {};
}

QString PanelModel::tabTitleForPath(const QString &path)
{
    if (path.isEmpty() || path == "/")
        return QStringLiteral("/");
    const QString name = QFileInfo(path).fileName();
    return name.isEmpty() ? path : name;
}

void PanelModel::syncActiveTabState()
{
    if (m_activeTab >= 0 && m_activeTab < m_tabs.size()) {
        m_tabs[m_activeTab].path = m_path;
        m_tabs[m_activeTab].backStack = m_backStack;
        m_tabs[m_activeTab].forwardStack = m_forwardStack;
        m_tabs[m_activeTab].isCollection = m_isCollectionView;
        m_tabs[m_activeTab].collectionTitle = m_collectionTitle;
        m_tabs[m_activeTab].collectionBasePath = m_collectionBasePath;
        m_tabs[m_activeTab].collectionPaths = m_collectionPaths;
    }
}

QVariantList PanelModel::tabs() const
{
    QVariantList out;
    out.reserve(m_tabs.size());
    for (int i = 0; i < m_tabs.size(); ++i) {
        const QString p = (i == m_activeTab && !m_path.isEmpty()) ? m_path : m_tabs.at(i).path;
        const bool isCol = (i == m_activeTab) ? m_isCollectionView : m_tabs.at(i).isCollection;
        const QString colTitle = (i == m_activeTab) ? m_collectionTitle : m_tabs.at(i).collectionTitle;
        QVariantMap entry;
        entry["path"] = p;
        entry["title"] = (isCol && !colTitle.isEmpty()) ? colTitle : tabTitleForPath(p);
        out.append(entry);
    }
    return out;
}

void PanelModel::setActiveTab(int index)
{
    if (index < 0 || index >= m_tabs.size() || index == m_activeTab)
        return;

    syncActiveTabState();
    m_activeTab = index;
    const PanelTab &tab = m_tabs.at(m_activeTab);
    m_backStack = tab.backStack;
    m_forwardStack = tab.forwardStack;
    m_isCollectionView = tab.isCollection;
    m_collectionTitle = tab.collectionTitle;
    m_collectionBasePath = tab.collectionBasePath;
    m_collectionPaths = tab.collectionPaths;

    const QString targetPath = tab.path;
    m_switchingTab = true;
    if (m_isCollectionView) {
        m_path = targetPath;
        m_selectedPaths.clear();
        if (!m_filter.isEmpty()) {
            m_filter.clear();
            emit filterChanged();
        }
        loadDirectory();
        emit pathChanged();
        emit freeSpaceChanged();
        emit selectionChanged();
    } else if (m_path != targetPath) {
        setPath(targetPath);
    } else {
        m_selectedPaths.clear();
        if (!m_filter.isEmpty()) {
            m_filter.clear();
            emit filterChanged();
        }
        loadDirectory();
        emit pathChanged();
        emit selectionChanged();
    }
    m_switchingTab = false;
    emit historyChanged();
    emit tabsChanged();
}

int PanelModel::addTab(const QString &path)
{
    syncActiveTabState();

    QString target = resolveDirectoryPath(path);
    if (target.isEmpty())
        target = m_path.isEmpty() ? QDir::homePath() : m_path;

    m_tabs.append(PanelTab{target, {}, {}, false, {}, {}, {}});
    m_activeTab = m_tabs.size() - 1;
    m_backStack.clear();
    m_forwardStack.clear();
    m_isCollectionView = false;
    m_collectionTitle.clear();
    m_collectionBasePath.clear();
    m_collectionPaths.clear();

    m_switchingTab = true;
    if (m_path != target) {
        setPath(target);
    } else {
        m_selectedPaths.clear();
        if (!m_filter.isEmpty()) {
            m_filter.clear();
            emit filterChanged();
        }
        loadDirectory();
        emit pathChanged();
        emit selectionChanged();
    }
    m_switchingTab = false;
    emit historyChanged();
    emit tabsChanged();
    return m_activeTab;
}

void PanelModel::closeTab(int index)
{
    if (m_tabs.size() <= 1)
        return;

    const int targetIdx = (index < 0) ? m_activeTab : index;
    if (targetIdx < 0 || targetIdx >= m_tabs.size())
        return;

    syncActiveTabState();
    m_tabs.removeAt(targetIdx);

    if (targetIdx < m_activeTab) {
        --m_activeTab;
        emit tabsChanged();
        return;
    }

    if (targetIdx == m_activeTab) {
        m_activeTab = std::min(targetIdx, static_cast<int>(m_tabs.size()) - 1);
        const PanelTab &tab = m_tabs.at(m_activeTab);
        m_backStack = tab.backStack;
        m_forwardStack = tab.forwardStack;
        m_isCollectionView = tab.isCollection;
        m_collectionTitle = tab.collectionTitle;
        m_collectionBasePath = tab.collectionBasePath;
        m_collectionPaths = tab.collectionPaths;

        const QString nextPath = tab.path;
        m_switchingTab = true;
        if (m_isCollectionView) {
            m_path = nextPath;
            m_selectedPaths.clear();
            loadDirectory();
            emit pathChanged();
            emit freeSpaceChanged();
            emit selectionChanged();
        } else if (m_path != nextPath) {
            setPath(nextPath);
        } else {
            m_selectedPaths.clear();
            loadDirectory();
            emit pathChanged();
            emit selectionChanged();
        }
        m_switchingTab = false;
        emit historyChanged();
    }
    emit tabsChanged();
}

void PanelModel::nextTab()
{
    if (m_tabs.size() > 1)
        setActiveTab((m_activeTab + 1) % m_tabs.size());
}

void PanelModel::prevTab()
{
    if (m_tabs.size() > 1)
        setActiveTab((m_activeTab - 1 + m_tabs.size()) % m_tabs.size());
}

QStringList PanelModel::tabPaths() const
{
    QStringList out;
    for (int i = 0; i < m_tabs.size(); ++i)
        out.append((i == m_activeTab && !m_path.isEmpty()) ? m_path : m_tabs.at(i).path);
    return out;
}

void PanelModel::restoreTabs(const QStringList &paths, int activeIndex)
{
    QList<PanelTab> validTabs;
    for (const QString &raw : paths) {
        const QString resolved = resolveDirectoryPath(raw);
        if (!resolved.isEmpty())
            validTabs.append(PanelTab{resolved, {}, {}, false, {}, {}, {}});
    }
    if (validTabs.isEmpty())
        return;

    m_tabs = validTabs;
    m_activeTab = std::clamp(activeIndex, 0, static_cast<int>(m_tabs.size()) - 1);
    m_backStack.clear();
    m_forwardStack.clear();

    const QString target = m_tabs.at(m_activeTab).path;
    m_switchingTab = true;
    if (m_path != target)
        setPath(target);
    else
        loadDirectory();
    m_switchingTab = false;
    emit historyChanged();
    emit tabsChanged();
}

void PanelModel::setPath(const QString &newPath)
{
    const QString cleanPath = resolveDirectoryPath(newPath);
    if (cleanPath.isEmpty())
        return;

    if (m_path == cleanPath && !m_isCollectionView)
        return;

    if (!m_path.isEmpty() && !m_navigatingHistory && !m_switchingTab && !m_isCollectionView) {
        m_backStack.append(m_path);
        if (m_backStack.size() > 50)
            m_backStack.removeFirst();
        m_forwardStack.clear();
        emit historyChanged();
    }

    if (!m_dirWatcher.directories().isEmpty())
        m_dirWatcher.removePaths(m_dirWatcher.directories());
    if (!m_dirWatcher.files().isEmpty())
        m_dirWatcher.removePaths(m_dirWatcher.files());

    m_path = cleanPath;
    m_isCollectionView = false;
    m_collectionTitle.clear();
    m_collectionBasePath.clear();
    m_collectionPaths.clear();
    if (m_flatView) {
        m_flatView = false;
        emit flatViewChanged();
    }
    if (m_diskUsageMode) {
        m_diskUsageMode = false;
        emit diskUsageModeChanged();
    }

    QString archiveFile;
    QString archiveInternal;
    if (QFileInfo(m_path).isDir()) {
        m_archiveFile.clear();
        m_archiveInternalPath.clear();
    } else if (splitArchivePath(m_path, &archiveFile, &archiveInternal)) {
        m_archiveFile = archiveFile;
        m_archiveInternalPath = archiveInternal;
    } else {
        m_archiveFile.clear();
        m_archiveInternalPath.clear();
    }

    const QString watchTarget = isArchiveView() ? m_archiveFile : m_path;
    if (!watchTarget.isEmpty() && QFileInfo::exists(watchTarget))
        m_dirWatcher.addPath(watchTarget);

    if (m_tabs.isEmpty()) {
        m_tabs.append(PanelTab{m_path, m_backStack, m_forwardStack, false, {}, {}, {}});
        m_activeTab = 0;
    } else if (m_activeTab >= 0 && m_activeTab < m_tabs.size()) {
        m_tabs[m_activeTab].path = m_path;
        m_tabs[m_activeTab].backStack = m_backStack;
        m_tabs[m_activeTab].forwardStack = m_forwardStack;
    }

    m_selectedPaths.clear();
    m_calculatedDirSizes.clear();
    if (!m_filter.isEmpty()) {
        m_filter.clear();
        emit filterChanged();
    }
    loadDirectory();
    emit pathChanged();
    emit tabsChanged();
    emit freeSpaceChanged();
    emit selectionChanged();
}

void PanelModel::setFilter(const QString &filter)
{
    if (m_filter == filter)
        return;

    m_filter = filter;
    beginResetModel();
    if (m_filter.trimmed().isEmpty()) {
        m_items = m_allItems;
    } else {
        m_items.clear();
        const QString lower = m_filter.trimmed().toLower();
        for (const auto &item : m_allItems) {
            if (item.isParent || item.name.toLower().contains(lower)) {
                m_items.append(item);
            }
        }
    }
    recalculateSizeMetrics();
    endResetModel();
    emit filterChanged();
    emit countChanged();
}

void PanelModel::setShowHidden(bool show)
{
    if (m_showHidden == show)
        return;

    m_showHidden = show;
    emit showHiddenChanged();
    loadDirectory();
}

void PanelModel::setSortField(int field)
{
    if (m_sortField == field) {
        setSortAscending(!m_sortAscending);
        return;
    }
    m_sortField = field;
    emit sortChanged();
    sortItems();
}

void PanelModel::setSortAscending(bool asc)
{
    if (m_sortAscending == asc)
        return;
    m_sortAscending = asc;
    emit sortChanged();
    sortItems();
}

void PanelModel::setFlatView(bool flat)
{
    if (m_flatView == flat)
        return;

    m_flatView = flat;
    m_selectedPaths.clear();
    loadDirectory();
    emit flatViewChanged();
    emit selectionChanged();
}

void PanelModel::toggleFlatView()
{
    setFlatView(!m_flatView);
}

void PanelModel::feedItems(const QStringList &paths, const QString &title, const QString &basePath)
{
    const QString resolvedBase = resolveDirectoryPath(basePath.isEmpty() ? m_path : basePath);
    if (!resolvedBase.isEmpty())
        m_path = resolvedBase;

    m_isCollectionView = true;
    m_collectionBasePath = m_path;
    m_collectionTitle = title.trimmed().isEmpty() ? tr("Search Results") : title.trimmed();
    m_collectionPaths = paths;
    m_archiveFile.clear();
    m_archiveInternalPath.clear();
    m_selectedPaths.clear();

    if (m_flatView) {
        m_flatView = false;
        emit flatViewChanged();
    }
    if (!m_filter.isEmpty()) {
        m_filter.clear();
        emit filterChanged();
    }

    syncActiveTabState();
    loadDirectory();
    emit pathChanged();
    emit tabsChanged();
    emit selectionChanged();
}

void PanelModel::exitCollectionView()
{
    if (!m_isCollectionView)
        return;

    const QString restorePath = m_collectionBasePath.isEmpty() ? m_path : m_collectionBasePath;
    m_isCollectionView = false;
    m_collectionTitle.clear();
    m_collectionBasePath.clear();
    m_collectionPaths.clear();
    m_selectedPaths.clear();

    if (!restorePath.isEmpty())
        m_path = restorePath;

    syncActiveTabState();
    loadDirectory();
    emit pathChanged();
    emit tabsChanged();
    emit freeSpaceChanged();
    emit selectionChanged();
}

void PanelModel::setDiskUsageMode(bool enabled)
{
    if (m_diskUsageMode == enabled)
        return;

    m_diskUsageMode = enabled;
    if (m_diskUsageMode) {
        calculateAllFolderSizes();
        m_sortField = SortBySize;
        m_sortAscending = false;
        emit sortChanged();
        sortItems();
    }
    emit diskUsageModeChanged();
}

void PanelModel::toggleDiskUsageMode()
{
    setDiskUsageMode(!m_diskUsageMode);
}

void PanelModel::cd(const QString &nameOrPath)
{
    if (nameOrPath == "..") {
        cdUp();
        return;
    }
    if (nameOrPath == "~" || nameOrPath.startsWith("~/")) {
        setPath(nameOrPath);
        return;
    }

    if (isArchiveView()) {
        if (QFileInfo(nameOrPath).isAbsolute())
            setPath(nameOrPath);
        else
            setPath(m_path + "/" + nameOrPath);
        return;
    }

    QFileInfo info(nameOrPath);
    if (!info.isAbsolute())
        info.setFile(m_path + "/" + nameOrPath);

    if (info.isDir() || (info.isFile() && isArchiveFileName(info.fileName()))) {
        setPath(info.absoluteFilePath());
    }
}

void PanelModel::cdUp()
{
    if (m_isCollectionView) {
        exitCollectionView();
        return;
    }
    if (isArchiveView()) {
        if (!m_archiveInternalPath.isEmpty()) {
            const int lastSlash = m_archiveInternalPath.lastIndexOf('/');
            const QString parentInternal = (lastSlash > 0) ? m_archiveInternalPath.left(lastSlash) : QString();
            setPath(parentInternal.isEmpty() ? m_archiveFile : (m_archiveFile + "/" + parentInternal));
        } else {
            setPath(QFileInfo(m_archiveFile).absolutePath());
        }
        return;
    }

    QDir dir(m_path);
    if (dir.cdUp()) {
        setPath(dir.absolutePath());
    }
}

void PanelModel::goBack()
{
    if (m_backStack.isEmpty())
        return;

    const QString prev = m_backStack.takeLast();
    m_forwardStack.append(m_path);
    m_navigatingHistory = true;
    setPath(prev);
    m_navigatingHistory = false;
    emit historyChanged();
}

void PanelModel::goForward()
{
    if (m_forwardStack.isEmpty())
        return;

    const QString next = m_forwardStack.takeLast();
    m_backStack.append(m_path);
    m_navigatingHistory = true;
    setPath(next);
    m_navigatingHistory = false;
    emit historyChanged();
}

void PanelModel::refresh()
{
    m_cachedArchiveFile.clear();
    loadDirectory();
    emit freeSpaceChanged();
}

qint64 PanelModel::computeDirectorySize(const QString &dirPath)
{
    qint64 total = 0;
    QDirIterator it(dirPath, QDir::Files | QDir::Hidden | QDir::System | QDir::NoSymLinks,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        total += it.fileInfo().size();
    }
    return total;
}

void PanelModel::recalculateSizeMetrics()
{
    qint64 maxSz = 0;
    qint64 totalSz = 0;
    for (const PanelItem &item : std::as_const(m_items)) {
        if (item.isParent)
            continue;
        if (item.isDir && !item.dirSizeCalculated)
            continue;
        if (item.size > 0) {
            maxSz = std::max(maxSz, item.size);
            totalSz += item.size;
        }
    }
    m_maxItemSize = maxSz;
    m_totalItemsSize = totalSz;
}

void PanelModel::calculateFolderSizeInternal(int index, bool deferMetrics)
{
    if (isArchiveView() || index < 0 || index >= m_items.size())
        return;

    PanelItem &item = m_items[index];
    if (!item.isDir || item.isParent)
        return;

    const qint64 bytes = computeDirectorySize(item.path);
    m_calculatedDirSizes.insert(item.path, bytes);
    item.size = bytes;
    item.dirSizeCalculated = true;
    item.formattedSize = formatSize(bytes, false);

    for (PanelItem &allItem : m_allItems) {
        if (allItem.path == item.path) {
            allItem.size = bytes;
            allItem.dirSizeCalculated = true;
            allItem.formattedSize = item.formattedSize;
            break;
        }
    }

    if (!deferMetrics) {
        recalculateSizeMetrics();
        if (!m_items.isEmpty())
            emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0),
                             {SizeRole, FormattedSizeRole, SizeRatioRole, SizePercentRole});
        emit countChanged();
    } else {
        QModelIndex idx = createIndex(index, 0);
        emit dataChanged(idx, idx, {SizeRole, FormattedSizeRole});
    }
    emit selectionChanged();
}

void PanelModel::calculateFolderSize(int index)
{
    calculateFolderSizeInternal(index, false);
}

void PanelModel::calculateAllFolderSizes()
{
    bool computedAny = false;
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].isDir && !m_items[i].isParent) {
            calculateFolderSizeInternal(i, true);
            computedAny = true;
        }
    }
    if (m_sortField == SortBySize) {
        sortItems();
    } else if (computedAny) {
        recalculateSizeMetrics();
        if (!m_items.isEmpty())
            emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0),
                             {SizeRole, FormattedSizeRole, SizeRatioRole, SizePercentRole});
        emit countChanged();
    }
}

void PanelModel::toggleSelection(int index)
{
    if (index < 0 || index >= m_items.size())
        return;

    PanelItem &item = m_items[index];
    if (item.isParent)
        return;

    // Total Commander behavior: pressing Space on a folder also calculates its size
    if (item.isDir && !item.dirSizeCalculated) {
        calculateFolderSize(index);
    }

    item.isSelected = !item.isSelected;
    if (item.isSelected)
        m_selectedPaths.insert(item.path);
    else
        m_selectedPaths.remove(item.path);

    for (PanelItem &allItem : m_allItems) {
        if (allItem.path == item.path) {
            allItem.isSelected = item.isSelected;
            break;
        }
    }

    QModelIndex idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {IsSelectedRole, SizeRole, FormattedSizeRole});
    emit selectionChanged();
}

bool PanelModel::itemIsSelected(int index) const
{
    if (index < 0 || index >= m_items.size())
        return false;
    return m_items[index].isSelected;
}

void PanelModel::setItemSelected(int index, bool selected)
{
    if (index < 0 || index >= m_items.size())
        return;

    PanelItem &item = m_items[index];
    if (item.isParent || item.isSelected == selected)
        return;

    item.isSelected = selected;
    if (selected)
        m_selectedPaths.insert(item.path);
    else
        m_selectedPaths.remove(item.path);

    for (PanelItem &allItem : m_allItems) {
        if (allItem.path == item.path) {
            allItem.isSelected = selected;
            break;
        }
    }

    QModelIndex idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {IsSelectedRole});
    emit selectionChanged();
}

void PanelModel::selectRange(int fromIndex, int toIndex, bool select)
{
    if (m_items.isEmpty())
        return;

    int start = qBound(0, qMin(fromIndex, toIndex), m_items.size() - 1);
    int end = qBound(0, qMax(fromIndex, toIndex), m_items.size() - 1);

    bool changed = false;
    for (int i = start; i <= end; ++i) {
        PanelItem &item = m_items[i];
        if (item.isParent || item.isSelected == select)
            continue;
        item.isSelected = select;
        if (select)
            m_selectedPaths.insert(item.path);
        else
            m_selectedPaths.remove(item.path);
        changed = true;
    }

    if (changed) {
        for (PanelItem &allItem : m_allItems) {
            allItem.isSelected = m_selectedPaths.contains(allItem.path);
        }
        emit dataChanged(createIndex(start, 0), createIndex(end, 0), {IsSelectedRole});
        emit selectionChanged();
    }
}

void PanelModel::setSelectedIndices(const QList<int> &indices, bool addToExisting)
{
    QSet<int> targetSet(indices.begin(), indices.end());
    bool changed = false;

    if (!addToExisting) {
        for (int i = 0; i < m_items.size(); ++i) {
            PanelItem &item = m_items[i];
            if (item.isParent)
                continue;
            bool shouldBeSelected = targetSet.contains(i);
            if (item.isSelected != shouldBeSelected) {
                item.isSelected = shouldBeSelected;
                if (shouldBeSelected)
                    m_selectedPaths.insert(item.path);
                else
                    m_selectedPaths.remove(item.path);
                changed = true;
                QModelIndex idx = createIndex(i, 0);
                emit dataChanged(idx, idx, {IsSelectedRole});
            }
        }
    } else {
        for (int i : targetSet) {
            if (i >= 0 && i < m_items.size()) {
                PanelItem &item = m_items[i];
                if (!item.isParent && !item.isSelected) {
                    item.isSelected = true;
                    m_selectedPaths.insert(item.path);
                    changed = true;
                    QModelIndex idx = createIndex(i, 0);
                    emit dataChanged(idx, idx, {IsSelectedRole});
                }
            }
        }
    }

    if (changed) {
        for (PanelItem &allItem : m_allItems) {
            allItem.isSelected = m_selectedPaths.contains(allItem.path);
        }
        emit selectionChanged();
    }
}

void PanelModel::selectAll()
{
    for (PanelItem &item : m_items) {
        if (!item.isParent) {
            item.isSelected = true;
            m_selectedPaths.insert(item.path);
        }
    }
    for (PanelItem &item : m_allItems) {
        if (!item.isParent)
            item.isSelected = true;
    }
    if (!m_items.isEmpty())
        emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0), {IsSelectedRole});
    emit selectionChanged();
}

void PanelModel::deselectAll()
{
    m_selectedPaths.clear();
    for (PanelItem &item : m_items)
        item.isSelected = false;
    for (PanelItem &item : m_allItems)
        item.isSelected = false;
    if (!m_items.isEmpty())
        emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0), {IsSelectedRole});
    emit selectionChanged();
}

void PanelModel::selectByPattern(const QString &pattern, bool select)
{
    const QString trimmed = pattern.trimmed();
    if (trimmed.isEmpty())
        return;

    QStringList patterns;
    for (const QString &part : trimmed.split(QRegularExpression(R"([;,\s]+)"), Qt::SkipEmptyParts)) {
        QString pat = part.trimmed();
        if (!pat.isEmpty()) {
            if (!pat.contains('*') && !pat.contains('?'))
                pat = "*" + pat + "*";
            patterns.append(pat);
        }
    }
    if (patterns.isEmpty())
        return;

    bool anyChanged = false;
    for (PanelItem &item : m_items) {
        if (item.isParent)
            continue;

        if (QDir::match(patterns, item.name)) {
            if (item.isSelected != select) {
                item.isSelected = select;
                anyChanged = true;
                if (select)
                    m_selectedPaths.insert(item.path);
                else
                    m_selectedPaths.remove(item.path);
            }
        }
    }

    for (PanelItem &allItem : m_allItems) {
        if (!allItem.isParent)
            allItem.isSelected = m_selectedPaths.contains(allItem.path);
    }

    if (anyChanged) {
        if (!m_items.isEmpty())
            emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0), {IsSelectedRole});
        emit selectionChanged();
    }
}

void PanelModel::setViewMode(int mode)
{
    const int clean = (mode == ViewModeGrid) ? ViewModeGrid : ViewModeList;
    if (m_viewMode != clean) {
        m_viewMode = clean;
        emit viewModeChanged();
    }
}

void PanelModel::toggleViewMode()
{
    setViewMode(m_viewMode == ViewModeList ? ViewModeGrid : ViewModeList);
}

void PanelModel::updateGitStatus()
{
    m_isGitRepo = false;
    m_gitBranch.clear();
    m_gitModifiedCount = 0;
    m_gitUntrackedCount = 0;

    if (isArchiveView() || m_path.isEmpty() || !QDir(m_path).exists()) {
        emit gitChanged();
        return;
    }

    QDir checkDir(m_path);
    bool foundGit = false;
    while (true) {
        if (checkDir.exists(".git")) {
            foundGit = true;
            break;
        }
        if (!checkDir.cdUp())
            break;
    }

    if (!foundGit) {
        emit gitChanged();
        return;
    }

    m_isGitRepo = true;

    QProcess branchProc;
    branchProc.setWorkingDirectory(m_path);
    branchProc.start("git", {"branch", "--show-current"});
    if (branchProc.waitForFinished(1000) && branchProc.exitCode() == 0) {
        m_gitBranch = QString::fromUtf8(branchProc.readAllStandardOutput()).trimmed();
    }
    if (m_gitBranch.isEmpty()) {
        QProcess headProc;
        headProc.setWorkingDirectory(m_path);
        headProc.start("git", {"rev-parse", "--short", "HEAD"});
        if (headProc.waitForFinished(1000) && headProc.exitCode() == 0) {
            m_gitBranch = QString::fromUtf8(headProc.readAllStandardOutput()).trimmed();
        }
    }

    QProcess statusProc;
    statusProc.setWorkingDirectory(m_path);
    statusProc.start("git", {"status", "--porcelain=v1", "."});
    if (statusProc.waitForFinished(2000) && statusProc.exitCode() == 0) {
        const QByteArray rawOut = statusProc.readAllStandardOutput();
        const QList<QByteArray> lines = rawOut.split('\n');
        QHash<QString, QString> statusMap;

        for (const QByteArray &line : lines) {
            if (line.size() < 4)
                continue;
            const char x = line.at(0);
            const char y = line.at(1);
            QByteArray relPath = line.mid(3).trimmed();
            const int arrow = relPath.indexOf(" -> ");
            if (arrow != -1)
                relPath = relPath.mid(arrow + 4);

            if (relPath.startsWith('"') && relPath.endsWith('"'))
                relPath = relPath.mid(1, relPath.size() - 2);

            QString fileName = QString::fromUtf8(relPath);
            const int slash = fileName.indexOf('/');
            if (slash != -1)
                fileName = fileName.left(slash);

            QString status;
            if (x == '?' && y == '?') {
                status = QStringLiteral("untracked");
                ++m_gitUntrackedCount;
            } else if (x == 'A' || y == 'A') {
                status = QStringLiteral("staged");
                ++m_gitModifiedCount;
            } else if (x == 'D' || y == 'D') {
                status = QStringLiteral("deleted");
                ++m_gitModifiedCount;
            } else {
                status = QStringLiteral("modified");
                ++m_gitModifiedCount;
            }

            if (!statusMap.contains(fileName) || status == "modified") {
                statusMap.insert(fileName, status);
            }
        }

        for (PanelItem &item : m_allItems) {
            if (!item.isParent && statusMap.contains(item.name))
                item.gitStatus = statusMap.value(item.name);
            else
                item.gitStatus.clear();
        }
        for (PanelItem &item : m_items) {
            if (!item.isParent && statusMap.contains(item.name))
                item.gitStatus = statusMap.value(item.name);
            else
                item.gitStatus.clear();
        }
    }

    emit gitChanged();
}

QString PanelModel::itemGitStatus(int index) const
{
    if (index >= 0 && index < m_items.size())
        return m_items.at(index).gitStatus;
    return {};
}

void PanelModel::invertSelection()
{
    for (PanelItem &item : m_items) {
        if (!item.isParent) {
            item.isSelected = !item.isSelected;
            if (item.isSelected)
                m_selectedPaths.insert(item.path);
            else
                m_selectedPaths.remove(item.path);
        }
    }
    for (PanelItem &item : m_allItems) {
        if (!item.isParent)
            item.isSelected = m_selectedPaths.contains(item.path);
    }
    if (!m_items.isEmpty())
        emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0), {IsSelectedRole});
    emit selectionChanged();
}

void PanelModel::selectDifferenceFrom(PanelModel *other)
{
    if (!other)
        return;

    QHash<QString, PanelItem> otherFiles;
    for (const auto &item : other->m_allItems) {
        if (!item.isParent) {
            otherFiles.insert(item.name, item);
        }
    }

    m_selectedPaths.clear();
    for (PanelItem &item : m_items) {
        if (item.isParent || item.isDir) {
            item.isSelected = false;
            continue;
        }
        bool isDiff = false;
        if (!otherFiles.contains(item.name)) {
            isDiff = true;
        } else {
            const PanelItem &o = otherFiles.value(item.name);
            if (item.size != o.size || item.modified > o.modified) {
                isDiff = true;
            }
        }
        item.isSelected = isDiff;
        if (isDiff)
            m_selectedPaths.insert(item.path);
    }

    for (PanelItem &item : m_allItems) {
        if (!item.isParent)
            item.isSelected = m_selectedPaths.contains(item.path);
    }

    if (!m_items.isEmpty())
        emit dataChanged(createIndex(0, 0), createIndex(m_items.size() - 1, 0), {IsSelectedRole});
    emit selectionChanged();
}

QString PanelModel::itemPath(int index) const
{
    if (index >= 0 && index < m_items.size())
        return m_items.at(index).path;
    return {};
}

bool PanelModel::itemIsDir(int index) const
{
    if (index >= 0 && index < m_items.size())
        return m_items.at(index).isDir;
    return false;
}

QString PanelModel::itemName(int index) const
{
    if (index >= 0 && index < m_items.size())
        return m_items.at(index).name;
    return {};
}

QStringList PanelModel::selectedPaths() const
{
    QStringList result;
    for (const auto &item : m_items) {
        if (!item.isParent && item.isSelected)
            result.append(item.path);
    }
    return result;
}

QStringList PanelModel::allItemNames(bool excludeParent) const
{
    QStringList result;
    result.reserve(m_items.size());
    for (const auto &item : m_items) {
        if (excludeParent && (item.isParent || item.name == QLatin1String("..")))
            continue;
        result.append(item.name);
    }
    return result;
}

QStringList PanelModel::allItemPaths(bool excludeParent) const
{
    QStringList result;
    result.reserve(m_items.size());
    for (const auto &item : m_items) {
        if (excludeParent && (item.isParent || item.name == QLatin1String("..")))
            continue;
        result.append(item.path);
    }
    return result;
}

bool PanelModel::isWritable() const
{
    if (isArchiveView())
        return false;
    const QString checkPath = m_isCollectionView && !m_collectionBasePath.isEmpty() ? m_collectionBasePath : m_path;
    return QFileInfo(checkPath).isWritable();
}

int PanelModel::selectedCount() const
{
    int count = 0;
    for (const auto &item : m_items) {
        if (!item.isParent && item.isSelected)
            count++;
    }
    return count;
}

QString PanelModel::totalSelectedSizeFormatted() const
{
    qint64 total = 0;
    for (const auto &item : m_items) {
        if (!item.isParent && item.isSelected && (!item.isDir || item.dirSizeCalculated))
            total += item.size;
    }
    return formatSize(total, false);
}

QString PanelModel::freeSpaceFormatted() const
{
    const QString target = isArchiveView() ? QFileInfo(m_archiveFile).absolutePath() : m_path;
    QStorageInfo storage(target);
    if (!storage.isValid() || !storage.isReady())
        return {};
    return formatSize(storage.bytesAvailable(), false);
}

int PanelModel::findIndexByPrefix(const QString &prefix, int startIndex) const
{
    if (prefix.isEmpty() || m_items.isEmpty())
        return -1;

    const QString lower = prefix.toLower();
    for (int i = startIndex; i < m_items.size(); ++i) {
        if (m_items.at(i).name.toLower().startsWith(lower))
            return i;
    }
    for (int i = 0; i < startIndex; ++i) {
        if (m_items.at(i).name.toLower().startsWith(lower))
            return i;
    }
    return -1;
}

QString PanelModel::formatSize(qint64 bytes, bool isDir)
{
    if (isDir)
        return QStringLiteral("<DIR>");

    if (bytes < 1024)
        return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024)
        return QString("%1 KB").arg(QString::number(bytes / 1024.0, 'f', 1));
    if (bytes < 1024 * 1024 * 1024)
        return QString("%1 MB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 1));
    return QString("%1 GB").arg(QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2));
}

QString PanelModel::detectIconTypeForName(const QString &fileName, bool isDir, bool isExec)
{
    if (isDir)
        return QStringLiteral("folder");

    const QString ext = QFileInfo(fileName).suffix().toLower();
    if (ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "svg" || ext == "webp" || ext == "gif")
        return QStringLiteral("image");
    if (ext == "cpp" || ext == "h" || ext == "c" || ext == "py" || ext == "js" || ext == "ts" ||
        ext == "json" || ext == "xml" || ext == "html" || ext == "css" || ext == "sh" || ext == "qml" || ext == "rs" || ext == "go")
        return QStringLiteral("code");
    if (ext == "zip" || ext == "tar" || ext == "gz" || ext == "xz" || ext == "bz2" || ext == "7z" || ext == "zst" || ext == "rar")
        return QStringLiteral("archive");
    if (ext == "mp3" || ext == "ogg" || ext == "wav" || ext == "flac")
        return QStringLiteral("audio");
    if (ext == "mp4" || ext == "mkv" || ext == "avi" || ext == "webm" || ext == "mov")
        return QStringLiteral("video");
    if (ext == "txt" || ext == "md" || ext == "log" || ext == "csv")
        return QStringLiteral("text");
    if (isExec)
        return QStringLiteral("binary");

    return QStringLiteral("file");
}

QString PanelModel::detectIconType(const QFileInfo &info)
{
    return detectIconTypeForName(info.fileName(), info.isDir(), !info.isDir() && info.isExecutable());
}

void PanelModel::loadDirectory()
{
    if (m_isCollectionView) {
        loadCollectionItems();
        sortItems();
        updateGitStatus();
        return;
    }

    if (isArchiveView()) {
        loadArchiveDirectory();
        sortItems();
        updateGitStatus();
        return;
    }

    QDir dir(m_path);
    m_allItems.clear();

    if (m_path != "/" && !m_path.isEmpty()) {
        PanelItem parentItem;
        parentItem.name = "..";
        parentItem.path = dir.cleanPath(m_path + "/..");
        parentItem.isDir = true;
        parentItem.isParent = true;
        parentItem.formattedSize = "<UP>";
        parentItem.iconType = "folder-parent";
        m_allItems.append(parentItem);
    }

    auto makeItem = [this](const QFileInfo &fi, const QString &displayName) -> PanelItem {
        PanelItem item;
        item.name = displayName;
        item.path = fi.absoluteFilePath();
        item.isDir = fi.isDir();
        item.isParent = false;
        if (fi.isDir() && m_calculatedDirSizes.contains(item.path)) {
            item.size = m_calculatedDirSizes.value(item.path);
            item.dirSizeCalculated = true;
            item.formattedSize = formatSize(item.size, false);
        } else {
            item.size = fi.isDir() ? 0 : fi.size();
            item.dirSizeCalculated = false;
            item.formattedSize = formatSize(fi.size(), fi.isDir());
        }
        item.modified = fi.lastModified();
        item.formattedModified = item.modified.toString("yyyy-MM-dd hh:mm");
        item.extension = fi.suffix();
        item.iconType = detectIconType(fi);
        item.isSelected = m_selectedPaths.contains(item.path);
        item.permissions = formatPosixPermissions(toPosixMode(fi.permissions()));
        return item;
    };

    QDir::Filters filters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::System;
    if (m_showHidden)
        filters |= QDir::Hidden;

    if (m_flatView) {
        constexpr int kMaxFlatItems = 5000;
        int flatCount = 0;
        QStringList queue{m_path};
        while (!queue.isEmpty() && flatCount < kMaxFlatItems) {
            const QString currentDir = queue.takeFirst();
            const QFileInfoList subEntries = QDir(currentDir).entryInfoList(filters);
            for (const QFileInfo &fi : subEntries) {
                if (fi.isDir()) {
                    if (!fi.isSymLink())
                        queue.append(fi.absoluteFilePath());
                    continue;
                }
                const QString relName = dir.relativeFilePath(fi.absoluteFilePath());
                if (!m_showHidden && hasHiddenSegment(relName))
                    continue;
                m_allItems.append(makeItem(fi, relName));
                if (++flatCount >= kMaxFlatItems)
                    break;
            }
        }
    } else {
        const QFileInfoList entries = dir.entryInfoList(filters);
        for (const QFileInfo &fi : entries)
            m_allItems.append(makeItem(fi, fi.fileName()));
    }

    sortItems();
    updateGitStatus();
}

void PanelModel::loadCollectionItems()
{
    m_allItems.clear();

    const QString base = m_collectionBasePath.isEmpty() ? m_path : m_collectionBasePath;
    PanelItem parentItem;
    parentItem.name = QStringLiteral("..");
    parentItem.path = base;
    parentItem.isDir = true;
    parentItem.isParent = true;
    parentItem.formattedSize = QStringLiteral("<UP>");
    parentItem.iconType = QStringLiteral("folder-parent");
    m_allItems.append(parentItem);

    QString cleanBase = QDir(base).absolutePath();
    if (!cleanBase.endsWith('/'))
        cleanBase += '/';

    QSet<QString> seenPaths;
    for (const QString &rawPath : std::as_const(m_collectionPaths)) {
        const QFileInfo fi(rawPath);
        if (!fi.exists())
            continue;
        const QString abs = fi.absoluteFilePath();
        if (seenPaths.contains(abs))
            continue;
        seenPaths.insert(abs);

        PanelItem item;
        item.name = (!cleanBase.isEmpty() && abs.startsWith(cleanBase)) ? abs.mid(cleanBase.size()) : fi.fileName();
        item.path = abs;
        item.isDir = fi.isDir();
        item.isParent = false;
        if (fi.isDir() && m_calculatedDirSizes.contains(abs)) {
            item.size = m_calculatedDirSizes.value(abs);
            item.dirSizeCalculated = true;
            item.formattedSize = formatSize(item.size, false);
        } else {
            item.size = fi.isDir() ? 0 : fi.size();
            item.dirSizeCalculated = false;
            item.formattedSize = formatSize(fi.size(), fi.isDir());
        }
        item.modified = fi.lastModified();
        item.formattedModified = item.modified.toString("yyyy-MM-dd hh:mm");
        item.extension = fi.suffix();
        item.iconType = detectIconType(fi);
        item.isSelected = m_selectedPaths.contains(abs);
        item.permissions = formatPosixPermissions(toPosixMode(fi.permissions()));
        m_allItems.append(item);
    }
}

void PanelModel::loadArchiveDirectory()
{
    m_allItems.clear();

    const QFileInfo archiveFi(m_archiveFile);
    PanelItem parentItem;
    parentItem.name = "..";
    if (!m_archiveInternalPath.isEmpty()) {
        const int lastSlash = m_archiveInternalPath.lastIndexOf('/');
        const QString parentInternal = (lastSlash > 0) ? m_archiveInternalPath.left(lastSlash) : QString();
        parentItem.path = parentInternal.isEmpty() ? m_archiveFile : (m_archiveFile + "/" + parentInternal);
    } else {
        parentItem.path = archiveFi.absolutePath();
    }
    parentItem.isDir = true;
    parentItem.isParent = true;
    parentItem.formattedSize = "<UP>";
    parentItem.iconType = "folder-parent";
    m_allItems.append(parentItem);

    if (!archiveFi.exists() || !archiveFi.isFile())
        return;

    const QDateTime archiveMtime = archiveFi.lastModified();
    if (m_cachedArchiveFile != m_archiveFile || m_cachedArchiveMtime != archiveMtime) {
        m_cachedArchiveEntries = readArchiveEntries(m_archiveFile);
        m_cachedArchiveFile = m_archiveFile;
        m_cachedArchiveMtime = archiveMtime;
    }

    const QString prefix = m_archiveInternalPath.isEmpty() ? QString() : (m_archiveInternalPath + '/');
    QHash<QString, PanelItem> childDirs;
    QHash<QString, PanelItem> childFiles;

    for (const ArchiveEntryInfo &entry : m_cachedArchiveEntries) {
        if (!prefix.isEmpty() && !entry.internalPath.startsWith(prefix))
            continue;

        const QString rel = prefix.isEmpty() ? entry.internalPath : entry.internalPath.mid(prefix.size());
        if (rel.isEmpty())
            continue;
        if (!m_showHidden && hasHiddenSegment(rel))
            continue;

        if (m_flatView) {
            if (entry.isDir)
                continue;
            PanelItem item;
            item.name = rel;
            item.path = m_archiveFile + "/" + entry.internalPath;
            item.isDir = false;
            item.isParent = false;
            item.size = entry.size;
            item.formattedSize = formatSize(entry.size, false);
            item.modified = entry.modified;
            item.formattedModified = entry.modified.isValid() ? entry.modified.toString("yyyy-MM-dd hh:mm") : QString();
            item.extension = QFileInfo(rel).suffix();
            item.permissions = entry.permissions;
            item.iconType = detectIconTypeForName(QFileInfo(rel).fileName(), false, entry.isExecutable);
            item.isSelected = m_selectedPaths.contains(item.path);
            m_allItems.append(item);
            continue;
        }

        const int slash = rel.indexOf('/');
        if (slash == -1) {
            if (entry.isDir) {
                PanelItem &dirItem = childDirs[rel];
                if (dirItem.name.isEmpty()) {
                    dirItem.name = rel;
                    dirItem.path = m_archiveFile + "/" + entry.internalPath;
                    dirItem.isDir = true;
                    dirItem.iconType = QStringLiteral("folder");
                    dirItem.permissions = entry.permissions;
                    dirItem.modified = entry.modified;
                    dirItem.formattedModified = entry.modified.isValid() ? entry.modified.toString("yyyy-MM-dd hh:mm") : QString();
                    dirItem.formattedSize = formatSize(0, true);
                    dirItem.isSelected = m_selectedPaths.contains(dirItem.path);
                }
            } else {
                PanelItem fileItem;
                fileItem.name = rel;
                fileItem.path = m_archiveFile + "/" + entry.internalPath;
                fileItem.isDir = false;
                fileItem.size = entry.size;
                fileItem.formattedSize = formatSize(entry.size, false);
                fileItem.modified = entry.modified;
                fileItem.formattedModified = entry.modified.isValid() ? entry.modified.toString("yyyy-MM-dd hh:mm") : QString();
                fileItem.extension = QFileInfo(rel).suffix();
                fileItem.permissions = entry.permissions;
                fileItem.iconType = detectIconTypeForName(rel, false, entry.isExecutable);
                fileItem.isSelected = m_selectedPaths.contains(fileItem.path);
                childFiles.insert(rel, fileItem);
            }
        } else {
            const QString dirName = rel.left(slash);
            const QString dirInternalPath = prefix + dirName;
            PanelItem &dirItem = childDirs[dirName];
            if (dirItem.name.isEmpty()) {
                dirItem.name = dirName;
                dirItem.path = m_archiveFile + "/" + dirInternalPath;
                dirItem.isDir = true;
                dirItem.iconType = QStringLiteral("folder");
                dirItem.permissions = QStringLiteral("rwxr-xr-x");
                dirItem.formattedSize = formatSize(0, true);
                dirItem.isSelected = m_selectedPaths.contains(dirItem.path);
            }
            if (!entry.isDir) {
                dirItem.size += entry.size;
                dirItem.dirSizeCalculated = true;
                dirItem.formattedSize = formatSize(dirItem.size, false);
            }
            if (entry.modified.isValid() && (!dirItem.modified.isValid() || entry.modified > dirItem.modified)) {
                dirItem.modified = entry.modified;
                dirItem.formattedModified = entry.modified.toString("yyyy-MM-dd hh:mm");
            }
        }
    }

    for (auto it = childDirs.constBegin(); it != childDirs.constEnd(); ++it)
        m_allItems.append(it.value());
    for (auto it = childFiles.constBegin(); it != childFiles.constEnd(); ++it)
        m_allItems.append(it.value());
}

void PanelModel::sortItems()
{
    beginResetModel();

    QList<PanelItem> dirs;
    QList<PanelItem> files;
    PanelItem parentItem;
    bool hasParent = false;

    for (const auto &item : m_allItems) {
        if (item.isParent) {
            parentItem = item;
            hasParent = true;
        } else if (item.isDir) {
            dirs.append(item);
        } else {
            files.append(item);
        }
    }

    auto comparator = [this](const PanelItem &a, const PanelItem &b) -> bool {
        bool result = false;
        switch (m_sortField) {
        case SortByName:
            result = QString::localeAwareCompare(a.name.toLower(), b.name.toLower()) < 0;
            break;
        case SortByExt:
            if (a.extension == b.extension)
                result = QString::localeAwareCompare(a.name.toLower(), b.name.toLower()) < 0;
            else
                result = QString::localeAwareCompare(a.extension.toLower(), b.extension.toLower()) < 0;
            break;
        case SortBySize:
            if (a.size == b.size)
                result = QString::localeAwareCompare(a.name.toLower(), b.name.toLower()) < 0;
            else
                result = a.size < b.size;
            break;
        case SortByDate:
            if (a.modified == b.modified)
                result = QString::localeAwareCompare(a.name.toLower(), b.name.toLower()) < 0;
            else
                result = a.modified < b.modified;
            break;
        default:
            result = QString::localeAwareCompare(a.name.toLower(), b.name.toLower()) < 0;
            break;
        }
        return m_sortAscending ? result : !result;
    };

    m_allItems.clear();
    if (hasParent)
        m_allItems.append(parentItem);

    if (m_diskUsageMode && m_sortField == SortBySize) {
        // Rank directories and files together by size so large files surface above empty folders
        QList<PanelItem> combined;
        combined.reserve(dirs.size() + files.size());
        combined.append(dirs);
        combined.append(files);
        std::sort(combined.begin(), combined.end(), comparator);
        m_allItems.append(combined);
    } else {
        std::sort(dirs.begin(), dirs.end(), comparator);
        std::sort(files.begin(), files.end(), comparator);
        m_allItems.append(dirs);
        m_allItems.append(files);
    }

    if (m_filter.trimmed().isEmpty()) {
        m_items = m_allItems;
    } else {
        m_items.clear();
        const QString lower = m_filter.trimmed().toLower();
        for (const auto &item : m_allItems) {
            if (item.isParent || item.name.toLower().contains(lower)) {
                m_items.append(item);
            }
        }
    }

    recalculateSizeMetrics();
    endResetModel();
    emit countChanged();
}
