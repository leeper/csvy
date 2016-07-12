#' @title Import CSVY data
#' @description Import CSVY data as a data.frame
#' @param file A character string or R connection specifying a file.
#' @param sep A character string specifying a between-field separator. Passed to \code{\link[data.table]{fread}}.
#' @param sep2 A character string specifying a within-field separator. Passed to \code{\link[data.table]{fread}}.
#' @param header A character string or logical specifying whether the file contains a header row of column names (below the YAML frontmatter). Passed to \code{\link[data.table]{fread}}.
#' @param stringsAsFactors A logical specifying whether to treat character columns as factors. Passed to \code{\link[data.table]{fread}}.
#' @param \dots Additional arguments passed to \code{\link[data.table]{fread}}.
#' @importFrom data.table fread
#' @importFrom yaml yaml.load
#' @export
#' @seealso \code{\link{write_csvy}}
read_csvy <- function(file, sep = "auto", sep2 = "auto", header = "auto", stringsAsFactors = FALSE, ...) {
  # read in whole file
  f <- readLines(file)
  
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
  
  # load the data
  out <- fread(input = paste0(f[(g[2]+1):length(f)], collapse = "\n"), 
               sep = sep, sep2 = sep2, header = header, 
               stringsAsFactors = stringsAsFactors, ...)
  for (i in seq_along(y$fields)) {
    attributes(out[, i]) <- y$fields[[i]]
  }
  y$fields <- NULL
  
  meta <- c(list(out), y)
  out <- do.call("structure", meta)
  out
}
