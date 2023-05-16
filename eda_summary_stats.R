# EDA and Visualize

# 1. Load Libraries -------------------------------------------------------

library(sf) # For Geospatial analysis and Simple Features
library(tidyverse) # data manipulation, ggplot2 all the good R stuff
library(tidyquant) # Mainly for theme
library(flextable) # For Tables

# 2. Load Data ------------------------------------------------------------

# Load in Simple Features Data
ignitions_tbl <- read_sf("v1/Data/NFDB_point(1)/NFDB_point_20220901.shp")

# Get Vector of AB SRC_Agencies
AB_full <- c("AB","PC-WB","PC-GL","PC-BA", "PC-CH", "PC-EI", "PC-JA", "PC-LL", "PC-RO","PC-WL")


# Create Only AB Ignitions (Overwrite tbl so I don't have to change everything)
ignitions_tbl <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% AB_full) %>% 
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    mutate(large_fire = if_else(SIZE_HA >= 200, "Yes", "No")) %>% 
    filter(SIZE_HA > 0)


# 3. Explore --------------------------------------------------------------

ignitions_tbl %>% glimpse()
# Note: Lots of Chr need to be factors

# Plot log size (skewed)
hist(log(ignitions_tbl$SIZE_HA))

# Range of fires
range(ignitions_tbl$SIZE_HA)

# Get Unique SRC_AGENCIES
(unique(as.factor(ignitions_tbl$SRC_AGENCY)))

# Get Unique Borreal
(unique(as.factor(ignitions_tbl$ECOZ_NAME)))

ignitions_tbl %>% 
    group_by(ECOZ_NAME, large_fire) %>% 
    summarise("# Fires" = n()) %>% 
    as_tibble() %>% 
    select(-c("geometry")) %>% 
    rename(
        "Ecology Zone" = ECOZ_NAME,
        "Large Fire" = large_fire
    ) %>% 
    flextable()
    


# Get Unique FIRE_TYPE
(unique(as.factor(ignitions_tbl$FIRE_TYPE)))


ignitions_tbl %>% 
    group_by(FIRE_TYPE, large_fire) %>% 
    summarise("# Fires" = n()) %>% 
    as_tibble() %>% 
    select(-c("geometry")) %>% 
    rename(
        "Fire Type" = FIRE_TYPE,
        "Large Fire" = large_fire
    ) %>% 
    flextable()


# Get Unique Cause
(unique(as.factor(ignitions_tbl$CAUSE)))


ignitions_tbl %>% 
    group_by(CAUSE, large_fire) %>% 
    summarise("# Fires" = n()) %>% 
    as_tibble() %>% 
    select(-c("geometry")) %>% 
    rename(
        "Cause" = CAUSE,
        "Large Fire" = large_fire
    ) %>% 
    flextable()

# Get Max Fire Size
max_size <- max(ignitions_tbl$SIZE_HA)

max_fire_tbl <- ignitions_tbl %>% 
    filter(SIZE_HA == max_size)

# 4. Visualization --------------------------------------------------------


# Get Fires by Decade
ignitions_tbl %>% 
    group_by(DECADE, large_fire) %>% 
    summarize(fires = n()) %>% 
    ungroup() %>% 
    
    # Declare Canvas
    ggplot(aes(x = DECADE, y = fires)) +
    
    # Declare Geometries
    geom_histogram(color = "red", fill = "red",stat = "identity") +
    
    # Add Label
    geom_label(aes(label = fires),
               #hjust =  "inward",
               size = 3,
               color = palette_light()[1]) +
    labs(
        title = "Wildfires By Decade",
        subtitle = "Split By Large Fire Variable",
        y = "Wildfires",
        x = "Decade"
    ) +
    
    # Get Theme 
    facet_wrap(~large_fire, scales = "free") +
    theme_tq()
    


# Get Fire Size
ignitions_tbl %>% 
    
    # Declare Canvas
    ggplot(aes(log(SIZE_HA))) +
    
    # Declare Geometries
    geom_histogram(fill = "red", color = "red") +
    labs(
        title = "Wildfire Size By Province",
        y = "# Fires",
        x = "Province"
    ) +
    
    # Get Theme and Declare Facet
    facet_wrap(~large_fire, scales = "free") + 
    theme_tq()



# Get Top 10 Fires By ECOZ_NAME
ignitions_tbl %>% 
    
    # Clean Data For Plot
    group_by(ECOZ_NAME, large_fire) %>% 
    summarize(fires = n()) %>% 
    ungroup() %>% 
    arrange(desc(fires)) %>% 
    top_n(10, fires) %>% 
    
    # Declare Canvas
    ggplot(aes(x = fct_reorder(ECOZ_NAME, desc(fires)), y = fires)) +
    
    # Declare Geometries
    geom_histogram(color = "red", fill = "red",stat = "identity") +
    
    # Add Label
    geom_label(aes(label = fires),
               #hjust =  "inward",
               size = 3,
               color = palette_light()[1]) +
    labs(
        title = "Top 10 Ecology Fire Zones",
        subtitle = "Split By Large Fire Variable",
        y = "Wildfires",
        x = "Zone"
    ) +
    
    # Get Theme 
    facet_wrap(~large_fire, scales = "free") +
    theme_tq()

# Get Top 10 Fires By FIRE_TYPE
ignitions_tbl %>% 
    
    # Clean Data For Plot
    group_by(FIRE_TYPE, large_fire) %>% 
    summarize(fires = n()) %>% 
    ungroup() %>% 
    arrange(desc(fires)) %>% 
    top_n(10, fires) %>% 
    
    # Declare Canvas
    ggplot(aes(x = fct_reorder(FIRE_TYPE, desc(fires)), y = fires)) +
    
    # Declare Geometries
    geom_histogram(color = "red", fill = "red",stat = "identity") +
    
    # Add Label
    geom_label(aes(label = fires),
               #hjust =  "inward",
               size = 3,
               color = palette_light()[1]) +
    labs(
        title = "Top 10 Fire Types",
        y = "Wildfires",
        x = "Fire Types"
    ) +
    
    # Get Theme 
    facet_wrap(~large_fire, scales = "free") +
    theme_tq()



# Plot Top Ignitions
ignitions_tbl %>% 
    
    arrange(desc(SIZE_HA)) %>% 
    top_n(1000, SIZE_HA) %>% 
    
    # Declare Canvas
    ggplot(aes(x = LONGITUDE, y = LATITUDE)) +
    
    # Declare Geometries
    geom_point(aes(size = SIZE_HA, color = DECADE, fill = DECADE)) +
    
    labs(
        title = "Top 1000 Wildfire Ignitions by Size"
    ) +
    
    # Get Theme 
    theme_tq() 
    #theme(legend.position = "")



# Montly Spread 
ignitions_tbl %>% 
    
    filter(!(DECADE %in%c("1940-1949","1950-1959"))) %>% 
    
    # Declare Canvas
    ggplot(aes(x = MONTH)) +
    
    # Declare Geometries
    stat_bin(fill = "red", color = "red",binwidth = 1) +
    stat_bin(binwidth=1, geom="text", aes(label=..count..), vjust=.5, size = 3) +
    facet_wrap(~ DECADE) +
    
    labs(
        title = "Total Wildfire Count By Month",
        x = "Month",
        y = "Number of Fires"
    ) +
    
    # Get Theme 
    theme_tq()


