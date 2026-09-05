#include "install.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMessageBox>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QTextStream>
#include <QUrl>

static QString homeWritableDir(const QString &sub) {
    QDir d(QDir::home());
    for (const QString &part : sub.split(QChar('/'))) {
        if (!part.isEmpty() && !d.cd(part)) {
            d.mkdir(part);
            d.cd(part);
        }
    }
    return d.absolutePath();
}

QString defaultInstallDir(const EngineTarget &target) {
    if (target.system == QLatin1String("windows")) {
        const QString local = QStandardPaths::writableLocation(
            QStandardPaths::AppLocalDataLocation);
        const QString base =
            local.isEmpty() ? QDir::homePath() + QLatin1String("/AppData/Local")
                            : QFileInfo(local).absolutePath();
        return base + QLatin1String("/Aurora Browser");
    }
    if (target.system == QLatin1String("macos")) {
        return QStringLiteral("/Applications/Aurora Browser.app");
    }
    return homeWritableDir(QStringLiteral(".local/share/aurora-browser"));
}

static void copyFile(const QString &src, const QString &dst, bool executable = false) {
    QDir().mkpath(QFileInfo(dst).absolutePath());
    QFile::remove(dst);
    QFile::copy(src, dst);
    if (executable) {
        QFile::Permissions perms = QFile::permissions(dst);
        perms |= QFileDevice::ExeOwner | QFileDevice::ExeGroup | QFileDevice::ExeOther;
        QFile::setPermissions(dst, perms);
    }
}

static void copyTree(const QString &src, const QString &dst) {
    QDir srcDir(src);
    QDir().mkpath(dst);
    const QStringList entries = srcDir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot);
    for (const QString &entry : entries) {
        const QString from = srcDir.filePath(entry);
        const QString to = dst + QLatin1Char('/') + entry;
        if (QFileInfo(from).isDir()) {
            copyTree(from, to);
        } else {
            copyFile(from, to);
        }
    }
}

QString applyPayload(const EngineTarget &target, const QString &installDir,
                     const QString &payloadDir) {
    const QDir payload(payloadDir);
    if (target.system == QLatin1String("linux")) {
        copyFile(payload.filePath(QStringLiteral("linux/aurora-browser")),
                 installDir + QLatin1String("/aurora-browser"), true);
        copyFile(payload.filePath(QStringLiteral("aurora.png")),
                 installDir + QLatin1String("/aurora.png"));
    } else if (target.system == QLatin1String("windows")) {
        const QString exe = payload.filePath(QStringLiteral("windows/aurora-browser.exe"));
        if (QFile::exists(exe)) {
            copyFile(exe, installDir + QLatin1String("/aurora-browser.exe"));
        } else {
            // Generate a batch launcher that runs ladybird
            const QString bat = installDir + QLatin1String("/aurora-browser.bat");
            QFile batOut(bat);
            batOut.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
            QTextStream batTs(&batOut);
            batTs << "@echo off\n"
                  << "set DIR=%~dp0\n"
                  << "if exist \"%DIR%ladybird.exe\" (\n"
                  << "  start \"\" \"%DIR%ladybird.exe\" %*\n"
                  << ") else (\n"
                  << "  echo ERROR: ladybird.exe not found in %DIR%\n"
                  << "  pause\n"
                  << ")\n";
            batOut.close();
        }
        copyFile(payload.filePath(QStringLiteral("aurora.png")),
                 installDir + QLatin1String("/aurora.png"));
    } else {
        const QString appSrc = payload.filePath(QStringLiteral("Aurora Browser.app"));
        const QString appDst = QFileInfo(installDir).isAbsolute()
                                   ? installDir
                                   : installDir + QLatin1String("/Aurora Browser.app");
        if (QDir(appDst).exists()) {
            QDir(appDst).removeRecursively();
        }
        QDir().mkpath(QFileInfo(appDst).absolutePath());
        copyTree(appSrc, appDst);
    }
    return installDir;
}

void createShortcutsFor(const EngineTarget &target, const QString &installDir,
                        bool desktopShortcut, QStringList *created) {
    if (target.system == QLatin1String("linux")) {
        const QString appsDir =
            QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
        if (appsDir.isEmpty()) {
            return;
        }
        QDir().mkpath(appsDir);
        const QString desktop = appsDir + QLatin1String("/aurora-browser.desktop");
        QFile f(desktop);
        f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
        QTextStream ts(&f);
        ts << "[Desktop Entry]\n"
           << "Name=Aurora Browser\n"
           << "Comment=Aurora-based browser with auto-update\n"
           << "Exec=" << installDir << "/aurora-browser %U\n"
           << "Icon=" << installDir << "/aurora.png\n"
           << "Terminal=false\n"
           << "Type=Application\n"
           << "Categories=Network;WebBrowser;\n"
           << "MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;\n"
           << "StartupWMClass=Aurora-Browser\n";
        f.close();
        QFile::setPermissions(
            desktop, QFile::permissions(desktop) | QFileDevice::ExeOwner |
                         QFileDevice::ExeGroup | QFileDevice::ExeOther);
        if (created) {
            created->append(desktop);
        }
        if (desktopShortcut) {
            const QString userDesktop =
                QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
            if (!userDesktop.isEmpty() && QDir(userDesktop).exists()) {
                copyFile(desktop, userDesktop + QLatin1String("/aurora-browser.desktop"), true);
                if (created) {
                    created->append(userDesktop + QLatin1String("/aurora-browser.desktop"));
                }
            }
        }
        return;
    }

    if (target.system == QLatin1String("macos")) {
        if (created) {
            created->append(installDir);
        }
        return;
    }

    const QString startDir =
        QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    const QString script =
        QStringLiteral("$sh = New-Object -ComObject WScript.Shell; "
                       "$l = $sh.CreateShortcut($args[0]); "
                       "$l.TargetPath = $args[1]; "
                       "$l.WorkingDirectory = $args[2]; "
                       "$l.IconLocation = $args[3]; $l.Save()");
    const QString launcherPath = installDir + QLatin1String("/aurora-browser.exe");
    const QString pngPath = installDir + QLatin1String("/aurora.png");

    auto makeLnk = [&](const QString &lnkPath) {
        QProcess p;
        p.start(QStringLiteral("powershell"),
                {QStringLiteral("-NoProfile"), QStringLiteral("-ExecutionPolicy"),
                 QStringLiteral("Bypass"), QStringLiteral("-Command"), script, lnkPath,
                 launcherPath, installDir, pngPath});
        p.waitForFinished(30000);
        if (p.exitStatus() == QProcess::NormalExit && created) {
            created->append(lnkPath);
        }
    };

    if (!startDir.isEmpty()) {
        makeLnk(startDir + QLatin1String("/Aurora Browser.lnk"));
    }
    if (desktopShortcut) {
        const QString desktop =
            QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
        if (!desktop.isEmpty()) {
            makeLnk(desktop + QLatin1String("/Aurora Browser.lnk"));
        }
    }
}

void launchInstalled(const EngineTarget &target, const QString &installDir) {
    if (target.system == QLatin1String("linux")) {
        QProcess::startDetached(installDir + QLatin1String("/aurora-browser"));
    } else if (target.system == QLatin1String("windows")) {
        const QString exe = installDir + QLatin1String("/aurora-browser.exe");
        const QString bat = installDir + QLatin1String("/aurora-browser.bat");
        QProcess::startDetached(
            QStringLiteral("cmd"),
            {QStringLiteral("/c"), QStringLiteral("start"), QStringLiteral(""),
             QFile::exists(exe) ? exe : bat});
    } else {
        QProcess::startDetached(QStringLiteral("open"), {installDir});
    }
}

struct InstallProgress {
    const EngineTarget *target = nullptr;
    const QString *installDir = nullptr;
    bool shortcuts = true;
    ProgressFn progress;
};

InstallResult runInstall(const EngineTarget &target, const QString &installDir,
                         bool createShortcuts, const QByteArray &payloadZip,
                         const ProgressFn &progress) {
    InstallResult result;
    result.installDir = installDir;

    auto step = [&progress](int pct, const QString &msg) {
        if (progress) {
            progress(pct, msg);
        }
    };

    QString tag;
    QString url;
    if (!resolveEngine(target, &tag, &url)) {
        result.error = QStringLiteral("Could not determine an engine download URL.");
        return result;
    }

    step(5, QStringLiteral("Preparing install directory"));
    QDir().mkpath(installDir);

    step(10, QStringLiteral("Downloading Aurora Browser"));
    QTemporaryDir engineTmp;
    if (!engineTmp.isValid()) {
        result.error = QStringLiteral("Could not create a temporary directory.");
        return result;
    }
    const QString zipPath = engineTmp.filePath(QStringLiteral("engine.zip"));
    const QString err = downloadFile(url, zipPath, [&](qint64 done, qint64 total) {
        const int pct = total > 0 ? 10 + static_cast<int>(((done * 55) / total)) : 10;
        step(qBound(10, pct, 65), QStringLiteral("Downloading Aurora Browser"));
    });
    if (!err.isEmpty()) {
        result.error = QStringLiteral("Engine download failed: ") + err;
        return result;
    }

    step(70, QStringLiteral("Extracting engine"));
    const QString extractDir = engineTmp.filePath(QStringLiteral("engine"));
    const QString extractErr = extractArchive(zipPath, extractDir);
    if (!extractErr.isEmpty()) {
        result.error = QStringLiteral("Engine extraction failed: ") + extractErr;
        return result;
    }

    step(78, QStringLiteral("Locating engine"));
    QDir extract(extractDir);
    QString engineSrc;
    const QStringList dirs =
        extract.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &entry : dirs) {
        if (entry.contains(target.engineDir)) {
            engineSrc = extract.filePath(entry);
            break;
        }
    }
    if (engineSrc.isEmpty()) {
        result.error = QStringLiteral("Engine directory not found in the archive.");
        return result;
    }
    if (target.system == QLatin1String("macos")) {
        const QString app = engineSrc + QLatin1String("/Google Chrome for Testing.app");
        if (!QFile::exists(app) && !QFile::exists(engineSrc + QLatin1String("/chrome"))) {
            result.error = QStringLiteral("Engine binary not found in the archive.");
            return result;
        }
    } else if (!QFile::exists(engineSrc + QLatin1Char('/') + target.engineBin)) {
        result.error = QStringLiteral("Engine binary not found in the archive.");
        return result;
    }

    const QString engineDst = installDir + QLatin1Char('/') + target.engineDir;
    if (QDir(engineDst).exists()) {
        const QString oldDir = installDir + QLatin1String("/") + target.engineDir +
                               QLatin1String(".old");
        QDir(oldDir).removeRecursively();
        QDir(installDir).rename(target.engineDir,
                                target.engineDir + QLatin1String(".old"));
    }
    if (!QDir().rename(engineSrc, engineDst)) {
        copyTree(engineSrc, engineDst);
    }

    step(85, QStringLiteral("Installing app files"));
    QTemporaryDir payloadTmp;
    if (!payloadTmp.isValid()) {
        result.error = QStringLiteral("Could not create a temporary directory.");
        return result;
    }
    const QString zipBytes = payloadTmp.filePath(QStringLiteral("payload.zip"));
    if (payloadZip.size() <= 0) {
        result.error = QStringLiteral("Installer payload is missing.");
        return result;
    }
    QFile payloadZipFile(zipBytes);
    payloadZipFile.open(QIODevice::WriteOnly | QIODevice::Truncate);
    payloadZipFile.write(payloadZip);
    payloadZipFile.close();
    const QString payloadSrc = payloadTmp.filePath(QStringLiteral("payload"));
    const QString payloadErr = extractArchive(zipBytes, payloadSrc);
    if (!payloadErr.isEmpty()) {
        result.error = QStringLiteral("Payload extraction failed: ") + payloadErr;
        return result;
    }
    applyPayload(target, installDir, payloadSrc);

    const QString ver = engineVersion(engineDst, target);
    QFile vf(installDir + QLatin1String("/version.txt"));
    vf.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
    QTextStream(&vf) << "ENGINE_VERSION=" << tag << "\n";
    if (!ver.isEmpty()) {
        QTextStream(&vf) << "LIBWEB_VERSION=" << ver << "\n";
    }
    vf.close();

    step(92, QStringLiteral("Creating shortcuts"));
    createShortcutsFor(target, installDir, createShortcuts, &result.createdShortcuts);

    step(100, QStringLiteral("Done"));
    result.ok = true;
    return result;
}