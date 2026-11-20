#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QString>

struct CommandLogEntry {
    int id = 0;
    QString command;
    QString cwd;
    QString output;
    int exitCode = 0;
    bool running = false;
    bool cancelled = false;
    QString timestamp;
};

class CommandLogModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        CommandRole,
        CwdRole,
        OutputRole,
        ExitCodeRole,
        RunningRole,
        CancelledRole,
        TimestampRole,
        FormattedBlockRole
    };

    explicit CommandLogModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_entries.size(); }

    int beginEntry(const QString &cwd, const QString &command);
    void appendOutput(int id, const QString &chunk);
    void finishEntry(int id, int exitCode, bool cancelled = false);

    Q_INVOKABLE QString formatEntryForCopy(int index) const;
    Q_INVOKABLE QString formatAllForCopy() const;
    Q_INVOKABLE void clear();

signals:
    void countChanged();

private:
    int indexOfId(int id) const;
    static QString formatEntry(const CommandLogEntry &e);

    QList<CommandLogEntry> m_entries;
    int m_nextId = 0;
};
