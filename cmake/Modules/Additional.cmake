include(LibFindMacros)

# set(FMOD_INCLUDE_DIR "$PROJECT_SOURCE_DIR/libs/fmodex/inc")
# set(FMOD_LIBRARY $PROJECT_SOURCE_DIR/libs/dll-binaries/x86_64/fmodex64.dll)

# set(FMOD_PROCESS_INCLUDES FMOD_INCLUDE_DIR)
# set(FMOD_PROCESS_LIBS FMOD_LIBRARY)
# libfind_process(FMOD)

# set(DRMINGW_INCLUDE_DIR "$PROJECT_SOURCE_DIR/libs/drmingw/include")
# set(DRMINGW_LIBRARY $PROJECT_SOURCE_DIR/libs/win32/libexchndl.a)

# set(DRMINGW_PROCESS_INCLUDES DRMINGW_INCLUDE_DIR)
# set(DRMINGW_PROCESS_LIBS DRMINGW_LIBRARY)
# libfind_process(DRMINGW)

# set(CURL_INCLUDE_DIR "$PROJECT_SOURCE_DIR/libs/curl/include/curl")
# set(CURL_LIBRARY $PROJECT_SOURCE_DIR/libs/curl/lib32/libcurl.dll)

# set(CURL_PROCESS_INCLUDES CURL_INCLUDE_DIR)
# set(CURL_PROCESS_LIBS CURL_LIBRARY)
# libfind_process(CURL)

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()