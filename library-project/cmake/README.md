# About this Directory
This is the `cmake` directory it contains, cmake helpers and other items used by cmake.

  - `projectHelpers.cmake` - Contains cmake
  - the `_template` subdirectory

## Before using in your project
 Edit the needed files in the `_template` directory

## Functions and Macros in projectHelpers.cmake

 - `create_library` - Used to create library Targets
 - `MAKE_DEMO` - Used to create Demo applications
 - `MAKE_TEST` - Used to crate Unit tests.
 - `git_version_from_tag` - Used to make generate project version information from semantic versioned git tags.
 - `sbom_generate` - Begins the process of sbom generation
 - `sbom_add` - Add New `TARGET` or `PACKAGE` to the sbom report
 - `sbom_finalize` - Finalize the sbom creation process


### create_library
#### Overview
  The create_library function simplifes creating a new library for your project. By default it will create a new target for your project of the library name and the items to support the new library `install targets`, `library alias`, `export_headers` and more are created.

  | OPTION              | Additional Input                 | Effect |
  |---------------------|:--------------------------------:|--------|
  | TARGET              | Single String   | REQUIRED Name of the new library |
  | TYPE                | `SHARED`, `STATIC` or `MODULE`  | Type of library. Default: `${BUILD_SHARED_LIBS}` |
  | EXCLUDE_FROM_ALL    |     NONE         | Set [EXCLUDE_FROM_ALL](https://cmake.org/cmake/help/latest/command/add_library.html#alias-libraries) on the new library. |
  | SKIP_ALIAS          |     NONE         | Skip [alias-libarary](https://cmake.org/cmake/help/latest/command/add_library.html#alias-libraries) for the new library. |
  | SKIP_ALIAS_HEADERS  |     NONE         | Skip creation of alias headers for the new library `HEADERS` |
  | SKIP_SBOM           |     NONE         | Do not generate SBOM info for this library |
  | FRAMEWORK           |     NONE         | MACOS Only: Create a framework target |
  | QML_MODULE          |     NONE         | The target is a QML Module. |
  | RC_TEMPLATE         | File Path        | Windows Only: rc template to embed.  Default: [_template/libTemplate.rc.in](_template/libTemplate.rc.in) |
  | ALIAS               | Formated String  A::B | Name for Alias Library. Default `${CMAKE_PROJECT_NAME}::TARGET` |
  | RPATH               |  Rpath String    | UNIX Only: Install Rpath on linux/mac, Default: `${INSTALL_RPATH_STRING}` |
  | INSTALL_INCLUDEDIR  |     Path         | Install Path for `HEADERS` `${CMAKE_INSTALL_INCLUDEDIR}` will be prepended to the input.  Default `${CMAKE_PROJECT_NAME}/TARGET` |
  | COMPATIBILITY       | `AnyNewerVersion`<br/> `SameMajorVersion`<br/> `SameMinorVersion`<br/> `ExactVersion` | Set the `${CMAKE_PROJECT_COMPATIBILITY}` Default:  ExactVersion |
  | PUBLIC_LINKS| List | Libraries to link as PUBLIC |
  | PRIVATE_LINKS| List| Libraries to link as PRIVATE |
  | INTERFACE_LINKS| List | Libraries to link as INTERFACE |
  | SOURCES | List | Source files including qrc and ui files |
  | HEADERS | List | Headers for the library these will be deployed |
  | RESOURCE_PREFIX     |  IMPORT PATH     | QML_MODULE Only Qml Import Prefix. Default : "/qt/qml" |
  | URI                 |  Single String   | QML_MODULE Only To be used for module import |
  | QMLFILES| List | QML_MODULE Only, Qml sources for the module |
  | QMLDEPENDS| List | QML_MODULE Only Other Qml modules required |

