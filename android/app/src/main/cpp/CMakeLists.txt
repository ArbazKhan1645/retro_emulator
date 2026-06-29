cmake_minimum_required(VERSION 3.18.1)

project("retroverse_bridge")

# Specify the dynamic C/C++ bridge library
add_library(
    retroverse_bridge
    SHARED
    retroverse_bridge.cpp
)

# Search for NDK library dependencies
find_library(
    log-lib
    log
)

# Link your native bridge with target libraries
target_link_libraries(
    retroverse_bridge
    ${log-lib}
)
