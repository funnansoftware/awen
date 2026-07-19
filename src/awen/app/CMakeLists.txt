# awen-app — the shared Qt bootstrap (awen::runApp) behind the main() that
# awen_add_executable generates per app from main.cpp.in.
add_library(awen-app STATIC
    App.h
    App.cpp
)
target_include_directories(awen-app PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(awen-app PUBLIC Qt6::Quick)
