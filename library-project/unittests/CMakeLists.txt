enable_testing()

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED NO_MODULE COMPONENTS
    Test
)

#Add_subdir for each part you want to test.
#should mirror your src directory


#Linux CI is often just a CLI
if(UNIX AND NOT APPLE)
    set(qPA_Platform "QT_QPA_PLATFORM=minimal")
endif()

get_property( PROJECTS_TESTS GLOBAL PROPERTY ${CMAKE_PROJECT_NAME}_tests)

add_custom_target (run_tests ALL DEPENDS ${PROJECTS_TESTS})

add_custom_command(
    TARGET run_tests
    POST_BUILD
    COMMAND ${qPA_Platform} ${CMAKE_CTEST_COMMAND} --test-dir "${CMAKE_BINARY_DIR}/unittests" --output-on-failure
)
