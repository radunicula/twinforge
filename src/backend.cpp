#include <archive.h>
#include <archive_entry.h>

#include "backend.h"

#include <QClipboard>
#include <QColor>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QDrag>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontMetrics>
#include <QGuiApplication>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLocale>
#include <QMimeData>
#include <QMimeDatabase>
#include <QPainter>
#include <QPixmap>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTemporaryDir>
#include <QThread>
#include <QUrl>

#include <algorithm>
#include <sys/stat.h>

namespace {

bool itemExistsOrLink(const QFileInfo &fi)
{
    return fi.exists() || fi.isSymLink();
}

QString trashInfoForTrashFile(const QString &pathInTrash)
{
    const QFileInfo trashFi(pathInTrash);
    QDir dir = trashFi.dir();
    if (dir.dirName() != QLatin1String("files") || !dir.cdUp())
        return {};
    const QString candidate = dir.filePath(QStringLiteral("info/") + trashFi.fileName() + QStringLiteral(".trashinfo"));
    return QFileInfo::exists(candidate) ? candidate : QString();
}

bool isImageExtension(const QString &ext)
{
    const QString lower = ext.toLower();
    return lower == QLatin1String("png") || lower == QLatin1String("jpg") ||
           lower == QLatin1String("jpeg") || lower == QLatin1String("svg") ||
           lower == QLatin1String("webp") || lower == QLatin1String("gif");
}

QString computeFileSha256Hex(const QString &filePath, bool quickPrehash = false)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return {};

    QCryptographicHash hasher(QCryptographicHash::Sha256);
    if (quickPrehash && f.size() > 32768) {
        hasher.addData(f.read(16384));
        if (f.seek(f.size() - 16384))
            hasher.addData(f.read(16384));
        return QString::fromLatin1(hasher.result().toHex());
    }

    char buf[65536];
    qint64 bytesRead = 0;
    while ((bytesRead = f.read(buf, sizeof(buf))) > 0)
        hasher.addData(QByteArrayView(buf, bytesRead));
    return QString::fromLatin1(hasher.result().toHex());
}

struct SearchSpec {
    QString nameQuery;
    QString contentQuery;
    bool caseSensitive = false;
    bool useRegex = false;
    bool includeHidden = true;
    QString typeFilter = QStringLiteral("all"); // "all", "files", "dirs"
    qint64 minSizeBytes = 0;
    qint64 maxSizeBytes = -1;
    int modifiedWithinDays = 0;
    int maxResults = 1000;
};

SearchSpec parseSearchOptions(const QVariantMap &options)
{
    SearchSpec spec;
    spec.nameQuery = options.value(QStringLiteral("nameQuery")).toString().trimmed();
    spec.contentQuery = options.value(QStringLiteral("contentQuery")).toString();
    spec.caseSensitive = options.value(QStringLiteral("caseSensitive"), false).toBool();
    spec.useRegex = options.value(QStringLiteral("useRegex"), false).toBool();
    spec.includeHidden = options.value(QStringLiteral("includeHidden"), true).toBool();
    spec.typeFilter = options.value(QStringLiteral("typeFilter"), QStringLiteral("all")).toString();
    spec.minSizeBytes = options.value(QStringLiteral("minSizeBytes"), 0).toLongLong();
    spec.maxSizeBytes = options.value(QStringLiteral("maxSizeBytes"), -1).toLongLong();
    spec.modifiedWithinDays = options.value(QStringLiteral("modifiedWithinDays"), 0).toInt();
    spec.maxResults = std::max(1, options.value(QStringLiteral("maxResults"), 1000).toInt());
    return spec;
}

bool searchFileContent(const QString &filePath, const SearchSpec &spec, const QRegularExpression &contentRe,
                       std::atomic<bool> *cancelFlag, int *outLine, QString *outPreview)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return false;

    const QByteArray head = f.peek(4096);
    if (head.contains('\0'))
        return false;

    const Qt::CaseSensitivity cs = spec.caseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive;
    const bool useRe = contentRe.isValid() && spec.useRegex;
    int lineNum = 0;

    while (!f.atEnd()) {
        if (cancelFlag && (lineNum & 127) == 0 && cancelFlag->load(std::memory_order_relaxed))
            return false;

        QByteArray raw = f.readLine(65536);
        ++lineNum;
        if (raw.contains('\0'))
            return false;

        while (raw.endsWith('\n') || raw.endsWith('\r'))
            raw.chop(1);

        const QString line = QString::fromUtf8(raw);
        const bool hit = useRe ? contentRe.match(line).hasMatch() : line.contains(spec.contentQuery, cs);
        if (hit) {
            if (outLine)
                *outLine = lineNum;
            if (outPreview) {
                QString preview = line.trimmed();
                if (preview.size() > 140)
                    preview = preview.left(139) + QStringLiteral("…");
                *outPreview = preview;
            }
            return true;
        }
    }
    return false;
}

template <typename ProgressFn>
QVariantList runSearchImpl(const QString &rootPath, const SearchSpec &spec,
                           std::atomic<bool> *cancelFlag, ProgressFn onProgress,
                           int *outScanned = nullptr)
{
    QVariantList allResults;
    if (rootPath.isEmpty() || !QFileInfo(rootPath).isDir())
        return allResults;

    const Qt::CaseSensitivity cs = spec.caseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive;
    const QRegularExpression::PatternOptions reOpts =
        spec.caseSensitive ? QRegularExpression::NoPatternOption : QRegularExpression::CaseInsensitiveOption;

    QRegularExpression nameRe;
    bool useNameRe = false;
    if (!spec.nameQuery.isEmpty()) {
        if (spec.useRegex) {
            nameRe = QRegularExpression(spec.nameQuery, reOpts);
            useNameRe = nameRe.isValid();
        } else if (spec.nameQuery.contains('*') || spec.nameQuery.contains('?')) {
            nameRe = QRegularExpression(QRegularExpression::wildcardToRegularExpression(spec.nameQuery), reOpts);
            useNameRe = nameRe.isValid();
        }
    }

    QRegularExpression contentRe;
    if (!spec.contentQuery.isEmpty() && spec.useRegex)
        contentRe = QRegularExpression(spec.contentQuery, reOpts);

    const bool hasContentQuery = !spec.contentQuery.isEmpty();
    const bool onlyFiles = hasContentQuery || spec.typeFilter == QLatin1String("files")
                           || spec.minSizeBytes > 0 || spec.maxSizeBytes >= 0;
    const bool onlyDirs = !hasContentQuery && spec.typeFilter == QLatin1String("dirs");
    const QDateTime mtimeCutoff = (spec.modifiedWithinDays > 0)
                                      ? QDateTime::currentDateTime().addDays(-spec.modifiedWithinDays)
                                      : QDateTime();

    QDir::Filters entryFilters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::System;
    if (spec.includeHidden)
        entryFilters |= QDir::Hidden;

    const QDir rootDir(rootPath);
    QStringList queue{rootDir.absolutePath()};
    QVariantList pendingBatch;
    int scanned = 0;

    while (!queue.isEmpty() && allResults.size() < spec.maxResults) {
        if (cancelFlag && cancelFlag->load(std::memory_order_relaxed))
            break;

        const QString dirPath = queue.takeFirst();
        const QFileInfoList entries = QDir(dirPath).entryInfoList(entryFilters);
        for (const QFileInfo &fi : entries) {
            if (cancelFlag && cancelFlag->load(std::memory_order_relaxed))
                break;

            const bool isDir = fi.isDir();
            if (isDir && !fi.isSymLink())
                queue.append(fi.absoluteFilePath());

            ++scanned;
            if ((scanned % 60) == 0 && (!pendingBatch.isEmpty() || (scanned % 240) == 0)) {
                onProgress(scanned, pendingBatch);
                pendingBatch.clear();
            }

            if (onlyFiles && isDir)
                continue;
            if (onlyDirs && !isDir)
                continue;

            const QString fileName = fi.fileName();
            if (!spec.nameQuery.isEmpty()) {
                const bool nameMatched = useNameRe ? nameRe.match(fileName).hasMatch()
                                                   : fileName.contains(spec.nameQuery, cs);
                if (!nameMatched)
                    continue;
            }

            const qint64 sz = isDir ? 0 : fi.size();
            if (spec.minSizeBytes > 0 && sz < spec.minSizeBytes)
                continue;
            if (spec.maxSizeBytes >= 0 && sz > spec.maxSizeBytes)
                continue;
            if (mtimeCutoff.isValid() && fi.lastModified() < mtimeCutoff)
                continue;

            int matchLine = 0;
            QString matchPreview;
            if (hasContentQuery) {
                constexpr qint64 kMaxSearchFileBytes = 64LL * 1024 * 1024;
                if (isDir || sz > kMaxSearchFileBytes)
                    continue;
                if (!searchFileContent(fi.absoluteFilePath(), spec, contentRe, cancelFlag, &matchLine, &matchPreview))
                    continue;
            }

            QVariantMap row;
            row[QStringLiteral("path")] = fi.absoluteFilePath();
            row[QStringLiteral("name")] = fileName;
            row[QStringLiteral("relPath")] = rootDir.relativeFilePath(fi.absoluteFilePath());
            row[QStringLiteral("isDir")] = isDir;
            row[QStringLiteral("size")] = sz;
            row[QStringLiteral("formattedSize")] = PanelModel::formatSize(sz, isDir);
            row[QStringLiteral("modified")] = fi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"));
            row[QStringLiteral("matchLine")] = matchLine;
            row[QStringLiteral("matchPreview")] = matchPreview;
            allResults.append(row);
            pendingBatch.append(row);

            if (pendingBatch.size() >= 15) {
                onProgress(scanned, pendingBatch);
                pendingBatch.clear();
            }
            if (allResults.size() >= spec.maxResults)
                break;
        }
    }

    if (!pendingBatch.isEmpty())
        onProgress(scanned, pendingBatch);
    if (outScanned)
        *outScanned = scanned;
    return allResults;
}

QHash<QString, QFileInfo> collectFilesRecursive(const QString &rootPath, bool includeHidden)
{
    QHash<QString, QFileInfo> files;
    const QDir rootDir(rootPath);
    if (rootPath.isEmpty() || !rootDir.exists())
        return files;

    QDir::Filters filters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot;
    if (includeHidden)
        filters |= QDir::Hidden;

    QStringList queue{rootDir.absolutePath()};
    while (!queue.isEmpty()) {
        const QString cur = queue.takeFirst();
        const QFileInfoList entries = QDir(cur).entryInfoList(filters);
        for (const QFileInfo &fi : entries) {
            if (fi.isDir()) {
                if (!fi.isSymLink())
                    queue.append(fi.absoluteFilePath());
            } else if (fi.isFile()) {
                const QString rel = rootDir.relativeFilePath(fi.absoluteFilePath());
                if (!includeHidden && rel.startsWith('.'))
                    continue;
                files.insert(rel, fi);
            }
        }
    }
    return files;
}

QString formatHexDumpText(const QByteArray &chunk, const QString &formattedSize, qint64 totalSize)
{
    const QByteArray sample = chunk.left(512);
    QString hexDump = QObject::tr("[Binary file — %1 (%2 bytes)]\n\n").arg(formattedSize).arg(totalSize);
    for (int offset = 0; offset < sample.size(); offset += 16) {
        QString hexPart;
        QString asciiPart;
        for (int j = 0; j < 16; ++j) {
            if (offset + j < sample.size()) {
                unsigned char c = static_cast<unsigned char>(sample.at(offset + j));
                hexPart += QString("%1 ").arg(c, 2, 16, QLatin1Char('0')).toUpper();
                asciiPart += (c >= 32 && c < 127) ? QChar(c) : QChar('.');
            } else {
                hexPart += "   ";
            }
            if (j == 7)
                hexPart += " ";
        }
        hexDump += QString("%1  %2 |%3|\n")
                       .arg(offset, 6, 16, QLatin1Char('0')).toUpper()
                       .arg(hexPart, asciiPart);
    }
    return hexDump;
}

QString normalizeArchiveEntryPath(struct archive_entry *entry, bool *outEndsWithSlash = nullptr)
{
    const char *utf8Name = archive_entry_pathname_utf8(entry);
    QString rawName = utf8Name ? QString::fromUtf8(utf8Name)
                               : QString::fromLocal8Bit(archive_entry_pathname(entry));
    if (outEndsWithSlash)
        *outEndsWithSlash = rawName.endsWith('/') || rawName.endsWith('\\');
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
    return safeParts.join('/');
}

bool streamArchiveToFile(struct archive *a, const QString &destPath, int perm)
{
    QFileInfo destFi(destPath);
    if (!QDir().mkpath(destFi.absolutePath()))
        return false;

    QFile out(destPath);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;

    const void *buff = nullptr;
    size_t size = 0;
    la_int64_t offset = 0;
    bool ok = true;

    while (true) {
        const int r = archive_read_data_block(a, &buff, &size, &offset);
        if (r == ARCHIVE_EOF)
            break;
        if (r < ARCHIVE_OK) {
            ok = false;
            break;
        }
        if (offset > out.pos()) {
            const qint64 gap = offset - out.pos();
            static const QByteArray zeros(4096, '\0');
            qint64 remaining = gap;
            while (remaining > 0) {
                const qint64 chunk = std::min<qint64>(remaining, zeros.size());
                if (out.write(zeros.constData(), chunk) != chunk) {
                    ok = false;
                    break;
                }
                remaining -= chunk;
            }
            if (!ok)
                break;
        }
        if (size > 0 && out.write(static_cast<const char *>(buff), static_cast<qint64>(size)) != static_cast<qint64>(size)) {
            ok = false;
            break;
        }
    }

    out.close();
    if (ok && perm > 0) {
        QFile::Permissions qp = QFile::ReadOwner | QFile::WriteOwner;
        if (perm & 0100) qp |= QFile::ExeOwner;
        if (perm & 0040) qp |= QFile::ReadGroup;
        if (perm & 0020) qp |= QFile::WriteGroup;
        if (perm & 0010) qp |= QFile::ExeGroup;
        if (perm & 0004) qp |= QFile::ReadOther;
        if (perm & 0002) qp |= QFile::WriteOther;
        if (perm & 0001) qp |= QFile::ExeOther;
        QFile::setPermissions(destPath, qp);
    }
    return ok;
}

bool anyPathInsideArchive(const QStringList &paths)
{
    QString arc, inner;
    for (const QString &p : paths) {
        if (PanelModel::splitArchivePath(p, &arc, &inner) && !inner.isEmpty())
            return true;
    }
    return false;
}

bool isArchiveTargetPath(const QString &targetDir)
{
    QString arc, inner;
    return PanelModel::splitArchivePath(targetDir, &arc, &inner);
}

} // namespace

Backend::Backend(const QString &bookmarksFile, QObject *parent)
    : QObject(parent),
      m_leftPanel(QDir::homePath()),
      m_rightPanel(QDir::homePath()),
      m_bookmarksFile(bookmarksFile.isEmpty() ? QDir::homePath() + "/.config/omapanel/bookmarks.json" : bookmarksFile),
      m_sessionFile(QFileInfo(m_bookmarksFile).dir().filePath("session.ini"))
{
    if (QDir(QDir::homePath() + "/Downloads").exists()) {
        m_rightPanel.setPath(QDir::homePath() + "/Downloads");
    }
    loadBookmarks();
    loadSession();
    refreshDrives();

    if (m_recentDirs.isEmpty()) {
        m_loadingSession = true;
        if (!m_leftPanel.isArchiveView())
            recordRecentDirectory(m_leftPanel.path());
        if (!m_rightPanel.isArchiveView())
            recordRecentDirectory(m_rightPanel.path());
        m_loadingSession = false;
    }

    auto connectPanelSession = [this](PanelModel *panel) {
        connect(panel, &PanelModel::pathChanged, this, [this, panel] {
            if (!panel->isArchiveView())
                recordRecentDirectory(panel->path());
            saveSession();
        });
        connect(panel, &PanelModel::tabsChanged, this, &Backend::saveSession);
        connect(panel, &PanelModel::sortChanged, this, &Backend::saveSession);
        connect(panel, &PanelModel::showHiddenChanged, this, &Backend::saveSession);
    };
    connectPanelSession(&m_leftPanel);
    connectPanelSession(&m_rightPanel);

    if (auto *clipboard = QGuiApplication::clipboard()) {
        connect(clipboard, &QClipboard::dataChanged, this, &Backend::refreshClipboardState);
        refreshClipboardState();
    }
}

Backend::~Backend()
{
    cancelSearch();
    saveSession();
    delete m_archiveTempDir;
    m_archiveTempDir = nullptr;
    if (m_fileOp) {
        m_fileOp->cancel();
        m_fileOpThread->wait();
        delete m_fileOpThread;
        delete m_fileOp;
    }
}

void Backend::setActivePanel(int index)
{
    if (index != 0 && index != 1)
        return;
    if (m_activePanel != index) {
        m_activePanel = index;
        emit activePanelChanged();
        saveSession();
    }
}

void Backend::setWindowWidth(int width)
{
    const int clamped = std::max(860, width);
    if (m_windowWidth != clamped) {
        m_windowWidth = clamped;
        emit windowSizeChanged();
        saveSession();
    }
}

void Backend::setWindowHeight(int height)
{
    const int clamped = std::max(540, height);
    if (m_windowHeight != clamped) {
        m_windowHeight = clamped;
        emit windowSizeChanged();
        saveSession();
    }
}

void Backend::setThemeMode(const QString &mode)
{
    const QString normalized = (mode.trimmed().compare(QLatin1String("light"), Qt::CaseInsensitive) == 0)
                                   ? QStringLiteral("light")
                                   : QStringLiteral("dark");
    if (m_themeMode != normalized) {
        m_themeMode = normalized;
        emit themeModeChanged();
        saveSession();
    }
}

void Backend::toggleThemeMode()
{
    setThemeMode(isDarkTheme() ? QStringLiteral("light") : QStringLiteral("dark"));
    showStatus(isDarkTheme() ? tr("Theme switched to Dark.") : tr("Theme switched to Light."));
}

PanelModel* Backend::activeModel()
{
    return (m_activePanel == 0) ? &m_leftPanel : &m_rightPanel;
}

PanelModel* Backend::targetModel()
{
    return (m_activePanel == 0) ? &m_rightPanel : &m_leftPanel;
}

void Backend::switchPanel()
{
    setActivePanel(m_activePanel == 0 ? 1 : 0);
}

void Backend::swapPanels()
{
    const QString leftPath = m_leftPanel.path();
    const QString rightPath = m_rightPanel.path();
    m_leftPanel.setPath(rightPath);
    m_rightPanel.setPath(leftPath);
    showStatus(tr("Panels swapped."));
}

void Backend::syncPanels()
{
    targetModel()->setPath(activeModel()->path());
    showStatus(tr("Target panel synced to %1").arg(activeModel()->path()));
}

void Backend::compareDirectories()
{
    m_leftPanel.selectDifferenceFrom(&m_rightPanel);
    m_rightPanel.selectDifferenceFrom(&m_leftPanel);
    const int leftDiff = m_leftPanel.selectedCount();
    const int rightDiff = m_rightPanel.selectedCount();
    showStatus(tr("Compare complete: %1 diff in left, %2 diff in right.").arg(leftDiff).arg(rightDiff));
}

void Backend::openItem(const QString &path)
{
    QString archiveFile;
    QString internalPath;
    if (PanelModel::splitArchivePath(path, &archiveFile, &internalPath)) {
        if (internalPath.isEmpty()) {
            activeModel()->setPath(archiveFile);
            showStatus(tr("Opened archive: %1").arg(QFileInfo(archiveFile).fileName()));
            return;
        }
        const QList<ArchiveEntryInfo> entries = PanelModel::readArchiveEntries(archiveFile);
        const QString childPrefix = internalPath + '/';
        for (const ArchiveEntryInfo &entry : entries) {
            if ((entry.internalPath == internalPath && entry.isDir) || entry.internalPath.startsWith(childPrefix)) {
                activeModel()->setPath(archiveFile + "/" + internalPath);
                return;
            }
        }
        const QString tempFile = extractArchiveEntryToTemp(archiveFile, internalPath);
        if (!tempFile.isEmpty()) {
            QDesktopServices::openUrl(QUrl::fromLocalFile(tempFile));
        }
        return;
    }

    QFileInfo info(path);
    if (!info.exists())
        return;

    if (info.isDir()) {
        activeModel()->cd(info.absoluteFilePath());
    } else if (isArchive(info.fileName())) {
        activeModel()->setPath(info.absoluteFilePath());
        showStatus(tr("Opened archive: %1").arg(info.fileName()));
    } else {
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    }
}

void Backend::openWithEditor(const QString &path)
{
    QString targetPath = path;
    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner) && !inner.isEmpty()) {
        targetPath = extractArchiveEntryToTemp(arc, inner);
        if (targetPath.isEmpty())
            return;
    }

    QFileInfo info(targetPath);
    if (!info.exists())
        return;

    QString editor = qEnvironmentVariable("EDITOR");
    if (!editor.isEmpty()) {
        QString terminal = QStandardPaths::findExecutable("xdg-terminal-exec");
        if (terminal.isEmpty())
            terminal = QStandardPaths::findExecutable("foot");
        if (terminal.isEmpty())
            terminal = QStandardPaths::findExecutable("alacritty");
        if (terminal.isEmpty())
            terminal = QStandardPaths::findExecutable("kitty");

        if (!terminal.isEmpty()) {
            QProcess::startDetached(terminal, {"-e", editor, targetPath});
            return;
        }
    }

    QDesktopServices::openUrl(QUrl::fromLocalFile(targetPath));
}

void Backend::openInTerminal(const QString &path)
{
    QString dirPath;
    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner)) {
        dirPath = QFileInfo(arc).absolutePath();
    } else {
        QFileInfo info(path);
        dirPath = info.isDir() ? info.absoluteFilePath() : info.absolutePath();
    }

    QString terminal = QStandardPaths::findExecutable("xdg-terminal-exec");
    if (terminal.isEmpty())
        terminal = QStandardPaths::findExecutable("foot");
    if (terminal.isEmpty())
        terminal = QStandardPaths::findExecutable("alacritty");
    if (terminal.isEmpty())
        terminal = QStandardPaths::findExecutable("kitty");
    if (terminal.isEmpty())
        terminal = "xterm";

    QProcess::startDetached(terminal, {}, dirPath);
}

bool Backend::startFileOperation(FileOperation::Mode mode, const QStringList &sourcePaths, const QString &targetDir)
{
    if (sourcePaths.isEmpty() || targetDir.isEmpty())
        return false;

    if (m_fileOp) {
        showStatus(tr("Another file operation is still running."));
        return false;
    }

    if (!QFileInfo(targetDir).isDir()) {
        showStatus(tr("Target folder does not exist: %1").arg(targetDir));
        return false;
    }

    m_fileOp = new FileOperation(mode, sourcePaths, targetDir);
    connect(m_fileOp, &FileOperation::progress, this, [this](qint64 done, qint64 total, const QString &name) {
        m_busyProgress = total > 0 ? static_cast<double>(done) / static_cast<double>(total) : 0.0;
        m_busyDetail = name;
        emit busyChanged();
    });
    connect(m_fileOp, &FileOperation::conflict, this, &Backend::conflictRequested);
    connect(m_fileOp, &FileOperation::finished, this, &Backend::onFileOperationFinished, Qt::QueuedConnection);

    FileOperation *op = m_fileOp;
    m_fileOpThread = QThread::create([op] { op->run(); });

    m_isBusy = true;
    m_canCancel = true;
    m_busyTitle = mode == FileOperation::Copy ? tr("Copying files...") : tr("Moving files...");
    m_busyProgress = 0.0;
    m_busyDetail.clear();
    emit busyChanged();

    m_fileOpThread->start();
    return true;
}

void Backend::onFileOperationFinished()
{
    if (!m_fileOp)
        return;

    m_fileOpThread->wait();
    const bool isCopy = m_fileOp->mode() == FileOperation::Copy;
    const bool cancelled = m_fileOp->wasCancelled();
    const int completed = m_fileOp->completedCount();
    const int skipped = m_fileOp->skippedCount();
    const int failed = m_fileOp->failedCount();
    const QStringList errors = m_fileOp->errors();
    const QList<QPair<QString, QString>> moved = m_fileOp->movedPairs();

    delete m_fileOpThread;
    delete m_fileOp;
    m_fileOpThread = nullptr;
    m_fileOp = nullptr;

    if (!isCopy && !moved.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Move;
        entry.description = moved.size() == 1
                                ? tr("Move %1").arg(QFileInfo(moved.first().second).fileName())
                                : tr("Move %1 item(s)").arg(moved.size());
        // Reverse order so nested/merged items unwind safely.
        for (int i = moved.size() - 1; i >= 0; --i)
            entry.pairs.append(UndoPair{moved.at(i).first, moved.at(i).second, {}});
        pushUndo(std::move(entry));
    }

    m_isBusy = false;
    m_canCancel = false;
    m_busyDetail.clear();
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    for (const QString &error : errors)
        qWarning("omapanel: %s", qPrintable(error));

    QString message;
    if (cancelled)
        message = isCopy ? tr("Copy cancelled.") : tr("Move cancelled.");
    else if (failed == 0 && skipped == 0)
        message = isCopy ? tr("Copy completed.") : tr("Move completed.");
    else
        message = tr("%1 done, %2 skipped, %3 failed.").arg(completed).arg(skipped).arg(failed);
    if (!errors.isEmpty())
        message += " " + errors.first();

    const bool success = !cancelled && failed == 0;
    showStatus(message);
    emit operationFinished(success, message);
}

bool Backend::copyItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (!sourcePaths.isEmpty()) {
        QString archiveFile;
        QString internalPath;
        if (PanelModel::splitArchivePath(sourcePaths.first(), &archiveFile, &internalPath) && !internalPath.isEmpty()) {
            return extractArchiveItems(archiveFile, sourcePaths, targetDir);
        }
    }
    if (isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    return startFileOperation(FileOperation::Copy, sourcePaths, targetDir);
}

bool Backend::moveItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (anyPathInsideArchive(sourcePaths) || isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    return startFileOperation(FileOperation::Move, sourcePaths, targetDir);
}

void Backend::cancelOperation()
{
    if (!m_fileOp)
        return;
    m_fileOp->cancel();
    m_canCancel = false;
    m_busyTitle = tr("Cancelling...");
    emit busyChanged();
}

void Backend::resolveConflict(int action, bool applyToAll)
{
    if (m_fileOp)
        m_fileOp->resolveConflict(action, applyToAll);
}

QString Backend::formatConflictDetails(qint64 size, const QDateTime &modified, bool isDir) const
{
    const QString sizeText = isDir ? tr("folder") : PanelModel::formatSize(size, false);
    return QString("%1  ·  %2").arg(sizeText, modified.toString("yyyy-MM-dd hh:mm:ss"));
}

bool Backend::deleteItems(const QStringList &paths, bool permanent)
{
    if (paths.isEmpty())
        return false;

    if (anyPathInsideArchive(paths)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (m_fileOp) {
        showStatus(tr("Another file operation is still running."));
        return false;
    }

    m_isBusy = true;
    m_busyTitle = tr("Deleting files...");
    emit busyChanged();

    bool success = true;
    QList<UndoPair> trashedPairs;

    for (const QString &path : paths) {
        QFileInfo fi(path);
        if (!itemExistsOrLink(fi))
            continue;

        bool deleted = false;
        if (!permanent) {
            QString pathInTrash;
            deleted = QFile::moveToTrash(fi.absoluteFilePath(), &pathInTrash);
            if (deleted && !pathInTrash.isEmpty()) {
                trashedPairs.append(UndoPair{pathInTrash, fi.absoluteFilePath(), trashInfoForTrashFile(pathInTrash)});
            }
        } else {
            if (fi.isDir() && !fi.isSymLink()) {
                deleted = QDir(fi.absoluteFilePath()).removeRecursively();
            } else {
                deleted = QFile::remove(fi.absoluteFilePath());
            }
        }

        if (!deleted)
            success = false;
    }

    if (!trashedPairs.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Trash;
        entry.description = trashedPairs.size() == 1
                                ? tr("Trash %1").arg(QFileInfo(trashedPairs.first().toPath).fileName())
                                : tr("Trash %1 item(s)").arg(trashedPairs.size());
        entry.pairs = trashedPairs;
        pushUndo(std::move(entry));
    }

    m_isBusy = false;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    if (!success && !permanent) {
        showStatus(tr("Could not move item(s) to Trash."));
    } else {
        showStatus(success ? tr("Delete completed.") : tr("Some files could not be deleted."));
    }
    emit operationFinished(success, success ? tr("Deleted successfully") : tr("Delete failed"));
    return success;
}

bool Backend::createDirectory(const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;

    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (name.contains(','))
        return createDirectories(name) > 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create folder in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return false;
    }

    bool ok = current.mkpath(name.trimmed());
    if (ok) {
        activeModel()->refresh();
        showStatus(tr("Folder created: %1").arg(name.trimmed()));
    } else {
        showStatus(tr("Failed to create folder '%1' in %2 (Permission denied)").arg(name.trimmed(), current.path()));
    }
    return ok;
}

int Backend::createDirectories(const QString &namesCsv)
{
    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return 0;
    }

    const QStringList parts = namesCsv.split(',', Qt::SkipEmptyParts);
    if (parts.isEmpty())
        return 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return 0;
    }

    int createdCount = 0;
    QStringList createdNames;
    QStringList failedNames;

    for (const QString &rawPart : parts) {
        const QString name = rawPart.trimmed();
        if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String(".."))
            continue;

        if (current.mkpath(name)) {
            createdCount++;
            createdNames.append(name);
        } else {
            failedNames.append(name);
        }
    }

    if (createdCount > 0) {
        activeModel()->refresh();
        if (failedNames.isEmpty()) {
            if (createdCount == 1) {
                showStatus(tr("Folder created: %1").arg(createdNames.first()));
            } else {
                showStatus(tr("%1 folders created: %2").arg(createdCount).arg(createdNames.join(QStringLiteral(", "))));
            }
        } else {
            showStatus(tr("%1 folders created (%2 failed): %3")
                           .arg(createdCount)
                           .arg(failedNames.size())
                           .arg(createdNames.join(QStringLiteral(", "))));
        }
    } else if (!failedNames.isEmpty()) {
        showStatus(tr("Failed to create folder(s) in %1 (Permission denied): %2")
                       .arg(current.path(), failedNames.join(QStringLiteral(", "))));
    }

    return createdCount;
}

bool Backend::createNewFile(const QString &fileName)
{
    if (fileName.trimmed().isEmpty())
        return false;

    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    if (fileName.contains(','))
        return createFiles(fileName) > 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return false;
    }

    const QString fullPath = current.filePath(fileName.trimmed());
    QFileInfo fi(fullPath);
    if (!fi.dir().exists()) {
        current.mkpath(fi.dir().path());
    }

    if (QFileInfo::exists(fullPath)) {
        openWithEditor(fullPath);
        return true;
    }

    QFile f(fullPath);
    if (!f.open(QIODevice::WriteOnly)) {
        showStatus(tr("Failed to create file '%1' in %2: %3").arg(fileName, current.path(), f.errorString()));
        return false;
    }
    f.close();

    activeModel()->refresh();
    showStatus(tr("File created: %1").arg(fileName));
    openWithEditor(fullPath);
    return true;
}

int Backend::createFiles(const QString &namesCsv)
{
    if (activeModel()->isArchiveView()) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return 0;
    }

    const QStringList parts = namesCsv.split(',', Qt::SkipEmptyParts);
    if (parts.isEmpty())
        return 0;

    QDir current(activeModel()->path());
    if (!QFileInfo(current.path()).isWritable()) {
        showStatus(tr("Cannot create in %1: Permission denied (Folder is read-only)").arg(current.path()));
        return 0;
    }

    int createdCount = 0;
    QStringList createdNames;
    QStringList failedNames;
    QString firstCreatedFullPath;
    QString lastError;

    for (const QString &rawPart : parts) {
        const QString name = rawPart.trimmed();
        if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String(".."))
            continue;

        const QString fullPath = current.filePath(name);
        QFileInfo fi(fullPath);
        if (!fi.dir().exists()) {
            current.mkpath(fi.dir().path());
        }

        if (fi.exists()) {
            createdCount++;
            createdNames.append(name);
            if (firstCreatedFullPath.isEmpty())
                firstCreatedFullPath = fullPath;
            continue;
        }

        QFile f(fullPath);
        if (f.open(QIODevice::WriteOnly)) {
            f.close();
            createdCount++;
            createdNames.append(name);
            if (firstCreatedFullPath.isEmpty())
                firstCreatedFullPath = fullPath;
        } else {
            failedNames.append(name);
            lastError = f.errorString();
        }
    }

    if (createdCount > 0) {
        activeModel()->refresh();
        if (failedNames.isEmpty()) {
            if (createdCount == 1) {
                showStatus(tr("File created: %1").arg(createdNames.first()));
                openWithEditor(firstCreatedFullPath);
            } else {
                showStatus(tr("%1 files created: %2").arg(createdCount).arg(createdNames.join(QStringLiteral(", "))));
            }
        } else {
            showStatus(tr("%1 files created (%2 failed): %3")
                           .arg(createdCount)
                           .arg(failedNames.size())
                           .arg(createdNames.join(QStringLiteral(", "))));
        }
    } else if (!failedNames.isEmpty()) {
        if (!lastError.isEmpty()) {
            showStatus(tr("Failed to create file(s) in %1 (%2): %3")
                           .arg(current.path(), lastError, failedNames.join(QStringLiteral(", "))));
        } else {
            showStatus(tr("Failed to create file(s) in %1 (Permission denied): %2")
                           .arg(current.path(), failedNames.join(QStringLiteral(", "))));
        }
    }

    return createdCount;
}

QString Backend::copyNamesAsCsv(const QStringList &paths)
{
    QStringList resolvedPaths = paths;
    if (resolvedPaths.isEmpty()) {
        resolvedPaths = activeModel()->selectedPaths();
        if (resolvedPaths.isEmpty()) {
            resolvedPaths = activeModel()->allItemPaths(true);
        }
    }

    QStringList names;
    names.reserve(resolvedPaths.size());
    for (const QString &p : resolvedPaths) {
        const QString fn = QFileInfo(p).fileName();
        if (!fn.isEmpty() && fn != QLatin1String(".."))
            names.append(fn);
    }

    if (names.isEmpty()) {
        showStatus(tr("No files or folders to copy as text."));
        return {};
    }

    const QString csvText = names.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 name(s) as text to clipboard: %2")
                   .arg(names.size())
                   .arg(csvText.length() > 60 ? csvText.left(57) + QStringLiteral("...") : csvText));
    return csvText;
}

QString Backend::copyPathsAsCsv(const QStringList &paths)
{
    QStringList resolvedPaths = paths;
    if (resolvedPaths.isEmpty()) {
        resolvedPaths = activeModel()->selectedPaths();
        if (resolvedPaths.isEmpty()) {
            resolvedPaths = activeModel()->allItemPaths(true);
        }
    }

    QStringList validPaths;
    validPaths.reserve(resolvedPaths.size());
    for (const QString &p : resolvedPaths) {
        if (!p.isEmpty() && QFileInfo(p).fileName() != QLatin1String(".."))
            validPaths.append(p);
    }

    if (validPaths.isEmpty()) {
        showStatus(tr("No files or folders to copy as text."));
        return {};
    }

    const QString csvText = validPaths.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 path(s) as text to clipboard").arg(validPaths.size()));
    return csvText;
}

QString Backend::copyFolderContentsAsCsv(const QString &dirPath, bool fullPaths)
{
    const QString target = dirPath.isEmpty() ? activeModel()->path() : dirPath;
    QDir dir(target);
    const QFileInfoList entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot, QDir::DirsFirst | QDir::Name);

    QStringList list;
    list.reserve(entries.size());
    for (const QFileInfo &fi : entries) {
        list.append(fullPaths ? fi.absoluteFilePath() : fi.fileName());
    }

    if (list.isEmpty()) {
        showStatus(tr("Folder is empty."));
        return {};
    }

    const QString csvText = list.join(QStringLiteral(", "));
    auto *cb = QGuiApplication::clipboard();
    if (cb) {
        cb->setText(csvText);
    }

    showStatus(tr("Copied %1 item(s) from %2 to clipboard")
                   .arg(list.size())
                   .arg(QFileInfo(target).fileName()));
    return csvText;
}

bool Backend::createSymlink(const QString &sourcePath, const QString &linkDir, const QString &linkName)
{
    QFileInfo srcFi(sourcePath);
    if (!srcFi.exists() && !srcFi.isSymLink()) {
        showStatus(tr("Source file does not exist."));
        return false;
    }

    const QString destDir = linkDir.isEmpty() ? targetModel()->path() : linkDir;
    QDir dir(destDir);
    if (!dir.exists()) {
        showStatus(tr("Destination folder does not exist."));
        return false;
    }

    const QString finalName = linkName.trimmed().isEmpty() ? srcFi.fileName() : linkName.trimmed();
    const QString destPath = dir.filePath(finalName);
    if (QFileInfo::exists(destPath) || QFileInfo(destPath).isSymLink()) {
        showStatus(tr("A file named \"%1\" already exists at destination.").arg(finalName));
        return false;
    }

    bool ok = QFile::link(srcFi.absoluteFilePath(), destPath);
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Created symlink: %1 → %2").arg(finalName, srcFi.fileName())
                  : tr("Failed to create symlink."));
    return ok;
}

bool Backend::createSymlinks(const QStringList &sourcePaths, const QString &linkDir)
{
    if (sourcePaths.isEmpty())
        return false;
    int created = 0;
    for (const QString &src : sourcePaths) {
        if (createSymlink(src, linkDir))
            ++created;
    }
    return created > 0;
}

bool Backend::renameItem(const QString &oldPath, const QString &newName)
{
    if (oldPath.isEmpty() || newName.trimmed().isEmpty())
        return false;

    if (anyPathInsideArchive({oldPath})) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    QFileInfo oldFi(oldPath);
    if (!itemExistsOrLink(oldFi))
        return false;

    const QString absOld = oldFi.absoluteFilePath();
    const QString newPath = oldFi.dir().filePath(newName.trimmed());
    if (absOld == newPath)
        return true;

    if (itemExistsOrLink(QFileInfo(newPath))) {
        showStatus(tr("An item named \"%1\" already exists.").arg(newName.trimmed()));
        return false;
    }

    bool ok = QFile::rename(absOld, newPath);
    if (ok) {
        UndoEntry entry;
        entry.type = UndoEntry::Rename;
        entry.description = tr("Rename %1 → %2").arg(oldFi.fileName(), newName.trimmed());
        entry.pairs.append(UndoPair{newPath, absOld, {}});
        pushUndo(std::move(entry));

        m_leftPanel.refresh();
        m_rightPanel.refresh();
        showStatus(tr("Renamed to: %1").arg(newName));
    } else {
        showStatus(tr("Failed to rename item."));
    }
    return ok;
}

void Backend::pushUndo(UndoEntry entry)
{
    if (entry.pairs.isEmpty())
        return;
    m_undoStack.append(std::move(entry));
    while (m_undoStack.size() > 25)
        m_undoStack.removeFirst();
    emit undoChanged();
}

bool Backend::undoLastOperation()
{
    if (m_fileOp) {
        showStatus(tr("Another file operation is still running."));
        return false;
    }
    if (m_undoStack.isEmpty()) {
        showStatus(tr("Nothing to undo."));
        return false;
    }

    const UndoEntry entry = m_undoStack.takeLast();
    emit undoChanged();

    int restored = 0;
    for (const UndoPair &pair : entry.pairs) {
        if (!itemExistsOrLink(QFileInfo(pair.fromPath)))
            continue;
        if (itemExistsOrLink(QFileInfo(pair.toPath)))
            continue;

        if (FileOperation::moveSinglePath(pair.fromPath, pair.toPath)) {
            if (!pair.trashInfoPath.isEmpty())
                QFile::remove(pair.trashInfoPath);
            ++restored;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const bool ok = restored == entry.pairs.size();
    if (ok) {
        showStatus(tr("Undone: %1").arg(entry.description));
    } else {
        showStatus(tr("Undo partially completed (%1/%2): %3")
                       .arg(restored)
                       .arg(entry.pairs.size())
                       .arg(entry.description));
    }
    emit operationFinished(ok, m_statusMessage);
    return ok;
}

bool Backend::setClipboardFiles(const QStringList &paths, bool cut)
{
    QList<QUrl> urls;
    QByteArray gnomePayload = cut ? QByteArray("cut") : QByteArray("copy");

    for (const QString &p : paths) {
        const QFileInfo fi(p);
        if (!itemExistsOrLink(fi))
            continue;
        const QUrl url = QUrl::fromLocalFile(fi.absoluteFilePath());
        urls.append(url);
        gnomePayload.append('\n');
        gnomePayload.append(url.toEncoded());
    }

    if (urls.isEmpty())
        return false;

    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return false;

    auto *mime = new QMimeData();
    mime->setUrls(urls);
    mime->setData(QStringLiteral("x-special/gnome-copied-files"), gnomePayload);
    mime->setData(QStringLiteral("application/x-kde-cutselection"), cut ? QByteArray("1") : QByteArray("0"));
    clipboard->setMimeData(mime);

    refreshClipboardState();
    showStatus(cut ? tr("Cut %1 item(s) to clipboard.").arg(urls.size())
                   : tr("Copied %1 item(s) to clipboard.").arg(urls.size()));
    return true;
}

bool Backend::copyToClipboard(const QStringList &paths)
{
    return setClipboardFiles(paths, false);
}

bool Backend::cutToClipboard(const QStringList &paths)
{
    return setClipboardFiles(paths, true);
}

bool Backend::parseClipboardMime(const QMimeData *mime, QStringList &outPaths, bool &outIsCut)
{
    outPaths.clear();
    outIsCut = false;
    if (!mime)
        return false;

    if (mime->hasFormat(QStringLiteral("x-special/gnome-copied-files"))) {
        const QList<QByteArray> lines = mime->data(QStringLiteral("x-special/gnome-copied-files")).split('\n');
        if (!lines.isEmpty()) {
            const QByteArray header = lines.first().trimmed();
            outIsCut = (header == "cut");
            for (int i = 1; i < lines.size(); ++i) {
                const QByteArray raw = lines.at(i).trimmed();
                if (raw.isEmpty())
                    continue;
                const QUrl url = QUrl::fromEncoded(raw);
                const QString local = url.isLocalFile() ? url.toLocalFile() : QString::fromUtf8(raw);
                if (!local.isEmpty() && itemExistsOrLink(QFileInfo(local)))
                    outPaths.append(QFileInfo(local).absoluteFilePath());
            }
            if (!outPaths.isEmpty())
                return true;
        }
    }

    if (mime->hasFormat(QStringLiteral("application/x-kde-cutselection"))) {
        outIsCut = mime->data(QStringLiteral("application/x-kde-cutselection")).trimmed() == "1";
    }

    if (mime->hasUrls()) {
        for (const QUrl &url : mime->urls()) {
            if (!url.isLocalFile())
                continue;
            const QString local = url.toLocalFile();
            if (!local.isEmpty() && itemExistsOrLink(QFileInfo(local)))
                outPaths.append(QFileInfo(local).absoluteFilePath());
        }
    }

    return !outPaths.isEmpty();
}

void Backend::refreshClipboardState()
{
    QStringList paths;
    bool isCut = false;
    if (auto *clipboard = QGuiApplication::clipboard())
        parseClipboardMime(clipboard->mimeData(), paths, isCut);

    if (paths != m_clipboardPaths || isCut != m_clipboardIsCut) {
        m_clipboardPaths = paths;
        m_clipboardIsCut = isCut;
        emit clipboardChanged();
    }
}

bool Backend::pasteFromClipboard(const QString &targetDir)
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return false;

    QStringList paths;
    bool isCut = false;
    if (!parseClipboardMime(clipboard->mimeData(), paths, isCut)) {
        showStatus(tr("Clipboard does not contain any files."));
        return false;
    }

    const QString dest = targetDir.isEmpty() ? activeModel()->path() : targetDir;
    if (isArchiveTargetPath(dest)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }
    if (isCut) {
        const bool started = moveItems(paths, dest);
        if (started) {
            clipboard->clear();
            refreshClipboardState();
        }
        return started;
    }
    return copyItems(paths, dest);
}

void Backend::startDrag(const QStringList &paths)
{
    QList<QUrl> urls;
    for (const QString &p : paths) {
        const QFileInfo fi(p);
        if (itemExistsOrLink(fi))
            urls.append(QUrl::fromLocalFile(fi.absoluteFilePath()));
    }
    if (urls.isEmpty())
        return;

    auto *drag = new QDrag(this);
    auto *mime = new QMimeData();
    mime->setUrls(urls);
    drag->setMimeData(mime);

    const QString label = urls.size() == 1
                              ? QFileInfo(urls.first().toLocalFile()).fileName()
                              : tr("%1 items").arg(urls.size());
    QFont font;
    font.setPixelSize(12);
    font.setBold(true);
    const QFontMetrics fm(font);
    const int w = std::clamp(fm.horizontalAdvance(label) + 28, 80, 280);
    const int h = 28;

    QPixmap pixmap(w, h);
    pixmap.fill(Qt::transparent);
    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setBrush(QColor("#161b2a"));
    painter.setPen(QColor("#7d82d9"));
    painter.drawRoundedRect(pixmap.rect().adjusted(1, 1, -1, -1), 5, 5);
    painter.setFont(font);
    painter.setPen(QColor("#f1f5f9"));
    painter.drawText(pixmap.rect().adjusted(12, 0, -12, 0),
                     Qt::AlignVCenter | Qt::AlignLeft,
                     fm.elidedText(label, Qt::ElideMiddle, w - 24));
    painter.end();

    drag->setPixmap(pixmap);
    drag->exec(Qt::CopyAction | Qt::MoveAction, Qt::CopyAction);
}

bool Backend::handleDrop(const QVariantList &urls, const QString &targetDir, bool move)
{
    if (urls.isEmpty() || targetDir.isEmpty())
        return false;

    if (isArchiveTargetPath(targetDir)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    const QFileInfo targetInfo(targetDir);
    if (!targetInfo.isDir())
        return false;
    const QString canonicalTarget = targetInfo.canonicalFilePath().isEmpty()
                                        ? QDir::cleanPath(targetInfo.absoluteFilePath())
                                        : targetInfo.canonicalFilePath();

    QStringList paths;
    for (const QVariant &v : urls) {
        QUrl url = v.toUrl();
        if (url.isEmpty() && v.typeId() == QMetaType::QString)
            url = QUrl::fromUserInput(v.toString());
        const QString local = url.isLocalFile() ? url.toLocalFile() : v.toString();
        const QFileInfo fi(local);
        if (!local.isEmpty() && itemExistsOrLink(fi)) {
            const QString parentCanonical = QDir(fi.absolutePath()).canonicalPath();
            const QString cleanParent = parentCanonical.isEmpty()
                                            ? QDir::cleanPath(fi.absolutePath())
                                            : parentCanonical;
            // Ignore accidental self-folder drops so small drags inside one folder don't duplicate files.
            if (cleanParent == canonicalTarget || fi.absoluteFilePath() == targetInfo.absoluteFilePath())
                continue;
            paths.append(fi.absoluteFilePath());
        }
    }

    if (paths.isEmpty())
        return false;

    return move ? moveItems(paths, targetInfo.absoluteFilePath())
                : copyItems(paths, targetInfo.absoluteFilePath());
}

QString Backend::formatSymbolicPermissions(int octalMode) const
{
    QString s(9, QLatin1Char('-'));
    if (octalMode & 0400) s[0] = QLatin1Char('r');
    if (octalMode & 0200) s[1] = QLatin1Char('w');
    if (octalMode & 0100) s[2] = QLatin1Char('x');
    if (octalMode & 0040) s[3] = QLatin1Char('r');
    if (octalMode & 0020) s[4] = QLatin1Char('w');
    if (octalMode & 0010) s[5] = QLatin1Char('x');
    if (octalMode & 0004) s[6] = QLatin1Char('r');
    if (octalMode & 0002) s[7] = QLatin1Char('w');
    if (octalMode & 0001) s[8] = QLatin1Char('x');
    return s;
}

QVariantMap Backend::calculateChecksums(const QString &filePath) const
{
    QVariantMap res;
    QFileInfo fi(filePath);
    if (!fi.exists() || fi.isDir())
        return res;

    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly))
        return res;

    QCryptographicHash md5(QCryptographicHash::Md5);
    QCryptographicHash sha1(QCryptographicHash::Sha1);
    QCryptographicHash sha256(QCryptographicHash::Sha256);

    char buf[65536];
    qint64 bytesRead = 0;
    while ((bytesRead = f.read(buf, sizeof(buf))) > 0) {
        const QByteArrayView view(buf, bytesRead);
        md5.addData(view);
        sha1.addData(view);
        sha256.addData(view);
    }

    res["filePath"] = fi.absoluteFilePath();
    res["fileName"] = fi.fileName();
    res["size"] = fi.size();
    res["formattedSize"] = PanelModel::formatSize(fi.size(), false);
    res["md5"] = QString::fromLatin1(md5.result().toHex());
    res["sha1"] = QString::fromLatin1(sha1.result().toHex());
    res["sha256"] = QString::fromLatin1(sha256.result().toHex());
    return res;
}

bool Backend::verifyChecksum(const QString &filePath, const QString &expectedHash) const
{
    const QString cleanExpected = expectedHash.trimmed().toLower();
    if (cleanExpected.isEmpty())
        return false;
    const QVariantMap sums = calculateChecksums(filePath);
    if (sums.isEmpty())
        return false;
    if (cleanExpected.length() == 32)
        return sums["md5"].toString() == cleanExpected;
    if (cleanExpected.length() == 40)
        return sums["sha1"].toString() == cleanExpected;
    if (cleanExpected.length() == 64)
        return sums["sha256"].toString() == cleanExpected;
    return sums["md5"].toString() == cleanExpected
        || sums["sha1"].toString() == cleanExpected
        || sums["sha256"].toString() == cleanExpected;
}

bool Backend::saveChecksumFile(const QString &filePath, const QString &algorithm, const QString &targetFilePath) const
{
    QFileInfo fi(filePath);
    if (!fi.exists() || fi.isDir())
        return false;
    const QVariantMap sums = calculateChecksums(filePath);
    if (sums.isEmpty())
        return false;

    const QString algo = algorithm.trimmed().toLower();
    const QString hash = (algo == "md5") ? sums["md5"].toString() : sums["sha256"].toString();
    const QString ext = (algo == "md5") ? ".md5" : ".sha256";

    QString outPath = targetFilePath.trimmed();
    if (outPath.isEmpty())
        outPath = fi.dir().filePath(fi.fileName() + ext);

    QFile f(outPath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    f.write(QString("%1  %2\n").arg(hash, fi.fileName()).toUtf8());
    f.close();

    const_cast<Backend*>(this)->m_leftPanel.refresh();
    const_cast<Backend*>(this)->m_rightPanel.refresh();
    const_cast<Backend*>(this)->showStatus(tr("Checksum file saved: %1").arg(QFileInfo(outPath).fileName()));
    return true;
}

QVariantMap Backend::verifyChecksumFile(const QString &checksumFilePath) const
{
    QVariantMap result;
    QFileInfo sumFi(checksumFilePath);
    if (!sumFi.exists()) {
        result["success"] = false;
        result["message"] = tr("Checksum file not found.");
        return result;
    }
    QFile f(checksumFilePath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result["success"] = false;
        result["message"] = tr("Could not read checksum file.");
        return result;
    }
    QDir dir = sumFi.dir();
    int total = 0;
    int matched = 0;
    int failed = 0;
    int missing = 0;
    QVariantList details;

    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        static const QRegularExpression rx(R"(^([a-fA-F0-9]{32,64})\s+[*]?(.+)$)");
        auto match = rx.match(line);
        if (match.hasMatch()) {
            const QString hash = match.captured(1).toLower();
            const QString relName = match.captured(2).trimmed();
            const QString targetPath = dir.filePath(relName);
            ++total;
            QVariantMap item;
            item["file"] = relName;
            item["expected"] = hash;
            if (!QFile::exists(targetPath)) {
                ++missing;
                item["status"] = "missing";
            } else if (verifyChecksum(targetPath, hash)) {
                ++matched;
                item["status"] = "ok";
            } else {
                ++failed;
                item["status"] = "mismatch";
            }
            details.append(item);
        }
    }
    result["success"] = (total > 0 && failed == 0 && missing == 0);
    result["total"] = total;
    result["matched"] = matched;
    result["failed"] = failed;
    result["missing"] = missing;
    result["details"] = details;
    result["message"] = tr("Checksum verification: %1/%2 matched (%3 failed, %4 missing).")
                            .arg(matched).arg(total).arg(failed).arg(missing);
    return result;
}

QVariantMap Backend::compareFiles(const QString &path1, const QString &path2) const
{
    QVariantMap res;
    QFileInfo fi1(path1);
    QFileInfo fi2(path2);
    if (!fi1.exists() || !fi2.exists() || fi1.isDir() || fi2.isDir()) {
        res["success"] = false;
        res["message"] = tr("Both paths must be existing files.");
        return res;
    }

    res["file1"] = fi1.absoluteFilePath();
    res["file2"] = fi2.absoluteFilePath();
    res["name1"] = fi1.fileName();
    res["name2"] = fi2.fileName();
    res["size1"] = fi1.size();
    res["size2"] = fi2.size();

    QFile f1(path1);
    QFile f2(path2);
    if (!f1.open(QIODevice::ReadOnly) || !f2.open(QIODevice::ReadOnly)) {
        res["success"] = false;
        res["message"] = tr("Could not read files.");
        return res;
    }

    const QByteArray head1 = f1.peek(4096);
    const QByteArray head2 = f2.peek(4096);
    bool isBinary = false;
    for (char c : head1) { if (c == '\0') { isBinary = true; break; } }
    if (!isBinary) {
        for (char c : head2) { if (c == '\0') { isBinary = true; break; } }
    }
    res["isBinary"] = isBinary;

    if (isBinary) {
        f1.seek(0);
        f2.seek(0);
        const bool same = (fi1.size() == fi2.size()) && (f1.readAll() == f2.readAll());
        res["success"] = true;
        res["isIdentical"] = same;
        res["differences"] = same ? 0 : 1;
        res["added"] = 0;
        res["deleted"] = 0;
        res["modified"] = same ? 0 : 1;
        res["rows"] = QVariantList();
        return res;
    }

    QStringList lines1;
    while (!f1.atEnd()) {
        QString l = QString::fromUtf8(f1.readLine());
        if (l.endsWith('\n')) l.chop(1);
        if (l.endsWith('\r')) l.chop(1);
        lines1.append(l);
    }
    QStringList lines2;
    while (!f2.atEnd()) {
        QString l = QString::fromUtf8(f2.readLine());
        if (l.endsWith('\n')) l.chop(1);
        if (l.endsWith('\r')) l.chop(1);
        lines2.append(l);
    }

    const int n = lines1.size();
    const int m = lines2.size();

    if (lines1 == lines2) {
        res["success"] = true;
        res["isIdentical"] = true;
        res["differences"] = 0;
        res["added"] = 0;
        res["deleted"] = 0;
        res["modified"] = 0;
        QVariantList rows;
        for (int idx = 0; idx < n; ++idx) {
            QVariantMap row;
            row["type"] = "equal";
            row["line1"] = idx + 1;
            row["text1"] = lines1[idx];
            row["line2"] = idx + 1;
            row["text2"] = lines2[idx];
            rows.append(row);
        }
        res["rows"] = rows;
        return res;
    }

    const int maxLines = 3000;
    if (n > maxLines || m > maxLines) {
        QVariantList rows;
        int diffCount = 0;
        const int limit = std::max(n, m);
        for (int idx = 0; idx < limit; ++idx) {
            QVariantMap row;
            const QString t1 = (idx < n) ? lines1[idx] : QString();
            const QString t2 = (idx < m) ? lines2[idx] : QString();
            if (idx >= n) {
                row["type"] = "added";
                row["line1"] = 0;
                row["text1"] = "";
                row["line2"] = idx + 1;
                row["text2"] = t2;
                ++diffCount;
            } else if (idx >= m) {
                row["type"] = "deleted";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = 0;
                row["text2"] = "";
                ++diffCount;
            } else if (t1 == t2) {
                row["type"] = "equal";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = idx + 1;
                row["text2"] = t2;
            } else {
                row["type"] = "modified";
                row["line1"] = idx + 1;
                row["text1"] = t1;
                row["line2"] = idx + 1;
                row["text2"] = t2;
                ++diffCount;
            }
            rows.append(row);
        }
        res["success"] = true;
        res["isIdentical"] = false;
        res["differences"] = diffCount;
        res["rows"] = rows;
        return res;
    }

    std::vector<std::vector<int>> dp(n + 1, std::vector<int>(m + 1, 0));
    for (int r = 0; r < n; ++r) {
        for (int c = 0; c < m; ++c) {
            if (lines1[r] == lines2[c])
                dp[r + 1][c + 1] = dp[r][c] + 1;
            else
                dp[r + 1][c + 1] = std::max(dp[r + 1][c], dp[r][c + 1]);
        }
    }

    struct RawEdit { int type; int idx1; int idx2; }; // 0: equal, 1: deleted, 2: added
    QList<RawEdit> edits;
    int r = n, c = m;
    while (r > 0 || c > 0) {
        if (r > 0 && c > 0 && lines1[r - 1] == lines2[c - 1]) {
            edits.prepend({0, r - 1, c - 1});
            --r; --c;
        } else if (c > 0 && (r == 0 || dp[r][c - 1] >= dp[r - 1][c])) {
            edits.prepend({2, -1, c - 1});
            --c;
        } else if (r > 0 && (c == 0 || dp[r][c - 1] < dp[r - 1][c])) {
            edits.prepend({1, r - 1, -1});
            --r;
        }
    }

    QVariantList rows;
    int addedCount = 0;
    int deletedCount = 0;
    int modifiedCount = 0;

    int editIdx = 0;
    while (editIdx < edits.size()) {
        const auto &e = edits[editIdx];
        if (e.type == 0) {
            QVariantMap row;
            row["type"] = "equal";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = e.idx2 + 1;
            row["text2"] = lines2[e.idx2];
            rows.append(row);
            ++editIdx;
        } else if (e.type == 1 && (editIdx + 1 < edits.size()) && edits[editIdx + 1].type == 2) {
            QVariantMap row;
            row["type"] = "modified";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = edits[editIdx + 1].idx2 + 1;
            row["text2"] = lines2[edits[editIdx + 1].idx2];
            rows.append(row);
            ++modifiedCount;
            editIdx += 2;
        } else if (e.type == 1) {
            QVariantMap row;
            row["type"] = "deleted";
            row["line1"] = e.idx1 + 1;
            row["text1"] = lines1[e.idx1];
            row["line2"] = 0;
            row["text2"] = "";
            rows.append(row);
            ++deletedCount;
            ++editIdx;
        } else {
            QVariantMap row;
            row["type"] = "added";
            row["line1"] = 0;
            row["text1"] = "";
            row["line2"] = e.idx2 + 1;
            row["text2"] = lines2[e.idx2];
            rows.append(row);
            ++addedCount;
            ++editIdx;
        }
    }

    res["success"] = true;
    res["isIdentical"] = (addedCount == 0 && deletedCount == 0 && modifiedCount == 0);
    res["differences"] = addedCount + deletedCount + modifiedCount;
    res["added"] = addedCount;
    res["deleted"] = deletedCount;
    res["modified"] = modifiedCount;
    res["rows"] = rows;
    return res;
}

QVariantMap Backend::getItemProperties(const QString &path) const
{
    QVariantMap props;
    const QFileInfo fi(path);
    if (!itemExistsOrLink(fi)) {
        props["exists"] = false;
        return props;
    }

    struct stat st{};
    const bool hasStat = (::lstat(QFile::encodeName(fi.absoluteFilePath()).constData(), &st) == 0);
    const int mode = hasStat ? static_cast<int>(st.st_mode & 0777) : 0644;

    const bool isSymLink = fi.isSymLink();
    const bool isRealDir = fi.isDir() && !isSymLink;

    QMimeDatabase mimeDb;
    const QMimeType mime = isRealDir
                               ? mimeDb.mimeTypeForName(QStringLiteral("inode/directory"))
                               : mimeDb.mimeTypeForFile(fi.absoluteFilePath(), QMimeDatabase::MatchDefault);

    qint64 totalBytes = isSymLink ? 0 : (isRealDir ? 0 : fi.size());
    int fileCount = 0;
    int dirCount = 0;
    if (isRealDir) {
        QDirIterator it(fi.absoluteFilePath(),
                        QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QFileInfo sub = it.fileInfo();
            if (sub.isSymLink()) {
                ++fileCount;
            } else if (sub.isDir()) {
                ++dirCount;
            } else {
                ++fileCount;
                totalBytes += sub.size();
            }
        }
    }

    const QString humanSize = PanelModel::formatSize(totalBytes, false);
    const QString exactBytes = QLocale().toString(totalBytes);

    props["exists"] = true;
    props["name"] = fi.fileName().isEmpty() ? QStringLiteral("/") : fi.fileName();
    props["path"] = fi.absoluteFilePath();
    props["parentPath"] = fi.absolutePath();
    props["isDir"] = isRealDir;
    props["isSymLink"] = isSymLink;
    props["symLinkTarget"] = isSymLink ? fi.readSymLink() : QString();
    props["mimeName"] = mime.name();
    props["mimeComment"] = mime.comment();
    props["size"] = totalBytes;
    props["formattedSize"] = QString("%1 (%2 B)").arg(humanSize, exactBytes);
    props["itemCounts"] = isRealDir ? tr("%1 files, %2 folders").arg(fileCount).arg(dirCount) : QString();
    props["owner"] = fi.owner().isEmpty() ? QString::number(fi.ownerId()) : fi.owner();
    props["group"] = fi.group().isEmpty() ? QString::number(fi.groupId()) : fi.group();
    props["created"] = fi.birthTime().isValid() ? fi.birthTime().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["modified"] = fi.lastModified().isValid() ? fi.lastModified().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["accessed"] = fi.lastRead().isValid() ? fi.lastRead().toString("yyyy-MM-dd hh:mm:ss") : QStringLiteral("—");
    props["mode"] = mode;
    props["octal"] = QString("0%1").arg(mode, 3, 8, QLatin1Char('0'));
    props["symbolic"] = formatSymbolicPermissions(mode);
    return props;
}

bool Backend::setItemPermissions(const QString &path, int octalMode, bool recursive)
{
    const QFileInfo fi(path);
    if (!itemExistsOrLink(fi))
        return false;

    const mode_t cleanMode = static_cast<mode_t>(octalMode & 0777);
    bool ok = true;

    if (!fi.isSymLink()) {
        if (::chmod(QFile::encodeName(fi.absoluteFilePath()).constData(), cleanMode) != 0)
            ok = false;
    }

    if (recursive && fi.isDir() && !fi.isSymLink()) {
        QDirIterator it(fi.absoluteFilePath(),
                        QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QFileInfo sub = it.fileInfo();
            if (sub.isSymLink())
                continue;
            if (::chmod(QFile::encodeName(sub.absoluteFilePath()).constData(), cleanMode) != 0)
                ok = false;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const QString octalStr = QString("0%1").arg(octalMode & 0777, 3, 8, QLatin1Char('0'));
    showStatus(ok ? tr("Permissions updated to %1 (%2).")
                        .arg(octalStr, formatSymbolicPermissions(octalMode & 0777))
                  : tr("Could not change permissions on some items."));
    return ok;
}

void Backend::loadSession()
{
    if (!QFileInfo::exists(m_sessionFile))
        return;

    m_loadingSession = true;
    QSettings settings(m_sessionFile, QSettings::IniFormat);

    m_windowWidth = std::max(860, settings.value("window/width", 1260).toInt());
    m_windowHeight = std::max(540, settings.value("window/height", 800).toInt());
    const int savedActive = settings.value("window/activePanel", 0).toInt();
    m_activePanel = (savedActive == 1) ? 1 : 0;
    const QString savedTheme = settings.value("window/themeMode", "dark").toString();
    m_themeMode = (savedTheme.compare(QLatin1String("light"), Qt::CaseInsensitive) == 0)
                      ? QStringLiteral("light")
                      : QStringLiteral("dark");

    auto restorePanel = [&settings](const QString &group, PanelModel &panel) {
        settings.beginGroup(group);
        panel.setShowHidden(settings.value("showHidden", false).toBool());
        const int sortField = std::clamp(settings.value("sortField", 0).toInt(), 0, 3);
        const bool sortAsc = settings.value("sortAscending", true).toBool();
        if (panel.sortField() != sortField)
            panel.setSortField(sortField);
        panel.setSortAscending(sortAsc);

        QStringList savedTabs = settings.value("tabs").toStringList();
        const QString singlePath = settings.value("path").toString();
        if (savedTabs.isEmpty() && !singlePath.isEmpty())
            savedTabs.append(singlePath);
        const int activeTab = settings.value("activeTab", 0).toInt();
        if (!savedTabs.isEmpty())
            panel.restoreTabs(savedTabs, activeTab);
        settings.endGroup();
    };

    restorePanel("leftPanel", m_leftPanel);
    restorePanel("rightPanel", m_rightPanel);

    m_recentDirs.clear();
    const QStringList savedRecent = settings.value("history/recentDirs").toStringList();
    for (const QString &rawDir : savedRecent) {
        const QFileInfo fi(rawDir);
        if (fi.isDir()) {
            const QString canon = fi.canonicalFilePath().isEmpty() ? fi.absoluteFilePath() : fi.canonicalFilePath();
            if (!m_recentDirs.contains(canon))
                m_recentDirs.append(canon);
        }
        if (m_recentDirs.size() >= 50)
            break;
    }

    m_loadingSession = false;
    emit recentDirectoriesChanged();
}

void Backend::saveSession() const
{
    if (m_loadingSession || m_sessionFile.isEmpty())
        return;

    QDir().mkpath(QFileInfo(m_sessionFile).absolutePath());
    QSettings settings(m_sessionFile, QSettings::IniFormat);

    settings.setValue("window/width", m_windowWidth);
    settings.setValue("window/height", m_windowHeight);
    settings.setValue("window/activePanel", m_activePanel);
    settings.setValue("window/themeMode", m_themeMode);
    settings.setValue("history/recentDirs", m_recentDirs);

    auto savePanel = [&settings](const QString &group, const PanelModel &panel) {
        settings.beginGroup(group);
        settings.setValue("path", panel.path());
        settings.setValue("tabs", panel.tabPaths());
        settings.setValue("activeTab", panel.activeTab());
        settings.setValue("sortField", panel.sortField());
        settings.setValue("sortAscending", panel.sortAscending());
        settings.setValue("showHidden", panel.showHidden());
        settings.endGroup();
    };

    savePanel("leftPanel", m_leftPanel);
    savePanel("rightPanel", m_rightPanel);
    settings.sync();
}

QString Backend::computeNewName(const QString &originalName, int index, const QString &findText,
                                const QString &replaceText, const QString &prefix,
                                const QString &suffix, int caseMode, bool addCounter)
{
    QFileInfo fi(originalName);
    QString base = fi.completeBaseName();
    QString ext = fi.suffix();
    if (base.isEmpty() && !ext.isEmpty()) {
        // Dotfile like .bashrc
        base = "." + ext;
        ext.clear();
    }

    if (!findText.isEmpty()) {
        base.replace(findText, replaceText, Qt::CaseInsensitive);
    }

    switch (caseMode) {
    case 1: // lowercase
        base = base.toLower();
        ext = ext.toLower();
        break;
    case 2: // UPPERCASE
        base = base.toUpper();
        ext = ext.toUpper();
        break;
    case 3: // Title Case
        if (!base.isEmpty()) {
            base = base.left(1).toUpper() + base.mid(1).toLower();
        }
        ext = ext.toLower();
        break;
    default:
        break;
    }

    QString result = prefix + base + suffix;
    if (addCounter) {
        result += QString("_%1").arg(index + 1, 3, 10, QLatin1Char('0'));
    }
    if (!ext.isEmpty()) {
        result += "." + ext;
    }
    return result;
}

QVariantList Backend::previewMultiRename(const QStringList &paths, const QString &findText,
                                         const QString &replaceText, const QString &prefix,
                                         const QString &suffix, int caseMode, bool addCounter) const
{
    QVariantList list;
    for (int i = 0; i < paths.size(); ++i) {
        QFileInfo fi(paths.at(i));
        QVariantMap entry;
        entry["oldPath"] = fi.absoluteFilePath();
        entry["oldName"] = fi.fileName();
        entry["newName"] = computeNewName(fi.fileName(), i, findText, replaceText, prefix, suffix, caseMode, addCounter);
        list.append(entry);
    }
    return list;
}

bool Backend::executeMultiRename(const QStringList &paths, const QString &findText,
                                 const QString &replaceText, const QString &prefix,
                                 const QString &suffix, int caseMode, bool addCounter)
{
    if (paths.isEmpty())
        return false;

    if (anyPathInsideArchive(paths)) {
        showStatus(tr("Archive view is read-only. Use F5 to extract files to the other panel."));
        return false;
    }

    int renamedCount = 0;
    QList<UndoPair> renamedPairs;

    for (int i = 0; i < paths.size(); ++i) {
        QFileInfo fi(paths.at(i));
        if (!itemExistsOrLink(fi))
            continue;
        const QString oldAbs = fi.absoluteFilePath();
        const QString newName = computeNewName(fi.fileName(), i, findText, replaceText, prefix, suffix, caseMode, addCounter);
        const QString newPath = fi.dir().filePath(newName);
        if (oldAbs == newPath) {
            ++renamedCount;
            continue;
        }
        if (itemExistsOrLink(QFileInfo(newPath)))
            continue;
        if (QFile::rename(oldAbs, newPath)) {
            renamedPairs.prepend(UndoPair{newPath, oldAbs, {}});
            ++renamedCount;
        }
    }

    if (!renamedPairs.isEmpty()) {
        UndoEntry entry;
        entry.type = UndoEntry::Rename;
        entry.description = tr("Multi-Rename %1 item(s)").arg(renamedPairs.size());
        entry.pairs = renamedPairs;
        pushUndo(std::move(entry));
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(tr("Multi-Rename: %1/%2 items renamed.").arg(renamedCount).arg(paths.size()));
    return renamedCount == paths.size();
}

bool Backend::isArchive(const QString &path) const
{
    return PanelModel::isArchiveFileName(path);
}

bool Backend::packArchive(const QStringList &sourcePaths, const QString &archivePath)
{
    if (sourcePaths.isEmpty() || archivePath.trimmed().isEmpty())
        return false;

    QFileInfo firstFi(sourcePaths.first());
    const QString workDir = firstFi.absolutePath();
    QStringList relativeNames;
    for (const QString &p : sourcePaths) {
        relativeNames.append(QFileInfo(p).fileName());
    }

    QString outArchive = archivePath.trimmed();
    if (QFileInfo(outArchive).isRelative()) {
        outArchive = QDir(targetModel()->path()).filePath(outArchive);
    }

    QProcess proc;
    proc.setWorkingDirectory(workDir);

    if (outArchive.endsWith(".zip", Qt::CaseInsensitive)) {
        const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
        const QString zipBin = QStandardPaths::findExecutable("zip");
        if (!zipBin.isEmpty()) {
            QStringList args = {"-r", outArchive};
            args.append(relativeNames);
            proc.start(zipBin, args);
        } else if (!bsdtar.isEmpty()) {
            QStringList args = {"-a", "-cf", outArchive};
            args.append(relativeNames);
            proc.start(bsdtar, args);
        } else {
            showStatus(tr("Missing zip or bsdtar tool."));
            return false;
        }
    } else {
        // Default to tar -caf
        QStringList args = {"-caf", outArchive};
        args.append(relativeNames);
        proc.start("tar", args);
    }

    bool ok = proc.waitForFinished(30000) && proc.exitCode() == 0;
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Created archive: %1").arg(QFileInfo(outArchive).fileName())
                  : tr("Failed to create archive."));
    return ok;
}

bool Backend::extractArchive(const QString &archivePath, const QString &targetDir)
{
    QFileInfo fi(archivePath);
    if (!fi.exists() || targetDir.isEmpty())
        return false;

    QDir(targetDir).mkpath(".");
    QProcess proc;
    proc.setWorkingDirectory(targetDir);

    const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
    if (!bsdtar.isEmpty()) {
        proc.start(bsdtar, {"-xf", fi.absoluteFilePath(), "-C", targetDir});
    } else if (archivePath.endsWith(".zip", Qt::CaseInsensitive)) {
        proc.start("unzip", {"-o", fi.absoluteFilePath(), "-d", targetDir});
    } else if (archivePath.endsWith(".7z", Qt::CaseInsensitive)) {
        proc.start("7z", {"x", "-y", fi.absoluteFilePath(), "-o" + targetDir});
    } else {
        proc.start("tar", {"-xf", fi.absoluteFilePath(), "-C", targetDir});
    }

    bool ok = proc.waitForFinished(30000) && proc.exitCode() == 0;
    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(ok ? tr("Extracted %1 to %2").arg(fi.fileName(), targetDir)
                  : tr("Failed to extract archive."));
    return ok;
}

bool Backend::extractArchiveItems(const QString &archivePath, const QStringList &sourcePaths, const QString &targetDir)
{
    QFileInfo arcFi(archivePath);
    if (!arcFi.isFile() || sourcePaths.isEmpty() || targetDir.trimmed().isEmpty())
        return false;

    const QString cleanArchive = arcFi.canonicalFilePath().isEmpty()
                                     ? arcFi.absoluteFilePath()
                                     : arcFi.canonicalFilePath();

    QDir().mkpath(targetDir);
    const QFileInfo targetFi(targetDir);
    if (!targetFi.isDir()) {
        showStatus(tr("Target folder does not exist: %1").arg(targetDir));
        return false;
    }
    const QString targetRoot = targetFi.canonicalFilePath().isEmpty()
                                   ? QDir::cleanPath(targetFi.absoluteFilePath())
                                   : targetFi.canonicalFilePath();
    const QString safePrefix = targetRoot.endsWith('/') ? targetRoot : (targetRoot + '/');

    struct ExtractTarget {
        QString internalPath;
        QString stripPrefix;
    };
    QList<ExtractTarget> targets;
    for (const QString &rawSource : sourcePaths) {
        QString selArchive;
        QString selInternal;
        if (PanelModel::splitArchivePath(rawSource, &selArchive, &selInternal)) {
            if (selArchive != cleanArchive || selInternal.isEmpty())
                continue;
        } else {
            selInternal = rawSource;
            selInternal.replace('\\', '/');
            while (selInternal.startsWith('/'))
                selInternal.remove(0, 1);
            while (selInternal.endsWith('/'))
                selInternal.chop(1);
            if (selInternal.isEmpty())
                continue;
        }
        const int lastSlash = selInternal.lastIndexOf('/');
        const QString strip = (lastSlash > 0) ? selInternal.left(lastSlash + 1) : QString();
        targets.append(ExtractTarget{selInternal, strip});
    }

    if (targets.isEmpty())
        return false;

    struct archive *a = archive_read_new();
    if (!a)
        return false;
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    const QByteArray encodedArchive = QFile::encodeName(cleanArchive);
    if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
        archive_read_free(a);
        showStatus(tr("Failed to open archive: %1").arg(arcFi.fileName()));
        return false;
    }

    int extractedCount = 0;
    struct archive_entry *entry = nullptr;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        bool endsWithSlash = false;
        const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
        if (entryPath.isEmpty()) {
            archive_read_data_skip(a);
            continue;
        }

        const ExtractTarget *matched = nullptr;
        for (const ExtractTarget &t : targets) {
            if (entryPath == t.internalPath || entryPath.startsWith(t.internalPath + '/')) {
                matched = &t;
                break;
            }
        }
        if (!matched) {
            archive_read_data_skip(a);
            continue;
        }

        const QString relOut = entryPath.mid(matched->stripPrefix.size());
        if (relOut.isEmpty() || relOut.contains(QLatin1String(".."))) {
            archive_read_data_skip(a);
            continue;
        }

        const QString cleanDest = QDir::cleanPath(safePrefix + relOut);
        if (!cleanDest.startsWith(safePrefix)) {
            archive_read_data_skip(a);
            continue;
        }

        const auto ftype = archive_entry_filetype(entry);
        if (ftype == AE_IFDIR || endsWithSlash) {
            if (QDir().mkpath(cleanDest))
                ++extractedCount;
            archive_read_data_skip(a);
        } else if (ftype == AE_IFLNK) {
            const char *symTarget = archive_entry_symlink(entry);
            if (symTarget && *symTarget) {
                QDir().mkpath(QFileInfo(cleanDest).absolutePath());
                QFile::remove(cleanDest);
                if (QFile::link(QString::fromUtf8(symTarget), cleanDest))
                    ++extractedCount;
            }
            archive_read_data_skip(a);
        } else {
            const int perm = static_cast<int>(archive_entry_perm(entry)) & 0777;
            if (streamArchiveToFile(a, cleanDest, perm > 0 ? perm : 0644))
                ++extractedCount;
        }
    }

    archive_read_free(a);
    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const bool ok = extractedCount > 0;
    const QString msg = ok
                            ? tr("Extracted %1 item(s) from %2 to %3").arg(extractedCount).arg(arcFi.fileName(), targetRoot)
                            : tr("No matching items extracted from %1.").arg(arcFi.fileName());
    showStatus(msg);
    emit operationFinished(ok, msg);
    return ok;
}

QString Backend::extractArchiveEntryToTemp(const QString &archivePath, const QString &internalPath)
{
    if (archivePath.isEmpty() || internalPath.isEmpty())
        return {};

    if (!m_archiveTempDir) {
        m_archiveTempDir = new QTemporaryDir();
    }
    if (!m_archiveTempDir->isValid())
        return {};

    const QString key = QString::fromLatin1(
        QCryptographicHash::hash((archivePath + QLatin1Char('|') + internalPath).toUtf8(), QCryptographicHash::Sha1)
            .toHex()
            .left(12));
    const QString fileName = QFileInfo(internalPath).fileName();
    if (fileName.isEmpty() || fileName == QLatin1String(".") || fileName == QLatin1String(".."))
        return {};

    const QString destPath = m_archiveTempDir->filePath(key + QLatin1Char('/') + fileName);

    struct archive *a = archive_read_new();
    if (!a)
        return {};
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);

    const QByteArray encodedArchive = QFile::encodeName(archivePath);
    if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
        archive_read_free(a);
        return {};
    }

    QString outPath;
    struct archive_entry *entry = nullptr;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        bool endsWithSlash = false;
        const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
        if (entryPath == internalPath && archive_entry_filetype(entry) != AE_IFDIR && !endsWithSlash) {
            const int perm = static_cast<int>(archive_entry_perm(entry)) & 0777;
            if (streamArchiveToFile(a, destPath, perm > 0 ? perm : 0644))
                outPath = destPath;
            break;
        }
        archive_read_data_skip(a);
    }

    archive_read_free(a);
    return outPath;
}

void Backend::recordRecentDirectory(const QString &path)
{
    if (path.trimmed().isEmpty())
        return;

    QString arc, inner;
    if (PanelModel::splitArchivePath(path, &arc, &inner))
        return;

    QFileInfo fi(path);
    if (!fi.isDir())
        return;

    const QString clean = fi.canonicalFilePath().isEmpty()
                              ? QDir::cleanPath(fi.absoluteFilePath())
                              : fi.canonicalFilePath();
    if (clean.isEmpty())
        return;

    if (!m_recentDirs.isEmpty() && m_recentDirs.first() == clean)
        return;

    m_recentDirs.removeAll(clean);
    m_recentDirs.prepend(clean);
    while (m_recentDirs.size() > 50)
        m_recentDirs.removeLast();

    emit recentDirectoriesChanged();

    const QString tmpRoot = QDir::tempPath();
    if (!m_loadingSession && !clean.startsWith(tmpRoot + '/') && !m_bookmarksFile.startsWith(tmpRoot + '/')) {
        const QString zoxide = QStandardPaths::findExecutable(QStringLiteral("zoxide"));
        if (!zoxide.isEmpty())
            QProcess::startDetached(zoxide, {QStringLiteral("add"), clean});
    }
}

int Backend::fuzzyScore(const QString &pattern, const QString &candidate)
{
    const QString pat = pattern.trimmed().toLower();
    if (pat.isEmpty())
        return 0;

    const QString cand = candidate.toLower();
    if (cand.isEmpty())
        return -1;

    int score = 0;
    int patIdx = 0;
    int prevMatch = -2;
    for (int i = 0; i < cand.size() && patIdx < pat.size(); ++i) {
        if (cand.at(i) == pat.at(patIdx)) {
            int bonus = 10;
            if (i == 0) {
                bonus += 25;
            } else {
                const QChar prev = cand.at(i - 1);
                if (prev == '/' || prev == '-' || prev == '_' || prev == '.' || prev == ' ')
                    bonus += 18;
            }
            if (i == prevMatch + 1)
                bonus += 15;
            score += bonus;
            prevMatch = i;
            ++patIdx;
        }
    }

    if (patIdx < pat.size())
        return -1;

    const int exactPos = cand.indexOf(pat);
    if (exactPos == 0)
        score += 80;
    else if (exactPos > 0)
        score += 40;

    score -= std::min(50, static_cast<int>(cand.size()) / 4);
    return std::max(1, score);
}

QVariantList Backend::queryJumpDirectories(const QString &query, int maxResults) const
{
    struct Candidate {
        QString path;
        QString name;
        QString source;
        QString badge;
        int priorityBonus = 0;
        bool forceInclude = false;
    };

    QList<Candidate> candidates;
    QHash<QString, int> indexByPath;

    auto addCandidate = [&](const QString &rawPath, const QString &source, const QString &badge,
                            int priorityBonus, bool forceInclude = false) {
        QFileInfo fi(rawPath);
        if (!fi.isDir())
            return;
        const QString clean = fi.canonicalFilePath().isEmpty()
                                  ? QDir::cleanPath(fi.absoluteFilePath())
                                  : fi.canonicalFilePath();
        if (clean.isEmpty())
            return;

        if (indexByPath.contains(clean)) {
            Candidate &existing = candidates[indexByPath.value(clean)];
            if (priorityBonus > existing.priorityBonus) {
                existing.source = source;
                existing.badge = badge;
                existing.priorityBonus = priorityBonus;
            }
            if (forceInclude)
                existing.forceInclude = true;
            return;
        }

        Candidate c;
        c.path = clean;
        c.name = clean == QLatin1String("/") ? QStringLiteral("/") : QFileInfo(clean).fileName();
        if (c.name.isEmpty())
            c.name = clean;
        c.source = source;
        c.badge = badge;
        c.priorityBonus = priorityBonus;
        c.forceInclude = forceInclude;
        indexByPath.insert(clean, candidates.size());
        candidates.append(c);
    };

    const PanelModel *active = (m_activePanel == 0) ? &m_leftPanel : &m_rightPanel;
    const QString activeRealDir = active->isArchiveView()
                                      ? QFileInfo(active->archiveFilePath()).absolutePath()
                                      : active->path();
    const QString trimmed = query.trimmed();

    // 1. Direct path completion if user typed an explicit path (/..., ~/..., ./..., ../...)
    if (trimmed.startsWith('/') || trimmed.startsWith('~') || trimmed.startsWith('.')) {
        QString expanded = trimmed;
        if (expanded == QLatin1String("~"))
            expanded = QDir::homePath();
        else if (expanded.startsWith(QLatin1String("~/")))
            expanded = QDir::homePath() + expanded.mid(1);
        else if (expanded.startsWith('.'))
            expanded = QDir::cleanPath(activeRealDir + '/' + expanded);

        if (QFileInfo(expanded).isDir())
            addCandidate(expanded, QStringLiteral("path"), tr("Path"), 220, true);

        const int lastSlash = expanded.lastIndexOf('/');
        const QString parentDir = (lastSlash == 0) ? QStringLiteral("/")
                                  : (lastSlash > 0) ? expanded.left(lastSlash)
                                                    : QString();
        const QString leafPrefix = (lastSlash >= 0) ? expanded.mid(lastSlash + 1).toLower() : QString();
        if (!parentDir.isEmpty() && QFileInfo(parentDir).isDir()) {
            const QDir pDir(parentDir);
            const QFileInfoList subDirs = pDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot |
                                                                 (leafPrefix.startsWith('.') ? QDir::Hidden : QDir::Filter(0)));
            int added = 0;
            for (const QFileInfo &sd : subDirs) {
                if (leafPrefix.isEmpty() || sd.fileName().toLower().startsWith(leafPrefix) ||
                    fuzzyScore(leafPrefix, sd.fileName()) > 0) {
                    addCandidate(sd.absoluteFilePath(), QStringLiteral("path"), tr("Path"), 190, true);
                    if (++added >= 40)
                        break;
                }
            }
        }
    }

    // 2. Bookmarks
    for (const QString &b : m_bookmarks)
        addCandidate(b, QStringLiteral("bookmark"), tr("Bookmark"), 95);

    // 3. Open tabs (both panels)
    for (const QString &tp : m_leftPanel.tabPaths())
        addCandidate(tp, QStringLiteral("tab"), tr("Open Tab"), 85);
    for (const QString &tp : m_rightPanel.tabPaths())
        addCandidate(tp, QStringLiteral("tab"), tr("Open Tab"), 85);

    // 4. Recent directories (newer entries get slightly higher bonus)
    for (int i = 0; i < m_recentDirs.size(); ++i)
        addCandidate(m_recentDirs.at(i), QStringLiteral("recent"), tr("Recent"), std::max(40, 80 - i));

    // 5. Direct subdirectories of active panel (when not in archive view)
    if (!active->isArchiveView() && QFileInfo(active->path()).isDir()) {
        const QDir activeDir(active->path());
        const QFileInfoList children = activeDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        int childCount = 0;
        for (const QFileInfo &ch : children) {
            addCandidate(ch.absoluteFilePath(), QStringLiteral("subfolder"), tr("Subfolder"), 65);
            if (++childCount >= 120)
                break;
        }
    }

    // 6. Mounted drives
    for (const QVariant &dv : m_drives) {
        const QVariantMap d = dv.toMap();
        if (d.value(QStringLiteral("isMounted")).toBool())
            addCandidate(d.value(QStringLiteral("path")).toString(), QStringLiteral("drive"), tr("Drive"), 55);
    }

    // 7. zoxide frecency database (when installed)
    const QString tmpRoot = QDir::tempPath();
    if (!m_bookmarksFile.startsWith(tmpRoot + '/')) {
        const QString zoxide = QStandardPaths::findExecutable(QStringLiteral("zoxide"));
        if (!zoxide.isEmpty()) {
            QProcess proc;
            QStringList args{QStringLiteral("query"), QStringLiteral("-l")};
            if (!trimmed.isEmpty() && !trimmed.startsWith('/') && !trimmed.startsWith('~') && !trimmed.startsWith('.')) {
                args.append(trimmed.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts));
            }
            proc.start(zoxide, args);
            if (proc.waitForFinished(500) && proc.exitCode() == 0) {
                const QString out = QString::fromUtf8(proc.readAllStandardOutput());
                const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
                int count = 0;
                for (const QString &line : lines) {
                    addCandidate(line.trimmed(), QStringLiteral("zoxide"), QStringLiteral("zoxide"),
                                 std::max(35, 78 - count));
                    if (++count >= 80)
                        break;
                }
            }
        }
    }

    struct ScoredCandidate {
        Candidate cand;
        int score = 0;
    };
    QList<ScoredCandidate> scored;
    const QString activePath = active->path();

    for (const Candidate &c : candidates) {
        int totalScore = 0;
        if (trimmed.isEmpty()) {
            totalScore = c.priorityBonus + (c.path == activePath ? -15 : 0);
        } else if (c.forceInclude) {
            const int ps = fuzzyScore(trimmed, c.path);
            totalScore = c.priorityBonus + std::max(0, ps);
        } else {
            const int nameScore = fuzzyScore(trimmed, c.name);
            const int pathScore = fuzzyScore(trimmed, c.path);
            if (nameScore < 0 && pathScore < 0)
                continue;
            totalScore = std::max(0, nameScore) * 2 + std::max(0, pathScore) + c.priorityBonus;
        }
        scored.append(ScoredCandidate{c, totalScore});
    }

    std::sort(scored.begin(), scored.end(), [](const ScoredCandidate &a, const ScoredCandidate &b) {
        if (a.score != b.score)
            return a.score > b.score;
        if (a.cand.path.size() != b.cand.path.size())
            return a.cand.path.size() < b.cand.path.size();
        return a.cand.path.compare(b.cand.path, Qt::CaseInsensitive) < 0;
    });

    const int limit = std::clamp(maxResults, 1, 200);
    QVariantList result;
    result.reserve(std::min(limit, static_cast<int>(scored.size())));
    for (int i = 0; i < scored.size() && i < limit; ++i) {
        QVariantMap row;
        row["path"] = scored.at(i).cand.path;
        row["name"] = scored.at(i).cand.name;
        row["source"] = scored.at(i).cand.source;
        row["badge"] = scored.at(i).cand.badge;
        row["score"] = scored.at(i).score;
        result.append(row);
    }
    return result;
}

void Backend::refreshDrives()
{
    QVariantList result;
    QSet<QString> seenPaths;

    auto addDrive = [&](const QString &label, const QString &path, const QString &freeStr, bool canUnmount = false) {
        if (seenPaths.contains(path) || !QDir(path).exists())
            return;
        seenPaths.insert(path);
        QVariantMap d;
        d["label"] = label;
        d["path"] = path;
        d["free"] = freeStr;
        d["isMounted"] = true;
        d["canUnmount"] = canUnmount;
        d["isRemovable"] = canUnmount;
        d["devPath"] = QString();
        result.append(d);
    };

    const QStorageInfo homeStorage(QDir::homePath());
    addDrive("~ Home", QDir::homePath(), PanelModel::formatSize(homeStorage.bytesAvailable(), false));

    const QStorageInfo rootStorage("/");
    addDrive("/ Root", "/", PanelModel::formatSize(rootStorage.bytesAvailable(), false));

    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady())
            continue;
        const QString rootPath = storage.rootPath();
        const QByteArray fsType = storage.fileSystemType();
        if (fsType == "tmpfs" || fsType == "devtmpfs" || fsType == "proc" || fsType == "sysfs" ||
            fsType == "cgroup2" || fsType == "overlay" || fsType == "squashfs" || fsType == "efivarfs")
            continue;
        if (rootPath == QLatin1String("/") || rootPath == QLatin1String("/home") ||
            rootPath == QLatin1String("/root") || rootPath == QLatin1String("/srv") ||
            rootPath.startsWith("/boot") || rootPath.startsWith("/run/user") ||
            rootPath.startsWith("/var") || rootPath.startsWith("/sys") || rootPath.startsWith("/dev"))
            continue;

        QString label = storage.displayName();
        if (label.isEmpty() || label == rootPath) {
            label = QFileInfo(rootPath).fileName();
            if (label.isEmpty())
                label = rootPath;
        }
        const bool canUnmount = rootPath.startsWith("/run/media") || rootPath.startsWith("/media") || rootPath.startsWith("/mnt");
        addDrive(label, rootPath, PanelModel::formatSize(storage.bytesAvailable(), false), canUnmount);
    }

    addDrive("/tmp", "/tmp", "");

    // Query unmounted USB & removable block devices via lsblk -J
    QProcess lsblkProc;
    lsblkProc.start("lsblk", {"-J", "-o", "NAME,PATH,RM,RO,TYPE,SIZE,MOUNTPOINT,LABEL,FSTYPE,MODEL"});
    if (lsblkProc.waitForFinished(2000) && lsblkProc.exitCode() == 0) {
        const QByteArray out = lsblkProc.readAllStandardOutput();
        const QJsonObject rootObj = QJsonDocument::fromJson(out).object();
        const QJsonArray blockDevices = rootObj["blockdevices"].toArray();

        std::function<void(const QJsonArray&)> parseDevices = [&](const QJsonArray &devs) {
            for (const QJsonValue &v : devs) {
                const QJsonObject dev = v.toObject();
                const QString mountPoint = dev["mountpoint"].toString();
                const QString devPath = dev["path"].toString();
                const QString fstype = dev["fstype"].toString();
                const QString size = dev["size"].toString();
                const QString label = dev["label"].toString();
                const bool isRm = dev["rm"].toBool();
                const QString model = dev["model"].toString();

                if (mountPoint.isEmpty() && !fstype.isEmpty() && fstype != "swap" && fstype != "crypto_LUKS") {
                    QString displayLabel = label.isEmpty() ? QFileInfo(devPath).fileName() : label;
                    if (!model.isEmpty())
                        displayLabel += " (" + model.trimmed() + ")";
                    QVariantMap d;
                    d["label"] = displayLabel;
                    d["path"] = devPath;
                    d["free"] = size;
                    d["isMounted"] = false;
                    d["canUnmount"] = false;
                    d["isRemovable"] = isRm;
                    d["devPath"] = devPath;
                    d["fsType"] = fstype;
                    result.append(d);
                }

                if (dev.contains("children")) {
                    parseDevices(dev["children"].toArray());
                }
            }
        };
        parseDevices(blockDevices);
    }

    m_drives = result;
    emit drivesChanged();
}

bool Backend::mountDevice(const QString &devPath)
{
    if (devPath.trimmed().isEmpty())
        return false;

    QProcess proc;
    proc.start("udisksctl", {"mount", "-b", devPath.trimmed()});
    if (!proc.waitForFinished(10000)) {
        showStatus(tr("Mount command timed out."));
        return false;
    }

    const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

    if (proc.exitCode() == 0) {
        static const QRegularExpression rx(R"(Mounted\s+\S+\s+at\s+(\S+))");
        auto match = rx.match(out);
        refreshDrives();
        if (match.hasMatch()) {
            const QString mountPoint = match.captured(1);
            activeModel()->setPath(mountPoint);
            showStatus(tr("Mounted at: %1").arg(mountPoint));
        } else {
            showStatus(tr("Device mounted successfully."));
        }
        return true;
    }

    showStatus(err.isEmpty() ? tr("Failed to mount %1").arg(devPath) : err);
    return false;
}

bool Backend::unmountDevice(const QString &mountOrDevPath)
{
    if (mountOrDevPath.trimmed().isEmpty())
        return false;

    QProcess proc;
    if (mountOrDevPath.startsWith("/dev/")) {
        proc.start("udisksctl", {"unmount", "-b", mountOrDevPath.trimmed()});
    } else {
        proc.start("udisksctl", {"unmount", "-p", mountOrDevPath.trimmed()});
        if (!proc.waitForFinished(3000) || proc.exitCode() != 0) {
            proc.start("udisksctl", {"unmount", "-b", mountOrDevPath.trimmed()});
        }
    }
    proc.waitForFinished(8000);

    const bool ok = (proc.exitCode() == 0);
    if (ok) {
        if (m_leftPanel.path().startsWith(mountOrDevPath))
            m_leftPanel.setPath(QDir::homePath());
        if (m_rightPanel.path().startsWith(mountOrDevPath))
            m_rightPanel.setPath(QDir::homePath());
        refreshDrives();
        showStatus(tr("Device unmounted successfully."));
    } else {
        const QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();
        showStatus(err.isEmpty() ? tr("Failed to unmount.") : err);
    }
    return ok;
}

void Backend::loadBookmarks()
{
    m_bookmarks.clear();
    QFile file(m_bookmarksFile);
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonArray arr = QJsonDocument::fromJson(file.readAll()).array();
        for (const QJsonValue &v : arr) {
            if (v.isString() && !v.toString().isEmpty())
                m_bookmarks.append(v.toString());
        }
    }
    if (m_bookmarks.isEmpty()) {
        m_bookmarks.append(QDir::homePath());
        if (QDir(QDir::homePath() + "/Downloads").exists())
            m_bookmarks.append(QDir::homePath() + "/Downloads");
        if (QDir(QDir::homePath() + "/Projects").exists())
            m_bookmarks.append(QDir::homePath() + "/Projects");
    }
    emit bookmarksChanged();
}

void Backend::saveBookmarks() const
{
    QFileInfo fi(m_bookmarksFile);
    QDir().mkpath(fi.absolutePath());
    QFile file(m_bookmarksFile);
    if (file.open(QIODevice::WriteOnly)) {
        QJsonArray arr;
        for (const QString &b : m_bookmarks)
            arr.append(b);
        file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    }
}

void Backend::toggleBookmark(const QString &path)
{
    if (path.isEmpty())
        return;

    if (m_bookmarks.contains(path)) {
        m_bookmarks.removeAll(path);
        showStatus(tr("Removed bookmark: %1").arg(path));
    } else {
        m_bookmarks.append(path);
        showStatus(tr("Added bookmark: %1").arg(path));
    }
    saveBookmarks();
    emit bookmarksChanged();
}

bool Backend::isBookmarked(const QString &path) const
{
    return m_bookmarks.contains(path);
}

QVariantMap Backend::runCommand(const QString &command)
{
    QVariantMap res;
    if (command.trimmed().isEmpty())
        return res;

    QProcess proc;
    const QString workDir = activeModel()->isArchiveView()
                                ? QFileInfo(activeModel()->archiveFilePath()).absolutePath()
                                : activeModel()->path();
    proc.setWorkingDirectory(workDir);
    proc.setProcessChannelMode(QProcess::MergedChannels);
    proc.start("/bin/sh", {"-c", command});
    proc.waitForFinished(10000);

    const QString output = QString::fromUtf8(proc.readAll()).trimmed();
    const int code = proc.exitCode();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    res["exitCode"] = code;
    res["output"] = output;

    if (!output.isEmpty()) {
        QString firstLine = output.section('\n', 0, 0);
        showStatus(QString("[%1] %2").arg(code).arg(firstLine));
    } else {
        showStatus(tr("Command finished (exit %1): %2").arg(code).arg(command));
    }
    return res;
}

QVariantMap Backend::getPreview(const QString &path)
{
    QVariantMap map;

    QString archiveFile;
    QString internalPath;
    if (PanelModel::splitArchivePath(path, &archiveFile, &internalPath) && !internalPath.isEmpty()) {
        struct archive *a = archive_read_new();
        if (!a) {
            map["exists"] = false;
            return map;
        }
        archive_read_support_filter_all(a);
        archive_read_support_format_all(a);

        const QByteArray encodedArchive = QFile::encodeName(archiveFile);
        if (archive_read_open_filename(a, encodedArchive.constData(), 65536) != ARCHIVE_OK) {
            archive_read_free(a);
            map["exists"] = false;
            return map;
        }

        const QString childPrefix = internalPath + '/';
        bool matchedDir = false;
        QString dirModified;
        int subDirs = 0;
        int files = 0;
        qint64 directBytes = 0;
        QStringList sampleNames;
        QSet<QString> seenChildren;

        struct archive_entry *entry = nullptr;
        while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
            bool endsWithSlash = false;
            const QString entryPath = normalizeArchiveEntryPath(entry, &endsWithSlash);
            if (entryPath.isEmpty()) {
                archive_read_data_skip(a);
                continue;
            }

            const bool entryIsDir = (archive_entry_filetype(entry) == AE_IFDIR) || endsWithSlash;
            const qint64 entrySize = std::max<qint64>(0, static_cast<qint64>(archive_entry_size(entry)));
            const QString modifiedStr = archive_entry_mtime_is_set(entry)
                                            ? QDateTime::fromSecsSinceEpoch(archive_entry_mtime(entry))
                                                  .toString("yyyy-MM-dd hh:mm:ss")
                                            : QString();

            if (entryPath == internalPath && !entryIsDir) {
                const QFileInfo entryFi(internalPath);
                const QString ext = entryFi.suffix().toLower();
                map["exists"] = true;
                map["name"] = entryFi.fileName();
                map["path"] = archiveFile + "/" + internalPath;
                map["isDir"] = false;
                map["size"] = entrySize;
                map["formattedSize"] = PanelModel::formatSize(entrySize, false);
                map["modified"] = modifiedStr;

                if (isImageExtension(ext)) {
                    archive_read_free(a);
                    const QString tempImg = extractArchiveEntryToTemp(archiveFile, internalPath);
                    if (!tempImg.isEmpty()) {
                        map["isImage"] = true;
                        map["imagePath"] = QUrl::fromLocalFile(tempImg).toString();
                        QImageReader reader(tempImg);
                        const QSize sz = reader.size();
                        if (sz.isValid())
                            map["imageDimensions"] = QString("%1 × %2 px").arg(sz.width()).arg(sz.height());
                        const QString fmt = QString::fromLatin1(reader.format()).toUpper();
                        map["imageFormat"] = fmt.isEmpty() ? ext.toUpper() : fmt;
                    }
                    return map;
                }

                constexpr qint64 kMaxPreviewBytes = 128 * 1024;
                QByteArray chunk;
                char buf[8192];
                bool truncated = false;
                while (chunk.size() <= kMaxPreviewBytes) {
                    const la_ssize_t n = archive_read_data(a, buf, sizeof(buf));
                    if (n <= 0)
                        break;
                    chunk.append(buf, static_cast<qsizetype>(n));
                    if (chunk.size() > kMaxPreviewBytes) {
                        chunk.truncate(kMaxPreviewBytes);
                        truncated = true;
                        break;
                    }
                }
                archive_read_free(a);

                const bool isBinary = chunk.contains('\0');
                map["isImage"] = false;
                map["isBinary"] = isBinary;
                map["isText"] = true;
                if (!isBinary) {
                    map["text"] = QString::fromUtf8(chunk);
                    map["truncated"] = truncated;
                } else {
                    map["text"] = formatHexDumpText(chunk, map["formattedSize"].toString(), entrySize);
                }
                return map;
            }

            if (entryPath == internalPath && entryIsDir) {
                matchedDir = true;
                dirModified = modifiedStr;
            } else if (entryPath.startsWith(childPrefix)) {
                matchedDir = true;
                const QString rel = entryPath.mid(childPrefix.size());
                const int slash = rel.indexOf('/');
                const QString childName = (slash >= 0) ? rel.left(slash) : rel;
                const bool childIsDir = (slash >= 0) || entryIsDir;
                if (!childName.isEmpty() && !seenChildren.contains(childName)) {
                    seenChildren.insert(childName);
                    if (childIsDir)
                        ++subDirs;
                    else {
                        ++files;
                        directBytes += entrySize;
                    }
                    if (sampleNames.size() < 25)
                        sampleNames.append((childIsDir ? "📁 " : "🗎 ") + childName);
                }
            }
            archive_read_data_skip(a);
        }

        archive_read_free(a);
        if (matchedDir) {
            map["exists"] = true;
            map["name"] = QFileInfo(internalPath).fileName();
            map["path"] = archiveFile + "/" + internalPath;
            map["isDir"] = true;
            map["size"] = 0;
            map["formattedSize"] = PanelModel::formatSize(0, true);
            map["modified"] = dirModified;
            map["isText"] = true;
            map["text"] = tr("Archive Folder: %1\nPath: %2\n\nContents: %3 folder(s), %4 file(s)\nDirect files size: %5\n\nItems:\n%6")
                              .arg(map["name"].toString(),
                                   map["path"].toString())
                              .arg(subDirs)
                              .arg(files)
                              .arg(PanelModel::formatSize(directBytes, false),
                                   sampleNames.isEmpty() ? tr("(empty directory)") : sampleNames.join("\n"));
            return map;
        }

        map["exists"] = false;
        return map;
    }

    QFileInfo fi(path);
    if (!fi.exists()) {
        map["exists"] = false;
        return map;
    }

    map["exists"] = true;
    map["name"] = fi.fileName();
    map["path"] = fi.absoluteFilePath();
    map["isDir"] = fi.isDir();
    map["size"] = fi.size();
    map["formattedSize"] = PanelModel::formatSize(fi.size(), fi.isDir());
    map["modified"] = fi.lastModified().toString("yyyy-MM-dd hh:mm:ss");

    if (fi.isDir()) {
        QDir dir(fi.absoluteFilePath());
        const QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
        int subDirs = 0;
        int files = 0;
        qint64 directBytes = 0;
        QStringList sampleNames;
        for (const QFileInfo &entry : list) {
            if (entry.isDir())
                ++subDirs;
            else {
                ++files;
                directBytes += entry.size();
            }
            if (sampleNames.size() < 25)
                sampleNames.append((entry.isDir() ? "📁 " : "🗎 ") + entry.fileName());
        }
        map["isText"] = true;
        map["text"] = tr("Directory: %1\nPath: %2\nModified: %3\n\nContents: %4 folder(s), %5 file(s)\nDirect files size: %6\n\nItems:\n%7")
                          .arg(fi.fileName(),
                               fi.absoluteFilePath(),
                               map["modified"].toString())
                          .arg(subDirs)
                          .arg(files)
                          .arg(PanelModel::formatSize(directBytes, false),
                               sampleNames.isEmpty() ? tr("(empty directory)") : sampleNames.join("\n"));
        return map;
    }

    const QString ext = fi.suffix().toLower();
    bool isImage = isImageExtension(ext);
    map["isImage"] = isImage;

    if (isImage) {
        map["imagePath"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        QImageReader reader(fi.absoluteFilePath());
        const QSize sz = reader.size();
        if (sz.isValid()) {
            map["imageDimensions"] = QString("%1 × %2 px").arg(sz.width()).arg(sz.height());
        }
        const QString fmt = QString::fromLatin1(reader.format()).toUpper();
        map["imageFormat"] = fmt.isEmpty() ? ext.toUpper() : fmt;
        return map;
    }

    if (isArchive(path)) {
        QProcess proc;
        const QString bsdtar = QStandardPaths::findExecutable("bsdtar");
        if (!bsdtar.isEmpty()) {
            proc.start(bsdtar, {"-tvf", fi.absoluteFilePath()});
        } else if (ext == "zip") {
            proc.start("unzip", {"-l", fi.absoluteFilePath()});
        } else {
            proc.start("tar", {"-tvf", fi.absoluteFilePath()});
        }
        if (proc.waitForFinished(3000) && proc.exitCode() == 0) {
            map["isText"] = true;
            map["text"] = tr("Archive: %1 (%2)\n\n").arg(fi.fileName(), map["formattedSize"].toString()) +
                          QString::fromUtf8(proc.readAllStandardOutput());
            return map;
        }
    }

    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
        QByteArray chunk = file.read(128 * 1024);
        const bool isBinary = chunk.contains('\0');
        map["isBinary"] = isBinary;
        if (!isBinary) {
            map["isText"] = true;
            map["text"] = QString::fromUtf8(chunk);
            map["truncated"] = (file.size() > chunk.size());
        } else {
            map["isText"] = true;
            map["text"] = formatHexDumpText(chunk, map["formattedSize"].toString(), fi.size());
        }
    }

    return map;
}

QStringList Backend::searchFiles(const QString &rootPath, const QString &query, int maxResults)
{
    QStringList results;
    if (rootPath.isEmpty() || query.trimmed().isEmpty())
        return results;

    const QString needle = query.trimmed().toLower();
    QDirIterator it(rootPath, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden,
                    QDirIterator::Subdirectories);

    while (it.hasNext() && results.size() < maxResults) {
        it.next();
        if (it.fileName().toLower().contains(needle)) {
            results.append(it.filePath());
        }
    }

    return results;
}

QVariantList Backend::runAdvancedSearchSync(const QString &rootPath, const QVariantMap &options)
{
    const SearchSpec spec = parseSearchOptions(options);
    return runSearchImpl(rootPath, spec, nullptr, [](int, const QVariantList &) {});
}

void Backend::cancelSearch()
{
    if (!m_searchThread && !m_searchRunning)
        return;

    m_searchCancelRequested.store(true, std::memory_order_relaxed);
    ++m_searchGeneration;

    if (m_searchThread) {
        m_searchThread->wait();
        delete m_searchThread;
        m_searchThread = nullptr;
    }

    if (m_searchRunning) {
        m_searchRunning = false;
        emit searchStateChanged();
        showStatus(tr("Search cancelled."));
    }
}

void Backend::startAdvancedSearch(const QString &rootPath, const QVariantMap &options)
{
    cancelSearch();

    const QFileInfo rootFi(rootPath);
    if (!rootFi.exists() || !rootFi.isDir()) {
        showStatus(tr("Search folder does not exist: %1").arg(rootPath));
        return;
    }

    const QString cleanRoot = rootFi.absoluteFilePath();
    const SearchSpec spec = parseSearchOptions(options);

    m_searchCancelRequested.store(false, std::memory_order_relaxed);
    const quint64 gen = ++m_searchGeneration;
    m_searchRunning = true;
    m_searchScannedCount = 0;
    m_searchResultItems.clear();
    emit searchResultsChanged();
    emit searchProgressChanged();
    emit searchStateChanged();

    QThread *worker = QThread::create([this, gen, cleanRoot, spec]() {
        int totalScanned = 0;
        runSearchImpl(cleanRoot, spec, &m_searchCancelRequested,
                      [this, gen](int scanned, const QVariantList &batch) {
                          QMetaObject::invokeMethod(this, [this, gen, scanned, batch]() {
                              if (gen != m_searchGeneration)
                                  return;
                              m_searchScannedCount = scanned;
                              emit searchProgressChanged();
                              if (!batch.isEmpty()) {
                                  m_searchResultItems.append(batch);
                                  emit searchResultsChanged();
                              }
                          }, Qt::QueuedConnection);
                      },
                      &totalScanned);

        const bool cancelled = m_searchCancelRequested.load(std::memory_order_relaxed);
        QMetaObject::invokeMethod(this, [this, gen, totalScanned, cancelled]() {
            if (gen != m_searchGeneration)
                return;
            m_searchScannedCount = totalScanned;
            m_searchRunning = false;
            if (m_searchThread) {
                m_searchThread->wait();
                delete m_searchThread;
                m_searchThread = nullptr;
            }
            emit searchProgressChanged();
            emit searchStateChanged();
            showStatus(cancelled
                           ? tr("Search stopped (%1 results found).").arg(m_searchResultItems.size())
                           : tr("Search finished: %1 result(s) across %2 item(s).")
                                 .arg(m_searchResultItems.size())
                                 .arg(totalScanned));
        }, Qt::QueuedConnection);
    });

    m_searchThread = worker;
    worker->start();
}

void Backend::feedPathsToPanel(const QStringList &paths, const QString &title, bool newTab)
{
    PanelModel *panel = activeModel();
    const QString basePath = panel->isArchiveView() ? QFileInfo(panel->archiveFilePath()).absolutePath() : panel->path();
    const QString cleanTitle = title.trimmed().isEmpty() ? tr("Search Results") : title.trimmed();
    if (newTab)
        panel->addTab(basePath);
    panel->feedItems(paths, cleanTitle, basePath);
    showStatus(tr("Fed %1 item(s) to panel \"%2\".").arg(paths.size()).arg(cleanTitle));
}

QVariantList Backend::compareDirectoriesRecursive(const QString &leftRoot, const QString &rightRoot,
                                                  const QString &compareMode, bool includeHidden)
{
    QVariantList out;
    if (leftRoot.isEmpty() || rightRoot.isEmpty())
        return out;

    const QDir leftDir(leftRoot);
    const QDir rightDir(rightRoot);
    if (!leftDir.exists() || !rightDir.exists())
        return out;

    const QHash<QString, QFileInfo> leftMap = collectFilesRecursive(leftRoot, includeHidden);
    const QHash<QString, QFileInfo> rightMap = collectFilesRecursive(rightRoot, includeHidden);

    QSet<QString> keySet;
    for (auto it = leftMap.constBegin(); it != leftMap.constEnd(); ++it)
        keySet.insert(it.key());
    for (auto it = rightMap.constBegin(); it != rightMap.constEnd(); ++it)
        keySet.insert(it.key());

    QStringList sortedKeys = keySet.values();
    std::sort(sortedKeys.begin(), sortedKeys.end(), [](const QString &a, const QString &b) {
        return QString::localeAwareCompare(a.toLower(), b.toLower()) < 0;
    });

    const QString mode = compareMode.trimmed().toLower();
    out.reserve(sortedKeys.size());

    for (const QString &rel : std::as_const(sortedKeys)) {
        const bool inL = leftMap.contains(rel);
        const bool inR = rightMap.contains(rel);
        const QFileInfo lFi = leftMap.value(rel);
        const QFileInfo rFi = rightMap.value(rel);

        QString status;
        QString action;

        if (inL && !inR) {
            status = QStringLiteral("left_only");
            action = QStringLiteral("copy_to_right");
        } else if (!inL && inR) {
            status = QStringLiteral("right_only");
            action = QStringLiteral("copy_to_left");
        } else {
            const qint64 lSz = lFi.size();
            const qint64 rSz = rFi.size();
            const QDateTime lTm = lFi.lastModified();
            const QDateTime rTm = rFi.lastModified();
            const qint64 deltaSecs = lTm.secsTo(rTm); // > 0 means right is newer

            if (mode == QLatin1String("size")) {
                if (lSz == rSz) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else {
                    status = QStringLiteral("different");
                    action = (deltaSecs < -2) ? QStringLiteral("copy_to_right")
                                              : ((deltaSecs > 2) ? QStringLiteral("copy_to_left") : QStringLiteral("skip"));
                }
            } else if (mode == QLatin1String("sha256")) {
                bool contentSame = (lSz == rSz);
                if (contentSame)
                    contentSame = (computeFileSha256Hex(lFi.absoluteFilePath()) == computeFileSha256Hex(rFi.absoluteFilePath()));

                if (contentSame) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else if (deltaSecs < -2) {
                    status = QStringLiteral("left_newer");
                    action = QStringLiteral("copy_to_right");
                } else if (deltaSecs > 2) {
                    status = QStringLiteral("right_newer");
                    action = QStringLiteral("copy_to_left");
                } else {
                    status = QStringLiteral("different");
                    action = QStringLiteral("skip");
                }
            } else {
                // Default: "date_size"
                if (lSz == rSz && qAbs(deltaSecs) <= 2) {
                    status = QStringLiteral("equal");
                    action = QStringLiteral("skip");
                } else if (deltaSecs < -2) {
                    status = QStringLiteral("left_newer");
                    action = QStringLiteral("copy_to_right");
                } else if (deltaSecs > 2) {
                    status = QStringLiteral("right_newer");
                    action = QStringLiteral("copy_to_left");
                } else {
                    status = QStringLiteral("different");
                    action = QStringLiteral("skip");
                }
            }
        }

        QVariantMap row;
        row[QStringLiteral("relPath")] = rel;
        row[QStringLiteral("leftPath")] = inL ? lFi.absoluteFilePath() : leftDir.filePath(rel);
        row[QStringLiteral("rightPath")] = inR ? rFi.absoluteFilePath() : rightDir.filePath(rel);
        row[QStringLiteral("leftExists")] = inL;
        row[QStringLiteral("rightExists")] = inR;
        row[QStringLiteral("leftSize")] = inL ? lFi.size() : qint64(-1);
        row[QStringLiteral("rightSize")] = inR ? rFi.size() : qint64(-1);
        row[QStringLiteral("leftFormattedSize")] = inL ? PanelModel::formatSize(lFi.size(), false) : QString();
        row[QStringLiteral("rightFormattedSize")] = inR ? PanelModel::formatSize(rFi.size(), false) : QString();
        row[QStringLiteral("leftModified")] = inL ? lFi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm")) : QString();
        row[QStringLiteral("rightModified")] = inR ? rFi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm")) : QString();
        row[QStringLiteral("status")] = status;
        row[QStringLiteral("action")] = action;
        out.append(row);
    }

    return out;
}

QVariantMap Backend::executeDirectorySync(const QString &leftRoot, const QString &rightRoot, const QVariantList &syncItems)
{
    int copiedToRight = 0;
    int copiedToLeft = 0;
    int failed = 0;

    const QDir leftDir(leftRoot);
    const QDir rightDir(rightRoot);

    for (const QVariant &v : syncItems) {
        const QVariantMap item = v.toMap();
        const QString action = item.value(QStringLiteral("action")).toString();
        if (action != QLatin1String("copy_to_right") && action != QLatin1String("copy_to_left"))
            continue;

        const QString relPath = item.value(QStringLiteral("relPath")).toString();
        if (relPath.isEmpty() || QDir::isAbsolutePath(relPath) || relPath.contains(QLatin1String(".."))) {
            ++failed;
            continue;
        }

        const bool toRight = (action == QLatin1String("copy_to_right"));
        const QString srcPath = toRight ? leftDir.filePath(relPath) : rightDir.filePath(relPath);
        const QString dstPath = toRight ? rightDir.filePath(relPath) : leftDir.filePath(relPath);

        const QFileInfo srcFi(srcPath);
        if (!srcFi.exists() || !srcFi.isFile()) {
            ++failed;
            continue;
        }

        if (!QDir().mkpath(QFileInfo(dstPath).absolutePath())) {
            ++failed;
            continue;
        }

        const QString tmpDst = dstPath + QStringLiteral(".omapanel_sync_tmp");
        QFile::remove(tmpDst);
        if (!QFile::copy(srcPath, tmpDst)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        if (QFileInfo::exists(dstPath) && !QFile::remove(dstPath)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        if (!QFile::rename(tmpDst, dstPath)) {
            QFile::remove(tmpDst);
            ++failed;
            continue;
        }

        const QDateTime srcMtime = srcFi.lastModified();
        if (srcMtime.isValid()) {
            QFile dstFile(dstPath);
            if (dstFile.open(QIODevice::ReadWrite)) {
                dstFile.setFileTime(srcMtime, QFileDevice::FileModificationTime);
                dstFile.close();
            }
        }

        if (toRight)
            ++copiedToRight;
        else
            ++copiedToLeft;
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    const int totalApplied = copiedToRight + copiedToLeft;
    showStatus(tr("Synchronized %1 file(s): %2 → right, %3 ← left (%4 failed).")
                   .arg(totalApplied)
                   .arg(copiedToRight)
                   .arg(copiedToLeft)
                   .arg(failed));

    QVariantMap summary;
    summary[QStringLiteral("copiedToRight")] = copiedToRight;
    summary[QStringLiteral("copiedToLeft")] = copiedToLeft;
    summary[QStringLiteral("failed")] = failed;
    summary[QStringLiteral("totalApplied")] = totalApplied;
    return summary;
}

QVariantList Backend::findDuplicateFiles(const QString &rootPath, const QString &secondaryRootPath,
                                         qint64 minSizeBytes, bool includeHidden)
{
    QVariantList result;
    const qint64 minSz = std::max<qint64>(1, minSizeBytes);

    QStringList scanRoots;
    if (!rootPath.isEmpty() && QFileInfo(rootPath).isDir())
        scanRoots.append(rootPath);
    if (!secondaryRootPath.isEmpty() && QFileInfo(secondaryRootPath).isDir())
        scanRoots.append(secondaryRootPath);
    if (scanRoots.isEmpty())
        return result;

    QHash<qint64, QList<QFileInfo>> bySize;
    QSet<QString> visitedCanonical;

    for (const QString &root : std::as_const(scanRoots)) {
        const QHash<QString, QFileInfo> files = collectFilesRecursive(root, includeHidden);
        for (auto it = files.constBegin(); it != files.constEnd(); ++it) {
            const QFileInfo &fi = it.value();
            if (fi.size() < minSz)
                continue;
            QString canon = fi.canonicalFilePath();
            if (canon.isEmpty())
                canon = fi.absoluteFilePath();
            if (visitedCanonical.contains(canon))
                continue;
            visitedCanonical.insert(canon);
            bySize[fi.size()].append(fi);
        }
    }

    struct DupGroup {
        qint64 size = 0;
        QString hash;
        QList<QFileInfo> files;
    };
    QList<DupGroup> groups;

    for (auto sizeIt = bySize.constBegin(); sizeIt != bySize.constEnd(); ++sizeIt) {
        const qint64 sz = sizeIt.key();
        const QList<QFileInfo> &candidates = sizeIt.value();
        if (candidates.size() < 2)
            continue;

        QList<QFileInfo> filtered = candidates;
        if (sz > 128 * 1024) {
            QHash<QString, QList<QFileInfo>> preBuckets;
            for (const QFileInfo &fi : candidates) {
                const QString pre = computeFileSha256Hex(fi.absoluteFilePath(), true);
                if (!pre.isEmpty())
                    preBuckets[pre].append(fi);
            }
            filtered.clear();
            for (auto pbIt = preBuckets.constBegin(); pbIt != preBuckets.constEnd(); ++pbIt) {
                if (pbIt.value().size() >= 2)
                    filtered.append(pbIt.value());
            }
        }

        if (filtered.size() < 2)
            continue;

        QHash<QString, QList<QFileInfo>> fullBuckets;
        for (const QFileInfo &fi : filtered) {
            const QString sha = computeFileSha256Hex(fi.absoluteFilePath(), false);
            if (!sha.isEmpty())
                fullBuckets[sha].append(fi);
        }

        for (auto fbIt = fullBuckets.constBegin(); fbIt != fullBuckets.constEnd(); ++fbIt) {
            if (fbIt.value().size() < 2)
                continue;
            QList<QFileInfo> sortedFiles = fbIt.value();
            std::sort(sortedFiles.begin(), sortedFiles.end(), [](const QFileInfo &a, const QFileInfo &b) {
                if (a.lastModified() != b.lastModified())
                    return a.lastModified() > b.lastModified(); // newest first
                return a.absoluteFilePath() < b.absoluteFilePath();
            });
            groups.append(DupGroup{sz, fbIt.key(), sortedFiles});
        }
    }

    std::sort(groups.begin(), groups.end(), [](const DupGroup &a, const DupGroup &b) {
        const qint64 wasteA = a.size * (a.files.size() - 1);
        const qint64 wasteB = b.size * (b.files.size() - 1);
        if (wasteA != wasteB)
            return wasteA > wasteB;
        if (a.size != b.size)
            return a.size > b.size;
        return a.hash < b.hash;
    });

    for (int g = 0; g < groups.size(); ++g) {
        const DupGroup &grp = groups.at(g);
        const int count = grp.files.size();
        for (int i = 0; i < count; ++i) {
            const QFileInfo &fi = grp.files.at(i);
            const bool isFirst = (i == 0);
            QVariantMap row;
            row[QStringLiteral("groupIndex")] = g;
            row[QStringLiteral("hash")] = grp.hash;
            row[QStringLiteral("path")] = fi.absoluteFilePath();
            row[QStringLiteral("name")] = fi.fileName();
            row[QStringLiteral("dirPath")] = fi.absolutePath();
            row[QStringLiteral("size")] = grp.size;
            row[QStringLiteral("formattedSize")] = PanelModel::formatSize(grp.size, false);
            row[QStringLiteral("modified")] = fi.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"));
            row[QStringLiteral("modifiedSecs")] = fi.lastModified().toSecsSinceEpoch();
            row[QStringLiteral("isFirstInGroup")] = isFirst;
            row[QStringLiteral("groupCount")] = count;
            row[QStringLiteral("wastedBytes")] = isFirst ? qint64(0) : grp.size;
            row[QStringLiteral("selected")] = !isFirst;
            result.append(row);
        }
    }

    return result;
}

void Backend::showStatus(const QString &message)
{
    m_statusMessage = message;
    emit statusMessageChanged();
}
