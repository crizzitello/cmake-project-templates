# SPDX-FileCopyrightText: Chris Rizzitello <sithlord48@gmail.com>
# SPDX-License-Identifier: MIT

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED NO_MODULE COMPONENTS
    Core
)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}Config.cmake.in
    "\@PACKAGE_INIT\@\ninclude(CMakeFindDependencyMacro)\nfind_dependency(Qt6 ${REQUIRED_QT_VERSION} COMPONENTS Core)\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/${CMAKE_PROJECT_NAME}Targets.cmake\")"
)

configure_file(Info.h.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}Info.h @ONLY)

set (${CMAKE_PROJECT_NAME}_HEADERS
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}Info.h
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_export.h
)

set (${CMAKE_PROJECT_NAME}_PublicLIBLINKS
      Qt::Core
)

MAKE_LIBRARY(${CMAKE_PROJECT_NAME} ${CMAKE_PROJECT_NAME})
