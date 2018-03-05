context("CSVY export using write_csvy()")
require("datasets")

test_that("Basic export to CSVY", {
    tmp <- tempfile()
    write_csvy(iris, tmp)
    suppressWarnings(expect_true(file.exists(tmp)))
    unlink(tmp)
})

test_that("Export to CSVY with separate yaml header", {
    tmp_csvy <- tempfile(fileext = ".csv")
    tmp_yaml <- tempfile(fileext = ".yaml")
    tmp_json <- tempfile(fileext = ".json")
    
    # write to yaml
    write_csvy(iris, file = tmp_csvy, metadata = tmp_yaml)
    suppressWarnings(expect_true(file.exists(tmp_csvy)))
    suppressWarnings(expect_true(file.exists(tmp_yaml)))
    unlink(tmp_csvy)
    unlink(tmp_yaml)
    
    # write to json
    write_csvy(iris, file = tmp_csvy, metadata = tmp_json)
    suppressWarnings(expect_true(file.exists(tmp_csvy)))
    suppressWarnings(expect_true(file.exists(tmp_json)))
    
    unlink(tmp_csvy)
    unlink(tmp_json)
})
