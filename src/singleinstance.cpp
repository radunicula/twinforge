#include "singleinstance.h"

#include <QLocalSocket>

#include <unistd.h>

SingleInstance::SingleInstance(const QString &socketName, QObject *parent)
    : QObject(parent)
    , m_socketName(socketName.trimmed().isEmpty() ? defaultSocketName() : socketName.trimmed())
{
    connect(&m_server, &QLocalServer::newConnection, this, &SingleInstance::handleNewConnection);
}

SingleInstance::~SingleInstance()
{
    if (m_server.isListening())
        m_server.close();
}

QString SingleInstance::defaultSocketName()
{
    const QByteArray overrideName = qgetenv("TWINFORGE_IPC_SOCKET");
    if (!overrideName.isEmpty())
        return QString::fromUtf8(overrideName);
    return QStringLiteral("twinforge-ipc-%1").arg(static_cast<qulonglong>(::getuid()));
}

bool SingleInstance::sendToRunningInstance(const CliRequest &request, int timeoutMs) const
{
    QLocalSocket socket;
    socket.connectToServer(m_socketName, QIODevice::ReadWrite);
    if (!socket.waitForConnected(timeoutMs))
        return false;

    const QByteArray data = serializeCliRequest(request);
    if (socket.write(data) != data.size())
        return false;
    if (!socket.waitForBytesWritten(timeoutMs))
        return false;

    // Wait briefly for "OK\n" ack so the primary instance has received the request.
    if (socket.waitForReadyRead(timeoutMs)) {
        const QByteArray ack = socket.readAll();
        if (ack.contains("OK")) {
            socket.disconnectFromServer();
            return true;
        }
    }
    socket.disconnectFromServer();
    return true;
}

bool SingleInstance::startListening()
{
    if (m_server.isListening())
        return true;

    m_server.setSocketOptions(QLocalServer::UserAccessOption);
    if (m_server.listen(m_socketName))
        return true;

    // Only clean up a stale socket if nobody is actively listening on it.
    QLocalSocket probe;
    probe.connectToServer(m_socketName);
    if (probe.waitForConnected(100)) {
        probe.disconnectFromServer();
        return false;
    }

    QLocalServer::removeServer(m_socketName);
    return m_server.listen(m_socketName);
}

void SingleInstance::handleNewConnection()
{
    while (QLocalSocket *client = m_server.nextPendingConnection()) {
        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            if (!client->canReadLine())
                return;
            const QByteArray line = client->readLine();
            bool ok = false;
            const CliRequest req = deserializeCliRequest(line, &ok);
            client->write(ok ? "OK\n" : "ERR\n");
            client->flush();
            client->disconnectFromServer();
            if (ok)
                emit requestReceived(req);
        });
        connect(client, &QLocalSocket::disconnected, client, &QObject::deleteLater);

        // Handle data that arrived before the signal connection was made.
        if (client->canReadLine()) {
            const QByteArray line = client->readLine();
            bool ok = false;
            const CliRequest req = deserializeCliRequest(line, &ok);
            client->write(ok ? "OK\n" : "ERR\n");
            client->flush();
            client->disconnectFromServer();
            if (ok)
                emit requestReceived(req);
        }
    }
}
