#include "Gamepad.h"

#include "GamepadBackend.h"

#include <algorithm>
#include <chrono>

using awen::Gamepad;
using std::chrono::milliseconds;

Gamepad::Gamepad(QObject* parent) : QObject{parent}
{
    // The backend — SDL on desktop and wasm, inert on android — connects this
    // instance to the shared, engine-owned source; button and axis events arrive
    // re-emitted as this type's Button/Axis enums.
    awen::attachGamepad(this, parent);
}

auto Gamepad::qmlAttachedProperties(QObject* object) -> Gamepad*
{
    // The QML engine takes ownership of the attached instance (parents it to
    // @p object), so returning a raw new is the required Qt contract.
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
    return new Gamepad{object};
}

auto Gamepad::pollInterval() const -> int
{
    return static_cast<int>(pollInterval_.count());
}

auto Gamepad::setPollInterval(int intervalMs) -> void
{
    // Clamp before comparing so the stored value (and what the property reads
    // back) is the applied one.
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
