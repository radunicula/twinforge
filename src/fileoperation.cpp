#include "fileoperation.h"

#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QRandomGenerator>
#include <QSaveFile>
#include <QTemporaryDir>

#include <cerrno>
#include <cstdio>
#include <cstring>
#include <unistd.h>

namespace {

// QFileInfo::exists() is false for dangling symlinks, but they still occupy the name.
bool pathExists(const QFileInfo &fi)
{
    return fi.exists() || fi.isSymLink();
}

bool isRealDir(const QFileInfo &fi)
{
    return fi.isDir() && !fi.isSymLink();
}

QString errnoString(int err)
{
    return QString::fromLocal8Bit(std::strerror(err));
}

// Canonical path even for paths that do not exist yet (resolves the deepest existing parent).
QString canonicalish(const QString &path)
{
    QFileInfo fi(path);
    const QString canonical = fi.canonicalFilePath();
    if (!canonical.isEmpty())
        return canonical;
    const QString parent = fi.absolutePath();
    if (parent == fi.absoluteFilePath())
        return QDir::cleanPath(fi.absoluteFilePath());
    return QDir::cleanPath(canonicalish(parent) + "/" + fi.fileName());
}

constexpr QDir::Filters kAllEntries = QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot;

} // namespace

FileOperation::FileOperation(Mode mode, const QStringList &sources, const QString &targetDir, QObject *parent)
    : QObject(parent), m_mode(mode), m_sources(sources), m_targetDir(targetDir)
{
}

bool FileOperation::isSameOrInside(const QString &path, const QString &parent)
{
    const QString p = canonicalish(path);
    const QString q = canonicalish(parent);
    if (q == "/")
        return true;
    return p == q || p.startsWith(q + "/");
}

QString FileOperation::uniqueName(const QString &dir, const QString &fileName)
{
    QString base = fileName;
    QString ext;
    const int lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
        base = fileName.left(lastDot);
        ext = fileName.mid(lastDot);
        if (base.endsWith(".tar", Qt::CaseInsensitive)) {
            base.chop(4);
            ext.prepend(".tar");
        }
    }

    const QDir d(dir);
    for (int i = 1;; ++i) {
        const QString candidate = d.filePath(QString("%1 (%2)%3").arg(base).arg(i).arg(ext));
        if (!pathExists(QFileInfo(candidate)))
            return candidate;
    }
}

bool FileOperation::moveSinglePath(const QString &src, const QString &dest)
{
    const QFileInfo si(src);
    if (!pathExists(si) || pathExists(QFileInfo(dest)))
        return false;

    QFileInfo destInfo(dest);
    if (!QDir().mkpath(destInfo.absolutePath()))
        return false;

    if (::rename(QFile::encodeName(src).constData(), QFile::encodeName(dest).constData()) == 0)
        return true;
    if (errno != EXDEV)
        return false;

    // Cross-filesystem fallback: stage inside a temp directory beside `dest`, then atomic-rename into place.
    QTemporaryDir stageDir(destInfo.absolutePath() + "/.omapanel-move-XXXXXX");
    if (!stageDir.isValid())
        return false;

    FileOperation op(Copy, {src}, stageDir.path());
    op.setConflictPolicy(Cancel);
    op.run();
    if (op.completedCount() != 1 || op.failedCount() > 0)
        return false;

    const QString stagedPath = QDir(stageDir.path()).filePath(si.fileName());
    if (::rename(QFile::encodeName(stagedPath).constData(), QFile::encodeName(dest).constData()) != 0)
        return false;

    return isRealDir(si) ? QDir(src).removeRecursively() : QFile::remove(src);
}

void FileOperation::cancel()
{
    m_cancelled = true;
    {
        QMutexLocker lock(&m_mutex);
        m_paused = false;
        m_answered.wakeAll();
        m_pauseCond.wakeAll();
    }
}

void FileOperation::setPaused(bool paused)
{
    bool changed = false;
    {
        QMutexLocker lock(&m_mutex);
        const bool cur = m_paused.load();
        if (cur != paused) {
            changed = true;
            if (paused) {
                m_paused = true;
                m_pauseTimer.start();
            } else {
                if (m_pauseTimer.isValid()) {
                    m_pausedMs += m_pauseTimer.elapsed();
                    m_pauseTimer.invalidate();
                }
                m_paused = false;
                m_pauseCond.wakeAll();
            }
        }
    }
    if (changed)
        emit pausedChanged(paused);
}

qint64 FileOperation::activeElapsedMs() const
{
    QMutexLocker lock(&m_mutex);
    if (!m_runTimer.isValid())
        return 0;
    const qint64 total = m_runTimer.elapsed();
    qint64 paused = m_pausedMs;
    if (m_paused.load() && m_pauseTimer.isValid())
        paused += m_pauseTimer.elapsed();
    return std::max<qint64>(1, total - paused);
}

void FileOperation::waitIfPaused()
{
    if (!m_paused.load() || m_cancelled.load())
        return;
    QMutexLocker lock(&m_mutex);
    while (m_paused.load() && !m_cancelled.load())
        m_pauseCond.wait(&m_mutex, 100);
}

void FileOperation::resolveConflict(int action, bool applyToAll)
{
    QMutexLocker lock(&m_mutex);
    m_answer = (action >= Overwrite && action <= Cancel) ? static_cast<ConflictAction>(action) : Skip;
    m_answerApplyAll = applyToAll;
    m_hasAnswer = true;
    m_answered.wakeAll();
}

void FileOperation::run()
{
    {
        QMutexLocker lock(&m_mutex);
        m_runTimer.start();
        m_pausedMs = 0;
        if (m_paused.load())
            m_pauseTimer.start();
    }
    m_progressTimer.start();

    if (!QFileInfo(m_targetDir).isDir()) {
        fail(m_targetDir, tr("Target folder does not exist"));
        m_failed = m_sources.size();
        emit finished();
        return;
    }

    for (const QString &src : std::as_const(m_sources)) {
        waitIfPaused();
        if (m_cancelled)
            break;
        const qint64 size = scanSize(src);
        m_topLevelSizes.insert(src, size);
        m_totalBytes += size;
    }
    addDone(0, {}, true);

    const QString targetCanonical = canonicalish(m_targetDir);
    for (const QString &src : std::as_const(m_sources)) {
        waitIfPaused();
        if (m_cancelled)
            break;

        const QFileInfo si(src);
        if (!pathExists(si)) {
            fail(src, tr("Source no longer exists"));
            ++m_failed;
            continue;
        }

        if (isRealDir(si) && isSameOrInside(m_targetDir, src)) {
            fail(src, m_mode == Copy ? tr("Cannot copy a folder into itself")
                                     : tr("Cannot move a folder into itself"));
            ++m_failed;
            continue;
        }

        QString dest = QDir(m_targetDir).filePath(si.fileName());
        const bool sameFolder = canonicalish(si.absolutePath()) == targetCanonical;

        Result result;
        if (sameFolder) {
            if (m_mode == Move) {
                addDone(m_topLevelSizes.value(src), si.fileName());
                ++m_skipped;
                continue;
            }
            // Copy onto itself: duplicate next to the original.
            dest = uniqueName(m_targetDir, si.fileName());
            result = copyEntry(src, dest, false);
        } else {
            result = (m_mode == Copy) ? copyEntry(src, dest, false) : moveEntry(src, dest);
        }

        switch (result) {
        case Result::Ok: ++m_completed; break;
        case Result::Skipped: ++m_skipped; break;
        case Result::Failed: ++m_failed; break;
        }
    }

    addDone(0, {}, true);
    emit finished();
}

qint64 FileOperation::scanSize(const QString &path)
{
    const QFileInfo fi(path);
    if (fi.isSymLink())
        return 0;
    if (!fi.isDir())
        return fi.size();

    qint64 total = 0;
    // No FollowSymlinks: symlinked folders are copied as links, so they don't count.
    QDirIterator it(path, kAllEntries, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        if (m_cancelled)
            break;
        it.next();
        const QFileInfo f = it.fileInfo();
        if (!f.isSymLink() && f.isFile())
            total += f.size();
    }
    return total;
}

FileOperation::ConflictAction FileOperation::askConflict(const QFileInfo &src, const QFileInfo &dest)
{
    if (m_policy != Ask)
        return m_policy;

    QVariantMap info;
    info["name"] = dest.fileName();
    info["sourcePath"] = src.absoluteFilePath();
    info["destPath"] = dest.absoluteFilePath();
    info["sourceIsDir"] = isRealDir(src);
    info["destIsDir"] = isRealDir(dest);
    info["sourceSize"] = src.isSymLink() ? 0 : src.size();
    info["destSize"] = dest.isSymLink() ? 0 : dest.size();
    info["sourceModified"] = src.lastModified();
    info["destModified"] = dest.lastModified();

    {
        QMutexLocker lock(&m_mutex);
        m_hasAnswer = false;
    }
    emit conflict(info);

    QMutexLocker lock(&m_mutex);
    while (!m_hasAnswer && !m_cancelled)
        m_answered.wait(&m_mutex);
    if (m_cancelled)
        return Cancel;
    if (m_answerApplyAll && m_answer != Cancel)
        m_policy = m_answer;
    return m_answer;
}

FileOperation::Result FileOperation::handleConflict(const QFileInfo &src, QString &dest)
{
    const QFileInfo di(dest);
    if (!pathExists(di))
        return Result::Ok;

    switch (askConflict(src, di)) {
    case Skip:
        return Result::Skipped;
    case Rename:
        dest = uniqueName(di.absolutePath(), di.fileName());
        return Result::Ok;
    case Overwrite:
        if (isRealDir(src) != isRealDir(di)) {
            fail(dest, isRealDir(src) ? tr("Cannot replace a file with a folder")
                                      : tr("Cannot replace a folder with a file"));
            return Result::Failed;
        }
        return Result::Ok;
    case Ask:
    case Cancel:
        break;
    }
    cancel();
    return Result::Skipped;
}

FileOperation::Result FileOperation::copyEntry(const QString &src, QString dest, bool overwriteConfirmed)
{
    waitIfPaused();
    if (m_cancelled)
        return Result::Skipped;

    const QFileInfo si(src);

    if (si.isSymLink()) {
        if (!overwriteConfirmed) {
            const Result r = handleConflict(si, dest);
            if (r != Result::Ok)
                return r;
        }
        return copySymlink(si, dest);
    }

    if (si.isDir()) {
        QFileInfo di(dest);
        if (pathExists(di) && !isRealDir(di)) {
            // A file or link is in the way; existing folders are merged instead.
            if (!overwriteConfirmed) {
                const Result r = handleConflict(si, dest);
                if (r != Result::Ok)
                    return r;
            }
            di = QFileInfo(dest);
        }
        if (!pathExists(di) && !QDir().mkdir(dest)) {
            fail(dest, tr("Cannot create folder"));
            return Result::Failed;
        }

        Result result = Result::Ok;
        const QStringList entries = QDir(src).entryList(kAllEntries);
        for (const QString &entry : entries) {
            if (m_cancelled) {
                result = worst(result, Result::Skipped);
                break;
            }
            result = worst(result, copyEntry(src + "/" + entry, dest + "/" + entry, false));
        }
        // Applied last so read-only folders can still be filled.
        QFile::setPermissions(dest, si.permissions());
        return result;
    }

    if (!si.isFile()) {
        fail(src, si.exists() ? tr("Special files (sockets, pipes, devices) are not copied")
                              : tr("Source no longer exists"));
        return Result::Failed;
    }

    if (!overwriteConfirmed) {
        const Result r = handleConflict(si, dest);
        if (r != Result::Ok)
            return r;
    }
    return copyFile(si, dest);
}

FileOperation::Result FileOperation::copySymlink(const QFileInfo &src, const QString &dest)
{
    const QByteArray target = QFile::encodeName(src.readSymLink());
    const QByteArray destName = QFile::encodeName(dest);

    if (!pathExists(QFileInfo(dest))) {
        if (::symlink(target.constData(), destName.constData()) != 0) {
            fail(dest, errnoString(errno));
            return Result::Failed;
        }
    } else {
        // Replace atomically: create the link under a temporary name, then rename over.
        const QString tmp = QString("%1/.omapanel-%2.tmp").arg(QFileInfo(dest).absolutePath())
                                .arg(QRandomGenerator::global()->generate64(), 0, 16);
        const QByteArray tmpName = QFile::encodeName(tmp);
        if (::symlink(target.constData(), tmpName.constData()) != 0) {
            fail(dest, errnoString(errno));
            return Result::Failed;
        }
        if (::rename(tmpName.constData(), destName.constData()) != 0) {
            const int err = errno;
            ::unlink(tmpName.constData());
            fail(dest, errnoString(err));
            return Result::Failed;
        }
    }
    addDone(0, src.fileName());
    return Result::Ok;
}

FileOperation::Result FileOperation::copyFile(const QFileInfo &src, const QString &dest)
{
    addDone(0, src.fileName(), true);

    QFile in(src.absoluteFilePath());
    if (!in.open(QIODevice::ReadOnly)) {
        fail(src.absoluteFilePath(), in.errorString());
        return Result::Failed;
    }

    // Never write through a symlink that is being replaced; replace the link itself.
    if (QFileInfo(dest).isSymLink() && !QFile::remove(dest)) {
        fail(dest, tr("Cannot replace existing file"));
        return Result::Failed;
    }

    // QSaveFile writes to a temporary file and renames it into place on commit, so an
    // existing file is only replaced once the new copy is complete.
    QSaveFile out(dest);
    out.setDirectWriteFallback(false);
    if (!out.open(QIODevice::WriteOnly)) {
        fail(dest, out.errorString());
        return Result::Failed;
    }

    QByteArray buffer(256 * 1024, Qt::Uninitialized);
    while (true) {
        waitIfPaused();
        if (m_cancelled) {
            out.cancelWriting();
            return Result::Skipped;
        }
        const qint64 n = in.read(buffer.data(), buffer.size());
        if (n < 0) {
            out.cancelWriting();
            fail(src.absoluteFilePath(), in.errorString());
            return Result::Failed;
        }
        if (n == 0)
            break;
        if (out.write(buffer.constData(), n) != n) {
            const QString error = out.errorString();
            out.cancelWriting();
            fail(dest, error);
            return Result::Failed;
        }
        addDone(n, src.fileName());
    }

    out.flush();
    out.setFileTime(src.lastModified(), QFileDevice::FileModificationTime);
    if (!out.commit()) {
        fail(dest, out.errorString());
        return Result::Failed;
    }
    QFile::setPermissions(dest, src.permissions());
    return Result::Ok;
}

FileOperation::Result FileOperation::moveEntry(const QString &src, QString dest)
{
    waitIfPaused();
    if (m_cancelled)
        return Result::Skipped;

    const QFileInfo si(src);
    if (!pathExists(si)) {
        fail(src, tr("Source no longer exists"));
        return Result::Failed;
    }
    m_currentName = si.fileName();

    const QFileInfo di(dest);
    if (isRealDir(si) && isRealDir(di)) {
        // Merge into the existing folder; conflicts are resolved per entry.
        Result result = Result::Ok;
        const QStringList entries = QDir(src).entryList(kAllEntries);
        for (const QString &entry : entries) {
            if (m_cancelled) {
                result = worst(result, Result::Skipped);
                break;
            }
            result = worst(result, moveEntry(src + "/" + entry, dest + "/" + entry));
        }
        if (result == Result::Ok && !QDir().rmdir(src)) {
            fail(src, tr("Moved contents, but the source folder could not be removed"));
            return Result::Failed;
        }
        return result;
    }

    bool overwrite = false;
    if (pathExists(di)) {
        const Result r = handleConflict(si, dest);
        if (r != Result::Ok)
            return r;
        overwrite = pathExists(QFileInfo(dest));
    }

    const qint64 size = m_topLevelSizes.contains(src) ? m_topLevelSizes.value(src) : scanSize(src);

    // rename(2) replaces an existing file atomically.
    if (::rename(QFile::encodeName(src).constData(), QFile::encodeName(dest).constData()) == 0) {
        if (!overwrite)
            m_movedPairs.append({dest, src});
        addDone(size, si.fileName());
        return Result::Ok;
    }
    if (errno != EXDEV) {
        fail(src, errnoString(errno));
        return Result::Failed;
    }

    // Different filesystem: copy, and only remove the source once the copy fully succeeded.
    const Result r = copyEntry(src, dest, overwrite);
    if (r != Result::Ok)
        return r;
    const bool removed = isRealDir(si) ? QDir(src).removeRecursively() : QFile::remove(src);
    if (!removed) {
        fail(src, tr("Copied, but the source could not be removed"));
        return Result::Failed;
    }
    if (!overwrite)
        m_movedPairs.append({dest, src});
    return Result::Ok;
}

FileOperation::Result FileOperation::worst(Result a, Result b)
{
    return static_cast<int>(a) >= static_cast<int>(b) ? a : b;
}

void FileOperation::fail(const QString &path, const QString &reason)
{
    m_errors.append(QString("%1: %2").arg(QFileInfo(path).fileName(), reason));
}

void FileOperation::addDone(qint64 bytes, const QString &name, bool force)
{
    m_doneBytes += bytes;
    if (!name.isEmpty())
        m_currentName = name;
    if (force || m_progressTimer.elapsed() >= 50) {
        m_progressTimer.restart();
        emit progress(m_doneBytes, m_totalBytes, m_currentName);
    }
}
