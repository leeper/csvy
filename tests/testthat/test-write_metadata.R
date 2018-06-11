context("write_metadata")

test_that("empty arguments fail", {
  expect_error(write_metadata(), regexp = "must provide.*list")
  expect_error(write_metadata(list()), regexp = "metadata \\(filename\\)")
})

test_that("wrong filetype fails", {
  expect_warning(write_metadata(list(), "file.xls"), regexp = "either a \\.json")
})

test_that("basic yaml writing works", {
  temp_file <- tempfile(fileext = ".yaml")
  write_metadata(list(a = 123.4, foo = "bar"), temp_file)
  dat <- yaml::read_yaml(temp_file)
  expect_identical(dat$a, 123.4)
  expect_identical(dat$foo, "bar")
  unlink(temp_file)
})

test_that("basic json writing works", {
  temp_file <- tempfile(fileext = ".json")
  write_metadata(list(a = 123.4, foo = "bar"), temp_file)
  dat <- jsonlite::read_json(temp_file, simplifyVector = TRUE)
  expect_identical(dat$a, 123.4)
  expect_identical(dat$foo, "bar")
  unlink(temp_file)
})

test_that("only metadata is written", {
  temp_dir <- tempdir()
  temp_file <- tempfile(tmpdir = temp_dir, fileext = ".json")
  write_csvy(mtcars, file = file.path(temp_dir, "mtcars.csvy"), metadata = temp_file, metadata_only = TRUE)
  dat <- jsonlite::read_json(temp_file, simplifyVector = TRUE)
  expect_identical(dat$name, "mtcars")
  expect_identical(unlist(dat$resources$schema$fields[[1]]$type), rep("number", 11))
  expect_identical(length(dir(temp_dir, pattern = "*.csvy")), 0L)
  unlink(temp_file)  
})

test_that("roundtrip when metadata is written separately", {
  temp_dir <- tempdir()
  temp_file <- tempfile(tmpdir = temp_dir, fileext = ".json")
  write_csvy(mtcars, file = file.path(temp_dir, "mtcars.csvy"), metadata = temp_file, metadata_only = FALSE)
  dat <- jsonlite::read_json(temp_file, simplifyVector = TRUE)
  expect_identical(dat$name, "mtcars")
  expect_identical(unlist(dat$resources$schema$fields[[1]]$type), rep("number", 11))
  expect_identical(length(dir(temp_dir, pattern = "*.csvy")), 1L)
  csvy <- read_csvy(file.path(temp_dir, "mtcars.csvy"), metadata = temp_file)
  expect_equivalent(csvy, mtcars)
  unlink(temp_file)  
})
