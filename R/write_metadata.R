
#' @title Write csvy metadata
#' @md
#' @description Write csvy metadata to an external `.yml/.yaml` or `.json` file
#'
#' @param metadata_list metadata to be stored. Must be valid as per
#'   [yaml::as.yaml()] or [jsonlite::write_json()] for that particular output
#'   type.
#' @param file full path of file in which to save the metadata.
#'
#' @importFrom yaml as.yaml
#' @importFrom jsonlite write_json
#' @importFrom tools file_ext
#' 
#' @return `NULL` (invisibly)
#' @export
write_metadata <- function(metadata_list = NULL, file = NULL) {
  
  if (is.null(metadata_list) || !is.list(metadata_list)) stop("must provide metadata_list as a list")
  if (is.null(file) || !is.character(file)) stop("metadata (filename) must be provided")
  
  ## get file extension
  ext <- tools::file_ext(file)
  
  # write metadata to separate metadata file
  if (tolower(ext) %in% c("yml", "yaml")) {
    cat(yaml::as.yaml(metadata_list), file = file)
  } else if (tolower(ext) == "json") {
    jsonlite::write_json(metadata_list, path = file)
  } else {
    warning("'metadata' should be either a .json or .yaml file.") ## TODO stop?
  }
  
  return(invisible(NULL))
  
}