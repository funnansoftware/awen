# Layers, bottom-up: the game core (renderer-free simulation + state), then the
# Qt Quick edge, which composes the briarthorn executable around it.
add_subdirectory(game)
add_subdirectory(quick)
