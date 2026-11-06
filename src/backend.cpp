#include "backend.h"

#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QUrl>

Backend::Backend(QObject *parent)
    : QObject(parent),
      m_leftPanel(QDir::homePath()),
      m_rightPanel(QDir::homePath())
{
    // If there is another common directory like / or ~/Downloads, we can point right panel to it or home
    if (QDir(QDir::homePath() + "/Downloads").exists()) {
        m_rightPanel.setPath(QDir::homePath() + "/Downloads");
    }
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
        // Run editor in terminal or directly
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

    // Default to xdg-open
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

    QProcess process;
    process.setWorkingDirectory(dirPath);
    QProcess::startDetached(terminal, {}, dirPath);
}

bool Backend::copyRecursively(const QString &srcFilePath, const QString &tgtFilePath)
{
    QFileInfo srcInfo(srcFilePath);
    if (srcInfo.isDir()) {
        QDir targetDir(tgtFilePath);
        targetDir.cdUp();
        if (!targetDir.mkdir(QFileInfo(tgtFilePath).fileName())) {
            // might already exist
        }
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
            // Copying into same folder: append "_copy"
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

        // Try atomic rename first
        if (!QFile::rename(src, dest)) {
            // Cross-device move fallback
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
    map["modified"] = fi.lastModified().toString("yyyy-MM-dd hh:mm:ss");

    const QString ext = fi.suffix().toLower();
    bool isImage = (ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "svg" || ext == "webp" || ext == "gif");
    map["isImage"] = isImage;

    if (isImage) {
        map["imagePath"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
    } else if (!fi.isDir()) {
        // Read preview if small enough (up to 256 KB)
        QFile file(path);
        if (file.open(QIODevice::ReadOnly)) {
            QByteArray chunk = file.read(256 * 1024);
            // Check if binary by scanning null bytes
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
                map["isText"] = false;
                map["text"] = tr("[Binary file - %1 bytes]").arg(fi.size());
            }
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
