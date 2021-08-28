# Find SDL2
# Once done, this will define
#
#  SDL2_MAIN_FOUND - system has SDL2
#  SDL2_MAIN_INCLUDE_DIRS - SDL2 include directories
#  SDL2_MAIN_LIBRARIES - link libraries

include(LibFindMacros)

libfind_pkg_check_modules(SDL2_MAIN_PKGCONF SDL2)

# includes
find_path(SDL2_MAIN_INCLUDE_DIR
	NAMES SDL.h
	PATHS
		${SDL2_MAIN_PKGCONF_INCLUDE_DIRS}
		"/usr/include/SDL2"
		"/usr/local/include/SDL2"
		"${PROJECT_SOURCE_DIR}/libs/SDL2/include"
)

# library
find_library(SDL2_MAIN_LIBRARY
	NAMES
		SDL2_main
		SDL2main
	PATHS
		${SDL2_MAIN_PKGCONF_LIBRARY_DIRS}
		"/usr/lib"
		"/usr/local/lib"
		"${PROJECT_SOURCE_DIR}/libs/SDL2/i686-w64-mingw32/lib"
)

# set(SDL2_MAIN_INCLUDE_DIR "$PROJECT_SOURCE_DIR/libs/SDL2/include")
# set(SDL2_MAIN_LIBRARY $PROJECT_SOURCE_DIR/libs/SDL2/lib/x64/SDL2main.lib)

# set include dir variables
set(SDL2_MAIN_PROCESS_INCLUDES SDL2_MAIN_INCLUDE_DIR)
set(SDL2_MAIN_PROCESS_LIBS SDL2_MAIN_LIBRARY)
libfind_process(SDL2_MAIN)
