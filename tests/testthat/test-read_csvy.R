context("CSVY import using read_csvy()")
library("datasets")

test_that("Basic import from CSVY", {
    d1 <- read_csvy(system.file("examples", "example1.csvy", package = "csvy"))
    expect_true(inherits(d1, "data.frame"))
    
    d3 <- read_csvy(system.file("examples", "example3.csvy", package = "csvy"))
    expect_true(identical(dim(d3), c(2L, 3L)))
    
    d4 <- read.csv(system.file("examples", "example3.csvy", package = "csvy"), comment.char = "#")
    expect_true(identical(dim(d4), c(2L, 3L)))
})

test_that("Import from CSVY with separate yaml header", {
    tmp_csvy <- tempfile(fileext = ".csv")
    tmp_yaml <- tempfile(fileext = ".yaml")
    write_csvy(iris, file = tmp_csvy, metadata = tmp_yaml)
    expect_true(inherits(read_csvy(tmp_csvy, metadata = tmp_yaml), "data.frame"))
    unlink(tmp_csvy)
    unlink(tmp_yaml)
})
