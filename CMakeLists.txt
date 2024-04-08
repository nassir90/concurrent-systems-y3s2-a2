cmake_minimum_required(VERSION 3.18.4)
project(concurrent)
add_compile_options(
  "-msse4"
  $<$<CONFIG:Debug>:-ggdb>
  $<$<CONFIG:Release>:-O2>
)
find_package(OpenMP REQUIRED)
add_executable(concurrent conv-harness.c)
if (${PRINT_PLOT_TEXT})
  target_compile_definitions(concurrent PRIVATE "PRINT_PLOT_TEXT")
endif()
if (${NO_DAVID})
  target_compile_definitions(concurrent PRIVATE "NO_DAVID")
endif()
target_link_libraries(concurrent OpenMP::OpenMP_C)
