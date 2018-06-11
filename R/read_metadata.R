#' @title Read metadata
#' @md
#' @description Read csvy metadata from an external `.yml/.yaml` or `.json` file
#' 
#' @param file full path of file from which to read the metadata.
#'
#' @return the metadata as a list
#' 
#' @importFrom yaml yaml.load
#' @importFrom jsonlite fromJSON
#' @importFrom tools file_ext
#'  
#' @export
read_metadata <- function(file) {
    ext <- tools::file_ext(file)
    if (ext %in% c("yaml", "yml")) {
        metadata_list <- yaml::yaml.load(paste(readLines(file), collapse = "\n"))
    } else if (ext == "json") {
        metadata_list <- jsonlite::fromJSON(file, simplifyDataFrame = FALSE)
    } else {
        stop("'metadata' should be either a .json or .yaml file.") ## should fail
    }
    return(metadata_list)
}
