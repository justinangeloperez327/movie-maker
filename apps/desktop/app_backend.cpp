#include "app_backend.h"

#include "bridge.h"

#include <QtGlobal>

namespace {
QString fromRustString(const rust::String& value) {
    return QString::fromUtf8(value.data(), static_cast<qsizetype>(value.size()));
}
} // namespace

AppBackend::AppBackend(QObject* parent)
    : QObject(parent) {}

QString AppBackend::engineName() const {
    return fromRustString(movie_maker::application_name());
}

QString AppBackend::coreVersion() const {
    return fromRustString(movie_maker::core_version());
}
