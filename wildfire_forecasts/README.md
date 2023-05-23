## Authors
- Christopher Ewanik <christopher.ewanik@maine.edu>
- Abhilash Durgam <abhilash.durgam@maine.edu>

## tl;dr
1. Top performing model (Multivariate DeepAR) had a RMSE of 0.65 Fires / Week
2. Proper preprocessing, including spatial binning, improved results
3. Need for testing on different prediction lengths and exploration of cost functions
4. Model stacking would improve results
5. Only you can prevent wildfires

## Introduction
Wildfires have become an increasingly complex problem, with damages estimated at $1 billion annually in the 2010s. The cost of wildfires does not only encompass the financial impact but also the massive carbon emissions and the incalculable toll on families who lose homes, pets, and loved ones. Research using advanced data science techniques to predict wildfires has become more prevalent in recent years. This project aimed to develop a sophisticated neural network capable of predicting wildfires in Alberta, Canada, based on historical data and satellite imagery. This project uses Neural Networks to create 10-week wildfire forecasts. 

## Data
The Canadian National Fire Database served as the primary data source for this project. It contains ignition data for Canadian wildfires from 1930 onwards, including longitude and latitude for ignition points and polygon data for fire perimeters. The dataset has some inconsistencies and sporadic data, requiring careful consideration in selecting the years to include in the model. We have made use of data from 1980 onwards. The dataset was then cleaned to become a weekly time series. The target variable was the number of fires. However, we ultimately predicted the natural logarithm of fires plus 1. The plus one allows us to avoid the natural logarithm of zero (which results in - infinity). For the multivariate estimator, the province was binned into 16 sections based on their latitude and longitude. These bins were predicted separately using the same model architecture. The dataset is first loaded and pre-processed, with 75% of the data used for training (1979-12-30 to 2013-07-14) and the remaining 25% (2013-07-14 to 2021-12-14) for testing. 

# Methods
We implemented three deep learning architectures: DeepAREstimator, multivariate DeepAREstimator, and Temporal Fusion Transformer. The success of the models was evaluated using various loss functions such as RMSE, wQL, MAPE, MASE, and WAPE metrics. The DeepAREstimator and multivariate DeepAREstimator models were optimized using the Optuna hyperparameter optimization framework. In contrast, the Temporal Fusion Transformer used predetermined hyperparameters. The models were optimized for 6 hours on the Google Colab Premium GPU. The DeepAR models have a single layer of 55 hidden units and use an embedding dimension of 37. It is trained for 181 epochs with a learning rate of approximately 0.09185 and a batch size of 767. Additionally, a context length of 61 defines the length of the input sequence, and a dropout rate of close to 0.11223 is applied to the network to prevent overfitting. The Temporal Fusion Transformer uses a context length of 6 and a hidden dimension of 32, with 4 attention heads to capture complex temporal patterns. It is trained for 100 epochs with a learning rate of 0.001 and a batch size of 32. The model applies a dropout rate of 0.1 to prevent overfitting and also includes weight decay regularization with a strength of 1e-4.

# Limitations
One significant limitation of this study is its inability to differentiate between small and large fires. Although large fires comprise only 3% of fires, they are responsible for 97% of the burned area. Therefore, further attempts could be made to separately forecast small and large fires. Additionally, the model is optimized to make predictions 10 weeks in advance. To make this model more useful, changes should be made to attempt and provide longer forecasts for 26 or 52 weeks. 

![Wildfire Forecast](https://github.com/chrisewanik/wildfire_projects/assets/113730877/8543d694-6051-406e-890c-eaed3632d476)
