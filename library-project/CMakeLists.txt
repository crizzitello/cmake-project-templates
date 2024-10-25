### PROJECT TEMPLATE
# Works well for libraries with demo applications

# Cmake 3.21+ is required to build this project
cmake_minimum_required(VERSION 3.21)

# Allow Cmake to use the cmake or env var <package>_ROOT for find_package calls for <package>
# https://cmake.org/cmake/help/latest/policy/CMP0074.html
cmake_policy(SET CMP0074 NEW)

# First include init-project and use the setup_project function
include(${CMAKE_CURRENT_LIST_DIR}/cmake/init-project.cmake)

# Read the project info from our project file
# Sets the following to be used in your project call and then unset
# The project call will transform them into the names on the right
# PROJECTS_NAME     -> CMAKE_PROJECT_NAME
# PROJECTS_DESC     -> CMAKE_PROJECT_DESCRIPTION
# PROJECTS_VERSION  -> CMAKE_PROJECT_VERSION
# PROJECTS_HOMEPAGE -> CMAKE_PROJECT_HOMEPAGE
# Below are not standard Cmake project vars we have set
# You will not find these outside of using the template
# CMAKE_PROJECT_CONTACT <- Project contact used for packaging
# CMAKE_PROJECT_COMPATIBILITY <- Used by consuming projects to check if the verison found is compatible with the version requested
# CMAKE_PROJECT_LICENSE <- SPDX Name for your license
# CMAKE_PROJECT_SUPPLIER <- The supplier of the generated package. A person, group or company
# CMAKE_PROJECT_LC_NAME <- Lower Case name
# CMAKE_PROJECT_UC_NAME <- Upper case name should be use for package components
# CMAKE_PROJECT_LICENSE_FILE <- The detected license file
read_project_info(${CMAKE_CURRENT_LIST_DIR}/projectInfo.txt)

#FILL VARS
# SYSTEM_NAME
# SYSTEM_LIKE
# SYSTEM_CODENAME
# SYSTEM_VERSION_ID
# SYSTEM_CVE_STRING <- Not Used Yet
set_extra_os_info()

#Used Modules that can be included before a project call has been made
include(CMakePackageConfigHelpers)
include(GenerateExportHeader)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/projectHelpers.cmake)

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Call Project ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# All These are set by the read_project_info call above
project(${PROJECTS_NAME}
    VERSION ${PROJECTS_VERSION}
    DESCRIPTION ${PROJECTS_DESCRIPTION}
    HOMEPAGE_URL ${PROJECTS_HOMEPAGE}
    LANGUAGES C CXX
)

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ PROJECT VARS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# These values are used only before project is called
unset(PROJECTS_NAME)
unset(PROJECTS_VERSION)
unset(PROJECTS_DESCRIPTION)
unset(PROJECTS_HOMEPAGE)

# Do We want to default to Shared LIBS ?
option(BUILD_SHARED_LIBS "Build using shared libraries" ON)

#Used Modules that must be included after a project call has been made
include(GNUInstallDirs)

# Attempt to force the use of all cpu cores to build most compilers will do this by default
option(USE_ALL_CPU "Detect and use all cores to build" ON)
if(USE_ALL_CPU)
    cmake_host_system_information(RESULT N QUERY NUMBER_OF_LOGICAL_CORES)
    set(CMAKE_BUILD_PARALLEL_LEVEL ${N})
endif()

#Prevent In-sourcebuild
if(CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "In source builds are not allowed; Set a build path")
endif()

# Report to the user Our basic project information
message(STATUS "Building ${CMAKE_PROJECT_NAME}: ${CMAKE_PROJECT_VERSION} Using: ${CMAKE_BUILD_PARALLEL_LEVEL} Threads")

## Setup Project C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Force Hidden by default for all compilers
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN YES)

# Include the current src/bin dirs when checking relative paths
set(CMAKE_INCLUDE_CURRENT_DIR ON)

#This Project will use Qt
#Any QObjects will have moc called for them automaticlly
set(CMAKE_AUTOMOC ON)
#Automatically call rcc on any qrc files used in a target
set(CMAKE_AUTORCC ON)
#Automatically call uic on any ui files used in a target
set(CMAKE_AUTOUIC ON)

#Pick a faster linker based on the compiler for linux
if (UNIX AND NOT APPLE)
    if(${CMAKE_CXX_COMPILER_ID} MATCHES Clang)
        string(REPLACE "." ";" VERSION_LIST ${CMAKE_CXX_COMPILER_VERSION})
        list(GET VERSION_LIST 0 CLANG_VERSION_MAJOR)
        find_program(LLD_PROGRAM_MATCH_VER lld-${CLANG_VERSION_MAJOR})
        find_program(LLD_PROGRAM lld)
        if (LLD_PROGRAM_MATCH_VER)
            message(STATUS "Set linker to LLD: ${LLD_PROGRAM_MATCH_VER}")
            add_link_options("-fuse-ld=lld-${CLANG_VERSION_MAJOR}")
        elseif(LLD_PROGRAM)
            message(STATUS "Set linker to LLD: ${LLD_PROGRAM}")
            add_link_options("-fuse-ld=lld")
        endif()
    elseif(${CMAKE_CXX_COMPILER_ID} MATCHES GNU)
        find_program(GNU_GOLD_PROGRAM gold)
        if (GNU_GOLD_PROGRAM)
            message(STATUS "Set linker to GNU gold")
            add_link_options("-fuse-ld=gold;LINKER:--threads,--thread-count=${CMAKE_BUILD_PARALLEL_LEVEL}")
        endif(GNU_GOLD_PROGRAM)
    endif()
endif()

# We Want to build our Library in RelWithDebInfo as a default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "" FORCE)
endif()

# Setup the SBOM to be generated during install.
sbom_generate(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/sbom-${PROJECT_NAME}-${PROJECT_VERSION}.spdx
        LICENSE ${CMAKE_PROJECT_LICENSE}
        SUPPLIER ${CMAKE_PROJECT_SUPPLIER}
        SUPPLIER_URL ${CMAKE_PROJECT_HOMEPAGE_URL}
)

### PLACE ANY PROJECT LEVEL FIND PACKAGES HERE
#Set Our Required Qt Version
# Use for all find_package and init calls later
set(REQUIRED_QT_VERSION 6.2.0)

#Find Qt's Info and setup what deployment application we will use later on
find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED COMPONENTS Core)
get_target_property(qmake_executable Qt6::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin_dir "${qmake_executable}" DIRECTORY)
if(WIN32 OR APPLE)
    if(WIN32)
        set(deployqtapp windeployqt)
    elseif(APPLE)
        set(deployqtapp macdeployqt)
    endif()
    find_program(PLATFORMDEPLOYQT ${deployqtapp} HINTS "${_qt_bin_dir}")
endif()

#For Every Dependency we must call sbom_add(PACKAGE ) with a package a version
# The package name will not always match the name of the libary may instead be the parent project name
# Check the NVD package search https://nvd.nist.gov/vuln/search
# To Be sure you have the correct name
# Our Project will require Qt and the version in use is the version of QtCore we just found
sbom_add(PACKAGE Qt VERSION ${Qt6Core_VERSION})


#~~~~~~~~~~~~~~~~~~~~~~Set the Rpath for our libs.
# Prevents the need for LD_LIBRARY path in most cases
if(UNIX)
    if(NOT APPLE)
        set(INSTALL_RPATH_STRING "\${ORIGIN}:\$ORIGIN/../lib:/lib:/usr/lib:/usr/local/lib:\$HOME/.local/lib:\$HOME/.local/usr/lib")
    else()
        set(INSTALL_RPATH_STRING "@loader_path/../Frameworks @loader_path @executable_path @executable_path/../Frameworks")
    endif()
endif()

#These properties will be used to track the targets and tests the pojects creates
define_property(GLOBAL PROPERTY ${CMAKE_PROJECT_NAME}_targets BRIEF_DOCS "Defined Non-Test Targets" FULL_DOCS "Dynamicly Generated list of Targets Tests")
define_property(GLOBAL PROPERTY ${CMAKE_PROJECT_NAME}_tests BRIEF_DOCS "Defined Tests" FULL_DOCS "Dynamicly Generated list of Defined Tests")

# Include any subdirectories
add_subdirectory(docs)
add_subdirectory(translations)
add_subdirectory(src)

# Any optional subdirs should be options
option(DEMOS "Build Demo Apps" OFF)
if(DEMOS)
    add_subdirectory(demos)
endif()


option(TESTS "Run UnitTests" ON)
if(TESTS)
    add_subdirectory(unittests)
endif()

#Always add packaging last
option(PACKAGE "Allow Packaging" ON)
if(PACKAGE)
    add_subdirectory(packaging)
endif()

#Install our License File
install (FILES "${CMAKE_PROJECT_LICENSE_FILE}" DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/${CMAKE_PROJECT_NAME} RENAME LICENSE COMPONENT ${CMAKE_PROJECT_UC_NAME}_LIBRARIES)

# uninstall target
if(NOT TARGET uninstall)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/_template/uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake"
    IMMEDIATE @ONLY)

  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake")
endif()

option(SBOM_LINT "Verify Generated SBOM is NTIA Compliant" OFF)
if (NOT SBOM_LINT)
    set(NO_VERIFY "NO_VERIFY")
endif()

option(SBOM_GRAPH "Create a Graph of the SBOM" OFF)
if(SBOM_GRAPH)
    set(GRAPH "GRAPH ${CMAKE_CURRENT_BINARY_DIR}/sbom-${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-spdx.png")
endif()

# Finalize must be called last
sbom_finalize(${NO_VERIFY} ${GRPAH})

#Install our sbom file
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/sbom-${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}.spdx DESTINATION share/${CMAKE_PROJECT_NAME} COMPONENT ${CMAKE_PROJECT_UC_NAME}_LIBRARIES)

#if we made a graph install the graph
if(SBOM_GRAPH)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/sbom-${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-spdx.png DESTINATION share/${CMAKE_PROJECT_NAME} COMPONENT ${CMAKE_PROJECT_UC_NAME}_LIBRARIES)
endif()
