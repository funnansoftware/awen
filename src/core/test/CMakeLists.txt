project(awen-core-test)

add_executable(${PROJECT_NAME})

target_sources(${PROJECT_NAME} PRIVATE
    Engine.test.cpp
    Object.test.cpp
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        awen-core
        awen-test
)

gtest_discover_tests(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)