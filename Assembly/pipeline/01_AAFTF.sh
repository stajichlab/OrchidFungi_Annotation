#!/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 16gb -J AAFTF --out logs/AAFTF.%a.log 
#SBATCH -p batch --time 48:00:00

hostname
MEM=16
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF

OUTDIR=input
SAMPLEFILE=samples.csv
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -d, -f1)
PHYLUM=basidiomycota
ASM=genomes

mkdir -p $ASM

if [ -z $CPU ]; then
    CPU=1
fi

ASMFILE=$ASM/${BASE}.spades.fasta
WORKDIR=working_AAFTF
VECCLEAN=$ASM/${BASE}.vecscreen.fasta
PURGE=$ASM/${BASE}.sourpurge.fasta
CLEANDUP=$ASM/${BASE}.rmdup.fasta
#PILON=$ASM/${BASE}.pilon.fasta
SORTED=$ASM/${BASE}.sorted.fasta
STATS=$ASM/${BASE}.sorted.stats.txt

LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

mkdir -p $WORKDIR

echo "$BASE"
if [ ! -f $ASMFILE ]; then    
echo "This run is short-circuited without assembly step. Need a valid file in $ASM folder for $ASMFILE"
exit
#    if [ ! -f $LEFT ]; then
#	echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
#	echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
#	exit
#    fi
#    echo "running assemble for $BASE"
#    AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  \
#	-o $ASMFILE -w $WORKDIR/spades_$BASE --mem $MEM
#    
#    if [ -s $ASMFILE ]; then
#	rm -rf $WORKDIR/spades_${BASE}
#    else
#	echo "SPADES must have failed, exiting"
#	exit
#    fi
fi

if [ ! -f $VECCLEAN ]; then
    AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
fi

if [ ! -f $PURGE ]; then
    AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM
fi

# this is going to take too long with highly fragmented assemblies
if [ ! -f $CLEANDUP ]; then
   AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1500
fi

#if [ ! -f $PILON ]; then
#   AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
#fi

#if [ ! -f $PILON ]; then
#    echo "Error running Pilon, did not create file. Exiting"
#    exit
#fi

if [ ! -f $SORTED ]; then
#    AAFTF sort -i $PILON -o $SORTED
    AAFTF sort -i $CLEANDUP -o $SORTED
#    AAFTF sort -i $PURGE -o $SORTED
fi

if [ ! -f $STATS ]; then
    AAFTF assess -i $SORTED -r $STATS
fi
