#pragma once

#include <game/System.hpp>

namespace bt::game
{
    struct Entity;

    /// @brief The kinematic engine. Each step it advances every entity from its
    /// latched Controls within its Limits.
    class Movement : public System
    {
    public:
        auto update(World& world, float dt) -> void override;

    private:
        static auto advance(Entity& entity, float dt) -> void;
    };
}
