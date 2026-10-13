#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

class AppBackend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString engineName READ engineName CONSTANT)
    Q_PROPERTY(QString coreVersion READ coreVersion CONSTANT)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(bool mediaPanelVisible READ mediaPanelVisible WRITE setMediaPanelVisible NOTIFY mediaPanelVisibleChanged)
    Q_PROPERTY(bool inspectorVisible READ inspectorVisible WRITE setInspectorVisible NOTIFY inspectorVisibleChanged)
    Q_PROPERTY(bool timelineVisible READ timelineVisible WRITE setTimelineVisible NOTIFY timelineVisibleChanged)
    Q_PROPERTY(QString activeSection READ activeSection WRITE setActiveSection NOTIFY activeSectionChanged)

public:
    explicit AppBackend(QObject* parent = nullptr);

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

signals:
    void darkModeChanged();
    void mediaPanelVisibleChanged();
    void inspectorVisibleChanged();
    void timelineVisibleChanged();
    void activeSectionChanged();

private:
    QSettings settings_;
    bool darkMode_ = true;
    bool mediaPanelVisible_ = true;
    bool inspectorVisible_ = true;
    bool timelineVisible_ = true;
    QString activeSection_ = QStringLiteral("media");
};
