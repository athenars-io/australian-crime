# This R file takes in nsw crime data and cleans and tidies it.
# It saves the cleaned and tidied data to a csv file.
# This R code primarily uses the Polars dataframe library for the wrangling.
# The intent is that it is then combined with like prepared data
# from the other States of Australia.

# Set working directory

# setwd("your/path/here")

# Import and load libraries

packages <- c("readr", "tidyr", "dplyr")

installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

lapply(packages, library, character.only = TRUE)

# load Polars (not on CRAN yet) otherwise would include above

# if (! "polars" %in% row.names(installed.packages())) install.packages("polars", repos = "https://rpolars.r-universe.dev")

if (!require("polars")) install.packages("polars", repos = "https://rpolars.r-universe.dev")

library(polars)

# Import data

data <- read_csv("data/nsw/NSW_SuburbData2022.csv")

# df = pl$read_csv("data/nsw/NSW_SuburbData2022.csv")#$
  # with_column(pl$lit(0)$alias("Day"))

# Add a day variable

data$Day <- "01" # need this to create the date variable / type later

# tidy data, using tidyr

tidy_data = data %>%
  select(-'Offence category') %>% # need / want to remove this column at this stage
  pivot_longer('Jan 1995':'Dec 2022', names_to = "period", values_to = "count") %>%
  pivot_wider(names_from = Subcategory, values_from = count)

tail(tidy_data)

# Saving lists of crime categories, to sum later

homicide_list <- list(c('Murder *', 'Attempted murder', 'Murder accessory, conspiracy', 'Manslaughter *'))

assault_list <- list(c('Domestic violence related assault', 'Non-domestic violence related assault', 'Assault Police'))

robbery_list <- list(c('Robbery without a weapon', 'Robbery with a firearm', 'Robbery with a weapon not a firearm'))

theft_list <- list(c('Break and enter dwelling', 'Break and enter non-dwelling', 'Receiving or handling stolen goods',
                     'Motor vehicle theft', 'Steal from motor vehicle', 'Steal from retail store',
                     'Steal from dwelling', 'Steal from person','Stock theft', 'Fraud', 'Other theft'))

sexual_list <- list(c('Sexual assault', 'Sexual touching, sexual act and other sexual offences'))

drugs_list <- list(c('Possession and/or use of cocaine', 'Possession and/or use of narcotics', 
                     'Possession and/or use of cannabis','Possession and/or use of amphetamines',
                     'Possession and/or use of ecstasy', 'Possession and/or use of other drugs',
                     'Dealing, trafficking in cocaine', 'Dealing, trafficking in narcotics', 'Dealing, trafficking in cannabis',
                     'Dealing, trafficking in amphetamines', 'Dealing, trafficking in ecstasy', 'Dealing, trafficking in other drugs',
                     'Cultivating cannabis', 'Manufacture drug', 'Importing drugs', 'Other drug offences'))

disorderly_list <- list(c('Trespass', 'Offensive conduct', 'Offensive language', 'Criminal intent'))

justice_list <- list(c('Escape custody', 'Breach Apprehended Violence Order', 'Breach bail conditions', 'Fail to appear',
                       'Resist or hinder officer', 'Other offences against justice procedures'))

other_list <- list(c('Abduction and kidnapping', 'Arson', 'Prohibited and regulated weapons offences', 'Blackmail and extortion',
                 'Intimidation, stalking and harassment', 'Other offences against the person', 'Malicious damage to property',
                 'Betting and gaming offences', 'Liquor offences', 'Pornography offences', 'Prostitution offences',
                 'Transport regulatory offences', 'Other offences'))

# Parsing, cleaning and wrangling of the data using polars

finished_df <- pl$DataFrame(tidy_data)$
  with_columns(pl$col("*")$exclude("Offence category"))$
  fill_null(0)$fill_nan(0)$
  with_columns(pl$col("period")$str$splitn(" ", 2)$alias("dtemp"))$
  with_columns(pl$col("dtemp")$struct$rename_fields(c("Month", "Year")))$unnest("dtemp")$
  with_columns((pl$col("Day") + pl$col("period"))$alias("Date"))$
  with_columns(pl$col("Date")$str$strptime(pl$Date, "%d%b %Y"),
               pl$sum(homicide_list)$alias("c_homicide"),
               pl$sum(assault_list)$alias("c_assault"),
               pl$sum(robbery_list)$alias("c_robbery"),
               pl$sum(theft_list)$alias("c_theft"),
               pl$sum(sexual_list)$alias("c_sexual"),
               pl$sum(drugs_list)$alias("c_drugs"),
               pl$sum(disorderly_list)$alias("c_disorderly"),
               pl$sum(justice_list)$alias("c_justice"),
               pl$sum(other_list)$alias("c_other"))$
  with_columns(pl$col("*")$exclude(c("Suburb", "Day", "period", "Date", "Month", "Year"))$cast(pl$Int32)
  )$
  select(pl$col(c("Date", "Month", "Year", "Suburb")), 
         pl$all()$exclude(c("Date", "Month", "Year", "Suburb", "period", "Day")))$
  sort(c("Date", "Suburb"))

# finished_df

# Finish by writing the file out to disk as csv

write.csv(finished_df, "outputs/nsw_tidy.csv")

