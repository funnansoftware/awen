#pragma once

#include <QtQml/qqmlregistration.h>
#include <QQuickItem>

#include <quick/GameController.hpp>

namespace bt::quick
{
    /// @brief The scene-graph view of the world: ownship-centred (1 px = 1 m),
    /// every entity a heading-aligned triangle marker, repainted on each
    /// simulation step.
    ///
    /// The Qt Quick analog of the raylib Renderer's draw pass; the key events it
    /// receives (it takes focus in Main.qml) feed the GameController's held-key set.
    class WorldView : public QQuickItem
    {
        Q_OBJECT
        QML_ELEMENT
        Q_PROPERTY(bt::quick::GameController* game READ game WRITE setGame NOTIFY gameChanged)

    public:
        explicit WorldView(QQuickItem* parent = nullptr);

        [[nodiscard]] auto game() const -> GameController*;
        auto setGame(GameController* game) -> void;

    signals:
        void gameChanged();

    protected:
        auto updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) -> QSGNode* override;
        auto keyPressEvent(QKeyEvent* event) -> void override;
        auto keyReleaseEvent(QKeyEvent* event) -> void override;
        auto focusOutEvent(QFocusEvent* event) -> void override;

    private:
        GameController* game_ = nullptr;
    };
}
