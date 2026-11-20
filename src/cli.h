#pragma once

#include <QByteArray>
#include <QString>
#include <QStringList>

struct CliRequest {
    QString leftPath;
    QString rightPath;
    QString selectPath;
    QString lastDirFile;
    QString shellInit;
    bool newTab = false;
    bool newWindow = false;
    bool printLastDir = false;
    bool smokeTest = false;
    bool activate = true;

    bool hasNavigation() const
    {
        return !leftPath.isEmpty() || !rightPath.isEmpty() || !selectPath.isEmpty();
    }

    bool shouldUseSingleInstance() const
    {
        return !newWindow && !smokeTest && lastDirFile.isEmpty() && !printLastDir && shellInit.isEmpty();
    }
};

QString resolveCliPath(const QString &rawArg, const QString &workingDir);

CliRequest parseCliArguments(const QStringList &arguments,
                             const QString &workingDir,
                             const QString &appVersion = QStringLiteral("0.1.0"),
                             QString *errorOut = nullptr,
                             bool *shouldExitOk = nullptr,
                             QString *stdoutOut = nullptr);

QString generateShellInitScript(const QString &shellName, QString *errorOut = nullptr);
QByteArray serializeCliRequest(const CliRequest &req);
CliRequest deserializeCliRequest(const QByteArray &payload, bool *ok = nullptr);
bool writeLastDirFile(const QString &filePath, const QString &dirPath);
