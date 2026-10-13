#pragma once

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QObject>
#include <QUrl>

// Native Qt Multimedia playback facade. Decoding and audio/video timing are
// handled by Qt's FFmpeg backend on supported Windows installations.
class PlaybackController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playbackChanged)
    Q_PROPERTY(bool seekable READ seekable NOTIFY seekableChanged)
    Q_PROPERTY(bool hasVideo READ hasVideo NOTIFY videoChanged)
    Q_PROPERTY(bool hasAudio READ hasAudio NOTIFY audioChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(double playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY playbackRateChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit PlaybackController(QObject* parent = nullptr);

    QUrl source() const;
    bool playing() const;
    bool seekable() const;
    bool hasVideo() const;
    bool hasAudio() const;
    qint64 position() const;
    qint64 duration() const;
    double volume() const;
    void setVolume(double value);
    bool muted() const;
    void setMuted(bool muted);
    double playbackRate() const;
    void setPlaybackRate(double value);
    QString errorString() const;
    QString status() const;

    Q_INVOKABLE bool load(const QUrl& file, const QString& kind);
    Q_INVOKABLE bool attachVideoSink(QObject* sink);
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seekMs(qint64 position);
    Q_INVOKABLE void stepFrame(int direction);
    Q_INVOKABLE void clear();

signals:
    void sourceChanged();
    void playbackChanged();
    void seekableChanged();
    void videoChanged();
    void audioChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void mutedChanged();
    void playbackRateChanged();
    void errorChanged();
    void statusChanged();

private:
    QMediaPlayer player_;
    QAudioOutput audioOutput_;
    QString validationError_;
};
