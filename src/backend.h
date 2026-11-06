#pragma once

#include <QFutureWatcher>
#include <QJsonObject>
#include <QObject>
#include <QStringList>
#include <QVariantMap>

#include "panelmodel.h"

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(PanelModel* leftPanel READ leftPanel CONSTANT)
    Q_PROPERTY(PanelModel* rightPanel READ rightPanel CONSTANT)
    Q_PROPERTY(int activePanel READ activePanel WRITE setActivePanel NOTIFY activePanelChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QString busyTitle READ busyTitle NOTIFY busyChanged)
    Q_PROPERTY(double busyProgress READ busyProgress NOTIFY busyChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;

    PanelModel* leftPanel() { return &m_leftPanel; }
    PanelModel* rightPanel() { return &m_rightPanel; }

    int activePanel() const { return m_activePanel; }
    void setActivePanel(int index);

    bool isBusy() const { return m_isBusy; }
    QString busyTitle() const { return m_busyTitle; }
    double busyProgress() const { return m_busyProgress; }
    QString statusMessage() const { return m_statusMessage; }

    PanelModel* activeModel();
    PanelModel* targetModel();

    Q_INVOKABLE void switchPanel();
    Q_INVOKABLE void openItem(const QString &path);
    Q_INVOKABLE void openWithEditor(const QString &path);
    Q_INVOKABLE void openInTerminal(const QString &path);

    Q_INVOKABLE bool copyItems(const QStringList &sourcePaths, const QString &targetDir);
    Q_INVOKABLE bool moveItems(const QStringList &sourcePaths, const QString &targetDir);
    Q_INVOKABLE bool deleteItems(const QStringList &paths, bool permanent = false);
    Q_INVOKABLE bool createDirectory(const QString &name);
    Q_INVOKABLE bool renameItem(const QString &oldPath, const QString &newName);

    Q_INVOKABLE QVariantMap getPreview(const QString &path);
    Q_INVOKABLE QStringList searchFiles(const QString &rootPath, const QString &query, int maxResults = 200);

    Q_INVOKABLE void showStatus(const QString &message);

signals:
    void activePanelChanged();
    void busyChanged();
    void statusMessageChanged();
    void operationFinished(bool success, const QString &message);

private:
    static bool copyRecursively(const QString &srcFilePath, const QString &tgtFilePath);

    PanelModel m_leftPanel;
    PanelModel m_rightPanel;
    int m_activePanel = 0; // 0 = left, 1 = right

    bool m_isBusy = false;
    QString m_busyTitle;
    double m_busyProgress = 0.0;
    QString m_statusMessage;
};
