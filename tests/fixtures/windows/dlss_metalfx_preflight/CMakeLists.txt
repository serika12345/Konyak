cmake_minimum_required(VERSION 3.25)

cmake_policy(SET CMP0091 NEW)

project(konyak_dlss_metalfx_preflight VERSION 0.1.0 LANGUAGES CXX)

if(NOT WIN32)
  message(FATAL_ERROR "konyak_dlss_metalfx_preflight builds only on Windows.")
endif()

if(NOT MSVC)
  message(FATAL_ERROR "konyak_dlss_metalfx_preflight requires the MSVC toolchain.")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
  message(FATAL_ERROR "konyak_dlss_metalfx_preflight must be built for x64.")
endif()

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_executable(konyak_dlss_metalfx_preflight src/main.cpp)

target_compile_features(konyak_dlss_metalfx_preflight PRIVATE cxx_std_17)
target_compile_definitions(
  konyak_dlss_metalfx_preflight
  PRIVATE
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)
target_compile_options(
  konyak_dlss_metalfx_preflight
  PRIVATE
    /EHsc
    /W4
    /WX
    /permissive-
)
target_link_libraries(
  konyak_dlss_metalfx_preflight
  PRIVATE
    d3d12.lib
    dxgi.lib
    dxguid.lib
    user32.lib
    gdi32.lib
)

install(TARGETS konyak_dlss_metalfx_preflight RUNTIME DESTINATION bin)
