# About this Directory
This is the `unittests` dir its contains

  - `CMakeLists.txt` - Instructions to build the unittests
  - additional directores that mirror the layout of the src directory

By Default Tests are run as the last step before packaging when building and your build will fail if you fail a test.

To disable tests set the cmake option `TESTS` to `OFF`.

Due to how the `MAKE_TEST` macro is setup the `core` library will not be linked to tests your library should not depend upon
`core`. If you want to link the core library to your test you must edit the `MAKE_TEST` macro.


# Creating Tests
 1. Create a sub directory for the library you are going to test this should match its name in the src dir. For example if you library is in `src/mylib` create `unittests/mylib`.
 2. In `unittests/CMakeLists.txt` include the new directory with `add_subdirectory(mylib)`. Tests for optional libraries should be guarded.
 3. Create a new CMakeLists.txt and any cpp tests in the new directory
 4. In the new CMakeLists.txt use the `MAKE_TEST` macro to create the test. `MAKE_TEST(myLibTest mylibtest.cpp)`.
