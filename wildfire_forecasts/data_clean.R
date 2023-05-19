
# ECE598 Final Project Data Clean -----------------------------------------


# Load Packages -----------------------------------------------------------

library(sf) # For Geospatial analysis and Simple Features
library(tidyverse) # data manipulation, ggplot2 all the good R stuff
library(lubridate) # For Time Manipulation
library(timetk) # For Time Series Data Functions


# Set Working Directory ---------------------------------------------------

setwd("~/School/UMaine_Spring_2023/ECE_590_Neural_Networks/Final_Project")


# Load Data ---------------------------------------------------------------

# Load in Simple Features Data
ignitions <- read_sf("Data/NFDB_point/NFDB_point_20220901.shp")


# Preview Data ------------------------------------------------------------

ignitions %>% glimpse()

# Data Manipulation -------------------------------------------------------

# Convert to Normal Dataframe
ignitions_tbl <- as_tibble(ignitions)


# Filter To Only AB Fires and mutate large_fire

# Get Vector of AB SRC_Agencies
AB_full <- c("AB","PC-WB","PC-GL","PC-BA", "PC-CH", "PC-EI", "PC-JA", "PC-LL", "PC-RO","PC-WL")

ignitions_tbl_cleaned <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% AB_full) %>% # Only Keep AB Fires
    filter(between(LONGITUDE,-120 ,-110)) %>% # LONG Filter
    filter(between(LATITUDE, 49, 60)) %>% # LAT Filter
    filter(YEAR >= 1980) %>% # Only Data starting at 1980
    filter(!(is.na(REP_DATE))) %>%  # Remove Any Fires without a Reported Date
    mutate(large_fire = if_else(SIZE_HA >= 200, "Yes", "No")) %>% # Create Large Fire
    mutate(t = yday(REP_DATE)) %>%  # Create Day of Year Var
    mutate(week = isoweek(REP_DATE)) # Get the ISO week of the year


# Keep Only Needed Columns
ignitions_ts_tbl <- ignitions_tbl_cleaned %>% 
    select(REP_DATE, lat_long_bin)

# Turn Data Set into a weekly time series
ignitions_ts_cleaned_tbl <- ignitions_ts_tbl %>% 
    
    # Create Weekly Ignitions
    summarize_by_time(REP_DATE, .by = "week", n_fires = n()) %>% 
    
    # Pad By Day to Remove Missing Days
    pad_by_time(REP_DATE, .by = "week", .pad_value = 0) %>% 
    
    # Log Plus 1 Transform Target
    mutate(log_n_fires = log1p(n_fires))

# See NAs (Should be zero)
ignitions_ts_cleaned_tbl %>% 
    summarise(across(everything(), ~ sum(is.na(.x))))


# Save Output Data --------------------------------------------------------

write.csv(ignitions_ts_cleaned_tbl,"Data/ignition_data_ts.csv", row.names = FALSE)


# Section 2: Binning Updates ----------------------------------------------

# Get Vector of AB SRC_Agencies
AB_full <- c("AB","PC-WB","PC-GL","PC-BA", "PC-CH", "PC-EI", "PC-JA", "PC-LL", "PC-RO","PC-WL")

ignitions_tbl_cleaned <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% AB_full) %>% # Only Keep AB Fires
    filter(between(LONGITUDE,-120 ,-110)) %>% # LONG Filter
    filter(between(LATITUDE, 49, 60)) %>% # LAT Filter
    mutate(latitude_bin = cut(LATITUDE, breaks = 4),
           longitude_bin = cut(LONGITUDE, breaks = 4)) %>% 
    mutate(lat_long_bin = group_indices(., latitude_bin, longitude_bin)) %>% # Create Lat_Long Bins
    filter(YEAR >= 1980) %>% # Only Data starting at 1980
    filter(!(is.na(REP_DATE))) %>%  # Remove Any Fires without a Reported Date
    mutate(large_fire = if_else(SIZE_HA >= 200, "Yes", "No")) %>% # Create Large Fire
    mutate(t = yday(REP_DATE)) %>%  # Create Day of Year Var
    mutate(week = isoweek(REP_DATE)) # Get the ISO week of the year


# Keep Only Needed Columns
ignitions_ts_tbl <- ignitions_tbl_cleaned %>% 
    select(REP_DATE, lat_long_bin)

# Turn Data Set into a weekly time series
ignitions_ts_cleaned_tbl <- ignitions_ts_tbl %>% 
    
    # # Group By lat_long_bin
    group_by(lat_long_bin, REP_DATE) %>% 
    # Create Weekly Ignitions
    summarize_by_time(REP_DATE, .by = "week", n_fires = n()) %>%
    # Pad By Day to Remove Missing Days
    pad_by_time(REP_DATE, .by = "week", .pad_value = 0) %>% 
    # Log Plus 1 Transform Target
    mutate(log_n_fires = log1p(n_fires)) %>% 
    # Ungroup the lat_long_bin and REP_DATE
    ungroup(lat_long_bin, REP_DATE) %>% 
    # Complete Combinations 
    complete(lat_long_bin, REP_DATE, fill = list(log_n_fires = 0)) %>% 
    # Filter out rows with lat_long_bin = = 0 (created by complete)
    filter(lat_long_bin != 0) %>% 
    # Replace NA n_fires
    mutate(n_fires = replace_na(n_fires, 0)) %>% 
    # Remove n_fires column
    select(-n_fires) %>% 
    # Change from long to wide dataset
    pivot_wider(id_cols = REP_DATE, names_from = lat_long_bin, values_from = log_n_fires) %>% 
    # Order by Rep_date and lat_long_bin
    arrange(REP_DATE)

# Rename the columns
ignitions_ts_tbl <- ignitions_ts_cleaned_tbl %>% 
    select(-1) %>%
    rename_all(~ paste("lat_long_bin_", ., sep = ""))


# Bind the dataframe back together
ignitions_modeling_tbl <- ignitions_ts_cleaned_tbl %>% 
    select(1) %>% 
    cbind(ignitions_ts_tbl) %>% 
    glimpse()


# Save Output Data --------------------------------------------------------

write.csv(ignitions_modeling_tbl,"Data/ignition_data_bins_ts.csv", row.names = FALSE)



