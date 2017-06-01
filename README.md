# Import and Export CSV Data With a YAML Metadata Header #

THIS IS PATCHED VERSION, which parses `name` and `class` values in
YAML fields property for `colClasses` parameter passed to underlying
`read.csv`, `data.table::fread`, or `readr::read_csv` to have a better
support for column classes( particularly Date -class).


CSVY is a file format that combines the simplicity of CSV (comma-separated values) with the metadata of other plain text and binary formats (JSON, XML, Stata, etc.). The [CSVY file specification](http://csvy.org/) is simple: place a YAML header on top of a regular CSV. 

A CSVY file looks like this:

```
#---
#name: my-dataset
#fields:
#  - name: var1
#    title: variable 1
#    type: string
#    description: explaining var1
#    constraints:
#      - required: true
#  - name: var2
#    title: variable 2
#    type: integer
#  - name: var3
#    title: variable 3
#    type: number
#---
var1,var2,var3
A,1,2.5
B,3,4.3
```

Which we can read into R like this:



```r
library("csvy")
str(read_csvy("inst/examples/readme.csvy"))
```

```
## 'data.frame':	2 obs. of  3 variables:
##  $ var1: atomic  A B
##   ..- attr(*, "title")= chr "variable 1"
##   ..- attr(*, "type")= chr "string"
##   ..- attr(*, "description")= chr "explaining var1"
##   ..- attr(*, "constraints")=List of 1
##   .. ..$ :List of 1
##   .. .. ..$ required: logi TRUE
##  $ var2: atomic  1 3
##   ..- attr(*, "title")= chr "variable 2"
##   ..- attr(*, "type")= chr "integer"
##  $ var3: atomic  2.5 4.3
##   ..- attr(*, "title")= chr "variable 3"
##   ..- attr(*, "type")= chr "number"
##  - attr(*, "name")= chr "my-dataset"
```

Optional comment characters on the YAML lines make the data readable with any standard CSV parser while retaining the ability to import and export variable- and file-level metadata. The CSVY specification does not use these, but the csvy package for R does so that you (and other users) can continue to rely on `utils::read.csv()` or `readr::read_csv()` as usual. The `import()` in [rio](https://cran.r-project.org/package=rio) supports CSVY natively.

To create a CSVY file from R, just do:


```r
library("csvy")
library("datasets")
write_csvy(iris, "iris.csvy")
```

```
## Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
## sep2, : appending column names to file
```

```
## [1] "iris.csvy"
```

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
##  $ Species     : atomic  setosa setosa setosa setosa ...
##   ..- attr(*, "levels")= chr  "setosa" "versicolor" "virginica"
```

or use any other appropriate data import function to ignore the YAML metadata:


```r
d2 <- utils::read.table("iris.csvy", sep = ",")
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



## Package Installation ##

The package is available on [CRAN](https://cran.r-project.org/package=csvy) and can be installed directly in R using:

```R
install.packages("csvy")
```

The latest development version on GitHub can be installed using **devtools**:

```R
if(!require("ghit")){
    install.packages("ghit")
}
ghit::install_github("leeper/csvy")
```

[![CRAN Version](http://www.r-pkg.org/badges/version/csvy)](https://cran.r-project.org/package=csvy)
![Downloads](http://cranlogs.r-pkg.org/badges/csvy)
[![Travis-CI Build Status](https://travis-ci.org/leeper/csvy.png?branch=master)](https://travis-ci.org/leeper/csvy)
[![Appveyor Build status](https://ci.appveyor.com/api/projects/status/sgttgdfcql63578u?svg=true)](https://ci.appveyor.com/project/leeper/csvy)
[![codecov.io](http://codecov.io/github/leeper/csvy/coverage.svg?branch=master)](http://codecov.io/github/leeper/csvy?branch=master)

