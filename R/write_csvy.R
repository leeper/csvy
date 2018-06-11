#' @title Export CSVY data
#' @description Export data.frame to CSVY
#' @param x A data.frame.
#' @param file A character string or R connection specifying a file.
#' @param metadata Optionally, a character string specifying a YAML (\dQuote{.yaml}) or JSON (\dQuote{.json}) file to write the metadata (in lieu of including it in the header of the file).
#' @param sep A character string specifying a between-field separator. Passed to \code{\link[data.table]{fwrite}}.
#' @param sep2 A character string specifying a within-field separator. Passed to \code{\link[data.table]{fwrite}}.
#' @param comment_header A logical indicating whether to comment the lines containing the YAML front matter. Default is \code{TRUE}.
#' @param metadata_only A logical indicating whether only the metadata should be produced (no CSV component).
#' @param name A character string specifying a name for the dataset.
#' @param \dots Additional arguments passed to \code{\link[data.table]{fwrite}}.
#' @examples
#' library("datasets")
#' write_csvy(head(iris))
#' 
#' # write yaml w/o comment charaters
#' write_csvy(head(iris), comment_header = FALSE)
#' 
#' @importFrom stats setNames
#' @importFrom data.table fwrite
#' @importFrom yaml as.yaml
#' @importFrom jsonlite write_json
#' @export
#' @seealso \code{\link{write_csvy}}
write_csvy <-
function(
  x,
  file,
  metadata = NULL,
  sep = ",",
  sep2 = ".",
  comment_header = if (is.null(metadata)) TRUE else FALSE,
  name = as.character(substitute(x)),
  metadata_only = FALSE,
  ...
) {
    
    ## data-level metadata
    metadata_list <- list(profile = "tabular-data-package",
                          name = name)
    
    ## build variable-specific metadata list
    fields <- list()
    for (i in seq_along(x)) {
        # grab attributes for this variable
        fields_this_col <- attributes(x[[i]])
        
        # initialize metadata list for this variable
        fields[[i]] <- list()
        
        # add 'name' field
        fields[[i]][["name"]] <- names(x)[i]
        # add 'title' field
        if ("label" %in% names(fields_this_col)) {
            fields[[i]][["title"]] <- fields_this_col[["label"]]
        }
        # R has no canonical analogue to 'description' field, but if it's there add it
        if ("description" %in% names(fields_this_col)) {
            fields[[i]][["description"]] <- fields_this_col[["description"]]
        }
        # add 'type' field
        ## default is 'string' unless specified otherwise
        fields[[i]][["type"]] <- switch(class(x[[i]])[1L],
                                        character = "string",
                                        Date = "date",
                                        integer = "integer",
                                        logical = "boolean",
                                        numeric = "number",
                                        POSIXct = "datetime",
                                        "string")
        if ("labels" %in% names(fields_this_col)) {
            fields[[i]][["labels"]] <- 
              setNames(as.list(unname(fields_this_col$labels)), names(fields_this_col$labels))
        }
        if ("levels" %in% names(fields_this_col)) {
            fields[[i]][["levels"]] <- 
              setNames(as.list(unname(fields_this_col$levels)), names(fields_this_col$levels))
        }
        rm(fields_this_col)
    }
    
    ## build resource-level metadata list
    metadata_list$resources <- list(
        list(order = 1L,
             schema = list(fields = fields),
             dialect = list(csvddfVersion = 1.0,
                            delimiter = sep,
                            doubleQuote = FALSE,
                            lineTerminator = '\\n',
                            escapeChar = '\\',
                            quoteChar = '\"',
                            skipInitialSpace = TRUE,
                            header = TRUE,
                            caseSensitiveHeader = TRUE)
             )
    )
    
    if (!is.null(metadata)) {
      ## write metadata to separate file
      write_metadata(metadata_list, metadata)
      ## don't write the csv component if metadata_only is TRUE
      if (!metadata_only) {
        # write CSV
        data.table::fwrite(x = x, file = file, sep = sep, dec = sep2, ...)
      }
    } else {
        # write metadata to file
        y <- paste0("---\n", yaml::as.yaml(metadata_list), "---\n")
        if (isTRUE(comment_header)){
          m <- readLines(textConnection(y))
          y <- paste0("#", m[-length(m)],collapse = "\n")
          y <- c(y, "\n")
        }
        if (missing(file)) {
            cat(y)
            data.table::fwrite(x = x, file = "", sep = sep, dec = sep2, append = TRUE, col.names = TRUE, ...)
        } else {
            cat(y, file = file)
            # append CSV to file
            data.table::fwrite(x = x, file = file, sep = sep, dec = sep2, append = TRUE, col.names = TRUE, ...)
        }
    }
    invisible(x)
}
