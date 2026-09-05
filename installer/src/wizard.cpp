#include "wizard.h"

#include <QCheckBox>
#include <QFileDialog>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QProgressBar>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWizard>

InstallWorker::InstallWorker(const EngineTarget &target, const QString &installDir,
                             bool shortcuts, const QByteArray &payloadZip)
    : m_target(target), m_installDir(installDir), m_shortcuts(shortcuts),
      m_payloadZip(payloadZip) {}

void InstallWorker::start() {
    const ProgressFn progress = [this](int percent, const QString &status) {
        emit this->progress(percent, status);
    };
    const InstallResult result =
        runInstall(m_target, m_installDir, m_shortcuts, m_payloadZip, progress);
    if (result.ok) {
        emit success(result.installDir, result.createdShortcuts);
    } else {
        emit failure(result.error);
    }
}

static const int kStartPageId = 2;
static const int kFinishPageId = 3;

class WelcomePage : public QWizardPage {
public:
    explicit WelcomePage(const QString &version) {
        setTitle(QStringLiteral("Welcome"));
        setSubTitle(QStringLiteral("This wizard installs Aurora Browser and "
                                   "downloads the LibWeb engine it runs on."));
        auto *layout = new QVBoxLayout(this);
        auto *name = new QLabel(QStringLiteral("Aurora Browser"));
        QFont f = name->font();
        f.setPointSize(f.pointSize() + 8);
        f.setBold(true);
        name->setFont(f);
        layout->addWidget(name);
        layout->addWidget(new QLabel(QStringLiteral("Version %1").arg(version)));
        layout->addWidget(new QLabel(
            QStringLiteral("Aurora Browser is built on the Ladybird LibWeb engine — "
                           "a custom open-source rendering engine with no Chromium "
                           "or Firefox dependency.\n\n"
                           "The engine is downloaded during installation. You can go "
                           "back and change the install location on the next screen.")));
        layout->addStretch();
#ifdef Q_OS_MACOS
        layout->addWidget(new QLabel(QStringLiteral("Detected platform: macOS")));
#elif defined(Q_OS_WIN)
        layout->addWidget(new QLabel(QStringLiteral("Detected platform: Windows")));
#else
        layout->addWidget(new QLabel(QStringLiteral("Detected platform: Linux")));
#endif
    }
};

class DestinationPage : public QWizardPage {
public:
    explicit DestinationPage(const QString &defaultDir) {
        setTitle(QStringLiteral("Installation directory"));
        setSubTitle(QStringLiteral("Choose where Aurora Browser and its engine "
                                   "will be installed."));
        auto *layout = new QVBoxLayout(this);
        layout->addWidget(new QLabel(QStringLiteral("Install to:")));
        m_dir = new QLineEdit(defaultDir);
        layout->addWidget(m_dir);
        auto *browse = new QPushButton(QStringLiteral("Browse..."));
        connect(browse, &QPushButton::clicked, this, [this]() {
            const QString dir = QFileDialog::getExistingDirectory(
                this, QStringLiteral("Choose installation directory"),
                QFileInfo(m_dir->text()).absolutePath());
            if (!dir.isEmpty()) {
                m_dir->setText(dir);
            }
        });
        layout->addWidget(browse, 0, Qt::AlignLeft);
        m_shortcuts = new QCheckBox(
            QStringLiteral("Create shortcuts (app menu and desktop)"));
        m_shortcuts->setChecked(true);
#ifdef Q_OS_MACOS
        m_shortcuts->setEnabled(false);
        m_shortcuts->setChecked(true);
#endif
        layout->addWidget(m_shortcuts);
        layout->addStretch();
        registerField(QStringLiteral("installDir*"), m_dir);
        registerField(QStringLiteral("shortcuts"), m_shortcuts);
    }

    QLineEdit *m_dir = nullptr;
    QCheckBox *m_shortcuts = nullptr;
};

class ProgressPage : public QWizardPage {
public:
    explicit ProgressPage() {
        setTitle(QStringLiteral("Installing"));
        setSubTitle(QStringLiteral("Please wait while Aurora Browser is set up."));
        auto *layout = new QVBoxLayout(this);
        layout->addStretch();
        m_status = new QLabel(QStringLiteral("Preparing..."));
        m_status->setAlignment(Qt::AlignCenter);
        layout->addWidget(m_status);
        m_bar = new QProgressBar();
        m_bar->setRange(0, 100);
        m_bar->setValue(0);
        m_bar->setTextVisible(true);
        layout->addWidget(m_bar);
        layout->addStretch();
    }

    void setProgress(int percent, const QString &status) {
        m_status->setText(status);
        m_bar->setValue(percent);
    }

    QLabel *m_status = nullptr;
    QProgressBar *m_bar = nullptr;
};

class FinishPage : public QWizardPage {
public:
    explicit FinishPage(Wizard *ctrl) {
        setTitle(QStringLiteral("Completing installation"));
        setSubTitle(QStringLiteral("Aurora Browser has been installed."));
        auto *layout = new QVBoxLayout(this);
        m_text = new QLabel();
        m_text->setWordWrap(true);
        layout->addWidget(m_text);
        auto *launch = new QPushButton(QStringLiteral("Launch Aurora Browser"));
        launch->setAutoDefault(false);
        connect(launch, &QPushButton::clicked, ctrl, &Wizard::launch);
        layout->addWidget(launch, 0, Qt::AlignLeft);
        layout->addStretch();
    }

    void setResult(const QString &dir) {
        m_text->setText(QStringLiteral("Aurora Browser was installed to:\n%1\n\n"
                                       "Click \"Launch Aurora Browser\" to start "
                                       "it now, or find it in your app menu.")
                            .arg(dir));
    }

    QLabel *m_text = nullptr;
};

class Wizard::QWizardWindow : public QWizard {
public:
    QWizardWindow(Wizard *ctrl, const QString &version)
        : m_ctrl(ctrl), m_defaultDir(defaultInstallDir(currentTarget())) {
        setWindowTitle(QStringLiteral("Aurora Browser Installer"));
        setWizardStyle(ModernStyle);
        setOption(QWizard::NoBackButtonOnStartPage, true);
        addPage(new WelcomePage(version));
        addPage(new DestinationPage(m_defaultDir));
        m_progress = new ProgressPage();
        addPage(m_progress);
        m_finish = new FinishPage(ctrl);
        addPage(m_finish);
        ctrl->m_window = this;
    }

    void initializePage(int id) override {
        QWizard::initializePage(id);
        if (id == kStartPageId) {
            button(QWizard::BackButton)->setEnabled(false);
            button(QWizard::NextButton)->setEnabled(false);
            m_ctrl->startInstall(field(QStringLiteral("installDir")).toString(),
                                 field(QStringLiteral("shortcuts")).toBool());
        }
        if (id == kFinishPageId) {
            m_finish->setResult(m_ctrl->m_result.installDir);
        }
    }

    int nextId() const override {
        if (currentId() == kStartPageId && !m_ctrl->m_installFinished) {
            return -1;
        }
        return QWizard::nextId();
    }

    bool validateCurrentPage() override {
        if (currentId() == kStartPageId && !m_ctrl->m_installFinished) {
            return false;
        }
        return QWizard::validateCurrentPage();
    }

    ProgressPage *m_progress = nullptr;
    FinishPage *m_finish = nullptr;
    Wizard *m_ctrl = nullptr;
    QString m_defaultDir;
};

Wizard::Wizard(const QByteArray &payloadZip, const QString &version)
    : m_payloadZip(payloadZip), m_version(version), m_target(currentTarget()) {}

Wizard::~Wizard() {
    if (m_worker) {
        m_worker->disconnect();
        m_thread.quit();
        m_thread.wait(5000);
        m_worker->deleteLater();
    }
}

void Wizard::exec() {
    if (m_thread.isRunning()) {
        return;
    }
    m_window = new Wizard::QWizardWindow(this, m_version);
    connect(m_window, &QDialog::finished, this, [this]() {
        if (m_worker) {
            m_worker->disconnect();
        }
        if (m_thread.isRunning()) {
            m_thread.quit();
            m_thread.wait(5000);
        }
    });
    m_window->setMinimumSize(560, 420);
    m_window->resize(560, 420);
    m_window->show();
}

void Wizard::startInstall(const QString &installDir, bool shortcuts) {
    if (m_worker || m_thread.isRunning()) {
        return;
    }
    m_worker = new InstallWorker(m_target, installDir, shortcuts, m_payloadZip);
    m_worker->moveToThread(&m_thread);
    m_thread.start();

    connect(m_worker, &InstallWorker::progress, this,
            [this](int percent, const QString &status) {
                if (m_window) {
                    m_window->m_progress->setProgress(percent, status);
                }
            });
    connect(m_worker, &InstallWorker::success, this, &Wizard::onSuccess);
    connect(m_worker, &InstallWorker::failure, this, &Wizard::onFailure);
    QMetaObject::invokeMethod(m_worker, "start", Qt::QueuedConnection);
}

void Wizard::onSuccess(const QString &installDir, const QStringList &shortcuts) {
    m_result.installDir = installDir;
    m_result.createdShortcuts = shortcuts;
    m_result.ok = true;
    if (!m_installFinished) {
        m_installFinished = true;
        if (m_window) {
            m_window->button(QWizard::NextButton)->setEnabled(true);
            m_window->next();
        }
    }
}

void Wizard::onFailure(const QString &error) {
    if (m_window) {
        m_window->button(QWizard::BackButton)->setEnabled(true);
        QMessageBox::critical(m_window, QStringLiteral("Installation failed"),
                              QStringLiteral(
                                  "Aurora Browser could not be installed:\n\n%1")
                                  .arg(error));
        m_installFinished = false;
        m_window->restart();
    }
}

void Wizard::launch() {
    launchInstalled(m_target, m_result.installDir);
}