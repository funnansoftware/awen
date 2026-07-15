#pragma once

namespace bt::game
{
    /// @brief The flight controls a controller last set: the throttle, brake,
    /// steer and afterburner-lever positions the movement system integrates.
    struct Controls
    {
        /// @brief 0..1
        float throttle{0.0F};

        /// @brief 0..1
        float brake{0.0F};

        /// @brief -1..1, negative left, positive right
        float steer{0.0F};

        /// @brief 0..1 afterburner lever
        float boost{0.0F};
    };
}
