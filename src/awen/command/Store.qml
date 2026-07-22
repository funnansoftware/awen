import awen.entity

// Base type for a command observer: a System that drains the queue's
// published batch each tick, routing every record to the declared handler
// with its name — the store's handlers are its whole transition surface.
// Declare stores after the queue in the Systems list. Stores that consume
// records generically (recorders, relays) override consume() instead of
// declaring handlers; they observe without marking records consumed.
System {
    id: store

    // The queue this store observes.
    required property CommandQueue queue

    // The store's registrations, as child objects; the first handler with a
    // record's name wins.
    default property list<CommandHandler> handlers

    function update(dt: real) {
        const batch = store.queue.commands;
        for (let i = 0; i < batch.length; ++i)
            store.consume(batch[i]);
    }

    // Routes one record to its named handler and marks it consumed; the scan
    // is linear because a store holds a handful of handlers.
    function consume(record: var) {
        for (let i = 0; i < store.handlers.length; ++i) {
            const handler = store.handlers[i];
            if (handler.enabled && handler.name === record.name) {
                record.consumed = true;
                handler.handle(record.payload);
                return;
            }
        }
    }
}
