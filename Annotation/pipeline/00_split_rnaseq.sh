#!/usr/bin/bash
#SBATCH -p short --mem 8gb -n 8

module load BBMap

pushd lib
odir=RNASeq
for file in *.filter-RNA.fastq.gz
do
    base=$(basename $file .filter-RNA.fastq.gz)
    if [ ! -f $odir/${base}_R1.fq.gz ]; then
	reformat.sh in=$file out=$odir/${base}_R1.fq.gz out2=$odir/${base}_R2.fq.gz
    fi
done

