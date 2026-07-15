#include <quick/GameController.hpp>

#include <Qt>

#include <Briarthorn.hpp>
#include <game/CommandBuffer.hpp>
#include <game/Entity.hpp>

using bt::quick::GameController;

GameController::GameController(Briarthorn& briarthorn, QObject* parent) : QObject{parent}, briarthorn_{briarthorn}
{
}

auto GameController::world() const -> const bt::game::World&
{
    return briarthorn_.world();
}

auto GameController::setKey(int key, bool down) -> void
{
    if (down)
    {
        held_.insert(key);
    }
    else
    {
        held_.remove(key);
    }
}

auto GameController::releaseKeys() -> void
{
    held_.clear();
}

auto GameController::frame() -> void
{
    // The same device→intent mapping as raylib's pollInput, from the held-key
    // set Qt's key events maintain instead of a per-frame IsKeyDown poll.
    if (const auto player = briarthorn_.world().getPlayer(); player != game::NullEntity)
    {
        const auto held = [this](Qt::Key key) { return held_.contains(key); };
        const auto forward = held(Qt::Key_W) || held(Qt::Key_Up);
        const auto backward = held(Qt::Key_S) || held(Qt::Key_Down);
        const auto left = held(Qt::Key_A) || held(Qt::Key_Left);
        const auto right = held(Qt::Key_D) || held(Qt::Key_Right);
        const auto boost = held(Qt::Key_Shift);

        auto& commands = briarthorn_.commands();
        commands.throttle(player, forward ? 1.0F : 0.0F);
        commands.brake(player, backward ? 1.0F : 0.0F);
        commands.steer(player, (right ? 1.0F : 0.0F) - (left ? 1.0F : 0.0F));
        commands.boost(player, boost ? 1.0F : 0.0F);
    }

    // The simulation advances on its own fixed clock, decoupled from the frame rate.
    briarthorn_.update();

    emit stepped();
}
