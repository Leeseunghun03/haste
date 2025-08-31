cmake_minimum_required(VERSION 3.0.0)
project(haste VERSION 1.0.0 LANGUAGES CXX) # Hypotheses-based Asynchronous Tracker of Events

# Prefer GLVND for OpenGL (silence CMP0072 warning)
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
endif()
set(OpenGL_GL_PREFERENCE GLVND)

# Extra CMake finders
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/" ${CMAKE_MODULE_PATH})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -O3")

# --- OpenCV: prefer 4.x, fallback to 3.2+ ---
find_package(OpenCV 4 QUIET)
if(NOT OpenCV_FOUND)
  find_package(OpenCV 3.2 REQUIRED)
endif()
message(STATUS "Using OpenCV ${OpenCV_VERSION}")
include_directories(${OpenCV_INCLUDE_DIRS})
if(OpenCV_VERSION VERSION_GREATER_EQUAL 4.0)
  add_compile_definitions(OPENCV4)
endif()

# --- gflags (Config 우선, 어떤 타겟명이든 흡수; 실패 시 임포트 타겟 생성) ---
find_package(gflags QUIET CONFIG)
if(TARGET gflags::gflags)
  set(GFLAGS_TARGET gflags::gflags)
elseif(TARGET gflags)
  set(GFLAGS_TARGET gflags)
elseif(TARGET gflags_nothreads)
  set(GFLAGS_TARGET gflags_nothreads)
else()
  find_path(GFLAGS_INCLUDE_DIR NAMES gflags/gflags.h
    PATHS /usr/include /usr/local/include)
  find_library(GFLAGS_LIBRARY NAMES gflags
    PATHS /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib)
  if(NOT GFLAGS_INCLUDE_DIR OR NOT GFLAGS_LIBRARY)
    message(FATAL_ERROR "gflags not found. Set -Dgflags_DIR or install libgflags-dev.")
  endif()
  add_library(gflags::gflags UNKNOWN IMPORTED)
  set_target_properties(gflags::gflags PROPERTIES
    IMPORTED_LOCATION "${GFLAGS_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${GFLAGS_INCLUDE_DIR}")
  set(GFLAGS_TARGET gflags::gflags)
endif()
message(STATUS "Using gflags target: ${GFLAGS_TARGET}")

# --- glog (Config 있으면 사용, 없으면 cmake_modules/Findglog.cmake 폴백) ---
find_package(glog QUIET CONFIG)
if(NOT glog_FOUND)
  find_package(glog REQUIRED)  # uses cmake_modules/Findglog.cmake
endif()
if(TARGET glog::glog)
  set(GLOG_TARGET glog::glog)
elseif(TARGET glog)
  set(GLOG_TARGET glog)
else()
  # Our Findglog.cmake creates glog::glog
  set(GLOG_TARGET glog::glog)
endif()
message(STATUS "Using glog target: ${GLOG_TARGET}")

# --- Eigen: vendored 우선, 없으면 시스템 ---
set(EIGEN3_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/eigen)
if(EXISTS "${EIGEN3_INCLUDE_DIR}/Eigen/Core")
  message(STATUS "Using vendored Eigen headers in: ${EIGEN3_INCLUDE_DIR}")
  include_directories(${EIGEN3_INCLUDE_DIR})
else()
  find_package(Eigen3 3.3.4 REQUIRED NO_MODULE)
  message(STATUS "Using system Eigen headers in: ${EIGEN3_INCLUDE_DIR}")
  include_directories(${EIGEN3_INCLUDE_DIR})
endif()

# Project headers
include_directories(include)

# --- executables ---
add_executable(tracking_app_file src/tracking_app_file.cpp)
target_link_libraries(tracking_app_file
  PRIVATE
    ${OpenCV_LIBS}
    ${GFLAGS_TARGET}
    ${GLOG_TARGET}
)

# --- GUI option ---
option(GUI "Builds HASTE GUI playground" ON)
if(GUI)
  message(STATUS "-DGUI=true (Default). GUI will be compiled.")
  add_subdirectory(thirdparty/quickgui)
  add_executable(tracking_app_gui ${CMAKE_CURRENT_LIST_DIR}/src/tracking_app_gui.cpp)
  target_link_libraries(tracking_app_gui
    PRIVATE
      ${OpenCV_LIBS}
      ${GFLAGS_TARGET}
      ${GLOG_TARGET}
      QuickGui
  )
else()
  message(STATUS "-DGUI=false. No GUI will be compiled.")
endif()

