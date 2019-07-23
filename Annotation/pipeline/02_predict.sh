#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/predict.%a.log


module unload python
module unload perl
module unload miniconda2
module load miniconda3
module load funannotate/git-live
module unload ncbi-blast
module load ncbi-blast/2.2.31+

export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
mkdir -p $TEMP

SEED_SPECIES="fusarium"
BUSCO=/srv/projects/db/BUSCO/v9/ascomycota_odb9
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate

mkdir -p $OUTDIR

SAMPLEFILE=strains.csv
BUSCO=sordariomyceta_odb9
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
IFS=,
sed -n ${N}p $SAMPLEFILE | while read BASE SPECIES
do
    strain=$(echo $BASE | perl -p -e 's/_/ /g')
    if [ ! -f $INDIR/$BASE.masked.fasta ]; then
	echo "No genome for $INDIR/$BASE.masked.fasta yet - run 00_mask.sh $N"
	exit
    fi
    PEPLIB=$(realpath lib/informant.aa)
    GENOMEFILE=$(realpath $INDIR/$BASE.masked.fasta)
    OUTDEST=$(realpath $OUTDIR/$BASE)
    mkdir $BASE.predict.$SLURM_JOB_ID
    pushd $BASE.predict.$SLURM_JOB_ID

    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter NCAUR \
	--busco_db $BUSCO --strain "$strain" \
	-i $GENOMEFILE --name $BASE \
	--protein_evidence $PEPLIB $FUNANNOTATE_DB/uniprot_sprot.fasta  \
	--min_training_models 100 \
	-s "$SPECIES"  -o $OUTDEST --busco_seed_species $SEED_SPECIES
    popd

    rmdir $BASE.predict.$SLURM_JOB_ID
done
