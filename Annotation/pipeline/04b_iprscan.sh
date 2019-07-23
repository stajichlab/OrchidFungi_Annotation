#!/bin/bash
#SBATCH --ntasks 32 --nodes 1 --mem 96G -p intel 
#SBATCH --time 48:00:00 --out logs/iprscan.%A.log

module unload miniconda2
module load miniconda3
module load funannotate/git-live
module load iprscan
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

if [[ -f "config.txt" ]]; then
	source config.txt
else
        echo "Need a config file"
        exit
fi

XML=$ODIR/annotate_misc/iprscan.xml
IPRPATH=$(which interproscan.sh)
if [ ! -f $XML ]; then
	funannotate iprscan -i $ODIR -o $XML -m local -c $CPU --iprscan_path $IPRPATH
fi
