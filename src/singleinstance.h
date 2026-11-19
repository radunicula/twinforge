#pragma once

#include <QLocalServer>
#include <QObject>
#include <QString>

#include "cli.h"

class SingleInstance : public QObject {
    Q_OBJECT

public:
    explicit SingleInstance(const QString &socketName = {}, QObject *parent = nullptr);
    ~SingleInstance() override;

    static QString defaultSocketName();
    QString socketName() const { return m_socketName; }

    // Tries to connect to a running instance and forward the CLI request.
    // Returns true if another instance accepted and acknowledged the request.
    bool sendToRunningInstance(const CliRequest &request, int timeoutMs = 400) const;

    // Starts listening as the primary instance on m_socketName.
    bool startListening();
    bool isListening() const { return m_server.isListening(); }

signals:
    void requestReceived(const CliRequest &request);

private:
    void handleNewConnection();

    QString m_socketName;
    QLocalServer m_server;
};
