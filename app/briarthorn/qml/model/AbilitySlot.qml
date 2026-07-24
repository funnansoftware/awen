import QtQml

// One ability as carried by an entity: the definition row plus the live
// cooldown, charge and intent state. activate() is the single entry point
// player input and AI share — it raises pending for the consuming system
// when the slot is ready, and does nothing otherwise.
QtObject {
    id: slot

    // The ability definition this slot instantiates.
    property Ability def: null

    // Seconds until ready again and rounds left (-1 is unlimited); the
    // consuming system spends both.
    property real cooldownRemaining: 0
    property int charges: def ? def.charges : -1

    // The raised intent, cleared by the consuming system.
    property bool pending: false

    readonly property bool ready: cooldownRemaining <= 0 && charges !== 0

    function activate() {
        if (slot.ready)
            slot.pending = true;
    }
}
