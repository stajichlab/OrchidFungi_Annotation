#!/usr/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 16gb
#SBATCH --output=logs/annotfunc.%a.%A.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel -J annotfunc
module load funannotate/git-live
module load phobius
CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
SAMPFILE=strains.csv
BUSCO=basidiomycota_odb9
TEMPLATE=

if [ ! $CPUS ]; then
 CPUS=1
fi
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi

MAX=$(wc -l $SAMPFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
echo "N is $N"
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read BASE SPECIES STRAIN RNASEQSET LOCUS
do
	if [ ! -d $OUTDIR/$BASE  ]; then
		echo "No annotation dir for ${BASE} ($OUTDIR/$BASE)"
		exit
 	fi
	# here we woudl conditionally make SBT file location from BASE info?

	MOREFEATURE=""
	if [[ ! -z $TEMPLATE ]]; then
		 MOREFEATURE="--sbt $TEMPLATE"
	fi
	# need to add detect for antismash and then add that
	funannotate annotate --busco_db $BUSCO -i $OUTDIR/$BASE --species \"$SPECIES\" --strain \"$STRAIN\" --cpus $CPUS $EXTRAANNOT $MOREFEATURE
done
