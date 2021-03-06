% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write_metadata.R
\name{write_metadata}
\alias{write_metadata}
\title{Write csvy metadata}
\usage{
write_metadata(metadata_list = NULL, file = NULL)
}
\arguments{
\item{metadata_list}{metadata to be stored. Must be valid as per
\code{\link[yaml:as.yaml]{yaml::as.yaml()}} or \code{\link[jsonlite:write_json]{jsonlite::write_json()}} for that particular output
type.}

\item{file}{full path of file in which to save the metadata.}
}
\value{
\code{NULL} (invisibly)
}
\description{
Write csvy metadata to an external \code{.yml/.yaml} or \code{.json} file
}
