#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QSet>
#include <QStorageInfo>

struct PanelItem {
    QString name;
    QString path;
    bool isDir = false;
    bool isParent = false;
    qint64 size = 0;
    QString formattedSize;
    QDateTime modified;
    QString formattedModified;
    QString extension;
    QString permissions;
    QString iconType;
    bool isSelected = false;
};

class PanelModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(int sortField READ sortField WRITE setSortField NOTIFY sortChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortChanged)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY countChanged)
    Q_PROPERTY(int selectedCount READ selectedCount NOTIFY selectionChanged)
    Q_PROPERTY(QString totalSelectedSizeFormatted READ totalSelectedSizeFormatted NOTIFY selectionChanged)
    Q_PROPERTY(QString freeSpaceFormatted READ freeSpaceFormatted NOTIFY freeSpaceChanged)

public:
    enum SortField {
        SortByName = 0,
        SortByExt = 1,
        SortBySize = 2,
        SortByDate = 3
    };
    Q_ENUM(SortField)

    enum PanelRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsDirRole,
        IsParentRole,
        SizeRole,
        FormattedSizeRole,
        ModifiedRole,
        ExtensionRole,
        PermissionsRole,
        IconTypeRole,
        IsSelectedRole
    };

    explicit PanelModel(const QString &initialPath = QString(), QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString path() const { return m_path; }
    Q_INVOKABLE void setPath(const QString &newPath);

    QString filter() const { return m_filter; }
    Q_INVOKABLE void setFilter(const QString &filter);

    bool showHidden() const { return m_showHidden; }
    Q_INVOKABLE void setShowHidden(bool show);

    int sortField() const { return m_sortField; }
    Q_INVOKABLE void setSortField(int field);

    bool sortAscending() const { return m_sortAscending; }
    Q_INVOKABLE void setSortAscending(bool asc);

    int itemCount() const { return m_items.size(); }
    int selectedCount() const;
    QString totalSelectedSizeFormatted() const;
    QString freeSpaceFormatted() const;

    Q_INVOKABLE void cd(const QString &nameOrPath);
    Q_INVOKABLE void cdUp();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggleSelection(int index);
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void deselectAll();
    Q_INVOKABLE void invertSelection();
    Q_INVOKABLE QString itemPath(int index) const;
    Q_INVOKABLE bool itemIsDir(int index) const;
    Q_INVOKABLE QString itemName(int index) const;
    Q_INVOKABLE QStringList selectedPaths() const;
    Q_INVOKABLE int findIndexByPrefix(const QString &prefix, int startIndex = 0) const;

signals:
    void pathChanged();
    void filterChanged();
    void showHiddenChanged();
    void sortChanged();
    void countChanged();
    void selectionChanged();
    void freeSpaceChanged();

private:
    void loadDirectory();
    void sortItems();
    static QString formatSize(qint64 bytes, bool isDir);
    static QString detectIconType(const QFileInfo &info);

    QString m_path;
    QString m_filter;
    bool m_showHidden = false;
    int m_sortField = SortByName;
    bool m_sortAscending = true;

    QList<PanelItem> m_allItems;
    QList<PanelItem> m_items;
    QSet<QString> m_selectedPaths;
    QFileSystemWatcher m_dirWatcher;
};
