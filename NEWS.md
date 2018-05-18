# csvy v0.2.1

 * Expanded test suite and fixed some small bugs in the process.
 * If reading a file `data.csvy` without a metadata header, and a `data.[yaml|yml|json]` file
   is present (in the same directory), that will be automatically read-in as the metadata 
   (completes requests for #10, h/t @jonocarroll)

# csvy v0.2.0

 * Removed support for `utils::read.csv()` and `readr::read_csv()` for simplicity.
 * Updated support to current CSVY specifications. (#13, h/t Michael Chirico)
 * Substantially changed internal code and added markup.
 * Changed example files.
 * Added option to output metadata to separate YAML or JSON file. (#10, h/t Hadley Wickham)

# csvy v0.1.2

 * Address header that is not in the same order as data columns. (#1)
 * Support for `readr::read_csv()` and `utils::read.csv()`. (#2)

# csvy v0.1.1

 * Initial release
