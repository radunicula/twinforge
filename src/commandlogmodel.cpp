#include "commandlogmodel.h"

#include <QDateTime>
#include <QStringList>

namespace {
constexpr int kMaxCommandEntries = 200;
constexpr int kMaxEntryOutputChars = 128 * 1024;
} // namespace

CommandLogModel::CommandLogModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int CommandLogModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant CommandLogModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const CommandLogEntry &e = m_entries.at(index.row());
    switch (role) {
    case IdRole: return e.id;
    case CommandRole: return e.command;
    case CwdRole: return e.cwd;
    case OutputRole: return e.output;
    case ExitCodeRole: return e.exitCode;
    case RunningRole: return e.running;
    case CancelledRole: return e.cancelled;
    case TimestampRole: return e.timestamp;
    case FormattedBlockRole: return formatEntry(e);
    default: return {};
    }
}

QHash<int, QByteArray> CommandLogModel::roleNames() const
{
    return {
        {IdRole, "entryId"},
        {CommandRole, "command"},
        {CwdRole, "cwd"},
        {OutputRole, "output"},
        {ExitCodeRole, "exitCode"},
        {RunningRole, "running"},
        {CancelledRole, "cancelled"},
        {TimestampRole, "timestamp"},
        {FormattedBlockRole, "formattedBlock"}
    };
}

int CommandLogModel::indexOfId(int id) const
{
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        if (m_entries.at(i).id == id)
            return i;
    }
    return -1;
}

QString CommandLogModel::formatEntry(const CommandLogEntry &e)
{
    QString text = QStringLiteral("%1 ❯ %2").arg(e.cwd, e.command);
    const QString outTrimmed = e.output.trimmed();
    if (!outTrimmed.isEmpty())
        text += QLatin1Char('\n') + outTrimmed;
    if (e.running)
        text += QStringLiteral("\n[running]");
    else if (e.cancelled)
        text += QStringLiteral("\n[cancelled (exit %1)]").arg(e.exitCode);
    else
        text += QStringLiteral("\n[exit %1]").arg(e.exitCode);
    return text;
}

int CommandLogModel::beginEntry(const QString &cwd, const QString &command)
{
    while (m_entries.size() >= kMaxCommandEntries) {
        beginRemoveRows(QModelIndex(), 0, 0);
        m_entries.removeFirst();
        endRemoveRows();
    }

    CommandLogEntry entry;
    entry.id = ++m_nextId;
    entry.cwd = cwd;
    entry.command = command;
    entry.running = true;
    entry.timestamp = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));

    const int row = m_entries.size();
    beginInsertRows(QModelIndex(), row, row);
    m_entries.append(entry);
    endInsertRows();
    emit countChanged();
    return entry.id;
}

void CommandLogModel::appendOutput(int id, const QString &chunk)
{
    if (chunk.isEmpty())
        return;
    const int row = indexOfId(id);
    if (row < 0)
        return;

    CommandLogEntry &e = m_entries[row];
    e.output.append(chunk);
    if (e.output.size() > kMaxEntryOutputChars)
        e.output = e.output.right(kMaxEntryOutputChars);

    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {OutputRole, FormattedBlockRole});
}

void CommandLogModel::finishEntry(int id, int exitCode, bool cancelled)
{
    const int row = indexOfId(id);
    if (row < 0)
        return;

    CommandLogEntry &e = m_entries[row];
    e.exitCode = exitCode;
    e.running = false;
    e.cancelled = cancelled;

    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {ExitCodeRole, RunningRole, CancelledRole, FormattedBlockRole});
}

QString CommandLogModel::formatEntryForCopy(int index) const
{
    if (index < 0 || index >= m_entries.size())
        return {};
    return formatEntry(m_entries.at(index));
}

QString CommandLogModel::formatAllForCopy() const
{
    QStringList blocks;
    blocks.reserve(m_entries.size());
    for (const CommandLogEntry &e : std::as_const(m_entries))
        blocks.append(formatEntry(e));
    return blocks.join(QStringLiteral("\n\n"));
}

void CommandLogModel::clear()
{
    if (m_entries.isEmpty())
        return;
    beginResetModel();
    m_entries.clear();
    endResetModel();
    emit countChanged();
}
