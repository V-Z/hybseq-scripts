#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes gene trees for all aligned contigs named *.aln.fasta (output of hybseq_4_alignment_1_submitter.sh and following scripts) in DATADIR and all subdirectories, for each of them submits job using qsub to process the sample with IQ-TREE.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
WORKDIR="/storage/brno2/home/${LOGNAME}/hybseq"

# Data to process
DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/3_aligned"

# Submitting individual tasks

# Go to working directory
echo "Switching to ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

# Make output directory
echo "Making output directory"
mkdir trees
echo

################################################################################
# NOTE On another clusters than Czech MetaCentrum edit the 'qsub' command below to fit your needs
# See https://docs.metacentrum.cz/advanced/pbs-options/
# Edit qsub parameters if you need more resources, use particular cluster, etc.
################################################################################

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Processing all samples
echo "Processing all samples at $(date)..."
echo
for ALN in $(find . -name "*.aln.fasta" | sed 's/^\.\///' | sort); do
	ALNB="$(basename "${ALN}")"
	echo "Processing ${ALNB}"
	qsub -l walltime=48:0:0 -l select=1:ncpus=1:mem=16gb:scratch_local=1gb -N HybSeq.genetree."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALN}" "${WORKDIR}"/bin/hybseq_5_gene_trees_2_qsub.sh || { echo "Error! Submission of \"${ALNB}\" failed. Aborting."; echo; exit 1; }
	echo
	done

echo "All jobs submitted..."
echo

exit

