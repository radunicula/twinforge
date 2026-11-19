#pragma once

#include <QImage>
#include <QQuickAsyncImageProvider>
#include <QString>
#include <QThreadPool>

#include <atomic>
#include <memory>

class ThumbnailProvider : public QQuickAsyncImageProvider {
public:
    ThumbnailProvider();
    ~ThumbnailProvider() override;

    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

    // Freedesktop Thumbnail Managing Standard helpers (also used by tests).
    static QString thumbnailCacheRoot();
    static QString canonicalUriForPath(const QString &filePath);
    static QString cacheFilePathFor(const QString &filePath, bool large = true);
    static QString decodeRequestPath(const QString &id);
    static bool supportsThumbnailForPath(const QString &filePath);
    static QImage loadOrGenerateThumbnail(const QString &filePath,
                                          const QSize &requestedSize,
                                          const std::atomic<bool> *cancelFlag = nullptr,
                                          bool *outFromCache = nullptr);

private:
    QThreadPool m_pool;
};
