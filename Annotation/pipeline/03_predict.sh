#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/predict.%a.log
module unload miniconda2
module load miniconda3
#module load funannotate/1.5.2-30c1166
module load funannotate/git-live
module switch mummer/4.0
module unload augustus
module load augustus/3.3
module load bamtools
module load braker/2.0.5
module load lp_solve
module load diamond
module unload rmblastn
module load ncbi-rmblast/2.6.0
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

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
tail -n +2 $SAMPFILE | sed -n ${N}p | while read BASE SPECIES STRAIN RNASEQSET
do
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
     	echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
     	exit
    fi
    name=$(echo "${SPECIES}_$STRAIN" | perl -p -e 'chomp; s/\s+/_/g; ')
    species=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g;')
    SEED_SPECIES="coprinopsis_cinerea_okayama7"
    mkdir $name.predict.$$
    pushd $name.predict.$$
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter JGI --busco_db $BUSCO --strain "$STRAIN" \
	-i $MASKED --name $BASE --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta \
	-s $species -o ../$OUTDIR/$BASE --busco_seed_species $SEED_SPECIES --genemark_mode ET
    popd
    rmdir $name.predict.$$
done
