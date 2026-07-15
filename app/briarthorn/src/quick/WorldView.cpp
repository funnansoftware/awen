#include <quick/WorldView.hpp>

#include <QKeyEvent>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>

#include <game/Entity.hpp>
#include <game/Geo.hpp>
#include <game/Vec2.hpp>
#include <game/World.hpp>

using bt::quick::WorldView;

namespace
{
    // Marker geometry (metres): a small triangle pointing along the heading.
    // Mirrors the raylib Renderer so both edges draw the same picture.
    constexpr auto MarkerNose = 12.0F;
    constexpr auto MarkerTail = 9.0F;
    constexpr auto MarkerTailAngle = 140.0F; // heading offset to each tail corner (deg)
    constexpr auto Half = 0.5F;

    // raylib's ORANGE (the player) and SKYBLUE (everything else).
    struct Rgba
    {
        unsigned char r, g, b, a;
    };

    constexpr auto PlayerColor = Rgba{.r = 255, .g = 161, .b = 0, .a = 255};
    constexpr auto MarkerColor = Rgba{.r = 102, .g = 191, .b = 255, .a = 255};

    constexpr auto VerticesPerMarker = 3;
}

WorldView::WorldView(QQuickItem* parent) : QQuickItem{parent}
{
    setFlag(ItemHasContents);
}

auto WorldView::game() const -> bt::quick::GameController*
{
    return game_;
}

auto WorldView::setGame(GameController* game) -> void
{
    if (game == game_)
    {
        return;
    }
    if (game_ != nullptr)
    {
        disconnect(game_, nullptr, this, nullptr);
    }
    game_ = game;
    if (game_ != nullptr)
    {
        // Repaint after every simulation step — the render loop's pull.
        connect(game_, &GameController::stepped, this, &QQuickItem::update);
    }
    emit gameChanged();
    update();
}

auto WorldView::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* /*data*/) -> QSGNode*
{
    auto* node = static_cast<QSGGeometryNode*>(oldNode);

    const auto* world = game_ != nullptr ? &game_->world() : nullptr;
    const auto count = world != nullptr ? static_cast<int>(world->entities().size()) : 0;

    if (node == nullptr)
    {
        node = new QSGGeometryNode;
        auto* geometry = new QSGGeometry{QSGGeometry::defaultAttributes_ColoredPoint2D(), count * VerticesPerMarker};
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        auto* material = new QSGVertexColorMaterial;
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }
    else
    {
        node->geometry()->allocate(count * VerticesPerMarker);
    }

    if (world != nullptr)
    {
        // Ownship-centred camera: the player (if any) sits at the item's centre.
        auto camera = game::Vec2{};
        if (const auto* player = world->find(world->getPlayer()); player != nullptr)
        {
            camera = player->position;
        }
        const auto centerX = static_cast<float>(width()) * Half;
        const auto centerY = static_cast<float>(height()) * Half;

        auto* vertices = node->geometry()->vertexDataAsColoredPoint2D();
        auto index = 0;
        for (const auto& entity : world->entities())
        {
            const auto color = entity.id == world->getPlayer() ? PlayerColor : MarkerColor;
            const auto nose = entity.position + game::Geo::offset(entity.heading, MarkerNose);
            const auto tailLeft = entity.position + game::Geo::offset(entity.heading - MarkerTailAngle, MarkerTail);
            const auto tailRight = entity.position + game::Geo::offset(entity.heading + MarkerTailAngle, MarkerTail);

            for (const auto& corner : {nose, tailLeft, tailRight})
            {
                vertices[index].set(centerX + (corner.x - camera.x), centerY + (corner.y - camera.y), color.r, color.g, color.b, color.a);
                ++index;
            }
        }
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}

auto WorldView::keyPressEvent(QKeyEvent* event) -> void
{
    if (game_ == nullptr || event->isAutoRepeat())
    {
        QQuickItem::keyPressEvent(event);
        return;
    }
    game_->setKey(event->key(), true);
    event->accept();
}

auto WorldView::keyReleaseEvent(QKeyEvent* event) -> void
{
    if (game_ == nullptr || event->isAutoRepeat())
    {
        QQuickItem::keyReleaseEvent(event);
        return;
    }
    game_->setKey(event->key(), false);
    event->accept();
}

auto WorldView::focusOutEvent(QFocusEvent* event) -> void
{
    // Releases stop arriving once focus is gone; drop the held set so no key sticks.
    if (game_ != nullptr)
    {
        game_->releaseKeys();
    }
    QQuickItem::focusOutEvent(event);
}
