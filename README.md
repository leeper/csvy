# Import and Export CSV Data With a YAML Metadata Header

CSVY is a file format that combines the simplicity of CSV (comma-separated values) with the metadata of other plain text and binary formats (JSON, XML, Stata, etc.). The [CSVY file specification](http://csvy.org/) is simple: place a YAML header on top of a regular CSV. The yaml header is formatted according to the [Table Schema](https://frictionlessdata.io/specs/table-schema/) of a [Tabular Data Package](https://frictionlessdata.io/specs/tabular-data-package/).

A CSVY file looks like this:

```
#---
#profile: tabular-data-resource
#name: my-dataset
#path: https://raw.githubusercontent.com/csvy/csvy.github.io/master/examples/example.csvy
#title: Example file of csvy 
#description: Show a csvy sample file.
#format: csvy
#mediatype: text/vnd.yaml
#encoding: utf-8
#schema:
#  fields:
#  - name: var1
#    type: string
#  - name: var2
#    type: integer
#  - name: var3
#    type: number
#dialect:
#  csvddfVersion: 1.0
#  delimiter: ","
#  doubleQuote: false
#  lineTerminator: "\r\n"
#  quoteChar: "\""
#  skipInitialSpace: true
#  header: true
#sources:
#- title: The csvy specifications
#  path: http://csvy.org/
#  email: ''
#licenses:
#- name: CC-BY-4.0
#  title: Creative Commons Attribution 4.0
#  path: https://creativecommons.org/licenses/by/4.0/
#---
var1,var2,var3
A,1,2.0
B,3,4.3
```

Which we can read into R like this:



```r
library("csvy")
str(read_csvy(system.file("examples", "example1.csvy", package = "csvy")))
```

```
## 'data.frame':	2 obs. of  3 variables:
##  $ var1: chr  "A" "B"
##  $ var2: int  1 3
##  $ var3: num  2 4.3
##  - attr(*, "profile")= chr "tabular-data-resource"
##  - attr(*, "title")= chr "Example file of csvy"
##  - attr(*, "description")= chr "Show a csvy sample file."
##  - attr(*, "name")= chr "my-dataset"
##  - attr(*, "format")= chr "csvy"
##  - attr(*, "sources")=List of 1
##   ..$ :List of 3
##   .. ..$ name : chr "CC-BY-4.0"
##   .. ..$ title: chr "Creative Commons Attribution 4.0"
##   .. ..$ path : chr "https://creativecommons.org/licenses/by/4.0/"
```

Optional comment characters on the YAML lines make the data readable with any standard CSV parser while retaining the ability to import and export variable- and file-level metadata. The CSVY specification does not use these, but the csvy package for R does so that you (and other users) can continue to rely on `utils::read.csv()` or `readr::read_csv()` as usual. The `import()` function in [rio](https://cran.r-project.org/package=rio) supports CSVY natively.

### Export

To create a CSVY file from R, just do:


```r
library("csvy")
library("datasets")
write_csvy(iris, "iris.csvy")
```

It is also possible to export the metadata to separate YAML or JSON file (and then also possible to import from those separate files) by specifying the `metadata` field in `write_csvy()` and `read_csvy()`.

### Import

To read a CSVY into R, just do:


```r
d1 <- read_csvy("iris.csvy")
str(d1)
```

```
## 'data.frame':	150 obs. of  5 variables:
##  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
##  $ Species     : chr  "setosa" "setosa" "setosa" "setosa" ...
##   ..- attr(*, "levels")= chr  "setosa" "versicolor" "virginica"
##  - attr(*, "profile")= chr "tabular-data-package"
##  - attr(*, "name")= chr "iris"
```

or use any other appropriate data import function to ignore the YAML metadata:


```r
d2 <- utils::read.table("iris.csvy", sep = ",", header = TRUE)
str(d2)
```

```
## 'data.frame':	150 obs. of  5 variables:
##  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
##  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
##  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
##  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
##  $ Species     : Factor w/ 3 levels "setosa","versicolor",..: 1 1 1 1 1 1 1 1 1 1 ...
```



## Package Installation

The package is available on [CRAN](https://cran.r-project.org/package=csvy) and can be installed directly in R using:

```R
install.packages("csvy")
```

The latest development version on GitHub can be installed using **devtools**:

```R
if(!require("remotes")){
    install.packages("remotes")
}
remotes::install_github("leeper/csvy")
```

[![CRAN Version](http://www.r-pkg.org/badges/version/csvy)](https://cran.r-project.org/package=csvy)
![Downloads](http://cranlogs.r-pkg.org/badges/csvy)
[![Travis-CI Build Status](https://travis-ci.org/leeper/csvy.png?branch=master)](https://travis-ci.org/leeper/csvy)
[![Appveyor Build status](https://ci.appveyor.com/api/projects/status/sgttgdfcql63578u?svg=true)](https://ci.appveyor.com/project/leeper/csvy)
[![codecov.io](http://codecov.io/github/leeper/csvy/coverage.svg?branch=master)](http://codecov.io/github/leeper/csvy?branch=master)

