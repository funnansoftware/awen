#include "BuildInfo.h"

#include "awen_build_version.h" // awen::BuildVersion, stamped at build time.

using awen::BuildInfo;

BuildInfo::BuildInfo(QObject* parent) : QObject{parent}, version_{QString::fromUtf8(BuildVersion)}
{
}

auto BuildInfo::version() const -> QString
{
    return version_;
}
