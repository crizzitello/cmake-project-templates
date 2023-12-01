# Building PROJECTS_NAME

To build PROJECTS_NAME you will a minimum of: 
    - [cmake] 3.21+


A Default Build of PROJECTS_NAME will build: 
     - A Required Core Library
     - All Additional Libraries
     - Headers for the libraries so you can link to them
     - Required CMake parts to find it post install.
     - Translation files "PROJECTS_NAME_<lang>.qm" for supported languages
     - Documentation if [doxygen] was found on your system
     - Unit Test that will be run as part of the build process.

## Configuration
PROJECTS_NAME Supports Several Build options
Build Options:
         Option          |            Description                  |   Default Value    | Addtional Requirments |
:-----------------------:|:---------------------------------------:|:------------------:|:---------------------:|
CMAKE_BUILD_TYPE         | Type of Build that is produced          | ReleaseWithDebInfo | |
DOCS                     | Build Documentation                     | ON                 | [doxygen] |
DEMOS                    | Build The Demo Applications             | OFF                | |
PACKAGE                  | Enable Package target                   | ON                 | |
FRAMEWORKS               | Build as Frameworks (EXPERMANTAL)       | OFF                | Mac Os Only |
TESTS                    | Build and run unit tests                | ON                 | |
SPLITPACKAGES            | Create Split Packages                   | OFF                | |
CLEAN_TRS                | Remove Obsolete Translation Entries     | OFF                | |
SBOM_LINT                | Check the generated SBom for NTIA compliance | OFF           | [ntia-conformance-checker] |
SBOM_GRAPH               | Generate Sbom graph                     | OFF                | [spsx-tools] |

Enabling Demos will allow you to set this additional options all are enabled by default
       Demo              |            Description                  |
:-----------------------:|:---------------------------------------:|
WIDGET_GALLERY           | Build the Widget based gallery.         |
QML_GALLERY              | Build the QML based gallery.            |

Example cmake configuration.
`cmake -S. -Bbuild -DDEMOS=ON -DCMAKE_INSTALL_PREFIX=<INSTALLPREFIX>`

## Build
After Configuring you Should be able to run make to build all targets.

`cmake --build build`

## Install
 To test installation run `DESTDIR=<installDIR> cmake --install build` to install into `<installDir>/<CMAKE_INSTALL_PREFIX>` <br>
 Running `cmake --install build` will install to the `CMAKE_INSTALL_PREFIX`

## Making PROJECTS_NAME packages
 PROJECTS_NAME can generate several packages using cpack
 To generate packages build the `package` or `package_source` target
 example ` cmake --build build --target package package_source` would generate both package and package source packages.
 Installing the Qt Installer Framework will allow PROJECTS_NAME to create a QtIFW installer.
 
# Using PROJECTS_NAME in your project

After installing you can use in your cmake project by simply adding 
`find_project(PROJECTS_NAME)` link with `PROJECTS_NAME::PROJECTS_NAME`

## PROJECTS_NAME version info
 PROJECTS_NAME Versions are based on its git info. Failing this the project version is updated on every release.
 include the file ff7tk.h and use the function(s)
  - PROJECTS_NAME::version() To get version info in to form of Major.minor.patch.tweak
   -- If patch or rev are empty they are excluded from the version number
   -- tweak is Number of commits since the last tag release
### PROJECTS_NAME version compatibility
 PROJECTS_NAME versions with the same major and minor version are compatible. Building your project with an incompatible version can lead to API issues for this reason its HIGHLY recommend any CI jobs use a Release or specific COMMIT HASH when pulling ff7tk.

## Translations
  In addition to PROJECTS_NAME's language files your application should also load and/or ship the qt_base_<lang>.qm these are required to translate strings from inside Qt libraries.
  
You can use PROJECTS_NAME::translationList to get a QMap<QString, QTranslation*> of all the auto detected language files. This will look in several places in the application directory and around the system to attempt to find them.

## Deploying PROJECTS_NAME with your app
 When using PROJECTS_NAME your project needs to ship the libraries ff7tk needs to run its recommended to run windepoyqt / macdeployqt on the PROJECTS_NAME libs being used when you pack your application to be sure to get all the libs needed are deployed.
 
### Item Depends
LIST OF YOUR LIBRARIES WITH THEIR DEPENDS 
  - exampleLibrary
    -- QtCore, QtXml, QtSvg, Svg Image plugin, Core5Compat
  
### Sbom Generation
 A Software Bill Of Materials will be generated and installed into share/PROJECTS_NAME
 The SBOM is generated at install time and does not require any additional software on the build system
 Generating a graph or verifing the sbom is ntia compliant requires additonal software see the option table above.

[Qt]:https://www.qt.io
[doxygen]:http://www.stack.nl/~dimitri/doxygen/
[cmake]:https://cmake.org/
[ntia-conformance-checker]:https://github.com/spdx/ntia-conformance-checker
[spdx-tools]:https://github.com/spdx/sbom-tools
