#

# 1. Load Libraries -------------------------------------------------------

library(sf) # For Geospatial analysis and Simple Features
library(tidyverse) # data manipulation, ggplot2 all the good R stuff
library(tidyquant) # Mainly for theme
library(flextable) # For Tables\
library(h2o)



# 2. Load Data ------------------------------------------------------------

# Load in Simple Features Data
ignitions_tbl <- read_sf("v1/Data/NFDB_point(1)/NFDB_point_20220901.shp")

# Create Only AB Ignitions (Overwrite tbl so I don't have to change everything)
ignitions_tbl <- ignitions_tbl %>% 
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    mutate(large_fire = if_else(SIZE_HA >= 200, "Yes", "No"))


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


# Get Earth Data
world <- ne_countries(scale = "medium", returnclass = "sf")
class(world)

# Plot Largest Fire
ggplot(data = world) +
    geom_sf() +
    geom_point(data = max_fire_tbl, aes(x = LONGITUDE, y = LATITUDE), size = 4, 
               shape = 23, fill = "darkred") +
    coord_sf(xlim = c(-120 ,-110), ylim = c(49, 60), expand = FALSE)


# 4. Visualization --------------------------------------------------------


# Get Fires by Decade
decade_count_plot <- ignitions_tbl %>% 
    group_by(DECADE) %>% 
    summarize(fires = n()) %>% 
    
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
        y = "Wildfires",
        x = "Decade"
    ) +
    
    # Get Theme 
    theme_tq()


# Get Fires By Province
provinces_list <- c("BC","AB","SK","MB","ON","QC","NL","NB","NS","YT","NT")

province_count_plot <- ignitions_tbl %>% 
    group_by(SRC_AGENCY) %>% 
    filter(SRC_AGENCY %in% provinces_list) %>% 
    summarize(fires = n()) %>% 
    
    # Declare Canvas
    ggplot(aes(x = fct_reorder(SRC_AGENCY, desc(fires)), y = fires)) +
    
    # Declare Geometries
    geom_histogram(color = "red", fill = "red",stat = "identity") +
    
    # Add Label
    geom_label(aes(label = fires),
               #hjust =  "inward",
               size = 3,
               color = palette_light()[1]) +
    labs(
        title = "Wildfires By Province",
        y = "Wildfires",
        x = "Province"
    ) +
    
    # Get Theme 
    theme_tq()


# Get Fire Size By Province Facet Wrap Histogram
province_box_plot <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% provinces_list) %>%
    filter(SIZE_HA > 0) %>% 
    
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
    facet_wrap(~ SRC_AGENCY, ncol = 4) + 
    theme_tq()



# Get Top 10 Fires By ECOZ_NAME

ecoz_t10_count_plot <- ignitions_tbl %>% 
    
    # Clean Data For Plot
    group_by(ECOZ_NAME) %>% 
    summarize(fires = n()) %>% 
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
        title = "Top 10 Ecology Zones",
        y = "Wildfires",
        x = "Zone"
    ) +
    
    # Get Theme 
    theme_tq()

# Get Top 10 Fires By FIRE_TYPE

fire_type_count_plot <- ignitions_tbl %>% 
    
    # Clean Data For Plot
    group_by(FIRE_TYPE) %>% 
    summarize(fires = n()) %>% 
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
    theme_tq()


# Plot Ignitions
national_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE, -150, -50)) %>% 
    #filter(SRC_AGENCY %in% provinces_list) %>% 
    
    # Declare Canvas
    ggplot(aes(x = LONGITUDE, y = LATITUDE)) +
    
    # Declare Geometries
    geom_point(aes(color = SRC_AGENCY, fill = SRC_AGENCY)) +

    labs(
            title = "Wildfire Ignitions"
    ) +
        
    # Get Theme 
    theme_tq() +
    theme(legend.position="none")

# Plot Ignitions
national_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE, -150, -50)) %>% 
    filter(SRC_AGENCY %in% provinces_list) %>% 
    
    # Declare Canvas
    ggplot(aes(x = LONGITUDE, y = LATITUDE)) +
    
    # Declare Geometries
    geom_point(aes(color = SRC_AGENCY, fill = SRC_AGENCY)) +
    
    labs(
        title = "Wildfire Ignitions"
    ) +
    
    # Get Theme 
    theme_tq()


# Plot Top Ignitions
size_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE, -150, -50)) %>% 
    filter(SRC_AGENCY %in% provinces_list) %>%
    arrange(desc(SIZE_HA)) %>% 
    top_n(1000, SIZE_HA) %>% 
    
    # Declare Canvas
    ggplot(aes(x = LONGITUDE, y = LATITUDE)) +
    
    # Declare Geometries
    geom_point(aes(size = SIZE_HA, color = SRC_AGENCY, fill = SRC_AGENCY)) +
    
    labs(
        title = "Top 1000 Wildfire Ignitions by Size"
    ) +
    
    # Get Theme 
    theme_tq()

# # Map
# canada <- c(lon = 106.3468, lat = 56.1304)
# canada_map <- get_map(location = canada, zoom = 10)

# Yearly Spread - Large Ignitions
annual_large_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    filter(SIZE_HA >= 200) %>% 

    # Declare Canvas
    ggplot(aes(x = YEAR)) +
    
    # Declare Geometries
    stat_bin(fill = "red", color = "red",binwidth = 3) +
    stat_bin(binwidth=3, geom="text", aes(label=..count..), vjust=1, size = 4) +
    
    labs(
        title = "Large Wildfire Count By Year",
        x = "Year",
        y = "Number of Fires"
    ) +
    
    # Get Theme 
    theme_tq()


# Yearly Spread - All Ignitions
annual_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    
    # Declare Canvas
    ggplot(aes(x = YEAR)) +
    
    # Declare Geometries
    stat_bin(fill = "red", color = "red",binwidth = 3) +
    stat_bin(binwidth=3, geom="text", aes(label=..count..), vjust=1, size = 3.5) +
    
    labs(
        title = "Total Wildfire Count By Year",
        x = "Year",
        y = "Number of Fires"
    ) +
    
    # Get Theme 
    theme_tq()



# Montly Spread - All Ignitions
monthly_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    filter(!(DECADE %in%c("1940-1949", "2020-2029"))) %>% 
    
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

# Montly Spread - Large Ignitions
monthly_large_ignitions <- ignitions_tbl %>% 
    
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    filter(!(DECADE %in%c("1940-1949", "2020-2029"))) %>% 
    filter(SIZE_HA >= 200) %>% 
    
    # Declare Canvas
    ggplot(aes(x = MONTH)) +
    
    # Declare Geometries
    stat_bin(fill = "red", color = "red",binwidth = 1) +
    stat_bin(binwidth=1, geom="text", aes(label=..count..), vjust=.5, size = 3) +
    facet_wrap(~ DECADE) +
    
    labs(
        title = "Total Large Wildfire Count By Month",
        x = "Month",
        y = "Number of Fires"
    ) +
    
    # Get Theme 
    theme_tq()


