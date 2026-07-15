#include <game/World.hpp>

using bt::game::Entity;
using bt::game::EntityId;
using bt::game::World;

auto World::spawn(Entity entity) -> EntityId
{
    const auto id = nextId_++;
    if (nextId_ == NullEntity)
    {
        nextId_ = 1; // never hand out the null id after a 32-bit wrap
    }
    entity.id = id;
    entities_.push_back(entity);
    return id;
}

auto World::despawn(EntityId id) -> bool
{
    for (auto it = entities_.begin(); it != entities_.end(); ++it)
    {
        if (it->id == id)
        {
            entities_.erase(it);
            return true;
        }
    }
    return false;
}

auto World::find(EntityId id) -> Entity*
{
    for (auto& entity : entities_)
    {
        if (entity.id == id)
        {
            return &entity;
        }
    }
    return nullptr;
}

auto World::find(EntityId id) const -> const Entity*
{
    for (const auto& entity : entities_)
    {
        if (entity.id == id)
        {
            return &entity;
        }
    }
    return nullptr;
}

auto World::entities() -> std::vector<Entity>&
{
    return entities_;
}

auto World::entities() const -> const std::vector<Entity>&
{
    return entities_;
}

auto World::getPlayer() const -> EntityId
{
    return player_;
}

auto World::setPlayer(EntityId id) -> void
{
    player_ = id;
}
