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
        // Should have .. (if not /), subfolder, alpha.txt
        QVERIFY(model.rowCount() >= 2);

        int idx = model.findIndexByPrefix("alpha");
        QVERIFY(idx >= 0);
        QCOMPARE(model.itemName(idx), QString("alpha.txt"));
        QCOMPARE(model.itemIsDir(idx), false);
    }

    void panelModelSelection()
    {
        QTemporaryDir dir;
        QFile f1(dir.filePath("a.txt"));
        QVERIFY(f1.open(QIODevice::WriteOnly));
        f1.write("123");
        f1.close();

        QFile f2(dir.filePath("b.txt"));
        QVERIFY(f2.open(QIODevice::WriteOnly));
        f2.write("456");
        f2.close();

        PanelModel model(dir.path());
        QCOMPARE(model.selectedCount(), 0);

        model.selectAll();
        QCOMPARE(model.selectedCount(), 2);

        model.deselectAll();
        QCOMPARE(model.selectedCount(), 0);
    }

    void panelModelSorting()
    {
        QTemporaryDir dir;
        // Create files with different names, extensions, and sizes
        QFile f1(dir.filePath("zebra.txt"));
        QVERIFY(f1.open(QIODevice::WriteOnly));
        f1.write(QByteArray(100, 'x')); // 100 bytes
        f1.close();

        QFile f2(dir.filePath("apple.bin"));
        QVERIFY(f2.open(QIODevice::WriteOnly));
        f2.write(QByteArray(500, 'y')); // 500 bytes
        f2.close();

        QFile f3(dir.filePath("middle.doc"));
        QVERIFY(f3.open(QIODevice::WriteOnly));
        f3.write(QByteArray(200, 'z')); // 200 bytes
        f3.close();

        PanelModel model(dir.path());

        // Sort by Name Ascending: apple.bin, middle.doc, zebra.txt
        model.setSortField(PanelModel::SortByName);
        model.setSortAscending(true);
        // Index 0 might be ".." if not root, check last 3
        int count = model.itemCount();
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));

        // Sort by Size Ascending: zebra.txt (100B), middle.doc (200B), apple.bin (500B)
        model.setSortField(PanelModel::SortBySize);
        model.setSortAscending(true);
        QCOMPARE(model.itemName(count - 3), QString("zebra.txt"));
        QCOMPARE(model.itemName(count - 1), QString("apple.bin"));

        // Sort by Size Descending (toggle)
        model.setSortField(PanelModel::SortBySize); // calling with same field toggles direction
        QCOMPARE(model.sortAscending(), false);
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));

        // Sort by Ext Ascending: .bin (apple), .doc (middle), .txt (zebra)
        model.setSortField(PanelModel::SortByExt);
        model.setSortAscending(true);
        QCOMPARE(model.itemName(count - 3), QString("apple.bin"));
        QCOMPARE(model.itemName(count - 2), QString("middle.doc"));
        QCOMPARE(model.itemName(count - 1), QString("zebra.txt"));
    }

    void backendOperations()
    {
        QTemporaryDir srcDir;
        QTemporaryDir dstDir;

        QFile f(srcDir.filePath("sample.txt"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("Some sample content");
        f.close();

        Backend backend;
        backend.leftPanel()->setPath(srcDir.path());
        backend.rightPanel()->setPath(dstDir.path());

        // Copy item from left to right
        bool copied = backend.copyItems({srcDir.filePath("sample.txt")}, dstDir.path());
        QVERIFY(copied);
        QVERIFY(QFile::exists(dstDir.filePath("sample.txt")));

        // Test preview
        QVariantMap preview = backend.getPreview(dstDir.filePath("sample.txt"));
        QCOMPARE(preview["isText"].toBool(), true);
        QCOMPARE(preview["name"].toString(), QString("sample.txt"));
        QVERIFY(preview["text"].toString().contains("Some sample content"));

        // Test search
        QStringList results = backend.searchFiles(dstDir.path(), "sample");
        QCOMPARE(results.size(), 1);

        // Test delete
        bool deleted = backend.deleteItems({dstDir.filePath("sample.txt")}, true);
        QVERIFY(deleted);
        QVERIFY(!QFile::exists(dstDir.filePath("sample.txt")));
    }
};

QTEST_MAIN(OmapanelTests)
#include "omapanel_tests.moc"
