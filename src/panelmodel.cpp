#include "panelmodel.h"

#include <algorithm>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QLocale>
#include <QProcess>
#include <QRegularExpression>
#include <QUrl>
#include <QVariantMap>

PanelModel::PanelModel(const QString &initialPath, QObject *parent)
    : QAbstractListModel(parent)
{
    connect(&m_dirWatcher, &QFileSystemWatcher::directoryChanged, this, &PanelModel::refresh);

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
    return roles;
}

QString PanelModel::resolveDirectoryPath(const QString &rawPath)
{
    QString expanded = rawPath.trimmed();
    if (expanded == "~") {
        expanded = QDir::homePath();
    } else if (expanded.startsWith("~/")) {
        expanded = QDir::homePath() + expanded.mid(1);
    }
    if (expanded.isEmpty())
        return {};

    QDir dir(expanded);
    if (!dir.exists())
        return {};

    const QString canonical = dir.canonicalPath();
    return canonical.isEmpty() ? dir.absolutePath() : canonical;
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
    }
}

QVariantList PanelModel::tabs() const
{
    QVariantList out;
    out.reserve(m_tabs.size());
    for (int i = 0; i < m_tabs.size(); ++i) {
        const QString p = (i == m_activeTab && !m_path.isEmpty()) ? m_path : m_tabs.at(i).path;
        QVariantMap entry;
        entry["path"] = p;
        entry["title"] = tabTitleForPath(p);
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
    m_backStack = m_tabs.at(m_activeTab).backStack;
    m_forwardStack = m_tabs.at(m_activeTab).forwardStack;

    const QString targetPath = m_tabs.at(m_activeTab).path;
    m_switchingTab = true;
    if (m_path != targetPath) {
        setPath(targetPath);
    } else {
        m_selectedPaths.clear();
        if (!m_filter.isEmpty()) {
            m_filter.clear();
            emit filterChanged();
        }
        loadDirectory();
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

    m_tabs.append(PanelTab{target, {}, {}});
    m_activeTab = m_tabs.size() - 1;
    m_backStack.clear();
    m_forwardStack.clear();

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
        m_backStack = m_tabs.at(m_activeTab).backStack;
        m_forwardStack = m_tabs.at(m_activeTab).forwardStack;

        const QString nextPath = m_tabs.at(m_activeTab).path;
        m_switchingTab = true;
        if (m_path != nextPath) {
            setPath(nextPath);
        } else {
            m_selectedPaths.clear();
            loadDirectory();
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
            validTabs.append(PanelTab{resolved, {}, {}});
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

    if (m_path == cleanPath)
        return;

    if (!m_path.isEmpty() && !m_navigatingHistory && !m_switchingTab) {
        m_backStack.append(m_path);
        if (m_backStack.size() > 50)
            m_backStack.removeFirst();
        m_forwardStack.clear();
        emit historyChanged();
    }

    if (!m_dirWatcher.directories().isEmpty())
        m_dirWatcher.removePaths(m_dirWatcher.directories());

    m_path = cleanPath;
    if (QFileInfo::exists(m_path))
        m_dirWatcher.addPath(m_path);

    if (m_tabs.isEmpty()) {
        m_tabs.append(PanelTab{m_path, m_backStack, m_forwardStack});
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

    QFileInfo info(nameOrPath);
    if (!info.isAbsolute())
        info.setFile(m_path + "/" + nameOrPath);

    if (info.isDir()) {
        setPath(info.absoluteFilePath());
    }
}

void PanelModel::cdUp()
{
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

void PanelModel::calculateFolderSize(int index)
{
    if (index < 0 || index >= m_items.size())
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

    QModelIndex idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {SizeRole, FormattedSizeRole});
    emit selectionChanged();
}

void PanelModel::calculateAllFolderSizes()
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].isDir && !m_items[i].isParent) {
            calculateFolderSize(i);
        }
    }
    if (m_sortField == SortBySize) {
        sortItems();
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

    if (m_path.isEmpty() || !QDir(m_path).exists()) {
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
    return QFileInfo(m_path).isWritable();
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
    QStorageInfo storage(m_path);
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

QString PanelModel::detectIconType(const QFileInfo &info)
{
    if (info.isDir())
        return QStringLiteral("folder");

    const QString ext = info.suffix().toLower();
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
    if (info.isExecutable())
        return QStringLiteral("binary");

    return QStringLiteral("file");
}

void PanelModel::loadDirectory()
{
    QDir dir(m_path);
    QDir::Filters filters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::System;
    if (m_showHidden)
        filters |= QDir::Hidden;

    QFileInfoList entries = dir.entryInfoList(filters);

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

    for (const QFileInfo &fi : entries) {
        PanelItem item;
        item.name = fi.fileName();
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

        QFile::Permissions p = fi.permissions();
        QString perm;
        perm += (p & QFile::ReadOwner) ? 'r' : '-';
        perm += (p & QFile::WriteOwner) ? 'w' : '-';
        perm += (p & QFile::ExeOwner) ? 'x' : '-';
        perm += (p & QFile::ReadGroup) ? 'r' : '-';
        perm += (p & QFile::WriteGroup) ? 'w' : '-';
        perm += (p & QFile::ExeGroup) ? 'x' : '-';
        perm += (p & QFile::ReadOther) ? 'r' : '-';
        perm += (p & QFile::WriteOther) ? 'w' : '-';
        perm += (p & QFile::ExeOther) ? 'x' : '-';
        item.permissions = perm;

        m_allItems.append(item);
    }

    sortItems();
    updateGitStatus();
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

    std::sort(dirs.begin(), dirs.end(), comparator);
    std::sort(files.begin(), files.end(), comparator);

    m_allItems.clear();
    if (hasParent)
        m_allItems.append(parentItem);
    m_allItems.append(dirs);
    m_allItems.append(files);

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

    endResetModel();
    emit countChanged();
}
