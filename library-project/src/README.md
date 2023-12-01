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
The CMakeLists.txt in this folder contains the MAKE_LIBRARY macro.

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


