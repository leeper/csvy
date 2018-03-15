context("CSVY import/export with additional metadata")
require("datasets")

test_that("Metadata supported by read_csvy() and write_csvy()", {
    # setup metadata
    iris2 <- iris
    attr(iris2$Sepal.Length, "labels") <- "Sepal Length"
    attr(iris2$Sepal.Width, "labels") <- "Sepal Length"
    attr(iris2$Petal.Length, "labels") <- "Sepal Length"
    attr(iris2$Petal.Width, "labels") <- "Sepal Length"
    
    # export
    tmp <- tempfile()
    write_csvy(iris2, tmp, name = "Edgar Anderson's Iris Data")
    suppressWarnings(expect_true(file.exists(tmp), label = "export works with metadata"))
    
    # import
    iris3 <- read_csvy(tmp)
    expect_true(attr(iris3, "name") == "Edgar Anderson's Iris Data")
    expect_true(attr(iris3$Sepal.Length, "labels") == "Sepal Length")
    
    # cleanup
    unlink(tmp)
})
