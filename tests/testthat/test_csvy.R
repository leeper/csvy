context("CSVY imports/exports")
require("datasets")

test_that("Export to CSVY", {
    suppressWarnings(expect_true(write_csvy(iris, "iris.csvy") %in% dir()))
    unlink("iris.csvy")
})

test_that("Import from CSVY", {
    d <- read_csvy(system.file("examples", "example.csvy", package = "csvy"))
    expect_true(inherits(d, "data.frame"))
    
    d2 <- read_csvy(system.file("examples", "example2.csvy", package = "csvy"))
    expect_true(all(c("title", "units", "source") %in% names(attributes(d2))))
    
    d3 <- read_csvy(system.file("examples", "example3.csvy", package = "csvy"))
    expect_true(identical(dim(d3), c(2L, 3L)))

    d4 <- read.csv(system.file("examples", "example3.csvy", package = "csvy"), comment.char = "#")
    expect_true(identical(dim(d4), c(2L, 3L)))
})
