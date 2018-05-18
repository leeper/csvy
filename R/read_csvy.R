#' @title Import CSVY data
#' @description Import CSVY data as a data.frame
#' @param file A character string or R connection specifying a file.
#' @param metadata Optionally, a character string specifying a YAML (\dQuote{.yaml}) or JSON (\dQuote{.json}) file containing metadata (in lieu of including it in the header of the file).
#' @param stringsAsFactors A logical specifying whether to treat character columns as factors. Passed to \code{\link[utils]{read.csv}} or \code{\link[data.table]{fread}} depending on the value of \code{method}. Ignored for \code{method = 'readr'} which never returns factors.
#' @param \dots Additional arguments passed to \code{\link[data.table]{fread}}.
#' @examples
#' read_csvy(system.file("examples", "example3.csvy", package = "csvy"))
#' 
#' @importFrom tools file_ext
#' @importFrom jsonlite fromJSON
#' @importFrom data.table fread
#' @importFrom yaml yaml.load
#' @export
#' @seealso \code{\link{write_csvy}}
read_csvy <-
function(
    file,
    metadata = NULL,
    stringsAsFactors = FALSE,
    ...
) {
    
    # setup factor coercion conditional on presence of 'levels' metadata field
    if (isTRUE(stringsAsFactors)) {
        try_to_factorize <- "always"
    } else if (stringsAsFactors == "conditional") {
        stringsAsFactors <- FALSE
        try_to_factorize <- "conditional"
    } else {
        try_to_factorize <- "never"
    }
        
    if (is.null(metadata)) {
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
            message("No yaml/yml/json header in file, attempting to auto-detect")
            ## no yaml header; look for file.yaml or file.json
            filedir <- dirname(file)
            possible_metadata <- dir(filedir, pattern = "\\.json$|\\.yaml|\\.yml", full.names = TRUE)
            if (length(possible_metadata) > 1) {
                stop("More than 1 yaml/yml/json files detected in same directory as data")
            } else if (length(possible_metadata) == 0) {
                ## no metadata file found, just read file
                message("No yaml/yml/json files detected in same directory as data. Reading file as CSV")
                out <- data.table::fread(input = file, sep = "auto", header = "auto", 
                                         stringsAsFactors = stringsAsFactors,
                                         data.table = FALSE, ...)
                return(out)
            } else if (length(possible_metadata) == 1) {
                message(paste0("Detected ", basename(possible_metadata), ", attempting to use that"))
                metadata_list <- read_metadata(possible_metadata)
            }
        } else if (length(g) == 2) {
            # extract yaml front matter and convert to R list
            metadata_list <- f[(g[1]+1):(g[2]-1)]
            if (all(grepl("^#", metadata_list))) {
                metadata_list <- gsub("^#", "", metadata_list)
            }
            metadata_list <- yaml::yaml.load(paste(metadata_list, collapse = "\n"))
        }
    } else {
        metadata_list <- read_metadata(metadata)
    }
    
    # find variable-level metadata 'fields'
    if ("fields" %in% names(metadata_list)) {
        # this is a legacy
        fields <- metadata_list$fields
    } else if ("resources" %in% names(metadata_list)) {
        # this is the current standard
        # get first resource field (currently we don't support multiple resources)
        fields <- metadata_list$resources[[1L]]$schema$fields
    } else {
        fields <- NULL
    }
    
    # find 'dialect' to use for importing, if available
    if ("resources" %in% names(metadata_list)) {
        dialect <- metadata_list$resources[[1L]]$dialect
        ## delimiter
        sep <- dialect$delimeter
        ## header
        header <- as.logical(dialect$header)
        ## there are other args here but we really don't need them
        ## need to decide how to use them
    } else {
        sep <- "auto"
        header <- "auto"
    }
    
    # load the data
    if (is.null(metadata)) {
        # if metadata in header, load only relevant lines of file
        if (length(g) == 2) {
            dat <- paste0(f[(g[2]+1):length(f)], collapse = "\n")
        } else {
            dat <- paste0(f, collapse = "\n")
        }
        out <- data.table::fread(input = dat, sep = "auto", header = header, 
                                 stringsAsFactors = stringsAsFactors, data.table = FALSE, ...)
    } else {
        # if metadata is separate file, load whole file
        out <- data.table::fread(input = file, sep = "auto", header = header, 
                                 stringsAsFactors = stringsAsFactors, data.table = FALSE, ...)
    }
    
    # add data frame-level metadata to data
    out <- add_dataset_metadata(data_frame = out, metadata_list = metadata_list)
    
    # add variable-level metadata to data
    out <- add_variable_metadata(data = out, fields = fields, try_to_factorize = try_to_factorize)
    
    return(out)
}

check_variable_metadata <- function(data, fields) {
    if (is.null(fields)) {
        return(NULL)
    }
    
    hnames <- lapply(fields, `[[`, "name")
    
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

add_variable_metadata <- function(data, fields, try_to_factorize = "never") {
    
    # check metadata against header row
    check_variable_metadata(data = data, fields = fields)
    
    # add metadata to data, iterating across metadata list
    metadata_names <- lapply(fields, `[[`, "name")
    for (i in seq_along(fields)) {
        # grab attributes for this variable
        fields_this_col <- fields[[i]]
        
        # add 'title' field
        if ("title" %in% names(fields_this_col)) {
            attr(data[[i]], "label") <- fields_this_col[["label"]]
        }
        # add 'description' field
        if ("description" %in% names(fields_this_col)) {
            attr(data[[i]], "description") <- fields_this_col[["description"]]
        }
        # handle 'type' and 'format' fields
        ## 'type'
        if ("type" %in% names(fields_this_col)) {
            if (fields_this_col[["type"]] == "string") {
                ## character/factor
                if (try_to_factorize == "always") {
                    # convert all character to factor
                    if (is.null(fields_this_col[["levels"]])) {
                        try(data[[i]] <- as.factor(data[[i]]))
                    } else {
                        try(data[[i]] <- factor(data[[i]], levels = fields_this_col[["levels"]]))
                    }
                } else if (try_to_factorize == "conditional") {
                    # convert character to factor if levels are present
                    if (is.null(fields_this_col[["levels"]])) {
                        try(data[[i]] <- as.character(data[[i]]))
                    } else {
                        try(data[[i]] <- factor(data[[i]], levels = fields_this_col[["levels"]]))
                    }
                } else {
                    # do not convert character to factor
                    try(data[[i]] <- as.character(data[[i]]))
                }
            } else if (fields_this_col[["type"]] == "date") {
                try(data[[i]] <- as.Date(data[[i]]))
            } else if (fields_this_col[["type"]] == "datetime") {
                try(data[[i]] <- as.POSIXct(data[[i]]))
            } else if (fields_this_col[["type"]] == "boolean") {
                try(data[[i]] <- as.logical(data[[i]]))
            } else if (fields_this_col[["type"]] == "number") {
                try(data[[i]] <- as.numeric(data[[i]]))
            }
        }
        ## 'format' (just added as an attribute for now)
        if ("format" %in% names(fields_this_col)) {
            attr(data[[i]], "format") <- fields_this_col[["format"]]
        }
        ## add 'levels' (if not added above during factor coercion)
        if ("levels" %in% names(fields_this_col) && (!"levels" %in% attributes(data[[i]]))) {
            attr(data[[i]], "levels") <- fields_this_col[["levels"]]
        }
        ## add 'labels' (not in schema but useful)
        if ("labels" %in% names(fields_this_col) && (!"labels" %in% attributes(data[[i]]))) {
            attr(data[[i]], "labels") <- fields_this_col[["labels"]]
        }
        rm(fields_this_col)
    }
    
    return(data)
}

add_dataset_metadata <- function(data_frame, metadata_list) {
    if ("profile" %in% names(metadata_list)) {
        attr(data_frame, "profile") <- metadata_list[["profile"]]
    }
    if ("name" %in% names(metadata_list)) {
        attr(data_frame, "name") <- metadata_list[["name"]]
    }
    return(data_frame)
}


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
}