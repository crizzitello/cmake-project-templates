# DO NOT REMOVE THE TS FILES
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM 1)

option(CLEAN_TRS "Clean Obsolete translations from tr files" FALSE)
find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED COMPONENTS LinguistTools)

set(PACKAGE_TRS
    #THE TS FILES IN THIS DIRECTORY TO INCLUDE
)

if(CLEAN_TRS)
    set(CLEAN_OPTION "-no-obsolete")
else()
    set(CLEAN_OPTION "")
endif()

if(NOT "${PACKAGE_TRS}" STREQUAL "")
    qt_create_translation(TRS ${CMAKE_SOURCE_DIR}/src ${PACKAGE_TRS} OPTIONS -no-ui-lines -locations none ${CLEAN_OPTION})
    add_custom_target(${CMAKE_PROJECT_NAME}_translations ALL DEPENDS ${TRS})

    install(FILES ${TRS} DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}/translations COMPONENT ${CMAKE_PROJECT_NAME}_i18n)
endif()
