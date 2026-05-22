-- main.lua — Awen application entry point (hypothetical Lua scripting API)

local width  = 1280
local height = 720

-- Reactive state: updated by the event handler and bound to the Text node.
local keyText = awen.state ""

return Engine {
    Window {
        title  = "Awen",
        width  = width,
        height = height,

        -- Scene tree is declared directly as children.
        Rectangle {
            position = { x = 100.0, y = 100.0 },
            width    = 200.0,
            height   = 200.0,
            color    = colors.Red,

            Rectangle {
                position = { x = 10.0, y = 10.0 },
                width    = 50.0,
                height   = 50.0,
                color    = colors.Blue,
            },
        },

        Node {
            position = { x = width / 2.0, y = height / 2.0 },

            Text { content = keyText },
        },

        onEvents = function(event)
            if event.type == EventKeyboard then
                if event.keyboardType == EventKeyboard.Type.Pressed then
                    keyText:set(string.format("Key %s pressed", event.key))
                elseif event.keyboardType == EventKeyboard.Type.Released then
                    keyText:set(string.format("Key %s released", event.key))
                end
            end
        end,
    }
}
