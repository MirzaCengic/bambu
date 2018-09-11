
<!-- README.md is generated from README.Rmd. Please edit that file -->
Bambu project
=============

This repository contains data and scripts needed to project the potential distribution of Bamboo species in Peru.

To download the scripts you can individually save them, or clone the repository

``` git
git clone https://github.com/mirzacengic/bambu
```

------------------------------------------------------------------------

#### Directory structure

Bambu project contains directory for input data (environmental predictors & shapefiles), R scripts, MAXENT java application (to fit maxent models), and Results folders which are created when `run_models_manati.R` script is run.

    #> .
    #> ├── bambu
    #> ├── Data
    #> │   ├── Predictors
    #> │   └── Shapefiles
    #> ├── MAXENT
    #> ├── R
    #> └── Results
    #>     ├── biomod
    #>     └── csv
    #> 
    #> 9 directories

------------------------------------------------------------------------

#### TODO:

-   Prepare predictors
-   Downloading data (script for retrieving it from GBIF)
-   Bash script for array jobs with PBS

#### Downloading data from GBIF

Script *./bla.R* downloads additional data on species presences from GBIF. - Add more description
