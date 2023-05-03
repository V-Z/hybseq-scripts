#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=12:0:0 -l select=1:ncpus=1:mem=16gb:scratch_local=1gb -q ibot -m abe -N HybSeq.genetree."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALN}" ~/hybseq/bin/hybseq_5_gene_trees_2_qsub.sh

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar ${SCRATCHDIR} ${DATADIR}/ && clean_scratch' TERM

# Checking if all required variables are provided
if [[ -z "${ALNF}" ]]; then
	echo "Error! Sample name not provided!"
	exit 1
	fi
if [[ -z "${WORKDIR}" ]]; then
	echo "Error! Data and scripts for HybSeq not provided!"
	exit 1
	fi
if [[ -z "${DATADIR}" ]]; then
	echo "Error! Directory with data to process not provided!"
	exit 1
	fi

# Required modules
echo "Loading modules"
module add iqtree-2.2.0 || exit 1 # IQ-TREE 2
# module add raxml-ng-1.1.0 || exit 1 # RAxML-NG
echo

# Change working directory
echo "Going to working directory ${SCRATCHDIR}"
cd "${SCRATCHDIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - ${WORKDIR}"
cp "${WORKDIR}"/bin/hybseq_5_gene_trees_3_run.sh "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}/${ALNF}"
cp "${DATADIR}"/"${ALNF}" "${SCRATCHDIR}"/ || exit 1
echo

# Basename of the input contig
echo "Obtaining basename of input file ${ALNF}"
ALNA="$(basename "${ALNF}")" || exit 1
echo

# Runing the task (trees from individual alignments)
echo "Computing gene tree from ${ALNA}..."
./hybseq_5_gene_trees_3_run.sh -a "${ALNA}" | tee hybseq_gene_tree."${ALNA%.*}".log
rm "${ALNA}" hybseq_5_gene_trees_3_run.sh || { export CLEAN_SCRATCH='false'; exit 1; }
echo

# Copy results back to storage
cp -a "${SCRATCHDIR}"/* "${DATADIR}"/trees/ || export CLEAN_SCRATCH='false'

exit

