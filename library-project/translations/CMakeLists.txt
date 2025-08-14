# DO NOT REMOVE THE TS FILES
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM 1)

option(CLEAN_TRS "Clean Obsolete translations from tr files" FALSE)
find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED COMPONENTS LinguistTools)

# Set the projects Translation files below
# Exsiting files will be updated when the project is built
# Non Exsiting files will be geneated new empty files for the language.
#
# All Languge files must be named in one of the following formats
# Always use the first form unless the target language is a Country specific variant (ie. zh_CN, zh_TW, pt_BR)
#
# ProjectName_lc.ts
#           OR
# ProjectName_lc_CC.ts
#
# ProjectName is the project name the same as the CMAKE_PROJECT_NAME variable
#
# lc is the Language Code. A ISO-639 alpha-2 code,
#   lc Must be lowercase.
#   Must be in the `SET 1` column of https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes

#
# CC is the Country Code. A valid ISO 3166-1 alpha-2 code
#    CC Must be uppercase
#    Must be in the `CODE` column of https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
#
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
