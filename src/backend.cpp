#include "backend.h"

#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QProcess>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QUrl>

Backend::Backend(const QString &bookmarksFile, QObject *parent)
    : QObject(parent),
      m_leftPanel(QDir::homePath()),
      m_rightPanel(QDir::homePath()),
      m_bookmarksFile(bookmarksFile.isEmpty() ? QDir::homePath() + "/.config/omapanel/bookmarks.json" : bookmarksFile)
{
    if (QDir(QDir::homePath() + "/Downloads").exists()) {
        m_rightPanel.setPath(QDir::homePath() + "/Downloads");
    }
    loadBookmarks();
    refreshDrives();
}

Backend::~Backend() = default;

void Backend::setActivePanel(int index)
{
    if (index != 0 && index != 1)
        return;
    if (m_activePanel != index) {
        m_activePanel = index;
        emit activePanelChanged();
    }
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
    QFileInfo info(path);
    if (!info.exists())
        return;

    if (info.isDir()) {
        activeModel()->cd(info.absoluteFilePath());
    } else {
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    }
}

void Backend::openWithEditor(const QString &path)
{
    QFileInfo info(path);
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
            QProcess::startDetached(terminal, {"-e", editor, path});
            return;
        }
    }

    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void Backend::openInTerminal(const QString &path)
{
    QFileInfo info(path);
    QString dirPath = info.isDir() ? info.absoluteFilePath() : info.absolutePath();

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

bool Backend::copyRecursively(const QString &srcFilePath, const QString &tgtFilePath)
{
    QFileInfo srcInfo(srcFilePath);
    if (srcInfo.isDir()) {
        QDir targetDir(tgtFilePath);
        targetDir.cdUp();
        targetDir.mkdir(QFileInfo(tgtFilePath).fileName());

        QDir sourceDir(srcFilePath);
        const QStringList entries = sourceDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
        for (const QString &entry : entries) {
            const QString newSrc = srcFilePath + "/" + entry;
            const QString newTgt = tgtFilePath + "/" + entry;
            if (!copyRecursively(newSrc, newTgt))
                return false;
        }
        return true;
    } else {
        if (QFile::exists(tgtFilePath))
            QFile::remove(tgtFilePath);
        return QFile::copy(srcFilePath, tgtFilePath);
    }
}

bool Backend::copyItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (sourcePaths.isEmpty() || targetDir.isEmpty())
        return false;

    QDir target(targetDir);
    if (!target.exists())
        return false;

    m_isBusy = true;
    m_busyTitle = tr("Copying files...");
    m_busyProgress = 0.0;
    emit busyChanged();

    bool success = true;
    int total = sourcePaths.size();
    for (int i = 0; i < total; ++i) {
        const QString &src = sourcePaths.at(i);
        QFileInfo fi(src);
        QString dest = target.filePath(fi.fileName());

        if (src == dest) {
            dest = target.filePath(fi.baseName() + "_copy" + (fi.completeSuffix().isEmpty() ? "" : "." + fi.completeSuffix()));
        }

        if (!copyRecursively(src, dest)) {
            success = false;
        }
        m_busyProgress = static_cast<double>(i + 1) / total;
        emit busyChanged();
    }

    m_isBusy = false;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    showStatus(success ? tr("Copy completed.") : tr("Some files could not be copied."));
    emit operationFinished(success, success ? tr("Copied successfully") : tr("Copy failed"));
    return success;
}

bool Backend::moveItems(const QStringList &sourcePaths, const QString &targetDir)
{
    if (sourcePaths.isEmpty() || targetDir.isEmpty())
        return false;

    QDir target(targetDir);
    if (!target.exists())
        return false;

    m_isBusy = true;
    m_busyTitle = tr("Moving files...");
    m_busyProgress = 0.0;
    emit busyChanged();

    bool success = true;
    int total = sourcePaths.size();
    for (int i = 0; i < total; ++i) {
        const QString &src = sourcePaths.at(i);
        QFileInfo fi(src);
        QString dest = target.filePath(fi.fileName());

        if (src == dest)
            continue;

        if (QFile::exists(dest))
            QFile::remove(dest);

        if (!QFile::rename(src, dest)) {
            if (copyRecursively(src, dest)) {
                if (fi.isDir())
                    QDir(src).removeRecursively();
                else
                    QFile::remove(src);
            } else {
                success = false;
            }
        }
        m_busyProgress = static_cast<double>(i + 1) / total;
        emit busyChanged();
    }

    m_isBusy = false;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    showStatus(success ? tr("Move completed.") : tr("Some files could not be moved."));
    emit operationFinished(success, success ? tr("Moved successfully") : tr("Move failed"));
    return success;
}

bool Backend::deleteItems(const QStringList &paths, bool permanent)
{
    if (paths.isEmpty())
        return false;

    m_isBusy = true;
    m_busyTitle = tr("Deleting files...");
    emit busyChanged();

    bool success = true;
    for (const QString &path : paths) {
        QFileInfo fi(path);
        if (!fi.exists())
            continue;

        bool deleted = false;
        if (!permanent) {
            deleted = QFile::moveToTrash(path);
        }

        if (!deleted) {
            if (fi.isDir()) {
                deleted = QDir(path).removeRecursively();
            } else {
                deleted = QFile::remove(path);
            }
        }

        if (!deleted)
            success = false;
    }

    m_isBusy = false;
    emit busyChanged();

    m_leftPanel.refresh();
    m_rightPanel.refresh();

    showStatus(success ? tr("Delete completed.") : tr("Some files could not be deleted."));
    emit operationFinished(success, success ? tr("Deleted successfully") : tr("Delete failed"));
    return success;
}

bool Backend::createDirectory(const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;

    QDir current(activeModel()->path());
    bool ok = current.mkdir(name.trimmed());
    if (ok) {
        activeModel()->refresh();
        showStatus(tr("Folder created: %1").arg(name));
    } else {
        showStatus(tr("Failed to create folder: %1").arg(name));
    }
    return ok;
}

bool Backend::renameItem(const QString &oldPath, const QString &newName)
{
    if (oldPath.isEmpty() || newName.trimmed().isEmpty())
        return false;

    QFileInfo oldFi(oldPath);
    if (!oldFi.exists())
        return false;

    QString newPath = oldFi.dir().filePath(newName.trimmed());
    if (oldPath == newPath)
        return true;

    bool ok = QFile::rename(oldPath, newPath);
    if (ok) {
        activeModel()->refresh();
        showStatus(tr("Renamed to: %1").arg(newName));
    } else {
        showStatus(tr("Failed to rename item."));
    }
    return ok;
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

    int renamedCount = 0;
    for (int i = 0; i < paths.size(); ++i) {
        QFileInfo fi(paths.at(i));
        if (!fi.exists())
            continue;
        const QString newName = computeNewName(fi.fileName(), i, findText, replaceText, prefix, suffix, caseMode, addCounter);
        const QString newPath = fi.dir().filePath(newName);
        if (fi.absoluteFilePath() == newPath) {
            ++renamedCount;
            continue;
        }
        if (QFile::rename(fi.absoluteFilePath(), newPath)) {
            ++renamedCount;
        }
    }

    m_leftPanel.refresh();
    m_rightPanel.refresh();
    showStatus(tr("Multi-Rename: %1/%2 items renamed.").arg(renamedCount).arg(paths.size()));
    return renamedCount == paths.size();
}

bool Backend::isArchive(const QString &path) const
{
    const QString lower = path.toLower();
    return lower.endsWith(".zip") || lower.endsWith(".tar") || lower.endsWith(".tar.gz") ||
           lower.endsWith(".tgz") || lower.endsWith(".tar.xz") || lower.endsWith(".txz") ||
           lower.endsWith(".tar.bz2") || lower.endsWith(".tbz2") || lower.endsWith(".tar.zst") ||
           lower.endsWith(".7z");
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

void Backend::refreshDrives()
{
    QVariantList result;
    QSet<QString> seenPaths;

    auto addDrive = [&](const QString &label, const QString &path, const QString &freeStr) {
        if (seenPaths.contains(path) || !QDir(path).exists())
            return;
        seenPaths.insert(path);
        QVariantMap d;
        d["label"] = label;
        d["path"] = path;
        d["free"] = freeStr;
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
        if (rootPath.startsWith("/boot") || rootPath.startsWith("/run/user") || rootPath.startsWith("/var"))
            continue;

        QString label = storage.displayName();
        if (label.isEmpty() || label == rootPath) {
            label = QFileInfo(rootPath).fileName();
            if (label.isEmpty())
                label = rootPath;
        }
        addDrive(label, rootPath, PanelModel::formatSize(storage.bytesAvailable(), false));
    }

    addDrive("/tmp", "/tmp", "");

    m_drives = result;
    emit drivesChanged();
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
    proc.setWorkingDirectory(activeModel()->path());
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
    bool isImage = (ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "svg" || ext == "webp" || ext == "gif");
    map["isImage"] = isImage;

    if (isImage) {
        map["imagePath"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
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
        bool isBinary = false;
        for (char b : chunk) {
            if (b == '\0') {
                isBinary = true;
                break;
            }
        }
        map["isBinary"] = isBinary;
        if (!isBinary) {
            map["isText"] = true;
            map["text"] = QString::fromUtf8(chunk);
            map["truncated"] = (file.size() > chunk.size());
        } else {
            map["isText"] = true;
            // Format first 512 bytes as a clean Hex + ASCII dump
            const QByteArray sample = chunk.left(512);
            QString hexDump = tr("[Binary file — %1 (%2 bytes)]\n\n").arg(map["formattedSize"].toString()).arg(fi.size());
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
            map["text"] = hexDump;
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

void Backend::showStatus(const QString &message)
{
    m_statusMessage = message;
    emit statusMessageChanged();
}
