#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 8G --out logs/mask_fast.%a.log
# This script runs Funannotate mask step
# Because this a project focused on population genomics we are assuming the repeat library
# generated for one R.stolonifer is suitable for all to save time this is used
# This expects to be run as slurm array jobs where the number passed into the array corresponds
# to the line in the samples.info file

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

if [ -z $SLURM_JOB_ID ]; then
    SLURM_JOB_ID=$$
fi

INDIR=genomes
OUTDIR=genomes
SAMPLEFILE=strains.csv
GENERICLIB=lib/Scedosporium.rm.lib
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
if [ ! -f $GENERICLIB ]; then
	echo " Cannot find general lib for fast running"
	exit
fi
IFS=,
sed -n ${N}p $SAMPLEFILE | while read BASE SPECIES
do
    IN=$(realpath $INDIR/$BASE.sorted.fasta)
    OUT=$(realpath $OUTDIR/$BASE.masked.fasta)

 if [ ! -f $IN ]; then
     echo "Cannot find $BASE.sorted.fasta in $INDIR - may not have been run yet"
     exit
 fi

 if [ ! -f $OUT ]; then

    module load funannotate/git-live
    module unload rmblastn
    module load ncbi-rmblast/2.6.0
    export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config

    mkdir $BASE.mask.$SLURM_JOB_ID
    pushd $BASE.mask.$SLURM_JOB_ID
    funannotate mask --cpus $CPU -l ../$GENERICLIB -i $IN -o $OUT

    mv funannotate-mask.log ../logs/$BASE.funannotate-mask.log
    mv repeatmodeler-library.*.fasta repeat_library/$BASE.repeatmodeler-library.fasta
    popd
    rmdir $BASE.mask.$SLURM_JOB_ID
 else 
     echo "Skipping ${BASE} as masked already"
 fi
done
