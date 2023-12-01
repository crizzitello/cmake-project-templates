# About this Directory
This is the `docs` dir its contains

  - `mainpage.md` - The main page for your documentation
  - `build.md` - An additional Page with build info abour your project
  - `CMakeLists.txt` - Instructions to build the documentation

 Documentation is automaticly generated if doxygen is found

## Before use in your project
 Before using in a project you should
  - Edit `mainpage.md`
    - Check for instances of `PROJECTS_NAME` and replace them with your project's name
    - Add Additional Information about your project here
  - Edit `build.md` replace instances of `PROJECTS_NAME` with your projets name.

# Adding Documentation
  Create new md files and add them to the target sources in CMakeLists.txt. Link the pages to the mainpage or another page in the new document see the mainpage for an example on how to link.


