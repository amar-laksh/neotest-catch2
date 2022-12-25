cmake_minimum_required (VERSION 3.5)
project (exampleProject)
add_subdirectory (src) 
add_subdirectory (tests)
enable_testing ()
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

