# Find SDL2
# Once done, this will define
#
#  SDL2_FOUND - system has SDL2
#  SDL2_INCLUDE_DIRS - SDL2 include directories
#  SDL2_LIBRARIES - link libraries

include(LibFindMacros)

libfind_pkg_check_modules(SDL2_PKGCONF SDL2)

# includes
find_path(SDL2_INCLUDE_DIR
	NAMES SDL.h
	PATHS
		${SDL2_PKGCONF_INCLUDE_DIRS}
		"/usr/include/SDL2"
		"/usr/local/include/SDL2"
		"${PROJECT_SOURCE_DIR}/libs/SDL2/include"
)

# library
find_library(SDL2_LIBRARY
	NAMES SDL2
	PATHS
		${SDL2_PKGCONF_LIBRARY_DIRS}
		"/usr/lib"
		"/usr/local/lib"
		"${PROJECT_SOURCE_DIR}/libs/SDL2/i686-w64-mingw32/lib"
)

# set(SDL2_INCLUDE_DIR "$PROJECT_SOURCE_DIR/libs/SDL2/include")
# set(SDL2_LIBRARY $PROJECT_SOURCE_DIR/libs/SDL2/lib/x64/SDL2.lib)

# set include dir variables
set(SDL2_PROCESS_INCLUDES SDL2_INCLUDE_DIR)
set(SDL2_PROCESS_LIBS SDL2_LIBRARY)
libfind_process(SDL2)
