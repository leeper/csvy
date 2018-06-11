detect_metadata <- function(file) {
    filedir <- dirname(file)
    possible_metadata <- dir(filedir, pattern = "\\.json$|\\.yaml|\\.yml", full.names = TRUE) # <- case-sensitive pattern
    if (length(possible_metadata) > 1) {
        # too many potential metadata files found
        stop("More than one yaml/yml/json files detected in same directory as data")
    } else if (length(possible_metadata) == 0) {
        # no metadata file found, so just read file
        return(NULL)
    }
    # one file found
    message(sprintf("Attempting to read metadata from auto-detected file: %s", basename(possible_metadata)))
    return(read_metadata(possible_metadata))
}
