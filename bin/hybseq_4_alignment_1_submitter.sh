#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Aligns all FASTA files in DATADIR named *.FNA or *.fasta (output of hybseq_3_hybpiper_postprocess_2_run.sh), for each of them submits job using qsub to process the sample with MAFFT and R.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
# HybSeq scripts and data
WORKDIR="/storage/brno2/home/${LOGNAME}/hybseq"

# Data to process
DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/2_seqs"

# Submitting individual tasks

# Go to working directory
echo "Switching to ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

# Removing zero size files
echo "There are $(find . -maxdepth 1 -type f -size 0 | grep -c "\.fasta$\|\.FNA$") alignments with zero size - removing them"
find . -maxdepth 1 -type f -size 0 -exec echo "Removing '{}'" \; -exec rm '{}' \;
echo

# Make output directory
echo "Making output directory"
mkdir aligned || { echo "Error! Failed creation of directory 'aligned' for storing alignments, or the directory already exists. Aborting."; echo; exit 1; }
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
for ALN in $(find . -maxdepth 1 -name "*.FNA" -o -name "*.fasta" | sort); do
	ALNB="$(basename "${ALN}")"
	echo "Processing ${ALNB}"
	qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=1gb -N HybSeq.alignment."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALNB}" "${WORKDIR}"/bin/hybseq_4_alignment_2_qsub.sh || { echo "Error! Submission of \"${ALNB}\" failed. Aborting."; echo; exit 1; }
	echo
	done

echo "All jobs submitted..."
echo

exit

