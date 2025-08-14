# About this Directory
This is the `translations` directory it contains

  - `CMakeLists.txt` - Instructions to build the translations
  - additional ts files for supported translations

 Translations will be automaticly generated if ts files are added to the PROJECT_TRS var in `CMakeLists.txt`.

 When adding new language files they must be in the form
  - `PROJECT_LANG.ts`
  - `PROJECT_LANG_COUNTRY.ts`

  `PROJECT` is the name of the project <br/>
  `LANG` is a valid ISO-639 alpha-2 code (From the `SET 1` Column in this [Table](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) ) <br/>
  `COUNTRY` is a valid ISO 3166-1 alpha-2 code (From the `CODE` column this [Table](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements)) <br/>
