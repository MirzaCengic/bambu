
<!-- README.md is generated from README.Rmd. Please edit that file -->
Bambu project
=============

This repository contains data and scripts needed to project the potential distribution of Bamboo species in Peru.

To download the scripts you can individually save them, or clone the repository as follows:

``` git
git clone https://github.com/mirzacengic/bambu
```

This is ideally done in users home directory, otherwise the `processing_directory` variable in the main script might need to be adjusted. From here, the main modeling script should be ready to run (see more details below). To run the script, go to the folder with R scripts `R/`, and submit the script to the PBS scheduler (*note: it might be necessary to install some R packages, although this step should be automatic*).

``` git
cd
cd Bambu/R/
qsub run_models_manati_parallel.R
```

------------------------------------------------------------------------

#### Directory structure

Bambu project contains directory for input data (environmental predictors & shapefiles), R scripts, MAXENT java application (to fit maxent models), and Results folders which are created when `run_models_manati_*.R` script is run.

    #> .
    #> ├── bambu
    #> ├── Data
    #> │   ├── Predictors
    #> │   └── Shapefiles
    #> ├── MAXENT
    #> ├── R
    #> └── Results
    #>     ├── biomod
    #>     ├── csv
    #>     └── logs
    #> 
    #> 10 directories

------------------------------------------------------------------------

Running the models
------------------

There are two types of the main script - `run_models_manati_*.R`.
Both scripts will automatically load the data that is included in the `Data/` directory, create some directories, and run the models where their outputs will be stored in the `Results/` folder.

**Run in parallel (with foreach loop)**

-   `run_models_manati_parallel.R` will run models with a single script which uses parallel for loop (with foreach). This script should be submitted to the PBS job scheduler, and in the header of the script the number of cores can be defined (line 3), as well as in the R script (line 93). These numbers should be the same, and if the computer allows, it can be the same as the number of species that are being modelled.

**Run in parallel (with PBS array)**

-   `run_models_manati_array.R` will run models with a single script, using PBS array jobs. There is a script `run_array.sh` which should be submitted to the PBS job scheduler. This in turn will run the R script, and PBS will run multiple jobs at the same time (as defined by the *-t* argument from PBS header; 1-10 means that PBS will pass iterator i (using the `${PBS_ARRAYID}` from the bash script) to the main script from 1 to 10 (same as `for (i in 1:10)`); 1-10%3 means that 3 jobs max can be run at the same time).

Additional scripts
------------------

-   Script `./R/get_species_data.R` downloads additional data on species presences from GBIF.
-   Script `./R/plot_results.R` is useful for retrieving the modeling results.
