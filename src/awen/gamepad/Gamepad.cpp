#include "Gamepad.h"

#include "GamepadBackend.h"

#include <algorithm>
#include <chrono>

using awen::Gamepad;
using std::chrono::milliseconds;

Gamepad::Gamepad(QObject* parent) : QObject{parent}
{
    // The platform backend connects this instance to the shared engine-owned source.
    awen::attachGamepad(this, parent);
}

auto Gamepad::qmlAttachedProperties(QObject* object) -> Gamepad*
{
    // The QML engine takes ownership of the attached instance.
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
    return new Gamepad{object};
}

auto Gamepad::pollInterval() const -> int
{
    return static_cast<int>(pollInterval_.count());
}

auto Gamepad::setPollInterval(int intervalMs) -> void
{
    // Clamp before comparing so the property reads back the applied value.
    const auto interval = milliseconds{std::max(1, intervalMs)};
    if (interval == pollInterval_)
    {
        return;
    }
    pollInterval_ = interval;
    emit pollIntervalChanged();
}

auto Gamepad::idlePollInterval() const -> int
{
    return static_cast<int>(idlePollInterval_.count());
}

auto Gamepad::setIdlePollInterval(int intervalMs) -> void
{
    const auto interval = milliseconds{std::max(1, intervalMs)};
    if (interval == idlePollInterval_)
    {
        return;
    }
    idlePollInterval_ = interval;
    emit idlePollIntervalChanged();
}
