#pragma once

namespace bt::game
{
    /// @brief The capability ceilings bounding one entity's motion: what the
    /// airframe can do, where Controls records what the pilot asked for.
    ///
    /// Flat values for now; the full port derives these from stats via
    /// GameRules (briardart's Entity.topSpeed etc).
    struct Limits
    {
        /// @brief m/s at speedBoost == 1
        float topSpeed{180.0F};

        /// @brief deg/s
        float turnRate{90.0F};

        /// @brief m/s^2
        float acceleration{120.0F};
    };
}
