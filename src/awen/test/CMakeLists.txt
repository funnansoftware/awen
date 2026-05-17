project(awen-test)

add_library(${PROJECT_NAME} INTERFACE)

target_include_directories(${PROJECT_NAME} INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/../..
)

target_sources(${PROJECT_NAME} INTERFACE
    Test.hpp
)

find_package(GTest CONFIG REQUIRED)

target_link_libraries(${PROJECT_NAME} INTERFACE
    GTest::gtest
    GTest::gtest_main
)
