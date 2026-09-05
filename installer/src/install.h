#pragma once

#include "engine.h"

#include <QString>
#include <functional>

struct InstallResult {
    bool ok = false;
    QString error;
    QString installDir;
    QStringList createdShortcuts;
};

using ProgressFn = std::function<void(int percent, const QString &status)>;

QString defaultInstallDir(const EngineTarget &target);

InstallResult runInstall(const EngineTarget &target, const QString &installDir,
                         bool createShortcuts, const QByteArray &payloadZip,
                         const ProgressFn &progress);

void launchInstalled(const EngineTarget &target, const QString &installDir);

QString applyPayload(const EngineTarget &target, const QString &installDir,
                     const QString &payloadDir);

void createShortcutsFor(const EngineTarget &target, const QString &installDir,
                        bool desktopShortcut, QStringList *created);