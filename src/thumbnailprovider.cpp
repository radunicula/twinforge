#include "thumbnailprovider.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QProcess>
#include <QQuickTextureFactory>
#include <QRunnable>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QThread>
#include <QUrl>
#include <QUuid>

#include <algorithm>

namespace {

bool isCancelled(const std::atomic<bool> *flag)
{
    return flag && flag->load(std::memory_order_relaxed);
}

bool waitProcessCancelable(QProcess &proc, int timeoutMs, const std::atomic<bool> *cancelFlag)
{
    int elapsed = 0;
    constexpr int stepMs = 40;
    while (proc.state() != QProcess::NotRunning && elapsed < timeoutMs) {
        if (isCancelled(cancelFlag)) {
            proc.kill();
            proc.waitForFinished(200);
            return false;
        }
        if (proc.waitForFinished(stepMs))
            return true;
        elapsed += stepMs;
    }
    if (proc.state() != QProcess::NotRunning) {
        proc.kill();
        proc.waitForFinished(200);
        return false;
    }
    return true;
}

bool isImageExtension(const QString &ext)
{
    return ext == QLatin1String("png") || ext == QLatin1String("jpg") || ext == QLatin1String("jpeg")
           || ext == QLatin1String("webp") || ext == QLatin1String("bmp") || ext == QLatin1String("gif")
           || ext == QLatin1String("tiff") || ext == QLatin1String("tif") || ext == QLatin1String("ico")
           || ext == QLatin1String("avif") || ext == QLatin1String("heic") || ext == QLatin1String("heif")
           || ext == QLatin1String("svg") || ext == QLatin1String("svgz");
}

bool isVideoExtension(const QString &ext)
{
    return ext == QLatin1String("mp4") || ext == QLatin1String("mkv") || ext == QLatin1String("avi")
           || ext == QLatin1String("webm") || ext == QLatin1String("mov") || ext == QLatin1String("m4v")
           || ext == QLatin1String("flv") || ext == QLatin1String("wmv") || ext == QLatin1String("mpg")
           || ext == QLatin1String("mpeg");
}

QImage generateImageThumbnail(const QString &filePath, int maxDim, const std::atomic<bool> *cancelFlag)
{
    if (isCancelled(cancelFlag))
        return {};

    QImageReader reader(filePath);
    reader.setAutoTransform(true);
    const QSize origSize = reader.size();
    if (origSize.isValid() && (origSize.width() > maxDim || origSize.height() > maxDim)) {
        reader.setScaledSize(origSize.scaled(maxDim, maxDim, Qt::KeepAspectRatio));
    }

    QImage img = reader.read();
    if (img.isNull() || isCancelled(cancelFlag))
        return {};

    if (img.width() > maxDim || img.height() > maxDim) {
        img = img.scaled(maxDim, maxDim, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return img;
}

QImage generateVideoThumbnail(const QString &filePath, int maxDim, const std::atomic<bool> *cancelFlag)
{
    if (isCancelled(cancelFlag))
        return {};

    const QString tmpBase = QDir::temp().filePath(
        QStringLiteral("twinforge_vthumb_%1.png").arg(QUuid::createUuid().toString(QUuid::Id128)));

    QImage img;
    const QString thumbBin = QStandardPaths::findExecutable(QStringLiteral("ffmpegthumbnailer"));
    if (!thumbBin.isEmpty()) {
        QProcess proc;
        proc.start(thumbBin, {QStringLiteral("-i"), filePath, QStringLiteral("-o"), tmpBase,
                              QStringLiteral("-s"), QString::number(maxDim)});
        if (waitProcessCancelable(proc, 4000, cancelFlag) && proc.exitCode() == 0 && QFileInfo::exists(tmpBase)) {
            img.load(tmpBase);
        }
        QFile::remove(tmpBase);
        if (!img.isNull())
            return img;
    }

    if (isCancelled(cancelFlag))
        return {};

    const QString ffmpegBin = QStandardPaths::findExecutable(QStringLiteral("ffmpeg"));
    if (!ffmpegBin.isEmpty()) {
        const QString scaleFilter = QStringLiteral("scale=%1:%1:force_original_aspect_ratio=decrease").arg(maxDim);
        for (const QString &seekPos : {QStringLiteral("00:00:01"), QStringLiteral("00:00:00")}) {
            if (isCancelled(cancelFlag))
                break;
            QProcess proc;
            proc.start(ffmpegBin, {QStringLiteral("-y"), QStringLiteral("-loglevel"), QStringLiteral("error"),
                                   QStringLiteral("-ss"), seekPos, QStringLiteral("-i"), filePath,
                                   QStringLiteral("-frames:v"), QStringLiteral("1"),
                                   QStringLiteral("-vf"), scaleFilter, tmpBase});
            if (waitProcessCancelable(proc, 4500, cancelFlag) && proc.exitCode() == 0 && QFileInfo::exists(tmpBase)) {
                img.load(tmpBase);
            }
            QFile::remove(tmpBase);
            if (!img.isNull())
                return img;
        }
    }

    return {};
}

QImage generatePdfThumbnail(const QString &filePath, int maxDim, const std::atomic<bool> *cancelFlag)
{
    if (isCancelled(cancelFlag))
        return {};

    const QString pdftoppmBin = QStandardPaths::findExecutable(QStringLiteral("pdftoppm"));
    if (pdftoppmBin.isEmpty())
        return {};

    const QString tmpPrefix = QDir::temp().filePath(
        QStringLiteral("twinforge_pthumb_%1").arg(QUuid::createUuid().toString(QUuid::Id128)));
    const QString tmpPng = tmpPrefix + QStringLiteral(".png");

    QProcess proc;
    proc.start(pdftoppmBin, {QStringLiteral("-png"), QStringLiteral("-singlefile"),
                             QStringLiteral("-f"), QStringLiteral("1"),
                             QStringLiteral("-l"), QStringLiteral("1"),
                             QStringLiteral("-scale-to"), QString::number(maxDim),
                             filePath, tmpPrefix});

    QImage img;
    if (waitProcessCancelable(proc, 4500, cancelFlag) && proc.exitCode() == 0 && QFileInfo::exists(tmpPng)) {
        img.load(tmpPng);
    }
    QFile::remove(tmpPng);
    return img;
}

class ThumbnailResponse : public QQuickImageResponse {
public:
    ThumbnailResponse(const QString &id, const QSize &requestedSize, QThreadPool *pool)
        : m_cancelFlag(std::make_shared<std::atomic<bool>>(false))
    {
        const QString filePath = ThumbnailProvider::decodeRequestPath(id);
        const std::shared_ptr<std::atomic<bool>> cancel = m_cancelFlag;

        auto *task = QRunnable::create([this, filePath, requestedSize, cancel]() {
            if (!cancel->load(std::memory_order_relaxed)) {
                QImage img = ThumbnailProvider::loadOrGenerateThumbnail(filePath, requestedSize, cancel.get());
                if (!cancel->load(std::memory_order_relaxed)) {
                    m_image = std::move(img);
                    if (m_image.isNull())
                        m_error = QStringLiteral("Thumbnail unavailable");
                }
            }
            QMetaObject::invokeMethod(this, [this]() {
                emit finished();
            }, Qt::QueuedConnection);
        });
        task->setAutoDelete(true);
        pool->start(task);
    }

    QQuickTextureFactory *textureFactory() const override
    {
        if (m_image.isNull())
            return nullptr;
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

    QString errorString() const override { return m_error; }

    void cancel() override
    {
        m_cancelFlag->store(true, std::memory_order_relaxed);
    }

private:
    std::shared_ptr<std::atomic<bool>> m_cancelFlag;
    QImage m_image;
    QString m_error;
};

} // namespace

ThumbnailProvider::ThumbnailProvider()
{
    const int threads = std::clamp(QThread::idealThreadCount() / 2, 2, 4);
    m_pool.setMaxThreadCount(threads);
}

ThumbnailProvider::~ThumbnailProvider()
{
    m_pool.clear();
    m_pool.waitForDone(3000);
}

QQuickImageResponse *ThumbnailProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    return new ThumbnailResponse(id, requestedSize, &m_pool);
}

QString ThumbnailProvider::thumbnailCacheRoot()
{
    const QByteArray overrideDir = qgetenv("TWINFORGE_THUMBNAIL_CACHE_DIR");
    if (!overrideDir.isEmpty())
        return QString::fromUtf8(overrideDir);

    const QByteArray xdgCache = qgetenv("XDG_CACHE_HOME");
    if (!xdgCache.isEmpty())
        return QDir(QString::fromUtf8(xdgCache)).filePath(QStringLiteral("thumbnails"));

    return QDir(QDir::homePath()).filePath(QStringLiteral(".cache/thumbnails"));
}

QString ThumbnailProvider::canonicalUriForPath(const QString &filePath)
{
    const QFileInfo fi(filePath);
    QString absPath = fi.canonicalFilePath();
    if (absPath.isEmpty())
        absPath = fi.absoluteFilePath();
    return QString::fromUtf8(QUrl::fromLocalFile(absPath).toEncoded());
}

QString ThumbnailProvider::cacheFilePathFor(const QString &filePath, bool large)
{
    const QString uri = canonicalUriForPath(filePath);
    const QByteArray hash = QCryptographicHash::hash(uri.toUtf8(), QCryptographicHash::Md5).toHex();
    const QString subDir = large ? QStringLiteral("large") : QStringLiteral("normal");
    return QDir(thumbnailCacheRoot()).filePath(subDir + QLatin1Char('/') + QString::fromLatin1(hash) + QStringLiteral(".png"));
}

QString ThumbnailProvider::decodeRequestPath(const QString &id)
{
    QString raw = id;
    const int qIdx = raw.indexOf(QLatin1Char('?'));
    if (qIdx != -1)
        raw = raw.left(qIdx);
    QString decoded = QUrl::fromPercentEncoding(raw.toUtf8());
    if (!decoded.startsWith(QLatin1Char('/')) && QFileInfo::exists(QLatin1Char('/') + decoded))
        decoded.prepend(QLatin1Char('/'));
    return decoded;
}

bool ThumbnailProvider::supportsThumbnailForPath(const QString &filePath)
{
    const QString ext = QFileInfo(filePath).suffix().toLower();
    return isImageExtension(ext) || isVideoExtension(ext) || ext == QLatin1String("pdf");
}

QImage ThumbnailProvider::loadOrGenerateThumbnail(const QString &filePath,
                                                  const QSize &requestedSize,
                                                  const std::atomic<bool> *cancelFlag,
                                                  bool *outFromCache)
{
    if (outFromCache)
        *outFromCache = false;
    if (filePath.isEmpty() || isCancelled(cancelFlag))
        return {};

    const QFileInfo fi(filePath);
    if (!fi.exists() || !fi.isFile() || !fi.isReadable())
        return {};

    // Per Freedesktop spec, never thumbnail files inside the thumbnail cache itself.
    const QString cacheRoot = QDir::cleanPath(thumbnailCacheRoot());
    const QString absFile = fi.canonicalFilePath().isEmpty() ? fi.absoluteFilePath() : fi.canonicalFilePath();
    if (!cacheRoot.isEmpty() && QDir::cleanPath(absFile).startsWith(cacheRoot + QLatin1Char('/')))
        return {};

    const bool useLarge = !requestedSize.isValid() || requestedSize.width() > 128 || requestedSize.height() > 128;
    const int maxDim = useLarge ? 256 : 128;
    const qint64 mtimeSecs = fi.lastModified().toSecsSinceEpoch();
    const qint64 fileSize = fi.size();
    const QString mtimeStr = QString::number(mtimeSecs);
    const QString sizeStr = QString::number(fileSize);

    const QString cachePath = cacheFilePathFor(absFile, useLarge);
    if (QFileInfo::exists(cachePath)) {
        QImageReader cachedReader(cachePath, "png");
        QImage cached = cachedReader.read();
        if (!cached.isNull()) {
            const QString cachedMtime = cached.text(QStringLiteral("Thumb::MTime"));
            const QString cachedSize = cached.text(QStringLiteral("Thumb::Size"));
            const bool mtimeMatches = (cachedMtime == mtimeStr);
            const bool sizeMatches = cachedSize.isEmpty() || (cachedSize == sizeStr);
            if (mtimeMatches && sizeMatches) {
                if (outFromCache)
                    *outFromCache = true;
                if (requestedSize.isValid() && (cached.width() > requestedSize.width() || cached.height() > requestedSize.height())) {
                    cached = cached.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                }
                return cached;
            }
        }
    }

    if (isCancelled(cancelFlag))
        return {};

    const QString ext = fi.suffix().toLower();
    QImage thumb;
    if (isImageExtension(ext)) {
        thumb = generateImageThumbnail(absFile, maxDim, cancelFlag);
    } else if (isVideoExtension(ext)) {
        thumb = generateVideoThumbnail(absFile, maxDim, cancelFlag);
    } else if (ext == QLatin1String("pdf")) {
        thumb = generatePdfThumbnail(absFile, maxDim, cancelFlag);
    }

    if (thumb.isNull() || isCancelled(cancelFlag))
        return {};

    // Save to Freedesktop cache atomically with 0700 dir / 0600 file permissions.
    const QString cacheDirPath = QFileInfo(cachePath).absolutePath();
    if (QDir().mkpath(cacheDirPath)) {
        QFile::setPermissions(cacheRoot, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
        QFile::setPermissions(cacheDirPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);

        QImage toSave = thumb;
        toSave.setText(QStringLiteral("Thumb::URI"), canonicalUriForPath(absFile));
        toSave.setText(QStringLiteral("Thumb::MTime"), mtimeStr);
        toSave.setText(QStringLiteral("Thumb::Size"), sizeStr);
        toSave.setText(QStringLiteral("Software"), QStringLiteral("TwinForge"));

        const QString tmpSave = cacheDirPath + QStringLiteral("/.tmp-")
                                + QUuid::createUuid().toString(QUuid::Id128) + QStringLiteral(".png");
        if (toSave.save(tmpSave, "PNG")) {
            QFile::setPermissions(tmpSave, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
            QFile::remove(cachePath);
            if (!QFile::rename(tmpSave, cachePath))
                QFile::remove(tmpSave);
        } else {
            QFile::remove(tmpSave);
        }
    }

    if (requestedSize.isValid() && (thumb.width() > requestedSize.width() || thumb.height() > requestedSize.height())) {
        thumb = thumb.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return thumb;
}
