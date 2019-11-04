#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 96G --out logs/antismash.%a.%A.log -J antismash

module load antismash
module unload perl
source activate antismash
which perl

CENTER=USC
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotate
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

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

IFS=,
tail -n +2 $SAMPFILE sed -n ${N}p | while read BASE SPECIES STRAIN RNASEQSET LOCUS
do

	if [ ! -d $OUTDIR/$BASE  ]; then
		echo "No annotation dir for ${BASE}"
		exit
 	fi
	mkdir -p $OUTDIR/$BASE/annotate_misc
	antismash --taxon fungi --outputfolder $OUTDIR/$BASE/annotate_misc/antismash \
	    --asf --full-hmmer --cassis --clusterblast --smcogs --subclusterblast --knownclusterblast -c $CPU \
	    $OUTDIR/$BASE/predict_results/*.gbk
done
