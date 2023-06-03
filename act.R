# This R file takes in ACT crime data and cleans and tidies it.
# It saves the cleaned and tidied data to a csv file.
# This R code primarily uses the Polars dataframe library for the wrangling.
# The intent is that it is then combined with like prepared data from the
# other States and Territories of Australia.

# Set working dir

# setwd("set/path/here")

# Import and load libraries

packages <- c("readr", "tidyr")

installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

lapply(packages, library, character.only = TRUE)

# Load Polars (not on CRAN yet)

if (!require("polars")) install.packages("polars", repos = "https://rpolars.r-universe.dev")

library(polars)

# Import data

data <- read_csv("data/act/ACT_district_monthly.csv")

data$Day <- "01" # Need this to create the date variable / type later

# Tidy data

tidy_data <- data %>%
  pivot_longer('APR23':'JAN14', names_to = 'period', values_to = 'count') %>%
  pivot_wider(names_from = 'Offence', values_from = 'count')

road_list <- list(c("Road Collision with injury", "Road Fatality", "Traffic infringement notices"))

# Cleaning and arranging the data

finished_df <- pl$DataFrame(tidy_data)$
  with_columns((pl$col("Day") + pl$col("period"))$alias("Date"))$
  with_columns(pl$col("Date")$str$strptime(pl$Date, "%d %B%y"))$
  with_columns(pl$col("Date")$dt$strftime("%b")$alias("Month"),
               pl$col("Date")$dt$strftime("%Y")$alias("Year"),
               pl$sum(road_list)$alias("c_road"))$
  select(pl$col(c("Date", "Month", "Year", "District")),
         pl$all()$exclude(c("Date", "Month", "Year", "District", "Day", "period")))$
  with_columns(pl$col("*")$exclude(c("Date", "Year", "Month", "District"))$cast(pl$Int32))$
  sort(c("Date", "District"))

# finished_df

# Write to csv

write.csv(finished_df, "outputs/act_tidy.csv")
