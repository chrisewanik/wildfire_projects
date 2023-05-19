# Connecting to Postgres
from sqlalchemy import create_engine
import geopandas as gpd
import geoalchemy2

# Get connected
try:
    connection_uri = 'postgresql://testuser:#testuser37@localhost:5432/SIE555_2022'
    engine = create_engine(connection_uri)
except Exception as e:
    print("Unable to connect to the database")
    raise Exception(e)
else:
    print("Database connected")


# Read Data
try:
    gdf = gpd.read_file('C:/Users/Chris/OneDrive/Documents/School/UMaine Fall 2022/SIE 512/Final Project/'
                        'wildfire_ignitions/v1/Data/NFDB_point(1)/NFDB_point_20220901.shp')
except Exception as e:
    print("Unable to load data")
    raise Exception(e)
else:
    print("Data loaded")


# Push the geodataframe to postgresql
try:
    gdf.to_postgis("ignitions", engine, schema="final_project", index=False, if_exists='replace')
except Exception as e:
    print("Unable to push data")
    raise Exception(e)
else:
    print("Data pushed")