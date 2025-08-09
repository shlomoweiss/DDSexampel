
cmake_minimum_required(VERSION 3.15)

# Let CMake find the compilers automatically
# (removing explicit compiler settings)

project("icd_library")

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

# Create the DLL library
add_library(ICD SHARED
    ICDPubSubTypes.cxx
    ICDTypeObjectSupport.cxx
    dds_facade.cpp
)

target_link_libraries(ICD 
    PUBLIC 
        fastcdr 
        fastdds
)



# Set include directories for users of this library
target_include_directories(ICD 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${fastdds_INCLUDE_DIRS}
        ${fastcdr_INCLUDE_DIRS}
)



