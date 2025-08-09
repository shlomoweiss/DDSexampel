cmake_minimum_required(VERSION 3.15)
project(icdwrapper)

# Ensure we're using MSVC
if(NOT MSVC)
    message(FATAL_ERROR "This project requires MSVC compiler")
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)

# Enable DLL creation
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
set(BUILD_SHARED_LIBS ON)

# Find requirements
find_package(fastcdr REQUIRED)
find_package(fastdds 3 REQUIRED)

# Find the pre-built hello_msg_lib
find_library(ICD NAMES ICD PATHS "C:/cpp-prj/DDSexampel/DDSmessage/build/Release" REQUIRED)

# Add your own target (example: an executable or another library)
# add_executable(my_app main.cpp)
# target_link_libraries(my_app ${HELLO_MSG_LIB} fastrtps fastcdr)

# Or, if you want to create a library that links to hello_msg_lib:
# Create the SWIG wrapper library
add_library(ICDWrapper SHARED ICD_wrap.cxx)
target_link_libraries(ICDWrapper ${ICD} fastdds fastcdr)

# Set include directories for users of this library
target_include_directories(ICDWrapper 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        "C:/cpp-prj/DDSexampel/DDSmessage"
)
