#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 8gb -p batch --out training.%A.log

module unload miniconda3
module load genemarkESET
module load perl/5.20.2

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
GENOME=LprolificansJHH5317_Genome.masked.fasta
gmes_petap.pl --core $CPU --fungus --ES --sequence $GENOME >& train.log
