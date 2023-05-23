## tl;dr
1. PostgreSQL has great spatial features
2. Working between R, Python, and SQL is easy

## Introduction
The Canadian Fire Services provide many outstanding data sources and options for anyone looking to analyze their data. All of it is available online in different formats. To make it easy to access the data, it is often in a large .shp file which is slow and cumbersome. This project will create a PostgreSQL database with Python and R connections to allow for a seamless flow between the three.

## Data
The Data is wildfire ignition data taken from the Canadian Wildfire DataMart (https://cwfis.cfs.nrcan.gc.ca/ha/nfdb). The dataset includes many variables, including the burn size, ignition type, fire cause etc. 

## Methods
The general methodology of this project is to use Python to read and input data into PostgreSQL. PostgreSQL tables are designed and split, and normalized to improve performance. Finally, data is pulled into R to enable quick, easy access. 

## Results
Query time was reduced by 94% by using a database compared to .shp files. Additionally, this format has lots of room to grow and scale and could incorporate more tables and more data, specifically raster data. 
