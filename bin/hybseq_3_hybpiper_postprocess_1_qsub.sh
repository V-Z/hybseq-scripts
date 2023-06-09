#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Reads list of samples (output directories of hybseq_2_hybpiper_3_run.sh) in SAMPLES (must be in DATADIR) and extracts contigs of exons, introns and supercontigs, and computes basic statistics.
# All results are copied back to DATADIR. Resulting contigs can be used for alignments.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

################################################################################
# NOTE Submit the job by the command below
# On another clusters than Czech MetaCentrum edit the 'qsub' command below to fit your needs
# See https://docs.metacentrum.cz/advanced/pbs-options/
# Edit qsub parameters if you need more resources, use particular cluster, etc.
################################################################################

# qsub -l walltime=12:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=100gb -m abe ~/hybseq/bin/hybseq_3_hybpiper_postprocess_1_qsub.sh

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
# HybSeq scripts and data
WORKDIR="/storage/brno2/home/${LOGNAME}/hybseq"

# Reference bait FASTA files - relative path within WORKDIR
BAITFILE='ref/zingiberaceae/curcuma_HybSeqProbes_first958_concat.fasta'

# Data to process
DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/2_seqs"

# samples_list.txt is created by hybseq_1_prep.sh in the output directory for deduplicated sequences (it must be in in the directory with pre-processed input FASTQ sequences)
# If merging multiple libraries, either merge the samples_list.txt from each library, or run something like:
# find . -maxdepth 1 -type d | sed 's/^\.\///' | sort | tail -n+2 > samples_list.txt
SAMPLES='samples_list.txt'

################################################################################
# Cleanup of temporal (scratch) directory where the calculation was done
# See https://docs.metacentrum.cz/advanced/job-tracking/#trap-command-usage
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'trap' commands below
################################################################################

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar ${SCRATCHDIR} ${DATADIR}/ && clean_scratch' TERM

# Change working directory
echo "Going to working directory ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - ${WORKDIR}"
cp -a "${WORKDIR}"/{bin/hybseq_3_hybpiper_postprocess_2_run.sh,ref} . || exit 1
echo

################################################################################
# The calculation
################################################################################

# Runing the task (HibPiper postprocessing)
echo "Running HybPiper postprocessing..."
./hybseq_3_hybpiper_postprocess_2_run.sh -b "${BAITFILE}" -s "${SAMPLES}" | tee hybseq_hybpiper_postprocess.log
echo

exit

