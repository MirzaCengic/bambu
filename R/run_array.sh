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

Rscript /home/USERNAME/Bambu/R/run_models_manati_array.R -input=file-${PBS_ARRAYID}
