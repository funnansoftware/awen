local width = 1280
local height = 720

return Rectangle {
    position = { x = 100.0, y = 100.0 },
    width    = 200.0,
    height   = 200.0,
    -- color    = colors.Red,

    Rectangle {
        position = { x = 10.0, y = 10.0 },
        width    = 50.0,
        height   = 50.0,
        -- color    = colors.Blue,
    },
}