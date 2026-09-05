#include "engine.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QEventLoop>
#include <QTimer>
#include <QProcess>
#include <QDir>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QRegularExpression>

const char *kUserAgent = "AuroraBrowser-Installer/3.0";
const char *kRepo = "Draftiermovie66/Aurora-Browser";

bool looksLikeWindows() {
#ifdef Q_OS_WIN
    return true;
#else
    return false;
#endif
}

QString exeSuffix() {
#ifdef Q_OS_WIN
    return ".exe";
#else
    return {};
#endif
}

QString platformLabel() {
#ifdef Q_OS_WIN
    return QStringLiteral("windows-x86_64");
#elif defined(Q_OS_MACOS)
#if defined(Q_PROCESSOR_ARM)
    return QStringLiteral("macos-arm64");
#else
    return QStringLiteral("macos-x86_64");
#endif
#else
    return QStringLiteral("linux-x86_64");
#endif
}

EngineTarget currentTarget() {
#ifdef Q_OS_WIN
    return {QStringLiteral("windows"), QStringLiteral("win"),
            {QStringLiteral("win"), QStringLiteral("windows")},
            QStringLiteral("ladybird"), QStringLiteral("ladybird.exe")};
#elif defined(Q_OS_MACOS)
#if defined(Q_PROCESSOR_ARM)
    return {QStringLiteral("macos"), QStringLiteral("macos"),
            {QStringLiteral("macos"), QStringLiteral("mac-arm64")},
            QStringLiteral("Aurora Browser.app"), {}};
#else
    return {QStringLiteral("macos"), QStringLiteral("macos"),
            {QStringLiteral("macos"), QStringLiteral("mac-x86_64")},
            QStringLiteral("Aurora Browser.app"), {}};
#endif
#else
    return {QStringLiteral("linux"), QStringLiteral("linux"),
            {QStringLiteral("linux"), QStringLiteral("linux-x86_64")},
            QStringLiteral("ladybird"), QStringLiteral("ladybird")};
#endif
}

QString httpGetString(const QUrl &url, int timeoutMs, QString *error) {
    QNetworkAccessManager nam;
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QString::fromUtf8(kUserAgent));
    QNetworkReply *reply = nam.get(req);

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);
    bool timedOut = false;
    QObject::connect(&timer, &QTimer::timeout, &loop, [&loop, &timedOut]() {
        timedOut = true;
        loop.quit();
    });
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    timer.start(timeoutMs);
    loop.exec();
    timer.stop();

    QByteArray data;
    if (timedOut) {
        if (error) {
            *error = QStringLiteral("HTTP request timed out");
        }
    } else if (reply->error() != QNetworkReply::NoError) {
        if (error) {
            *error = reply->errorString();
        }
    } else {
        data = reply->readAll();
    }
    reply->deleteLater();
    return data;
}

QString downloadFile(const QUrl &url, const QString &dest,
                     const std::function<void(qint64, qint64)> &progress) {
    QNetworkAccessManager nam;
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QString::fromUtf8(kUserAgent));
    QNetworkReply *reply = nam.get(req);

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);
    bool timedOut = false;
    QObject::connect(&timer, &QTimer::timeout, &loop, [&loop, &timedOut]() {
        timedOut = true;
        loop.quit();
    });
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);

    QString partial = dest + QStringLiteral(".part");
    QFile out(partial);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        reply->abort();
        return QStringLiteral("cannot write ") + partial;
    }

    const auto onProgress = [&progress](qint64 done, qint64 total) {
        if (progress) {
            progress(done, total);
        }
    };
    QObject::connect(reply, &QNetworkReply::downloadProgress, &loop,
                     [onProgress](qint64 done, qint64 total) { onProgress(done, total); });
    QObject::connect(reply, &QNetworkReply::readyRead, &loop,
                     [&out, reply]() { out.write(reply->readAll()); });

    timer.start(600000);
    loop.exec();
    timer.stop();

    if (timedOut) {
        out.close();
        QFile::remove(partial);
        reply->deleteLater();
        return QStringLiteral("download timed out");
    }

    if (reply->error() != QNetworkReply::NoError) {
        const QString err = reply->errorString();
        out.close();
        QFile::remove(partial);
        reply->deleteLater();
        return err;
    }
    out.write(reply->readAll());
    out.close();
    reply->deleteLater();

    QFile::remove(dest);
    if (!QFile::rename(partial, dest)) {
        return QStringLiteral("cannot move downloaded file into place");
    }
    return {};
}

bool resolveEngine(const EngineTarget &target, QString *tag, QString *url) {
    const QByteArray overrideUrl = qgetenv("AURORA_ENGINE_URL");
    if (!overrideUrl.isEmpty()) {
        const QByteArray overrideTag = qgetenv("AURORA_ENGINE_TAG");
        *tag = overrideTag.isEmpty() ? QStringLiteral("custom") : QString::fromUtf8(overrideTag);
        *url = QString::fromUtf8(overrideUrl);
        return true;
    }

    // Fetch latest release from Aurora Browser GitHub
    const QUrl api(QStringLiteral("https://api.github.com/repos/") +
                   QString::fromUtf8(kRepo) + QStringLiteral("/releases/latest"));
    QString err;
    const QJsonDocument doc =
        QJsonDocument::fromJson(httpGetString(api, 20000, &err).toUtf8());
    const QJsonObject obj = doc.object();
    const QString version = obj.value(QStringLiteral("tag_name")).toString();
    if (!version.isEmpty()) {
        const QJsonArray assets = obj.value(QStringLiteral("assets")).toArray();
        for (const auto &value : assets) {
            const QJsonObject asset = value.toObject();
            const QString name = asset.value(QStringLiteral("name")).toString().toLower();
            for (const QString &suffix : target.ghSuffixes) {
                if (name.contains(suffix.toLower())) {
                    const QString downloadUrl =
                        asset.value(QStringLiteral("browser_download_url")).toString();
                    if (!downloadUrl.isEmpty()) {
                        *tag = version;
                        *url = downloadUrl;
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

static bool isTarArchive(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return false;
    // tar files have 'ustar' at offset 257
    f.seek(257);
    QByteArray magic = f.read(5);
    return magic == "ustar";
}

QString extractArchive(const QString &archivePath, const QString &destDir) {
    QDir().mkpath(destDir);

    if (archivePath.endsWith(".zip") || archivePath.endsWith(".ZIP")) {
        // ZIP extraction
        if (!looksLikeWindows()) {
            if (QStandardPaths::findExecutable(QStringLiteral("unzip")).isEmpty()) {
                return QStringLiteral("'unzip' is required but was not found");
            }
            QProcess p;
            p.start(QStringLiteral("unzip"), {QStringLiteral("-qo"), archivePath,
                                              QStringLiteral("-d"), destDir});
            p.waitForFinished(-1);
            if (p.exitCode() != 0) {
                return QStringLiteral("unzip failed") +
                       QString::fromUtf8(p.readAllStandardError());
            }
            return {};
        }
        // Windows: use PowerShell
        QProcess p;
        p.start(QStringLiteral("powershell"),
                {QStringLiteral("-NoProfile"), QStringLiteral("-Command"),
                 QStringLiteral("Expand-Archive -Path '") + archivePath +
                     QStringLiteral("' -DestinationPath '") + destDir +
                     QStringLiteral("' -Force")});
        p.waitForFinished(-1);
        return p.exitCode() == 0 ? QString{}
                                 : QStringLiteral("PowerShell Expand-Archive failed");
    }

    // TAR/BZ2/GZ/XZ extraction
    if (isTarArchive(archivePath)) {
        if (QStandardPaths::findExecutable(QStringLiteral("tar")).isEmpty()) {
            return QStringLiteral("'tar' is required but was not found");
        }
        QProcess p;
        p.start(QStringLiteral("tar"), {QStringLiteral("-xf"), archivePath,
                                        QStringLiteral("-C"), destDir});
        p.waitForFinished(-1);
        return p.exitCode() == 0 ? QString{} : QStringLiteral("tar extraction failed");
    }

    // DMG (macOS)
    if (archivePath.endsWith(".dmg") || archivePath.endsWith(".DMG")) {
#ifdef Q_OS_MACOS
        // Mount DMG, copy contents, detach
        QTemporaryDir tmpMount;
        QString mountPoint = tmpMount.filePath("dmg");
        QDir().mkpath(mountPoint);
        QProcess mount;
        mount.start("hdiutil",
                    {"attach", archivePath, "-mountpoint", mountPoint, "-nobrowse",
                     "-quiet"});
        mount.waitForFinished(-1);
        if (mount.exitCode() != 0) {
            return QStringLiteral("hdiutil attach failed");
        }
        // Copy everything from mount to destDir
        QDir srcDir(mountPoint);
        for (const QString &entry :
             srcDir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot)) {
            QFile::copy(srcDir.filePath(entry), destDir + "/" + entry);
        }
        QProcess detach;
        detach.start("hdiutil", {"detach", mountPoint, "-quiet"});
        detach.waitForFinished(-1);
        return {};
#else
        return QStringLiteral("DMG extraction only supported on macOS");
#endif
    }

    return QStringLiteral("Unsupported archive format: ") + archivePath;
}

QString engineVersion(const QString &engineDir, const EngineTarget &target) {
    QStringList bin;
    if (target.system == QLatin1String("macos")) {
        // Ladybird on macOS is an .app bundle
        const QString appPath = engineDir + QDir::separator() +
                                QStringLiteral("Aurora Browser.app") +
                                QDir::separator() + QStringLiteral("Contents") +
                                QDir::separator() + QStringLiteral("MacOS") +
                                QDir::separator() + QStringLiteral("ladybird");
        const QString alt = engineDir + QDir::separator() + QStringLiteral("ladybird");
        bin << (QFile::exists(appPath) ? appPath : alt)
            << QStringLiteral("--version");
    } else {
        bin << engineDir + QDir::separator() + target.engineBin
            << QStringLiteral("--version");
    }
    QProcess p;
    p.start(bin.first(), bin.mid(1));
    p.waitForFinished(60000);
    const QString out = QString::fromUtf8(p.readAllStandardOutput()) +
                        QString::fromUtf8(p.readAllStandardError());
    // Ladybird version format: "Ladybird 0.x.x" or similar
    static const QRegularExpression re(QStringLiteral("(\\d+\\.\\d+(?:\\.\\d+)?)"));
    const QRegularExpressionMatch m = re.match(out);
    return m.hasMatch() ? m.captured(0) : QString();
}
