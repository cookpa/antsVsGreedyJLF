#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "  $0 <subj> "
  exit 1
fi

subj=$1

binDir=`dirname $0`

outputBaseDir=/data/grossman/pcook/antsVsGreedyJLF/AntsRegAntsJLF

mkdir -p ${outputBaseDir}/$subj

qsub -l h_vmem=9G,s_vmem=9G -cwd -j y -o ${outputBaseDir}/${subj}/${subj}_log.txt -b y -v ANTSPATH=/data/jet/pcook/bin/ants/ ${binDir}/antsLabelSubjectLOO.pl $subj $outputBaseDir

