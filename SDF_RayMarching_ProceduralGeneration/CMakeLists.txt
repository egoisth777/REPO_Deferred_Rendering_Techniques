# Setting up the project
# Required Cmake version
cmake_minimum_required(VERSION 3.27)
add_compile_options(-Wall)
# Enabled static link to to stdlib ()
# This will enable Nsight Graphics to open the project succesfully
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static") # This will solve some of the problem that cause the DLL to link cxx1112 issue

# automatically set the build platform
set(_target_platform "x64" CACHE STRING "Target Platform: x86 or x64")
if(_target_platform STREQUAL "x86")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
elseif(_target_platform STREQUAL "x64")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m64")
else()
    message(FATAL_ERROR "unknown target platform ${_target_platform}")
endif()


# When in Windows system, need to convert the path to the cmake format
if (WIN32) # set to be true if the system is windows
    function(convert_to_cmake_path_format PATH)
        string(REPLACE "\\" "/" ${PATH} ${PATH})
    endfunction()
else ()
    function(convert_to_cmake_path_format PATH)
    endfunction()
endif ()

# Get Current Directory Name
get_filename_component(PROJECT_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)

# Project Name and Languages
project(${PROJECT_NAME} LANGUAGES CXX)

# Find the required packages


# Set CMake Prefix Path
convert_to_cmake_path_format(QT6_DIR)
set(CMAKE_PREFIX_PATH ${QT6_DIR})# Set the QT6 installation path

# Find the required packages
find_package(OpenGL REQUIRED) # In QT6, OpenGL is not included in the QT6 package, so we need to find it separately
find_package(Qt6 6.2.2 COMPONENTS Core Widgets Gui OpenGL OpenGLWidgets REQUIRED) #necessary components to create qt GUI/OpenGL application

# if packages not found, print the error message if needed
if(NOT Qt6_FOUND)
    message(FATAL_ERROR "QT6 not found")
endif()


# Set the C++ Stanard C++17
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_DEBUG "-g") # Set the debug flag



# Add include directories
# PreProcessor needs to know where to find the header files
include_directories(${PROJECT_SOURCE_DIR}/include ${PROJECT_SOURCE_DIR}/src)

# Set the source file of the project
file(GLOB_RECURSE PROJECT_SOURCES
        src/*.cpp
        src/*.c
        src/*.cc
)

# Automatically run moc and uic on sources and headers
set(CMAKE_AUTOMOC ON) # automatically
set(CMAKE_AUTORCC ON) # automatically parse the qrc file
set(CMAKE_AUTOUIC ON) # automatically parse the qt headers file
set(CMAKE_AUTOUIC_SEARCH_PATHS ${PROJECT_SOURCE_DIR}/forms) # Set the search path for the ui files

# Add the executable targets
add_executable(${PROJECT_NAME}
        ${PROJECT_SOURCES}
)

# Link the Libraries
target_link_libraries(${PROJECT_NAME}
        PRIVATE
        Qt6::Widgets
        Qt6::Gui
        Qt6::OpenGLWidgets
        Qt6::Core
        OpenGL::GL
        OpenGL::GLU
)
