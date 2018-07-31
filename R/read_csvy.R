#' @title Import CSVY data
#' @description Import CSVY data as a data.frame
#' @param file A character string or R connection specifying a file.
#' @param metadata Optionally, a character string specifying a YAML (\dQuote{.yaml}) or JSON (\dQuote{.json}) file containing metadata (in lieu of including it in the header of the file).
#' @param stringsAsFactors A logical specifying whether to treat character columns as factors. Passed to \code{\link[utils]{read.csv}} or \code{\link[data.table]{fread}} depending on the value of \code{method}. Ignored for \code{method = 'readr'} which never returns factors.
#' @param detect_metadata A logical specifying whether to auto-detect a metadata file if none is specified (and if no header is found).
#' @param \dots Additional arguments passed to \code{\link[data.table]{fread}}.
#' @examples
#' read_csvy(system.file("examples", "example1.csvy", package = "csvy"))
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
    detect_metadata = TRUE,
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
        metadata_raw <- get_yaml_header(file, verbose = FALSE)
        if (is.null(metadata_raw) & !detect_metadata) {
            # no metadata found in file and no auto-detection requested
            message("No metadata header found. Reading file as CSV.")
            out <- data.table::fread(input = file, sep = "auto", header = "auto",
                                     stringsAsFactors = stringsAsFactors,
                                     data.table = FALSE, ...)
            return(out)
        } else if (is.null(metadata_raw) & isTRUE(detect_metadata)) {
            # no metadata found in file but auto-detection requested
            message("No metadata header found in file, so attempting to auto-detect metadata file.")
            skip_lines <- 0L
            metadata_list <- detect_metadata(file)
            if (is.null(metadata_list)) {
                message("No metadata file found. Reading file as CSV.")
                out <- data.table::fread(input = file, sep = "auto", header = "auto",
                                         stringsAsFactors = stringsAsFactors,
                                         data.table = FALSE, ...)
                return(out)
            }
        } else {
            # metadata found in file
            skip_lines <- length(metadata_raw) + 1L     # Including opening and closing "---"
            metadata_list <- yaml::yaml.load(paste(metadata_raw, collapse = "\n"))
        }
    } else {
        skip_lines <- 0L
        metadata_list <- read_metadata(metadata)
    }
    
    # find variable-level metadata 'fields'
    if ("fields" %in% names(metadata_list)) {
        fields <- metadata_list$fields
        col_classes <- NULL
    } else if ("schema" %in% names(metadata_list)) {
        fields <- metadata_list$schema$fields
        field_types <- vapply(fields, "[[", character(1), "type")
        col_classes <- colclass_dict[field_types]
        names(col_classes) <- vapply(fields, "[[", character(1), "name")
    } else {
        fields <- NULL
        col_classes <- NULL
    }
    
    # find 'dialect' to use for importing, if available
    if ("dialect" %in% names(metadata_list)) {
        ## delimiter
        sep <- metadata_list$dialect$delimeter
        if (is.null(sep)) sep <- "auto"
        ## header
        header <- as.logical(metadata_list$dialect$header)
        if (is.null(header)) {
            header <- "auto"
        }
        ## there are other args here but we really don't need them
        ## need to decide how to use them
    } else {
        sep <- "auto"
        header <- "auto"
    }

    # load the data
    out <- data.table::fread(
        file = file,
        sep = sep,
        header = header,
        stringsAsFactors = stringsAsFactors,
        data.table = FALSE,
        colClasses = col_classes,
        skip = skip_lines,
        ...
    )
    
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
            attr(data[[i]], "label") <- fields_this_col[["title"]]
        }
        # add 'description' field
        if ("description" %in% names(fields_this_col)) {
            attr(data[[i]], "description") <- fields_this_col[["description"]]
        }
        ## store attributes already calculated
        dat_attributes <- attributes(data[[i]])
        
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
            ## replace attributes
            attributes(data[[i]]) <- dat_attributes
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
    if ("title" %in% names(metadata_list)) {
        attr(data_frame, "title") <- metadata_list[["title"]]
    }
    if ("description" %in% names(metadata_list)) {
        attr(data_frame, "description") <- metadata_list[["description"]]
    }
    if ("name" %in% names(metadata_list)) {
        attr(data_frame, "name") <- metadata_list[["name"]]
    }
    if ("format" %in% names(metadata_list)) {
        attr(data_frame, "format") <- metadata_list[["format"]]
    }
    if ("sources" %in% names(metadata_list)) {
        attr(data_frame, "sources") <- metadata_list[["sources"]]
    }
    if ("licenses" %in% names(metadata_list)) {
        attr(data_frame, "sources") <- metadata_list[["licenses"]]
    }
    return(data_frame)
}
