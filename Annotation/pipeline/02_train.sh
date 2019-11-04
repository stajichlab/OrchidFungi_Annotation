#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem 256gb -p intel
#SBATCH --time=7-00:15:00   
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"
module unload python
module unload perl
module unload miniconda2
module load miniconda3
module load funannotate/git-live
PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
TRINITYHOMEPATH=$(dirname `which Trinity`)
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
CPUS=$SLURM_CPUS_ON_NODE

MEM=256G

if [ ! $CPUS ]; then
 CPUS=2
fi

ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNASeq
SAMPLEFILE=strains.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read BASE SPECIES STRAIN RNASEQSET LOCUS
do
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
     	echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
     	exit
    fi

	funannotate train -i $MASKED -o $ODIR/$BASE --PASAHOME $PASAHOMEPATH \
 --TRINITYHOME $TRINITYHOMEPATH \
 --left $RNAFOLDER/${RNASEQSET}_R1.fq.gz --right $RNAFOLDER/${RNASEQSET}_R1.fq.gz \
   --stranded RF --jaccard_clip --species "$SPECIES" --isolate $STRAIN  --cpus $CPUS --memory $MEM
done
