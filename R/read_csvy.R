#' @title Import CSVY data
#' @description Import CSVY data as a data.frame
#' @param file A character string or R connection specifying a file.
#' @param sep A character string specifying a between-field separator. Passed to \code{\link[utils]{read.csv}} or \code{\link[data.table]{fread}} depending on the value of \code{method}. Ignored for \code{method = 'readr'}.
#' @param dec A character string specifying a within-field separator. Passed to \code{\link[utils]{read.csv}} or \code{\link[data.table]{fread}} depending on the value of \code{method}. Ignored for \code{method = 'readr'}.
#' @param header A character string or logical specifying whether the file contains a header row of column names (below the YAML frontmatter). Passed to \code{\link[utils]{read.csv}}, \code{\link[data.table]{fread}}, or \code{\link[readr]{read_csv}} depending on the value of \code{method}.
#' @param colClasses A character vector specifying the classes of columns to override default imports. This is passed, as appropriate, to the function determined by \code{method}.
#' @param stringsAsFactors A logical specifying whether to treat character columns as factors. Passed to \code{\link[utils]{read.csv}} or \code{\link[data.table]{fread}} depending on the value of \code{method}. Ignored for \code{method = 'readr'} which never returns factors.
#' @param method A character string specifying which package to use to read in the CSV data. Must be on of \dQuote{utils} (for \code{\link[utils]{read.csv}}), \dQuote{data.table} (for \code{\link[data.table]{fread}}), or \dQuote{readr} (for \code{\link[readr]{read_csv}}).
#' @param \dots Additional arguments passed to \code{\link[utils]{read.csv}}, \code{\link[data.table]{fread}}, or \code{\link[readr]{read_csv}} depending on the value of \code{method}.
#' @examples
#' read_csvy(system.file("examples", "example3.csvy", package = "csvy"))
#' 
#' @importFrom utils read.csv
#' @importFrom yaml yaml.load
#' @export
#' @seealso \code{\link{write_csvy}}
read_csvy <- 
function(file, 
         sep = ",", 
         dec = ".", 
         header = "auto", 
         colClasses, 
         stringsAsFactors = FALSE, 
         method = c("utils", "data.table", "readr"), 
         ...) 
{
    # read in whole file
    f <- readLines(file)
    if (!length(f)) {
        stop("File does not exist or is empty")
    }
  
    # identify yaml delimiters
    g <- grep("^#?---", f)
    if (length(g) > 2) {
        stop("More than 2 yaml delimiters found in file")
    } else if (length(g) == 1) {
        stop("Only one yaml delimiter found")
    } else if (length(g) == 0) {
        stop("No yaml delimiters found")
    }
    
    # extract yaml front matter and convert to R list
    y <- f[(g[1]+1):(g[2]-1)]
    if (all(grepl("^#", y))) {
        y <- gsub("^#", "", y)
    }
    y <- yaml.load(paste(y, collapse = "\n"))

    # initialize `colClasses` from name/class-properties if not specified
    if (missing(colClasses)) {
        cl <- lapply(y$fields, function(fld) {
            na <- fld[["name"]]
            cl <- fld[["class"]]
            if (!is.null(cl) && !is.null(na)) {
                names(cl) <- na[1L]
                return(cl)
            } else {
                NA_character_
            }
        })
        if (anyNA(cl)) {
            colClasses <- NULL
        } else {
            colClasses <- cl
        }
    }
    
    # load the data
    method <- match.arg(method)
    dat <- paste0(f[(g[2]+1):length(f)], collapse = "\n")
    if (method == "utils") {
        out <- read.csv(text = dat, 
                        colClasses = if (is.null(colClasses)) NA else colClasses,
                        sep = if (sep == "auto") "," else sep, 
                        dec = if (dec == "auto") "." else dec, 
                        stringsAsFactors = stringsAsFactors, ...)
    } else if (method == "data.table") {
        requireNamespace("data.table")
        out <- data.table::fread(input = dat, 
                                 colClasses = colClasses,
                                 sep = sep, sep2 = dec, header = header, 
                                 stringsAsFactors = stringsAsFactors, ...)
    } else if (method == "readr") {
        requireNamespace("readr")
        out <- readr::read_csv(file = dat, col_names = header, col_types = colClasses, ...)
    }
  
    # check metadata against header row
    check_metadata(y, out)
    
    # add metadata to data
    hnames <- lapply(y$fields, `[[`, "name")
    for (i in seq_along(y$fields)) {
        fields_this_col <- y[["fields"]][[match(names(out)[i], hnames)]]
        if ("name" %in% names(fields_this_col)) {
            fields_this_col[["name"]] <- NULL
        }
        if ("class" %in% names(fields_this_col)) {
            if (fields_this_col[["class"]] == "factor") {
                if (isTRUE(stringsAsFactors)) {
                    try(out[,i] <- factor(out[,i], levels = fields_this_col[["levels"]]))
                }
            } else {
                class(out[, i]) <- fields_this_col[["class"]]
            }
            fields_this_col[["class"]] <- NULL
        }
        attributes(out[, i]) <- append(attributes(out[,i]), fields_this_col)
        rm(fields_this_col)
    }
    y$fields <- NULL
  
    meta <- c(list(out), y)
    out <- do.call("structure", meta)
    out
}

check_metadata <- function(metadata, data) {
    hnames <- lapply(metadata$fields, `[[`, "name")
    
    missing_from_metadata <- names(data)[!names(data) %in% hnames]
    if (length(missing_from_metadata)) {
        warning("Metadata is missing for ", 
                ngettext(length(missing_from_metadata), "variable", "variables"), 
                " listed in data: ", paste(missing_from_metadata, collapse = ", "))
    }
    
    missing_from_data <- unlist(hnames)[!unlist(hnames) %in% names(data)]
    if (length(missing_from_data)) {
        warning("Data is missing for ", 
                ngettext(length(missing_from_data), "variable", "variables"), 
                " listed in frontmatter: ", paste(missing_from_metadata, collapse = ", "))
    }
    
    duplicated_metadata <- unlist(hnames)[duplicated(unlist(hnames))]
    if (length(duplicated_metadata)) {
        warning("Duplicate metadata entries for ", 
                ngettext(length(duplicated_metadata), "variable", "variables"), 
                " listed in frontmatter: ", paste(duplicated_metadata, collapse = ", "))
    }
    
    duplicated_columns <- unlist(hnames)[duplicated(unlist(hnames))]
    if (length(duplicated_columns)) {
        warning("Duplicate column names for ", 
                ngettext(length(duplicated_columns), "variable", "variables"), 
                ": ", paste(duplicated_metadata, collapse = ", "))
    }
    
    NULL
}
