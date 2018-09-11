# Script to extract and plot projection results from the modeling stage

# 
pacman::p_load(raster, tidyverse, mapview)



# Set directory that has biomod results
processing_directory <- "Projects/Bambu" %>%
  milkunize2()

biomod_dir <- paste0(processing_directory, "/Results/biomod")


# Pass a species name or a genus name, and raster stack that contains 
# that string in the name will be returned
load_data <- function(sp, directory) {
  projection_stack <- directory %>% 
    list.files(recursive = TRUE, pattern = "img$", full.names = TRUE) %>% 
    str_subset(sp) %>% 
    stack()
  
  return(projection_stack)
}

# Periu border (to be used for cropping)
peru <- processing_directory %>% 
  paste0("/Data/Shapefiles/GADM_2.8_PER_adm0.rds") %>% 
  read_rds()

# Load data related with Bambusa genus
bambusa <- load_data("Bambusa", biomod_dir)
plot(bambusa)

# Load everything
all <- load_data("", biomod_dir)
plot(all)

# Check what is within the raster stack
# !! Outputs from ensemble models are:
# - EMmeanByTSS -- Mean value of multiple models
# - EMwmeanByTSS -- Mean value of multiple models weighted by TSS value (better models weigh more)
# - ensemble.x -- One of the models that go into the ensemble
# - .x -- individual model projections

names(bambusa)

####
bambusa_mean <- mean(bambusa)
bambusa_median <- raster::calc(bambusa, fun = median)

plot(chusquea_mean)
plot(chusquea_median)

# Mask weighted mean projection to the boundary of Peru
bambusa_peru_wmean <- mask(bambusa[[2]], peru)

plot(bambusa_peru_wmean)



