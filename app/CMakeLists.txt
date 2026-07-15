# The awen sample app is pure Qt Quick, so it only exists when the framework
# does; briarthorn decides internally which rendering edge to build.
if("qt" IN_LIST VCPKG_MANIFEST_FEATURES)
    add_subdirectory(awen)
endif()

add_subdirectory(briarthorn)
