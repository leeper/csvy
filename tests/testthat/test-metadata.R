context("CSVY import/export with additional metadata")
require("datasets")

test_that("Metadata supported by read_csvy() and write_csvy()", {
    # setup metadata
    iris2 <- iris
    attr(iris2$Sepal.Length, "label") <- "Sepal Length"
    attr(iris2$Sepal.Width, "label") <- "Sepal Length"
    attr(iris2$Petal.Length, "label") <- "Sepal Length"
    attr(iris2$Petal.Width, "label") <- "Sepal Length"

    # export
    tmp <- tempfile()
    write_csvy(iris2, tmp, name = "Edgar Anderson's Iris Data")
    suppressWarnings(expect_true(file.exists(tmp), label = "export works with metadata"))

    # import
    iris3 <- read_csvy(tmp)
    expect_true(attr(iris3, "name") == "Edgar Anderson's Iris Data")
    expect_true(attr(iris3$Sepal.Length, "label") == "Sepal Length")
    # cleanup
    unlink(tmp)
})

context("External metadata can be found and loaded")

test_that("External metadata loads automatically", {
    iris2 <- iris
    # attr(iris2$Sepal.Length, "label") <- "Sepal Length"  # to be fixed in PR#21
    # attr(iris2$Sepal.Width, "label") <- "Sepal Length"   # to be fixed in PR#21
    # attr(iris2$Petal.Length, "label") <- "Sepal Length"  # to be fixed in PR#21
    # attr(iris2$Petal.Width, "label") <- "Sepal Length"   # to be fixed in PR#21

    # export
    tmp <- tempfile("iris", fileext = ".csvy")
    tmp_metadata <- sub("csvy", "yaml", tmp)
    write_csvy(iris2, tmp, metadata = tmp_metadata, name = "Edgar Anderson's Iris Data")
    expect_true(file.exists(tmp))
    expect_true(file.exists(tmp_metadata))
    expect_identical(readLines(dir(dirname(tmp), pattern = ".csvy", full.names = TRUE))[1],
                     "Sepal.Length,Sepal.Width,Petal.Length,Petal.Width,Species")
    expect_identical(readLines(dir(dirname(tmp), pattern = ".yaml", full.names = TRUE))[1],
                     "profile: tabular-data-package")
    ## read only csv, auto-detecect metadata
    iris3 <- read_csvy(file = tmp) # read metadata automatically
    expect_true(attr(iris3, "name") == "Edgar Anderson's Iris Data")
    # expect_true(attr(iris3$Sepal.Length, "label") == "Sepal Length") # to be fixed in PR#21
    unlink(tmp)
    unlink(tmp_metadata)

})

context("read_metadata")

test_that("empty/bad arguments fail", {
    expect_error(read_metadata(), regexp = "argument \"file\" is missing")
    expect_error(read_metadata("foo.txt"), regexp = "should be either a \\.json")
})

test_that("basic yaml reading works", {
    temp_file <- tempfile(fileext = ".yaml")
    cat(yaml::as.yaml(list(a = 123.4, foo = "bar")), file = temp_file)
    dat <- read_metadata(temp_file)
    expect_identical(dat$a, 123.4)
    expect_identical(dat$foo, "bar")
    unlink(temp_file)
})

test_that("basic json reading works", {
    temp_file <- tempfile(fileext = ".json")
    jsonlite::write_json(list(a = 123.4, foo = "bar"), path = temp_file)
    dat <- read_metadata(temp_file)
    expect_identical(dat$a, 123.4)
    expect_identical(dat$foo, "bar")
    unlink(temp_file)
})

