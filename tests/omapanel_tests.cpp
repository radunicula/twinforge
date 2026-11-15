#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMimeData>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QUrl>
#include <QtTest>

#include <sys/stat.h>

#include "backend.h"
#include "fileoperation.h"
#include "panelmodel.h"
#include "theme.h"
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

        // Pressing Space (toggleSelection) on folder calculates its size and selects it
        model.toggleSelection(folderIdx);
        QCOMPARE(model.selectedCount(), 1);
        QCOMPARE(model.data(model.index(folderIdx, 0), PanelModel::SizeRole).toLongLong(), 2048LL);
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
        QVERIFY(!backend.copyItems({src.filePath("2.txt")}, dst.path())); // one operation at a time
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
        writeFile(testFile, "Hello Total Commander omapanel checksum!");
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
        QVERIFY(model.isGitRepo());
        QVERIFY(!model.gitBranch().isEmpty());
        QVERIFY(model.gitModifiedCount() >= 1 || model.gitUntrackedCount() >= 1);
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
    }
};

QTEST_MAIN(OmapanelTests)
#include "omapanel_tests.moc"
