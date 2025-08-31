# Minimal finder for glog (Ubuntu 20.04)
find_path(glog_INCLUDE_DIR NAMES glog/logging.h
  PATHS /usr/include /usr/local/include
)
find_library(glog_LIBRARY NAMES glog
  PATHS /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib
)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(glog REQUIRED_VARS glog_INCLUDE_DIR glog_LIBRARY)

if(glog_FOUND AND NOT TARGET glog::glog)
  add_library(glog::glog UNKNOWN IMPORTED)
  set_target_properties(glog::glog PROPERTIES
    IMPORTED_LOCATION "${glog_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${glog_INCLUDE_DIR}"
  )
endif()

mark_as_advanced(glog_INCLUDE_DIR glog_LIBRARY)
