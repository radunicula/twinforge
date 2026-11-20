#pragma once

#include <QElapsedTimer>
#include <QFileInfo>
#include <QHash>
#include <QList>
#include <QMutex>
#include <QObject>
#include <QPair>
#include <QStringList>
#include <QVariantMap>
#include <QWaitCondition>

#include <atomic>

// Copies or moves a set of files/folders into a target directory.
//
// run() is blocking and meant to be executed on a worker thread. Progress,
// name conflicts and completion are reported through signals; conflicts pause
// the worker until resolveConflict() (or cancel()) is called from any thread.
class FileOperation : public QObject {
    Q_OBJECT

public:
    enum Mode { Copy, Move };
    Q_ENUM(Mode)

    enum ConflictAction { Ask = 0, Overwrite = 1, Skip = 2, Rename = 3, Cancel = 4 };
    Q_ENUM(ConflictAction)

    FileOperation(Mode mode, const QStringList &sources, const QString &targetDir, QObject *parent = nullptr);

    void run();

    // Thread-safe controls.
    void cancel();
    void setPaused(bool paused);
    void pause() { setPaused(true); }
    void resume() { setPaused(false); }
    void resolveConflict(int action, bool applyToAll);

    // Pre-set how conflicts are handled (Ask = prompt via conflict()).
    void setConflictPolicy(ConflictAction action) { m_policy = action; }

    Mode mode() const { return m_mode; }
    bool wasCancelled() const { return m_cancelled.load(); }
    bool isPaused() const { return m_paused.load(); }
    qint64 doneBytes() const { return m_doneBytes; }
    qint64 totalBytes() const { return m_totalBytes; }
    qint64 activeElapsedMs() const;
    int completedCount() const { return m_completed; }
    int skippedCount() const { return m_skipped; }
    int failedCount() const { return m_failed; }
    QString targetDir() const { return m_targetDir; }
    QStringList sources() const { return m_sources; }
    QStringList completedSources() const { return m_completedSources; }
    QStringList remainingSources() const { return m_remainingSources; }
    QString interruptedSource() const { return m_interruptedSource; }
    QString interruptedReason() const { return m_interruptedReason; }
    QStringList errors() const { return m_errors; }
    // Pairs of (newDestPath, originalSrcPath) for non-overwriting moves, suitable for Undo.
    QList<QPair<QString, QString>> movedPairs() const { return m_movedPairs; }

    // True when `path` equals `parent` or lies somewhere below it.
    static bool isSameOrInside(const QString &path, const QString &parent);
    // Returns "name (1).ext", "name (2).ext", ... that does not exist in `dir`.
    static QString uniqueName(const QString &dir, const QString &fileName);
    // Moves a single file/folder/symlink from `src` to exact path `dest` (including across filesystems).
    static bool moveSinglePath(const QString &src, const QString &dest);
    // Reads raw symlink target string (Qt 6.4+ compatible wrapper around readlink / QFileInfo::readSymLink).
    static QString readRawSymLink(const QFileInfo &fi);

signals:
    void progress(qint64 doneBytes, qint64 totalBytes, const QString &currentName);
    void pausedChanged(bool paused);
    void conflict(const QVariantMap &info);
    void finished();

private:
    enum class Result { Ok, Skipped, Failed };
    static Result worst(Result a, Result b);

    qint64 scanSize(const QString &path);
    Result copyEntry(const QString &src, QString dest, bool overwriteConfirmed);
    Result moveEntry(const QString &src, QString dest);
    Result copyFile(const QFileInfo &src, const QString &dest);
    Result copySymlink(const QFileInfo &src, const QString &dest);

    // Resolves an existing destination. Returns Ok to proceed (dest may be
    // rewritten for Rename), Skipped or Failed (cancel / impossible overwrite).
    Result handleConflict(const QFileInfo &src, QString &dest);
    ConflictAction askConflict(const QFileInfo &src, const QFileInfo &dest);

    void fail(const QString &path, const QString &reason);
    void addDone(qint64 bytes, const QString &name, bool force = false);
    void waitIfPaused();

    Mode m_mode;
    QStringList m_sources;
    QString m_targetDir;

    std::atomic<bool> m_cancelled{false};
    std::atomic<bool> m_paused{false};
    ConflictAction m_policy = Ask;

    mutable QMutex m_mutex;
    QWaitCondition m_answered;
    QWaitCondition m_pauseCond;
    bool m_hasAnswer = false;
    ConflictAction m_answer = Skip;
    bool m_answerApplyAll = false;

    qint64 m_totalBytes = 0;
    qint64 m_doneBytes = 0;
    QString m_currentName;
    QElapsedTimer m_progressTimer;
    QElapsedTimer m_runTimer;
    QElapsedTimer m_pauseTimer;
    qint64 m_pausedMs = 0;
    QHash<QString, qint64> m_topLevelSizes;

    int m_completed = 0;
    int m_skipped = 0;
    int m_failed = 0;
    QStringList m_completedSources;
    QStringList m_remainingSources;
    QString m_interruptedSource;
    QString m_interruptedReason;
    QStringList m_errors;
    QList<QPair<QString, QString>> m_movedPairs;
};
