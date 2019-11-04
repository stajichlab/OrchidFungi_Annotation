#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/update.%a.log
module unload python
module unload perl
module unload miniconda2
module load miniconda3
module load funannotate/git-live
PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
TRINITYHOMEPATH=$(dirname `which Trinity`)
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi
module load lp_solve
module load diamond
module unload rmblastn
module load ncbi-rmblast/2.6.0
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)


INDIR=genomes
OUTDIR=annotate
BUSCO=basidiomycota_odb9
SAMPFILE=strains.csv

N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`
if [ -z "$MAX" ]; then
    MAX=0
fi
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read BASE SPECIES STRAIN RNASEQSET LOCUS
do
    funannotate update --cpus $CPU -i $OUTDIR/$BASE --out $OUTDIR/$BASE
done
