# tl;dr
1. Periodicity of wildfires is changing
2. Data exhibits clear spatial-temporal clustering
3. Feed Forward Neural Networks predicted fire size (large/small) accurately in 93% of test cases
4. Properly predicting large fires has the largest impact

## Introduction
This project conducts a spatial analysis of Albertan Wildfire Ignition Data. The analysis uses a variety of spatial statistics and an artificial neural network to attempt and analyze and study the trends of wildfires. The classification goal of the neural network is to predict whether a fire is over or below 200 hectares (the general definition for large wildfires). The project shows that Alberta wildfires are showing similar trends to California's. Additionally, the study provides strong evidence for spatial-temporal clustering and achieves a 93% accuracy in predicting the size of the fire. 

To Watch the video presentation, please click here: https://drive.google.com/file/d/1nZ6omCaEfYmhqb3qh8wnNuEhwUKcgmOi/view?usp=share_link (Please Note that I make a major speaking mistake and call the Slave Lake Fire the St. Paul Fire, sorry)

# Data
The Data is wildfire ignition data taken from the Canadian Wildfire DataMart (https://cwfis.cfs.nrcan.gc.ca/ha/nfdb). The dataset includes many variables, including the burn size, ignition type, fire cause etc. Elevation was also feature-engineered using AWS Open Data Terrain Tiles via the ElevatR package. The data uses a 75% 25% train test split. 

# Methods
The project focuses on using spatial statistics to try and analyze wildfires. I plot spatial intensities, conduct quadrat tests, fit alternative spatial models, estimate nearest neighbour distance probability,  and use Mantel's Random Test to test for spatial-temporal clustering. Finally, H2O is used to construct feed-forward neural networks that classify fires as large or small.

# Limitations
The project has both strengths and weaknesses. Overall the data collection issues alter some of our historical data and underrepresent the volume of fires in earlier years. Additionally, while the model has strong accuracy, it still struggles to predict large fires correctly. Large fires cause the most damage; a more helpful model would focus on these instances.

![Fire Intensities](https://github.com/chrisewanik/wildfire_projects/assets/113730877/6e15d08a-cd24-4e56-9db1-b4e95ab0abfc)
