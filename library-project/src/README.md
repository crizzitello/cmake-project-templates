# About this Directory
This is the `src` dir its contains

  - `CMakeLists.txt`
  - a `core` directory
  - Additional Sub directories for other libraries

## The Core Library
 in core a library named CMAKE_PROJECT_NAMEInfo will be created it will provide version info and location of the i18n files.

### Adding A New Library
 To Add a new library Follow these steps

  1. Decide upon a libaryName (i.e Foo)
  2. In the src directory's `CMakeLists.txt`
      1. Add a new option to the top of the file named with your lib name. Example `option(FOO "Build the Foo Library" ON)`
      2. Towards the bottom add a like that will include your sub dir if the option is on example: `if (FOO) add_subdirectory(foo) endif()`
      3. Document This option in `docs/build.md`
  3. Make a new subdirectory
  4. In the new directory create a `CMakeLists.txt`
     1. Use the core folder for an example
     2. Always Include in var Foo_HEADERS `${CMAKE_CURRENT_BINARY_DIR}/Foo_export.h`. This file will be generated at build time
  5. In the new directory create a `FooConfig.cmake.in` Use your library name in place of `Foo`. This file will be used when an applicton or lib looks for your library.
     1. Use The PROJECT_NAMEConfig.cmake.in as a starting point
     2. Add any other find dependency calls needed to link with this application
     3. Always include the line `include("${CMAKE_CURRENT_LIST_DIR}/${CMAKE_PROJECT_NAME}Targets.cmake")` last
  6. In your class be sure to
     1. Include the export header `#include <foo_export.h>
     2. Use the FOO_EXPORT macro to expose your class ex. `class FOO_EXPORT className ...`

#### Linking your New library
 Your library will be made with an alias of `myProject::foo` foo being the name you have picked

#### Using the MAKE_LIBRARY Macro
To Create a library use the MAKE_LIBRARY macro

usage: `MAKE_LIBRARY(LIB_TARGET HEADER_INSTALL_DIR)`
Input
  - `LIB_TARGET` - Name of Library to Make
  - `HEADER_INSTALL_DIR` sub path of include directory to install the headers into ex:`myProject/foo`

Must Set these variables in the CMakeLists.txt before Calling the macro Remember to replace 'Foo' With your library name

  - `Foo_SRC` List of the libraries source files
  - `Foo_HEADERS` List of libraries headers Must include at least `${CMAKE_CURRENT_BINARY_DIR}/Foo_export.h`
  - `Foo_RESOURCES` List of Resource(s) your library has
  - `Foo_PublicLIBLINKS` Libraries that something linking to your library needs to also link.
  - `Foo_PrivateLIBLINKS` Libraries that only your library needs to link aginst.

  For Qml Moduels you can also set, These items as

  - `Foo_MAKEQMLMODULE` true/false - If True A QML Module will be made by calling qt_add_qml_module instead of add_library
  - `FOO_TARGET_URI` - The URI of the new module
  - `Foo_RESOURCE_PREFIX` - Set to /qt/qml unless otherwise specified
  - `Foo_DEPENDS` - The list of Qml Modules this module will depend upon. Depends are added to LIB_TARGET_PublicLIBLINKS
  - `Foo_QML_FILES` - QML Files that are part of the module

#### What is created with the macro

  1. A Libary
     - Depending on the compiler the library may be prefixed with "lib"
     - An Alias `${CMAKE_PROJECT_NAME}::${LIB_TARGET}` use this when linking to the library
     - On Windows this libary will have info embedded using the `_templates/libTemplate.rc.in`
     - The library will have it rpath modified based on the INSTALL_RPATH_STRING (set in the main cmakelist)
     - The Library will be publicly linked to the libraries in `${Foo_PublicLIBLINKS}`
     - The Library will be privately linked to the libraries in `${Foo_PrivateLIBLINKS}`
     - The Library will have all the needed items for cmake to find it as a COMPONENT of the project
     - The Library is added to the list of targets for the sbom.
     - The Library will declare compatibiliy based upon its MAJOR version number
         - If Major Version is >= 1, The compatibiliy will be set to `SameMajorVersion`
         - If Major Version is < 1, The compatibiliy will be set to `SameMinorVersion`


  2. Debug Info
     - dbg files are created for the librares and are installed

  3. Install Rules
     - The library will be installed to ${CMAKE_INSTALL_LIBDIR}/${CMAKE_PROJECT_NAME}
     - Library Headers will be installed to ${CMAKE_INSTALL_INCDIR}/${CMAKE_PROJECT_NAME}/${LIB_TARGET}
     - Alias headers are generated so you can #include<foo> or #include<foo.h>
