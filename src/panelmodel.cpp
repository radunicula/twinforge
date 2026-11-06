#include "panelmodel.h"

#include <algorithm>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QLocale>

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
    roles[IsSelectedRole] = "isSelected";
    return roles;
}

void PanelModel::setPath(const QString &newPath)
{
    QString expanded = newPath.trimmed();
    if (expanded == "~") {
        expanded = QDir::homePath();
    } else if (expanded.startsWith("~/")) {
        expanded = QDir::homePath() + expanded.mid(1);
    }

    QDir dir(expanded);
    if (!dir.exists())
        return;

    QString cleanPath = dir.canonicalPath();
    if (cleanPath.isEmpty())
        cleanPath = dir.absolutePath();

    if (m_path == cleanPath)
        return;

    if (!m_path.isEmpty() && !m_navigatingHistory) {
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

    m_selectedPaths.clear();
    m_calculatedDirSizes.clear();
    if (!m_filter.isEmpty()) {
        m_filter.clear();
        emit filterChanged();
    }
    loadDirectory();
    emit pathChanged();
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
        perm += (p & QFile::ReadUser) ? 'r' : '-';
        perm += (p & QFile::WriteUser) ? 'w' : '-';
        perm += (p & QFile::ExeUser) ? 'x' : '-';
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
