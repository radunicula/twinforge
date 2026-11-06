#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "panelmodel.h"
#include "theme.h"
#include "translator.h"

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

        // Copy item from left to right
        bool copied = backend.copyItems({srcDir.filePath("sample.txt")}, dstDir.path());
        QVERIFY(copied);
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
};

QTEST_MAIN(OmapanelTests)
#include "omapanel_tests.moc"
