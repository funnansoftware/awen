#include <gtest/gtest.h>

#include <game/CommandBuffer.hpp>
#include <game/Entity.hpp>
#include <game/Heading.hpp>
#include <game/World.hpp>
#include <game/systems/Movement.hpp>

namespace
{
    using bt::game::CommandBuffer;
    using bt::game::Entity;
    using bt::game::Heading;
    using bt::game::Movement;
    using bt::game::World;

    TEST(MovementTest, ThrottleAcceleratesAlongHeading)
    {
        auto world = World{};
        auto entity = Entity{};
        entity.heading = Heading{90.0F}; // due east: +x
        entity.controls.throttle = 1.0F;
        entity.limits.acceleration = 50.0F; // distinct from the other limits
        const auto id = world.spawn(entity);

        auto movement = Movement{};
        movement.update(world, 1.0F); // one second

        const auto* out = world.find(id);
        ASSERT_NE(out, nullptr);
        EXPECT_FLOAT_EQ(out->speed, 50.0F);        // full throttle * the acceleration limit
        EXPECT_GT(out->position.x, 0.0F);          // moved east
        EXPECT_NEAR(out->position.y, 0.0F, 1e-2F); // not north/south
    }

    TEST(MovementTest, SteerTurnsWithinTheRate)
    {
        auto world = World{};
        auto entity = Entity{};
        entity.controls.steer = 1.0F; // full right
        entity.limits.turnRate = 90.0F;
        const auto id = world.spawn(entity);

        auto movement = Movement{};
        movement.update(world, 0.5F);

        EXPECT_FLOAT_EQ(world.find(id)->heading.degrees(), 45.0F); // 90 deg/s * 0.5 s
    }

    TEST(MovementTest, BrakeDeceleratesAndFloorsAtZero)
    {
        auto world = World{};
        auto entity = Entity{};
        entity.speed = 100.0F;
        const auto id = world.spawn(entity);

        auto commands = CommandBuffer{};
        commands.brake(id, 5.0F); // over-range -> clamps to 1
        commands.flush(world);
        EXPECT_FLOAT_EQ(world.find(id)->controls.brake, 1.0F);

        auto movement = Movement{};
        movement.update(world, 0.5F);
        EXPECT_FLOAT_EQ(world.find(id)->speed, 40.0F); // 100 - 120 m/s^2 * 0.5 s

        movement.update(world, 0.5F);
        EXPECT_FLOAT_EQ(world.find(id)->speed, 0.0F); // floors at zero
    }

    TEST(MovementTest, BoostLiftsTheTopSpeedCeiling)
    {
        auto world = World{};
        const auto id = world.spawn(Entity{});

        auto commands = CommandBuffer{};
        commands.throttle(id, 1.0F);
        commands.boost(id, 1.0F);
        commands.flush(world);

        auto movement = Movement{};
        movement.update(world, 1.0F);
        movement.update(world, 1.0F);
        movement.update(world, 1.0F); // enough to hit the boosted ceiling

        // At full boost the ceiling is limits.topSpeed * Movement's 1.6
        // afterburner multiplier.
        const auto* out = world.find(id);
        ASSERT_NE(out, nullptr);
        EXPECT_FLOAT_EQ(out->speed, out->limits.topSpeed * 1.6F);

        commands.boost(id, 0.0F); // release the afterburner
        commands.flush(world);
        movement.update(world, 1.0F);

        EXPECT_FLOAT_EQ(world.find(id)->speed, out->limits.topSpeed); // re-clamped
    }

    TEST(MovementTest, ControlsStayLatchedAcrossSteps)
    {
        auto world = World{};
        const auto id = world.spawn(Entity{});

        auto commands = CommandBuffer{};
        commands.throttle(id, 1.0F);
        commands.flush(world); // one flush; no further commands

        auto movement = Movement{};
        movement.update(world, 0.5F);
        const auto speedAfterOneStep = world.find(id)->speed;
        movement.update(world, 0.5F); // the lever persists until countermanded

        EXPECT_GT(speedAfterOneStep, 0.0F);
        EXPECT_GT(world.find(id)->speed, speedAfterOneStep);
    }
}
