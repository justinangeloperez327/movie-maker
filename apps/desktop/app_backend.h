#pragma once

#include <memory>
#include <QList>
#include <QVariantList>
#include <QObject>
#include <QSettings>
#include <QString>
#include <QUrl>

class ProjectSessionHolder;

class AppBackend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString engineName READ engineName CONSTANT)
    Q_PROPERTY(QString coreVersion READ coreVersion CONSTANT)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(bool mediaPanelVisible READ mediaPanelVisible WRITE setMediaPanelVisible NOTIFY mediaPanelVisibleChanged)
    Q_PROPERTY(bool inspectorVisible READ inspectorVisible WRITE setInspectorVisible NOTIFY inspectorVisibleChanged)
    Q_PROPERTY(bool timelineVisible READ timelineVisible WRITE setTimelineVisible NOTIFY timelineVisibleChanged)
    Q_PROPERTY(QString activeSection READ activeSection WRITE setActiveSection NOTIFY activeSectionChanged)
    Q_PROPERTY(bool hasProject READ hasProject NOTIFY projectChanged)
    Q_PROPERTY(QString projectName READ projectName NOTIFY projectChanged)
    Q_PROPERTY(QString projectPath READ projectPath NOTIFY projectChanged)
    Q_PROPERTY(bool isModified READ isModified NOTIFY projectChanged)
    Q_PROPERTY(int mediaCount READ mediaCount NOTIFY projectChanged)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY projectChanged)
    Q_PROPERTY(QVariantList mediaItems READ mediaItems NOTIFY projectChanged)
    Q_PROPERTY(bool importing READ importing NOTIFY importStateChanged)
    Q_PROPERTY(int pendingImports READ pendingImports NOTIFY importStateChanged)

public:
    explicit AppBackend(QObject* parent = nullptr);
    ~AppBackend() override;

    QString engineName() const;
    QString coreVersion() const;

    bool darkMode() const;
    void setDarkMode(bool value);
    bool mediaPanelVisible() const;
    void setMediaPanelVisible(bool value);
    bool inspectorVisible() const;
    void setInspectorVisible(bool value);
    bool timelineVisible() const;
    void setTimelineVisible(bool value);
    QString activeSection() const;
    void setActiveSection(const QString& section);
    Q_INVOKABLE void restoreDefaultWorkspace();

    bool hasProject() const;
    QString projectName() const;
    QString projectPath() const;
    bool isModified() const;
    int mediaCount() const;
    int trackCount() const;
    QVariantList mediaItems() const;
    bool importing() const;
    int pendingImports() const;

    Q_INVOKABLE bool createProject(const QString& name);
    Q_INVOKABLE bool openProject(const QUrl& url);
    Q_INVOKABLE bool saveProject();
    Q_INVOKABLE bool saveProjectAs(const QUrl& url);
    Q_INVOKABLE bool importMedia(const QList<QUrl>& urls);

signals:
    void darkModeChanged();
    void mediaPanelVisibleChanged();
    void inspectorVisibleChanged();
    void timelineVisibleChanged();
    void activeSectionChanged();
    void projectChanged();
    void importStateChanged();
    void operationFailed(const QString& detail);

private:
    QSettings settings_;
    bool darkMode_ = true;
    bool mediaPanelVisible_ = true;
    bool inspectorVisible_ = true;
    bool timelineVisible_ = true;
    QString activeSection_ = QStringLiteral("media");

    std::unique_ptr<ProjectSessionHolder> project_;
    QString projectPath_;
    bool modified_ = false;
    int pendingImports_ = 0;
    quint64 projectGeneration_ = 0;
};
