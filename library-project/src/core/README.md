This is an example of a library using the projects helper macros.  This example is unusual because the code is generated when cmake configures the project.

# The Core Library
 - This singleton libary is to provide users of or your libraries with infomation about the project such as location of i18n files or the version number.
 - The `MAKE_TEST` Macro will not link this to tests when crating them.


