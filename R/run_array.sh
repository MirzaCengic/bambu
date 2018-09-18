#!/bin/bash

#PBS -N bambu_modeling
#PBS -l nodes=1,walltime=24:00:00
#PBS -l mem=32gb
#PBS -M myemail@gmail.com
#PBS -m abe
#PBS -t 1-10
#PBS -o /home/USERNAME/Bambu/Results/logs/output.txt
#PBS -e /home/USERNAME/Bambu/Results/logs/output_error.txt

#### Settings to change for the PBS header ####
# ^^ Change the -o directory above ^^ # 
# ^^ Change the -M email above ^^ # 
# ^^ Change the -o USERNAME and directory if needed above and below ^^ # 

/opt/shared/R-3.4.2/bin/R --vanilla --no-save --args ${PBS_ARRAYID} < /home/USERNAME/Bambu/R/run_models_manati_array.R
