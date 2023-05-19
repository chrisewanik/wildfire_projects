# PostgreSQL Connection

# 1. Load Library ---------------------------------------------------------

#library(RPostgreSQL)
#library(RPostgres)
library(DBI)
library(sf)
library(rpostgis) # R Interface to a 'PostGIS' Database


# 2. Enter Credentials ----------------------------------------

db <- 'SIE555_2022'  # provide the name of your db
host_db <- 'localhost' #i.e. # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'  
db_port <- '5432'  # or any other port specified by the DBA
db_user <- "testuser" # provide the username to log into DB
db_password <- "#testuser37" # Provide password

# 3. Connect --------------------------------------------------------------

con <- dbConnect(RPostgres::Postgres(), dbname = db, host=host_db, port=db_port, user=db_user, password=db_password) 
dbListTables(con) # List Tables

# 4.  Check the geometries in the database --------------------------------

pgListGeom(con, geog = TRUE)

# 5. Queries --------------------------------------------------------------

# Query database for all data
all_ignitions <- dbGetQuery(con, "SELECT * FROM final_project.ignitions")

# Convert to SF
all_ignitions_sf <- st_as_sf(all_ignitions,coords = c("LONGITUDE", "LATITUDE"), remove = F)

# Query database for all Wildfires in Alberta
ab_ignitions <- dbGetQuery(con, 
        "SELECT *
        FROM final_project.fire_table
        WHERE longitude BETWEEN -120 AND -110
        AND latitude BETWEEN 49 AND 60;"
)

# Convert to SF
ab_ignitions_sf <- st_as_sf(ab_ignitions,coords = c("LONGITUDE", "LATITUDE"), remove = F)

# Query database for all The Largest Fire By Decade
largest_fire_decades <- dbGetQuery(con, 
                "SELECT d.decade, ROUND(MAX(f.size_ha), 0)
                 FROM final_project.fire_table f, final_project.date_table d
                 WHERE f.f_id = d.f_id
                 GROUP BY d.decade;"
)
# Convert to SF
largest_fire_decades_sf <- st_as_sf(largest_fire_decades,coords = c("LONGITUDE", "LATITUDE"), remove = F)

# Query database for the Count of Fires by Zone
ignitions_eco_zone <- dbGetQuery(con, 
                            "SELECT e.ecoz_name, COUNT(*) as fires
                            FROM final_project.fire_table f, final_project.eco_table e
                            WHERE f.f_id = e.f_id
                            GROUP BY e.ecoz_name
                            ORDER BY fires DESC;"
)
# Convert to SF
ignitions_eco_zone_sf <- st_as_sf(ignitions_eco_zone,coords = c("LONGITUDE", "LATITUDE"), remove = F)


# 6. Navigate to final_project Scheme and Query ---------------------------

# List tables associated with a specifc schema
dbGetQuery(con,
           "SELECT table_name FROM information_schema.tables
                   WHERE table_schema='final_project'")
# List fields in a table
dbListFields(con, c("ignitions", "tablename"))


