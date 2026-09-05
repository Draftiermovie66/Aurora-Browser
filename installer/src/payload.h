#pragma once

#include <QString>
#include <QByteArray>
#include <optional>

namespace PayloadInfo {

struct Info {
    QString version;
    QByteArray zipBytes;
};

std::optional<Info> load();

}