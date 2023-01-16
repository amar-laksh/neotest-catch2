cmake_minimum_required (VERSION 3.5)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE "Debug")
project (exampleProject)
add_subdirectory (src) 
add_subdirectory (tests)
enable_testing ()

