#!/usr/bin/env Rscript

#PBS -N bambu_parallel
#PBS -l nodes=10
#PBS -l mem=64gb
#PBS -l walltime 24:00:00
#PBS -M myemail@gmail.com
#PBS -m abe
#PBS -o /home/USERNAME/Bambu/Results/logs/Bambu_parallel.txt

#### Settings to change for the PBS header ####
# ^^ Change the -o directory above ^^ # 
# ^^ Change the -M email above ^^ # 
# ^^ Change the -o USERNAME and directory if needed ^^ # 

# Main script to bamboo distributiosn models - with foreach parallel loop




# Load packages -----------------------------------------------------------

# Install pacman package if missing
# install.packages("pacman")
pacman::p_load(raster, sf, readr, fasterize, dplyr, usdm,
               mapview, biomod2, readxl, stringr, doParallel, foreach)

# Set some parameters -----------------------------------------------------

# Create processing directory in the user's home folder (should be the same directory in which git repository was cloned into)
processing_directory <- "./Bambu"

# Directory for biomod resulty
biomod_dir <- paste0(processing_directory, "/Results/biomod")
# Directory for csv file outputs
csvs_folder <- paste0(processing_directory, "/Results/csv")
# Directory for job logs
logs_folder <- paste0(processing_directory, "/Results/logs")
# Create folders
dir.create(processing_directory)
dir.create(biomod_dir, recursive = TRUE)
dir.create(csvs_folder, recursive = TRUE)
dir.create(logs_folder, recursive = TRUE)

# Set working directory so the biomod output gets stored there
setwd(biomod_dir)

# Load data ---------------------------------------------------------------

# Here we'll load environmental predictors, species data, and additional data used (i.e. Peru boundary)
# Load climate predictors

bambu_rasters <- processing_directory %>% 
  paste0("/Data/Predictors/Climate") %>%
  list.files(pattern = "tif", full.names = TRUE) %>%
  stack()

####
bambu_rasters_raw <- processing_directory %>% 
  paste0("/Data/Predictors") %>%
  list.files(pattern = "tif", recursive = TRUE, full.names = TRUE) %>% 
  stack()

# Do variable selection based on VIF values, where variables with VIF < 10 are selected for further modeling.
bambu_vif <- usdm::vifstep(bambu_rasters_raw, th = 10)
# Create rasterstack with excluded variables
bambu_rasters <- usdm::exclude(bambu_rasters_raw, bambu_vif)
####


# Load species data
bambu_data <- processing_directory %>% 
  paste0("/Data/Shapefiles/bambu_with_gbif_samer_genus.gpkg") %>%
  read_sf()

# Load Peru data (used later to crop maps)
peru_boundary <- processing_directory %>% 
  paste0("/Data/Shapefiles/GADM_2.8_PER_adm0.rds") %>% 
  read_rds()

# Crop rasters for prediction
bambu_rasters_peru <- stack(crop(bambu_rasters, peru_boundary))


processing_species <- unique(bambu_data$Name_cleaned)
##%######################################################%##
#                                                          #
####                    BIOMOD part                     ####
#                                                          #
##%######################################################%##

# Set number of cores (should be the same as #PBS -l nodes=x)
cores_number <- 20
cl <- makeCluster(cores_number)
registerDoParallel(cl)

# Parallel foreach loop
foreach(species = processing_species) %dopar%
# Regular for loop
# for (species in processing_species)
{

pacman::p_load(raster, sf, readr, dplyr,
               biomod2, readxl, stringr, doParallel, foreach)
  
Console_output <- file(paste0(logs_folder, "/", as.character(species), "_", format(Sys.time(), "%d%m%y"), ".txt"), open = "wt")
sink(Console_output, append = TRUE)
sink(Console_output, append = TRUE, type = "message")
cat(paste0("#############################\n","Modeling ", as.character(species), "\n", "#############################\n"), "\n")

cat(paste("The process started at: ", Sys.time()), "\n")

# Get unique species range
cat("Getting species data", "\n")

###############
# biomod part #
###############
species = "Chusquea"
bambu_species_single <- bambu_data %>%
  dplyr::filter(Name_cleaned == species)

bambu_species_coordinates <- bambu_data %>%
  filter(Name_cleaned == species) %>%
  st_coordinates()
#
cat(paste0("There are ", nrow(bambu_species_single), " point records available for this species..."), "\n")
# species
cat("Calculating model data...", "\n")
model_data <- BIOMOD_FormatingData(resp.var = rep(1, nrow(bambu_species_single)),
                                   expl.var = bambu_rasters,
                                   resp.xy = bambu_species_coordinates,
                                   resp.name = paste0("Model_", str_replace(species, " ", "_")),
                                   PA.strategy = "random",
                                   PA.nb.absences = 1000,
                                   PA.nb.rep = 1, # or 10, check barbet massin
                                   na.rm = TRUE)


# MaxEnt
maxent_params <- list(path_to_maxent.jar = paste0(processing_directory, "/MAXENT/maxent.jar"),
                      memory_allocated = 2048)
#### Still to add more modeling tecniques; check from meeting notes what have we decided upon
biomod_options <- BIOMOD_ModelingOptions(MAXENT.Phillips = maxent_params)


# Do full models when there are less then 5 points
if (nrow(bambu_species_single) < 5)
{
  full_models <- TRUE
} else {
  full_models <- FALSE
}
# Set which modeling algorithms to use (still might be changed)

# model_algo <- c("MAXENT.Phillips", "GLM")
model_algo <- c("MAXENT.Phillips", "GLM", "GBM", "RF")


model_out <- BIOMOD_Modeling(model_data, models = model_algo,
                             models.options = biomod_options,
                             VarImport = 1,
                             NbRunEval = 1,
                             Prevalence = 0.5,
                             DataSplit = 66, # Split data into 2/3 - 1/3
                             models.eval.meth = c("ROC", "TSS"),
                             rescal.all.models = FALSE,
                             do.full.models = full_models,
                             SaveObj = TRUE,
                             modeling.id = paste0(str_replace(species, " ", "_"), "_model"))

eval_values <- model_out %>%
  get_evaluations() %>%
  as.data.frame() %>%
  select(contains("Testing.data")) %>%
  mutate(Var = row.names(.),
         sp_name = species) %>%
  select(Var, everything())

write.csv(eval_values, paste0(csvs_folder, "/Model_assessment_", str_replace(species, " ", "_"), ".csv"),
          row.names = FALSE)

var_imp_values <- model_out %>%
  get_variables_importance() %>%
  as.data.frame() %>%
  mutate(Var = row.names(.), 
         sp_name = species) %>%
  select(Var, everything())

write.csv(var_imp_values, paste0(csvs_folder, "/EMout_varimp_", str_replace(species, " ", "_"), ".csv"),
          row.names = FALSE)

# Project models for current climate
model_projection <- BIOMOD_Projection(modeling.output = model_out,
                                      new.env = bambu_rasters_peru,
                                      compress = "xz",
                                      output.format = ".img",
                                      proj.name = "current_projection",
                                      selected.models = "all",
                                      binary.meth = "TSS",
                                      build.clamping.mask = FALSE)


ensemble_model_out <- BIOMOD_EnsembleModeling(modeling.output = model_out,
                                              chosen.models = 'all',
                                              em.by = 'all',
                                              eval.metric = "TSS", #metric used to scale the ensamble
                                              eval.metric.quality.threshold = 0.5,
                                              prob.mean = TRUE,
                                              prob.cv = FALSE,
                                              prob.ci = FALSE,
                                              prob.ci.alpha = 0.05,
                                              prob.median = FALSE,
                                              committee.averaging = FALSE,
                                              prob.mean.weight = TRUE, #weight by TSS, Luca had T
                                              prob.mean.weight.decay = "proportional")

eval_values_ensemble <- ensemble_model_out %>%
  get_evaluations() %>%
  as.data.frame() %>%
  select(contains("Testing.data")) %>%
  transmute(Var = row.names(.),
         em_mean = .[[1]],
         em_wmean = .[[2]],
         sp_name = species) %>%
  select(Var, everything())

write.csv(eval_values_ensemble, paste0(csvs_folder, "/Ensemble_model_assessment_", str_replace(species, " ", "_"), ".csv"),
          row.names = FALSE)


ensemble_model_projection <- BIOMOD_EnsembleForecasting(projection.output = model_projection,
                                                        EM.output = ensemble_model_out,
                                                        compress = "xz",
                                                        output.format = ".img",
                                                        total.consensus = TRUE,
                                                        binary.meth = "TSS")

cat(paste("The process ended at: ", Sys.time()), "\n")

sink(type = "message")
sink()
}