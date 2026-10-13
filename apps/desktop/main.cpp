#include "app_backend.h"

#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QEventLoop>
#include <QFileInfo>
#include <QTimer>
#include "media_indexer.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStringList>
#include <QTemporaryDir>
#include <QUrl>

int main(int argc, char* argv[]) {
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Movie Maker"));
    QCoreApplication::setOrganizationName(QStringLiteral("MovieMaker"));

    AppBackend backend;

    if (app.arguments().contains(QStringLiteral("--self-test"))) {
        const bool healthy =
            backend.engineName() == QStringLiteral("Movie Maker") &&
            backend.coreVersion() == QStringLiteral("0.1.0-dev");
        if (!healthy) {
            qCritical() << "Rust/CXX bridge self-test failed";
            return 1;
        }
        qInfo() << "Rust/CXX bridge OK:" << backend.engineName() << backend.coreVersion();
        return 0;
    }

    // End-to-end cross-language project test: Rust create/serialize/parse,
    // Qt QSaveFile write and QFile read, plus failure preserving open state.
    if (app.arguments().contains(QStringLiteral("--project-self-test"))) {
        QTemporaryDir folder;
        if (!folder.isValid()) return 4;
        const QUrl projectUrl = QUrl::fromLocalFile(folder.filePath(QStringLiteral("example.mmproj")));
        if (!backend.createProject(QStringLiteral("CI Sample")) || !backend.isModified()) return 5;
        if (!backend.saveProjectAs(projectUrl) || backend.isModified()) return 6;
        if (!backend.openProject(projectUrl) || backend.projectName() != QStringLiteral("CI Sample")
            || backend.trackCount() != 2 || backend.mediaCount() != 0) return 7;
        const QUrl invalidUrl = QUrl::fromLocalFile(folder.filePath(QStringLiteral("bad.mmproj")));
        QFile badFile(invalidUrl.toLocalFile());
        if (!badFile.open(QIODevice::WriteOnly)) return 8;
        badFile.write("{invalid");
        badFile.close();
        if (backend.openProject(invalidUrl) || backend.projectName() != QStringLiteral("CI Sample")) return 9;
        qInfo() << "Rust/CXX/Qt project create, atomic save, load and reject-invalid checks passed";
        return 0;
    }

    if (app.arguments().contains(QStringLiteral("--media-self-test"))) {
        const int index = app.arguments().indexOf(QStringLiteral("--media-self-test"));
        if (index < 0 || app.arguments().size() <= index + 2) return 10;
        QTemporaryDir temp;
        if (!temp.isValid() || !backend.createProject(QStringLiteral("Media smoke test"))) return 11;
        const QList<QUrl> inputs = {
            QUrl::fromLocalFile(app.arguments().at(index + 1)),
            QUrl::fromLocalFile(app.arguments().at(index + 2))
        };
        if (!backend.importMedia(inputs)) return 12;
        QEventLoop loop;
        QTimer timeout;
        timeout.setSingleShot(true);
        QObject::connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
        QObject::connect(&backend, &AppBackend::importStateChanged, &loop, [&] {
            if (!backend.importing()) loop.quit();
        });
        timeout.start(90'000);
        if (backend.importing()) loop.exec();
        if (backend.importing() || backend.mediaCount() != 2) {
            qCritical() << "FFmpeg indexing did not finish correctly:" << backend.mediaCount();
            return 13;
        }
        const QVariantList items = backend.mediaItems();
        bool videoFound = false;
        bool audioFound = false;
        for (const QVariant& itemValue : items) {
            const QVariantMap item = itemValue.toMap();
            const QString kind = item.value(QStringLiteral("kind")).toString();
            if (kind == QStringLiteral("video")) {
                videoFound = item.value(QStringLiteral("width")).toInt() > 0
                    && item.value(QStringLiteral("thumbnailUrl")).toUrl().isLocalFile()
                    && QFileInfo::exists(item.value(QStringLiteral("thumbnailUrl")).toUrl().toLocalFile());
            }
            if (kind == QStringLiteral("audio")) {
                audioFound = item.value(QStringLiteral("waveformUrl")).toUrl().isLocalFile()
                    && QFileInfo::exists(item.value(QStringLiteral("waveformUrl")).toUrl().toLocalFile());
            }
        }
        if (!videoFound || !audioFound) {
            qCritical() << "FFmpeg preview cache missing:" << videoFound << audioFound;
            return 14;
        }
        const QUrl file = QUrl::fromLocalFile(temp.filePath(QStringLiteral("imported.mmproj")));
        if (!backend.saveProjectAs(file) || !backend.openProject(file) || backend.mediaCount() != 2) {
            qCritical() << "Rust imported-media persistence failed";
            return 15;
        }
        qInfo() << "Media probes, thumbnails, waveforms, Rust persistence passed";
        return 0;
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("appBackend"), &backend);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] { QCoreApplication::exit(1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule("MovieMaker", "Main");

    if (app.arguments().contains(QStringLiteral("--ui-self-test"))) {
        if (engine.rootObjects().size() != 1
                || engine.rootObjects().first()->objectName() != QStringLiteral("movieMakerMainWindow")) {
            qCritical() << "Qt Quick workspace smoke test failed";
            return 2;
        }
        const QString originalSection = backend.activeSection();
        backend.setActiveSection(QStringLiteral("effects"));
        const bool sectionChanged = backend.activeSection() == QStringLiteral("effects");
        backend.setActiveSection(originalSection);
        if (!sectionChanged) {
            qCritical() << "Qt workspace backend state test failed";
            return 3;
        }
        qInfo() << "Qt Quick workspace loaded and backend state updated";
        return 0;
    }

    return app.exec();
}
