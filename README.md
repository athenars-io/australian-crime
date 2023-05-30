# Australian Crime

This repository provides R code to wrangle a range of Australian crime statistics. The crime statistics are from each of the State and Territory organic crime statistics areas - except Tasmania which does not have any crime data available below the State level.

The code in this repo wrangles, cleans and tidies crime statistics from across Australia down as low as the suburb and monthly level. This is as granular as is available in the public domain.

The crime data from all States and Territories are all in different formats and structures. This makes analysing the detailed suburb level crime as frequent as monthly data from across the country difficult.

So this repo aims to clean, tidy and arrange the data in a consistent format so that it can be combined into a consistent national dataset, maintaining the suburb / monthly detail.

# The approach to data standardisation

For each States dataset, the first focus is to arrange the data into a standard *tidy* format - drawing on [this article by Hadley Wickham](https://tidyr.tidyverse.org/articles/tidy-data.html). This means that each row is an observation and each column is a variable. For us and this data, this means that each observation will consist of crime statistics for a range of crime types for one suburb for one month as far back as the dataset goes. Each value for each crime type will be a count of those crimes for that time period at that suburb.

One observation of data aims to look like this:

| Date | Month | Year | Suburb | crime1 | crime2 | ... |
|---|---|---|---|---|---|---|
| 2022-09-18 | Sep | 2022 | Manly | 5 | 11 | ... |

None of the data is structured like this so they will all require different processing.

The R programming language is used to wrangle this data. Originally, the `dplyr` package was the focus however some lengthy compute times for some wrangling made this approach sub-optimal. This may be due to local user issues. Regardless, now the `rpolars` package is the focus of the data manipulation. Learning `polars` has been on the to-do list for some time, so this seemed as good a reason to use it as any. Because `rpolars` does not have capability match with either the Rust or Python versions of `polars`, it does not have `melt` or `pivot` as yet. So `tidyr` is used for this.

# Steps

Firstly, the data for each state is standardised as described above. This aims to keep the data in as original a state to the source data as possible, regarding the variable names and values etc, however in this tidy form. 

Additionally, values for categories of crimes has been computed. For example, in NSW 'Murder *', 'Attempted murder', 'Murder accessory, conspiracy' and 'Manslaughter' all come under the 'Homicide' offence category. So we've generated *category* variables that sum the subcategories together. These variables are prefixed with 'c_' then the category name. So for the homicide category, it is named 'c_homicide'. This is to facilitate conveniant group by, aggregations and faceting. Some analysts may prefer to use the data in this form while it is very close to the original data. Later steps will change the data more drastically.

We've also taken the original Month and Year variable and have generated Dates, using a default day of the month of the first. We've also split the original variable so there is a seperate Month and Year variable.

This first data processing step keeps all of the original crime variables and no editing of values has been conducted. So analysts using the data from this first processing will need to check for eronous and valid values.

Many of the States and Territories all use slightly different names for crimes. Some come under different categories. Some include more detailed discrete crimes when others group them together more.

So mapping the crime types between States and Territories will in some cases mean that some variables will be lost. Some variables may be combined and / or renamed in order to bring about consistent nation-wide data. Detailed documentation explaining the steps taken will be provided as we work through this project. We will look to the Australian Bureau of Statistics (ABS) for their lead when determining common crime variables across States and Territories.

The various R scripts will write the final tidy data into the `outputs/` directory.