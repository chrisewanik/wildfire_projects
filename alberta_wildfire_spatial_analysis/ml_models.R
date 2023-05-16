# ANN

# 1. Load Libraries -------------------------------------------------------

library(sf) # For Geospatial analysis and Simple Features
library(tidyverse) # data manipulation, ggplot2 all the good R stuff
library(tidyquant) # Mainly for theme
library(recipes) # For Data Cleaning
library(rsample) # For Training Testing Splits
library(h2o) # For Modelling
library(elevatr) # For Elevation Generation


# 2. Load Data ------------------------------------------------------------

# Load in Simple Features Data
ignitions_tbl <- read_sf("v1/Data/NFDB_point(1)/NFDB_point_20220901.shp")

# Get Vector of AB SRC_Agencies
AB_full <- c("AB","PC-WB","PC-GL","PC-BA", "PC-CH", "PC-EI", "PC-JA", "PC-LL", "PC-RO","PC-WL")

# Filter to AB
ignitions_tbl <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% AB_full) %>% 
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    mutate(t = yday(REP_DATE)) %>% 
    arrange(LONGITUDE, LATITUDE, SIZE_HA)

# Get Elevations
# Filter to AB
# Instead, find the long lat limits of AB and filter like that?
ignitions_small_tbl <- ignitions_tbl %>% 
    select(LONGITUDE, LATITUDE, SIZE_HA)

# Extract Elevation
df_elev_aws <- get_elev_point(ignitions_small_tbl, src = "aws")

# Join Elevation Back to ignitions_tbl
df_elev_aws <- df_elev_aws %>% 
    arrange(LONGITUDE, LATITUDE, SIZE_HA)

# Get Vector Of Elevations
elevations <- df_elev_aws$elevation

# Join to Original Df
ignitions_tbl <- cbind(ignitions_tbl, elevations)

# Create Final ML Data Set
ann_raw_tbl <- ignitions_tbl %>% 
    mutate(large_fire = ifelse(SIZE_HA>=200, 1, 0)) %>% 
    as_tibble() %>% 
    select(c(LATITUDE, LONGITUDE, MONTH, CAUSE, FIRE_TYPE, ECOZ_NAME, t, elevations, large_fire)) %>% 
    drop_na() %>% 
    glimpse()
    


# 3. Clean Data -----------------------------------------------------------

# Recipe For Feature Engineering
recipe_obj <- recipe(large_fire ~ ., ann_raw_tbl) %>% 
    step_discretize(LATITUDE, LONGITUDE, num_breaks = 20) %>% # Create Bins for Lat and Long
    step_mutate_at(MONTH, fn = as.factor) %>% # Create Factors
    step_dummy(all_predictors(), one_hot = T) %>%  # Create Dummy Variables for Nominal Variables
    step_interact(terms = ~ starts_with("fire_type"):starts_with("ecoz_name") + 
                      starts_with("fire_type"):starts_with("cause") + 
                      starts_with("ecoz_name"):starts_with("cause")) %>% # Create Interaction Terms
    step_mutate_at(large_fire, fn = as.factor) %>% # Create Factors
    step_naomit(all_predictors()) %>%  # Remove Rows with Missing Values
    prep() # Creates 246 Columns

# Create Training and Testing Splits
# Split training into Training and Testing
train_test_split <- initial_split(ann_raw_tbl)

# Create Train Set
train_readable_tbl <- training(train_test_split)
# Create Test Set
test_readable_tbl  <- testing(train_test_split)


# Bake Training Data
train_tbl <- recipe_obj %>% 
    bake(new_data = train_readable_tbl)
# View Training Data
train_tbl %>% glimpse()

# Bake Test Data
test_tbl <- recipe_obj %>% 
    bake(new_data = test_readable_tbl)
# View Test Data
test_tbl %>% glimpse()


# 4. Start Modelling ------------------------------------------------------


# Fire up JAVA to R
h2o.init(nthreads = -1)

# Create h2o train and test objects
train_h2o <- as.h2o(train_tbl)
test_h2o  <- as.h2o(test_tbl)

# Declare Prediction Variable
y <- "large_fire"
x <- setdiff(names(train_h2o), y)

# Build Baseline Deep Model
deep_automl_models_h2o <- h2o.automl(
    x = x,
    y = y,
    training_frame   = train_h2o,
    max_runtime_secs = 600,
    nfolds           = 5,
    include_algos = c("DeepLearning"),
    stopping_metric = "AUCPR",
    sort_metric = "AUCPR",
    balance_classes = TRUE,
)


# See Leaderboard
deep_automl_models_h2o@leaderboard

# See Leader
deep_automl_models_h2o@leader

# See Top 25
print(deep_automl_models_h2o@leaderboard, n = 50) %>% as_tibble()

# Function to Extract Model
extract_h2o_model_name_by_position <- function(h2o_leaderboard, n = 1, verbose = TRUE){
    
    model_name <- h2o_leaderboard %>% 
        as_tibble() %>% 
        slice(n) %>% 
        pull(model_id)
    
    # message() - generate a message that is printed to the screen while the function runs
    if (verbose) message(model_name)
    
    return(model_name)
}

# Pull Confusion Matrixes
deep_automl_models_h2o@leaderboard %>% 
    extract_h2o_model_name_by_position(2) %>% 
    h2o.getModel() %>% 
    h2o.confusionMatrix(newdata = test_h2o)

# Get Top Model
dl2 <- h2o.getModel("DeepLearning_grid_1_AutoML_2_20221212_233252_model_3")

# Get Confusion Matrix
h2o.confusionMatrix(dl2, newdata = test_h2o)

q# Save top Model
h2o.saveModel(object = dl2, path = "models/")



# contains the following columns "Relative Importance", "Scaled Importance", and "Percentage".
deep_feats <- h2o.permutation_importance(dl2, train_h2o) %>% 
    as.tibble()

top_feats <- deep_feats[c(1:15),]

fires_plot <- top_feats %>% 
    
    # Declare Canvas
    ggplot(aes(x = reorder(Variable, -Percentage), y = Percentage, fill = Variable), show.legend=FALSE) + 
    
    # Declare Geometries
    geom_bar(stat="identity") +
    
    # Aesthetics
    theme_tq() +
    labs(
        x = "",
        y = "Percent Importance",
        title = "Variable Importance on Large Fires"
    ) +
    theme(
        axis.text.x=element_blank(), #remove x axis labels
        axis.ticks.x=element_blank() #remove x axis ticks
    )

# Reload Model
dl2 <- h2o.loadModel("models/DeepLearning_grid_1_AutoML_2_20221212_233252_model_3")
