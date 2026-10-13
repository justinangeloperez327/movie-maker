#include "app_backend.h"

#include "bridge.h"
#include "media_indexer.h"

#include <QByteArray>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrent>
#include <QSaveFile>
#include <QtGlobal>

#include <exception>
#include <memory>
#include <utility>

class ProjectSessionHolder {
public:
    explicit ProjectSessionHolder(rust::Box<movie_maker::ProjectSession>&& project)
        : value(std::move(project)) {}

    rust::Box<movie_maker::ProjectSession> value;
};

namespace {
QString fromRustString(const rust::String& value) {
    return QString::fromUtf8(value.data(), static_cast<qsizetype>(value.size()));
}

rust::Str asRustStr(const QByteArray& value) {
    return rust::Str(value.constData(), static_cast<size_t>(value.size()));
}

bool validSection(const QString& section) {
    return section == QStringLiteral("media")
        || section == QStringLiteral("effects")
        || section == QStringLiteral("transitions")
        || section == QStringLiteral("titles");
}

constexpr qint64 kMaximumProjectBytes = 16 * 1024 * 1024;
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

AppBackend::~AppBackend() = default;

QString AppBackend::engineName() const {
    return fromRustString(movie_maker::application_name());
}

QString AppBackend::coreVersion() const {
    return fromRustString(movie_maker::core_version());
}

bool AppBackend::darkMode() const { return darkMode_; }

void AppBackend::setDarkMode(bool value) {
    if (darkMode_ == value) return;
    darkMode_ = value;
    settings_.setValue(QStringLiteral("workspace/darkMode"), value);
    emit darkModeChanged();
}

bool AppBackend::mediaPanelVisible() const { return mediaPanelVisible_; }

void AppBackend::setMediaPanelVisible(bool value) {
    if (mediaPanelVisible_ == value) return;
    mediaPanelVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/mediaVisible"), value);
    emit mediaPanelVisibleChanged();
}

bool AppBackend::inspectorVisible() const { return inspectorVisible_; }

void AppBackend::setInspectorVisible(bool value) {
    if (inspectorVisible_ == value) return;
    inspectorVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/inspectorVisible"), value);
    emit inspectorVisibleChanged();
}

bool AppBackend::timelineVisible() const { return timelineVisible_; }

void AppBackend::setTimelineVisible(bool value) {
    if (timelineVisible_ == value) return;
    timelineVisible_ = value;
    settings_.setValue(QStringLiteral("workspace/timelineVisible"), value);
    emit timelineVisibleChanged();
}

QString AppBackend::activeSection() const { return activeSection_; }

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

bool AppBackend::hasProject() const { return project_ != nullptr; }

QString AppBackend::projectName() const {
    return project_ ? fromRustString(project_->value->project_name()) : QStringLiteral("No project");
}

QString AppBackend::projectPath() const { return projectPath_; }
bool AppBackend::isModified() const { return modified_; }

int AppBackend::mediaCount() const {
    return project_ ? static_cast<int>(project_->value->project_media_count()) : 0;
}

int AppBackend::trackCount() const {
    return project_ ? static_cast<int>(project_->value->project_track_count()) : 0;
}

bool AppBackend::createProject(const QString& name) {
    try {
        const QByteArray utf8 = name.toUtf8();
        auto candidate = std::make_unique<ProjectSessionHolder>(movie_maker::new_project(asRustStr(utf8)));
        project_ = std::move(candidate);
        ++projectGeneration_;
        pendingImports_ = 0;
        emit importStateChanged();
        projectPath_.clear();
        modified_ = true; // New projects must be saved explicitly.
        emit projectChanged();
        return true;
    } catch (const std::exception& error) {
        emit operationFailed(QString::fromUtf8(error.what()));
        return false;
    }
}

bool AppBackend::openProject(const QUrl& url) {
    if (!url.isLocalFile()) {
        emit operationFailed(QStringLiteral("Projects must be opened from a local file."));
        return false;
    }
    const QString path = url.toLocalFile();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        emit operationFailed(QStringLiteral("Cannot open project: %1").arg(file.errorString()));
        return false;
    }
    if (file.size() > kMaximumProjectBytes) {
        emit operationFailed(QStringLiteral("Project file exceeds 16 MiB."));
        return false;
    }
    QByteArray bytes = file.read(kMaximumProjectBytes + 1);
    if (bytes.size() > kMaximumProjectBytes || file.error() != QFileDevice::NoError) {
        emit operationFailed(QStringLiteral("Could not read the complete project."));
        return false;
    }
    // CXX &str requires well-formed UTF-8. Reject malformed input before FFI.
    if (QString::fromUtf8(bytes).toUtf8() != bytes) {
        emit operationFailed(QStringLiteral("Project file is not valid UTF-8."));
        return false;
    }
    try {
        auto candidate = std::make_unique<ProjectSessionHolder>(movie_maker::project_from_json(asRustStr(bytes)));
        // Preserve the previously opened project if deserialization or validation fails.
        project_ = std::move(candidate);
        ++projectGeneration_;
        pendingImports_ = 0;
        emit importStateChanged();
        projectPath_ = QFileInfo(path).absoluteFilePath();
        modified_ = false;
        emit projectChanged();
        return true;
    } catch (const std::exception& error) {
        emit operationFailed(QString::fromUtf8(error.what()));
        return false;
    }
}

bool AppBackend::saveProject() {
    if (projectPath_.isEmpty()) {
        emit operationFailed(QStringLiteral("Choose a project filename with Save As."));
        return false;
    }
    return saveProjectAs(QUrl::fromLocalFile(projectPath_));
}

bool AppBackend::saveProjectAs(const QUrl& url) {
    if (!project_) {
        emit operationFailed(QStringLiteral("Create or open a project before saving."));
        return false;
    }
    if (!url.isLocalFile()) {
        emit operationFailed(QStringLiteral("Projects must be saved to a local file."));
        return false;
    }

    QString path = url.toLocalFile();
    if (QFileInfo(path).suffix().compare(QStringLiteral("mmproj"), Qt::CaseInsensitive) != 0) {
        path += QStringLiteral(".mmproj");
    }
    try {
        const rust::String serialized = project_->value->project_json();
        const QByteArray json(serialized.data(), static_cast<qsizetype>(serialized.size()));
        QSaveFile file(path);
        if (!file.open(QIODevice::WriteOnly)) {
            emit operationFailed(QStringLiteral("Cannot write project: %1").arg(file.errorString()));
            return false;
        }
        if (file.write(json) != json.size()) {
            file.cancelWriting();
            emit operationFailed(QStringLiteral("Unable to write the full project document."));
            return false;
        }
        if (!file.commit()) {
            emit operationFailed(QStringLiteral("Cannot finish saving project: %1").arg(file.errorString()));
            return false;
        }
        projectPath_ = QFileInfo(path).absoluteFilePath();
        modified_ = false;
        emit projectChanged();
        return true;
    } catch (const std::exception& error) {
        emit operationFailed(QString::fromUtf8(error.what()));
        return false;
    }
}

QVariantList AppBackend::mediaItems() const {
    QVariantList items;
    if (!project_) return items;
    const rust::String json = project_->value->project_media_json();
    const QByteArray payload(json.data(), static_cast<qsizetype>(json.size()));
    const QJsonArray media = QJsonDocument::fromJson(payload).array();
    items.reserve(media.size());
    for (const QJsonValue& value : media) {
        const QJsonObject mediaItem = value.toObject();
        const QString path = mediaItem.value(QStringLiteral("path")).toString();
        const QFileInfo file(path);
        QVariantMap item = mediaItem.toVariantMap();
        const QString kind = mediaItem.value(QStringLiteral("kind")).toString();
        const QString codec = mediaItem.value(QStringLiteral("codec")).toString();
        const int width = mediaItem.value(QStringLiteral("width")).toInt();
        const int height = mediaItem.value(QStringLiteral("height")).toInt();
        const quint64 durationUs = static_cast<quint64>(mediaItem.value(QStringLiteral("duration_us")).toDouble());
        const quint64 seconds = durationUs / 1000000;
        QString subtitle = kind.toUpper();
        if (!codec.isEmpty()) subtitle += QStringLiteral(" · ") + codec;
        if (width > 0 && height > 0) {
            subtitle += QStringLiteral(" · %1×%2").arg(width).arg(height);
        }
        if (durationUs > 0) {
            subtitle += QStringLiteral(" · %1:%2")
                .arg(seconds / 60)
                .arg(seconds % 60, 2, 10, QLatin1Char('0'));
        }
        item.insert(QStringLiteral("name"), file.fileName());
        item.insert(QStringLiteral("subtitle"), subtitle);
        item.insert(QStringLiteral("missing"), !file.exists());
        const QString thumbnail = MediaIndexer::cachedThumbnail(path);
        const QString waveform = MediaIndexer::cachedWaveform(path);
        item.insert(QStringLiteral("thumbnailUrl"),
                    thumbnail.isEmpty() ? QUrl() : QUrl::fromLocalFile(thumbnail));
        item.insert(QStringLiteral("waveformUrl"),
                    waveform.isEmpty() ? QUrl() : QUrl::fromLocalFile(waveform));
        items.append(item);
    }
    return items;
}

bool AppBackend::importing() const {
    return pendingImports_ > 0;
}

int AppBackend::pendingImports() const {
    return pendingImports_;
}

bool AppBackend::importMedia(const QList<QUrl>& urls) {
    if (!project_) {
        emit operationFailed(QStringLiteral("Create or open a project before importing media."));
        return false;
    }
    if (urls.isEmpty()) return false;
    if (MediaIndexer::ffmpegExecutable().isEmpty() || MediaIndexer::ffprobeExecutable().isEmpty()) {
        emit operationFailed(QStringLiteral("FFmpeg and FFprobe are required for importing. Add them to PATH or set MOVIE_MAKER_FFMPEG_DIR."));
        return false;
    }
    const quint64 generation = projectGeneration_;
    bool started = false;
    for (const QUrl& url : urls) {
        if (!url.isLocalFile()) {
            emit operationFailed(QStringLiteral("Only local media files are supported."));
            continue;
        }
        const QFileInfo file(url.toLocalFile());
        const QString canonical = file.canonicalFilePath();
        if (canonical.isEmpty() || !file.isReadable() || !file.isFile()) {
            emit operationFailed(QStringLiteral("Cannot read media: %1").arg(url.toLocalFile()));
            continue;
        }
        const QString path = canonical;
        auto* watcher = new QFutureWatcher<MediaIndexResult>(this);
        connect(watcher, &QFutureWatcher<MediaIndexResult>::finished, this, [this, watcher, generation]() {
            const MediaIndexResult indexed = watcher->result();
            watcher->deleteLater();
            if (generation != projectGeneration_ || !project_) return;
            --pendingImports_;
            emit importStateChanged();
            if (!indexed.ok()) {
                emit operationFailed(QStringLiteral("%1: %2").arg(QFileInfo(indexed.path).fileName(), indexed.error));
                return;
            }
            try {
                const QByteArray pathUtf8 = indexed.path.toUtf8();
                const QByteArray kindUtf8 = indexed.kind.toUtf8();
                const QByteArray codecUtf8 = indexed.codec.toUtf8();
                const bool added = project_->value->project_add_media(
                    asRustStr(pathUtf8),
                    asRustStr(kindUtf8),
                    indexed.durationUs,
                    indexed.width,
                    indexed.height,
                    asRustStr(codecUtf8)
                );
                if (added) {
                    modified_ = true;
                    emit projectChanged();
                }
            } catch (const std::exception& error) {
                emit operationFailed(QString::fromUtf8(error.what()));
            }
        });
        ++pendingImports_;
        emit importStateChanged();
        watcher->setFuture(QtConcurrent::run([path]() { return MediaIndexer::scan(path); }));
        started = true;
    }
    return started;
}
