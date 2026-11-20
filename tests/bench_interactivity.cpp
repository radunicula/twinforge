#include <QCoreApplication>
#include <QDir>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTemporaryDir>
#include <QTextStream>
#include <QThreadPool>
#include <QTimer>

#include <algorithm>
#include <array>
#include <fcntl.h>
#include <unistd.h>

#include "backend.h"
#include "panelmodel.h"

namespace {

bool writeFastFile(const QByteArray &pathUtf8, const char *buf, size_t len)
{
    const int fd = ::open(pathUtf8.constData(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0)
        return false;
    const ssize_t written = ::write(fd, buf, len);
    ::close(fd);
    return written == static_cast<ssize_t>(len);
}

QString fmtMs(double ms)
{
    return QString::number(ms, 'f', 2) + QStringLiteral(" ms");
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("twinforge-bench"));

    int numFiles = qEnvironmentVariableIntValue("TWINFORGE_BENCH_FILES");
    if (numFiles <= 0)
        numFiles = 50000;
    int numSubdirs = 40;
    bool jsonOut = false;

    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        if (args.at(i) == QLatin1String("--files") && i + 1 < args.size()) {
            bool ok = false;
            const int v = args.at(++i).toInt(&ok);
            if (ok && v >= 200)
                numFiles = v;
        } else if (args.at(i) == QLatin1String("--subdirs") && i + 1 < args.size()) {
            bool ok = false;
            const int v = args.at(++i).toInt(&ok);
            if (ok && v >= 1)
                numSubdirs = v;
        } else if (args.at(i) == QLatin1String("--json")) {
            jsonOut = true;
        }
    }

    QTemporaryDir tempRoot;
    if (!tempRoot.isValid()) {
        QTextStream(stderr) << "Failed to create temporary benchmark directory.\n";
        return 1;
    }

    const QString xdgConfig = tempRoot.filePath(QStringLiteral("xdg_cfg"));
    const QString xdgCache = tempRoot.filePath(QStringLiteral("xdg_cache"));
    QDir().mkpath(xdgConfig);
    QDir().mkpath(xdgCache);
    qputenv("XDG_CONFIG_HOME", xdgConfig.toUtf8());
    qputenv("XDG_CACHE_HOME", xdgCache.toUtf8());

    const QString heavyDir = tempRoot.filePath(QStringLiteral("heavy"));
    const QString smallDir = tempRoot.filePath(QStringLiteral("small"));
    QDir().mkpath(heavyDir);
    QDir().mkpath(smallDir);

    std::array<char, 1024> buf{};
    buf.fill('T');

    const int filesPerSub = (numFiles >= numSubdirs * 4)
                                ? std::min(50, numFiles / (numSubdirs * 2))
                                : 0;
    const int nestedFiles = numSubdirs * filesPerSub;
    const int rootFiles = numFiles - nestedFiles;

    QElapsedTimer setupTimer;
    setupTimer.start();

    for (int d = 0; d < numSubdirs; ++d) {
        const QString subName = QStringLiteral("sub_%1").arg(d, 3, 10, QLatin1Char('0'));
        const QString subPath = heavyDir + QLatin1Char('/') + subName;
        QDir().mkpath(subPath);
        const QByteArray subPrefix = (subPath + QLatin1Char('/')).toUtf8();
        for (int f = 0; f < filesPerSub; ++f) {
            const QByteArray p = subPrefix + QByteArrayLiteral("nested_")
                                 + QByteArray::number(f).rightJustified(3, '0') + QByteArrayLiteral(".log");
            const size_t sz = static_cast<size_t>(((d + f) % 7) * 128 + 32);
            if (!writeFastFile(p, buf.data(), sz)) {
                QTextStream(stderr) << "Failed creating benchmark fixture file.\n";
                return 1;
            }
        }
    }

    const QByteArray heavyPrefix = (heavyDir + QLatin1Char('/')).toUtf8();
    for (int i = 0; i < rootFiles; ++i) {
        const QByteArray p = heavyPrefix + QByteArrayLiteral("item_")
                             + QByteArray::number(i).rightJustified(5, '0')
                             + ((i % 2 == 0) ? QByteArrayLiteral(".txt") : QByteArrayLiteral(".log"));
        const size_t sz = static_cast<size_t>((i % 8) * 128 + 16);
        if (!writeFastFile(p, buf.data(), sz)) {
            QTextStream(stderr) << "Failed creating root benchmark fixture file.\n";
            return 1;
        }
    }

    writeFastFile((smallDir + QStringLiteral("/alpha.txt")).toUtf8(), buf.data(), 64);
    writeFastFile((smallDir + QStringLiteral("/beta.txt")).toUtf8(), buf.data(), 128);
    const double fixtureSetupMs = setupTimer.nsecsElapsed() / 1e6;

    const int expectedHeavyCount = rootFiles + numSubdirs + 1; // +1 for ".."

    // 1. Cold load + sort of heavy directory
    QElapsedTimer timer;
    timer.start();
    PanelModel panel(heavyDir);
    const double load50kMs = timer.nsecsElapsed() / 1e6;
    if (panel.itemCount() != expectedHeavyCount) {
        QTextStream(stderr) << "Unexpected item count: " << panel.itemCount()
                            << " expected " << expectedHeavyCount << "\n";
        return 1;
    }

    // 2. First viewport access (40 rows x 5 roles)
    timer.restart();
    const int viewportRows = std::min(40, panel.rowCount());
    for (int row = 0; row < viewportRows; ++row) {
        const QModelIndex idx = panel.index(row, 0);
        const QVariant vName = panel.data(idx, PanelModel::NameRole);
        const QVariant vSize = panel.data(idx, PanelModel::FormattedSizeRole);
        const QVariant vMod = panel.data(idx, PanelModel::ModifiedRole);
        const QVariant vPerm = panel.data(idx, PanelModel::PermissionsRole);
        const QVariant vIcon = panel.data(idx, PanelModel::IconTypeRole);
        Q_UNUSED(vName);
        Q_UNUSED(vSize);
        Q_UNUSED(vMod);
        Q_UNUSED(vPerm);
        Q_UNUSED(vIcon);
    }
    const double firstViewportMs = timer.nsecsElapsed() / 1e6;

    // 3. Live filter + clear across 50k items
    timer.restart();
    panel.setFilter(QStringLiteral("item_042"));
    const int filteredCount = panel.itemCount();
    panel.setFilter(QString());
    const double filter50kMs = timer.nsecsElapsed() / 1e6;
    if (filteredCount <= 1 || panel.itemCount() != expectedHeavyCount) {
        QTextStream(stderr) << "Filter benchmark invariant failed.\n";
        return 1;
    }

    // 4. Sort by Size across 50k items
    timer.restart();
    panel.setSortField(PanelModel::SortBySize);
    const double sortSize50kMs = timer.nsecsElapsed() / 1e6;

    // 5. Start folder size calculation on heavyDir, then switch immediately to Tab 2 (smallDir)
    panel.addTab(smallDir);
    panel.setActiveTab(0);
    bool trackingStale = false;
    int staleUpdatesAfterSwitch = 0;
    QObject::connect(&panel, &PanelModel::folderSizeCalculationChanged, &panel, [&]() {
        if (trackingStale)
            ++staleUpdatesAfterSwitch;
    });
    QObject::connect(&panel, &PanelModel::dataChanged, &panel,
                     [&](const QModelIndex &, const QModelIndex &, const QList<int> &roles) {
                         if (trackingStale
                             && (roles.isEmpty() || roles.contains(PanelModel::SizeRole)
                                 || roles.contains(PanelModel::FormattedSizeRole))) {
                             ++staleUpdatesAfterSwitch;
                         }
                     });

    panel.calculateAllFolderSizes();
    const bool sizeCalcStarted = panel.calculatingFolderSizes();
    timer.restart();
    panel.setActiveTab(1);
    const double tabSwitchDuringSizeCalcMs = timer.nsecsElapsed() / 1e6;
    trackingStale = true;

    if (!sizeCalcStarted || panel.calculatingFolderSizes() || panel.path() != smallDir) {
        QTextStream(stderr) << "Tab switch cancellation invariant failed.\n";
        return 1;
    }

    {
        QEventLoop waitLoop;
        QTimer::singleShot(100, &waitLoop, &QEventLoop::quit);
        waitLoop.exec();
    }
    if (staleUpdatesAfterSwitch != 0 || panel.path() != smallDir) {
        QTextStream(stderr) << "Detected stale folder-size updates after tab switch: "
                            << staleUpdatesAfterSwitch << "\n";
        return 1;
    }
    QThreadPool::globalInstance()->waitForDone(5000);

    // 6. Start heavy content search across 50k files, cancel it, measure UI return + worker drain
    Backend backend(tempRoot.filePath(QStringLiteral("bookmarks.json")));
    QVariantMap searchOpts;
    searchOpts.insert(QStringLiteral("contentQuery"), QStringLiteral("NO_SUCH_TOKEN_999999"));
    searchOpts.insert(QStringLiteral("typeFilter"), QStringLiteral("files"));
    backend.startAdvancedSearch(heavyDir, searchOpts);

    {
        QEventLoop warmLoop;
        QTimer::singleShot(15, &warmLoop, &QEventLoop::quit);
        warmLoop.exec();
    }

    const bool searchWasRunning = backend.searchRunning();
    timer.restart();
    backend.cancelSearch();
    const double searchCancelUiMs = timer.nsecsElapsed() / 1e6;
    if (backend.searchRunning()) {
        QTextStream(stderr) << "cancelSearch() did not clear searchRunning immediately.\n";
        return 1;
    }

    timer.restart();
    const bool poolDrained = QThreadPool::globalInstance()->waitForDone(5000);
    const double searchCancelWorkerMs = timer.nsecsElapsed() / 1e6;
    if (!poolDrained) {
        QTextStream(stderr) << "Background search worker did not stop within 5000 ms.\n";
        return 1;
    }

    if (jsonOut) {
        QJsonObject obj;
        obj.insert(QStringLiteral("files"), numFiles);
        obj.insert(QStringLiteral("subdirs"), numSubdirs);
        obj.insert(QStringLiteral("topLevelEntries"), expectedHeavyCount);
        obj.insert(QStringLiteral("fixtureSetupMs"), fixtureSetupMs);
        obj.insert(QStringLiteral("load50kMs"), load50kMs);
        obj.insert(QStringLiteral("firstViewport40RowsMs"), firstViewportMs);
        obj.insert(QStringLiteral("filter50kMs"), filter50kMs);
        obj.insert(QStringLiteral("sortSize50kMs"), sortSize50kMs);
        obj.insert(QStringLiteral("tabSwitchDuringSizeCalcMs"), tabSwitchDuringSizeCalcMs);
        obj.insert(QStringLiteral("staleUpdatesAfterSwitch"), staleUpdatesAfterSwitch);
        obj.insert(QStringLiteral("searchWasRunning"), searchWasRunning);
        obj.insert(QStringLiteral("searchCancelUiMs"), searchCancelUiMs);
        obj.insert(QStringLiteral("searchCancelWorkerMs"), searchCancelWorkerMs);
        QTextStream(stdout) << QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    } else {
        QTextStream out(stdout);
        out << "### TwinForge Interactivity Benchmark (" << numFiles << " files, "
            << expectedHeavyCount << " top-level entries)\n\n";
        out << "| Scenario | Measured | Notes |\n";
        out << "| :--- | :--- | :--- |\n";
        out << "| Load + Sort " << numFiles << " entries (`PanelModel::setPath`) | **"
            << fmtMs(load50kMs) << "** | Non-blocking lazy row formatting |\n";
        out << "| First Viewport Render (`40 rows x 5 roles`) | **"
            << fmtMs(firstViewportMs) << "** | Sub-frame first paint budget |\n";
        out << "| Live Name Filter + Clear (`" << numFiles << "` entries) | **"
            << fmtMs(filter50kMs) << "** | Pre-lowercased name cache |\n";
        out << "| Sort by Size (`" << numFiles << "` entries) | **"
            << fmtMs(sortSize50kMs) << "** | Zero-allocation strict weak ordering |\n";
        out << "| Tab Switch During Folder Size Calc | **"
            << fmtMs(tabSwitchDuringSizeCalcMs) << "** | Stale updates on new tab: `"
            << staleUpdatesAfterSwitch << "` |\n";
        out << "| Search Cancel (UI thread return) | **"
            << fmtMs(searchCancelUiMs) << "** | Active before cancel: `"
            << (searchWasRunning ? "yes" : "finished") << "` |\n";
        out << "| Search Cancel (Worker thread stop) | **"
            << fmtMs(searchCancelWorkerMs) << "** | Cooperative `QDirIterator` + atomic token |\n";
    }

    return 0;
}
