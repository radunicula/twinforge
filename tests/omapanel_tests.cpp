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
