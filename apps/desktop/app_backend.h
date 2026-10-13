#pragma once

#include <QObject>
#include <QString>

class AppBackend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString engineName READ engineName CONSTANT)
    Q_PROPERTY(QString coreVersion READ coreVersion CONSTANT)

public:
    explicit AppBackend(QObject* parent = nullptr);

    QString engineName() const;
    QString coreVersion() const;
};
