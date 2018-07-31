#' Retrieve YAML header from file
#'
#' Note that this assumes only one Yaml header, starting on the first line of the file.
#'
#' @inheritParams read_csvy
#' @param yaml_rxp Regular expression for parsing YAML header
#' @param verbose Logical. If \code{TRUE}, print warning if no header found.
#' @return Character vector of lines containing YAML header, or `NULL` if no YAML header found.
#' @export
get_yaml_header <- function(file, yaml_rxp = "^\\#*---[[:space:]]*$", verbose = TRUE) {
    # read first line to check for header
    con <- file(file, "r")
    on.exit(close(con))
    first_line <- readLines(con, n = 1L)
    if (!length(first_line) || !grepl(yaml_rxp, first_line)) {
        if (isTRUE(verbose)) {
            warning("No YAML header found.")
        }
        return(NULL)
    }
    
    # if header, read it in until "---" found
    iline <- 1L
    closing_tag <- FALSE
    out <- character()
    while (!isTRUE(closing_tag)) {
        out[iline] <- readLines(con, n = 1L)
        if (grepl(yaml_rxp, out[iline])) {
            closing_tag <- TRUE
        } else {
            iline <- iline + 1L
        }
    }
    
    # remove leading comment character, if present
    if (all(grepl("^#", out))) {
        out <- gsub("^#", "", out)
    }
    return(out)
}
