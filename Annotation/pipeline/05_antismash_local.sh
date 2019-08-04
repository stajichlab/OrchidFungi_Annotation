#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 96G --out logs/antismash.%A.log -J antismash

module unload miniconda3
module load miniconda2
module load antismash
module unload perl
conda info --envs
source activate antismash

CPU=$SLURM_CPUS_ON_NODE

which perl
TOPDIR=funannotate
antismash --taxon fungi --outputfolder antismash \
     --asf --full-hmmer --cassis --clusterblast --smcogs --subclusterblast --knownclusterblast -c $CPU \
     $TOPDIR/update_results/*.gbk
