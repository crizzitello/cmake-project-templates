# About this Directory
This is the `cmake` dir its contains

  - `projectHelpers.cmake`
  - the `_templates` subdirectory


  This File contains several cmake macros that will make creation of targets much eaiser.

## Before use in your project
 Before using in a project you should
  - Edit `_template/demoTemplate.rc.in` and place the copyright info in the file
  - Edit `_template/libTemplate.rc.in` and place the copyright info in the file

## Functions and Macros in projectHelpers.cmake

 - `create_library` - Used to create library Targets
 - `MAKE_DEMO` - Used to create Demo applications
 - `MAKE_TEST` - Used to crate Unit tests.
 - `git_version_from_tag` - Used to make generate project version information from semantic versioned git tag
 - `sbom_generate` - Begin the process of sbom generation
 - `sbom_add` - Add New `TARGET` or `PACKAGE` to the sbom report
 - `sbom_finalize` - Finalize the sbom creation process
