#include "app_backend.h"

#include <QCoreApplication>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStringList>

int main(int argc, char* argv[]) {
    // Styling is set before constructing Qt Quick Controls.
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
        qInfo() << "Rust/CXX bridge OK:" << backend.engineName()
                << backend.coreVersion();
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

        // Exercise QObject state change notifications without modifying persisted settings.
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
