# This R file takes in nsw crime data and cleans and tidies it.
# It saves the cleaned and tidied data to a csv file.
# The intent is that it is then combined with like prepared data
# from the other States of Australia.

# Set working directory

# setwd("your/path/here")

# Import and load libraries

packages <- c("readr", "dplyr", "tidyr")

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

# Add a dummy day variable

data$Day <- "01"

# tidy data

tidy_data = data %>%
  select(-'Offence category') %>%
  pivot_longer('Jan 1995':'Dec 2022', names_to = "period", values_to = "count") %>%
  pivot_wider(names_from = Subcategory, values_from = count)

# Testing Polars

homicide_list <- pl$series(c('Murder *', 'Attempted murder', 'Murder accessory, conspiracy', 'Manslaughter *'))

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

pl_big <- pl$DataFrame(tidy_data)$
  # fill_null(0)$fill_nan(0)$
  with_columns(pl$col("period")$str$splitn(" ", 2)$alias("dtemp"))$
  with_columns(pl$col("dtemp")$struct$rename_fields(c("Month", "Year")))$unnest("dtemp")$
  with_columns((pl$col("Day") + pl$col("period"))$alias("Date"))$
  with_columns(pl$col("*")$exclude(c("Suburb", "Day", "period", "Date", "Month", "Year"))$cast(pl$Int32))$
  with_columns(pl$col("Date")$str$strptime(pl$Date, "%d%b %Y"))$
  with_columns(pl$sum(homicide_list)$alias("c_homicide"),
               pl$sum(assault_list)$alias("c_assault"),
               pl$sum(robbery_list)$alias("c_robbery"),
               pl$sum(theft_list)$alias("c_theft"),
               pl$sum(sexual_list)$alias("c_sexual"),
               pl$sum(drugs_list)$alias("c_drugs"),
               pl$sum(disorderly_list)$alias("c_disorderly"),
               pl$sum(justice_list)$alias("c_justice"),
               pl$sum(other_list)$alias("c_other")
  )

  pl_big#$groupby("Suburb")$pl$col("*")$sum()$alias("tott")
  dim(pl_big)
  pl_big$select("Suburb", "Date", "Murder *", "c_theft", "c_homicide")$tail(20)

# df$with_columns((pl$col("a") * pl$col("b"))$alias("a * b"))

  #separate(period, into = c("Month", "Year"), sep = " ") %>%
  #mutate(ddate = paste(Year, Month, Day, sep = "-")) %>%
  #mutate(ddate = as.Date(ddate, "%Y-%b-%d")) %>%
  #rename(offence_cat = 'Offence category') %>%
  #select(ddate, Year, Month, Suburb, Subcategory, count) %>%
  #mutate(c_homicide = rowSums(across(c('Murder *', 'Attempted murder', 'Murder accessory, conspiracy', 'Manslaughter *')), na.rm = TRUE),
         # c_assault = rowSums(across(c('Domestic violence related assault', 'Non-domestic violence related assault', 'Assault Police')), na.rm = TRUE),
         # c_robbery = rowSums(across(c('Robbery without a weapon', 'Robbery with a firearm', 'Robbery with a weapon not a firearm')), na.rm = TRUE),
         # c_theft = rowSums(across(c('Break and enter dwelling', 'Break and enter non-dwelling', 'Receiving or handling stolen goods', 'Motor vehicle theft',
         #                          'Steal from motor vehicle', 'Steal from retail store', 'Steal from dwelling', 'Steal from person',
         #                          'Stock theft', 'Fraud', 'Other theft')), na.rm = TRUE),
         # c_sexual = rowSums(across(c('Sexual assault', 'Sexual touching, sexual act and other sexual offences')), na.rm = TRUE),
         # c_drugs = rowSums(across(c('Possession and/or use of cocaine', 'Possession and/or use of narcotics', 'Possession and/or use of cannabis',
         #                          'Possession and/or use of amphetamines', 'Possession and/or use of ecstasy', 'Possession and/or use of other drugs',
         #                          'Dealing, trafficking in cocaine', 'Dealing, trafficking in narcotics', 'Dealing, trafficking in cannabis',
         #                          'Dealing, trafficking in amphetamines', 'Dealing, trafficking in ecstasy', 'Dealing, trafficking in other drugs',
         #                          'Cultivating cannabis', 'Manufacture drug', 'Importing drugs', 'Other drug offences')), na.rm = TRUE),
         # c_disorderly = rowSums(across(c('Trespass', 'Offensive conduct', 'Offensive language', 'Criminal intent')), na.rm = TRUE),
         # c_justice = rowSums(across(c('Escape custody', 'Breach Apprehended Violence Order', 'Breach bail conditions',
         #                            'Fail to appear', 'Resist or hinder officer', 'Other offences against justice procedures')), na.rm = TRUE),
         # c_other = rowSums(across(c('Abduction and kidnapping', 'Arson', 'Prohibited and regulated weapons offences', 'Blackmail and extortion',
         #                            'Intimidation, stalking and harassment', 'Other offences against the person', 'Malicious damage to property',
         #                            'Betting and gaming offences', 'Liquor offences', 'Pornography offences', 'Prostitution offences', 'Transport regulatory offences',
         #                            'Other offences')), na.rm = TRUE),
         # .after = Suburb)

# write to csv is final step

# head(tidy_data, 50)

