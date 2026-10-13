#include "app_backend.h"

#include <QCoreApplication>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStringList>

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Movie Maker"));
    QCoreApplication::setOrganizationName(QStringLiteral("MovieMaker"));

    AppBackend backend;

    // Exercise the compiled Rust/CXX/C++ integration in Windows CI without opening a window.
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
    return app.exec();
}
