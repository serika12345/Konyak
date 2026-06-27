cmake_minimum_required(VERSION 3.25)

cmake_policy(SET CMP0091 NEW)

project(konyak_d3d12_minimal VERSION 0.1.0 LANGUAGES CXX)

if(NOT WIN32)
  message(FATAL_ERROR "konyak_d3d12_minimal builds only on Windows.")
endif()

if(NOT MSVC)
  message(FATAL_ERROR "konyak_d3d12_minimal requires the MSVC toolchain.")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
  message(FATAL_ERROR "konyak_d3d12_minimal must be built for x64.")
endif()

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_executable(konyak_d3d12_minimal src/main.cpp)

target_compile_features(konyak_d3d12_minimal PRIVATE cxx_std_17)
target_compile_definitions(
  konyak_d3d12_minimal
  PRIVATE
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)
target_compile_options(
  konyak_d3d12_minimal
  PRIVATE
    /EHsc
    /W4
    /WX
    /permissive-
)
target_link_libraries(
  konyak_d3d12_minimal
  PRIVATE
    d3d12.lib
    dxgi.lib
    dxguid.lib
    user32.lib
    gdi32.lib
)

install(TARGETS konyak_d3d12_minimal RUNTIME DESTINATION bin)
