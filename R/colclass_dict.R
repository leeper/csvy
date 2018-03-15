#' Dictionary of column classes for reading data
colclass_dict <- c(
  "string" = "character",
  "integer" = "integer",
  "number" = "numeric",
  "factor" = "character",   # Convert to factor afterwards -- fread doesn't do factors
  "date" = "Date",
  "datetime" = "POSIXct",
  "boolean" = "logical"
)
