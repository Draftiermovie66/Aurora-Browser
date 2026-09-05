#include "payload.h"
#include "engine.h"
#include "install.h"
#include "wizard.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QMessageBox>

#include <cstdio>

static int runCli(const QStringList &arguments) {
    QCommandLineParser parser;
    parser.setApplicationDescription(
        QStringLiteral("Install Aurora Browser on Windows, macOS, or Linux."));
    parser.addHelpOption();
    const QCommandLineOption installDirOption(
        {QStringLiteral("install-dir")},
        QStringLiteral("Installation directory"), QStringLiteral("path"));
    parser.addOption(installDirOption);
    const QCommandLineOption noShortcutsOption(QStringLiteral("no-shortcuts"));
    const QCommandLineOption launchOption(QStringLiteral("launch"));
    const QCommandLineOption quietOption(QStringLiteral("quiet"));
    const QCommandLineOption versionOption(QStringLiteral("version"));
    parser.addOption(noShortcutsOption);
    parser.addOption(launchOption);
    parser.addOption(quietOption);
    parser.addOption(versionOption);
    parser.process(arguments);

    const auto payload = PayloadInfo::load();
    if (!payload) {
        fprintf(stderr, "ERROR: installer payload is missing from this binary.\n");
        return 2;
    }

    if (parser.isSet(versionOption)) {
        printf("%s\n", qPrintable(payload->version));
        return 0;
    }

    const EngineTarget target = currentTarget();
    QString installDir = parser.value(installDirOption);
    if (installDir.isEmpty()) {
        installDir = defaultInstallDir(target);
    }
    const bool quiet = parser.isSet(quietOption);

    printf("Aurora Browser installer %s (%s)\n", qPrintable(payload->version),
           qPrintable(target.system));
    printf("Target directory: %s\n", qPrintable(installDir));

    const ProgressFn progress = [quiet](int percent, const QString &status) {
        if (!quiet) {
            printf("  [%3d%%] %s\n", percent, qPrintable(status));
            fflush(stdout);
        }
    };

    const InstallResult result =
        runInstall(target, installDir, !parser.isSet(noShortcutsOption),
                   payload->zipBytes, progress);

    if (!result.ok) {
        fprintf(stderr, "ERROR: %s\n", qPrintable(result.error));
        return 1;
    }

    printf("\nInstall complete!\n");
    printf("  Installed to: %s\n", qPrintable(result.installDir));
    for (const QString &s : result.createdShortcuts) {
        printf("  Shortcut:     %s\n", qPrintable(s));
    }
    if (parser.isSet(launchOption)) {
        launchInstalled(target, result.installDir);
        printf("  Launched Aurora Browser.\n");
    }
    return 0;
}

int main(int argc, char **argv) {
    bool cli = false;
    for (int i = 1; i < argc; ++i) {
        if (argv[i][0] == QLatin1Char('-')) {
            cli = true;
            break;
        }
    }

    if (cli) {
        QCoreApplication app(argc, argv);
        QCoreApplication::setApplicationName(QStringLiteral("aurora-installer"));
        return runCli(app.arguments());
    }

    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("aurora-installer"));

    const auto payload = PayloadInfo::load();
    if (!payload) {
        QMessageBox::critical(
            nullptr, QStringLiteral("Aurora Browser Installer"),
            QStringLiteral("The installer payload is missing from this binary."));
        return 2;
    }

    Wizard wizard(payload->zipBytes, payload->version);
    wizard.exec();
    return app.exec();
}