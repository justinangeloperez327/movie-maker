#include "playback_controller.h"

#include <QFileInfo>
#include <QMediaMetaData>
#include <QVideoSink>
#include <QtGlobal>

#include <algorithm>
#include <cmath>

PlaybackController::PlaybackController(QObject* parent)
    : QObject(parent), player_(this), audioOutput_(this) {
    player_.setAudioOutput(&audioOutput_);
    audioOutput_.setVolume(0.75);

    connect(&player_, &QMediaPlayer::sourceChanged, this, &PlaybackController::sourceChanged);
    connect(&player_, &QMediaPlayer::playbackStateChanged, this, &PlaybackController::playbackChanged);
    connect(&player_, &QMediaPlayer::positionChanged, this, &PlaybackController::positionChanged);
    connect(&player_, &QMediaPlayer::durationChanged, this, &PlaybackController::durationChanged);
    connect(&player_, &QMediaPlayer::seekableChanged, this, &PlaybackController::seekableChanged);
    connect(&player_, &QMediaPlayer::hasVideoChanged, this, &PlaybackController::videoChanged);
    connect(&player_, &QMediaPlayer::hasAudioChanged, this, &PlaybackController::audioChanged);
    connect(&player_, &QMediaPlayer::mediaStatusChanged, this, &PlaybackController::statusChanged);
    connect(&player_, &QMediaPlayer::errorChanged, this, &PlaybackController::errorChanged);
    connect(&player_, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString&) {
        emit errorChanged();
        emit statusChanged();
    });
    connect(&audioOutput_, &QAudioOutput::volumeChanged, this, &PlaybackController::volumeChanged);
    connect(&audioOutput_, &QAudioOutput::mutedChanged, this, &PlaybackController::mutedChanged);
    connect(&player_, &QMediaPlayer::playbackRateChanged, this, &PlaybackController::playbackRateChanged);
}

QUrl PlaybackController::source() const { return player_.source(); }
bool PlaybackController::playing() const { return player_.playbackState() == QMediaPlayer::PlayingState; }
bool PlaybackController::seekable() const { return player_.isSeekable(); }
bool PlaybackController::hasVideo() const { return player_.hasVideo(); }
bool PlaybackController::hasAudio() const { return player_.hasAudio(); }
qint64 PlaybackController::position() const { return player_.position(); }
qint64 PlaybackController::duration() const { return player_.duration(); }
double PlaybackController::volume() const { return audioOutput_.volume(); }
void PlaybackController::setVolume(double value) {
    audioOutput_.setVolume(std::clamp(value, 0.0, 1.0));
}
bool PlaybackController::muted() const { return audioOutput_.isMuted(); }
void PlaybackController::setMuted(bool muted) { audioOutput_.setMuted(muted); }
double PlaybackController::playbackRate() const { return player_.playbackRate(); }
void PlaybackController::setPlaybackRate(double value) {
    if (std::isfinite(value) && value >= 0.25 && value <= 2.0) player_.setPlaybackRate(value);
}
QString PlaybackController::errorString() const {
    return validationError_.isEmpty() ? player_.errorString() : validationError_;
}
QString PlaybackController::status() const {
    if (!errorString().isEmpty()) return QStringLiteral("Error");
    switch (player_.mediaStatus()) {
    case QMediaPlayer::NoMedia: return QStringLiteral("No source");
    case QMediaPlayer::LoadingMedia: return QStringLiteral("Loading");
    case QMediaPlayer::LoadedMedia: return QStringLiteral("Ready");
    case QMediaPlayer::BufferingMedia: return QStringLiteral("Buffering");
    case QMediaPlayer::StalledMedia: return QStringLiteral("Stalled");
    case QMediaPlayer::BufferedMedia: return QStringLiteral("Ready");
    case QMediaPlayer::EndOfMedia: return QStringLiteral("Finished");
    case QMediaPlayer::InvalidMedia: return QStringLiteral("Invalid media");
    }
    return QStringLiteral("Ready");
}

void PlaybackController::clear() {
    validationError_.clear();
    player_.stop();
    player_.setSource(QUrl());
    emit errorChanged();
    emit statusChanged();
}

bool PlaybackController::load(const QUrl& file, const QString& kind) {
    clear();
    if (kind == QStringLiteral("image") || file.isEmpty()) return false;
    if (!file.isLocalFile() || !(kind == QStringLiteral("video") || kind == QStringLiteral("audio"))
            || !QFileInfo(file.toLocalFile()).isReadable()) {
        validationError_ = QStringLiteral("Preview requires an existing local audio or video file.");
        emit errorChanged();
        emit statusChanged();
        return false;
    }
    player_.setSource(file);
    return true;
}

bool PlaybackController::attachVideoSink(QObject* sink) {
    auto* videoSink = qobject_cast<QVideoSink*>(sink);
    if (videoSink == nullptr) return false;
    player_.setVideoSink(videoSink);
    return true;
}

void PlaybackController::play() {
    if (!player_.source().isEmpty()) player_.play();
}
void PlaybackController::pause() { player_.pause(); }
void PlaybackController::toggle() { playing() ? pause() : play(); }
void PlaybackController::stop() { player_.stop(); }
void PlaybackController::seekMs(qint64 positionMs) {
    if (!seekable()) return;
    player_.setPosition(std::clamp(positionMs, qint64(0), std::max(qint64(0), duration())));
}

void PlaybackController::stepFrame(int direction) {
    if (!seekable() || direction == 0) return;
    pause();
    // QMediaPlayer provides millisecond seeking, not frame-accurate stepping.
    // The media's nominal frame rate provides a best-effort approximate step.
    const double fps = player_.metaData().value(QMediaMetaData::VideoFrameRate).toDouble();
    const double step = std::isfinite(fps) && fps >= 1.0 && fps <= 240.0
        ? (1000.0 / fps) : (1000.0 / 30.0);
    seekMs(position() + static_cast<qint64>(std::llround(step)) * (direction > 0 ? 1 : -1));
}
