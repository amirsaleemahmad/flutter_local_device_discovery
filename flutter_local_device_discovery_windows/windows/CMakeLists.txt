cmake_minimum_required(VERSION 3.14)
project(flutter_local_device_discovery_windows)

set(PLUGIN_NAME "flutter_local_device_discovery_windows")

add_library(${PLUGIN_NAME} SHARED
  "flutter_local_device_discovery_plugin.cpp"
  "flutter_local_device_discovery_plugin.h"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  NOMINMAX
)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE
  ws2_32
  iphlpapi
  dnsapi
)

# List of symbols to export
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)