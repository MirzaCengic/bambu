# Script to retrieve additional gbif data

# Things done by the script:
# - Read and clear bamboo data from IIAP
# - Get additional data from GBIF for species that are modeled 
# - Merge the datasets and rarify occurence points to a 1 kilometer grid
####

## Get packages
pacman::p_load(spocc, sf, mapview, lubridate, dplyr, readxl, raster, sf)



bambu_species_raw <- read_excel("BD_SPECIES_bamboo_080817_modified.xlsx", sheet = 5)


#### Clean up names
bambu_species_raw <- bambu_species_raw %>% 
  mutate(
    Species = case_when(
      Latin == "Bambusa vulgaris var. vittata" | Latin == "Bambusa vulgaris var. vulgaris" ~ "Bambusa vulgaris",
      Latin == "Phyllostachis aurea" ~ "Phyllostachys aurea",
      TRUE ~ as.character(Latin)
    )
  )


#### Select species to model
#######
bambu_species_to_model <- c("Aulonemia hirtula",
                            "Aulonemia longiaristata",
                            "Aulonemia queko",
                            "Aulonemia sp.",
                            "Bambusa vulgaris",
                            "Chusquea barbata",
                            "Chusquea scandens",
                            "Chusquea sp.",
                            "Chusquea uniflora",
                            "Cryptochloa unispiculata",
                            "Guadua angustifolia",
                            "Guadua sp.",
                            "Guadua takahashiae",
                            "Guadua weberbaueri",
                            "Olyra standleyi",
                            "Pharus virescens",
                            "Phyllostachys aurea",
                            "Rhipidocladum harmonicum",
                            "Rhipidocladum racemiflorum")

#### Make spatial
bambu_species_sf <- bambu_species_raw %>% 
  filter(complete.cases(Latitud)) %>% # Get data with coordinates
  filter(Species %in% bambu_species_to_model) %>% # Get only species of interest
  transmute(Species = Species, # Subset and rename columns 
            Latitude = Latitud,
            Longitude = Longitud,
            Source = Source) %>% 
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) # Convert into simple feature

# bambu_species_sp <- as(bambu_species_sf, "Spatial")

#### Get species list
bambu_species_list <- bambu_species_sf %>% 
  as.data.frame() %>% 
  dplyr::select(Species) %>% 
  unique() %>% 
  arrange(Species)

# Define bounding box for Peru (to download gbif data within this area)
bbox_peru <- c(-82.59846, -67.38535, -20.18324, 1.793963)

# Create empty dataframe into which data from gbif will be downloaded
bambu_species_additional <- data.frame(Species = character(),
                                       Source = character(),
                                       Latitude = double(),
                                       Longitude = double())

# Download data from GBIF (main loop)
for (i in seq_along(bambu_species_to_model))
{
  out <- occ(query = bambu_species_to_model[i], from = "gbif", geometry = bbox_peru,
             has_coords = TRUE)
  if (out$gbif$meta$returned == 0) {next}

    out_cleared <- out %>% 
    occ2df() %>% 
      filter(date > "2000-01-01") %>% 
          transmute(Species = name,
              Source = prov,
              Latitude = latitude,
              Longitude = longitude)
  
  print(out)
  bambu_species_additional <- rbind(bambu_species_additional, out_cleared)
}
###

table(bambu_species_additional$Species)

bambu_species_gbif_sf <- bambu_species_additional %>% 
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) # Convert into simple feature

bambu_species_merged <- rbind(bambu_species_sf, bambu_species_gbif_sf)
bambu_species_merged_sp <- as(bambu_species_merged, "Spatial")

bambu_species_empty <- bambu_species_merged_sp[FALSE, ]
#### Rarify point data so there is a single occurence for each cell

# Load raster file that should be used as a mask
raster_mask <- raster("")
raster_grid <- as(raster_mask, "SpatialGrid")

crs(raster_grid) <- proj4string(bambu_species_merged_sp)


for (species in unique(bambu_species_merged_sp$Species))
{
  bambu_species_merged_single <- bambu_species_merged_sp[bambu_species_merged_sp$Species == species, ]
  
  
  bambu_species_merged_single$grid <- over(bambu_species_merged_single, raster_grid)
  gridlist <- split(bambu_species_merged_single, bambu_species_merged_single$grid)
  # Take one point per grid
  samples <- lapply(gridlist, function(x) x[sample(1:nrow(x), 1, FALSE),])
  # Bind those rows back together in a new data frame
  sampledgrid <- do.call(rbind, samples)
  bambu_species_empty <- rbind(bambu_species_empty, sampledgrid)
}


bambu_species_cleared <- st_as_sf(bambu_species_empty)

st_write(bambu_species_cleared, "S:/Species_data/Bambu_filtered.shp")



