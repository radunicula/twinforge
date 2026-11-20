// twinforge — modern dual-panel file manager for Linux.

#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTextStream>
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

    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

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
