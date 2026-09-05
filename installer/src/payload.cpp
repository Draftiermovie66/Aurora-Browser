#include "payload.h"

#include <QCoreApplication>
#include <QFile>
#include <QtEndian>
#include <cstring>

namespace {

constexpr qint64 FOOTER_SIZE = 8 + 8 + 32 + 8;
const char MAGIC_A[] = "AURPAYLD";
const char MAGIC_B[] = "DLYAPRUA";

}

namespace PayloadInfo {

std::optional<Info> load() {
    QFile f(QCoreApplication::applicationFilePath());
    if (!f.open(QIODevice::ReadOnly)) {
        return std::nullopt;
    }
    const qint64 fileSize = f.size();
    if (fileSize < FOOTER_SIZE) {
        return std::nullopt;
    }

    const qint64 footerStart = fileSize - FOOTER_SIZE;
    f.seek(footerStart);
    const QByteArray footer = f.read(FOOTER_SIZE);
    if (footer.size() != FOOTER_SIZE) {
        return std::nullopt;
    }

    if (std::memcmp(footer.constData() + 8, MAGIC_A, 8) != 0 ||
        std::memcmp(footer.constData() + FOOTER_SIZE - 8, MAGIC_B, 8) != 0) {
        return std::nullopt;
    }

    const quint64 payloadSize =
        qFromLittleEndian<quint64>(reinterpret_cast<const uchar *>(footer.constData()));
    if (payloadSize == 0 || payloadSize > 512ULL * 1024 * 1024) {
        return std::nullopt;
    }
    const qint64 zipStart = footerStart - static_cast<qint64>(payloadSize);
    if (zipStart < 0) {
        return std::nullopt;
    }

    QByteArray version(32, '\0');
    std::memcpy(version.data(), footer.constData() + 16, 32);
    const int nul = version.indexOf('\0');
    if (nul >= 0) {
        version.truncate(nul);
    }

    f.seek(zipStart);
    const QByteArray zip = f.read(static_cast<qint64>(payloadSize));
    if (zip.size() != static_cast<qint64>(payloadSize)) {
        return std::nullopt;
    }

    Info info;
    info.version = QString::fromUtf8(version);
    info.zipBytes = zip;
    return info;
}

}