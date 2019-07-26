#!/usr/bin/bash
#SBATCH -p short --mem 8gb -n 8

module load BBMap

pushd lib
for file in *.filter-RNA.fastq.gz
do
base=$(basename $file .filter-RNA.fastq.gz)
reformat.sh in=$file out=${base}_R1.fq.gz out2=${base}_R2.fq.gz
done

