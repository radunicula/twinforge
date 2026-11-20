// twinforge — modern dual-panel file manager for Linux.

#include <QDir>
#include <QEventLoop>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QTextStream>
#include <QTimer>
#include <QUrl>

#include "backend.h"
#include "cli.h"
#include "panelmodel.h"
#include "singleinstance.h"
#include "theme.h"
#include "thumbnailprovider.h"
#include "translator.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("twinforge");
    app.setApplicationVersion("0.1.0");

    QString cliError;
    QString cliStdout;
    bool cliExitOk = false;
    const CliRequest cliReq = parseCliArguments(
        app.arguments(), QDir::currentPath(), app.applicationVersion(),
        &cliError, &cliExitOk, &cliStdout);

    if (!cliError.isEmpty()) {
        QTextStream err(stderr);
        err << cliError << Qt::endl;
        return 1;
    }
    if (cliExitOk) {
        if (!cliStdout.isEmpty()) {
            QTextStream out(stdout);
            out << cliStdout;
        }
        return 0;
    }

    SingleInstance singleInstance;
    if (cliReq.shouldUseSingleInstance()) {
        if (singleInstance.sendToRunningInstance(cliReq))
            return 0;
        singleInstance.startListening();
    }

    app.setDesktopFileName("twinforge");
    QIcon appIcon(":/logo.png");
    if (appIcon.isNull())
        appIcon = QIcon::fromTheme("twinforge");
    app.setWindowIcon(appIcon);

    QQuickStyle::setStyle("Material");

    Translator translator;
    app.installTranslator(&translator);

    Theme theme;
    Backend backend;
    translator.setLanguageOverride(backend.languageMode());
    QObject::connect(&backend, &Backend::settingsChanged, &translator, [&translator, &backend]() {
        translator.setLanguageOverride(backend.languageMode());
    });

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("thumb"), new ThumbnailProvider());
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty("translator", &translator);
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);

    QList<QQmlError> qmlWarnings;
    if (cliReq.smokeTest) {
        QObject::connect(&engine, &QQmlApplicationEngine::warnings, &engine,
                         [&qmlWarnings](const QList<QQmlError> &warnings) {
                             qmlWarnings.append(warnings);
                         });
    }

    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    if (cliReq.smokeTest) {
        QCoreApplication::processEvents();
        QTextStream out(stdout);
        QTextStream err(stderr);
        if (!qmlWarnings.isEmpty()) {
            err << QStringLiteral("SMOKE_TEST_FAIL: QML warnings detected:\n");
            for (const QQmlError &w : std::as_const(qmlWarnings))
                err << w.toString() << '\n';
            return 1;
        }
        if (cliReq.leftPath.isEmpty() || cliReq.rightPath.isEmpty()) {
            err << QStringLiteral("SMOKE_TEST_FAIL: --smoke-test requires <archive_path> <dest_dir>\n");
            return 1;
        }
        PanelModel *left = backend.leftPanel();
        PanelModel *right = backend.rightPanel();
        left->setPath(cliReq.leftPath);
        right->setPath(cliReq.rightPath);
        if (!left->isArchiveView()) {
            err << QStringLiteral("SMOKE_TEST_FAIL: failed to open archive view for %1\n").arg(cliReq.leftPath);
            return 1;
        }
        QString entryPath;
        QString entryName;
        for (int i = 0; i < left->itemCount(); ++i) {
            const QString name = left->itemName(i);
            if (name == QLatin1String("..") || left->itemIsDir(i))
                continue;
            entryName = name;
            entryPath = left->itemPath(i);
            break;
        }
        if (entryPath.isEmpty()) {
            err << QStringLiteral("SMOKE_TEST_FAIL: no file entries found in archive %1\n").arg(cliReq.leftPath);
            return 1;
        }
        if (!backend.copyItems({entryPath}, cliReq.rightPath)) {
            err << QStringLiteral("SMOKE_TEST_FAIL: copyItems returned false for %1\n").arg(entryPath);
            return 1;
        }
        if (backend.isBusy()) {
            QEventLoop waitLoop;
            QTimer timeoutTimer;
            timeoutTimer.setSingleShot(true);
            QObject::connect(&timeoutTimer, &QTimer::timeout, &waitLoop, &QEventLoop::quit);
            QObject::connect(&backend, &Backend::busyChanged, &waitLoop, [&backend, &waitLoop]() {
                if (!backend.isBusy())
                    waitLoop.quit();
            });
            timeoutTimer.start(10000);
            if (backend.isBusy())
                waitLoop.exec();
        }
        const QFileInfo extracted(QDir(cliReq.rightPath).filePath(entryName));
        if (!extracted.exists() || !extracted.isFile() || extracted.size() <= 0) {
            err << QStringLiteral("SMOKE_TEST_FAIL: extracted file missing or empty at %1\n")
                       .arg(extracted.absoluteFilePath());
            return 1;
        }
        out << QStringLiteral("SMOKE_TEST_OK: archive=%1 entry=%2 bytes=%3 dest=%4\n")
                   .arg(cliReq.leftPath, entryName)
                   .arg(extracted.size())
                   .arg(cliReq.rightPath);
        return 0;
    }

    if (cliReq.hasNavigation()) {
        backend.applyNavigationRequest(cliReq.leftPath, cliReq.rightPath, cliReq.selectPath, cliReq.newTab);
    }

    QObject::connect(&singleInstance, &SingleInstance::requestReceived, &backend,
                     [&backend](const CliRequest &req) {
                         backend.applyNavigationRequest(req.leftPath, req.rightPath, req.selectPath, req.newTab);
                     });

    const int exitCode = app.exec();

    const QString finalDir = backend.activeFilesystemPath();
    if (!cliReq.lastDirFile.isEmpty()) {
        writeLastDirFile(cliReq.lastDirFile, finalDir);
    }
    if (cliReq.printLastDir && !finalDir.isEmpty()) {
        QTextStream out(stdout);
        out << finalDir << Qt::endl;
    }

    return exitCode;
}
