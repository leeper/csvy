context("CSVY import using read_csvy()")
library("datasets")

test_that("Basic import from CSVY", {
    d1 <- read_csvy(system.file("examples", "example1.csvy", package = "csvy"))
    expect_true(inherits(d1, "data.frame"))
    expect_true(identical(dim(d1), c(2L, 3L)))
    
    d2 <- read_csvy(system.file("examples", "example2.csvy", package = "csvy"))
    expect_true(inherits(d2, "data.frame"))
    expect_true(identical(dim(d2), c(2L, 3L)))
})

test_that("Import from CSVY with separate yaml header", {
    tmp_csvy <- tempfile(fileext = ".csv")
    tmp_yaml <- tempfile(fileext = ".yaml")
    write_csvy(iris, file = tmp_csvy, metadata = tmp_yaml)
    expect_true(inherits(read_csvy(tmp_csvy, metadata = tmp_yaml), "data.frame"))
    unlink(tmp_csvy)
    unlink(tmp_yaml)
})
