#pragma once

#include <QString>
#include <QStringList>
#include <QUrl>
#include <functional>

struct EngineTarget {
    QString system;
    QString archSuffix;
    QStringList ghSuffixes;
    QString engineDir;
    QString engineBin;
};

EngineTarget currentTarget();

bool resolveEngine(const EngineTarget &target, QString *tag, QString *url);

QString httpGetString(const QUrl &url, int timeoutMs, QString *error);

QString downloadFile(const QUrl &url, const QString &dest,
                     const std::function<void(qint64, qint64)> &progress);

QString extractArchive(const QString &zipPath, const QString &destDir);
QString engineVersion(const QString &engineDir, const EngineTarget &target);

bool looksLikeWindows();
QString platformLabel();
QString exeSuffix();
