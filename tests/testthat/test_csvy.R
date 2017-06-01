context("CSVY imports/exports")
require("datasets")

context("CSVY fundamentals")
test_that("Export to CSVY", {
    tmp <- tempfile()
    suppressWarnings(expect_true(file.exists(write_csvy(iris, tmp))))
    unlink(tmp)
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

context("CSVY data type handling")
test_that("data type handling", {
    df <- data.frame(
        d = c("1990-01-01", "1990-01-02"),
        n = c(1,2.5),
        i = c(1L,2L)
    )
    df$d <- as.Date(df$d)
    attr(df$d, "myatt") <- "attribute value"
    
    expect_test_df <- function(dfToTest) {
        expect_is(dfToTest, "data.frame")
        expect_is(dfToTest$d, "Date")
        expect_is(dfToTest$n, "numeric")
        expect_is(dfToTest$i, "integer")
        expect_equal(attr(dfToTest$d, "myatt"), "attribute value")
    }
    expect_test_df(df)
    
    ## Write test data
    filePath <- tempfile()
    ret <- write_csvy(df, filePath)
    
    df2 <- read_csvy(filePath, colClasses = c("d"="Date", "n"="numeric","i"="integer"))
    expect_test_df(df2)
    row.names(df) <- NULL
    row.names(df2) <- NULL
    expect_equal(df, df2)
    
    df2 <- read_csvy(filePath)
    expect_test_df(df2)
    ## Check content 
    row.names(df) <- NULL
    row.names(df2) <- NULL
    expect_equal(df, df2)
})
