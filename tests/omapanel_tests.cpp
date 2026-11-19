#include <QBuffer>
#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QImage>
#include <QImageReader>
#include <QMimeData>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QUrl>
#include <QtTest>

#include <sys/stat.h>

#include "backend.h"
#include "cli.h"
#include "fileoperation.h"
#include "panelmodel.h"
#include "singleinstance.h"
#include "theme.h"
#include "thumbnailprovider.h"
#include "translator.h"

static void writeFile(const QString &path, const QByteArray &data)
{
    QFile f(path);
    QVERIFY(f.open(QIODevice::WriteOnly));
    f.write(data);
}

static QByteArray readFile(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return f.readAll();
}

// Runs a copy/move through Backend, answering every conflict with `answer`.
static bool runBackendOp(Backend &backend, bool move, const QStringList &sources, const QString &target,
                         int answer, int *conflicts = nullptr)
{
    int asked = 0;
    auto conn = QObject::connect(&backend, &Backend::conflictRequested, &backend, [&](const QVariantMap &) {
        ++asked;
        backend.resolveConflict(answer, false);
    });
    QSignalSpy finished(&backend, &Backend::operationFinished);
    const bool started = move ? backend.moveItems(sources, target) : backend.copyItems(sources, target);
    const bool done = started && finished.wait(10000);
    QObject::disconnect(conn);
    if (conflicts)
        *conflicts = asked;
    return done && finished.first().at(0).toBool();
}

class OmapanelTests : public QObject {
    Q_OBJECT

private slots:
    void themeFallsBack()
    {
        QTemporaryDir dir;
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#FFD60A"));
        QCOMPARE(theme.accentForeground(), QString("black"));
    }

    void themeReadsAccent()
    {
        QTemporaryDir dir;
        QDir(dir.path()).mkpath("theme");
        QFile colors(dir.path() + "/theme/colors.toml");
        QVERIFY(colors.open(QIODevice::WriteOnly));
        colors.write("accent = \"#112233\"\n");
        colors.close();

        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#112233"));
        QCOMPARE(theme.accentForeground(), QString("white"));
    }

    void translatorFallsBackToEnglish()
    {
        QTemporaryDir dir;
        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("en"));
        QVERIFY(translator.translate("Main", "View").isNull());
    }

    void panelModelLoadsDirectoryAndItems()
    {
        QTemporaryDir dir;
        QFile f1(dir.filePath("alpha.txt"));
        QVERIFY(f1.open(QIODevice::WriteOnly));
        f1.write("Hello world");
        f1.close();

        QDir(dir.path()).mkdir("subfolder");

        PanelModel model(dir.path());
        QVERIFY(model.rowCount() >= 2);

        int idx = model.findIndexByPrefix("alpha");
        QVERIFY(idx >= 0);
        QCOMPARE(model.itemName(idx), QString("alpha.txt"));
        QCOMPARE(model.itemIsDir(idx), false);
    }

    void panelModelSelectionAndFolderSize()
    {
        QTemporaryDir dir;
        QDir(dir.path()).mkdir("myfolder");
        QFile subFile(dir.filePath("myfolder/inside.bin"));
        QVERIFY(subFile.open(QIODevice::WriteOnly));
        subFile.write(QByteArray(2048, 'a')); // 2 KB
        subFile.close();

        PanelModel model(dir.path());
        int folderIdx = model.findIndexByPrefix("myfolder");
        QVERIFY(folderIdx >= 0);

        // Before pressing Space, folder shows <DIR>
        QCOMPARE(model.data(model.index(folderIdx, 0), PanelModel::FormattedSizeRole).toString(), QString("<DIR>"));

        // Pressing Space (toggleSelection) on folder selects it and triggers async size calculation
        model.toggleSelection(folderIdx);
        QCOMPARE(model.selectedCount(), 1);
        QTRY_COMPARE(model.data(model.index(folderIdx, 0), PanelModel::SizeRole).toLongLong(), 2048LL);
        QCOMPARE(model.data(model.index(folderIdx, 0), PanelModel::FormattedSizeRole).toString(), QString("2.0 KB"));
    }

    void panelModelHistoryNavigation()
    {
        QTemporaryDir dir;
        QDir(dir.path()).mkdir("sub1");
        QDir(dir.path()).mkdir("sub2");

        PanelModel model(dir.path());
        const QString rootPath = model.path();
        QCOMPARE(model.canGoBack(), false);

        model.cd("sub1");
        QVERIFY(model.path().endsWith("/sub1"));
        QCOMPARE(model.canGoBack(), true);

        model.goBack();
        QCOMPARE(model.path(), rootPath);
        QCOMPARE(model.canGoForward(), true);

        model.goForward();
        QVERIFY(model.path().endsWith("/sub1"));
    }

    void panelModelSorting()
    {
        QTemporaryDir dir;
        QFile f1(dir.filePath("zebra.txt"));
        QVERIFY(f1.open(QIODevice::WriteOnly));
        f1.write(QByteArray(100, 'x'));
        f1.close();

        QFile f2(dir.filePath("apple.bin"));
        QVERIFY(f2.open(QIODevice::WriteOnly));
        f2.write(QByteArray(500, 'y'));
        f2.close();

        QFile f3(dir.filePath("middle.doc"));
        QVERIFY(f3.open(QIODevice::WriteOnly));
        f3.write(QByteArray(200, 'z'));
        f3.close();

        PanelModel model(dir.path());

        model.setSortField(PanelModel::SortByName);
        model.setSortAscending(true);
        int count = model.itemCount();
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));

        model.setSortField(PanelModel::SortBySize);
        model.setSortAscending(true);
        QCOMPARE(model.itemName(count - 3), QString("zebra.txt"));
        QCOMPARE(model.itemName(count - 1), QString("apple.bin"));

        model.setSortField(PanelModel::SortBySize);
        QCOMPARE(model.sortAscending(), false);
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));

        model.setSortField(PanelModel::SortByExt);
        model.setSortAscending(true);
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 2), QString("middle.doc"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));
    }

    void backendOperationsAndAdvancedTools()
    {
        QTemporaryDir srcDir;
        QTemporaryDir dstDir;
        QTemporaryDir configDir;

        QFile f(srcDir.filePath("sample.txt"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("Some sample content");
        f.close();

        Backend backend(configDir.filePath("bookmarks.json"));
        backend.leftPanel()->setPath(srcDir.path());
        backend.rightPanel()->setPath(dstDir.path());

        // Compare directories: sample.txt is only in leftPanel
        backend.compareDirectories();
        QCOMPARE(backend.leftPanel()->selectedCount(), 1);
        QCOMPARE(backend.rightPanel()->selectedCount(), 0);

        // Copy item from left to right (runs on a worker thread)
        QSignalSpy finished(&backend, &Backend::operationFinished);
        bool copied = backend.copyItems({srcDir.filePath("sample.txt")}, dstDir.path());
        QVERIFY(copied);
        QVERIFY(finished.wait(5000));
        QCOMPARE(finished.first().at(0).toBool(), true);
        QVERIFY(QFile::exists(dstDir.filePath("sample.txt")));

        // Multi-rename in dstDir
        bool renamed = backend.executeMultiRename(
            {dstDir.filePath("sample.txt")},
            "sample", "report", "2026_", "", 0, true
        );
        QVERIFY(renamed);
        QVERIFY(QFile::exists(dstDir.filePath("2026_report_001.txt")));

        // Swap panels
        const QString oldLeft = backend.leftPanel()->path();
        const QString oldRight = backend.rightPanel()->path();
        backend.swapPanels();
        QCOMPARE(backend.leftPanel()->path(), oldRight);
        QCOMPARE(backend.rightPanel()->path(), oldLeft);

        // Bookmarks
        backend.toggleBookmark(srcDir.path());
        QVERIFY(backend.isBookmarked(srcDir.path()));

        // Run command
        QVariantMap cmdRes = backend.runCommand("echo hello_omapanel");
        QCOMPARE(cmdRes["exitCode"].toInt(), 0);
        QCOMPARE(cmdRes["output"].toString(), QString("hello_omapanel"));
    }
    void copyAsksBeforeOverwriting()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("a.txt"), "new");
        writeFile(dst.filePath("a.txt"), "old");
        Backend backend(cfg.filePath("bookmarks.json"));

        int conflicts = 0;
        runBackendOp(backend, false, {src.filePath("a.txt")}, dst.path(), FileOperation::Skip, &conflicts);
        QCOMPARE(conflicts, 1);
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("old"));

        QVERIFY(runBackendOp(backend, false, {src.filePath("a.txt")}, dst.path(), FileOperation::Rename, &conflicts));
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("old"));
        QCOMPARE(readFile(dst.filePath("a (1).txt")), QByteArray("new"));

        QVERIFY(runBackendOp(backend, false, {src.filePath("a.txt")}, dst.path(), FileOperation::Overwrite, &conflicts));
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("new"));
    }

    void moveAsksBeforeOverwritingAndKeepsSourceOnSkip()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("a.txt"), "new");
        writeFile(dst.filePath("a.txt"), "old");
        Backend backend(cfg.filePath("bookmarks.json"));

        runBackendOp(backend, true, {src.filePath("a.txt")}, dst.path(), FileOperation::Skip);
        QCOMPARE(readFile(src.filePath("a.txt")), QByteArray("new"));
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("old"));

        QVERIFY(runBackendOp(backend, true, {src.filePath("a.txt")}, dst.path(), FileOperation::Overwrite));
        QVERIFY(!QFile::exists(src.filePath("a.txt")));
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("new"));
    }

    void moveMergesIntoExistingFolder()
    {
        QTemporaryDir src, dst, cfg;
        QDir(src.path()).mkpath("docs");
        QDir(dst.path()).mkpath("docs");
        writeFile(src.filePath("docs/one.txt"), "1");
        writeFile(dst.filePath("docs/two.txt"), "2");
        Backend backend(cfg.filePath("bookmarks.json"));

        int conflicts = 0;
        QVERIFY(runBackendOp(backend, true, {src.filePath("docs")}, dst.path(), FileOperation::Cancel, &conflicts));
        QCOMPARE(conflicts, 0);
        QVERIFY(!QFileInfo::exists(src.filePath("docs")));
        QCOMPARE(readFile(dst.filePath("docs/one.txt")), QByteArray("1"));
        QCOMPARE(readFile(dst.filePath("docs/two.txt")), QByteArray("2"));
    }

    void copyFolderIntoItselfIsRejected()
    {
        QTemporaryDir root, cfg;
        QDir(root.path()).mkpath("a/b");
        writeFile(root.filePath("a/file.txt"), "x");
        Backend backend(cfg.filePath("bookmarks.json"));

        QVERIFY(!runBackendOp(backend, false, {root.filePath("a")}, root.filePath("a/b"), FileOperation::Skip));
        QVERIFY(!QFileInfo::exists(root.filePath("a/b/a")));
        QVERIFY(backend.statusMessage().contains("itself"));

        QVERIFY(!runBackendOp(backend, true, {root.filePath("a")}, root.filePath("a"), FileOperation::Skip));
        QVERIFY(QFileInfo::exists(root.filePath("a/file.txt")));
    }

    void copyIntoSameFolderMakesDuplicate()
    {
        QTemporaryDir root, cfg;
        writeFile(root.filePath("report.tar.gz"), "data");
        Backend backend(cfg.filePath("bookmarks.json"));
        QVERIFY(runBackendOp(backend, false, {root.filePath("report.tar.gz")}, root.path(), FileOperation::Skip));
        QCOMPARE(readFile(root.filePath("report (1).tar.gz")), QByteArray("data"));
    }

    void symlinksAreCopiedAsLinks()
    {
        QTemporaryDir src, dst, cfg;
        QDir(src.path()).mkpath("tree/real");
        writeFile(src.filePath("tree/real/f.txt"), "f");
        QVERIFY(QFile::link("real", src.filePath("tree/link-to-real")));
        QVERIFY(QFile::link("..", src.filePath("tree/real/loop")));       // would recurse forever if followed
        QVERIFY(QFile::link("missing", src.filePath("tree/dangling")));
        Backend backend(cfg.filePath("bookmarks.json"));

        QVERIFY(runBackendOp(backend, false, {src.filePath("tree")}, dst.path(), FileOperation::Skip));

        const QFileInfo link(dst.filePath("tree/link-to-real"));
        QVERIFY(link.isSymLink());
        QCOMPARE(link.readSymLink(), QString("real"));
        QVERIFY(QFileInfo(dst.filePath("tree/real/loop")).isSymLink());
        QVERIFY(QFileInfo(dst.filePath("tree/dangling")).isSymLink());
        QCOMPARE(readFile(dst.filePath("tree/real/f.txt")), QByteArray("f"));
    }

    void overwritingSymlinkDoesNotTouchItsTarget()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("a.txt"), "new");
        writeFile(dst.filePath("precious.txt"), "keep");
        QVERIFY(QFile::link("precious.txt", dst.filePath("a.txt")));
        Backend backend(cfg.filePath("bookmarks.json"));

        QVERIFY(runBackendOp(backend, false, {src.filePath("a.txt")}, dst.path(), FileOperation::Overwrite));
        QVERIFY(!QFileInfo(dst.filePath("a.txt")).isSymLink());
        QCOMPARE(readFile(dst.filePath("a.txt")), QByteArray("new"));
        QCOMPARE(readFile(dst.filePath("precious.txt")), QByteArray("keep"));
    }

    void cancelDuringConflictStopsOperation()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("1.txt"), "new");
        writeFile(src.filePath("2.txt"), "new");
        writeFile(dst.filePath("1.txt"), "old");
        Backend backend(cfg.filePath("bookmarks.json"));
        QObject::connect(&backend, &Backend::conflictRequested, &backend, [&] { backend.cancelOperation(); });

        QSignalSpy finished(&backend, &Backend::operationFinished);
        QVERIFY(backend.copyItems({src.filePath("1.txt"), src.filePath("2.txt")}, dst.path()));
        QVERIFY(backend.isBusy());
        QVERIFY(backend.copyItems({src.filePath("2.txt")}, dst.path())); // queued while busy
        QCOMPARE(backend.queueCount(), 1);
        backend.clearOperationQueue();
        QCOMPARE(backend.queueCount(), 0);
        QVERIFY(finished.wait(5000));
        QCOMPARE(finished.first().at(0).toBool(), false);
        QVERIFY(!backend.isBusy());
        QCOMPARE(readFile(dst.filePath("1.txt")), QByteArray("old"));
        QVERIFY(!QFile::exists(dst.filePath("2.txt")));
    }

    void applyToAllAsksOnce()
    {
        QTemporaryDir src, dst;
        for (const char *name : {"x.txt", "y.txt", "z.txt"}) {
            writeFile(src.filePath(name), "new");
            writeFile(dst.filePath(name), "old");
        }
        FileOperation op(FileOperation::Copy,
                         {src.filePath("x.txt"), src.filePath("y.txt"), src.filePath("z.txt")}, dst.path());
        int asked = 0;
        QObject::connect(&op, &FileOperation::conflict, &op, [&] {
            ++asked;
            op.resolveConflict(FileOperation::Overwrite, true);
        });
        op.run();
        QCOMPARE(asked, 1);
        QCOMPARE(op.completedCount(), 3);
        QCOMPARE(readFile(dst.filePath("z.txt")), QByteArray("new"));
    }

    void moveAcrossFilesystemsCopiesThenRemovesSource()
    {
        QTemporaryDir src; // usually /tmp (tmpfs)
        QTemporaryDir dst(QDir::currentPath() + "/omapanel-xdev-XXXXXX");
        struct stat a{}, b{};
        QVERIFY(::stat(QFile::encodeName(src.path()).constData(), &a) == 0);
        QVERIFY(::stat(QFile::encodeName(dst.path()).constData(), &b) == 0);
        if (a.st_dev == b.st_dev)
            QSKIP("Source and destination are on the same filesystem");

        QDir(src.path()).mkpath("folder/sub");
        writeFile(src.filePath("folder/sub/f.txt"), "content");
        QVERIFY(QFile::link("sub/f.txt", src.filePath("folder/link")));

        FileOperation op(FileOperation::Move, {src.filePath("folder")}, dst.path());
        op.run();
        QCOMPARE(op.completedCount(), 1);
        QVERIFY(!QFileInfo::exists(src.filePath("folder")));
        QCOMPARE(readFile(dst.filePath("folder/sub/f.txt")), QByteArray("content"));
        QCOMPARE(QFileInfo(dst.filePath("folder/link")).readSymLink(), QString("sub/f.txt"));
    }

    void largeCopyReportsProgress()
    {
        QTemporaryDir src, dst;
        writeFile(src.filePath("big.bin"), QByteArray(5 * 1024 * 1024, 'b'));
        FileOperation op(FileOperation::Copy, {src.filePath("big.bin")}, dst.path());
        QSignalSpy progress(&op, &FileOperation::progress);
        op.run();
        QVERIFY(progress.size() >= 2);
        QCOMPARE(progress.last().at(0).toLongLong(), 5LL * 1024 * 1024);
        QCOMPARE(progress.last().at(1).toLongLong(), 5LL * 1024 * 1024);
        QCOMPARE(QFileInfo(dst.filePath("big.bin")).size(), 5LL * 1024 * 1024);
    }

    void perPanelTabsAndHistory()
    {
        QTemporaryDir dirA, dirB;
        QDir(dirA.path()).mkdir("sub");

        PanelModel model(dirA.path());
        QCOMPARE(model.tabCount(), 1);
        QCOMPARE(model.activeTab(), 0);

        model.cd("sub");
        QVERIFY(model.path().endsWith("/sub"));
        QCOMPARE(model.canGoBack(), true);

        const int newIdx = model.addTab(dirB.path());
        QCOMPARE(newIdx, 1);
        QCOMPARE(model.tabCount(), 2);
        QCOMPARE(model.activeTab(), 1);
        QCOMPARE(QDir(model.path()).canonicalPath(), QDir(dirB.path()).canonicalPath());
        QCOMPARE(model.canGoBack(), false);

        // Switching back to tab 0 restores its path and independent Back history
        model.setActiveTab(0);
        QVERIFY(model.path().endsWith("/sub"));
        QCOMPARE(model.canGoBack(), true);

        model.nextTab();
        QCOMPARE(model.activeTab(), 1);
        model.prevTab();
        QCOMPARE(model.activeTab(), 0);

        model.closeTab(0);
        QCOMPARE(model.tabCount(), 1);
        QCOMPARE(model.activeTab(), 0);
        QCOMPARE(QDir(model.path()).canonicalPath(), QDir(dirB.path()).canonicalPath());

        // Last remaining tab must never be closed
        model.closeTab(0);
        QCOMPARE(model.tabCount(), 1);
    }

    void sessionPersistenceRoundTrip()
    {
        QTemporaryDir dirA, dirB, dirC, cfg;
        const QString bmFile = cfg.filePath("bookmarks.json");

        {
            Backend b1(bmFile);
            b1.leftPanel()->setPath(dirA.path());
            b1.leftPanel()->addTab(dirB.path());
            b1.leftPanel()->setSortField(PanelModel::SortBySize);
            b1.leftPanel()->setSortAscending(false);

            b1.rightPanel()->setPath(dirC.path());
            b1.rightPanel()->setShowHidden(true);

            b1.setActivePanel(1);
            b1.setWindowWidth(1440);
            b1.setWindowHeight(920);
        }

        Backend b2(bmFile);
        QCOMPARE(b2.windowWidth(), 1440);
        QCOMPARE(b2.windowHeight(), 920);
        QCOMPARE(b2.activePanel(), 1);

        QCOMPARE(b2.leftPanel()->tabCount(), 2);
        QCOMPARE(b2.leftPanel()->activeTab(), 1);
        QCOMPARE(QDir(b2.leftPanel()->path()).canonicalPath(), QDir(dirB.path()).canonicalPath());
        QCOMPARE(b2.leftPanel()->sortField(), static_cast<int>(PanelModel::SortBySize));
        QCOMPARE(b2.leftPanel()->sortAscending(), false);

        QCOMPARE(QDir(b2.rightPanel()->path()).canonicalPath(), QDir(dirC.path()).canonicalPath());
        QCOMPARE(b2.rightPanel()->showHidden(), true);
    }

    void systemClipboardCopyCutAndPaste()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("copy_me.txt"), "copied-payload");
        writeFile(src.filePath("cut_me.txt"), "cut-payload");

        Backend backend(cfg.filePath("bookmarks.json"));

        // 1. Copy to clipboard + Paste
        QVERIFY(backend.copyToClipboard({src.filePath("copy_me.txt")}));
        QCOMPARE(backend.canPaste(), true);
        QCOMPARE(backend.clipboardIsCut(), false);

        const QMimeData *mime = QGuiApplication::clipboard()->mimeData();
        QVERIFY(mime != nullptr);
        QVERIFY(mime->hasUrls());
        QVERIFY(mime->data("x-special/gnome-copied-files").startsWith("copy\n"));
        QCOMPARE(mime->data("application/x-kde-cutselection"), QByteArray("0"));

        QSignalSpy copyDone(&backend, &Backend::operationFinished);
        QVERIFY(backend.pasteFromClipboard(dst.path()));
        QVERIFY(copyDone.wait(5000));
        QVERIFY(QFile::exists(src.filePath("copy_me.txt")));
        QCOMPARE(readFile(dst.filePath("copy_me.txt")), QByteArray("copied-payload"));

        // 2. Cut to clipboard + Paste (moves file & clears clipboard)
        QVERIFY(backend.cutToClipboard({src.filePath("cut_me.txt")}));
        QCOMPARE(backend.canPaste(), true);
        QCOMPARE(backend.clipboardIsCut(), true);

        QSignalSpy cutDone(&backend, &Backend::operationFinished);
        QVERIFY(backend.pasteFromClipboard(dst.path()));
        QVERIFY(cutDone.wait(5000));
        QVERIFY(!QFile::exists(src.filePath("cut_me.txt")));
        QCOMPARE(readFile(dst.filePath("cut_me.txt")), QByteArray("cut-payload"));
        QCOMPARE(backend.canPaste(), false);
    }

    void dragDropUrlListCopyMoveAndSelfDropGuard()
    {
        QTemporaryDir src, dst, cfg;
        writeFile(src.filePath("d1.txt"), "drop-copy");
        writeFile(src.filePath("d2.txt"), "drop-move");
        Backend backend(cfg.filePath("bookmarks.json"));

        // Dropping onto the same parent directory is ignored
        QVariantList sameDirUrls = {QUrl::fromLocalFile(src.filePath("d1.txt"))};
        QVERIFY(!backend.handleDrop(sameDirUrls, src.path(), false));
        QVERIFY(!QFile::exists(src.filePath("d1 (1).txt")));

        // Drop copy to dst
        QSignalSpy copyDone(&backend, &Backend::operationFinished);
        QVERIFY(backend.handleDrop(sameDirUrls, dst.path(), false));
        QVERIFY(copyDone.wait(5000));
        QVERIFY(QFile::exists(src.filePath("d1.txt")));
        QCOMPARE(readFile(dst.filePath("d1.txt")), QByteArray("drop-copy"));

        // Drop move to dst
        QVariantList moveUrls = {QUrl::fromLocalFile(src.filePath("d2.txt"))};
        QSignalSpy moveDone(&backend, &Backend::operationFinished);
        QVERIFY(backend.handleDrop(moveUrls, dst.path(), true));
        QVERIFY(moveDone.wait(5000));
        QVERIFY(!QFile::exists(src.filePath("d2.txt")));
        QCOMPARE(readFile(dst.filePath("d2.txt")), QByteArray("drop-move"));
    }

    void undoRenameMultiRenameMoveAndTrash()
    {
        QTemporaryDir work, dst, cfg, fakeDataHome;
        const QByteArray prevXdgData = qgetenv("XDG_DATA_HOME");
        const bool hadXdgData = qEnvironmentVariableIsSet("XDG_DATA_HOME");
        qputenv("XDG_DATA_HOME", fakeDataHome.path().toUtf8());

        auto restoreEnv = qScopeGuard([&] {
            if (hadXdgData)
                qputenv("XDG_DATA_HOME", prevXdgData);
            else
                qunsetenv("XDG_DATA_HOME");
        });

        Backend backend(cfg.filePath("bookmarks.json"));
        QCOMPARE(backend.canUndo(), false);

        // 1. Single rename + Undo
        writeFile(work.filePath("orig.txt"), "hello");
        QVERIFY(backend.renameItem(work.filePath("orig.txt"), "renamed.txt"));
        QVERIFY(!QFile::exists(work.filePath("orig.txt")));
        QVERIFY(QFile::exists(work.filePath("renamed.txt")));
        QVERIFY(backend.canUndo());
        QVERIFY(backend.undoLastOperation());
        QVERIFY(QFile::exists(work.filePath("orig.txt")));
        QVERIFY(!QFile::exists(work.filePath("renamed.txt")));

        // 2. Multi-rename + Undo
        writeFile(work.filePath("b1.txt"), "1");
        writeFile(work.filePath("b2.txt"), "2");
        QVERIFY(backend.executeMultiRename(
            {work.filePath("b1.txt"), work.filePath("b2.txt")},
            "", "", "pre_", "", 0, false));
        QVERIFY(QFile::exists(work.filePath("pre_b1.txt")));
        QVERIFY(QFile::exists(work.filePath("pre_b2.txt")));
        QVERIFY(backend.undoLastOperation());
        QVERIFY(QFile::exists(work.filePath("b1.txt")));
        QVERIFY(QFile::exists(work.filePath("b2.txt")));

        // 3. Move + Undo
        QSignalSpy moveDone(&backend, &Backend::operationFinished);
        QVERIFY(backend.moveItems({work.filePath("orig.txt")}, dst.path()));
        QVERIFY(moveDone.wait(5000));
        QVERIFY(!QFile::exists(work.filePath("orig.txt")));
        QVERIFY(QFile::exists(dst.filePath("orig.txt")));
        QVERIFY(backend.undoLastOperation());
        QCOMPARE(readFile(work.filePath("orig.txt")), QByteArray("hello"));
        QVERIFY(!QFile::exists(dst.filePath("orig.txt")));

        // 4. Trash delete + Undo
        QVERIFY(backend.deleteItems({work.filePath("orig.txt")}, false));
        QVERIFY(!QFile::exists(work.filePath("orig.txt")));
        QVERIFY(backend.canUndo());
        QVERIFY(backend.undoLastOperation());
        QCOMPARE(readFile(work.filePath("orig.txt")), QByteArray("hello"));
    }

    void itemPropertiesAndPermissionsChmod()
    {
        QTemporaryDir dir, cfg;
        QDir(dir.path()).mkdir("pkg");
        const QString scriptPath = dir.filePath("pkg/build.sh");
        writeFile(scriptPath, "#!/bin/sh\necho ok\n");

        Backend backend(cfg.filePath("bookmarks.json"));

        const QVariantMap fileProps = backend.getItemProperties(scriptPath);
        QCOMPARE(fileProps["exists"].toBool(), true);
        QCOMPARE(fileProps["isDir"].toBool(), false);
        QCOMPARE(fileProps["name"].toString(), QString("build.sh"));
        QVERIFY(!fileProps["mimeName"].toString().isEmpty());

        QVERIFY(backend.setItemPermissions(scriptPath, 0750, false));
        struct stat st{};
        QVERIFY(::stat(QFile::encodeName(scriptPath).constData(), &st) == 0);
        QCOMPARE(static_cast<int>(st.st_mode & 0777), 0750);
        QCOMPARE(backend.formatSymbolicPermissions(0750), QString("rwxr-x---"));

        // Recursive folder chmod
        const QString pkgDir = dir.filePath("pkg");
        const QVariantMap dirProps = backend.getItemProperties(pkgDir);
        QCOMPARE(dirProps["isDir"].toBool(), true);
        QVERIFY(dirProps["itemCounts"].toString().contains("1"));

        QVERIFY(backend.setItemPermissions(pkgDir, 0755, true));
        QVERIFY(::stat(QFile::encodeName(pkgDir).constData(), &st) == 0);
        QCOMPARE(static_cast<int>(st.st_mode & 0777), 0755);
        QVERIFY(::stat(QFile::encodeName(scriptPath).constData(), &st) == 0);
        QCOMPARE(static_cast<int>(st.st_mode & 0777), 0755);
    }

    void checksumCalculationAndVerification()
    {
        QTemporaryDir dir, cfg;
        const QString testFile = dir.filePath("test.txt");
        writeFile(testFile, "Hello TwinForge checksum!");
        Backend backend(cfg.filePath("bookmarks.json"));

        const QVariantMap hashes = backend.calculateChecksums(testFile);
        QVERIFY(hashes.contains("md5"));
        QVERIFY(hashes.contains("sha256"));
        const QString md5 = hashes["md5"].toString();
        const QString sha256 = hashes["sha256"].toString();
        QVERIFY(!md5.isEmpty());
        QVERIFY(!sha256.isEmpty());

        // Verify checksum string
        QVERIFY(backend.verifyChecksum(testFile, md5));
        QVERIFY(backend.verifyChecksum(testFile, sha256));
        QVERIFY(!backend.verifyChecksum(testFile, "badhash123"));

        // Save checksum file and verify it
        const QString shaFile = dir.filePath("test.txt.sha256");
        QVERIFY(backend.saveChecksumFile(testFile, "sha256", shaFile));
        QVERIFY(QFile::exists(shaFile));

        const QVariantMap verifyRes = backend.verifyChecksumFile(shaFile);
        QCOMPARE(verifyRes["success"].toBool(), true);
        QCOMPARE(verifyRes["matched"].toInt(), 1);
        QCOMPARE(verifyRes["failed"].toInt(), 0);
    }

    void symlinkCreation()
    {
        QTemporaryDir srcDir, targetDir, cfg;
        writeFile(srcDir.filePath("original.txt"), "symlink content");
        Backend backend(cfg.filePath("bookmarks.json"));

        // 1. Single symlink
        QVERIFY(backend.createSymlink(srcDir.filePath("original.txt"), targetDir.path(), "my_link.txt"));
        const QString linkPath = targetDir.filePath("my_link.txt");
        QVERIFY(QFileInfo(linkPath).isSymLink());
        QCOMPARE(readFile(linkPath), QByteArray("symlink content"));

        // 2. Multiple symlinks
        writeFile(srcDir.filePath("file2.txt"), "file2 content");
        QVERIFY(backend.createSymlinks({srcDir.filePath("file2.txt")}, targetDir.path()));
        QVERIFY(QFileInfo(targetDir.filePath("file2.txt")).isSymLink());
    }

    void visualFileDiff()
    {
        QTemporaryDir dir, cfg;
        writeFile(dir.filePath("a.txt"), "line1\nline2\nline3\n");
        writeFile(dir.filePath("b.txt"), "line1\nmodified2\nline3\nextra4\n");
        writeFile(dir.filePath("c.txt"), "line1\nline2\nline3\n");
        Backend backend(cfg.filePath("bookmarks.json"));

        // Identical files
        const QVariantMap diffSame = backend.compareFiles(dir.filePath("a.txt"), dir.filePath("c.txt"));
        QCOMPARE(diffSame["isIdentical"].toBool(), true);
        QCOMPARE(diffSame["differences"].toInt(), 0);

        // Different files
        const QVariantMap diffDiff = backend.compareFiles(dir.filePath("a.txt"), dir.filePath("b.txt"));
        QCOMPARE(diffDiff["isIdentical"].toBool(), false);
        QVERIFY(diffDiff["differences"].toInt() > 0);
        const QVariantList rows = diffDiff["rows"].toList();
        QVERIFY(!rows.isEmpty());
    }

    void patternSelectionAndDeselection()
    {
        QTemporaryDir dir;
        writeFile(dir.filePath("photo1.jpg"), "");
        writeFile(dir.filePath("photo2.png"), "");
        writeFile(dir.filePath("document.txt"), "");
        writeFile(dir.filePath("archive.zip"), "");

        PanelModel model;
        model.setPath(dir.path());
        QCOMPARE(model.selectedCount(), 0);

        // Select by pattern *.jpg; *.png
        model.selectByPattern("*.jpg; *.png", true);
        QCOMPARE(model.selectedCount(), 2);

        // Deselect *.jpg
        model.deselectByPattern("*.jpg");
        QCOMPARE(model.selectedCount(), 1);

        // Select all text
        model.selectByPattern("*.txt", true);
        QCOMPARE(model.selectedCount(), 2);

        model.deselectAll();
        QCOMPARE(model.selectedCount(), 0);
    }

    void createNewFile()
    {
        QTemporaryDir dir, cfg;
        Backend backend(cfg.filePath("bookmarks.json"));
        backend.leftPanel()->setPath(dir.path());

        const QString targetPath = dir.filePath("new_note.txt");
        QVERIFY(!QFile::exists(targetPath));
        QVERIFY(backend.createNewFile(targetPath));
        QVERIFY(QFile::exists(targetPath));
    }

    void gitIntegration()
    {
        QTemporaryDir dir;
        QProcess proc;
        proc.setWorkingDirectory(dir.path());
        proc.start("git", {"init"});
        if (!proc.waitForFinished(3000) || proc.exitCode() != 0)
            return;

        writeFile(dir.filePath("tracked.txt"), "hello git");
        proc.start("git", {"add", "tracked.txt"});
        proc.waitForFinished(2000);
        proc.start("git", {"-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-m", "init"});
        proc.waitForFinished(2000);

        writeFile(dir.filePath("untracked.txt"), "new");
        writeFile(dir.filePath("tracked.txt"), "modified git content");

        PanelModel model;
        model.setPath(dir.path());
        QTRY_VERIFY(model.isGitRepo());
        QTRY_VERIFY(!model.gitBranch().isEmpty());
        QTRY_VERIFY(model.gitModifiedCount() >= 1 || model.gitUntrackedCount() >= 1);
    }

    void viewModeToggle()
    {
        PanelModel model;
        QCOMPARE(model.viewMode(), static_cast<int>(PanelModel::ViewModeList));
        model.setViewMode(PanelModel::ViewModeGrid);
        QCOMPARE(model.viewMode(), static_cast<int>(PanelModel::ViewModeGrid));
        model.toggleViewMode();
        QCOMPARE(model.viewMode(), static_cast<int>(PanelModel::ViewModeList));
    }

    void panelModelRangeAndBatchSelection()
    {
        QTemporaryDir dir;
        writeFile(dir.filePath("a.txt"), "a");
        writeFile(dir.filePath("b.txt"), "b");
        writeFile(dir.filePath("c.txt"), "c");
        writeFile(dir.filePath("d.txt"), "d");

        PanelModel model;
        model.setPath(dir.path());
        QVERIFY(model.itemCount() >= 4);

        // Verify setItemSelected and itemIsSelected
        QCOMPARE(model.selectedCount(), 0);
        model.setItemSelected(1, true);
        QVERIFY(model.itemIsSelected(1));
        QCOMPARE(model.selectedCount(), 1);

        model.setItemSelected(1, false);
        QVERIFY(!model.itemIsSelected(1));
        QCOMPARE(model.selectedCount(), 0);

        // Verify selectRange
        model.selectRange(1, 3, true);
        QCOMPARE(model.selectedCount(), 3);
        QVERIFY(model.itemIsSelected(1));
        QVERIFY(model.itemIsSelected(2));
        QVERIFY(model.itemIsSelected(3));

        model.selectRange(1, 2, false);
        QCOMPARE(model.selectedCount(), 1);
        QVERIFY(!model.itemIsSelected(1));
        QVERIFY(!model.itemIsSelected(2));
        QVERIFY(model.itemIsSelected(3));

        // Verify setSelectedIndices (marquee selection behavior)
        model.setSelectedIndices({1, 2}, false);
        QVERIFY(!model.itemIsSelected(3));
        QVERIFY(model.itemIsSelected(1));
        QVERIFY(model.itemIsSelected(2));

        // Verify addToExisting flag
        model.setSelectedIndices({3}, true);
        QVERIFY(model.itemIsSelected(1));
        QVERIFY(model.itemIsSelected(2));
        QVERIFY(model.itemIsSelected(3));
    }

    void multiDirectoryAndFileCreationFromCsv()
    {
        QTemporaryDir dir, cfg;
        Backend backend(cfg.filePath("bookmarks.json"));
        backend.leftPanel()->setPath(dir.path());

        // Multiple directory creation via CSV
        int dirCount = backend.createDirectories("alpha, beta, nested/gamma,  delta  ");
        QCOMPARE(dirCount, 4);
        QVERIFY(QDir(dir.filePath("alpha")).exists());
        QVERIFY(QDir(dir.filePath("beta")).exists());
        QVERIFY(QDir(dir.filePath("nested/gamma")).exists());
        QVERIFY(QDir(dir.filePath("delta")).exists());

        // createDirectory delegates to createDirectories when comma present
        QVERIFY(backend.createDirectory("folder_one, folder_two"));
        QVERIFY(QDir(dir.filePath("folder_one")).exists());
        QVERIFY(QDir(dir.filePath("folder_two")).exists());

        // Multiple file creation via CSV
        int fileCount = backend.createFiles("doc1.txt, doc2.md, subdocs/readme.org,  spaced.log  ");
        QCOMPARE(fileCount, 4);
        QVERIFY(QFile::exists(dir.filePath("doc1.txt")));
        QVERIFY(QFile::exists(dir.filePath("doc2.md")));
        QVERIFY(QFile::exists(dir.filePath("subdocs/readme.org")));
        QVERIFY(QFile::exists(dir.filePath("spaced.log")));

        // createNewFile delegates to createFiles when comma present
        QVERIFY(backend.createNewFile("batch_a.txt, batch_b.txt"));
        QVERIFY(QFile::exists(dir.filePath("batch_a.txt")));
        QVERIFY(QFile::exists(dir.filePath("batch_b.txt")));

        // Test isWritable and read-only directory handling
        QVERIFY(backend.leftPanel()->isWritable());

        QTemporaryDir roDir;
        QFile::setPermissions(roDir.path(), QFile::ReadOwner | QFile::ExeOwner | QFile::ReadGroup | QFile::ExeGroup);
        backend.leftPanel()->setPath(roDir.path());
        QVERIFY(!backend.leftPanel()->isWritable());

        // Attempts to create files/folders in read-only dir fail cleanly with 0 / false
        QCOMPARE(backend.createDirectories("fail_a, fail_b"), 0);
        QCOMPARE(backend.createFiles("fail_1.txt, fail_2.txt"), 0);
        QVERIFY(!backend.createDirectory("fail_single"));
        QVERIFY(!backend.createNewFile("fail_single.txt"));

        // Restore permissions for clean removal
        QFile::setPermissions(roDir.path(), QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
    }

    void copyAsCsvText()
    {
        QTemporaryDir dir, cfg;
        writeFile(dir.filePath("apple.txt"), "1");
        writeFile(dir.filePath("banana.md"), "2");
        writeFile(dir.filePath("cherry.json"), "3");

        Backend backend(cfg.filePath("bookmarks.json"));
        backend.leftPanel()->setPath(dir.path());

        PanelModel *model = backend.leftPanel();
        const QStringList allNames = model->allItemNames(true);
        QVERIFY(allNames.contains("apple.txt"));
        QVERIFY(allNames.contains("banana.md"));
        QVERIFY(allNames.contains("cherry.json"));

        const QStringList allPaths = model->allItemPaths(true);
        QCOMPARE(allPaths.size(), allNames.size());

        // Test explicit selection copying
        const QStringList explicitPaths = {dir.filePath("apple.txt"), dir.filePath("cherry.json")};
        const QString namesCsv = backend.copyNamesAsCsv(explicitPaths);
        QCOMPARE(namesCsv, QString("apple.txt, cherry.json"));
        if (auto *cb = QGuiApplication::clipboard()) {
            QCOMPARE(cb->text(), namesCsv);
        }

        const QString pathsCsv = backend.copyPathsAsCsv(explicitPaths);
        QCOMPARE(pathsCsv, QString("%1, %2").arg(dir.filePath("apple.txt"), dir.filePath("cherry.json")));

        // Test folder content copying
        const QString folderNamesCsv = backend.copyFolderContentsAsCsv(dir.path(), false);
        QVERIFY(folderNamesCsv.contains("apple.txt"));
        QVERIFY(folderNamesCsv.contains("banana.md"));
        QVERIFY(folderNamesCsv.contains("cherry.json"));

        const QString folderPathsCsv = backend.copyFolderContentsAsCsv(dir.path(), true);
        QVERIFY(folderPathsCsv.contains(dir.filePath("apple.txt")));
        QVERIFY(folderPathsCsv.contains(dir.filePath("banana.md")));
    }

    void themeAdaptiveAccents()
    {
        QTemporaryDir fallbackDir;
        Theme fallbackTheme(fallbackDir.path());
        QCOMPARE(fallbackTheme.darkAccent(), QString("#38bdf8"));
        QCOMPARE(fallbackTheme.darkAccentForeground(), QString("black"));
        QCOMPARE(fallbackTheme.lightAccent(), QString("#2563eb"));
        QCOMPARE(fallbackTheme.lightAccentForeground(), QString("white"));

        QTemporaryDir darkColorDir;
        QDir(darkColorDir.path()).mkpath("theme");
        writeFile(darkColorDir.path() + "/theme/colors.toml", "accent = \"#112233\"\n");
        Theme darkAccentTheme(darkColorDir.path());
        QCOMPARE(darkAccentTheme.lightAccent(), QString("#112233"));
        QCOMPARE(darkAccentTheme.lightAccentForeground(), QString("white"));
        QVERIFY(darkAccentTheme.darkAccent() != QString("#112233"));
        QVERIFY(QColor(darkAccentTheme.darkAccent()).lightnessF() > QColor("#112233").lightnessF());

        QTemporaryDir brightColorDir;
        QDir(brightColorDir.path()).mkpath("theme");
        writeFile(brightColorDir.path() + "/theme/colors.toml", "accent = \"#facc15\"\n");
        Theme brightAccentTheme(brightColorDir.path());
        QCOMPARE(brightAccentTheme.darkAccent(), QString("#facc15"));
        QCOMPARE(brightAccentTheme.darkAccentForeground(), QString("black"));
        QVERIFY(brightAccentTheme.lightAccent() != QString("#facc15"));
        QVERIFY(QColor(brightAccentTheme.lightAccent()).lightnessF() < QColor("#facc15").lightnessF());
    }

    void themeModeSwitchAndPersistence()
    {
        QTemporaryDir cfg;
        const QString bookmarksPath = cfg.filePath("bookmarks.json");

        {
            Backend backend(bookmarksPath);
            QCOMPARE(backend.themeMode(), QStringLiteral("dark"));
            QVERIFY(backend.isDarkTheme());

            QSignalSpy spy(&backend, &Backend::themeModeChanged);
            backend.setThemeMode(QStringLiteral("light"));
            QCOMPARE(spy.count(), 1);
            QCOMPARE(backend.themeMode(), QStringLiteral("light"));
            QVERIFY(!backend.isDarkTheme());

            // Setting the same mode should be a no-op.
            backend.setThemeMode(QStringLiteral("light"));
            QCOMPARE(spy.count(), 1);

            backend.toggleThemeMode();
            QCOMPARE(spy.count(), 2);
            QCOMPARE(backend.themeMode(), QStringLiteral("dark"));
            QVERIFY(backend.isDarkTheme());

            backend.toggleThemeMode();
            QCOMPARE(spy.count(), 3);
            QCOMPARE(backend.themeMode(), QStringLiteral("light"));
        }

        // Verify persisted themeMode reloads across Backend instances.
        {
            Backend reloaded(bookmarksPath);
            QCOMPARE(reloaded.themeMode(), QStringLiteral("light"));
            QVERIFY(!reloaded.isDarkTheme());
        }
    }

    void flatViewListsNestedFilesAndSupportsOperations()
    {
        QTemporaryDir dir;
        QTemporaryDir cfg;
        QVERIFY(QDir(dir.path()).mkpath("sub/deep"));
        QVERIFY(QDir(dir.path()).mkpath(".hidden_dir"));

        writeFile(dir.filePath("rootFile.txt"), "root");
        writeFile(dir.filePath("sub/nested.txt"), "hello nested");
        writeFile(dir.filePath("sub/deep/leaf.md"), "# leaf");
        writeFile(dir.filePath(".hidden_root.txt"), "hr");
        writeFile(dir.filePath("sub/.hidden_nested"), "hn");
        writeFile(dir.filePath(".hidden_dir/secret.txt"), "sec");

        Backend backend(cfg.filePath("bookmarks.json"));
        PanelModel *model = backend.leftPanel();
        model->setShowHidden(false);
        model->setPath(dir.path());
        QCOMPARE(model->flatView(), false);
        QCOMPARE(model->itemCount(), 3); // "..", "sub", "rootFile.txt"

        model->toggleFlatView();
        QCOMPARE(model->flatView(), true);

        QStringList names;
        QString nestedPath;
        for (int i = 0; i < model->itemCount(); ++i) {
            names << model->itemName(i);
            if (model->itemName(i) == QStringLiteral("sub/nested.txt"))
                nestedPath = model->itemPath(i);
        }

        QVERIFY(names.contains(QStringLiteral("..")));
        QVERIFY(names.contains(QStringLiteral("rootFile.txt")));
        QVERIFY(names.contains(QStringLiteral("sub/nested.txt")));
        QVERIFY(names.contains(QStringLiteral("sub/deep/leaf.md")));
        QVERIFY(!names.contains(QStringLiteral("sub")));
        QVERIFY(!names.contains(QStringLiteral("sub/deep")));
        QVERIFY(!names.contains(QStringLiteral(".hidden_root.txt")));
        QVERIFY(!names.contains(QStringLiteral("sub/.hidden_nested")));
        QVERIFY(!names.contains(QStringLiteral(".hidden_dir/secret.txt")));
        QCOMPARE(nestedPath, dir.filePath("sub/nested.txt"));

        // Hidden files in nested folders appear when showHidden is enabled
        model->setShowHidden(true);
        QStringList hiddenNames;
        for (int i = 0; i < model->itemCount(); ++i)
            hiddenNames << model->itemName(i);
        QVERIFY(hiddenNames.contains(QStringLiteral(".hidden_root.txt")));
        QVERIFY(hiddenNames.contains(QStringLiteral("sub/.hidden_nested")));
        QVERIFY(hiddenNames.contains(QStringLiteral(".hidden_dir/secret.txt")));

        // Renaming a flattened nested file keeps it inside sub/
        QVERIFY(backend.renameItem(nestedPath, QStringLiteral("renamed_nested.txt")));
        QVERIFY(QFile::exists(dir.filePath("sub/renamed_nested.txt")));
        QVERIFY(!QFile::exists(nestedPath));

        // Navigating to a different folder resets flatView
        model->setPath(dir.filePath("sub"));
        QCOMPARE(model->flatView(), false);
    }

    void virtualArchiveBrowsingAndSelectiveExtraction()
    {
        QTemporaryDir src;
        QTemporaryDir archDir;
        QTemporaryDir extractDst;
        QTemporaryDir cfg;

        QVERIFY(QDir(src.path()).mkpath("docs/sub"));
        writeFile(src.filePath("readme.txt"), "top level archive note\nsecond line\n");
        writeFile(src.filePath("docs/guide.md"), "# Guide\nSelective extraction test\n");
        QByteArray binData("\x00\x01\x02\x03\xFF\x41", 6);
        writeFile(src.filePath("docs/sub/data.bin"), binData);

        Backend backend(cfg.filePath("bookmarks.json"));
        const QString zipPath = archDir.filePath("bundle.zip");
        QVERIFY(backend.packArchive({src.filePath("readme.txt"), src.filePath("docs")}, zipPath));
        QVERIFY(QFile::exists(zipPath));

        // Also test .tar.zst archive support via bsdtar
        const QString tzstPath = archDir.filePath("bundle.tar.zst");
        const int tzstRc = QProcess::execute(QStringLiteral("bsdtar"),
                                             {QStringLiteral("-a"), QStringLiteral("-cf"), tzstPath,
                                              QStringLiteral("-C"), src.path(),
                                              QStringLiteral("readme.txt"), QStringLiteral("docs")});
        QCOMPARE(tzstRc, 0);

        PanelModel *left = backend.leftPanel();
        left->setPath(archDir.path());
        QCOMPARE(left->isArchiveView(), false);

        // Open zip archive virtually
        backend.openItem(zipPath);
        QCOMPARE(left->isArchiveView(), true);
        QCOMPARE(left->archiveFilePath(), zipPath);
        QCOMPARE(left->archiveInternalPath(), QString());
        QCOMPARE(left->isWritable(), false);

        QStringList rootItems;
        for (int i = 0; i < left->itemCount(); ++i)
            rootItems << left->itemName(i);
        QVERIFY(rootItems.contains(QStringLiteral("..")));
        QVERIFY(rootItems.contains(QStringLiteral("docs")));
        QVERIFY(rootItems.contains(QStringLiteral("readme.txt")));

        // Enter subfolder inside archive
        left->cd(QStringLiteral("docs"));
        QCOMPARE(left->isArchiveView(), true);
        QCOMPARE(left->archiveInternalPath(), QStringLiteral("docs"));

        // Preview text file inside archive
        const QVariantMap guidePreview = backend.getPreview(zipPath + QStringLiteral("::docs/guide.md"));
        QCOMPARE(guidePreview.value(QStringLiteral("exists")).toBool(), true);
        QCOMPARE(guidePreview.value(QStringLiteral("isText")).toBool(), true);
        QCOMPARE(guidePreview.value(QStringLiteral("isBinary")).toBool(), false);
        QVERIFY(guidePreview.value(QStringLiteral("text")).toString().contains(QStringLiteral("# Guide")));

        // Preview directory inside archive
        const QVariantMap dirPreview = backend.getPreview(zipPath + QStringLiteral("::docs"));
        QCOMPARE(dirPreview.value(QStringLiteral("exists")).toBool(), true);
        QCOMPARE(dirPreview.value(QStringLiteral("isDir")).toBool(), true);
        QVERIFY(dirPreview.value(QStringLiteral("text")).toString().contains(QStringLiteral("guide.md")));

        // Preview binary file inside archive
        const QVariantMap binPreview = backend.getPreview(zipPath + QStringLiteral("::docs/sub/data.bin"));
        QCOMPARE(binPreview.value(QStringLiteral("exists")).toBool(), true);
        QCOMPARE(binPreview.value(QStringLiteral("isText")).toBool(), true);
        QCOMPARE(binPreview.value(QStringLiteral("isBinary")).toBool(), true);
        QVERIFY(binPreview.value(QStringLiteral("text")).toString().contains(QStringLiteral("Binary")));

        // Flat View inside archive root lists nested files
        left->cdUp();
        QCOMPARE(left->archiveInternalPath(), QString());
        left->toggleFlatView();
        QCOMPARE(left->flatView(), true);
        QStringList flatArchiveItems;
        for (int i = 0; i < left->itemCount(); ++i)
            flatArchiveItems << left->itemName(i);
        QVERIFY(flatArchiveItems.contains(QStringLiteral("readme.txt")));
        QVERIFY(flatArchiveItems.contains(QStringLiteral("docs/guide.md")));
        QVERIFY(flatArchiveItems.contains(QStringLiteral("docs/sub/data.bin")));

        // Selective extraction via copyItems of a single file inside docs/
        QVERIFY(backend.copyItems({zipPath + QStringLiteral("::docs/guide.md")}, extractDst.path()));
        QCOMPARE(readFile(extractDst.filePath("guide.md")), QByteArray("# Guide\nSelective extraction test\n"));
        QVERIFY(!QFile::exists(extractDst.filePath("readme.txt")));

        // Selective extraction of a folder preserves binary payload
        QVERIFY(backend.copyItems({zipPath + QStringLiteral("::docs")}, extractDst.path()));
        QCOMPARE(readFile(extractDst.filePath("docs/sub/data.bin")), binData);

        // Read-only guards reject mutations inside archive
        QVERIFY(!backend.createDirectory(QStringLiteral("should_fail")));
        QVERIFY(!backend.createNewFile(QStringLiteral("should_fail.txt")));
        QVERIFY(!backend.renameItem(zipPath + QStringLiteral("::readme.txt"), QStringLiteral("x.txt")));
        QVERIFY(!backend.deleteItems({zipPath + QStringLiteral("::readme.txt")}, true));

        // cdUp from archive root exits back to host directory
        left->cdUp();
        QCOMPARE(left->isArchiveView(), false);
        QCOMPARE(left->path(), archDir.path());

        // Open .tar.zst archive virtually too
        backend.openItem(tzstPath);
        QCOMPARE(left->isArchiveView(), true);
        QCOMPARE(left->archiveFilePath(), tzstPath);
        const QVariantMap tzstPreview = backend.getPreview(tzstPath + QStringLiteral("::docs/guide.md"));
        QCOMPARE(tzstPreview.value(QStringLiteral("exists")).toBool(), true);
        QVERIFY(tzstPreview.value(QStringLiteral("text")).toString().contains(QStringLiteral("Selective extraction test")));
    }

    void recentDirectoriesAndQuickJumpQuery()
    {
        QTemporaryDir work;
        QTemporaryDir cfg;
        QVERIFY(QDir(work.path()).mkpath("alpha_project"));
        QVERIFY(QDir(work.path()).mkpath("beta_tools"));
        QVERIFY(QDir(work.path()).mkpath("gamma_docs"));

        QVERIFY(Backend::fuzzyScore(QStringLiteral("alproj"), QStringLiteral("alpha_project")) > 0);
        QVERIFY(Backend::fuzzyScore(QStringLiteral("xyz"), QStringLiteral("alpha_project")) < 0);

        Backend backend(cfg.filePath("bookmarks.json"));
        const QString alphaPath = work.filePath("alpha_project");
        const QString betaPath = work.filePath("beta_tools");
        const QString gammaPath = work.filePath("gamma_docs");

        backend.toggleBookmark(alphaPath);
        backend.recordRecentDirectory(betaPath);
        backend.leftPanel()->setPath(work.path());

        QVERIFY(backend.recentDirectories().contains(betaPath));

        const QVariantList allResults = backend.queryJumpDirectories(QString(), 50);
        QStringList returnedPaths;
        for (const QVariant &v : allResults)
            returnedPaths << v.toMap().value(QStringLiteral("path")).toString();
        QVERIFY(returnedPaths.contains(alphaPath));
        QVERIFY(returnedPaths.contains(betaPath));
        QVERIFY(returnedPaths.contains(gammaPath));

        // Fuzzy query matches alpha_project first
        const QVariantList fuzzy = backend.queryJumpDirectories(QStringLiteral("alproj"), 20);
        QVERIFY(!fuzzy.isEmpty());
        QCOMPARE(fuzzy.first().toMap().value(QStringLiteral("path")).toString(), alphaPath);

        // Path prefix query completes gamma_docs
        const QVariantList pathComp = backend.queryJumpDirectories(work.path() + QStringLiteral("/gam"), 20);
        bool foundGamma = false;
        for (const QVariant &v : pathComp) {
            if (v.toMap().value(QStringLiteral("path")).toString() == gammaPath)
                foundGamma = true;
        }
        QVERIFY(foundGamma);
    }

    void advancedSearchContentFiltersAndFeedToPanel()
    {
        QTemporaryDir rootDir;
        QTemporaryDir cfg;
        QVERIFY(QDir().mkpath(rootDir.filePath("sub/target_folder")));

        {
            QFile f(rootDir.filePath("sub/alpha.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("first line\ncontains MAGIC_TOKEN here\nthird line\n");
        }
        {
            QFile f(rootDir.filePath("sub/regex_hit.log"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("boot ok\nerror code 40477 detected\nshutdown\n");
        }
        {
            QFile f(rootDir.filePath("large.bin"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            QByteArray payload(1500, 'X');
            payload.replace(0, 11, "MAGIC_TOKEN");
            f.write(payload);
        }

        Backend backend(cfg.filePath("bookmarks.json"));

        QVariantMap tokenOpts;
        tokenOpts.insert(QStringLiteral("contentQuery"), QStringLiteral("MAGIC_TOKEN"));
        tokenOpts.insert(QStringLiteral("typeFilter"), QStringLiteral("files"));
        const QVariantList tokenMatches = backend.runAdvancedSearchSync(rootDir.path(), tokenOpts);
        QCOMPARE(tokenMatches.size(), 2);

        QVariantMap largeOpts = tokenOpts;
        largeOpts.insert(QStringLiteral("minSizeBytes"), 1000);
        const QVariantList largeMatches = backend.runAdvancedSearchSync(rootDir.path(), largeOpts);
        QCOMPARE(largeMatches.size(), 1);
        QCOMPARE(largeMatches.first().toMap().value(QStringLiteral("name")).toString(), QStringLiteral("large.bin"));

        QVariantMap regexOpts;
        regexOpts.insert(QStringLiteral("contentQuery"), QStringLiteral("error code \\d{5}"));
        regexOpts.insert(QStringLiteral("useRegex"), true);
        regexOpts.insert(QStringLiteral("typeFilter"), QStringLiteral("files"));
        const QVariantList regexMatches = backend.runAdvancedSearchSync(rootDir.path(), regexOpts);
        QCOMPARE(regexMatches.size(), 1);
        const QVariantMap regexHit = regexMatches.first().toMap();
        QCOMPARE(regexHit.value(QStringLiteral("name")).toString(), QStringLiteral("regex_hit.log"));
        QCOMPARE(regexHit.value(QStringLiteral("matchLine")).toInt(), 2);
        QVERIFY(regexHit.value(QStringLiteral("matchPreview")).toString().contains(QStringLiteral("40477")));

        QVariantMap dirOpts;
        dirOpts.insert(QStringLiteral("nameQuery"), QStringLiteral("*folder*"));
        dirOpts.insert(QStringLiteral("typeFilter"), QStringLiteral("dirs"));
        const QVariantList dirMatches = backend.runAdvancedSearchSync(rootDir.path(), dirOpts);
        QCOMPARE(dirMatches.size(), 1);
        QCOMPARE(dirMatches.first().toMap().value(QStringLiteral("isDir")).toBool(), true);

        backend.startAdvancedSearch(rootDir.path(), tokenOpts);
        QTRY_VERIFY(!backend.searchRunning());
        QVERIFY(backend.searchScannedCount() >= 3);
        const QVariantList asyncResults = backend.searchResultItems();
        QCOMPARE(asyncResults.size(), 2);

        QStringList feedPaths;
        bool sawAlphaPreview = false;
        for (const QVariant &v : asyncResults) {
            const QVariantMap row = v.toMap();
            feedPaths.append(row.value(QStringLiteral("path")).toString());
            if (row.value(QStringLiteral("name")).toString() == QStringLiteral("alpha.txt")) {
                QCOMPARE(row.value(QStringLiteral("matchLine")).toInt(), 2);
                sawAlphaPreview = row.value(QStringLiteral("matchPreview")).toString().contains(QStringLiteral("MAGIC_TOKEN"));
            }
        }
        QVERIFY(sawAlphaPreview);

        backend.leftPanel()->setPath(rootDir.path());
        const QString expectedBase = backend.leftPanel()->path();
        backend.feedPathsToPanel(feedPaths, QStringLiteral("Search: MAGIC_TOKEN"), false);
        QCOMPARE(backend.leftPanel()->isCollectionView(), true);
        QCOMPARE(backend.leftPanel()->collectionTitle(), QStringLiteral("Search: MAGIC_TOKEN"));
        QCOMPARE(backend.leftPanel()->rowCount(), 3); // ".." parent entry + 2 matched files
        QCOMPARE(backend.leftPanel()->index(0, 0).data(PanelModel::NameRole).toString(), QStringLiteral(".."));

        backend.leftPanel()->exitCollectionView();
        QCOMPARE(backend.leftPanel()->isCollectionView(), false);
        QCOMPARE(backend.leftPanel()->path(), expectedBase);

        const int initialTabs = backend.leftPanel()->tabCount();
        backend.feedPathsToPanel(feedPaths, QStringLiteral("Search Tab"), true);
        QCOMPARE(backend.leftPanel()->tabCount(), initialTabs + 1);
        QCOMPARE(backend.leftPanel()->isCollectionView(), true);
        QCOMPARE(backend.leftPanel()->rowCount(), 3);
    }

    void diskUsageMetricsAndAnalyzerMode()
    {
        QTemporaryDir rootDir;
        QTemporaryDir cfg;
        QVERIFY(QDir().mkpath(rootDir.filePath("big_dir")));
        QVERIFY(QDir().mkpath(rootDir.filePath("empty_dir")));

        {
            QFile f(rootDir.filePath("big_dir/payload.bin"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write(QByteArray(4096, 'A'));
        }
        {
            QFile f(rootDir.filePath("small.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write(QByteArray(512, 'B'));
        }

        Backend backend(cfg.filePath("bookmarks.json"));
        PanelModel *panel = backend.leftPanel();
        panel->setPath(rootDir.path());
        QCOMPARE(panel->diskUsageMode(), false);

        panel->toggleDiskUsageMode();
        QCOMPARE(panel->diskUsageMode(), true);
        QCOMPARE(panel->sortField(), static_cast<int>(PanelModel::SortBySize));
        QCOMPARE(panel->sortAscending(), false);

        QTRY_COMPARE(panel->maxItemSize(), static_cast<qint64>(4096));
        QCOMPARE(panel->totalItemsSize(), static_cast<qint64>(4608));
        QCOMPARE(panel->index(0, 0).data(PanelModel::NameRole).toString(), QStringLiteral(".."));
        QTRY_COMPARE(panel->index(1, 0).data(PanelModel::NameRole).toString(), QStringLiteral("big_dir"));

        const double ratio1 = panel->index(1, 0).data(PanelModel::SizeRatioRole).toDouble();
        const double percent1 = panel->index(1, 0).data(PanelModel::SizePercentRole).toDouble();
        QVERIFY(ratio1 > 0.99 && ratio1 <= 1.01);
        QVERIFY(percent1 > 88.0 && percent1 < 90.0);

        QCOMPARE(panel->index(2, 0).data(PanelModel::NameRole).toString(), QStringLiteral("small.txt"));
        const double ratio2 = panel->index(2, 0).data(PanelModel::SizeRatioRole).toDouble();
        const double percent2 = panel->index(2, 0).data(PanelModel::SizePercentRole).toDouble();
        QVERIFY(ratio2 > 0.12 && ratio2 < 0.13);
        QVERIFY(percent2 > 11.0 && percent2 < 12.0);
        QCOMPARE(panel->index(3, 0).data(PanelModel::NameRole).toString(), QStringLiteral("empty_dir"));

        panel->toggleDiskUsageMode();
        QCOMPARE(panel->diskUsageMode(), false);
    }

    void directorySynchronizationAndDuplicateFinder()
    {
        QTemporaryDir leftDir;
        QTemporaryDir rightDir;
        QTemporaryDir dupDir;
        QTemporaryDir cfg;
        QVERIFY(QDir().mkpath(leftDir.filePath("sub")));
        QVERIFY(QDir().mkpath(rightDir.filePath("sub")));
        QVERIFY(QDir().mkpath(dupDir.filePath("a")));
        QVERIFY(QDir().mkpath(dupDir.filePath("b/nested")));

        {
            QFile f(leftDir.filePath("only_left.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("left-only-data");
        }
        {
            QFile f(rightDir.filePath("only_right.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("right-only-data");
        }
        {
            QFile f(leftDir.filePath("sub/diff.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("12345");
        }
        {
            QFile f(rightDir.filePath("sub/diff.txt"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("abcde");
        }

        Backend backend(cfg.filePath("bookmarks.json"));

        // Same size, different contents: SHA-256 comparison must detect sub/diff.txt mismatch
        const QVariantList shaDiff = backend.compareDirectoriesRecursive(leftDir.path(), rightDir.path(), QStringLiteral("sha256"), false);
        bool sawLeftOnly = false;
        bool sawRightOnly = false;
        bool sawShaDiff = false;
        QVariantList syncPlan;
        for (const QVariant &v : shaDiff) {
            QVariantMap row = v.toMap();
            const QString rel = row.value(QStringLiteral("relPath")).toString();
            if (rel == QStringLiteral("only_left.txt")) {
                sawLeftOnly = true;
                QCOMPARE(row.value(QStringLiteral("action")).toString(), QStringLiteral("copy_to_right"));
                syncPlan.append(row);
            } else if (rel == QStringLiteral("only_right.txt")) {
                sawRightOnly = true;
                QCOMPARE(row.value(QStringLiteral("action")).toString(), QStringLiteral("copy_to_left"));
                syncPlan.append(row);
            } else if (rel == QStringLiteral("sub/diff.txt")) {
                sawShaDiff = true;
                row.insert(QStringLiteral("action"), QStringLiteral("copy_to_right"));
                syncPlan.append(row);
            }
        }
        QVERIFY(sawLeftOnly);
        QVERIFY(sawRightOnly);
        QVERIFY(sawShaDiff);

        const QVariantMap summary = backend.executeDirectorySync(leftDir.path(), rightDir.path(), syncPlan);
        QCOMPARE(summary.value(QStringLiteral("copiedToRight")).toInt(), 2);
        QCOMPARE(summary.value(QStringLiteral("copiedToLeft")).toInt(), 1);
        QCOMPARE(summary.value(QStringLiteral("failed")).toInt(), 0);
        QCOMPARE(summary.value(QStringLiteral("totalApplied")).toInt(), 3);

        QVERIFY(QFile::exists(rightDir.filePath("only_left.txt")));
        QVERIFY(QFile::exists(leftDir.filePath("only_right.txt")));

        const QVariantList postSyncSha = backend.compareDirectoriesRecursive(leftDir.path(), rightDir.path(), QStringLiteral("sha256"), false);
        int pendingAfterSync = 0;
        for (const QVariant &v : postSyncSha) {
            if (v.toMap().value(QStringLiteral("action")).toString() != QStringLiteral("skip"))
                ++pendingAfterSync;
        }
        QCOMPARE(pendingAfterSync, 0);

        // Duplicate Finder: 3 identical 256B files + 1 unique 256B file + 1 tiny below threshold
        const QByteArray dupPayload(256, 'D');
        const QStringList dupPaths = {
            dupDir.filePath("dup1.bin"),
            dupDir.filePath("a/dup2.bin"),
            dupDir.filePath("b/nested/dup3.bin")
        };
        for (const QString &p : dupPaths) {
            QFile f(p);
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write(dupPayload);
        }
        {
            QFile f(dupDir.filePath("unique.bin"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write(QByteArray(256, 'U'));
        }
        {
            QFile f(dupDir.filePath("tiny.bin"));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("hi");
        }

        const QVariantList dups = backend.findDuplicateFiles(dupDir.path(), QString(), 10, false);
        QCOMPARE(dups.size(), 3);

        int firstCount = 0;
        int selectedCount = 0;
        qint64 totalWasted = 0;
        QString sharedHash;
        for (const QVariant &v : dups) {
            const QVariantMap row = v.toMap();
            const bool isFirst = row.value(QStringLiteral("isFirstInGroup")).toBool();
            QCOMPARE(row.value(QStringLiteral("groupIndex")).toInt(), 0);
            QCOMPARE(row.value(QStringLiteral("groupCount")).toInt(), 3);
            QCOMPARE(row.value(QStringLiteral("wastedBytes")).toLongLong(), isFirst ? static_cast<qint64>(0) : static_cast<qint64>(256));
            totalWasted += row.value(QStringLiteral("wastedBytes")).toLongLong();
            if (sharedHash.isEmpty())
                sharedHash = row.value(QStringLiteral("hash")).toString();
            else
                QCOMPARE(row.value(QStringLiteral("hash")).toString(), sharedHash);
            if (isFirst)
                ++firstCount;
            if (row.value(QStringLiteral("selected")).toBool())
                ++selectedCount;
        }
        QVERIFY(!sharedHash.isEmpty());
        QCOMPARE(firstCount, 1);
        QCOMPARE(selectedCount, 2);
        QCOMPARE(totalWasted, static_cast<qint64>(512));
    }

    void qmlMainLoadsWithoutErrors()
    {
        QTemporaryDir cfg;
        Theme theme(cfg.path());
        Translator translator(cfg.filePath("language"), cfg.path());
        Backend backend(cfg.filePath("bookmarks.json"));

        QQmlApplicationEngine engine;
        engine.addImageProvider(QStringLiteral("thumb"), new ThumbnailProvider());
        engine.rootContext()->setContextProperty("theme", &theme);
        engine.rootContext()->setContextProperty("backend", &backend);
        engine.rootContext()->setContextProperty("i18n", &translator);
        engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
        QVERIFY(!engine.rootObjects().isEmpty());

        QObject *root = engine.rootObjects().first();
        QObject *palette = root->property("themePalette").value<QObject *>();
        QVERIFY(palette != nullptr);
        QCOMPARE(root->property("isDark").toBool(), true);
        QCOMPARE(palette->property("windowBg").value<QColor>(), QColor("#09090b"));

        backend.toggleThemeMode();
        QCOMPARE(backend.themeMode(), QStringLiteral("light"));
        QCOMPARE(root->property("isDark").toBool(), false);
        QCOMPARE(palette->property("windowBg").value<QColor>(), QColor("#eef0f5"));

        backend.toggleThemeMode();
        QCOMPARE(backend.themeMode(), QStringLiteral("dark"));
        QCOMPARE(root->property("isDark").toBool(), true);
        QCOMPARE(palette->property("windowBg").value<QColor>(), QColor("#09090b"));

        // Exercise full-box breadcrumb click target & path-editor right-side Copy button
        auto *win = qobject_cast<QQuickWindow *>(root);
        auto *crumbBox = root->findChild<QQuickItem *>(QStringLiteral("crumbBox_0"));
        auto *crumbBgMouse = root->findChild<QQuickItem *>(QStringLiteral("crumbBgMouse_0"));
        auto *pathEditField = root->findChild<QQuickItem *>(QStringLiteral("pathEditField_0"));
        auto *copyPathBtn = root->findChild<QQuickItem *>(QStringLiteral("copyPathBtn_0"));
        QVERIFY(win != nullptr);
        QVERIFY(crumbBox != nullptr);
        QVERIFY(crumbBgMouse != nullptr);
        QVERIFY(pathEditField != nullptr);
        QVERIFY(copyPathBtn != nullptr);

        QVERIFY(QTest::qWaitForWindowExposed(win));
        QTRY_VERIFY(crumbBox->width() > 120.0);
        QCOMPARE(crumbBgMouse->width(), crumbBox->width());
        QCOMPARE(crumbBgMouse->height(), crumbBox->height());
        QCOMPARE(crumbBox->isVisible(), true);
        QCOMPARE(pathEditField->isVisible(), false);

        // Real mouse click in the far-right empty area of the address box (just left of the bookmark star)
        const QPoint emptyClickPos = crumbBox->mapToScene(QPointF(crumbBox->width() - 36.0, crumbBox->height() * 0.5)).toPoint();
        QTest::mouseClick(win, Qt::LeftButton, Qt::NoModifier, emptyClickPos);
        QCOMPARE(crumbBox->isVisible(), false);
        QCOMPARE(pathEditField->isVisible(), true);
        QCOMPARE(copyPathBtn->isVisible(), true);
        QCOMPARE(pathEditField->property("text").toString(), backend.leftPanel()->path());

        // Real mouse click on the right-side Copy button keeps editor open and copies the path
        QTRY_VERIFY(copyPathBtn->x() > 50.0);
        const QPoint copyClickPos = copyPathBtn->mapToScene(QPointF(copyPathBtn->width() * 0.5, copyPathBtn->height() * 0.5)).toPoint();
        QTest::mouseClick(win, Qt::LeftButton, Qt::NoModifier, copyClickPos);
        QCOMPARE(QGuiApplication::clipboard()->text(), backend.leftPanel()->path());
        QCOMPARE(pathEditField->isVisible(), true);

        // Verify HD SVG icon inside Copy button loaded at 3x supersampled resolution
        QObject *hdIcon = nullptr;
        for (QObject *child : copyPathBtn->children()) {
            if (child->property("kind").isValid() && child->property("sourceSize").isValid()) {
                hdIcon = child;
                break;
            }
        }
        QVERIFY(hdIcon != nullptr);
        QTRY_COMPARE(hdIcon->property("status").toInt(), 1); // Image.Ready
        QCOMPARE(hdIcon->property("sourceSize").toSize(), QSize(68, 68));
        QVERIFY(hdIcon->property("source").toUrl().toString().startsWith(QStringLiteral("data:image/svg+xml;utf8,")));

        // Verify modern icon-type detection covers rich file categories
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("manual.pdf"), false, false), QStringLiteral("pdf"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("README.md"), false, false), QStringLiteral("markdown"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("budget.csv"), false, false), QStringLiteral("sheet"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("settings.json"), false, false), QStringLiteral("config"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("deploy.sh"), false, true), QStringLiteral("script"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("app.sqlite3"), false, false), QStringLiteral("database"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("Inter.ttf"), false, false), QStringLiteral("font"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("id_ed25519"), false, false), QStringLiteral("lock"));
        QCOMPARE(PanelModel::detectIconTypeForName(QStringLiteral("src"), true, false), QStringLiteral("folder"));
        QVERIFY(QMetaObject::invokeMethod(pathEditField, "escaped"));
        QCOMPARE(crumbBox->isVisible(), true);
        QCOMPARE(pathEditField->isVisible(), false);

        // Exercise Command Palette & Quick Jump modes and Flat View QML bindings
        QCOMPARE(root->property("commandPaletteOpen").toBool(), false);
        QVERIFY(QMetaObject::invokeMethod(root, "openCommandPalette", Q_ARG(QVariant, QStringLiteral("commands"))));
        QCOMPARE(root->property("commandPaletteOpen").toBool(), true);
        QCOMPARE(root->property("commandPaletteMode").toString(), QStringLiteral("commands"));

        QVERIFY(QMetaObject::invokeMethod(root, "openCommandPalette", Q_ARG(QVariant, QStringLiteral("jump"))));
        QCOMPARE(root->property("commandPaletteOpen").toBool(), true);
        QCOMPARE(root->property("commandPaletteMode").toString(), QStringLiteral("jump"));

        root->setProperty("commandPaletteOpen", false);
        QCOMPARE(root->property("commandPaletteOpen").toBool(), false);

        backend.leftPanel()->toggleFlatView();
        QCOMPARE(backend.leftPanel()->flatView(), true);
        backend.leftPanel()->toggleFlatView();
        QCOMPARE(backend.leftPanel()->flatView(), false);

        // Exercise Productivity Suite #2 dialogs, Disk Usage mode, and Feed to Panel QML bindings
        QVERIFY(QMetaObject::invokeMethod(root, "openAdvancedSearchDialog"));
        QCOMPARE(root->property("searchOpen").toBool(), true);
        root->setProperty("searchOpen", false);
        QCOMPARE(root->property("searchOpen").toBool(), false);

        QVERIFY(QMetaObject::invokeMethod(root, "openSyncDirsDialog"));
        QCOMPARE(root->property("syncDirsOpen").toBool(), true);
        root->setProperty("syncDirsOpen", false);
        QCOMPARE(root->property("syncDirsOpen").toBool(), false);

        QVERIFY(QMetaObject::invokeMethod(root, "openDuplicateFinderDialog"));
        QCOMPARE(root->property("duplicateFinderOpen").toBool(), true);
        root->setProperty("duplicateFinderOpen", false);
        QCOMPARE(root->property("duplicateFinderOpen").toBool(), false);

        backend.leftPanel()->toggleDiskUsageMode();
        QCOMPARE(backend.leftPanel()->diskUsageMode(), true);
        backend.leftPanel()->toggleDiskUsageMode();
        QCOMPARE(backend.leftPanel()->diskUsageMode(), false);

        backend.feedPathsToPanel(QStringList() << cfg.path(), QStringLiteral("QML Collection"), false);
        QCOMPARE(backend.leftPanel()->isCollectionView(), true);
        backend.leftPanel()->exitCollectionView();
        QCOMPARE(backend.leftPanel()->isCollectionView(), false);

        // Exercise Productivity Suite #3 Queue monitor, Next-Gen F3 Preview, and Multi-Rename QML bindings
        QVERIFY(QMetaObject::invokeMethod(root, "openOperationQueueDialog"));
        QCOMPARE(root->property("queueDialogOpen").toBool(), true);
        root->setProperty("queueDialogOpen", false);
        QCOMPARE(root->property("queueDialogOpen").toBool(), false);

        const QString mdPath = cfg.filePath("qml_preview.md");
        writeFile(mdPath, "# Hello\n\n**Bold** text\n");
        root->setProperty("previewData", backend.getPreview(mdPath));
        root->setProperty("previewOpen", true);
        QCOMPARE(root->property("previewOpen").toBool(), true);
        root->setProperty("previewOpen", false);
        QCOMPARE(root->property("previewOpen").toBool(), false);

        backend.leftPanel()->setPath(cfg.path());
        backend.leftPanel()->selectAll();
        QVERIFY(QMetaObject::invokeMethod(root, "triggerMultiRename"));
        QCOMPARE(root->property("multiRenameOpen").toBool(), true);
        root->setProperty("multiRenameOpen", false);
        QCOMPARE(root->property("multiRenameOpen").toBool(), false);

        // Exercise Productivity Suite #4 Remote Connections & Open With / Custom Actions dialogs
        QVERIFY(QMetaObject::invokeMethod(root, "openRemoteConnectionsDialog", Q_ARG(QVariant, QVariant(QString()))));
        QCOMPARE(root->property("remoteConnectionsOpen").toBool(), true);
        root->setProperty("remoteConnectionsOpen", false);
        QCOMPARE(root->property("remoteConnectionsOpen").toBool(), false);

        QVERIFY(QMetaObject::invokeMethod(root, "openOpenWithDialog", Q_ARG(QVariant, QVariant(mdPath)), Q_ARG(QVariant, QVariant(0))));
        QCOMPARE(root->property("openWithOpen").toBool(), true);
        root->setProperty("openWithOpen", false);
        QCOMPARE(root->property("openWithOpen").toBool(), false);
    }

    void operationQueueSpeedEtaAndPauseResume()
    {
        QTemporaryDir src, dst1, dst2, cfg;
        writeFile(src.filePath("big.bin"), QByteArray(2 * 1024 * 1024, 'M'));
        writeFile(src.filePath("queued.txt"), "queued-payload");
        writeFile(src.filePath("skipped.txt"), "removed-payload");

        Backend backend(cfg.filePath("bookmarks.json"));
        QSignalSpy finishedSpy(&backend, &Backend::operationFinished);
        bool sawSpeed = false;
        bool sawTotalBytes = false;
        QObject::connect(&backend, &Backend::busyChanged, &backend, [&]() {
            if (!backend.busySpeed().isEmpty())
                sawSpeed = true;
            if (backend.busyTotalBytes() > 0)
                sawTotalBytes = true;
        });

        QVERIFY(backend.copyItems({src.filePath("big.bin")}, dst1.path()));
        QVERIFY(backend.isBusy());

        backend.pauseOperation();
        QCOMPARE(backend.isPaused(), true);

        QVERIFY(backend.copyItems({src.filePath("queued.txt")}, dst2.path()));
        QVERIFY(backend.copyItems({src.filePath("skipped.txt")}, dst1.path()));
        QCOMPARE(backend.queueCount(), 2);
        const QVariantList qList = backend.operationQueue();
        QCOMPARE(qList.size(), 2);

        const int secondId = qList.at(1).toMap().value(QStringLiteral("id")).toInt();
        QVERIFY(backend.removeQueuedOperation(secondId));
        QCOMPARE(backend.queueCount(), 1);

        QTest::qWait(80);
        QCOMPARE(backend.isPaused(), true);

        backend.resumeOperation();
        QCOMPARE(backend.isPaused(), false);

        QTRY_VERIFY_WITH_TIMEOUT(!backend.isBusy() && backend.queueCount() == 0 && finishedSpy.count() == 2, 10000);
        QCOMPARE(finishedSpy.at(0).at(0).toBool(), true);
        QCOMPARE(finishedSpy.at(1).at(0).toBool(), true);
        QCOMPARE(QFileInfo(dst1.filePath("big.bin")).size(), static_cast<qint64>(2 * 1024 * 1024));
        QCOMPARE(readFile(dst2.filePath("queued.txt")), QByteArray("queued-payload"));
        QVERIFY(!QFile::exists(dst1.filePath("skipped.txt")));
        QVERIFY(sawSpeed);
        QVERIFY(sawTotalBytes);
    }

    void nextGenPreviewCodeMarkdownExifPdfFontAndMedia()
    {
        QTemporaryDir dir, cfg;
        Backend backend(cfg.filePath("bookmarks.json"));

        // 1. Source Code Syntax Highlighting
        const QString cppPath = dir.filePath("main.cpp");
        writeFile(cppPath, "// header\n#include <iostream>\nint main() { return 42; }\n");
        const QVariantMap cppPrev = backend.getPreview(cppPath);
        QCOMPARE(cppPrev.value(QStringLiteral("isCode")).toBool(), true);
        QCOMPARE(cppPrev.value(QStringLiteral("syntaxLanguage")).toString(), QStringLiteral("C++"));
        QVERIFY(cppPrev.value(QStringLiteral("highlightedHtml")).toString().contains(QStringLiteral("<span")));

        // 2. Markdown Rendering
        const QString mdPath = dir.filePath("README.md");
        writeFile(mdPath, "# AeroCommander\n\nFeatures **bold** and `code`.\n- item 1\n");
        const QVariantMap mdPrev = backend.getPreview(mdPath);
        QCOMPARE(mdPrev.value(QStringLiteral("isMarkdown")).toBool(), true);
        const QString mdHtml = mdPrev.value(QStringLiteral("renderedHtml")).toString();
        QVERIFY(mdHtml.contains(QStringLiteral("<h1")));
        QVERIFY(mdHtml.contains(QStringLiteral("<b>bold</b>")));

        // 3. Synthetic JPEG with EXIF APP1 (Canon EOS R5, ISO 400, f/2.8, 1/250s, 50 mm, GPS)
        QByteArray tiff;
        auto pushU16 = [&](quint16 v) { tiff.append(static_cast<char>(v & 0xFF)); tiff.append(static_cast<char>((v >> 8) & 0xFF)); };
        auto pushU32 = [&](quint32 v) {
            tiff.append(static_cast<char>(v & 0xFF));
            tiff.append(static_cast<char>((v >> 8) & 0xFF));
            tiff.append(static_cast<char>((v >> 16) & 0xFF));
            tiff.append(static_cast<char>((v >> 24) & 0xFF));
        };
        auto setU32 = [&](int pos, quint32 v) {
            tiff[pos] = static_cast<char>(v & 0xFF);
            tiff[pos + 1] = static_cast<char>((v >> 8) & 0xFF);
            tiff[pos + 2] = static_cast<char>((v >> 16) & 0xFF);
            tiff[pos + 3] = static_cast<char>((v >> 24) & 0xFF);
        };
        tiff.append("II*\0", 4);
        pushU32(8); // IFD0 offset

        // IFD0: 4 entries (0x010F Make, 0x0110 Model, 0x8769 ExifIFD, 0x8825 GPSIFD)
        pushU16(4);
        const int makeOffPos = tiff.size() + 8;   pushU16(0x010F); pushU16(2); pushU32(6); pushU32(0);
        const int modelOffPos = tiff.size() + 8;  pushU16(0x0110); pushU16(2); pushU32(7); pushU32(0);
        const int exifPtrPos = tiff.size() + 8;   pushU16(0x8769); pushU16(4); pushU32(1); pushU32(0);
        const int gpsPtrPos = tiff.size() + 8;    pushU16(0x8825); pushU16(4); pushU32(1); pushU32(0);
        pushU32(0); // next IFD

        setU32(makeOffPos, static_cast<quint32>(tiff.size()));  tiff.append("Canon\0", 6);
        setU32(modelOffPos, static_cast<quint32>(tiff.size())); tiff.append("EOS R5\0", 7);

        // Exif SubIFD: 5 entries
        setU32(exifPtrPos, static_cast<quint32>(tiff.size()));
        pushU16(5);
        const int expOffPos = tiff.size() + 8;   pushU16(0x829A); pushU16(5); pushU32(1); pushU32(0);
        const int fnumOffPos = tiff.size() + 8;  pushU16(0x829D); pushU16(5); pushU32(1); pushU32(0);
        pushU16(0x8827); pushU16(3); pushU32(1); pushU32(400); // inline ISO 400
        const int dateOffPos = tiff.size() + 8;  pushU16(0x9003); pushU16(2); pushU32(20); pushU32(0);
        const int flOffPos = tiff.size() + 8;    pushU16(0x920A); pushU16(5); pushU32(1); pushU32(0);
        pushU32(0);

        setU32(expOffPos, static_cast<quint32>(tiff.size()));   pushU32(1); pushU32(250);
        setU32(fnumOffPos, static_cast<quint32>(tiff.size()));  pushU32(28); pushU32(10);
        setU32(dateOffPos, static_cast<quint32>(tiff.size()));  tiff.append("2026:11:15 12:30:00\0", 20);
        setU32(flOffPos, static_cast<quint32>(tiff.size()));    pushU32(50); pushU32(1);

        // GPS SubIFD: 4 entries
        setU32(gpsPtrPos, static_cast<quint32>(tiff.size()));
        pushU16(4);
        pushU16(0x0001); pushU16(2); pushU32(2); tiff.append("N\0\0\0", 4);
        const int latOffPos = tiff.size() + 8; pushU16(0x0002); pushU16(5); pushU32(3); pushU32(0);
        pushU16(0x0003); pushU16(2); pushU32(2); tiff.append("E\0\0\0", 4);
        const int lonOffPos = tiff.size() + 8; pushU16(0x0004); pushU16(5); pushU32(3); pushU32(0);
        pushU32(0);

        setU32(latOffPos, static_cast<quint32>(tiff.size()));
        pushU32(44); pushU32(1); pushU32(25); pushU32(1); pushU32(3648); pushU32(100);
        setU32(lonOffPos, static_cast<quint32>(tiff.size()));
        pushU32(26); pushU32(1); pushU32(6); pushU32(1); pushU32(900); pushU32(100);

        QImage img(2, 2, QImage::Format_RGB32);
        img.fill(Qt::darkCyan);
        QByteArray baseJpeg;
        QBuffer jpegBuf(&baseJpeg);
        QVERIFY(jpegBuf.open(QIODevice::WriteOnly));
        QVERIFY(img.save(&jpegBuf, "JPEG", 90));
        QVERIFY(baseJpeg.startsWith(QByteArray("\xFF\xD8", 2)));

        QByteArray app1;
        const quint16 app1Len = static_cast<quint16>(2 + 6 + tiff.size());
        app1.append("\xFF\xE1", 2);
        app1.append(static_cast<char>((app1Len >> 8) & 0xFF));
        app1.append(static_cast<char>(app1Len & 0xFF));
        app1.append("Exif\0\0", 6);
        app1.append(tiff);

        QByteArray jpeg = baseJpeg.left(2) + app1 + baseJpeg.mid(2);

        const QString jpgPath = dir.filePath("photo.jpg");
        writeFile(jpgPath, jpeg);
        const QVariantMap jpgPrev = backend.getPreview(jpgPath);
        QCOMPARE(jpgPrev.value(QStringLiteral("isImage")).toBool(), true);
        QCOMPARE(jpgPrev.value(QStringLiteral("hasExif")).toBool(), true);
        const QVariantMap exif = jpgPrev.value(QStringLiteral("exif")).toMap();
        QCOMPARE(exif.value(QStringLiteral("cameraMake")).toString(), QStringLiteral("Canon"));
        QCOMPARE(exif.value(QStringLiteral("cameraModel")).toString(), QStringLiteral("EOS R5"));
        QCOMPARE(exif.value(QStringLiteral("iso")).toInt(), 400);
        QCOMPARE(exif.value(QStringLiteral("aperture")).toString(), QStringLiteral("f/2.8"));
        QCOMPARE(exif.value(QStringLiteral("exposure")).toString(), QStringLiteral("1/250s"));
        QCOMPARE(exif.value(QStringLiteral("focalLength")).toString(), QStringLiteral("50 mm"));
        QVERIFY(!exif.value(QStringLiteral("gpsCoordinates")).toString().isEmpty());

        // 4. Valid 2-Page PDF Preview & Page Navigation
        QByteArray pdf = "%PDF-1.4\n";
        QList<int> offsets;
        auto addObj = [&](const QByteArray &body) {
            offsets.append(pdf.size());
            pdf.append(body);
        };
        addObj("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");
        addObj("2 0 obj\n<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>\nendobj\n");
        addObj("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 5 0 R >>\nendobj\n");
        addObj("4 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 6 0 R >>\nendobj\n");
        const QByteArray st1 = "BT /F1 12 Tf 10 100 Td (PageOneHello) Tj ET";
        addObj("5 0 obj\n<< /Length " + QByteArray::number(st1.size()) + " >>\nstream\n" + st1 + "\nendstream\nendobj\n");
        const QByteArray st2 = "BT /F1 12 Tf 10 100 Td (PageTwoWorld) Tj ET";
        addObj("6 0 obj\n<< /Length " + QByteArray::number(st2.size()) + " >>\nstream\n" + st2 + "\nendstream\nendobj\n");
        addObj("7 0 obj\n<< /Title (Suite3 PDF Title) >>\nendobj\n");
        const int xrefPos = pdf.size();
        pdf.append("xref\n0 8\n0000000000 65535 f \n");
        for (int off : offsets)
            pdf.append(QStringLiteral("%1 00000 n \n").arg(off, 10, 10, QLatin1Char('0')).toLatin1());
        pdf.append("trailer\n<< /Size 8 /Root 1 0 R /Info 7 0 R >>\nstartxref\n" + QByteArray::number(xrefPos) + "\n%%EOF\n");

        const QString pdfPath = dir.filePath("sample.pdf");
        writeFile(pdfPath, pdf);
        const QVariantMap pdfP1 = backend.getPreview(pdfPath, 1);
        QCOMPARE(pdfP1.value(QStringLiteral("isPdf")).toBool(), true);
        QCOMPARE(pdfP1.value(QStringLiteral("pdfPageCount")).toInt(), 2);
        QCOMPARE(pdfP1.value(QStringLiteral("pdfPage")).toInt(), 1);
        QCOMPARE(pdfP1.value(QStringLiteral("pdfTitle")).toString(), QStringLiteral("Suite3 PDF Title"));
        QVERIFY(pdfP1.value(QStringLiteral("pdfPageText")).toString().contains(QStringLiteral("PageOneHello")));

        const QVariantMap pdfP2 = backend.getPreview(pdfPath, 2);
        QCOMPARE(pdfP2.value(QStringLiteral("pdfPage")).toInt(), 2);
        QVERIFY(pdfP2.value(QStringLiteral("pdfPageText")).toString().contains(QStringLiteral("PageTwoWorld")));

        // 5. Font Preview (copies first system .ttf if installed, else verifies extension path)
        QString systemTtf;
        QDirIterator fontIt(QStringLiteral("/usr/share/fonts"), {QStringLiteral("*.ttf")}, QDir::Files, QDirIterator::Subdirectories);
        if (fontIt.hasNext())
            systemTtf = fontIt.next();
        if (!systemTtf.isEmpty()) {
            const QString localTtf = dir.filePath("testfont.ttf");
            QVERIFY(QFile::copy(systemTtf, localTtf));
            const QVariantMap fontPrev = backend.getPreview(localTtf);
            QCOMPARE(fontPrev.value(QStringLiteral("isFont")).toBool(), true);
            QCOMPARE(fontPrev.value(QStringLiteral("fontFormat")).toString(), QStringLiteral("TTF"));
            QVERIFY(!fontPrev.value(QStringLiteral("fontUrl")).toString().isEmpty());
            QVERIFY(!fontPrev.value(QStringLiteral("fontFamily")).toString().isEmpty());
        }

        // 6. RIFF PCM WAV Audio Preview & Metadata
        QByteArray wav;
        auto pushLe32 = [&](quint32 v) {
            wav.append(static_cast<char>(v & 0xFF));
            wav.append(static_cast<char>((v >> 8) & 0xFF));
            wav.append(static_cast<char>((v >> 16) & 0xFF));
            wav.append(static_cast<char>((v >> 24) & 0xFF));
        };
        auto pushLe16 = [&](quint16 v) {
            wav.append(static_cast<char>(v & 0xFF));
            wav.append(static_cast<char>((v >> 8) & 0xFF));
        };
        const quint32 pcmBytes = 32000; // 1.0 sec @ 16000 Hz mono 16-bit
        wav.append("RIFF", 4);
        pushLe32(36 + pcmBytes);
        wav.append("WAVEfmt ", 8);
        pushLe32(16);
        pushLe16(1);     // PCM
        pushLe16(1);     // mono
        pushLe32(16000); // sampleRate
        pushLe32(32000); // byteRate
        pushLe16(2);     // blockAlign
        pushLe16(16);    // bitsPerSample
        wav.append("data", 4);
        pushLe32(pcmBytes);
        wav.append(QByteArray(static_cast<int>(pcmBytes), '\0'));

        const QString wavPath = dir.filePath("tone.wav");
        writeFile(wavPath, wav);
        const QVariantMap wavPrev = backend.getPreview(wavPath);
        QCOMPARE(wavPrev.value(QStringLiteral("isMedia")).toBool(), true);
        QCOMPARE(wavPrev.value(QStringLiteral("isAudio")).toBool(), true);
        QVERIFY(!wavPrev.value(QStringLiteral("mediaUrl")).toString().isEmpty());
        QCOMPARE(wavPrev.value(QStringLiteral("mediaSampleRate")).toString(), QStringLiteral("16000 Hz"));
        QCOMPARE(wavPrev.value(QStringLiteral("mediaChannels")).toInt(), 1);
        QVERIFY(!wavPrev.value(QStringLiteral("mediaDuration")).toString().isEmpty());
    }

    void multiRenameRegexDynamicTagsAndPresets()
    {
        QTemporaryDir root, cfg;
        const QString tripDir = root.filePath("Trips");
        QVERIFY(QDir().mkpath(tripDir));

        const QString p1 = tripDir + "/photo_2025-07_orig.txt";
        const QString p2 = tripDir + "/clip_2025-07_orig.txt";
        writeFile(p1, "p1");
        writeFile(p2, "p2");

        {
            Backend backend(cfg.filePath("bookmarks.json"));

            // Preview [Date] tag before renaming
            const QVariantList datePrev = backend.previewMultiRename(
                {p1}, QString(), QString(), QString(), QString(), 0, false,
                false, QStringLiteral("[Date]_[N].[Ext]"));
            QCOMPARE(datePrev.size(), 1);
            const QString dateNewName = datePrev.first().toMap().value(QStringLiteral("newName")).toString();
            QVERIFY(QRegularExpression(QStringLiteral("^\\d{4}-\\d{2}-\\d{2}_photo_2025-07_orig\\.txt$")).match(dateNewName).hasMatch());

            // Execute RegEx capture + [ParentFolder] + custom Counter start=10, step=2, digits=2
            QVERIFY(backend.executeMultiRename(
                {p1, p2},
                QStringLiteral("(\\d{4})-(\\d{2})_orig"),
                QStringLiteral("$2_$1"),
                QString(), QString(), 0, false,
                true,
                QStringLiteral("[ParentFolder]_[N]_[C]"),
                10, 2, 2));

            QVERIFY(QFile::exists(tripDir + "/Trips_photo_07_2025_10.txt"));
            QVERIFY(QFile::exists(tripDir + "/Trips_clip_07_2025_12.txt"));

            // Preset save & retrieve
            QVariantMap preset;
            preset[QStringLiteral("nameMask")] = QStringLiteral("[Date]_[ParentFolder]_[N]");
            preset[QStringLiteral("findText")] = QStringLiteral("orig");
            preset[QStringLiteral("replaceText")] = QStringLiteral("final");
            preset[QStringLiteral("useRegex")] = true;
            preset[QStringLiteral("counterStart")] = 5;
            preset[QStringLiteral("counterDigits")] = 4;
            QVERIFY(backend.saveMultiRenamePreset(QStringLiteral("TripPreset"), preset));
            QCOMPARE(backend.multiRenamePresets().size(), 1);
            QCOMPARE(backend.getMultiRenamePreset(QStringLiteral("TripPreset")).value(QStringLiteral("counterStart")).toInt(), 5);
        }

        // Reload Backend from same config dir to confirm preset persistence
        Backend backendReloaded(cfg.filePath("bookmarks.json"));
        QCOMPARE(backendReloaded.multiRenamePresets().size(), 1);
        QCOMPARE(backendReloaded.getMultiRenamePreset(QStringLiteral("TripPreset")).value(QStringLiteral("nameMask")).toString(),
                 QStringLiteral("[Date]_[ParentFolder]_[N]"));
        QVERIFY(backendReloaded.deleteMultiRenamePreset(QStringLiteral("TripPreset")));
        QCOMPARE(backendReloaded.multiRenamePresets().size(), 0);
    }

    void remoteConnectionsUriGvfsMountAndPersistence()
    {
        QTemporaryDir gvfsDir, cfg;
        qputenv("OMAPANEL_GVFS_DIR", gvfsDir.path().toUtf8());
        struct EnvCleanup {
            ~EnvCleanup() { qunsetenv("OMAPANEL_GVFS_DIR"); }
        } cleanup;

        const QString gvfsSftpRoot = gvfsDir.filePath("sftp:host=10.10.0.5,user=radu");
        const QString gvfsWebDir = gvfsSftpRoot + "/var/www";
        QVERIFY(QDir().mkpath(gvfsWebDir));
        writeFile(gvfsWebDir + "/index.html", "<h1>ok</h1>");

        {
            Backend backend(cfg.filePath("bookmarks.json"));

            const QVariantMap parsedSftp = backend.parseRemoteUri(QStringLiteral("sftp://radu@10.10.0.5:2222/var/www"));
            QCOMPARE(parsedSftp.value(QStringLiteral("protocol")).toString(), QStringLiteral("sftp"));
            QCOMPARE(parsedSftp.value(QStringLiteral("host")).toString(), QStringLiteral("10.10.0.5"));
            QCOMPARE(parsedSftp.value(QStringLiteral("port")).toInt(), 2222);
            QCOMPARE(parsedSftp.value(QStringLiteral("user")).toString(), QStringLiteral("radu"));
            QCOMPARE(parsedSftp.value(QStringLiteral("remotePath")).toString(), QStringLiteral("/var/www"));
            QCOMPARE(backend.buildRemoteUri(parsedSftp), QStringLiteral("sftp://radu@10.10.0.5:2222/var/www"));

            const QVariantMap parsedSmb = backend.parseRemoteUri(QStringLiteral("smb://WORKGROUP;radu@nas.local/media/films"));
            QCOMPARE(parsedSmb.value(QStringLiteral("protocol")).toString(), QStringLiteral("smb"));
            QCOMPARE(parsedSmb.value(QStringLiteral("domain")).toString(), QStringLiteral("WORKGROUP"));
            QCOMPARE(parsedSmb.value(QStringLiteral("host")).toString(), QStringLiteral("nas.local"));
            QCOMPARE(parsedSmb.value(QStringLiteral("remotePath")).toString(), QStringLiteral("/media/films"));

            const QVariantMap parsedSshfs = backend.parseRemoteUri(QStringLiteral("sshfs://dev@box.local:/srv/app"));
            QCOMPARE(parsedSshfs.value(QStringLiteral("protocol")).toString(), QStringLiteral("sshfs"));
            QCOMPARE(parsedSshfs.value(QStringLiteral("host")).toString(), QStringLiteral("box.local"));
            QCOMPARE(parsedSshfs.value(QStringLiteral("remotePath")).toString(), QStringLiteral("/srv/app"));

            QVariantMap sftpConn;
            sftpConn[QStringLiteral("id")] = QStringLiteral("web_srv");
            sftpConn[QStringLiteral("name")] = QStringLiteral("Web Server");
            sftpConn[QStringLiteral("protocol")] = QStringLiteral("sftp");
            sftpConn[QStringLiteral("host")] = QStringLiteral("10.10.0.5");
            sftpConn[QStringLiteral("port")] = 22;
            sftpConn[QStringLiteral("user")] = QStringLiteral("radu");
            sftpConn[QStringLiteral("remotePath")] = QStringLiteral("/var/www");
            QVERIFY(backend.saveRemoteConnection(sftpConn));

            QVariantMap smbConn;
            smbConn[QStringLiteral("id")] = QStringLiteral("nas_media");
            smbConn[QStringLiteral("name")] = QStringLiteral("NAS Media");
            smbConn[QStringLiteral("protocol")] = QStringLiteral("smb");
            smbConn[QStringLiteral("host")] = QStringLiteral("nas.local");
            smbConn[QStringLiteral("user")] = QStringLiteral("radu");
            smbConn[QStringLiteral("domain")] = QStringLiteral("WORKGROUP");
            smbConn[QStringLiteral("remotePath")] = QStringLiteral("/media");
            QVERIFY(backend.saveRemoteConnection(smbConn));

            QCOMPARE(backend.remoteConnections().size(), 2);

            const QString resolved = backend.resolveRemoteMountPath(sftpConn);
            QCOMPARE(resolved, QDir::cleanPath(gvfsWebDir));

            const QString connectedPath = backend.connectRemote(QStringLiteral("web_srv"));
            QCOMPARE(connectedPath, QDir::cleanPath(gvfsWebDir));
            QCOMPARE(backend.activeModel()->path(), QDir::cleanPath(gvfsWebDir));

            bool foundMountedRemoteDrive = false;
            const QVariantList driveList = backend.drives();
            for (const QVariant &v : driveList) {
                const QVariantMap d = v.toMap();
                if (d.value(QStringLiteral("remoteId")).toString() == QStringLiteral("web_srv")) {
                    QCOMPARE(d.value(QStringLiteral("isRemote")).toBool(), true);
                    QCOMPARE(d.value(QStringLiteral("isMounted")).toBool(), true);
                    QCOMPARE(d.value(QStringLiteral("canUnmount")).toBool(), true);
                    foundMountedRemoteDrive = true;
                }
            }
            QVERIFY(foundMountedRemoteDrive);

            QVERIFY(backend.disconnectRemote(QStringLiteral("web_srv")));
            QVERIFY(!QDir(gvfsSftpRoot).exists());
            QVERIFY(backend.resolveRemoteMountPath(sftpConn).isEmpty());
        }

        // Reload Backend from same config to verify persistence of remote connections
        Backend backendReloaded(cfg.filePath("bookmarks.json"));
        QCOMPARE(backendReloaded.remoteConnections().size(), 2);
        QVERIFY(backendReloaded.deleteRemoteConnection(QStringLiteral("web_srv")));
        QCOMPARE(backendReloaded.remoteConnections().size(), 1);
    }

    void openWithMimeDesktopAppsAndCustomActions()
    {
        QTemporaryDir appsDir, workDir, cfg;
        const QString mimeAppsPath = cfg.filePath("mimeapps.list");
        qputenv("OMAPANEL_APPS_DIR", appsDir.path().toUtf8());
        qputenv("OMAPANEL_APPS_ONLY_OVERRIDE", "1");
        qputenv("OMAPANEL_MIMEAPPS_FILE", mimeAppsPath.toUtf8());
        struct EnvCleanup {
            ~EnvCleanup() {
                qunsetenv("OMAPANEL_APPS_DIR");
                qunsetenv("OMAPANEL_APPS_ONLY_OVERRIDE");
                qunsetenv("OMAPANEL_MIMEAPPS_FILE");
            }
        } cleanup;

        QString trueBin = QStandardPaths::findExecutable(QStringLiteral("true"));
        if (trueBin.isEmpty())
            trueBin = QStringLiteral("/usr/bin/true");

        writeFile(appsDir.filePath("md-editor.desktop"),
                  QStringLiteral("[Desktop Entry]\nType=Application\nName=Markdown Writer\nGenericName=Editor\nExec=%1 %f\nMimeType=text/markdown;text/plain;\n")
                      .arg(trueBin).toUtf8());
        writeFile(appsDir.filePath("png-viewer.desktop"),
                  QStringLiteral("[Desktop Entry]\nType=Application\nName=Image Looker\nExec=%1 %u\nMimeType=image/png;\n")
                      .arg(trueBin).toUtf8());

        const QString mdPath = workDir.filePath("notes with space.md");
        writeFile(mdPath, "# Title\nline2\n");

        {
            Backend backend(cfg.filePath("bookmarks.json"));

            const QVariantMap mimeInfo = backend.getFileMimeInfo(mdPath);
            QCOMPARE(mimeInfo.value(QStringLiteral("mimeType")).toString(), QStringLiteral("text/markdown"));

            const QVariantList appsBefore = backend.getApplicationsForFile(mdPath);
            QCOMPARE(appsBefore.size(), 1);
            QCOMPARE(appsBefore.first().toMap().value(QStringLiteral("desktopId")).toString(), QStringLiteral("md-editor.desktop"));
            QCOMPARE(appsBefore.first().toMap().value(QStringLiteral("isDefault")).toBool(), false);

            QVERIFY(backend.setDefaultApplicationForMime(QStringLiteral("text/markdown"), QStringLiteral("md-editor.desktop")));
            const QVariantList appsAfter = backend.getApplicationsForFile(mdPath);
            QCOMPARE(appsAfter.size(), 1);
            QCOMPARE(appsAfter.first().toMap().value(QStringLiteral("isDefault")).toBool(), true);
            QCOMPARE(backend.getFileMimeInfo(mdPath).value(QStringLiteral("defaultApp")).toString(), QStringLiteral("md-editor.desktop"));

            QVERIFY(backend.openWithApplication({mdPath}, QStringLiteral("md-editor.desktop"), false));

            // Seeded default custom actions
            QVERIFY(backend.customActions().size() >= 3);

            // Custom Action: pattern filtering, % placeholders, execution & persistence
            QVariantMap customAct;
            customAct[QStringLiteral("id")] = QStringLiteral("count_bytes_md");
            customAct[QStringLiteral("name")] = QStringLiteral("Count Bytes in MD");
            customAct[QStringLiteral("command")] = QStringLiteral("wc -c < %f");
            customAct[QStringLiteral("pattern")] = QStringLiteral("*.md");
            customAct[QStringLiteral("runInTerminal")] = false;
            customAct[QStringLiteral("showOutput")] = true;
            QVERIFY(backend.saveCustomAction(customAct));

            const QVariantList matchedForMd = backend.getCustomActionsForFile(mdPath);
            bool foundMdAction = false;
            for (const QVariant &v : matchedForMd) {
                if (v.toMap().value(QStringLiteral("id")).toString() == QStringLiteral("count_bytes_md"))
                    foundMdAction = true;
            }
            QVERIFY(foundMdAction);

            const QString otherFile = workDir.filePath("pic.png");
            writeFile(otherFile, "PNGDATA");
            const QVariantList matchedForPng = backend.getCustomActionsForFile(otherFile);
            for (const QVariant &v : matchedForPng)
                QVERIFY(v.toMap().value(QStringLiteral("id")).toString() != QStringLiteral("count_bytes_md"));

            const QString expanded = backend.expandCustomActionCommand(QStringLiteral("echo %n %b %e %f"), {mdPath});
            QVERIFY(expanded.contains(QStringLiteral("notes with space.md")));
            QVERIFY(expanded.contains(QStringLiteral("'md'")));

            const QVariantMap execRes = backend.executeCustomAction(QStringLiteral("count_bytes_md"), {mdPath});
            QCOMPARE(execRes.value(QStringLiteral("ok")).toBool(), true);
            QCOMPARE(execRes.value(QStringLiteral("exitCode")).toInt(), 0);
            QCOMPARE(execRes.value(QStringLiteral("showOutput")).toBool(), true);
            QCOMPARE(execRes.value(QStringLiteral("output")).toString().trimmed().toInt(), 14);
        }

        // Verify persistence across Backend reload
        Backend backendReloaded(cfg.filePath("bookmarks.json"));
        const QVariantList reloadedForMd = backendReloaded.getCustomActionsForFile(mdPath);
        bool persistedFound = false;
        for (const QVariant &v : reloadedForMd) {
            if (v.toMap().value(QStringLiteral("id")).toString() == QStringLiteral("count_bytes_md"))
                persistedFound = true;
        }
        QVERIFY(persistedFound);
        QVERIFY(backendReloaded.deleteCustomAction(QStringLiteral("count_bytes_md")));
    }

    void googleDriveRcloneDiscoveryMountAndAuth()
    {
        QTemporaryDir mountsDir, cfg, binDir;
        const QString remotesStateFile = cfg.filePath("mock_remotes.txt");
        writeFile(remotesStateFile, "gdrive: drive\nmycloud: s3\n");

        const QString mockRclone = binDir.filePath("rclone");
        const QString script = QStringLiteral(
            "#!/bin/sh\n"
            "STATE_FILE=\"%1\"\n"
            "cmd=\"$1\"\n"
            "if [ \"$cmd\" = \"listremotes\" ]; then\n"
            "  cat \"$STATE_FILE\"\n"
            "  exit 0\n"
            "fi\n"
            "if [ \"$cmd\" = \"mount\" ]; then\n"
            "  target=\"$3\"\n"
            "  mkdir -p \"$target\"\n"
            "  echo \"Drive content\" > \"$target/DriveReadme.txt\"\n"
            "  exit 0\n"
            "fi\n"
            "if [ \"$cmd\" = \"config\" ]; then\n"
            "  sub=\"$2\"\n"
            "  name=\"$3\"\n"
            "  if [ \"$sub\" = \"create\" ]; then\n"
            "    echo \"NOTICE: Link: http://127.0.0.1:53682/auth?state=mock1\" >&2\n"
            "    echo '{\"State\":\"teamdrive_ok\",\"Option\":{\"DefaultStr\":\"false\"}}'\n"
            "    exit 0\n"
            "  elif [ \"$sub\" = \"update\" ]; then\n"
            "    echo \"${name}: drive\" >> \"$STATE_FILE\"\n"
            "    echo '{\"State\":\"\"}'\n"
            "    exit 0\n"
            "  fi\n"
            "fi\n"
            "exit 1\n").arg(remotesStateFile);
        writeFile(mockRclone, script.toUtf8());
        QFile::setPermissions(mockRclone, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner
                                              | QFile::ReadGroup | QFile::ExeGroup);

        qputenv("TWINFORGE_RCLONE_BIN", mockRclone.toUtf8());
        qputenv("TWINFORGE_MOUNTS_DIR", mountsDir.path().toUtf8());
        qputenv("TWINFORGE_RCLONE_CONF", cfg.filePath("rclone.conf").toUtf8());
        struct EnvCleanup {
            ~EnvCleanup() {
                qunsetenv("TWINFORGE_RCLONE_BIN");
                qunsetenv("TWINFORGE_MOUNTS_DIR");
                qunsetenv("TWINFORGE_RCLONE_CONF");
            }
        } cleanup;

        Backend backend(cfg.filePath("bookmarks.json"));

        // URI parsing and normalization
        const QVariantMap parsedGdrive = backend.parseRemoteUri(QStringLiteral("google-drive://personal/Docs"));
        QCOMPARE(parsedGdrive.value(QStringLiteral("protocol")).toString(), QStringLiteral("gdrive"));
        QCOMPARE(parsedGdrive.value(QStringLiteral("host")).toString(), QStringLiteral("personal"));
        QCOMPARE(parsedGdrive.value(QStringLiteral("port")).toInt(), 0);
        QCOMPARE(parsedGdrive.value(QStringLiteral("remotePath")).toString(), QStringLiteral("/Docs"));
        QCOMPARE(backend.buildRemoteUri(parsedGdrive), QStringLiteral("gdrive://personal/Docs"));

        const QVariantMap parsedRclone = backend.parseRemoteUri(QStringLiteral("rclone://mycloud/Backups"));
        QCOMPARE(parsedRclone.value(QStringLiteral("protocol")).toString(), QStringLiteral("rclone"));
        QCOMPARE(parsedRclone.value(QStringLiteral("host")).toString(), QStringLiteral("mycloud"));
        QCOMPARE(backend.buildRemoteUri(parsedRclone), QStringLiteral("rclone://mycloud/Backups"));

        // Discovered rclone remotes + automatic Drive bar entry
        QVERIFY(backend.rcloneAvailable());
        QCOMPARE(backend.rcloneRemotes().size(), 2);
        QCOMPARE(backend.rcloneRemotes().first().toMap().value(QStringLiteral("name")).toString(), QStringLiteral("gdrive"));
        QCOMPARE(backend.rcloneRemotes().first().toMap().value(QStringLiteral("isGoogleDrive")).toBool(), true);

        auto findDriveChip = [&backend](const QString &uri) -> QVariantMap {
            for (const QVariant &v : backend.drives()) {
                const QVariantMap d = v.toMap();
                if (d.value(QStringLiteral("remoteUri")).toString() == uri)
                    return d;
            }
            return {};
        };

        const QVariantMap chipBefore = findDriveChip(QStringLiteral("gdrive://gdrive"));
        QCOMPARE(chipBefore.value(QStringLiteral("isRemote")).toBool(), true);
        QCOMPARE(chipBefore.value(QStringLiteral("free")).toString(), QStringLiteral("GDRIVE"));
        QCOMPARE(chipBefore.value(QStringLiteral("isMounted")).toBool(), false);

        // Mount Google Drive remote and navigate active panel
        const QString mountedPath = backend.connectRemote(QStringLiteral("gdrive://gdrive"));
        QVERIFY(!mountedPath.isEmpty());
        QVERIFY(QFileInfo::exists(QDir(mountedPath).filePath(QStringLiteral("DriveReadme.txt"))));
        QCOMPARE(backend.activeModel()->path(), mountedPath);

        const QVariantMap chipAfter = findDriveChip(QStringLiteral("gdrive://gdrive"));
        QCOMPARE(chipAfter.value(QStringLiteral("isMounted")).toBool(), true);
        QCOMPARE(chipAfter.value(QStringLiteral("canUnmount")).toBool(), true);

        // Disconnect mount cleanly
        QVERIFY(backend.disconnectRemote(QStringLiteral("gdrive://gdrive")));
        const QVariantMap chipDisconnected = findDriveChip(QStringLiteral("gdrive://gdrive"));
        QCOMPARE(chipDisconnected.value(QStringLiteral("isMounted")).toBool(), false);

        // Async Google OAuth flow (mock create + continue update)
        QSignalSpy authSpy(&backend, &Backend::gdriveAuthFinished);
        backend.startGoogleDriveAuth(QStringLiteral("work_drive"));
        QTRY_COMPARE_WITH_TIMEOUT(authSpy.count(), 1, 5000);
        QCOMPARE(authSpy.first().at(0).toBool(), true);
        QCOMPARE(authSpy.first().at(1).toString(), QStringLiteral("work_drive"));
        QCOMPARE(backend.rcloneRemotes().size(), 3);

        bool workSaved = false;
        for (const QVariant &v : backend.remoteConnections()) {
            if (v.toMap().value(QStringLiteral("host")).toString() == QStringLiteral("work_drive"))
                workSaved = true;
        }
        QVERIFY(workSaved);
    }

    void asyncGitStatusAndDirectorySwitchCancellation()
    {
        QTemporaryDir repoDir;
        QTemporaryDir plainDir;
        QProcess proc;
        proc.setWorkingDirectory(repoDir.path());
        proc.start(QStringLiteral("git"), {QStringLiteral("init")});
        if (!proc.waitForFinished(3000) || proc.exitCode() != 0)
            return;

        writeFile(repoDir.filePath("file.txt"), "initial");
        proc.start(QStringLiteral("git"), {QStringLiteral("add"), QStringLiteral("file.txt")});
        proc.waitForFinished(2000);
        proc.start(QStringLiteral("git"), {QStringLiteral("-c"), QStringLiteral("user.name=Test"),
                                           QStringLiteral("-c"), QStringLiteral("user.email=test@example.com"),
                                           QStringLiteral("commit"), QStringLiteral("-m"), QStringLiteral("init")});
        proc.waitForFinished(2000);
        writeFile(repoDir.filePath("file.txt"), "edited");
        writeFile(plainDir.filePath("note.txt"), "not a git repo");

        PanelModel model;
        // Rapid switch: enter git repo, then immediately leave to plainDir.
        model.setPath(repoDir.path());
        model.setPath(plainDir.path());
        QTRY_COMPARE(model.gitStatusLoading(), false);
        QCOMPARE(model.isGitRepo(), false);
        QVERIFY(model.gitBranch().isEmpty());

        // Now navigate back into git repo and verify async status resolves cleanly.
        model.setPath(repoDir.path());
        QTRY_VERIFY(model.isGitRepo());
        QTRY_VERIFY(!model.gitBranch().isEmpty());
        QTRY_VERIFY(model.gitModifiedCount() >= 1);
    }

    void asyncHeavyOperationsAndCancellation()
    {
        QTemporaryDir leftDir;
        QTemporaryDir rightDir;
        QTemporaryDir dupDir;
        QTemporaryDir arcDir;
        QTemporaryDir cfg;
        QVERIFY(QDir().mkpath(dupDir.filePath("d1")));
        QVERIFY(QDir().mkpath(dupDir.filePath("d2")));

        const QString sampleFile = leftDir.filePath("hello.md");
        writeFile(sampleFile, "# Async Preview\n\nTwinForge background worker test.");
        writeFile(leftDir.filePath("only_left.txt"), "left payload");
        writeFile(rightDir.filePath("only_right.txt"), "right payload");
        writeFile(dupDir.filePath("d1/dup.bin"), QByteArray(4096, 'X'));
        writeFile(dupDir.filePath("d2/dup_copy.bin"), QByteArray(4096, 'X'));

        Backend backend(cfg.filePath("bookmarks.json"));

        // 1. Async checksum
        QSignalSpy checksumSpy(&backend, &Backend::checksumFinished);
        backend.startChecksumCalculation(sampleFile);
        QTRY_COMPARE_WITH_TIMEOUT(checksumSpy.count(), 1, 5000);
        const QVariantMap hashes = checksumSpy.first().at(0).toMap();
        QCOMPARE(hashes.value(QStringLiteral("sha256")).toString().length(), 64);
        QCOMPARE(hashes.value(QStringLiteral("md5")).toString().length(), 32);

        // 2. Async preview (modal + quickview)
        QSignalSpy previewSpy(&backend, &Backend::previewReady);
        backend.requestPreview(sampleFile, 1, QStringLiteral("modal"));
        backend.requestPreview(sampleFile, 1, QStringLiteral("quickview"));
        QTRY_COMPARE_WITH_TIMEOUT(previewSpy.count(), 2, 5000);
        bool sawModal = false, sawQuick = false;
        for (const QList<QVariant> &sig : previewSpy) {
            const QString target = sig.at(0).toString();
            const QVariantMap data = sig.at(1).toMap();
            QCOMPARE(data.value(QStringLiteral("isMarkdown")).toBool(), true);
            if (target == QLatin1String("modal")) sawModal = true;
            if (target == QLatin1String("quickview")) sawQuick = true;
        }
        QVERIFY(sawModal);
        QVERIFY(sawQuick);

        // 3. Async directory compare & sync
        QSignalSpy syncFinishedSpy(&backend, &Backend::directorySyncFinished);
        backend.startDirectoryCompare(leftDir.path(), rightDir.path(), QStringLiteral("date_size"), false);
        QTRY_VERIFY_WITH_TIMEOUT(!backend.syncRunning() && backend.syncCompareResults().size() >= 2, 5000);
        backend.startDirectorySync(leftDir.path(), rightDir.path(), backend.syncCompareResults());
        QTRY_COMPARE_WITH_TIMEOUT(syncFinishedSpy.count(), 1, 5000);
        QVERIFY(QFile::exists(rightDir.filePath("only_left.txt")));
        QVERIFY(QFile::exists(leftDir.filePath("only_right.txt")));

        // 4. Async duplicate finder
        backend.startDuplicateScan(dupDir.path(), QString(), 1, false);
        QTRY_VERIFY_WITH_TIMEOUT(!backend.duplicateScanRunning() && backend.duplicateResults().size() == 2, 5000);

        // 5. Async archive pack & extract
        const QString tarPath = arcDir.filePath("bundle.tar.gz");
        const QString extractDir = arcDir.filePath("out");
        QSignalSpy arcSpy(&backend, &Backend::archiveOperationFinished);
        backend.packArchiveAsync({sampleFile}, tarPath);
        QTRY_COMPARE_WITH_TIMEOUT(arcSpy.count(), 1, 8000);
        QCOMPARE(arcSpy.first().at(0).toBool(), true);
        QVERIFY(QFile::exists(tarPath));

        backend.extractArchiveAsync(tarPath, extractDir);
        QTRY_COMPARE_WITH_TIMEOUT(arcSpy.count(), 2, 8000);
        QCOMPARE(arcSpy.at(1).at(0).toBool(), true);
        QVERIFY(QFile::exists(QDir(extractDir).filePath("hello.md")));

        // 6. Async remote connect (pre-mounted GVFS mock)
        QTemporaryDir gvfsDir;
        QVERIFY(QDir().mkpath(gvfsDir.filePath("sftp:host=async.local,user=dev")));
        qputenv("TWINFORGE_GVFS_DIR", gvfsDir.path().toUtf8());
        auto cleanupEnv = qScopeGuard([] { qunsetenv("TWINFORGE_GVFS_DIR"); });
        QSignalSpy remoteSpy(&backend, &Backend::remoteOperationFinished);
        backend.connectRemoteAsync(QStringLiteral("sftp://dev@async.local/"));
        QTRY_COMPARE_WITH_TIMEOUT(remoteSpy.count(), 1, 5000);
        QCOMPARE(remoteSpy.first().at(0).toBool(), true);
        QVERIFY(!remoteSpy.first().at(1).toString().isEmpty());
    }

    void freedesktopThumbnailCacheSpec()
    {
        QTemporaryDir mediaDir;
        QTemporaryDir cacheDir;
        qputenv("TWINFORGE_THUMBNAIL_CACHE_DIR", cacheDir.path().toUtf8());
        auto cleanupEnv = qScopeGuard([] { qunsetenv("TWINFORGE_THUMBNAIL_CACHE_DIR"); });

        // Create a 400x300 PNG image
        const QString imgPath = mediaDir.filePath("photo sample.png");
        QImage srcImg(400, 300, QImage::Format_ARGB32);
        srcImg.fill(QColor("#2288ee"));
        QVERIFY(srcImg.save(imgPath, "PNG"));

        // Verify PanelModel exposes image://thumb/... URL for Grid view
        PanelModel model(mediaDir.path());
        const int idx = model.findIndexByPrefix("photo sample.png");
        QVERIFY(idx >= 0);
        const QString thumbUrl = model.data(model.index(idx, 0), PanelModel::ThumbnailUrlRole).toString();
        QVERIFY(thumbUrl.startsWith(QStringLiteral("image://thumb/")));
        QVERIFY(thumbUrl.contains(QStringLiteral("photo%20sample.png")));
        QCOMPARE(ThumbnailProvider::decodeRequestPath(thumbUrl.mid(QStringLiteral("image://thumb/").size())),
                 QFileInfo(imgPath).absoluteFilePath());

        // 1. First generation: cache miss, creates Freedesktop large/MD5.png with spec metadata
        bool fromCache = true;
        const QImage first = ThumbnailProvider::loadOrGenerateThumbnail(imgPath, QSize(192, 192), nullptr, &fromCache);
        QVERIFY(!first.isNull());
        QCOMPARE(fromCache, false);
        QVERIFY(first.width() <= 192 && first.height() <= 192);

        const QString expectedCacheFile = ThumbnailProvider::cacheFilePathFor(imgPath, true);
        QVERIFY(QFileInfo::exists(expectedCacheFile));
        QVERIFY(expectedCacheFile.contains(QStringLiteral("/large/")));
        QVERIFY(expectedCacheFile.endsWith(QStringLiteral(".png")));

        QImage cachedImg(expectedCacheFile);
        QVERIFY(!cachedImg.isNull());
        QCOMPARE(cachedImg.text(QStringLiteral("Thumb::URI")), ThumbnailProvider::canonicalUriForPath(imgPath));
        QCOMPARE(cachedImg.text(QStringLiteral("Thumb::MTime")),
                 QString::number(QFileInfo(imgPath).lastModified().toSecsSinceEpoch()));
        QCOMPARE(cachedImg.text(QStringLiteral("Thumb::Size")),
                 QString::number(QFileInfo(imgPath).size()));

        // 2. Second load: cache hit!
        fromCache = false;
        const QImage second = ThumbnailProvider::loadOrGenerateThumbnail(imgPath, QSize(192, 192), nullptr, &fromCache);
        QVERIFY(!second.isNull());
        QCOMPARE(fromCache, true);

        // 3. Normal (<= 128) size uses /normal/ bucket
        const QImage normalThumb = ThumbnailProvider::loadOrGenerateThumbnail(imgPath, QSize(96, 96), nullptr, &fromCache);
        QVERIFY(!normalThumb.isNull());
        QCOMPARE(fromCache, false);
        QVERIFY(QFileInfo::exists(ThumbnailProvider::cacheFilePathFor(imgPath, false)));
        QVERIFY(ThumbnailProvider::cacheFilePathFor(imgPath, false).contains(QStringLiteral("/normal/")));

        // 4. Modifying source file (new mtime/size) invalidates cache cleanly
        QImage updatedImg(500, 250, QImage::Format_ARGB32);
        updatedImg.fill(QColor("#ee4422"));
        QVERIFY(updatedImg.save(imgPath, "PNG"));
        {
            QFile f(imgPath);
            QVERIFY(f.open(QIODevice::ReadWrite));
            QVERIFY(f.setFileTime(QDateTime::currentDateTime().addSecs(10), QFileDevice::FileModificationTime));
        }
        fromCache = true;
        const QImage refreshed = ThumbnailProvider::loadOrGenerateThumbnail(imgPath, QSize(192, 192), nullptr, &fromCache);
        QVERIFY(!refreshed.isNull());
        QCOMPARE(fromCache, false);

        // 5. Files inside thumbnail cache directory must never be thumbnailed (Freedesktop spec)
        const QImage selfThumb = ThumbnailProvider::loadOrGenerateThumbnail(expectedCacheFile, QSize(128, 128));
        QVERIFY(selfThumb.isNull());
    }

    void cliArgumentsParsingAndShellInit()
    {
        QTemporaryDir root;
        QVERIFY(QDir().mkpath(root.filePath("left_dir")));
        QVERIFY(QDir().mkpath(root.filePath("right_dir")));
        const QString sampleFile = root.filePath("left_dir/readme.txt");
        writeFile(sampleFile, "cli test");

        QString err, out;
        bool exitOk = false;

        // 1. Two positional paths (one relative, one file:// URI)
        const CliRequest twoPanels = parseCliArguments(
            {QStringLiteral("tf"), QStringLiteral("left_dir"),
             QUrl::fromLocalFile(root.filePath("right_dir")).toString()},
            root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(err.isEmpty());
        QCOMPARE(exitOk, false);
        QCOMPARE(twoPanels.leftPath, QDir::cleanPath(root.filePath("left_dir")));
        QCOMPARE(twoPanels.rightPath, QDir::cleanPath(root.filePath("right_dir")));
        QCOMPARE(twoPanels.shouldUseSingleInstance(), true);

        // 2. Passing a file highlights it inside its parent directory
        const CliRequest fileArg = parseCliArguments(
            {QStringLiteral("tf"), QStringLiteral("--new-tab"), sampleFile},
            root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(err.isEmpty());
        QCOMPARE(fileArg.leftPath, QDir::cleanPath(root.filePath("left_dir")));
        QCOMPARE(fileArg.selectPath, QDir::cleanPath(sampleFile));
        QCOMPARE(fileArg.newTab, true);

        // 3. --select + --new-window disables single-instance handoff
        const CliRequest selArg = parseCliArguments(
            {QStringLiteral("tf"), QStringLiteral("-n"), QStringLiteral("-s"), sampleFile},
            root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(err.isEmpty());
        QCOMPARE(selArg.newWindow, true);
        QCOMPARE(selArg.shouldUseSingleInstance(), false);
        QCOMPARE(selArg.leftPath, QDir::cleanPath(root.filePath("left_dir")));
        QCOMPARE(selArg.selectPath, QDir::cleanPath(sampleFile));

        // 4. --last-dir-file & --print-last-dir disable single-instance handoff and write cleanly
        const QString lastDirPath = root.filePath("last_dir.txt");
        const CliRequest lastDirReq = parseCliArguments(
            {QStringLiteral("tf"), QStringLiteral("--last-dir-file"), lastDirPath, QStringLiteral("--print-last-dir")},
            root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(err.isEmpty());
        QCOMPARE(lastDirReq.shouldUseSingleInstance(), false);
        QCOMPARE(lastDirReq.printLastDir, true);
        QCOMPARE(lastDirReq.lastDirFile, QDir::cleanPath(lastDirPath));
        QVERIFY(writeLastDirFile(lastDirReq.lastDirFile, root.filePath("right_dir")));
        QCOMPARE(QString::fromUtf8(readFile(lastDirPath)).trimmed(), root.filePath("right_dir"));

        // 5. --version and --shell-init (bash, zsh, fish, invalid)
        parseCliArguments({QStringLiteral("tf"), QStringLiteral("--version")},
                          root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(err.isEmpty());
        QCOMPARE(exitOk, true);
        QVERIFY(out.contains(QStringLiteral("twinforge 0.1.0")));

        for (const QString &sh : {QStringLiteral("bash"), QStringLiteral("zsh"), QStringLiteral("fish")}) {
            parseCliArguments({QStringLiteral("tf"), QStringLiteral("--shell-init"), sh},
                              root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
            QVERIFY(err.isEmpty());
            QCOMPARE(exitOk, true);
            QVERIFY(out.contains(QStringLiteral("tfcd")));
            QVERIFY(out.contains(QStringLiteral("--last-dir-file")));
        }

        parseCliArguments({QStringLiteral("tf"), QStringLiteral("--shell-init"), QStringLiteral("powershell")},
                          root.path(), QStringLiteral("0.1.0"), &err, &exitOk, &out);
        QVERIFY(!err.isEmpty());
        QCOMPARE(exitOk, false);
    }

    void singleInstanceIpcAndNavigationRequest()
    {
        QTemporaryDir root;
        QTemporaryDir cfg;
        QVERIFY(QDir().mkpath(root.filePath("alpha")));
        QVERIFY(QDir().mkpath(root.filePath("beta")));
        const QString hiddenFile = root.filePath("beta/.secret_cfg");
        writeFile(hiddenFile, "secret=1");

        const QString sockName = QStringLiteral("twinforge-test-ipc-%1-%2")
                                     .arg(QCoreApplication::applicationPid())
                                     .arg(QDateTime::currentMSecsSinceEpoch());

        SingleInstance primary(sockName);
        QVERIFY(primary.startListening());
        QVERIFY(primary.isListening());

        Backend backend(cfg.filePath("bookmarks.json"));
        QSignalSpy focusSpy(&backend, &Backend::focusAndSelectRequested);
        QSignalSpy activateSpy(&backend, &Backend::windowActivateRequested);

        CliRequest received;
        bool gotRequest = false;
        QObject::connect(&primary, &SingleInstance::requestReceived, &backend,
                         [&](const CliRequest &req) {
                             received = req;
                             gotRequest = true;
                             backend.applyNavigationRequest(req.leftPath, req.rightPath, req.selectPath, req.newTab);
                         });

        CliRequest outbound;
        outbound.leftPath = root.filePath("alpha");
        outbound.rightPath = root.filePath("beta");
        outbound.selectPath = hiddenFile;
        outbound.newTab = true;

        std::atomic<bool> sendOk{false};
        QThread *senderThread = QThread::create([sockName, outbound, &sendOk]() {
            SingleInstance client(sockName);
            sendOk.store(client.sendToRunningInstance(outbound, 1500));
        });
        senderThread->start();

        QTRY_VERIFY_WITH_TIMEOUT(gotRequest, 3000);
        senderThread->wait(3000);
        delete senderThread;

        QCOMPARE(sendOk.load(), true);
        QCOMPARE(received.leftPath, outbound.leftPath);
        QCOMPARE(received.rightPath, outbound.rightPath);
        QCOMPARE(received.selectPath, outbound.selectPath);
        QCOMPARE(received.newTab, true);

        QCOMPARE(backend.leftPanel()->path(), QDir::cleanPath(root.filePath("alpha")));
        QCOMPARE(backend.rightPanel()->path(), QDir::cleanPath(root.filePath("beta")));
        QCOMPARE(backend.leftPanel()->tabCount(), 2);
        QCOMPARE(backend.rightPanel()->tabCount(), 2);
        QCOMPARE(backend.activePanel(), 1); // selectPath is inside rightPath
        QCOMPARE(backend.rightPanel()->showHidden(), true); // auto-revealed hidden target
        QVERIFY(backend.rightPanel()->findIndexByPath(hiddenFile) >= 0);
        QCOMPARE(focusSpy.count(), 1);
        QCOMPARE(focusSpy.first().at(0).toInt(), 1);
        QCOMPARE(focusSpy.first().at(1).toString(), QFileInfo(hiddenFile).absoluteFilePath());
        QVERIFY(activateSpy.count() >= 1);
        QCOMPARE(backend.activeFilesystemPath(), QDir::cleanPath(root.filePath("beta")));
    }

    void lockedTabsAndTabManagement()
    {
        QTemporaryDir root;
        QTemporaryDir cfg;
        const QString dirA = root.filePath("dirA");
        const QString dirB = root.filePath("dirB");
        const QString dirSub = root.filePath("dirA/sub");
        QVERIFY(QDir().mkpath(dirSub));
        QVERIFY(QDir().mkpath(dirB));

        {
            Backend backend(cfg.filePath("bookmarks.json"));
            PanelModel *left = backend.leftPanel();
            PanelModel *right = backend.rightPanel();

            left->setPath(dirA);
            left->addTab(dirB);
            QCOMPARE(left->tabCount(), 2);
            QCOMPARE(left->activeTab(), 1);

            // 1. Lock tab 0 in strict mode (TabLocked = 1)
            left->setTabLockMode(0, PanelModel::TabLocked);
            left->setActiveTab(0);
            QCOMPARE(left->activeTabLockMode(), static_cast<int>(PanelModel::TabLocked));

            // Attempting to close a locked tab must be blocked
            left->closeTab(0);
            QCOMPARE(left->tabCount(), 2);

            // Navigating from a strictly locked tab opens a new tab instead of changing the locked tab
            left->setPath(dirSub);
            QCOMPARE(left->tabCount(), 3);
            QCOMPARE(left->path(), QDir::cleanPath(dirSub));
            QCOMPARE(left->tabPaths().at(0), QDir::cleanPath(dirA));

            // 2. Lock tab 1 in allow-navigation mode (TabLockedAllowNav = 2)
            left->setActiveTab(1);
            left->setTabLockMode(1, PanelModel::TabLockedAllowNav);
            QCOMPARE(left->activeTabLockMode(), static_cast<int>(PanelModel::TabLockedAllowNav));
            left->setPath(dirSub);
            QCOMPARE(left->tabCount(), 3); // stayed on same tab
            QCOMPARE(left->path(), QDir::cleanPath(dirSub));
            // Resetting returns to lockedRootPath
            left->resetLockedTab(1);
            QCOMPARE(left->path(), QDir::cleanPath(dirB));

            // 3. Duplicate tab, move tab, closeOtherTabs (preserves locked tabs!), reopenClosedTab
            left->setActiveTab(2); // unlocked tab at dirSub
            left->duplicateTab(2);
            QCOMPARE(left->tabCount(), 4);
            left->moveTab(3, 2);
            QCOMPARE(left->activeTab(), 2);

            // Close tab 3 -> pushes to closed-tabs stack
            left->closeTab(3);
            QCOMPARE(left->tabCount(), 3);
            QVERIFY(left->canReopenClosedTab());
            QVERIFY(left->reopenClosedTab());
            QCOMPARE(left->tabCount(), 4);

            // Close other tabs keeping tab 2 -> locked tabs (0 & 1) stay protected!
            left->closeOtherTabs(2);
            QCOMPARE(left->tabCount(), 3); // tabs 0 (strict), 1 (allow-nav), and kept tab 2

            // Move unlocked tab to opposite panel
            const int rightBefore = right->tabCount();
            QVERIFY(backend.moveTabToOppositePanel(0, 2));
            QCOMPARE(right->tabCount(), rightBefore + 1);
            QCOMPARE(right->path(), QDir::cleanPath(dirSub));
            QCOMPARE(left->tabCount(), 2); // only the 2 locked tabs remain on left

            backend.saveSession();
        }

        // 4. Verify locked tab state persists cleanly across sessions
        {
            Backend reloaded(cfg.filePath("bookmarks.json"));
            const QVariantList tabs = reloaded.leftPanel()->tabs();
            QCOMPARE(tabs.size(), 2);
            QCOMPARE(tabs.at(0).toMap().value("lockMode").toInt(), static_cast<int>(PanelModel::TabLocked));
            QCOMPARE(tabs.at(0).toMap().value("lockedRootPath").toString(), QDir::cleanPath(dirA));
            QCOMPARE(tabs.at(1).toMap().value("lockMode").toInt(), static_cast<int>(PanelModel::TabLockedAllowNav));
            QCOMPARE(tabs.at(1).toMap().value("lockedRootPath").toString(), QDir::cleanPath(dirB));
        }
    }

    void workspacesSaveLoadAndPersistence()
    {
        QTemporaryDir root;
        QTemporaryDir cfg;
        const QString d1 = root.filePath("proj1");
        const QString d2 = root.filePath("proj2");
        const QString d3 = root.filePath("media");
        const QString d4 = root.filePath("other");
        QVERIFY(QDir().mkpath(d1));
        QVERIFY(QDir().mkpath(d2));
        QVERIFY(QDir().mkpath(d3));
        QVERIFY(QDir().mkpath(d4));

        {
            Backend backend(cfg.filePath("bookmarks.json"));
            backend.leftPanel()->setPath(d1);
            backend.leftPanel()->setTabLockMode(0, PanelModel::TabLockedAllowNav);
            backend.leftPanel()->addTab(d2);
            backend.rightPanel()->setPath(d3);
            backend.rightPanel()->setShowHidden(true);
            backend.setActivePanel(1);

            QVERIFY(backend.saveWorkspace(QStringLiteral("Dev Layout")));
            QCOMPARE(backend.workspaces().size(), 1);
            QCOMPARE(backend.activeWorkspaceName(), QStringLiteral("Dev Layout"));

            // Mutate panels completely
            backend.leftPanel()->setTabLockMode(0, PanelModel::TabUnlocked);
            backend.leftPanel()->restoreTabs({d4}, 0);
            backend.rightPanel()->restoreTabs({d4}, 0);
            backend.rightPanel()->setShowHidden(false);
            backend.setActivePanel(0);
            QCOMPARE(backend.leftPanel()->tabCount(), 1);
            QCOMPARE(backend.leftPanel()->path(), QDir::cleanPath(d4));

            // Reload workspace and verify full dual-panel restoration
            QVERIFY(backend.loadWorkspace(QStringLiteral("Dev Layout")));
            QCOMPARE(backend.leftPanel()->tabCount(), 2);
            QCOMPARE(backend.leftPanel()->tabPaths().at(0), QDir::cleanPath(d1));
            QCOMPARE(backend.leftPanel()->tabPaths().at(1), QDir::cleanPath(d2));
            QCOMPARE(backend.leftPanel()->tabs().at(0).toMap().value("lockMode").toInt(),
                     static_cast<int>(PanelModel::TabLockedAllowNav));
            QCOMPARE(backend.rightPanel()->path(), QDir::cleanPath(d3));
            QCOMPARE(backend.rightPanel()->showHidden(), true);
            QCOMPARE(backend.activePanel(), 1);
        }

        // Verify workspaces.json persistence across restarts & deletion
        {
            Backend fresh(cfg.filePath("bookmarks.json"));
            QCOMPARE(fresh.workspaces().size(), 1);
            QCOMPARE(fresh.workspaces().first().toMap().value("name").toString(), QStringLiteral("Dev Layout"));
            QVERIFY(fresh.deleteWorkspace(QStringLiteral("Dev Layout")));
            QCOMPARE(fresh.workspaces().size(), 0);
        }
    }

    void trashViewRestoreDeleteAndEmpty()
    {
        QTemporaryDir root;
        QTemporaryDir trashDir;
        QTemporaryDir cfg;

        const QByteArray prevTrashEnv = qgetenv("TWINFORGE_TRASH_DIR");
        qputenv("TWINFORGE_TRASH_DIR", trashDir.path().toUtf8());
        auto restoreEnv = qScopeGuard([&]() {
            if (prevTrashEnv.isEmpty())
                qunsetenv("TWINFORGE_TRASH_DIR");
            else
                qputenv("TWINFORGE_TRASH_DIR", prevTrashEnv);
        });

        const QString filesDir = trashDir.filePath("files");
        const QString infoDir = trashDir.filePath("info");
        QVERIFY(QDir().mkpath(filesDir));
        QVERIFY(QDir().mkpath(infoDir));

        const QString origDir = root.filePath("docs");
        QVERIFY(QDir().mkpath(origDir));

        // 1. Trashed file with spaces (percent-encoded Path in .trashinfo)
        const QString trashedNote = QDir(filesDir).filePath("my report.txt");
        writeFile(trashedNote, "hello trash");
        const QString origNote = QDir(origDir).filePath("my report.txt");
        const QByteArray encodedNote = QUrl::toPercentEncoding(origNote, "/");
        writeFile(QDir(infoDir).filePath("my report.txt.trashinfo"),
                  QByteArray("[Trash Info]\nPath=") + encodedNote + QByteArray("\nDeletionDate=2026-11-19T14:25:00\n"));

        // 2. Trashed file whose original path ALREADY has a conflicting file (test collision safety)
        const QString trashedDup = QDir(filesDir).filePath("dup.txt");
        writeFile(trashedDup, "from-trash");
        const QString origDup = QDir(origDir).filePath("dup.txt");
        writeFile(origDup, "existing-file");
        writeFile(QDir(infoDir).filePath("dup.txt.trashinfo"),
                  QByteArray("[Trash Info]\nPath=") + QUrl::toPercentEncoding(origDup, "/") + QByteArray("\nDeletionDate=2026-11-19T14:26:00\n"));

        // 3. Trashed folder to delete permanently & another file for emptyTrash
        const QString trashedFolder = QDir(filesDir).filePath("old_dir");
        QVERIFY(QDir().mkpath(trashedFolder));
        writeFile(QDir(trashedFolder).filePath("inside.txt"), "nested");
        writeFile(QDir(infoDir).filePath("old_dir.trashinfo"),
                  QByteArray("[Trash Info]\nPath=") + QUrl::toPercentEncoding(root.filePath("old_dir"), "/") + QByteArray("\nDeletionDate=2026-11-19T14:27:00\n"));

        const QString trashedLeftover = QDir(filesDir).filePath("leftover.bin");
        writeFile(trashedLeftover, "12345");
        writeFile(QDir(infoDir).filePath("leftover.bin.trashinfo"),
                  QByteArray("[Trash Info]\nPath=") + QUrl::toPercentEncoding(root.filePath("leftover.bin"), "/") + QByteArray("\nDeletionDate=2026-11-19T14:28:00\n"));

        Backend backend(cfg.filePath("bookmarks.json"));
        QCOMPARE(backend.trashCount(), 4);

        // Navigate active panel to trash://
        backend.openTrash();
        PanelModel *panel = backend.activeModel();
        QVERIFY(panel->isTrashView());
        QCOMPARE(panel->path(), QStringLiteral("trash://"));
        QCOMPARE(panel->itemCount(), 4);
        QCOMPARE(backend.activeFilesystemPath(), QDir::homePath());

        // Verify OriginalPathRole and DeletionDateRole metadata
        const int noteIdx = panel->findIndexByPath(trashedNote);
        QVERIFY(noteIdx >= 0);
        const QModelIndex mIdx = panel->index(noteIdx, 0);
        QCOMPARE(panel->data(mIdx, PanelModel::OriginalPathRole).toString(), QDir::cleanPath(origNote));
        QCOMPARE(panel->data(mIdx, PanelModel::DeletionDateRole).toString(), QStringLiteral("2026-11-19 14:25"));

        // Verify Drives bar contains the Trash chip with count "4"
        bool foundTrashChip = false;
        for (const QVariant &v : backend.drives()) {
            const QVariantMap d = v.toMap();
            if (d.value("isTrash").toBool()) {
                foundTrashChip = true;
                QCOMPARE(d.value("path").toString(), QStringLiteral("trash://"));
                QCOMPARE(d.value("free").toString(), QStringLiteral("4"));
            }
        }
        QVERIFY(foundTrashChip);

        // Restore both normal and colliding file
        QCOMPARE(backend.restoreFromTrash({trashedNote, trashedDup}), 2);
        QVERIFY(QFileInfo::exists(origNote));
        QVERIFY(!QFileInfo::exists(trashedNote));
        QVERIFY(!QFileInfo::exists(QDir(infoDir).filePath("my report.txt.trashinfo")));
        // Existing file untouched; colliding restore gets " (restored)" suffix
        const QString restoredDup = QDir(origDir).filePath("dup (restored).txt");
        QVERIFY(QFileInfo::exists(restoredDup));
        QFile fExisting(origDup);
        QVERIFY(fExisting.open(QIODevice::ReadOnly));
        QCOMPARE(fExisting.readAll(), QByteArray("existing-file"));
        QFile fRestored(restoredDup);
        QVERIFY(fRestored.open(QIODevice::ReadOnly));
        QCOMPARE(fRestored.readAll(), QByteArray("from-trash"));
        QCOMPARE(backend.trashCount(), 2);

        // Permanently delete trashed folder (and verify safety guard refuses paths outside trash)
        QCOMPARE(backend.deleteFromTrashPermanently({origNote}), 0);
        QVERIFY(QFileInfo::exists(origNote));
        QCOMPARE(backend.deleteFromTrashPermanently({trashedFolder}), 1);
        QVERIFY(!QFileInfo::exists(trashedFolder));
        QVERIFY(!QFileInfo::exists(QDir(infoDir).filePath("old_dir.trashinfo")));
        QCOMPARE(backend.trashCount(), 1);

        // Empty remaining trash
        QCOMPARE(backend.emptyTrash(), 1);
        QCOMPARE(backend.trashCount(), 0);
        QCOMPARE(panel->itemCount(), 0);
    }

    void typeAheadMultiCharQuickSearch()
    {
        QTemporaryDir root;
        writeFile(root.filePath("alpha.txt"), "1");
        writeFile(root.filePath("beta_one.txt"), "2");
        writeFile(root.filePath("beta_two.txt"), "3");
        writeFile(root.filePath("my_special_report.md"), "4");

        PanelModel model(root.path());
        // Multi-char prefix match
        const int idxTwo = model.findIndexByQuery(QStringLiteral("beta_t"), 0, true);
        QVERIFY(idxTwo >= 0);
        QCOMPARE(model.itemName(idxTwo), QStringLiteral("beta_two.txt"));

        // Cycling on single letter
        const int firstB = model.findIndexByQuery(QStringLiteral("b"), 0, false);
        QVERIFY(firstB >= 0);
        const int secondB = model.findIndexByQuery(QStringLiteral("b"), firstB + 1, false);
        QVERIFY(secondB >= 0);
        QVERIFY(secondB != firstB);
        QVERIFY(model.itemName(secondB).startsWith(QStringLiteral("beta_")));

        // Substring fallback when no prefix matches
        const int subIdx = model.findIndexByQuery(QStringLiteral("special"), 0, true);
        QVERIFY(subIdx >= 0);
        QCOMPARE(model.itemName(subIdx), QStringLiteral("my_special_report.md"));

        // Prefix-only mode must not match substring
        QCOMPARE(model.findIndexByQuery(QStringLiteral("special"), 0, false), -1);
    }

    void asyncCommandRunnerBuiltinCdAndHistory()
    {
        QTemporaryDir root;
        QTemporaryDir cfg;
        const QString subDir = root.filePath("sub folder");
        QVERIFY(QDir().mkpath(subDir));

        {
            Backend backend(cfg.filePath("bookmarks.json"));
            backend.leftPanel()->setPath(root.path());
            backend.setActivePanel(0);

            // Shell quoting helper
            QCOMPARE(backend.shellQuote(QStringLiteral("plain.txt")), QStringLiteral("plain.txt"));
            QCOMPARE(backend.shellQuote(QStringLiteral("my file.txt")), QStringLiteral("'my file.txt'"));
            QCOMPARE(backend.shellQuote(QStringLiteral("it's.txt")), QStringLiteral("'it'\\''s.txt'"));

            // Built-in cd with quoted spaces + cd -
            QSignalSpy doneSpy(&backend, &Backend::commandFinished);
            backend.runCommandAsync(QStringLiteral("cd \"sub folder\""));
            QCOMPARE(doneSpy.count(), 1);
            QCOMPARE(doneSpy.first().at(0).toBool(), true);
            QCOMPARE(backend.leftPanel()->path(), QDir::cleanPath(subDir));

            backend.runCommandAsync(QStringLiteral("cd -"));
            QCOMPARE(backend.leftPanel()->path(), QDir::cleanPath(root.path()));

            // Async shell command streaming output
            doneSpy.clear();
            backend.runCommandAsync(QStringLiteral("printf 'line1\\nline2\\n'"));
            QTRY_COMPARE_WITH_TIMEOUT(doneSpy.count(), 1, 3000);
            QCOMPARE(doneSpy.first().at(0).toBool(), true);
            QCOMPARE(backend.commandRunning(), false);
            QCOMPARE(backend.commandLastExitCode(), 0);
            QVERIFY(backend.commandOutput().contains(QStringLiteral("line1")));
            QVERIFY(backend.commandOutput().contains(QStringLiteral("line2")));

            // Cancel a long-running async command
            doneSpy.clear();
            backend.runCommandAsync(QStringLiteral("sleep 10"));
            QVERIFY(backend.commandRunning());
            backend.cancelCommand();
            QCOMPARE(backend.commandRunning(), false);
            QCOMPARE(doneSpy.count(), 1);
            QCOMPARE(doneSpy.first().at(0).toBool(), false);
            QVERIFY(backend.commandOutput().contains(QStringLiteral("[Cancelled]")));

            QVERIFY(backend.commandHistory().contains(QStringLiteral("cd \"sub folder\"")));
            QVERIFY(backend.commandHistory().contains(QStringLiteral("printf 'line1\\nline2\\n'")));
            backend.saveSession();
        }

        // Verify command history persists across restarts
        {
            Backend fresh(cfg.filePath("bookmarks.json"));
            QVERIFY(fresh.commandHistory().contains(QStringLiteral("cd \"sub folder\"")));
            QVERIFY(fresh.commandHistory().contains(QStringLiteral("printf 'line1\\nline2\\n'")));
        }
    }

    void fileSplitAndCombineWithSha256Verification()
    {
        QTemporaryDir root;
        QTemporaryDir cfg;
        const QString srcDir = root.filePath("src");
        const QString partsDir = root.filePath("parts");
        const QString outDir = root.filePath("out");
        QVERIFY(QDir().mkpath(srcDir));
        QVERIFY(QDir().mkpath(partsDir));
        QVERIFY(QDir().mkpath(outDir));

        // Create deterministic 2500-byte binary payload
        QByteArray payload;
        payload.reserve(2500);
        for (int i = 0; i < 2500; ++i)
            payload.append(static_cast<char>((i * 31 + 7) & 0xFF));
        const QString srcFile = QDir(srcDir).filePath("archive.bin");
        writeFile(srcFile, payload);

        Backend backend(cfg.filePath("bookmarks.json"));

        // 1. Inspect regular file -> split mode
        const QVariantMap splitInspect = backend.inspectSplitSource(srcFile);
        QCOMPARE(splitInspect.value("valid").toBool(), true);
        QCOMPARE(splitInspect.value("mode").toString(), QStringLiteral("split"));
        QCOMPARE(splitInspect.value("totalBytes").toLongLong(), 2500LL);

        // 2. Split into 1000-byte parts -> 3 parts (.001, .002, .003) + .crc
        const QVariantMap splitRes = backend.splitFile(srcFile, partsDir, 1000, true);
        QCOMPARE(splitRes.value("success").toBool(), true);
        QCOMPARE(splitRes.value("partCount").toInt(), 3);
        const QString part1 = QDir(partsDir).filePath("archive.bin.001");
        const QString part2 = QDir(partsDir).filePath("archive.bin.002");
        const QString part3 = QDir(partsDir).filePath("archive.bin.003");
        const QString crcFile = QDir(partsDir).filePath("archive.bin.crc");
        QCOMPARE(QFileInfo(part1).size(), 1000LL);
        QCOMPARE(QFileInfo(part2).size(), 1000LL);
        QCOMPARE(QFileInfo(part3).size(), 500LL);
        QVERIFY(QFileInfo::exists(crcFile));

        // 3. Inspect .001 / .crc -> combine mode with hasCrc = true
        const QVariantMap combInspect = backend.inspectSplitSource(part1);
        QCOMPARE(combInspect.value("valid").toBool(), true);
        QCOMPARE(combInspect.value("mode").toString(), QStringLiteral("combine"));
        QCOMPARE(combInspect.value("partCount").toInt(), 3);
        QCOMPARE(combInspect.value("hasCrc").toBool(), true);

        // 4. Async combine + SHA-256 verification
        QSignalSpy splitSpy(&backend, &Backend::splitOperationFinished);
        backend.startCombineFiles(crcFile, outDir);
        QTRY_COMPARE_WITH_TIMEOUT(splitSpy.count(), 1, 3000);
        const QVariantMap combRes = splitSpy.first().at(0).toMap();
        QCOMPARE(combRes.value("success").toBool(), true);
        QCOMPARE(combRes.value("verified").toBool(), true);
        const QString combinedPath = QDir(outDir).filePath("archive.bin");
        QFile fOut(combinedPath);
        QVERIFY(fOut.open(QIODevice::ReadOnly));
        QCOMPARE(fOut.readAll(), payload);
        fOut.close();

        // 5. Corrupt 1 byte in .002 -> combine must flag SHA-256 mismatch!
        QFile fCorrupt(part2);
        QVERIFY(fCorrupt.open(QIODevice::ReadWrite));
        char ch = 0;
        QCOMPARE(fCorrupt.read(&ch, 1), 1LL);
        fCorrupt.seek(0);
        ch ^= 0xFF;
        QCOMPARE(fCorrupt.write(&ch, 1), 1LL);
        fCorrupt.close();

        const QVariantMap badRes = backend.combineFiles(part1, outDir);
        QCOMPARE(badRes.value("hasCrc").toBool(), true);
        QCOMPARE(badRes.value("verified").toBool(), false);
        QCOMPARE(badRes.value("success").toBool(), false);
    }
};

QTEST_MAIN(OmapanelTests)
#include "omapanel_tests.moc"
