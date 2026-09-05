#pragma once

#include "engine.h"
#include "install.h"

#include <QByteArray>
#include <QObject>
#include <QThread>

class InstallWorker : public QObject {
    Q_OBJECT
public:
    InstallWorker(const EngineTarget &target, const QString &installDir,
                  bool shortcuts, const QByteArray &payloadZip);

public slots:
    void start();

signals:
    void progress(int percent, const QString &status);
    void success(const QString &installDir, const QStringList &shortcuts);
    void failure(const QString &error);

private:
    EngineTarget m_target;
    QString m_installDir;
    bool m_shortcuts = true;
    QByteArray m_payloadZip;
};

class Wizard : public QObject {
    Q_OBJECT
public:
    Wizard(const QByteArray &payloadZip, const QString &version);
    ~Wizard() override;

    void exec();

public slots:
    void onSuccess(const QString &installDir, const QStringList &shortcuts);
    void onFailure(const QString &error);
    void launch();

private:
    QByteArray m_payloadZip;
    QString m_version;
    EngineTarget m_target;

    QThread m_thread;
    InstallWorker *m_worker = nullptr;
    InstallResult m_result;
    bool m_installFinished = false;

    void startInstall(const QString &installDir, bool shortcuts);

    class QWizardWindow;
    friend class QWizardWindow;
    QWizardWindow *m_window = nullptr;
};