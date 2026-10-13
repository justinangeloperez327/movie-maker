#include "media_indexer.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSet>
#include <QStandardPaths>
#include <QStringList>

#include <cmath>
#include <limits>

namespace {
QString findTool(const QString& filename) {
    const QString customDir = qEnvironmentVariable("MOVIE_MAKER_FFMPEG_DIR");
    if (!customDir.isEmpty()) {
        const QString custom = QDir(customDir).filePath(filename + QStringLiteral(".exe"));
        if (QFileInfo::exists(custom)) return custom;
    }
    return QStandardPaths::findExecutable(filename);
}

struct ProcessResult {
    bool succeeded = false;
    QByteArray output;
    QString error;
};

ProcessResult invoke(const QString& program, const QStringList& args, int timeoutMs) {
    if (program.isEmpty()) {
        return {false, {}, QStringLiteral("FFmpeg tools not found. Add ffmpeg and ffprobe to PATH.")};
    }
    QProcess process;
    process.setProgram(program);
    process.setArguments(args);
    process.setProcessChannelMode(QProcess::SeparateChannels);
    process.start(QIODevice::ReadOnly);
    if (!process.waitForStarted(5000)) {
        return {false, {}, QStringLiteral("Could not launch %1: %2").arg(program, process.errorString())};
    }
    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(2000);
        return {false, {}, QStringLiteral("Media processing timed out.")};
    }
    const QByteArray stderrText = process.readAllStandardError().left(500);
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        return {false, {}, QStringLiteral("FFmpeg error: %1").arg(QString::fromUtf8(stderrText))};
    }
    const QByteArray output = process.readAllStandardOutput();
    if (output.size() > 1024 * 1024) {
        return {false, {}, QStringLiteral("Unexpected oversized FFprobe response.")};
    }
    return {true, output, {}};
}

quint64 durationMicros(const QJsonValue& value) {
    const QString source = value.toString();
    bool good = false;
    const double seconds = source.toDouble(&good);
    if (!good || !std::isfinite(seconds) || seconds <= 0.0 || seconds > 1.0e9) {
        return 0;
    }
    return static_cast<quint64>(std::round(seconds * 1000000.0));
}

bool isImageExtension(const QString& suffix) {
    static const QSet<QString> types = {
        QStringLiteral("png"), QStringLiteral("jpg"), QStringLiteral("jpeg"),
        QStringLiteral("webp"), QStringLiteral("bmp"), QStringLiteral("tif"),
        QStringLiteral("tiff"), QStringLiteral("gif")
    };
    return types.contains(suffix.toLower());
}
} // namespace

QString MediaIndexer::ffmpegExecutable() {
    return findTool(QStringLiteral("ffmpeg"));
}

QString MediaIndexer::ffprobeExecutable() {
    return findTool(QStringLiteral("ffprobe"));
}

QString MediaIndexer::cacheFile(const QString& path, const QString& prefix) {
    const QFileInfo source(path);
    QByteArray key = source.absoluteFilePath().toUtf8();
    key.append('|');
    key.append(QByteArray::number(source.size()));
    key.append('|');
    key.append(QByteArray::number(source.lastModified().toMSecsSinceEpoch()));
    const QByteArray hash = QCryptographicHash::hash(key, QCryptographicHash::Sha256).toHex();
    const QString cacheRoot = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (cacheRoot.isEmpty()) return {};
    const QString folder = QDir(cacheRoot).filePath(QStringLiteral("media-index"));
    if (!QDir().mkpath(folder)) return {};
    return QDir(folder).filePath(prefix + QString::fromLatin1(hash) + QStringLiteral(".png"));
}

QString MediaIndexer::cachedThumbnail(const QString& path) {
    const QString name = cacheFile(path, QStringLiteral("thumb-"));
    return QFileInfo::exists(name) ? name : QString();
}

QString MediaIndexer::cachedWaveform(const QString& path) {
    const QString name = cacheFile(path, QStringLiteral("wave-"));
    return QFileInfo::exists(name) ? name : QString();
}

MediaIndexResult MediaIndexer::scan(const QString& path) {
    MediaIndexResult result;
    result.path = path;
    const QFileInfo file(path);
    if (!file.exists() || !file.isFile() || !file.isReadable()) {
        result.error = QStringLiteral("Cannot read the media file: %1").arg(path);
        return result;
    }
    const QString probe = ffprobeExecutable();
    const QString encoder = ffmpegExecutable();
    if (probe.isEmpty() || encoder.isEmpty()) {
        result.error = QStringLiteral("FFmpeg and FFprobe are required for media import. Install them and add them to PATH.");
        return result;
    }

    const ProcessResult inspected = invoke(
        probe,
        {QStringLiteral("-v"), QStringLiteral("error"),
         QStringLiteral("-show_entries"), QStringLiteral("format=duration:stream=index,codec_type,codec_name,width,height,duration"),
         QStringLiteral("-of"), QStringLiteral("json"), path},
        15000
    );
    if (!inspected.succeeded) {
        result.error = inspected.error;
        return result;
    }
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(inspected.output, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        result.error = QStringLiteral("Invalid metadata returned by FFprobe.");
        return result;
    }
    const QJsonObject root = document.object();
    const QJsonArray streams = root.value(QStringLiteral("streams")).toArray();
    QJsonObject video;
    QJsonObject audio;
    for (const QJsonValue& streamValue : streams) {
        const QJsonObject stream = streamValue.toObject();
        const QString type = stream.value(QStringLiteral("codec_type")).toString();
        if (type == QStringLiteral("video") && video.isEmpty()) video = stream;
        if (type == QStringLiteral("audio") && audio.isEmpty()) audio = stream;
    }

    if (!video.isEmpty()) {
        result.kind = isImageExtension(file.suffix()) ? QStringLiteral("image") : QStringLiteral("video");
        result.width = static_cast<quint32>(qMax(0, video.value(QStringLiteral("width")).toInt()));
        result.height = static_cast<quint32>(qMax(0, video.value(QStringLiteral("height")).toInt()));
        result.codec = video.value(QStringLiteral("codec_name")).toString().left(64);
    } else if (!audio.isEmpty()) {
        result.kind = QStringLiteral("audio");
        result.codec = audio.value(QStringLiteral("codec_name")).toString().left(64);
    } else {
        result.error = QStringLiteral("No supported audio or video stream was found.");
        return result;
    }

    if (result.kind != QStringLiteral("image")) {
        result.durationUs = durationMicros(root.value(QStringLiteral("format")).toObject().value(QStringLiteral("duration")));
        if (result.durationUs == 0) {
            result.durationUs = durationMicros((!video.isEmpty() ? video : audio).value(QStringLiteral("duration")));
        }
        if (result.durationUs == 0) {
            result.error = QStringLiteral("Cannot determine media duration.");
            return result;
        }
    }
    // Cached previews are optional; extraction errors must not prevent a valid
    // project reference from being imported. The original is never modified.
    if (result.kind != QStringLiteral("audio")) {
        const QString destination = cacheFile(path, QStringLiteral("thumb-"));
        if (!destination.isEmpty() && !QFileInfo::exists(destination)) {
            const QStringList args = {
                QStringLiteral("-nostdin"), QStringLiteral("-hide_banner"),
                QStringLiteral("-loglevel"), QStringLiteral("error"),
                QStringLiteral("-y"), QStringLiteral("-i"), path,
                QStringLiteral("-frames:v"), QStringLiteral("1"),
                QStringLiteral("-vf"), QStringLiteral("scale=320:180:force_original_aspect_ratio=decrease"),
                destination
            };
            const ProcessResult thumb = invoke(encoder, args, 30000);
            if (!thumb.succeeded) QFile::remove(destination);
        }
        result.thumbnailPath = cachedThumbnail(path);
    }
    if (!audio.isEmpty()) {
        const QString destination = cacheFile(path, QStringLiteral("wave-"));
        if (!destination.isEmpty() && !QFileInfo::exists(destination)) {
            const QStringList args = {
                QStringLiteral("-nostdin"), QStringLiteral("-hide_banner"),
                QStringLiteral("-loglevel"), QStringLiteral("error"), QStringLiteral("-y"),
                QStringLiteral("-i"), path, QStringLiteral("-t"), QStringLiteral("45"),
                QStringLiteral("-filter_complex"),
                QStringLiteral("[0:a:0]aformat=channel_layouts=mono,showwavespic=s=640x96:colors=0xd33b43[v]"),
                QStringLiteral("-map"), QStringLiteral("[v]"),
                QStringLiteral("-frames:v"), QStringLiteral("1"), destination
            };
            const ProcessResult waveform = invoke(encoder, args, 30000);
            if (!waveform.succeeded) QFile::remove(destination);
        }
        result.waveformPath = cachedWaveform(path);
    }
    return result;
}
