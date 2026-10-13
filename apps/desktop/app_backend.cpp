#include "app_backend.h"

#include "bridge.h"

#include <QtGlobal>

namespace {
QString fromRustString(const rust::String& value) {
    return QString::fromUtf8(value.data(), static_cast<qsizetype>(value.size()));
}

bool validSection(const QString& section) {
    return section == QStringLiteral("media")
        || section == QStringLiteral("effects")
        || section == QStringLiteral("transitions")
        || section == QStringLiteral("titles");
}
} // namespace

AppBackend::AppBackend(QObject* parent)
    : QObject(parent) {
    darkMode_ = settings_.value(QStringLiteral("workspace/darkMode"), true).toBool();
    mediaPanelVisible_ = settings_.value(QStringLiteral("workspace/mediaVisible"), true).toBool();
    inspectorVisible_ = settings_.value(QStringLiteral("workspace/inspectorVisible"), true).toBool();
    timelineVisible_ = settings_.value(QStringLiteral("workspace/timelineVisible"), true).toBool();

    const QString section = settings_.value(QStringLiteral("workspace/activeSection"), QStringLiteral("media")).toString();
    activeSection_ = validSection(section) ? section : QStringLiteral("media");
}

QString AppBackend::engineName() const {
    return fromRustString(movie_maker::application_name());
}

QString AppBackend::coreVersion() const {
    return fromRustString(movie_maker::core_version());
}

bool AppBackend::darkMode() const {
    return darkMode_;
}

void AppBackend::setDarkMode(bool value) {
    if (darkMode_ == value) return;
    darkMode_ = value;
    settings_.setValue(QStringLiteral("workspace/darkMode"), value);
    emit darkModeChanged();
}

bool AppBackend::mediaPanelVisible() const {
    return mediaPanelVisible_;
}

void AppBackend::setMediaPanelVisible(bool value) {
    if (mediaPanelVisible_ == value) return;
    mediaPanelVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/mediaVisible"), value);
    emit mediaPanelVisibleChanged();
}

bool AppBackend::inspectorVisible() const {
    return inspectorVisible_;
}

void AppBackend::setInspectorVisible(bool value) {
    if (inspectorVisible_ == value) return;
    inspectorVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/inspectorVisible"), value);
    emit inspectorVisibleChanged();
}

bool AppBackend::timelineVisible() const {
    return timelineVisible_;
}

void AppBackend::setTimelineVisible(bool value) {
    if (timelineVisible_ == value) return;
    timelineVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/timelineVisible"), value);
    emit timelineVisibleChanged();
}

QString AppBackend::activeSection() const {
    return activeSection_;
}

void AppBackend::setActiveSection(const QString& section) {
    if (!validSection(section) || activeSection_ == section) return;
    activeSection_ = section;
    settings_.setValue(QStringLiteral("workspace/activeSection"), section);
    emit activeSectionChanged();
}

void AppBackend::restoreDefaultWorkspace() {
    setDarkMode(true);
    setMediaPanelVisible(true);
    setInspectorVisible(true);
    setTimelineVisible(true);
    setActiveSection(QStringLiteral("media"));
}
