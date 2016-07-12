#' @title Export CSVY data
#' @description Export data.frame to CSVY
#' @param x A data.frame.
#' @param file A character string or R connection specifying a file.
#' @param sep A character string specifying a between-field separator. Passed to \code{\link[utils]{write.table}}.
#' @param sep2 A character string specifying a within-field separator. Passed to \code{\link[utils]{write.table}}.
#' @param comment_header A logical indicating whether to comment the lines containing the YAML front matter. Default is \code{TRUE}.
#' @param \dots Additional arguments passed to \code{\link[utils]{write.table}}.
#' @importFrom stats setNames
#' @importFrom utils write.table
#' @importFrom yaml as.yaml
#' @export
#' @seealso \code{\link{write_csvy}}
write_csvy <- function(x, file, sep = ",", sep2 = ".", comment_header = TRUE, ...) {
    # write yaml
    a <- attributes(x)
    a <- a[!names(a) %in% c("names", "row.names")]
    
    a$fields <- list()
    for (i in seq_along(x)) {
        a$fields[[i]] <- list()
        a$fields[[i]][1] <- names(x)[i]
        a$fields[[i]][2] <- class(x[[i]])
        atmp <- attributes(x[[i]])
        atmp$class <- NULL
        a$fields[[i]] <- c(a$fields[[i]], unname(atmp))
        names(a$fields[[i]]) <- c("name", "class", names(atmp))
        if ("labels" %in% names(a$fields[[i]])) {
            a$fields[[i]][["labels"]] <- 
              setNames(as.list(unname(atmp$labels)), names(atmp$labels))
        }
        rm(atmp)
    }
    
    y <- paste0("---\n", as.yaml(a), "---\n")
    
    if (isTRUE(comment_header)){
      m <- readLines(textConnection(y))
      y <- paste0("#", m[-length(m)],collapse = "\n")
      y <- c(y, "\n")
    }
    cat(y, file = file)
    
    # append CSV
    write.table(file = file, x = x, append = TRUE, sep = sep, dec = sep2, ...)
}
