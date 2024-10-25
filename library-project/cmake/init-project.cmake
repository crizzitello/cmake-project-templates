# 2023 - 2024 Chris Rizzitello
# Modified to more fit a project template.


##### CMAKE POLICIES
# Allow Cmake to use the cmake or env var <package>_ROOT for find_package calls for <package>
# https://cmake.org/cmake/help/latest/policy/CMP0074.html
cmake_policy(SET CMP0074 NEW)

###~~~~ _project_from_file
#Read project info
function(_project_from_file IN_FILE)
    set(options)
    set(oneValueArgs
        NAME_OUTPUT    # The Variable to write the name into
        DESC_OUTPUT    # Single line description for the project
        VERSION_OUTPUT # Version to fallback to if unable to detect version info
        SUPPLIER_OUTPUT # The Person, Group or Company making the project. Used for package creation
        HOMEPAGE_OUTPUT # URL For the project
        LICENSE_OUTPUT # License the project is under
        CONTACT_OUTPUT # Project Contact Person
        COMPATIBILITY_OUTPUT #Should be [AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion] ${CMAKE_PROJECT_COMPATIBILITY} if that is not set will fallback to ExactVersion
    )
set(multiValueArgs)
cmake_parse_arguments(m "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

if(m_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown arguments: ${m_UNPARSED_ARGUMENTS}")
endif()

if("${IN_FILE}" STREQUAL "")
    message(FATAL_ERROR "You must set a file to read")
endif()

if(EXISTS "${IN_FILE}")
    FILE(STRINGS "${IN_FILE}" VERSION_FILE_CONTENTS)
    message(DEBUG "Reading Version from file: ${IN_FILE}")
else()
    message(FATAL_ERROR "Unable to read file ${IN_FILE}")
endif()

foreach(LINE IN LISTS VERSION_FILE_CONTENTS)
    if( "${LINE}" MATCHES "^PROJECT")
        string(REGEX REPLACE "^PROJECT *:? *" "" m_PROJECT_NAME ${LINE})
        message(DEBUG "PROJECT NAME IS:${m_PROJECT_NAME}")
    elseif( "${LINE}" MATCHES "^DESC")
        string(REGEX REPLACE "^DESC *:? *" "" m_PROJECT_DESC "${LINE}")
        message(DEBUG "PROJECT DESC IS:${m_PROJECT_DESC}")
    elseif( "${LINE}" MATCHES "^HOMEPAGE")
        string(REGEX REPLACE "^HOMEPAGE *:? *" "" m_PROJECT_HOMEPAGE "${LINE}")
        message(DEBUG "PROJECT HOMEPAGE IS:${m_PROJECT_HOMEPAGE}")
    elseif( "${LINE}" MATCHES "^SUPPLIER")
        string(REGEX REPLACE "^SUPPLIER *:? *" "" m_PROJECT_SUPPLIER "${LINE}")
        message(DEBUG "PROJECT SUPPLIER IS:${m_PROJECT_SUPPLIER}")
    elseif( "${LINE}" MATCHES "^VERSION")
        string(REGEX REPLACE "^VERSION *:? *" "" m_PROJECT_VERSION "${LINE}")
        message(DEBUG "PROJECT VERSION IS:${m_PROJECT_VERSION}")
    elseif( "${LINE}" MATCHES "^LICENSE")
        string(REGEX REPLACE "^LICENSE *:? *" "" m_PROJECT_LICENSE "${LINE}")
        message(DEBUG "PROJECT LICENSE IS:${m_PROJECT_LICENSE}")
    elseif( "${LINE}" MATCHES "^COMPATIBILITY")
        string(REGEX REPLACE "^COMPATIBILITY *:? *" "" m_PROJECT_COMPATIBILITY "${LINE}")
        message(DEBUG "PROJECT COMPATIBILITY IS:${m_PROJECT_COMPATIBILITY}")
    elseif( "${LINE}" MATCHES "^CONTACT")
        string(REGEX REPLACE "^CONTACT *:? *" "" m_PROJECT_CONTACT "${LINE}")
        message(DEBUG "PROJECT CONTACT IS:${m_PROJECT_CONTACT}")
    endif()
  endforeach()

  set(${m_NAME_OUTPUT} ${m_PROJECT_NAME} PARENT_SCOPE)
  set(${m_DESC_OUTPUT} ${m_PROJECT_DESC} PARENT_SCOPE)
  set(${m_VERSION_OUTPUT} ${m_PROJECT_VERSION} PARENT_SCOPE)
  set(${m_SUPPLIER_OUTPUT} ${m_PROJECT_SUPPLIER} PARENT_SCOPE)
  set(${m_HOMEPAGE_OUTPUT} ${m_PROJECT_HOMEPAGE} PARENT_SCOPE)
  set(${m_LICENSE_OUTPUT} ${m_PROJECT_LICENSE} PARENT_SCOPE)
  set(${m_CONTACT_OUTPUT} ${m_PROJECT_CONTACT} PARENT_SCOPE)
  set(${m_COMPATIBILITY_OUTPUT} ${m_PROJECT_COMPATIBILITY} PARENT_SCOPE)
endfunction()

# Parse a version string in the form of M.m.p or M.m.p-t M.m.p.t
# A minimum of M.m.p must be matched if t is not matched it is set to 0
function(_parse_version_string m_VERSION_STRING)
    set(options)
    set(oneValueArgs
        VERSION_OUT # version in form of M.m.p.t
    )
    set(multiValueArgs)

    cmake_parse_arguments(m "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if(m_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${m_UNPARSED_ARGUMENTS}")
    endif()


    if("${m_VERSION_OUT}" STREQUAL "")
        message(FATAL_ERROR "No VERSION_OUT set")
    endif()

    if("${m_VERSION_STRING}" MATCHES "^v?([0-9]+)\\.([0-9]+)[\\.|\-]([0-9]+)\-?([0-9]+)?")
        if("${CMAKE_MATCH_4}" STREQUAL "")
            set(CMAKE_MATCH_4 0)
        endif()
        set(${m_VERSION_OUT} "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}.${CMAKE_MATCH_4}" PARENT_SCOPE)
    else()
        message("Unable to parse version string: ${m_VERISON_STRING}")
    endif()

endfunction()


####~~~~~~~~~~~~~~~~~~~~~~_git_version_from_tag~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#git_version_from_tag(OUTPUT <var-name> [MAJOR <value>] [MINOR <value>] [PATCH <value>] [TWEAK <value> ])
#This Function will set the variable <var_name> to semantic version value based on the last git tag
#This Requires a tag in the format of vX.Y.Z in order to construct a proper verson
## REQUIRED ARGUMENTS
# OUTPUT <value> - The name of the variable the version will be written into
## OPTIONAL ARGUMENTS
# FALLBACK - The version to be used if one can not be detected use M.m.p or M.m.p.t
#The Tweak is auto generated based on the number of commits since the last tag
function(_git_version_from_tag)
    set(options)
    set(oneValueArgs
        OUTPUT # The Variable to write into
        FALLBACK # FALLBACK STRING
    )
    set(multiValueArgs)
    cmake_parse_arguments(m "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(m_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments: ${m_UNPARSED_ARGUMENTS}")
    endif()

    if("${m_OUTPUT}" STREQUAL "")
        message(FATAL_ERROR "No OUTPUT set")
    endif()

    _parse_version_string (
        "${m_FALLBACK}"
        VERSION_OUT M_VERSION
    )

    if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
        find_package(Git)
        if(GIT_FOUND)
            execute_process(
                COMMAND ${GIT_EXECUTABLE} describe --long --match v* --always
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                OUTPUT_VARIABLE GITREV
                ERROR_QUIET
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            _parse_version_string (
                "${GITREV}"
                VERSION_OUT M_VERSION
            )
        endif()
    endif()
    set(${m_OUTPUT} "${M_VERSION}" PARENT_SCOPE)
endfunction()


##Stup extra of info
function(set_extra_os_info)
    if(WIN32)
    elseif (APPLE)
        execute_process(
          COMMAND bash "-c" "sw_vers | grep ^ProductName= | sed 's/ProductName=\t\t//g'"
          OUTPUT_VARIABLE _NAME
          OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process(
          COMMAND bash "-c" "sw_vers | grep ^ProductVersion= | sed 's/ProductVersion=\t\t//g'"
          OUTPUT_VARIABLE _VERSION_ID
          OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REPLACE "\"" "" _NAME "${_NAME}")
        string(REGEX MATCH [0-9]+ _VERSION_ID ${_VERSION_ID})
    else()
        if(EXISTS "/etc/os-release")
            FILE(STRINGS "/etc/os-release" RELEASE_FILE_CONTENTS)
        else()
            message(FATAL_ERROR "Unable to read file /etc/os-release")
        endif()

        foreach(LINE IN LISTS RELEASE_FILE_CONTENTS)
            if( "${LINE}" MATCHES "^ID=")
                string(REGEX REPLACE "^ID=" "" _NAME ${LINE})
                string(REGEX REPLACE "\"" "" _NAME ${_NAME})
                message(DEBUG "Distro Name :${_NAME}")
            elseif( "${LINE}" MATCHES "^ID_LIKE=")
                string(REGEX REPLACE "^ID_LIKE=" "" _LIKE "${LINE}")
                string(REGEX REPLACE "\"" "" _LIKE ${_LIKE})
                message(DEBUG "Distro Like :${_LIKE}")
            elseif( "${LINE}" MATCHES "^VERSION_CODENAME=")
                string(REGEX REPLACE "^VERSION_CODENAME=" "" _CODENAME "${LINE}")
                string(REGEX REPLACE "\"" "" _CODENAME "${_CODENAME}")
                message(DEBUG "Distro Codename:${_CODENAME}")
            elseif( "${LINE}" MATCHES "^VERSION_ID=")
                string(REGEX REPLACE "^VERSION_ID=" "" _VERSION_ID "${LINE}")
                string(REGEX REPLACE "\"" "" _VERSION_ID "${_VERSION_ID}")
                message(DEBUG "Distro VersionID:${_VERSION_ID}")
            elseif( "${LINE}" MATCHES "^CPE_NAME=")
                string(REGEX REPLACE "^CPE_NAME=" "" _CPE_NAME "${LINE}")
                string(REGEX REPLACE "\"" "" _CPE_NAME "${_CPE_NAME}")
                message(DEBUG "Distro CPE Name:${_CPE_NAME}")
            endif()
        endforeach()
    endif()

    set(SYSTEM_NAME "${_NAME}" PARENT_SCOPE)
    set(SYSTEM_LIKE "${_LIKE}" PARENT_SCOPE)
    set(SYSTEM_CODENAME "${_CODENAME}" PARENT_SCOPE)
    set(SYSTEM_VERSION_ID "${_VERSION_ID}" PARENT_SCOPE)
    set(SYSTEM_CPE_STRING "${_CPE_NAME}" PARENT_SCOPE)
endfunction()

# checks for a license and sets the project license
function(_check_license_file OUT_VAR)
    #Set the License File
    if(EXISTS "${CMAKE_SOURCE_DIR}/COPYING.TXT")
        set(${OUT_VAR} "${CMAKE_CURRENT_SOURCE_DIR}/COPYING.TXT" PARENT_SCOPE)
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/LICENSE.txt")
        set(${OUT_VAR} "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "No License to install create a COPYING.TXT or LICENSE.txt in the root dir for the project")
    endif()
endfunction()

################## INIT PROJECT #####################
# This macro will set up your project
# Requires a project name at least
function(read_project_info IN_FILE)
    set(oneValueArgs
        NAME # Set Project Name
        DESC # Single line description for the project
        VERSION # Version to fallback to if unable to detect version info
        SUPPLIER # The Person, Group or Company making the project. Used for package creation
        LICENSE # License the project is under
        COMPATIBILITY #Should be [AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion] ${CMAKE_PROJECT_COMPATIBILITY} if that is not set will fallback to ExactVersion
    )
    cmake_parse_arguments(m "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    ## Sanity Checks
    if(m_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "read_project_info, unknown arguments: ${m_UNPARSED_ARGUMENTS}")
    endif()

    if("${IN_FILE}" STREQUAL "" AND "${m_NAME}" STREQUAL "")
        message(FATAL_ERROR "a Project name or Input File MUST be set")
    endif()

    if(IN_FILE)
        _project_from_file (
            "${IN_FILE}"
            NAME_OUTPUT  _name
            DESC_OUTPUT    _desc
            VERSION_OUTPUT _version
            HOMEPAGE_OUTPUT _homepage
            SUPPLIER_OUTPUT _supplier
            LICENSE_OUTPUT _license
            CONTACT_OUTPUT _contact
            COMPATIBILITY_OUTPUT _compatibility
        )
    endif()

    if (NOT "${m_NAME}" STREQUAL "")
        set(_name ${m_NAME})
    endif()
    string(TOLOWER ${_name} _name_lc)
    string(TOUPPER ${_name} _name_uc)

    if (NOT "${m_DESC}" STREQUAL "")
        set(_desc ${m_DESC})
    endif()

    if (NOT "${m_SUPPLIER}" STREQUAL "")
        set(_supplier ${m_SUPPLIER})
    endif()

    if (NOT "${m_LICENSE}" STREQUAL "")
        set(_license ${m_LICENSE})
    endif()

    if (NOT "${m_CONTACT}" STREQUAL "")
        set(_contact ${m_CONTACT})
    endif()

    if (NOT "${m_COMPATIBILITY}" STREQUAL "")
        set(_compatibility ${m_COMPATIBILITY})
    endif()

    _git_version_from_tag (
        OUTPUT _version
        FALLBACK ${_version}
    )

    _check_license_file(_license_file)

    set(PROJECTS_NAME "${_name}" PARENT_SCOPE)
    set(PROJECTS_DESC "${_desc}" PARENT_SCOPE)
    set(PROJECTS_VERSION "${_version}" PARENT_SCOPE)
    set(PROJECTS_HOMEPAGE "${_homepage}" PARENT_SCOPE)
    # Belowe are not standard Cmake project vars
    set(CMAKE_PROJECT_CONTACT "${_contact}" PARENT_SCOPE)
    set(CMAKE_PROJECT_COMPATIBILITY "${_compatibility}" PARENT_SCOPE)
    set(CMAKE_PROJECT_LICENSE "${_license}" PARENT_SCOPE)
    set(CMAKE_PROJECT_SUPPLIER "${_supplier}" PARENT_SCOPE)
    set(CMAKE_PROJECT_LC_NAME "${_name_lc}" PARENT_SCOPE)
    set(CMAKE_PROJECT_UC_NAME "${_name_uc}" PARENT_SCOPE)
    set(CMAKE_PROJECT_LICENSE_FILE "${_license_file}" PARENT_SCOPE)
endfunction()
