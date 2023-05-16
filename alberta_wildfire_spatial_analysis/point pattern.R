# Point Pattern Analysis

# 1. Load Libraries -------------------------------------------------------

library(sf) # For Geospatial analysis and Simple Features
library(tidyverse) # data manipulation, ggplot2 all the good R stuff
library(tidyquant) # Mainly for theme
library(splancs) # Load the splancs library
library(spatstat) # quadrat test
library(ade4) # Mantel Rand Test




# 2. Load Data ------------------------------------------------------------

# Load in Simple Features Data
ignitions_tbl <- read_sf("v1/Data/NFDB_point(1)/NFDB_point_20220901.shp")


# 3. Transform/Clean Data -------------------------------------------------

# Get Vector of AB SRC_Agencies
AB_full <- c("AB","PC-WB","PC-GL","PC-BA", "PC-CH", "PC-EI", "PC-JA", "PC-LL", "PC-RO","PC-WL")

#NOTE: To do this for three decades I simply switch the Decade filter statement and run
#      Everything after    
ignitions_short_ab_tbl <- ignitions_tbl %>% 
    filter(SRC_AGENCY %in% AB_full) %>% 
    filter(between(LONGITUDE,-120 ,-110)) %>% 
    filter(between(LATITUDE, 49, 60)) %>% 
    filter(SIZE_HA >= 200) %>% 
    filter(DECADE %in% c("1990-1999")) %>% 
    mutate(t = yday(REP_DATE)) %>% 
    rename(x = LONGITUDE,
           y = LATITUDE)


# 4. Create PPP Object ----------------------------------------------------

# Get Longitudes
ab_long <- ignitions_short_ab_tbl$x

# Get Latitudes
ab_lat <- ignitions_short_ab_tbl$y

# Get Window
ab_window <- owin(xrange=c(min(ab_long),max(ab_long)), yrange=c(min(ab_lat),max(ab_lat)))

ignitions_ppp <- ppp(ab_long, ab_lat, window = ab_window) #convert to a ppp for use in spatstat

plot(ignitions_ppp, pch=16, main = "2010-2019 Ignitions ppp")



# 5. Plot Intensities -----------------------------------------------------

# Use the `bw.diggle` function to find an initial bandwidth for each point pattern 
bw1 = bw.diggle(ignitions_ppp)
bw1a <- bw1 + 0

# Investigate first order effects (variation in intensity) for the point patterns using the spatstat density function
plot(density(ignitions_ppp, bw1a), main = "1990-1999 Ignition Density")


# 6. Quadrat Test ---------------------------------------------------------

# Run a quadrat Chi Square test for CSR
# Test the point pattern
qt <- quadrat.test(ignitions_ppp)

# Inspect the results
plot(qt)
print(qt) # Rejects the Null of CSR

# 7. Fit Alternative Models -----------------------------------------------


# Fit a CSR model (homogeneous Poisson) to the Cardiff data and compare to different inhomogeneous Poisson models.
Fit1=ppm(ignitions_ppp,  ~1) # homogeneous Poisson 
Fit2=ppm(ignitions_ppp,  ~x+y) # first order inhomogeneous Poisson
Fit3=ppm(ignitions_ppp,  ~ polynom(x, y, 2)) # Second order inhomogeneous Poisson


# Compare these models using AIC and ANOVA
anova(Fit1, Fit2, Fit3, test = "Chi")
cat("AIC of Model 1: ", AIC(Fit1))
cat("AIC of Model 2: ", AIC(Fit2))
cat("AIC of Model 3: ", AIC(Fit3))


# 8. Estimate Nearest Neighbor Distance Probability Function with  --------

# Estimate G(r)
G_poisson <- Gest(ignitions_ppp)

# Plot G(r) vs. r
plot(G_poisson, main = "2010-2019 Nearest Neighbor Distance Probability") # Clear Clustering



# 9. Use Mantel's Rand Test to Test Spatial Temporal Clustering ----------

# Get Coordinates
xy=st_coordinates(ignitions_short_ab_tbl)
x=xy[,1]
y=xy[,2]

# Create new DF with coordinates and day of year
firesnew=data.frame(x/1000,y/1000,ignitions_short_ab_tbl$t)
colnames(firesnew)=c("x","y","t")

# Drop NAs
firesnew <- firesnew %>% 
    drop_na()


# Mantel Test
# for space-time interaction. For space-time interaction test use
# spatial distances time distances

s<-dist(cbind(firesnew$x,firesnew$y))
t<-dist(firesnew$t,method= "manhattan")

# Compute the Mantel test. This test reports the mantel score - 
#       a correlation value and its pvalue based on how extreme the observed  
#       value is relative the set of mantel values generated from some number of permutations: 
#       eg. 99
mantel.randtest(s,t,99)
plot(mantel.randtest(s,t,99), main = "2010-2019 Mantel Test for Spatial Clustering") # Reject the Null of CSTR













