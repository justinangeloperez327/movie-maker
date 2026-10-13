#pragma once

#include <QString>
#include <QtGlobal>

// Immutable worker result. FFmpeg processes run outside the Qt UI thread.
struct MediaIndexResult {
    QString path;
    QString kind;
    QString codec;
    QString thumbnailPath;
    QString waveformPath;
    QString error;
    quint64 durationUs = 0;
    quint32 width = 0;
    quint32 height = 0;

    bool ok() const { return error.isEmpty(); }
};

class MediaIndexer {
public:
    static MediaIndexResult scan(const QString& path);
    static QString cachedThumbnail(const QString& path);
    static QString cachedWaveform(const QString& path);
    static QString ffmpegExecutable();
    static QString ffprobeExecutable();

private:
    static QString cacheFile(const QString& path, const QString& prefix);
};
