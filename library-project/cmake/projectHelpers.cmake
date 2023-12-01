# SBOM Items are based upon https://github.com/DEMCON/cmake-sbom and Jochem Rutgers' work
# Other Items are Based upon https://github.com/sithlord48/ff7tk
# 2023 Chris Rizzitello
# Modified to more fit a project template.

#Contains Various Macros to be included
#####~~~~~~~~~~~~~~~~~~~~~MAKE_LIBRARY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#This makes a Library and sets up all the install rules
# CMAKE_PROJECT_NAME will be used for the project name where needed
# Calls add_library or qt_add_qml_module based on the provided options
# LIB_TARGET NAME of Library to Make
# HEADER_INSTALL_DIR: Path to install headers
## The Follow should be by defined the caller before calling the macro
# LIB_TARGET_SRC
# LIB_TARGET_HEADERS
# LIB_TARGET_RESOURCES
# LIB_TARGET_PublicLIBLINKS
# LIB_TARGET_PrivateLIBLINKS
## QML PLUGINS##
# By Default a libary will be made if you would instead like a QML MODULE
# LIB_TARGET_MAKEQMLMODULE - If True A QML Module will be made by calling qt_add_qml_module instead of add_library
# LIB_TARGET_URI - The URI of the new module
# LIB_TARGET_RESOURCE_PREFIX - Set to /qt/qml unless otherwise specified
# LIB_TARGET_DEPENDS - The list of Qml Modules this module will depend upon. Depends are added to LIB_TARGET_PublicLIBLINKS
# LIB_TARGET_QML_FILES - QML Files that are part of the module

macro(MAKE_LIBRARY LIB_TARGET HEADER_INSTALL_DIR)
    if(DEFINED ${LIB_TARGET}_MAKEQMLMODULE)
        if(NOT DEFINED ${LIB_TARGET}_RESOURCE_PREFIX)
            set(RESOURCE_PREFIX "/qt/qml")
        endif()

        qt_add_qml_module(${LIB_TARGET}
            VERSION 1.0
            URI ${${LIB_TARGET}_URI}
            RESOURCE_PREFIX ${RESOURCE_PREFIX}
            DEPENDENCIES ${${LIB_TARGET}_DEPENDS}
            QML_FILES ${${LIB_TARGET}_QMLFILES}
            SOURCES ${${LIB_TARGET}_SRC} ${${LIB_TARGET}_HEADERS}
            NO_PLUGIN
        )
    else()
        add_library (${LIB_TARGET} SHARED
                ${${LIB_TARGET}_SRC}
                ${${LIB_TARGET}_HEADERS}
                ${${LIB_TARGET}_RESOURCES}
    )
    endif()
    add_library (${CMAKE_PROJECT_NAME}::${LIB_TARGET} ALIAS ${LIB_TARGET})

    #Embed rc file with Version info
    if(WIN32)
        set(LIB_NAME ${LIB_TARGET})
        configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/libTemplate.rc.in ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}.rc @ONLY)
        target_sources(${LIB_TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}.rc)
    endif()

    #Generate the non .h ending header let the user include "HEADER" or "HEADER.h"
    foreach ( HEADER ${${LIB_TARGET}_HEADERS})
        if(${HEADER} MATCHES "^/" OR ${HEADER} MATCHES "^[A-Za-z]:")
            string(FIND ${HEADER} "/" lastSlash REVERSE)
            string(SUBSTRING ${HEADER} 0 ${lastSlash} RMSTRING)
            string(REPLACE "${RMSTRING}/" "" HEADER ${HEADER})
        endif()
        set(fileContent "#pragma once\n#include<${HEADER}>\n")
        string(REPLACE ".h" "" HEADER ${HEADER})
        file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${HEADER} ${fileContent})
        list(APPEND ALIASHEADERS ${CMAKE_CURRENT_BINARY_DIR}/${HEADER})
    endforeach()

    if(APPLE)
        set_target_properties(${LIB_TARGET} PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
        if(${BUILD_FRAMEWORKS})
            target_include_directories(${LIB_TARGET} PUBLIC  $<BUILD_INTERFACE:$<TARGET_BUNDLE_CONTENT_DIR:${LIB_TARGET}>/Headers>)
        endif()
    endif()

    if(UNIX)
        set_target_properties(${LIB_TARGET} PROPERTIES INSTALL_RPATH ${INSTALL_RPATH_STRING})
    endif()

    set_target_properties(${LIB_TARGET} PROPERTIES
        FRAMEWORK ${BUILD_FRAMEWORKS}
        FRAMEWORK_VERSION ${PROJECT_VERSION_MAJOR}
        MACOSX_FRAMEWORK_IDENTIFIER com.sithlord48.${LIB_TARGET}
        VERSION "${PROJECT_VERSION}"
        SOVERSION "${PROJECT_VERSION_MAJOR}"
        PUBLIC_HEADER "${${LIB_TARGET}_HEADERS}"
        MAP_IMPORTED_CONFIG_DEBUG RELWITHDEBINFO
        MAP_IMPORTED_CONFIG_RELEASE RELWITHDEBINFO
        MAP_IMPORTED_CONFIG_RELWITHDEBINFO RELWITHDEBINFO
        MAP_IMPORTED_CONFIG_MINSIZEREL RELWITHDEBINFO
    )

    target_include_directories(${LIB_TARGET} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
        $<INSTALL_INTERFACE:include/${HEADER_INSTALL_DIR}>
    )

    target_link_libraries (${LIB_TARGET}
        PUBLIC
          ${${LIB_TARGET}_PublicLIBLINKS}
        PRIVATE
          ${${LIB_TARGET}_PrivateLIBLINKS}
        )

    generate_export_header(${LIB_TARGET})
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMinorVersion
    )
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}Config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
    )
    install(TARGETS ${LIB_TARGET}
        EXPORT ${CMAKE_PROJECT_NAME}Targets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_libraries
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_libraries
            NAMELINK_COMPONENT ${CMAKE_PROJECT_NAME}_headers
        FRAMEWORK DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_libraries
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_headers
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${HEADER_INSTALL_DIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_headers
    )
    install (FILES ${ALIASHEADERS}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${HEADER_INSTALL_DIR}
        COMPONENT ${CMAKE_PROJECT_NAME}_headers
    )

    if(UNIX)
        if(NOT APPLE)
            add_custom_command(TARGET ${LIB_TARGET} POST_BUILD
                COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:${LIB_TARGET}> $<TARGET_FILE:${LIB_TARGET}>.dbg
                COMMAND ${CMAKE_STRIP} --strip-debug $<TARGET_FILE:${LIB_TARGET}>
                COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:${LIB_TARGET}>.dbg $<TARGET_FILE:${LIB_TARGET}>
            )
        else()
            add_custom_command(TARGET ${LIB_TARGET} POST_BUILD
                COMMAND dsymutil -f $<TARGET_FILE:${LIB_TARGET}> -o $<TARGET_FILE:${LIB_TARGET}>.dbg
            )
        endif()
        install(FILES $<TARGET_FILE:${LIB_TARGET}>.dbg
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/debug
            COMPONENT ${CMAKE_PROJECT_NAME}_debug
        )
    elseif(WIN32)
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/$<TARGET_FILE_BASE_NAME:${LIB_TARGET}>.pdb
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT ${CMAKE_PROJECT_NAME}_debug
        )
    endif()

    install(
        EXPORT ${CMAKE_PROJECT_NAME}Targets
        NAMESPACE ${CMAKE_PROJECT_NAME}::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
        COMPONENT ${CMAKE_PROJECT_NAME}_headers
    )

    install(
        FILES
          ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}Config.cmake
          ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}ConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
        COMPONENT ${CMAKE_PROJECT_NAME}_headers
    )

    export(EXPORT ${CMAKE_PROJECT_NAME}Targets FILE ${CMAKE_CURRENT_BINARY_DIR}/${LIB_TARGET}Targets.cmake)
    set_property(GLOBAL APPEND PROPERTY ${CMAKE_PROJECT_NAME}_targets ${LIB_TARGET})

    sbom_add(TARGET ${LIB_TARGET})

endmacro()

#####~~~~~~~~~~~~~~~~~~~~~MAKE_DEMO~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#This Macro Creates a ${CMAKE_PROJECT_NAME} demo from a project
#Then Sets all install and pacakge info
##REQUIREMENTS
# The INSTALL_RPATH_STRING has been set (main CMakeLists.txt)
# Caller is a project with NAME VERSION AND DESCRIPTION set
# DEMO_NAME_SRC - Source for the demo
# DEMO_NAME_DEPENDS - ${CMAKE_PROJECT_NAME} items the demo depends on
# DEMO_NAME_LIBLINKS - Libraries to link
## Having these in the demo dir will override the generic versions
# DEMO_NAME.png  - Icon used on Linux
# DEMO_NAME.rc  - AppInfo for windows
# DEMO_NAME.ico  - Icon used on Windows
# DEMO_NAME.icns - Icon used on Mac Os
macro(MAKE_DEMO)
    if(APPLE)
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.icns)
            set(PLATFORM_EX_SRC ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.icns)
        else()
            configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/demoTemplate.icns ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.icns COPYONLY)
            set(PLATFORM_EX_SRC ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.icns)
        endif()
        set_source_files_properties(${PLATFORM_EX_SRC} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    elseif(WIN32)
        if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.ico)
            configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/demoTemplate.ico ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.ico COPYONLY)
        endif()
        configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/demoTemplate.rc.in ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.rc @ONLY)
        set(PLATFORM_EX_SRC ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.rc)
    endif()

    add_executable(${PROJECT_NAME} WIN32 MACOSX_BUNDLE ${${PROJECT_NAME}_SRC} ${PLATFORM_EX_SRC})
    add_dependencies(${PROJECT_NAME} ${${PROJECT_NAME}_DEPENDS})
    target_link_libraries ( ${PROJECT_NAME} PRIVATE ${${PROJECT_NAME}_LIBLINKS})

    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.${CMAKE_PROJECT_NAME}.${PROJECT_NAME}"
        MACOSX_BUNDLE_DISPLAY_NAME "${PROJECT_NAME}"
        MACOSX_BUNDLE_BUNDLE_NAME "${PROJECT_NAME}"
        MACOSX_BUNDLE_DISPLAY_NAME "${PROJECT_NAME}"
        MACOSX_BUNDLE_INFO_STRING "${PROJECT_DESCRIPTION}"
        MACOSX_BUNDLE_COPYRIGHT "2012-2023 ${CMAKE_PROJECT_NAME} Authors"
        MAXOSX_BUNDLE_ICON_FILE ${PROJECT_NAME}.icns
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    )
    if(APPLE)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${PLATFORMDEPLOYQT} $<TARGET_BUNDLE_DIR:${PROJECT_NAME}> -qmldir=${CMAKE_CURRENT_SOURCE_DIR}
        )
    elseif(UNIX AND NOT APPLE)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            INSTALL_RPATH ${INSTALL_RPATH_STRING}
        )
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.desktop)
            install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.desktop" DESTINATION ${CMAKE_INSTALL_DATADIR}/applications/ COMPONENT ${PROJECT_NAME})
        else()
            configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/demoTemplate.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop @ONLY)
            install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop" DESTINATION ${CMAKE_INSTALL_DATADIR}/applications/ COMPONENT ${PROJECT_NAME})
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.png)
            install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.png" DESTINATION ${CMAKE_INSTALL_DATADIR}/pixmaps COMPONENT ${PROJECT_NAME})
        else()
            install(FILES "${CMAKE_SOURCE_DIR}/cmake/_template/demoTemplate.png" DESTINATION ${CMAKE_INSTALL_DATADIR}/pixmaps RENAME "${PROJECT_NAME}.png" COMPONENT ${PROJECT_NAME})
        endif()
    endif()

    install(TARGETS ${PROJECT_NAME}
        COMPONENT ${PROJECT_NAME}
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    sbom_add(TARGET ${PROJECT_NAME})

    set_property(GLOBAL APPEND PROPERTY ${CMAKE_PROJECT_NAME}_targets ${PROJECT_NAME})
    list(APPEND CPACK_PACKAGE_EXECUTABLES "${PROJECT_NAME};${PROJECT_NAME}")
endmacro()
#####~~~~~~~~~~~~~~~~~~~~~MAKE_TEST~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# MAKE_TEST - Set up a unit test
# NAME - Name of the new Test
# FILE - cpp File for the Test
macro (MAKE_TEST NAME FILE)
    get_filename_component(curDir ${CMAKE_CURRENT_SOURCE_DIR} NAME)
    set(DEP_LIB ${CMAKE_PROJECT_NAME})
    if( NOT ${curDir} MATCHES core)
        string(SUBSTRING ${curDir} 0 1 FIRST_LETTER)
        string(TOUPPER ${FIRST_LETTER} FIRST_LETTER)
        string(REGEX REPLACE "^.(.*)" "${FIRST_LETTER}\\1" curDir_UPPER "${curDir}")
        string(APPEND DEP_LIB "${curDir_UPPER}")
    endif()
    add_executable( ${NAME} ${FILE} )
    target_link_libraries( ${NAME} ${DEP_LIB} Qt::Test)
    add_test(NAME ${NAME} COMMAND $<TARGET_FILE:${NAME}> WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/../../src/${curDir}")
    set_tests_properties(${NAME} PROPERTIES DEPENDS ${DEP_LIB})
    set_property(GLOBAL APPEND PROPERTY ${CMAKE_PROJECT_NAME}_tests ${NAME})
endmacro()


####~~~~~~~~~~~~~~~~~~~~~~git_version_from_tag~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#git_version_from_tag(OUTPUT <var-name> [MAJOR <value>] [MINOR <value>] [PATCH <value>] [TWEAK <value> ])
#This Function will set the variable <var_name> to semantic version value based on the last git tag
#This Requires a tag in the format of vX.Y.Z in order to construct a proper verson
## REQUIRED ARGUMENTS
# OUTPUT <value> - The name of the variable the version will be written into
## OPTIONAL ARGUMENTS
# MAJOR <value> - the MAJOR argument sets the fallback major to use if its unable to be detected [Default: 0]
# MINOR <value> - the MINOR argument sets the fallback minor to use if its unable to be detected [Default: 0]
# PATCH <value> - the PATCH argument sets the fallback patch to use if its unable to be detected [Default: 0]
# TWEAK <value> - the TWEAK argument sets the fallback tweak to use if its unable to be detected [Default: 0]
#Optional MAJOR, MINOR, PATCH should be set when calling they will be used if git can not be found or tag can not be processed.For this reason the MAJOR, MINOR and PATCH should should be synced with semantic tag in git
#The Tweak is auto generated based on the number of commits since the last tag
function(git_version_from_tag)
    set(options)
    set(oneValueArgs
        OUTPUT # The Variable to write into
        MAJOR # Fallback Version Major
        MINOR # Fallback Version Minor
        PATCH # Fallback Version Patch
        TWEAK # Fallback Version Patch
    )
    set(multiValueArgs)
    cmake_parse_arguments(m "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(m_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${m_UNPARSED_ARGUMENTS}")
    endif()

    if("${m_OUTPUT}" STREQUAL "")
        message(FATAL_ERROR "No OUTPUT set")
    endif()
    if(NOT m_MAJOR})
        set(m_MAJOR 0)
    endif()

    if(NOT m_MINOR)
        set(m_MINOR 0)
    endif()

    if(NOT m_PATCH)
        set(m_PATCH 0)
    endif()

    if(NOT m_TWEAK)
        set(m_TWEAK 0)
    endif()

    set(VERSION_MAJOR ${m_MAJOR})
    set(VERSION_MINOR ${m_MINOR})
    set(VERSION_PATCH ${m_PATCH})
    set(VERSION_TWEAK ${m_TWEAK})

    if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
        find_package(Git)
        if(GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --long --match v* --always
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE GITREV
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)
            string(FIND ${GITREV} "v" isRev)
            if(NOT isRev EQUAL -1)
                string(REGEX MATCH [0-9]+ MAJOR ${GITREV})
                string(REGEX MATCH \\.[0-9]+ MINOR ${GITREV})
                string(REPLACE "." "" MINOR "${MINOR}")
                string(REGEX MATCH [0-9]+\- PATCH ${GITREV})
                string(REPLACE "-" "" PATCH "${PATCH}")
                string(REGEX MATCH \-[0-9]+\- TWEAK ${GITREV})
                string(REPLACE "-" "" TWEAK "${TWEAK}")
                set(VERSION_MAJOR ${MAJOR})
                set(VERSION_MINOR ${MINOR})
                set(VERSION_PATCH ${PATCH})
                set(VERSION_TWEAK ${TWEAK})
            elseif(NOT ${GITREV} STREQUAL "")
                message(STATUS "Unable to process tag")
            endif()
        endif()
    endif()
    set(${m_OUTPUT} "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}.${VERSION_TWEAK}" PARENT_SCOPE)
endfunction()


# Common Platform Enumeration: https://nvd.nist.gov/products/cpe
#
# TODO: This detection can be improved.
# Detect CPE String Called by sbom_generate
function (detectCPE)
    if(DEFINED SBOM_CPE)
        return()
    endif()
    if(WIN32)
        if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
            set(_arch "x64")
        elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "IA64")
            set(_arch "x64")
        elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "ARM64")
            set(_arch "arm64")
        elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "X86")
            set(_arch "x86")
        elseif(CMAKE_CXX_COMPILER MATCHES "64")
            set(_arch "x64")
        elseif(CMAKE_CXX_COMPILER MATCHES "86")
            set(_arch "x86")
        else()
            set(_arch "*")
        endif()

        if("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.1")
            set(CPE "cpe:2.3:o:microsoft:windows_7:-:*:*:*:*:*:${_arch}:*")
        elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.2")
            set(CPE "cpe:2.3:o:microsoft:windows_8:-:*:*:*:*:*:${_arch}:*")
        elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.3")
            set(CPE "cpe:2.3:o:microsoft:windows_8.1:-:*:*:*:*:*:${_arch}:*")
        elseif("${CMAKE_SYSTEM_VERSION}" VERSION_GREATER_EQUAL 10)
            set(CPE "cpe:2.3:o:microsoft:windows_10:-:*:*:*:*:*:${_arch}:*")
        else()
            set(CPE "cpe:2.3:o:microsoft:windows:-:*:*:*:*:*:${_arch}:*")
        endif()
    elseif(APPLE)
        set(CPE "cpe:2.3:o:apple:mac_os:*:*:*:*:*:*:${CMAKE_SYSTEM_PROCESSOR}:*")
    elseif(UNIX)
        set(CPE "cpe:2.3:o:canonical:ubuntu_linux:-:*:*:*:*:*:${CMAKE_SYSTEM_PROCESSOR}:*")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
        set(CPE "cpe:2.3:h:arm:arm:-:*:*:*:*:*:*:*")
    else()
        message(FATAL_ERROR "Unsupported platform")
    endif()
    set(SBOM_CPE ${CPE} CACHE STRING "Sbom CPE")
endfunction()

# Sets the given variable to a unique SPDIXID-compatible value.
function(sbom_spdxid)
    set(options)
    set(oneValueArgs VARIABLE CHECK)
    set(multiValueArgs HINTS)
    cmake_parse_arguments(SBOM_SPDXID "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_SPDXID_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_SPDXID_UNPARSED_ARGUMENTS}")
    endif()

    if("${SBOM_SPDXID_VARIABLE}" STREQUAL "")
        message(FATAL_ERROR "Missing VARIABLE")
    endif()

    if("${SBOM_SPDXID_CHECK}" STREQUAL "")
        get_property(_spdxids GLOBAL PROPERTY sbom_spdxids)
        set(_suffix "-${_spdxids}")
        math(EXPR _spdxids "${_spdxids} + 1")
        set_property(GLOBAL PROPERTY sbom_spdxids "${_spdxids}")

        foreach(_hint IN LISTS SBOM_SPDXID_HINTS)
            string(REGEX REPLACE "[^a-zA-Z0-9]+" "-" _id "${_hint}")
            string(REGEX REPLACE "-+$" "" _id "${_id}")
            if(NOT "${_id}" STREQUAL "")
                set(_id "${_id}${_suffix}")
                break()
            endif()
        endforeach()

        if("${_id}" STREQUAL "")
            set(_id "SPDXRef${_suffix}")
        endif()
    else()
        set(_id "${SBOM_SPDXID_CHECK}")
    endif()

    if(NOT "${_id}" MATCHES "^SPDXRef-[-a-zA-Z0-9]+$")
        message(FATAL_ERROR "Invalid SPDXID \"${_id}\"")
    endif()

    set(${SBOM_SPDXID_VARIABLE} "${_id}" PARENT_SCOPE)
endfunction()

# Starts SBOM generation. Call sbom_add() and friends afterwards. End with sbom_finalize(). Input
# files allow having variables and generator expressions.
function(sbom_generate)
    set(options)
    set(oneValueArgs
        OUTPUT
        LICENSE
        COPYRIGHT
        PROJECT
        SUPPLIER
        SUPPLIER_URL
        NAMESPACE
    )
    set(multiValueArgs INPUT)
    cmake_parse_arguments(SBOM_GENERATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_GENERATE_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_GENERATE_UNPARSED_ARGUMENTS}")
    endif()

    string(TIMESTAMP NOW_UTC UTC)

    #Set our SBOM_CPE
    detectCPE()

    if("${SBOM_GENERATE_OUTPUT}" STREQUAL "")
        set(SBOM_GENERATE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}-sbom-${PROJECT_VERSION}.spdx")
    endif()

    if("${SBOM_GENERATE_LICENSE}" STREQUAL "")
        set(SBOM_GENERATE_LICENSE "NOASSERTION")
    endif()

    set(SBOM_CONCLUDED_LICENSE ${SBOM_GENERATE_LICENSE} CACHE STRING "license for binaries")

    if("${SBOM_GENERATE_PROJECT}" STREQUAL "")
        set(SBOM_GENERATE_PROJECT "${PROJECT_NAME}")
    endif()

    if("${SBOM_GENERATE_SUPPLIER}" STREQUAL "")
        set(SBOM_GENERATE_SUPPLIER "${SBOM_SUPPLIER}")
    elseif("${SBOM_SUPPLIER_URL}" STREQUAL "")
        set(SBOM_SUPPLIER "${SBOM_GENERATE_SUPPLIER}" CACHE STRING "SBOM supplier")
    endif()

    if("${SBOM_GENERATE_COPYRIGHT}" STREQUAL "")
        # There is a race when building at New Year's Eve...
        string(TIMESTAMP NOW_YEAR "%Y" UTC)
        set(SBOM_GENERATE_COPYRIGHT "${NOW_YEAR} ${SBOM_GENERATE_SUPPLIER}")
    endif()

    if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
        set(SBOM_GENERATE_SUPPLIER_URL "${SBOM_SUPPLIER_URL}")
        if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
            set(SBOM_GENERATE_SUPPLIER_URL "${PROJECT_HOMEPAGE_URL}")
        endif()
    elseif("${SBOM_SUPPLIER_URL}" STREQUAL "")
        set(SBOM_SUPPLIER_URL
            "${SBOM_GENERATE_SUPPLIER_URL}"
            CACHE STRING "SBOM supplier URL"
        )
    endif()

    if("${SBOM_GENERATE_NAMESPACE}" STREQUAL "")
        set(SBOM_GENERATE_NAMESPACE "${SBOM_GENERATE_SUPPLIER_URL}/spdxdocs/${PROJECT_NAME}-${PROJECT_VERSION}")
    endif()

    string(REGEX REPLACE "[^-A-Za-z0-9.]+" "-" SBOM_GENERATE_PROJECT "${SBOM_GENERATE_PROJECT}")

    install(
        CODE "
        message(STATUS \"Installing: ${SBOM_GENERATE_OUTPUT}\")
        set(SBOM_EXT_DOCS)
        file(WRITE \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\" \"\")
        "
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/sbom)

    if("${SBOM_GENERATE_INPUT}" STREQUAL "")
        if("${SBOM_GENERATE_SUPPLIER}" STREQUAL "")
            message(FATAL_ERROR "Specify a SUPPLIER, or set SBOM_SUPPLIER")
        endif()

        if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
            message(FATAL_ERROR "Specify a SUPPLIER_URL, or set SBOM_SUPPLIER_URL")
        endif()

        set(_f "${CMAKE_CURRENT_BINARY_DIR}/SPDXRef-DOCUMENT.spdx.in")

        get_filename_component(doc_name "${SBOM_GENERATE_OUTPUT}" NAME_WE)
        configure_file(${CMAKE_SOURCE_DIR}/cmake/_template/sbom-document.in ${_f} @ONLY)

        install(
            CODE "
            file(READ \"${_f}\" _f_contents)
            file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\" \"\${_f_contents}\")
            "
        )

        set(SBOM_LAST_SPDXID "SPDXRef-${SBOM_GENERATE_PROJECT}" PARENT_SCOPE)
    else()
        foreach(_f IN LISTS SBOM_GENERATE_INPUT)
            get_filename_component(_f_name "${_f}" NAME)
            set(_f_in "${CMAKE_CURRENT_BINARY_DIR}/${_f_name}")
            set(_f_in_gen "${_f_in}_gen")
            configure_file("${_f}" "${_f_in}" @ONLY)
            file(GENERATE OUTPUT "${_f_in_gen}" INPUT "${_f_in}")
            install(
                CODE "
                file(READ \"${_f_in_gen}\" _f_contents)
                file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\" \"\${_f_contents}\")
                "
            )
        endforeach()
        set(SBOM_LAST_SPDXID "" PARENT_SCOPE)
    endif()
    install(CODE "set(SBOM_VERIFICATION_CODES)")
    set_property(GLOBAL PROPERTY SBOM_FILENAME "${SBOM_GENERATE_OUTPUT}")
    set(SBOM_FILENAME "${SBOM_GENERATE_OUTPUT}" PARENT_SCOPE)
    set_property(GLOBAL PROPERTY sbom_project "${SBOM_GENERATE_PROJECT}")
    set_property(GLOBAL PROPERTY sbom_spdxids 0)
    file(WRITE ${CMAKE_BINARY_DIR}/sbom/CMakeLists.txt "")
endfunction()

# Find python.
#
# Usage sbom_find_python([REQUIRED])
macro(sbom_find_python)
    if(Python3_EXECUTABLE)
        set(Python3_FOUND TRUE)
    elseif(CMAKE_VERSION VERSION_GREATER_EQUAL 3.12)
        find_package(Python3 COMPONENTS Interpreter ${ARGV})
    else()
        if(WIN32)
            find_program(Python3_EXECUTABLE NAMES python ${ARGV})
        else()
            find_program(Python3_EXECUTABLE NAMES python3 ${ARGV})
        endif()

        if(Python3_EXECUTABLE)
            set(Python3_FOUND TRUE)
        else()
            set(Python3_FOUND FALSE)
        endif()
    endif()

    if(Python3_FOUND)
        if(NOT DEFINED SBOM_HAVE_PYTHON_DEPS)
            execute_process(
                COMMAND
                ${Python3_EXECUTABLE} -c "
                import spdx_tools.spdx.clitools.pyspdxtools
                import ntia_conformance_checker.main
                "
                RESULT_VARIABLE _res
                ERROR_QUIET OUTPUT_QUIET
            )

            if("${_res}" STREQUAL "0")
                set(SBOM_HAVE_PYTHON_DEPS TRUE CACHE INTERNAL "")
            else()
                set(SBOM_HAVE_PYTHON_DEPS FALSE CACHE INTERNAL "")
            endif()
        endif()

        if("${ARGN}" STREQUAL "REQUIRED" AND NOT SBOM_HAVE_PYTHON_DEPS)
            message(FATAL_ERROR "Missing python packages")
        endif()
    endif()
endmacro()

# Verify the generated SBOM. Call after sbom_generate() and other SBOM populating commands.
function(sbom_finalize)
    set(options NO_VERIFY VERIFY)
    set(oneValueArgs GRAPH)
    set(multiValueArgs)
    cmake_parse_arguments(SBOM_FINALIZE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_FINALIZE_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_FINALIZE_UNPARSED_ARGUMENTS}")
    endif()

    get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
    get_property(_sbom_project GLOBAL PROPERTY sbom_project)

    if("${_sbom_project}" STREQUAL "")
        message(FATAL_ERROR "Call sbom_generate() first")
    endif()

    file(
        WRITE ${CMAKE_BINARY_DIR}/sbom/verify.cmake
        "
        message(STATUS \"Finalizing: ${_sbom}\")
        list(SORT SBOM_VERIFICATION_CODES)
        string(REPLACE \";\" \"\" SBOM_VERIFICATION_CODES \"\${SBOM_VERIFICATION_CODES}\")
        file(WRITE \"${CMAKE_BINARY_DIR}/sbom/verification.txt\" \"\${SBOM_VERIFICATION_CODES}\")
        file(SHA1 \"${CMAKE_BINARY_DIR}/sbom/verification.txt\" SBOM_VERIFICATION_CODE)
        configure_file(\"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\" \"${_sbom}\")
        "
    )

    if(NOT "${SBOM_FINALIZE_GRAPH}" STREQUAL "")
        set(SBOM_FINALIZE_NO_VERIFY FALSE)
        set(SBOM_FINALIZE_VERIFY TRUE)
        set(_graph --graph --outfile "${SBOM_FINALIZE_GRAPH}")
    else()
        set(_graph)
    endif()

    if(SBOM_FINALIZE_NO_VERIFY)
        set(SBOM_FINALIZE_VERIFY FALSE)
    else()
        if(SBOM_FINALIZE_VERIFY)
            # Force verify.
            set(_req REQUIRED)
        else()
            # Check if we can verify.
            set(_req)
        endif()

        sbom_find_python(${_req})

        if(Python3_FOUND)
            set(SBOM_FINALIZE_VERIFY TRUE)
        endif()
    endif()

    if(SBOM_FINALIZE_VERIFY)
        file(
            APPEND ${CMAKE_BINARY_DIR}/sbom/verify.cmake
            "
            message(STATUS \"Verifying: ${_sbom}\")
            execute_process(
                COMMAND ${Python3_EXECUTABLE} -m spdx_tools.spdx.clitools.pyspdxtools
                -i \"${_sbom}\" ${_graph}
                RESULT_VARIABLE _res
            )
            if(NOT _res EQUAL 0)
                message(FATAL_ERROR \"SBOM verification failed\")
            endif()

            execute_process(
                COMMAND ${Python3_EXECUTABLE} -m ntia_conformance_checker.main
                --file \"${_sbom}\"
                RESULT_VARIABLE _res
            )
            if(NOT _res EQUAL 0)
                message(FATAL_ERROR \"SBOM NTIA verification failed\")
            endif()
            "
        )
    endif()

    file(APPEND ${CMAKE_BINARY_DIR}/sbom/CMakeLists.txt "install(SCRIPT verify.cmake)")

    # Workaround for pre-CMP0082.
    add_subdirectory(${CMAKE_BINARY_DIR}/sbom ${CMAKE_BINARY_DIR}/sbom)

    # Mark finalized.
    set(SBOM_FILENAME "${_sbom}" PARENT_SCOPE)
    set_property(GLOBAL PROPERTY sbom_project "")
endfunction()

# Append a file to the SBOM. Use this after calling sbom_generate().
function(sbom_file)
    set(options OPTIONAL)
    set(oneValueArgs FILENAME FILETYPE RELATIONSHIP SPDXID LICENSE)
    set(multiValueArgs)
    cmake_parse_arguments(SBOM_FILE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if(SBOM_FILE_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_FILE_UNPARSED_ARGUMENTS}")
    endif()

    if("${SBOM_FILE_FILENAME}" STREQUAL "")
        message(FATAL_ERROR "Missing FILENAME argument")
    endif()

    sbom_spdxid(
        VARIABLE SBOM_FILE_SPDXID
        CHECK "${SBOM_FILE_SPDXID}"
        HINTS "SPDXRef-${SBOM_FILE_FILENAME}"
    )

    set(SBOM_LAST_SPDXID "${SBOM_FILE_SPDXID}" PARENT_SCOPE)

    if("${SBOM_FILE_FILETYPE}" STREQUAL "")
        message(FATAL_ERROR "Missing FILETYPE argument")
    endif()

    get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
    get_property(_sbom_project GLOBAL PROPERTY sbom_project)


    if("${SBOM_FILE_LICENSE}" STREQUAL "")
        set(SBOM_FILE_LICENSE ${SBOM_CONCLUDED_LICENSE})
    endif()

    if("${SBOM_FILE_RELATIONSHIP}" STREQUAL "")
        set(SBOM_FILE_RELATIONSHIP "SPDXRef-${_sbom_project} CONTAINS ${SBOM_FILE_SPDXID}")
        set(SBOM_FILE_LICENSE_CONCLUDED )
    else()
        string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_FILE_SPDXID}" SBOM_FILE_RELATIONSHIP "${SBOM_FILE_RELATIONSHIP}")
    endif()

    if("${_sbom_project}" STREQUAL "")
        message(FATAL_ERROR "Call sbom_generate() first")
    endif()

    file(
        GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_FILE_SPDXID}.cmake
        CONTENT
        "
        cmake_policy(SET CMP0011 NEW)
        cmake_policy(SET CMP0012 NEW)
        if(NOT EXISTS $<TARGET_FILE:${SBOM_TARGET_TARGET}>)
            if(NOT ${SBOM_FILE_OPTIONAL})
                message(FATAL_ERROR \"Cannot find ${SBOM_FILE_FILENAME}\")
            endif()
        else()
            file(SHA1 $<TARGET_FILE:${SBOM_TARGET_TARGET}> _sha1)
            list(APPEND SBOM_VERIFICATION_CODES \${_sha1})
            file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\"
                \"
FileName: ./${SBOM_FILE_FILENAME}
SPDXID: ${SBOM_FILE_SPDXID}
FileType: ${SBOM_FILE_FILETYPE}
FileChecksum: SHA1: \${_sha1}
LicenseConcluded: ${SBOM_CONCLUDED_LICENSE}
LicenseInfoInFile: NOASSERTION
FileCopyrightText: NOASSERTION
Relationship: ${SBOM_FILE_RELATIONSHIP}
                \"
            )
        endif()
        "
    )
    install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_FILE_SPDXID}.cmake)
endfunction()

# Append a target output to the SBOM. Use this after calling sbom_generate().
function(sbom_target)
    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs)
    cmake_parse_arguments(SBOM_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if("${SBOM_TARGET_TARGET}" STREQUAL "")
        message(FATAL_ERROR "Missing TARGET argument")
    endif()

    get_target_property(_type ${SBOM_TARGET_TARGET} TYPE)
    if("${_type}" STREQUAL "EXECUTABLE")
        sbom_file(FILENAME ${CMAKE_INSTALL_BINDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
            FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
        )
    elseif("${_type}" STREQUAL "STATIC_LIBRARY")
        sbom_file(FILENAME ${CMAKE_INSTALL_LIBDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
            FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
        )
    elseif("${_type}" STREQUAL "SHARED_LIBRARY")
        if(WIN32)
            sbom_file(
                FILENAME
                ${CMAKE_INSTALL_BINDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
                FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
            )
            sbom_file(
                FILENAME
                ${CMAKE_INSTALL_LIBDIR}/$<TARGET_LINKER_FILE_NAME:${SBOM_TARGET_TARGET}>
                FILETYPE BINARY OPTIONAL ${SBOM_TARGET_UNPARSED_ARGUMENTS}
            )
        else()
            sbom_file(
                FILENAME
                ${CMAKE_INSTALL_LIBDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
                FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
            )
        endif()
    else()
        message(FATAL_ERROR "Unsupported target type ${_type}")
    endif()
    set(SBOM_LAST_SPDXID "${SBOM_LAST_SPDXID}" PARENT_SCOPE)
endfunction()

# Append all files recursively in a directory to the SBOM. Use this after calling sbom_generate().
function(sbom_directory)
    set(options)
    set(oneValueArgs DIRECTORY FILETYPE RELATIONSHIP)
    set(multiValueArgs)
    cmake_parse_arguments(SBOM_DIRECTORY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_DIRECTORY_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_DIRECTORY_UNPARSED_ARGUMENTS}")
    endif()

    if("${SBOM_DIRECTORY_DIRECTORY}" STREQUAL "")
        message(FATAL_ERROR "Missing DIRECTORY argument")
    endif()

    sbom_spdxid(VARIABLE SBOM_DIRECTORY_SPDXID HINTS "SPDXRef-${SBOM_DIRECTORY_DIRECTORY}")
    set(SBOM_LAST_SPDXID "${SBOM_DIRECTORY_SPDXID}")

    if("${SBOM_DIRECTORY_FILETYPE}" STREQUAL "")
        message(FATAL_ERROR "Missing FILETYPE argument")
    endif()

    get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
    get_property(_sbom_project GLOBAL PROPERTY sbom_project)

    if("${SBOM_DIRECTORY_RELATIONSHIP}" STREQUAL "")
        set(SBOM_DIRECTORY_RELATIONSHIP "SPDXRef-${_sbom_project} CONTAINS ${SBOM_DIRECTORY_SPDXID}")
    else()
        string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_DIRECTORY_SPDXID}" SBOM_DIRECTORY_RELATIONSHIP "${SBOM_DIRECTORY_RELATIONSHIP}")
    endif()

    if("${_sbom_project}" STREQUAL "")
        message(FATAL_ERROR "Call sbom_generate() first")
    endif()

    file(
        GENERATE
        OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${SBOM_DIRECTORY_SPDXID}.cmake"
        CONTENT
        "
        file(GLOB_RECURSE _files
            LIST_DIRECTORIES false RELATIVE \"${CMAKE_CURRENT_BINARY_DIR}\"
            \"${CMAKE_CURRENT_BINARY_DIR}/${SBOM_DIRECTORY_DIRECTORY}/*\"
        )

        set(_count 0)
        foreach(_f IN LISTS _files)
            file(SHA1 \"${CMAKE_CURRENT_BINARY_DIR}/\${_f}\" _sha1)
            list(APPEND SBOM_VERIFICATION_CODES \${_sha1})
            file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\"
            \"
FileName: ./\${_f}
SPDXID: ${SBOM_DIRECTORY_SPDXID}-\${_count}
FileType: ${SBOM_DIRECTORY_FILETYPE}
FileChecksum: SHA1: \${_sha1}
LicenseConcluded: NOASSERTION
LicenseInfoInFile: NOASSERTION
FileCopyrightText: NOASSERTION
Relationship: ${SBOM_DIRECTORY_RELATIONSHIP}-\${_count}
            \"
            )
            math(EXPR _count \"\${_count} + 1\")
        endforeach()
       "
    )

    install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_DIRECTORY_SPDXID}.cmake)
    set(SBOM_LAST_SPDXID "" PARENT_SCOPE)
endfunction()

# Append a package (without files) to the SBOM. Use this after calling sbom_generate().
function(sbom_package)
    set(options)
    set(oneValueArgs
        PACKAGE
        VERSION
        LICENSE
        DOWNLOAD_LOCATION
        RELATIONSHIP
        SPDXID
        SUPPLIER
    )
    set(multiValueArgs EXTREF)
    cmake_parse_arguments(SBOM_PACKAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_PACKAGE_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_PACKAGE_UNPARSED_ARGUMENTS}")
    endif()

    if("${SBOM_PACKAGE_PACKAGE}" STREQUAL "")
        message(FATAL_ERROR "Missing PACKAGE")
    endif()

    if("${SBOM_PACKAGE_DOWNLOAD_LOCATION}" STREQUAL "")
        set(SBOM_PACKAGE_DOWNLOAD_LOCATION NOASSERTION)
    endif()

    sbom_spdxid(
        VARIABLE SBOM_PACKAGE_SPDXID
        CHECK "${SBOM_PACKAGE_SPDXID}"
        HINTS "SPDXRef-${SBOM_PACKAGE_PACKAGE}"
    )

    set(SBOM_LAST_SPDXID "${SBOM_PACKAGE_SPDXID}" PARENT_SCOPE)
    set(_fields)

    if("${SBOM_PACKAGE_VERSION}" STREQUAL "")
        set(SBOM_PACKAGE_VERSION "unknown")
    endif()

    if("${SBOM_PACKAGE_SUPPLIER}" STREQUAL "")
        set(SBOM_PACKAGE_SUPPLIER "Person: Anonymous")
    endif()

    if(NOT "${SBOM_PACKAGE_LICENSE}" STREQUAL "")
        set(_fields "${_fields}\nPackageLicenseConcluded: ${SBOM_PACKAGE_LICENSE}")
    else()
        set(_fields "${_fields}\nPackageLicenseConcluded: NOASSERTION")
    endif()

    foreach(_ref IN LISTS SBOM_PACKAGE_EXTREF)
        set(_fields "${_fields}\nExternalRef: ${_ref}")
    endforeach()

    get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
    get_property(_sbom_project GLOBAL PROPERTY sbom_project)

    if("${SBOM_PACKAGE_RELATIONSHIP}" STREQUAL "")
        set(SBOM_PACKAGE_RELATIONSHIP "SPDXRef-${_sbom_project} DEPENDS_ON ${SBOM_PACKAGE_SPDXID}")
    else()
        string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_PACKAGE_SPDXID}" SBOM_PACKAGE_RELATIONSHIP "${SBOM_PACKAGE_RELATIONSHIP}")
    endif()

    if("${_sbom_project}" STREQUAL "")
        message(FATAL_ERROR "Call sbom_generate() first")
    endif()

    file(
        GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_PACKAGE_SPDXID}.cmake
        CONTENT
        "file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\"
            \"
PackageName: ${SBOM_PACKAGE_PACKAGE}
SPDXID: ${SBOM_PACKAGE_SPDXID}
ExternalRef: SECURITY cpe23Type ${SBOM_CPE}
PackageDownloadLocation: ${SBOM_PACKAGE_DOWNLOAD_LOCATION}
PackageLicenseDeclared: NOASSERTION
PackageCopyrightText: NOASSERTION
PackageVersion: ${SBOM_PACKAGE_VERSION}
PackageSupplier: ${SBOM_PACKAGE_SUPPLIER}
FilesAnalyzed: false${_fields}
Relationship: ${SBOM_PACKAGE_RELATIONSHIP}
            \"
        )"
    )

    file(APPEND ${CMAKE_BINARY_DIR}/sbom/CMakeLists.txt "install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_PACKAGE_SPDXID}.cmake)\n")
endfunction()

# Add a reference to a package in an external file.
function(sbom_external)
    set(options)
    set(oneValueArgs EXTERNAL FILENAME RENAME SPDXID RELATIONSHIP)
    set(multiValueArgs)
    cmake_parse_arguments(SBOM_EXTERNAL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SBOM_EXTERNAL_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${SBOM_EXTERNAL_UNPARSED_ARGUMENTS}")
    endif()

    if("${SBOM_EXTERNAL_EXTERNAL}" STREQUAL "")
        message(FATAL_ERROR "Missing EXTERNAL")
    endif()

    if("${SBOM_EXTERNAL_FILENAME}" STREQUAL "")
        message(FATAL_ERROR "Missing FILENAME")
    endif()

    if("${SBOM_EXTERNAL_SPDXID}" STREQUAL "")
        get_property(_spdxids GLOBAL PROPERTY sbom_spdxids)
        set(SBOM_EXTERNAL_SPDXID "DocumentRef-${_spdxids}")
        math(EXPR _spdxids "${_spdxids} + 1")
        set_property(GLOBAL PROPERTY sbom_spdxids "${_spdxids}")
    endif()

    if(NOT "${SBOM_EXTERNAL_SPDXID}" MATCHES "^DocumentRef-[-a-zA-Z0-9]+$")
        message(FATAL_ERROR "Invalid DocumentRef \"${SBOM_EXTERNAL_SPDXID}\"")
    endif()

    set(SBOM_LAST_SPDXID "${SBOM_EXTERNAL_SPDXID}" PARENT_SCOPE)
    get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
    get_property(_sbom_project GLOBAL PROPERTY sbom_project)

    if("${_sbom_project}" STREQUAL "")
        message(FATAL_ERROR "Call sbom_generate() first")
    endif()

    get_filename_component(sbom_dir "${_sbom}" DIRECTORY)

    if("${SBOM_EXTERNAL_RELATIONSHIP}" STREQUAL "")
        set(SBOM_EXTERNAL_RELATIONSHIP "SPDXRef-${_sbom_project} DEPENDS_ON ${SBOM_EXTERNAL_SPDXID}:${SBOM_EXTERNAL_EXTERNAL}")
    else()
        string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_EXTERNAL_SPDXID}" SBOM_EXTERNAL_RELATIONSHIP "${SBOM_EXTERNAL_RELATIONSHIP}")
    endif()

    # Filename may not exist yet, and it could be a generator expression.
    file(
        GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_EXTERNAL_SPDXID}.cmake
        CONTENT
        "
        file(SHA1 \"${SBOM_EXTERNAL_FILENAME}\" ext_sha1)
        file(READ \"${SBOM_EXTERNAL_FILENAME}\" ext_content)
        if(\"${SBOM_EXTERNAL_RENAME}\" STREQUAL \"\")
            get_filename_component(ext_name \"${SBOM_EXTERNAL_FILENAME}\" NAME)
            file(WRITE \"${sbom_dir}/\${ext_name}\" \"\${ext_content}\")
        else()
            file(WRITE \"${sbom_dir}/${SBOM_EXTERNAL_RENAME}\" \"\${ext_content}\")
        endif()

        if(NOT \"\${ext_content}\" MATCHES \"[\\r\\n]DocumentNamespace:\")
            message(FATAL_ERROR \"Missing DocumentNamespace in ${SBOM_EXTERNAL_FILENAME}\")
        endif()

        string(REGEX REPLACE \"^.*[\\r\\n]DocumentNamespace:[ \\t]*([^#\\r\\n]*).*$\"
            \"\\\\1\" ext_ns \"\${ext_content}\")

        list(APPEND SBOM_EXT_DOCS \"\nExternalDocumentRef: ${SBOM_EXTERNAL_SPDXID} \${ext_ns} SHA1: \${ext_sha1}\")

        file(APPEND \"${CMAKE_BINARY_DIR}/sbom/sbom.spdx.in\"
        \"\nRelationship: ${SBOM_EXTERNAL_RELATIONSHIP}\")
        "
    )

    file(APPEND ${CMAKE_BINARY_DIR}/sbom/CMakeLists.txt "install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_EXTERNAL_SPDXID}.cmake)\n")
endfunction()

# Append something to the SBOM. Use this after calling sbom_generate().
function(sbom_add type)
    if("${type}" STREQUAL "FILENAME")
        sbom_file(${ARGV})
    elseif("${type}" STREQUAL "DIRECTORY")
        sbom_directory(${ARGV})
    elseif("${type}" STREQUAL "TARGET")
        sbom_target(${ARGV})
    elseif("${type}" STREQUAL "PACKAGE")
        sbom_package(${ARGV})
    elseif("${type}" STREQUAL "EXTERNAL")
        sbom_external(${ARGV})
    else()
        message(FATAL_ERROR "Unsupported sbom_add(${type})")
    endif()

    set(SBOM_LAST_SPDXID
        "${SBOM_LAST_SPDXID}"
        PARENT_SCOPE
    )
endfunction()
