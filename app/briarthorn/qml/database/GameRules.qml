pragma Singleton

import QtQml

// Game configuration: the rules that turn an entity's stats — dimensionless
// 0..10 ratings — into concrete physical quantities. Each max constant says
// what the top of a rating's range is worth and each *For() helper scales a
// rating onto that span, so this is the one file to retune the game's feel.
// World quantities are physical: 1 px = 1 m, so distances are metres, speeds
// m/s and accelerations m/s^2.
QtObject {
    id: root

    // The top of every stat's range; stats are rated 0..maxStat.
    readonly property real maxStat: 10

    // kinetic buys speed, and the fuel it takes to hold it: the full-throttle
    // speed and the cruise burn (units/s) at the top of the range.
    readonly property real maxSpeed: 1000
    readonly property real maxFuelBurn: 1

    // Multiplier on the cruise burn at full throttle — the draw is
    // fuelBurnFor(kinetic) * (1 + fuelThrottleBurn * throttle), so pushing the
    // airframe costs far more than loitering does.
    readonly property real fuelThrottleBurn: 2

    // The speed fraction a hands-off lever commands: the airframe cruises at
    // half its ceiling, full brake pulls it to a stop and full throttle to max.
    readonly property real throttleIdle: 0.5

    // maneuver buys agility: the full-deflection turn rate (deg/s) and the
    // acceleration (m/s^2) speed closes on the commanded setting with.
    readonly property real maxTurnRate: 24
    readonly property real maxAcceleration: 200

    // durable buys survivability: hull integrity (hit points) and the fuel
    // capacity (units) of one airframe.
    readonly property real maxHealth: 200
    readonly property real maxFuel: 400

    // sensor buys the radar's detection range (m).
    readonly property real maxDetectionRange: 120000

    // compute buys a guided seeker's acquisition range (m).
    readonly property real maxGuidedRange: 150000

    // How far up its range a rating sits, clamped to [0, 1] — every rule
    // below is this fraction of the matching span.
    function fraction(stat: real): real {
        return Math.max(0, Math.min(stat, root.maxStat)) / root.maxStat;
    }

    function topSpeedFor(kinetic: real): real {
        return root.maxSpeed * root.fraction(kinetic);
    }

    // Prices a throttle lever, -1 (full brake) to 1 (full throttle), into the
    // commanded speed fraction swinging around the idle cruise.
    function throttleFor(lever: real): real {
        const swing = Math.max(-1, Math.min(1, lever));
        return root.throttleIdle + swing * (swing >= 0 ? 1 - root.throttleIdle : root.throttleIdle);
    }

    function fuelBurnFor(kinetic: real): real {
        return root.maxFuelBurn * root.fraction(kinetic);
    }

    function turnRateFor(maneuver: real): real {
        return root.maxTurnRate * root.fraction(maneuver);
    }

    function accelerationFor(maneuver: real): real {
        return root.maxAcceleration * root.fraction(maneuver);
    }

    function healthFor(durable: real): real {
        return root.maxHealth * root.fraction(durable);
    }

    function fuelCapacityFor(durable: real): real {
        return root.maxFuel * root.fraction(durable);
    }

    function detectionRangeFor(sensor: real): real {
        return root.maxDetectionRange * root.fraction(sensor);
    }

    function guidedRangeFor(compute: real): real {
        return root.maxGuidedRange * root.fraction(compute);
    }
}
