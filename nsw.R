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

# Import data

data <- read_csv("data/nsw/NSW_SuburbData2022.csv")

# View(data)

# Add a dummy day variable

data$Day <- "01"

# Tidy data

tidy_data <- data %>%
  pivot_longer('Jan 1995':'Dec 2022', names_to = "period", values_to = "count") %>%
  separate(period, into = c ("Month", "Year"), sep = " ") %>%
  mutate(ddate = paste(Year, Month, Day, sep = "-")) %>%
  mutate(ddate = as.Date(ddate, "%Y-%b-%d"))
           

# tidy_test <- head(tidy_data, 10)

# tidy_test$day <- "01"

# testing

final_test = data %>%
  # head(100) %>%
  select(-'Offence category') %>%
  pivot_longer('Jan 1995':'Dec 2022', names_to = "period", values_to = "count") %>%
  separate(period, into = c("Month", "Year"), sep = " ") %>%
  mutate(ddate = paste(Year, Month, Day, sep = "-")) %>%
  mutate(ddate = as.Date(ddate, "%Y-%b-%d")) %>%
  #rename(offence_cat = 'Offence category') %>%
  select(ddate, Year, Month, Suburb, Subcategory, count) %>%
  pivot_wider(names_from = Subcategory, values_from = count) %>%
  mutate(g_homicide = rowSums(across(c('Murder *', 'Attempted murder', 'Murder accessory, conspiracy', 'Manslaughter *')), na.rm = TRUE),
         g_assault = rowSums(across(c('Domestic violence related assault', 'Non-domestic violence related assault', 'Assault Police')), na.rm = TRUE),
         g_robbery = rowSums(across(c('Robbery without a weapon', 'Robbery with a firearm', 'Robbery with a weapon not a firearm')), na.rm = TRUE),
         g_theft = rowSums(across(c('Break and enter dwelling', 'Break and enter non-dwelling', 'Receiving or handling stolen goods', 'Motor vehicle theft',
                                  'Steal from motor vehicle', 'Steal from retail store', 'Steal from dwelling', 'Steal from person',
                                  'Stock theft', 'Fraud', 'Other theft')), na.rm = TRUE),
         g_sexual = rowSums(across(c('Sexual assault', 'Sexual touching, sexual act and other sexual offences')), na.rm = TRUE),
         g_drugs = rowSums(across(c('Possession and/or use of cocaine', 'Possession and/or use of narcotics', 'Possession and/or use of cannabis',
                                  'Possession and/or use of amphetamines', 'Possession and/or use of ecstasy', 'Possession and/or use of other drugs',
                                  'Dealing, trafficking in cocaine', 'Dealing, trafficking in narcotics', 'Dealing, trafficking in cannabis',
                                  'Dealing, trafficking in amphetamines', 'Dealing, trafficking in ecstasy', 'Dealing, trafficking in other drugs',
                                  'Cultivating cannabis', 'Manufacture drug', 'Importing drugs', 'Other drug offences')), na.rm = TRUE),
         g_disorderly = rowSums(across(c('Trespass', 'Offensive conduct', 'Offensive language', 'Criminal intent')), na.rm = TRUE),
         g_justice = rowSums(across(c('Escape custody', 'Breach Apprehended Violence Order', 'Breach bail conditions',
                                    'Fail to appear', 'Resist or hinder officer', 'Other offences against justice procedures')), na.rm = TRUE),
         g_other = rowSums(across(c('Abduction and kidnapping', 'Blackmail and extortion', 'Intimidation, stalking and harassment',
                                    'Other offences against the person', 'Malicious damage to property', 'Betting and gaming offences',
                                    'Liquor offences', 'Pornography offences', 'Prostitution offences', 'Transport regulatory offences',
                                    'Other offences')), na.rm = TRUE),
         .after = Suburb)
  #mutate(assault...) %>%
  #mutate(robbery...) %>%
  #mutate(theft...) %>%
  #mutate(drugs...) %>%
  #mutate()
  
  # pivot_wider(names_from = offence_cat, values_from = names[c(5:67)])
  
# I should mutate and create category variables by summing relevant variables.

# View(tidy_data)

head(tidy_data, 50)

